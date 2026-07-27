/*
 * Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import huks from '@ohos.security.huks';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { Log } from '../default/common/Log';
import { EmptyUtils } from './EmptyUtils';
import { ErrorCode } from '../commoncapability/error/ErrorCode';
import { util } from '@kit.ArkTS';

const AAD_LENGTH = 16;
const NONCE_LENGTH = 12;
const TAG = 'GcmUtil';
const ERROR_CODE = 1;

export class GcmUtil {
  public static readonly KEY_ALIAS_LOCATION: string = 'calendarLocation';

  /**
   * getEncryptedPwd 根据密码明文生成加密后的密码密文
   *
   * @param keyAlias 加密密钥的keyAlias
   * @param plainText 密码明文
   */
  public static async encryptString(keyAlias: string, plainText: string): Promise<string> {
    if (EmptyUtils.isEmptyString(keyAlias)) {
      Log.warn(TAG, 'encryptString keyAlias is not string or empty');
      return plainText;
    }
    if (EmptyUtils.isEmptyString(plainText)) {
      Log.warn(TAG, 'encryptString plainText is not string or empty');
      return plainText;
    }
    try {
      const aadU = GcmUtil.generateAad();
      const nonceU = GcmUtil.generateNonce();
      const ciphertext = await GcmUtil.encryptData(keyAlias, plainText, aadU, nonceU);
      if (ciphertext === undefined || ciphertext.length <= AAD_LENGTH) {
        Log.warn(TAG, `encryptString ciphertext length is ${ciphertext?.length} illegal`);
        return plainText;
      }
      // 加密后的结果是Uint8Array，直接转字符串是乱码，且可能出现\0等特殊字符导致转string后自动截断出错，因此输出为base64编码格式，以避免特殊字符
      const result = GcmUtil.uint8ArrayToBase64(new Uint8Array([...aadU, ...nonceU, ...ciphertext]));
      return result;
    } catch (err) {
      Log.logErrorMsg(TAG, `encryptString`, err);
      return plainText;
    }
  }

  /**
   * getDecryptedPwd 根据密码密文解密得到密码明文
   *
   * @param keyAlias 加密密钥的keyAlias
   * @param cipherText 数据库中取出的密码密文
   */
  public static async decryptString(keyAlias: string, cipherText: string): Promise<string> {
    if (EmptyUtils.isEmptyString(keyAlias)) {
      Log.warn(TAG, 'decryptedString keyAlias is not string or empty');
      return cipherText;
    }
    if (EmptyUtils.isEmptyString(cipherText)) {
      Log.warn(TAG, 'decryptedString cipherText is not string or empty');
      return cipherText;
    }
    try {
      // 加密的结果输出的是base64编码的字符串，所以解密处理前应按base64编码解码成Uint8Array
      const temp = GcmUtil.base64ToUint8Array(cipherText);
      if (temp.length <= AAD_LENGTH + NONCE_LENGTH + AAD_LENGTH) {
        Log.warn(TAG, `decryptedString cipherText length is ${temp.length} illegal`);
        return cipherText;
      }
      const aadS = temp.slice(0, AAD_LENGTH);
      const nonceS = temp.slice(AAD_LENGTH, AAD_LENGTH + NONCE_LENGTH);
      const purestCipherText = temp.slice(AAD_LENGTH + NONCE_LENGTH);
      const plainText = await GcmUtil.decryptData(keyAlias, purestCipherText, aadS, nonceS);
      return plainText;
    } catch (err) {
      Log.logErrorMsg(TAG, `decryptedString`, err);
      return cipherText;
    }
  }

  /*
 * 检查是否有密钥，如果没有密钥则生成密钥
 */
  private static async checkKeyItem(keyAlias: string): Promise<void> {
    // 获取生成密钥算法参数配置
    const genProperties = GcmUtil.getAesGenerateProperties();
    const options: huks.HuksOptions = {
      properties: genProperties
    };
    // 检查KeyItem是否存在
    try {
      await huks.isKeyItemExist(keyAlias, options);
    } catch (err) {
      Log.logErrorMsg(TAG, 'checkKeyItem isKeyItemExist', err);
      await huks.generateKeyItem(keyAlias, options);
    }
  }

  /**
   * 根据密码明文、aad和nonce来生成密文
   *
   * @param plainText 密码明文
   * @param aad
   * @param nonce
   * @returns 密文
   */
  private static async encryptData(keyAlias: string, plainText: string, aad: Uint8Array,
                                   nonce: Uint8Array): Promise<Uint8Array> {
    let handle: number = 0;
    await GcmUtil.checkKeyItem(keyAlias);
    const encryptProperties = GcmUtil.getAesEncryptProperties(aad, nonce);
    const inDataTemp = GcmUtil.stringToUint8Array(plainText);
    const options: huks.HuksOptions = {
      properties: encryptProperties,
      inData: inDataTemp
    };
    const sessionHandle = await huks.initSession(keyAlias, options);
    handle = sessionHandle.handle;
    const returnResult = await huks.finishSession(handle, options);
    return returnResult.outData as Uint8Array;
  }

  private static async decryptData(keyAlias: string, encryptedData: Uint8Array, aad: Uint8Array,
                                   nonce: Uint8Array): Promise<string> {
    if (aad.length !== AAD_LENGTH) {
      const msg = `aad length is ${aad.length} illegal`;
      throw { code: ErrorCode.ILLEGAL_CODE, message: msg, name: 'BusinessError' };
    }
    if (nonce.length !== NONCE_LENGTH) {
      const msg = `nonce length is ${nonce.length} illegal`;
      throw { code: ErrorCode.ILLEGAL_CODE, message: msg, name: 'BusinessError' };
    }
    if (EmptyUtils.isEmptyArray(encryptedData) || encryptedData.length <= AAD_LENGTH) {
      const msg = `encryptedData length is ${encryptedData?.length} illegal`;
      throw { code: ErrorCode.ILLEGAL_CODE, message: msg, name: 'BusinessError' };
    }
    await GcmUtil.checkKeyItem(keyAlias);
    const decryptOptions = GcmUtil.getAesDecryptProperties(encryptedData, aad, nonce);
    const options: huks.HuksOptions = {
      properties: decryptOptions,
      inData: encryptedData.slice(0, encryptedData.length - AAD_LENGTH)
    };
    const handle = (await huks.initSession(keyAlias, options)).handle;
    const outData = (await huks.finishSession(handle, options)).outData;
    if (EmptyUtils.isEmptyArray(outData)) {
      const msg = `outData length is ${outData?.length} illegal`;
      throw { code: ErrorCode.ILLEGAL_CODE, message: msg, name: 'BusinessError' };
    }
    const res = GcmUtil.uint8ArrayToString(outData);
    return res;
  }

  private static stringToUint8Array(str: String): Uint8Array {
    const arr: number[] = [];
    for (let i = 0; i < str.length; i++) {
      arr.push(str.charCodeAt(i));
    }
    return new Uint8Array(arr);
  }

  private static uint8ArrayToString(fileData: Uint8Array): string {
    let dataString = '';
    for (let i = 0; i < fileData.length; i++) {
      dataString += String.fromCharCode(fileData[i]);
    }
    return dataString;
  }

  private static base64ToUint8Array(str: string): Uint8Array {
    return new util.Base64Helper().decodeSync(str);
  }

  private static uint8ArrayToBase64(fileData: Uint8Array): string {
    return new util.Base64Helper().encodeToStringSync(fileData);
  }

  private static getAesGenerateProperties(): huks.HuksParam[] {
    const properties: huks.HuksParam[] = [];
    let index = 0;
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT |
      huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_NONE
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
      value: huks.HuksCipherMode.HUKS_MODE_GCM
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
      value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_CE
    };
    return properties;
  }

  private static getAesEncryptProperties(aad: Uint8Array, nonce: Uint8Array): Array<huks.HuksParam> {
    const properties: huks.HuksParam[] = [];
    let index = 0;
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_NONE
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
      value: huks.HuksCipherMode.HUKS_MODE_GCM
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_NONCE,
      value: nonce
    };
    // AAD 如果有AAD数据，则加密和解密时必须提供相同的AAD数据
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA,
      value: aad
    };
    const aead = GcmUtil.generateAead();
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AE_TAG,
      value: aead
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
      value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_CE
    };
    return properties;
  }

  /**
   * 生成AAD
   */
  private static generateAad(): Uint8Array {
    const aad = GcmUtil.gen(AAD_LENGTH);
    if (aad?.length !== AAD_LENGTH) {
      const msg = `generateAad aad length is ${aad?.length} illegal`;
      throw {
        code: ErrorCode.ILLEGAL_CODE,
        message: msg,
        name: 'BusinessError'
      };
    }
    return aad;
  }

  /**
   * 生成AEAD
   */
  private static generateAead(): Uint8Array {
    const aead = GcmUtil.gen(AAD_LENGTH);
    if (aead?.length !== AAD_LENGTH) {
      const msg = `generateAead aead length is ${aead?.length} illegal`;
      throw {
        code: ErrorCode.ILLEGAL_CODE,
        message: msg,
        name: 'BusinessError'
      };
    }
    return aead;
  }

  /**
   * 生成Nonce
   */
  private static generateNonce(): Uint8Array {
    const nonce = GcmUtil.gen(NONCE_LENGTH);
    if (nonce?.length !== NONCE_LENGTH) {
      const msg = `generateNonce nonce length is ${nonce?.length} illegal`;
      throw {
        code: ErrorCode.ILLEGAL_CODE,
        message: msg,
        name: 'BusinessError'
      };
    }
    return nonce;
  }

  /**
   * 随机生成AEAD、Nonce、AAD等参数
   *
   * @param len 参数长度
   * @returns 随机生成的参数值
   */
  private static gen(len: number): Uint8Array {
    const rand = cryptoFramework.createRandom();
    rand.setSeed(rand.generateRandomSync(len));
    return rand.generateRandomSync(len).data;
  }

  private static getAesDecryptProperties(cipherData: Uint8Array, aad: Uint8Array, nonce: Uint8Array): huks.HuksParam[] {
    let properties: huks.HuksParam[] = [];
    let index = 0;
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
      value: huks.HuksKeyAlg.HUKS_ALG_AES
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
      value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PURPOSE,
      value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_PADDING,
      value: huks.HuksKeyPadding.HUKS_PADDING_NONE
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
      value: huks.HuksCipherMode.HUKS_MODE_GCM
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_NONCE,
      value: nonce
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_ASSOCIATED_DATA,
      value: aad
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AE_TAG,
      value: cipherData.slice(cipherData.length - AAD_LENGTH)
    };
    properties[index++] = {
      tag: huks.HuksTag.HUKS_TAG_AUTH_STORAGE_LEVEL,
      value: huks.HuksAuthStorageLevel.HUKS_AUTH_STORAGE_LEVEL_CE
    };
    return properties;
  }
}