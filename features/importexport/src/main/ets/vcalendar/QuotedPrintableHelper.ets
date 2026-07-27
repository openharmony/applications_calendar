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

import { EmptyUtils, Log } from '@app/common';
import util from '@ohos.util';

const TAG = 'QuotedPrintableHelper'

const CR = 13; //回车对应ascII编码
const LF = 10; //换行对应ascII编码
const ESCAPE_CHAR = 61; // '='对应ascII编码
const HEX_NUM = 16; //16进制
const QP_LF_LENGTH = 69; //QP编码需要换行的字符数

/**
 * 支持打印机的编解码helper,双框架分享的日程是这个编码的,编码格式名为Quoted-printable或QP encoding
 */
export class QuotedPrintableHelper {
  private static sInstance: QuotedPrintableHelper | undefined = undefined;

  private constructor() {
  }

  static getInstance(): QuotedPrintableHelper {
    if (!QuotedPrintableHelper.sInstance) {
      QuotedPrintableHelper.sInstance = new QuotedPrintableHelper();
    }
    return QuotedPrintableHelper.sInstance;
  }

  /**
   * 编码可以打印的字符串
   * @param encodeString
   * @param charSet 可能是utf-8 gbk
   * @returns
   */
  encodeQuotedPrintable(encodeString: string, charSet: string): string {
    //校验
    if (EmptyUtils.isEmptyString(encodeString, false)) {
      return '';
    }
    let result: string = '';
    //通过TextEncoder,chars编码,Uint8Array获取编码后的数组
    try {
      let textEncoder: util.TextEncoder = new util.TextEncoder(charSet);
      let buffer: ArrayBuffer = new ArrayBuffer(20);
      let arrayResult: Uint8Array = new Uint8Array(buffer);
      arrayResult = textEncoder.encodeInto(encodeString);
      //将数字数组转换为qp数组,目前采取的是转换所有字符而不是非ascII字符,QP编码中大部分ascII字符为可选转换
      let hexArray: string[] = [];
      for (let i = 0; i < arrayResult.length; i++) {
        hexArray.push('=' + this.NumberToHex(arrayResult[i]));
      }
      //将数组转换为结果集
      let resultStr: string = hexArray.join('');
      //  qp在字符串长度超过70时需要做换行处理,在采取转换所有字符后结果集长度必为3的倍数
      const resultLength = Math.ceil(resultStr.length / QP_LF_LENGTH)
      if (resultLength <= 1) { //如果字符串小于70则无需做后续处理可直接返回结果
        return resultStr;
      }
      let resultArray: string[] = [];
      for (let j = 0; j < resultLength; j++) {
        //通过向后截取一位使每行末尾都是=\r\n的形式
        if (j === resultLength - 1) {
          resultArray.push(resultStr.substring(0, QP_LF_LENGTH));
        } else {
          resultArray.push(resultStr.substring(0, QP_LF_LENGTH) + '=');
        }
        resultStr = resultStr.substring(QP_LF_LENGTH);
      }
      result = resultArray.join('\r\n');
    } catch (err) {
      Log.logErrorMsg(TAG, 'encodeQuotedPrintable', err);
    }

    return result;
  }

  /**
   * 解码可以打印的字符串
   * @param encodeString
   * @param charSet 可能是utf-8 gbk
   * @returns
   */
  decodeQuotedPrintable(encodeString: string, charSet: string): string {
    //校验
    if (EmptyUtils.isEmptyString(encodeString, false)) {
      return '';
    }
    let result: string = '';
    try {
      const strLength: number = encodeString.length;
      let numbers: number[] = []; //用于存储的字符数组
      //循环遍历字符串
      for (let i = 0; i < strLength; i++) {
        const charNum: number = encodeString.charCodeAt(i); //字符串当前字符对应的ascII码
        if (charNum === ESCAPE_CHAR) { //如果是=号,则匹配=号后两位字符进行转换
          try {
            //qp默认换行,跳过
            if (encodeString.charCodeAt(i + 1) === CR && encodeString.charCodeAt(i + 2) === LF) {
              i += 2;
              continue;
            }
            //获取转换后的16进制二位字符并转换成对应数字
            const hexStr = encodeString.charAt(i + 1) + encodeString.charAt(i + 2);
            const hexNumber = this.HexToNumber(hexStr);
            numbers.push(hexNumber);
            i += 2;
          } catch (err) {
            Log.error(TAG, `decode error e: ${err} ;nowIndex ${i}, encodeString encodeString`);
            return result;
          }
        } else {
          //非=号则为ascII内字符无需处理
          numbers.push(charNum);
        }
      }
      //为0时不需要后续处理
      if (EmptyUtils.isEmptyArray(numbers)) {
        return result;
      }
      //通过TextDecoder和Uint8Array以及charSet将QP字符串转换成文字
      let textDecoder: util.TextDecoder = util.TextDecoder.create(charSet)
      let numberArray: Uint8Array = new Uint8Array(numbers);
      result = textDecoder.decodeWithStream(numberArray);
    } catch (err) {
      Log.logErrorMsg(TAG, 'decodeQuotedPrintable', err);
    }
    return result;
  }

  /**
   * 将数字转换为16进制的二位字符
   * @param sourceNumber
   * @returns
   */
  NumberToHex(sourceNumber: number): string {
    const hexString = (sourceNumber & 0xFF).toString(HEX_NUM).toUpperCase();
    return sourceNumber < HEX_NUM ? '0' + hexString : hexString;
  }

  /**
   * 将十六进制字符转换为数字
   * @param sourceHex
   * @returns
   */
  HexToNumber(sourceHex: string): number {
    try {
      return Number('0x' + sourceHex);
    } catch (err) {
      Log.logErrorMsg(TAG, 'convert hex string error', err);
      return 0;
    }
  }
}




