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
import util from '@ohos.util';
import fileIo from '@ohos.file.fs';
import { Log } from '../default/common/Log';
import { UTF_8 } from './CharsetUtil';
import { EmptyUtils } from './EmptyUtils';
import { Result } from '../templates/Result';
import { fileUri, WriteOptions } from '@kit.CoreFileKit';
import { common, wantConstant } from '@kit.AbilityKit';
// import lazy { filePreview } from '@kit.PreviewKit'; // PreviewKit 注释
import { DeviceConfig } from '../data/DeviceConfig';
import { GlobalThis } from '../data/GlobalThis';
import { EXT_VS_MIME_DICT, FileThumbnailType } from './FileConst';
//import lazy { fileManagerService } from '@kit.FileManagerServiceKit';

const TAG = 'FileUtils';

export class FileUtils {
  // GB 1024 * 1024 * 1024
  public static readonly GB: number = 1073741824;
  // MB 1024 * 1024
  public static readonly MB: number = 1048576;
  // KB 1024
  public static readonly KB: number = 1024;
  public static readonly UNKNOWN_FILE_TYPE = 'unknown';

  /**
   * 获取文件大小,单位bytes
   *
   * @param {string} filePath - filePath as the absolute path to the target file.
   * @return {number} - 文件大小 -1 表示异常
   */
  static getFileSize(filePath: string): number {
    if (!FileUtils.isFile(filePath)) {
      Log.warn(TAG, `getFileSize filePath not file`);
      return -1;
    }
    try {
      const state: fileIo.Stat = fileIo.statSync(filePath);
      return state.size;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getFileSize filePath', err);
      return -1;
    }
  }

  /**
   * Read String from disk by bundleName.
   *
   * @param {string} filePath - filePath as the absolute path to the target file.
   * @return {string} - read string from file
   */
  static getStringFromFile(filePath: string): string {
    let readStreamSync: fileIo.Stream | null = null;
    try {
      readStreamSync = fileIo.createStreamSync(filePath, 'r');
      const content: string = FileUtils.getStringContent(readStreamSync);
      return content;
    } catch (err) {
      Log.warn(TAG, `readStringFromFile error: ${err?.message}`);
      return '';
    } finally {
      if (readStreamSync) {
        readStreamSync.closeSync();
      }
    }
  }


  /**
   * 调用readTextSync api 操作非应用自己的沙箱文件会抛No such file or directory
   * @param fileUri
   * @returns
   */
  static getStringByReadSync(fileUri: string): string {
    const EACH_LENGTH: number = 4096;
    let srcFile: fileIo.File | undefined = undefined;
    try {
      const bufArray: ArrayBuffer[] = [];
      let totalLength: number = 0;
      srcFile = fileIo.openSync(fileUri, fileIo.OpenMode.READ_ONLY);
      let buf: ArrayBuffer = new ArrayBuffer(EACH_LENGTH);
      let len: number = fileIo.readSync(srcFile?.fd, buf);
      while (len != 0) {
        totalLength += len;
        if (len < EACH_LENGTH) {
          buf = buf.slice(0, len);
          bufArray.push(buf);
          break;
        }
        bufArray.push(buf);
        buf = new ArrayBuffer(EACH_LENGTH);
        len = fileIo.readSync(srcFile?.fd, buf);
      }
      const contentBuf = new Uint8Array(totalLength);
      let offset = 0;
      for (const bufArr of bufArray) {
        const uInt8Arr = new Uint8Array(bufArr);
        contentBuf.set(uInt8Arr, offset);
        offset += uInt8Arr.byteLength;
      }
      let textDecoder = util.TextDecoder.create(UTF_8, { ignoreBOM: true });
      const content = textDecoder.decodeWithStream(contentBuf, { stream: false });
      return content;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getStringByReadSync', err);
      return '';
    } finally {
      if (srcFile) {
        fileIo.closeSync(srcFile);
      }
    }
  }

  /**
   * Write string to a file.
   *
   * @param {string} str - target string will be written to file.
   * @param {string} filePath - filePath as the absolute path to the target file.
   */
  static putStringToFile(str: string, filePath: string): boolean {
    Log.debug(TAG, 'writeStringToFile start execution');
    let writeStreamSync: fileIo.Stream | null = null;
    try {
      writeStreamSync = fileIo.createStreamSync(filePath, 'w+');
      let number: number = writeStreamSync.writeSync(str);
      Log.debug(TAG, 'writeStringToFile number: ' + number);
      return true;
    } catch (err) {
      Log.warn(TAG, `writeStringToFile error: ${err?.message}`);
      return false;
    } finally {
      if (writeStreamSync) {
        writeStreamSync.closeSync();
      }
      Log.debug(TAG, 'writeStringToFile close sync');
    }
  }

  static putBytesToFile(bytes: ArrayBuffer, filePath: string, charset?: string): boolean {
    let writeStreamSync: fileIo.Stream | undefined = undefined;
    try {
      writeStreamSync = fileIo.createStreamSync(filePath, 'w+');
      const options: WriteOptions | undefined = charset ? { encoding: charset } : undefined;
      let num: number = writeStreamSync.writeSync(bytes, options);
      Log.debug(TAG, 'writeStringToFile number: ' + num);
      return num > 0;
    } catch (err) {
      Log.logErrorMsg(TAG, 'writeStringToFile', err);
      return false;
    } finally {
      if (writeStreamSync) {
        writeStreamSync.closeSync();
      }
      Log.debug(TAG, 'writeStringToFile close sync');
    }
  }

  /**
   * Read JSON object from a file.
   *
   * @param {object} readStreamSync - stream of target file
   * @return {object} - object read from file stream
   */
  static getStringContent(readStreamSync: fileIo.Stream): string {
    const READ_DATA_SIZE = 4096;
    const bufArray: ArrayBuffer[] = [];
    let totalLength: number = 0;
    let buf: ArrayBuffer = new ArrayBuffer(READ_DATA_SIZE);
    let len: number = readStreamSync.readSync(buf);
    while (len != 0) {
      totalLength += len;
      if (len < READ_DATA_SIZE) {
        buf = buf.slice(0, len);
        bufArray.push(buf);
        break;
      }
      bufArray.push(buf);
      buf = new ArrayBuffer(READ_DATA_SIZE);
      len = readStreamSync.readSync(buf);
    }
    Log.debug(TAG, `getContent read finished: ${totalLength}`);
    const contentBuf = new Uint8Array(totalLength);
    let offset = 0;
    for (const bufArr of bufArray) {
      const uInt8Arr = new Uint8Array(bufArr);
      contentBuf.set(uInt8Arr, offset);
      offset += uInt8Arr.byteLength;
    }
    let textDecoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
    const content = textDecoder.decode(contentBuf, { stream: false });
    return content;
  }

  static copyDir(srcDir: string, dstDir: string): boolean {
    try {
      fileIo.copyDirSync(srcDir, dstDir);
      Log.debug(TAG, 'copyDir success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'copyDir', err);
      return false;
    }
  }

  static copyFileFromSrcToDes(srcPath: string, dstPath: string, model?: number): boolean {
    try {
      fileIo.copyFileSync(srcPath, dstPath, model);
      Log.debug(TAG, 'copyFile success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'copyFileFromSrcToDes', err);
      return false;
    }
  }

  static isDir(path: string): boolean {
    if (!FileUtils.isFileExist(path)) {
      return false;
    }
    try {
      const state: fileIo.Stat = fileIo.statSync(path);
      return state.isDirectory();
    } catch (err) {
      Log.logErrorMsg(TAG, 'isDir error', err);
      return false;
    }
  }

  static isFile(path: string): boolean {
    if (!FileUtils.isFileExist(path)) {
      return false;
    }
    try {
      const state: fileIo.Stat = fileIo.statSync(path);
      return state.isFile();
    } catch (err) {
      Log.logErrorMsg(TAG, 'isFile error', err);
      return false;
    }
  }

  static deleteFile(path: string): boolean {
    try {
      fileIo.unlinkSync(path);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'deleteFile', err);
    }
    return false;
  }

  static deleteDir(path: string): boolean {
    try {
      fileIo.rmdirSync(path);
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'deleteDir', err);
    }
    return false;
  }

  static deleteChildren(path: string): boolean {
    const children = FileUtils.getChildFiles(path);
    if (EmptyUtils.isEmptyArray(children)) {
      return true;
    }
    let deleteTotal: boolean = true;
    for (let child of children) {
      const childPath = path + '/' + child;
      const deleteResult = FileUtils.isFile(childPath)
        ? FileUtils.deleteFile(childPath) : FileUtils.deleteDir(childPath);
      if (!deleteResult) {
        Log.warn(TAG, `deleteChildren path fail`);
        deleteTotal = false;
      }
    }
    return deleteTotal;
  }

  static createFileSync(path: string): boolean {
    if (FileUtils.isFileExist(path) && FileUtils.isFile(path)) {
      Log.debug(TAG, `createFileSync file is exist`);
      return true;
    }
    if (FileUtils.isFileExist(path) && !FileUtils.isFile(path)) {
      Log.warn(TAG, `createFileSync file is exist but is dir`);
      return false;
    }
    let randomAccessFile: fileIo.RandomAccessFile | null = null;
    try {
      randomAccessFile = fileIo.createRandomAccessFileSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      Log.info(TAG, 'createFileSync success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'createFileSync', err);
      return false;
    } finally {
      randomAccessFile?.close();
    }
  }

  static mkdirSync(path: string, recursion: boolean = false): boolean {
    if (FileUtils.isFileExist(path) && FileUtils.isDir(path)) {
      Log.debug(TAG, `mkdirSync is exist`);
      return true;
    }
    if (FileUtils.isFileExist(path) && !FileUtils.isDir(path)) {
      Log.warn(TAG, `mkdirSync is exist but is not dir`);
      return false;
    }
    try {
      fileIo.mkdirSync(path, recursion);
      Log.info(TAG, 'mkdirSync success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'mkdirSync', err);
      return false;
    }
  }


  /**
   * Check if the file exists.
   *
   * @param {string} filePath - filePath as the absolute path to the target file.
   * @return {boolean} - boolean true(Exist)
   */
  static isFileExist(filePath: string): boolean {
    try {
      return fileIo.accessSync(filePath);
    } catch (err) {
      Log.logErrorMsg(TAG, 'isFileExist', err);
      return false;
    }
  }

  static async rename(oldPath: string, newPath: string): Promise<Result<boolean>> {
    try {
      await fileIo.rename(oldPath, newPath);
      return Result.buildSuccessResult(true);
    } catch (error) {
      Log.logErrorMsg(TAG, 'rename', error);
      return Result.buildByErrorWithData(error, false);
    }
  }

  static moveFileFromSrcToDes(srcPath: string, dstPath: string): boolean {
    try {
      fileIo.moveFileSync(srcPath, dstPath);
      Log.debug(TAG, 'moveFile success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'moveFileFromSrcToDes', err);
      return false;
    }
  }

  static getChildFiles(path: string): string[] {
    try {
      return fileIo.listFileSync(path);
    } catch (err) {
      Log.logErrorMsg(TAG, 'getFileList', err);
      return [];
    }
  }

  /**
   * 文件系统下对与  / \ " : | * ? < > 等字符会为文件名时导致创建文件夹或文件失败
   * @param srcPath
   * @returns
   */
  static getCleanFileName(srcPath: string): string {
    if (EmptyUtils.isEmptyString(srcPath, true)) {
      return '';
    }
    const regex = new RegExp('[\'\<\>\|\:\\\\\"\*\?\/]', 'g');
    return srcPath.replace(regex, '');
  }

  public static getFileNameByURI(uri: string) {
    return decodeURIComponent(uri).split('/').pop() ?? '';
  }

  /**
   * 根据文件名返回对应的缩略图
   */
  public static getThumbnailByFileInfo(fileName: string): Resource {
    let resource: Resource = $r('app.media.ic_normal_unknown');
    let fileExtension = FileUtils.getFileExtension(fileName);
    if (!fileExtension) {
      Log.info(TAG, `getThumbnailByFileInfo fileExtension is undefined`);
      return resource;
    }
    let fileType: string = FileThumbnailType[fileExtension];
    if (!fileType) {
      fileType = FileUtils.UNKNOWN_FILE_TYPE;
    }
    try {
      //resource = fileManagerService.getFileIconSync(fileType) as Resource;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getThumbnailByFileInfo', err)
    }
    return resource;
  }

  /**
   * 根据文件名获取文件后缀
   */
  private static getFileExtension(fileName: string): string | undefined {
    return fileName?.split('.')?.pop()?.toLowerCase();
  }

  /**
   * 将文件大小转化成string类型,文件大小单位:B
   */
  public static sizeConversion(size: number): string {
    let fileSize = 0;
    if (size >= FileUtils.GB) {
      fileSize = size / FileUtils.GB;
      return fileSize.toFixed(2) + ' GB';
    } else if (size >= FileUtils.MB) {
      fileSize = size / FileUtils.MB;
      return fileSize.toFixed(2) + ' MB';
    } else if (size >= FileUtils.KB) {
      fileSize = size / FileUtils.KB;
      return fileSize.toFixed(2) + ' KB';
    } else {
      return size + ' B';
    }
  }

  /**
   * 附件预览
   */
  public static async previewAttachment(context: common.UIAbilityContext,
                                        contentUri: string | undefined, fileName: string | undefined,
    mimeType: string = ''): Promise<boolean> {
    if (!contentUri || !fileName) {
      Log.warn(TAG, 'attachment is empty');
      return false;
    }
    // PreviewKit 注释 - start (canPreview/openPreview 依赖 @kit.PreviewKit)
    // let canPreview = await FileUtils.canPreview(context, contentUri);
    // PreviewKit 注释 - end
    if (DeviceConfig.instance().config.needCommerce) {
      Log.info(TAG, 'do preview by ApplicationPicker');
      // 如果文件预览支持预览，则拉起应用选择器，不强制弹窗选择应用，否则强制弹窗选择应用
      FileUtils.openApplicationPicker(context, contentUri, mimeType, fileName, true);
      return true;
    }
    // PreviewKit 注释 - start
    // if (canPreview) {
    //   Log.info(TAG, 'do preview by openPreview');
    //   await FileUtils.openPreview(context, fileName, contentUri, mimeType);
    //   return true;
    // }
    // PreviewKit 注释 - end
    // 拉起应用选择器
    FileUtils.openApplicationPicker(context, contentUri, mimeType, fileName, true);
    return true;
  }

  /**
   * 拉起应用选择器 showDefaultPicker true时强制拉起选择器界面
   */
  public static openApplicationPicker(context: common.UIAbilityContext, path: string, mimeType: string, fileName: string,
                                      showDefaultPicker: boolean = true): void {
    if (!context) {
      Log.warn(TAG, `openApplicationPicker context null`);
      return;
    }
    const uri = fileUri.getUriFromPath(path);
    let wantInfo: Want = {
      action: 'ohos.want.action.viewData',
      uri: uri,
      type: EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE] === mimeType ? '' : mimeType,
      flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
      parameters: {
        fileName: fileName,
        'ability.params.stream': [uri],
        'ohos.ability.params.showDefaultPicker': showDefaultPicker
      }
    };
    context?.startAbility(wantInfo).then(() => {
      Log.info(TAG, 'openApplicationPicker startAbility Success');
    }).catch((err: Error) => {
      Log.logErrorMsg(TAG, `openApplicationPicker Failed to startAbility`, err);
    });
  }

  // PreviewKit 注释 - start
  // /**
  //  * 判断是否能预览
  //  */
  // public static async canPreview(context: common.UIAbilityContext, uri: string): Promise<boolean> {
  //   let result = false;
  //   if (!context) {
  //     Log.warn(TAG, `canPreview context null`);
  //     return false;
  //   }
  //   try {
  //     result = await filePreview.canPreview(context, fileUri.getUriFromPath(uri));
  //   } catch (err) {
  //     Log.logErrorMsg(TAG, `canPreview`, err);
  //     return result;
  //   }
  //   return result;
  // }

  // /**
  //  * 预览实现
  //  */
  // public static async openPreview(context: common.UIAbilityContext,
  //                                 fileName: string, uri: string, mimeType: string): Promise<void> {
  //   if (!context) {
  //     Log.warn(TAG, `openPreview context null`);
  //     return;
  //   }
  //   let displayInfo: filePreview.DisplayInfo = {
  //     x: 100,
  //     y: 100,
  //   };
  //   uri = fileUri.getUriFromPath(uri);
  //   let fileInfo: filePreview.PreviewInfo = {
  //     title: fileName,
  //     uri: uri,
  //     mimeType: EXT_VS_MIME_DICT[FileUtils.UNKNOWN_FILE_TYPE] === mimeType ? '' : mimeType
  //   };
  //   try {
  //     await filePreview.openPreview(context, fileInfo, displayInfo);
  //     Log.info(TAG, `openPreview success`);
  //   } catch (err) {
  //     Log.logErrorMsg(TAG, `openPreview`, err);
  //   }
  // }
  // PreviewKit 注释 - end

  /**
   * 外部传入路径合法性校验，防止路径注入，日志注入(进行一次uri解码后判断，防止编码绕过)
   *
   * @param filePath 待检查的文件路径
   * @returns  合法：true 不合法：false
   */
  public static isTrustedPath(filePath: string): boolean {
    if (filePath == '') {
      return true;
    }
    // 防止编码绕过
    const decodedPath = decodeURIComponent(filePath) ?? '';
    const pathTraversalPattern = /(\.\/|\.\.\/|\.\\\.\\)/i;
    const controlCharPattern = /[\b\n\v\f\r\x7f\0]/;
    if (pathTraversalPattern.test(decodedPath) || controlCharPattern.test(decodedPath) || decodedPath.includes('*') ||
    decodedPath.endsWith('/..')) {
      Log.error(TAG, "file path can't contains *、./、../、.\\.\\、%00、%08、%0a、%0b、%0c、%0d、%7f !");
      return false;
    }
    return true;
  }
}