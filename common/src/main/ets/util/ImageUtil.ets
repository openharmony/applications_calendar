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

import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import lazy { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Log } from '../default/common/Log';
import { CustomColors } from '@kit.ArkUI';
import { showToast } from './PromptActionUtils';

const MB_BYTES = 1024 * 1024;
const FILE_MAX_SELECTED_SIZE: number = 1;
const DEFAULT_COLOR: string = '#F76045';

class PhotoPickerThemeColor implements CustomColors {
  public brand: string = DEFAULT_COLOR; // 输入光标和选中底色
  public backgroundEmphasize: string = DEFAULT_COLOR; // 强调按钮背景板颜色
}

const resizeWidth = 10000;
const resizeHeight = 10000;
/**
 * 图片工具类
 *
 */

const TAG = 'ImageUtil';

export class ImageUtil {

  /**
   * @params maxImageSize 图片大小，单位: MB; eg: maxImageSize = 2,则实际大小为：2 * 1024 * 1024
   * 1、拉起picker
   * 2、解析成PixelMap对象返回
   */
  public static async getPhotoImagePixelMap(maxImageSize: number = 20):
    Promise<image.PixelMap | undefined> {
    const maxFileSize = maxImageSize * MB_BYTES;
    const fileSizeFilter = new photoAccessHelper.FileSizeFilter();
    fileSizeFilter.filterOperator = 3;
    fileSizeFilter.fileSize = maxFileSize;
    let data = await ImageUtil.openPhotoPicker(fileSizeFilter);
    if (!data) {
      Log.error(TAG, `get undefined from PhotoPicker.`);
      return undefined;
    }
    // 图片太大，提示错误
    const imageFileSize = data.byteLength;
    Log.info(TAG, `imageFileSize：${imageFileSize}`);
    if (imageFileSize > maxFileSize) {
      showToast(`仅支持上传${maxImageSize}M以内的图片`); // TODO 翻译
      return undefined;
    }
    let pixelMap = await ImageUtil.getPixelMap(data);
    if (pixelMap === undefined) {
      return pixelMap;
    }
    return await ImageUtil.resizePixelMap(pixelMap, resizeWidth, resizeHeight);
  }

  /**
   * 拉起picker，读取图片ArrayBuffer
   *
   */
  public static async openPhotoPicker(
          fileSizeFilter: photoAccessHelper.FileSizeFilter): Promise<ArrayBuffer | undefined> {
    let uri = '';
    let file: fs.File | undefined = undefined;
    try {
      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = FILE_MAX_SELECTED_SIZE;
      photoSelectOptions.fileSizeFilter = fileSizeFilter;
      photoSelectOptions.themeColor = new PhotoPickerThemeColor();
      let photoPicker = new photoAccessHelper.PhotoViewPicker();
      let photoSelectResult = await photoPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris?.length > 0) {
        uri = photoSelectResult.photoUris[0];
      }
      Log.info(TAG, `getPicturesUri: ${uri.length}`);

      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      let stat = await fs.stat(file.fd);
      let size = stat.size;
      Log.info(TAG, `img size: ${size}`);
      let data = new ArrayBuffer(size);
      fs.readSync(file.fd, data);
      // 业务侧暂不做压缩
      return data;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getPicturesUri', err);
    } finally {
      if (file) {
        fs.closeSync(file);
      }
    }
    return undefined;
  }

  /**
   * arrayBuffer转换为PixelMap
   *
   */
  public static async getPixelMap(buffer: ArrayBuffer): Promise<image.PixelMap | undefined> {
    let pixelMap: image.PixelMap | undefined = undefined;
    const imageSource: image.ImageSource = image.createImageSource(buffer);
    try {
      Log.info(TAG, `createImageSource`);
      pixelMap = await imageSource?.createPixelMap();
      Log.info(TAG, `createPixelMap success`);
    } catch (err) {
      Log.logErrorMsg(TAG, `getPixelMap error, buffer: ${buffer.byteLength}`, err);
    } finally {
      imageSource?.release();
    }
    return pixelMap;
  }

  /**
   * 重置图像信息尺寸,等比例缩放至宽或高为10000
   */
  public static async resizePixelMap(sourcePixelMap: image.PixelMap, resizeWidth: number,
                                     resizeHeight: number): Promise<image.PixelMap | undefined> {
    const size = await ImageUtil.getImageSize(sourcePixelMap);
    if (size === undefined) {
      return undefined;
    }
    let height = size.height;
    let width = size.width;
    if (height > resizeHeight || width > resizeWidth) {
      Log.info(TAG, `Image size overlimit, height: ${height}, width: ${width}`)
      let scaleSize = 1;
      if (height > width) {
        scaleSize = resizeHeight / height;
        height = resizeHeight;
        width = width * scaleSize;
      } else {
        scaleSize = resizeWidth / width;
        width = resizeWidth;
        height = height * scaleSize;
      }
      await sourcePixelMap.scale(scaleSize, scaleSize);
    }
    return sourcePixelMap;
  }

  /**
   * 获取图片size
   * @param pixelMap
   * @returns
   */
  public static async getImageSize(pixelMap: image.PixelMap): Promise<image.Size | undefined> {
    if (pixelMap === undefined) {
      return undefined;
    }
    try {
      const imageInfo = await pixelMap.getImageInfo();
      if (imageInfo === undefined) {
        return undefined;
      }
      return imageInfo.size;
    } catch (error) {
      Log.error(TAG, `Failed to obtain the image pixel map information, message is ${error.message}`);
      return undefined;
    }
  }

}

/**
 * Common constants for image compress
 */
export class ImageCompressConstants {
  /**
   * Maximum value of the picture quality range.
   */
  public static readonly PICTURE_QUALITY_MAX: number = 100;

  /**
   * Least dichotomous unit.
   */
  public static readonly DICHOTOMY_ACCURACY: number = 10;

  /**
   * Image zoom-out times.
   */
  public static readonly REDUCE_SCALE: number = 0.4;

  /**
   * Separation distance.
   */
  public static readonly SPACE_TEN: number = 10;

  /**
   * Byte conversion.
   */
  public static readonly BYTE_CONVERSION: number = 1024;
}

/**
 * Animate the execution of a function
 * @param fn：Callback functions to be executed within the animation, usually fn will change the state variable
 * @param duration：Animation duration
 * @param curve：Animation area line
 */
export function runWithAnimation(
  fn: () => void,
  duration: number = 300, // Scale the duration of the animation
  curve: Curve = Curve.Smooth): void {
  const uiContext: UIContext | undefined = AppStorage.get('uiContext');
  uiContext?.animateTo({ duration: duration, curve: curve }, () => {
    fn();
  });
}