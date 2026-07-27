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

import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { image } from '@kit.ImageKit';
import { photoAccessHelper as photo } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import effectKit from '@ohos.effectKit';
import fs from '@ohos.file.fs';
import { componentSnapshot, componentUtils } from '@kit.ArkUI';

const TAG: string = 'CardImageUtil';

/**
 * 卡片图片工具类
 * 含选取图片、生成PixelMap、保存PixelMap、获取图片路径、获取图片fd等
 */
export class ImageUtils {
  public static getImportantImagePath(path: string): string {
    if (!path || path.length === 0) {
      Log.warn(TAG, 'getImportantImagePath get invalid params');
      return '';
    }
    const context = GlobalThis.getInstance().getBasicContext();
    if (!context) {
      Log.warn(TAG, 'getImportantImagePath get invalid context');
      return '';
    }
    const fileDir = context.getApplicationContext().filesDir;
    const customizeImgPath = `${fileDir}/customizeImg`;
    if (!FileUtils.isFileExist(customizeImgPath)) {
      FileUtils.mkdirSync(customizeImgPath);
    }
    return `${customizeImgPath}/${path}`;
  }

  // 这里获取了文件句柄之后,直接交给了页面侧使用加载
  public static getImageFdByPath(path: string): number {
    if (!path || path.length === 0) {
      Log.warn(TAG, 'getImageFdByPath get invalid path');
      return 0;
    }
    try {
      const file = fileIo.openSync(path);
      if (!file) {
        Log.warn(TAG, 'getImageFdByPath get invalid file');
        return 0;
      }
      return file.fd;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getImageFdByPath', err);
    }
    return 0;
  }

  public static async selectImage(): Promise<string> {
    const photoSelectOptions = new photo.PhotoSelectOptions();
    photoSelectOptions.MIMEType = photo.PhotoViewMIMETypes.IMAGE_TYPE;
    photoSelectOptions.maxSelectNumber = 1;
    photoSelectOptions.isPreviewForSingleSelectionSupported = false;
    const photoViewPicker = new photo.PhotoViewPicker();
    let uri: string = '';
    try {
      const result: photo.PhotoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (result && result.photoUris && result.photoUris.length > 0) {
        uri = result.photoUris[0];
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'selectImage', err);
    }
    return uri;
  }
  
  /**
   * getImageSourceByPath
   * @param uri 路径
   * @returns 资源
   */
  public static async getPixelMapByUri(path: string, dstWidthVp: number = 1000): Promise<PixelMap | undefined> {
    const URI_PREFIX: string = 'file://';
    const MEDIA_PREFIX: string = 'file://media/';
    if (!path || !(path.startsWith(URI_PREFIX) || path.startsWith('/'))) {
      Log.error(TAG, 'invalid path');
      return undefined;
    }

    const begin = Date.now();
    Log.info(TAG, `begin`);
    let uri: string = path.startsWith(URI_PREFIX) ? path : URI_PREFIX + path;
    let imageSource: image.ImageSource | null | undefined = undefined;
    let fp: fs.File | undefined = undefined;
    let pixelMap: PixelMap | undefined = undefined;
    try {
      if (uri.startsWith(MEDIA_PREFIX)) {
        fp = await fs.open(uri, fs.OpenMode.READ_ONLY);
        if (fp) {
          imageSource = image.createImageSource(fp.fd);
        }
      } else {
        imageSource = image.createImageSource(uri);
      }
      if (!imageSource) {
        Log.info(TAG, `createImageSource failed`);
        return undefined;
      }
      const originalSize = imageSource.getImageInfoSync().size;
      const dstWidth = Math.min(vp2px(dstWidthVp), originalSize.width);
      const dstHeight = dstWidth / originalSize.width * originalSize.height;
      pixelMap = await imageSource.createPixelMap({
        desiredSize: {
          width: dstWidth, height: dstHeight
        }
      });
      await imageSource.release();
    } catch (e) {
      Log.logErrorMsg(TAG, 'get image source error', e);
    } finally {
      ImageUtils.closeFp(fp);
    }
    Log.info(TAG, `end cost ${Date.now() - begin}ms`);
    return pixelMap;
  }

  private static async closeFp(fp: fs.File | undefined): Promise<void> {
    if (fp) {
      try {
        await fs.close(fp);
      } catch (e) {
        Log.logErrorMsg(TAG, 'failed to close the file handle:', e);
      }
    }
  }

  public static getPixelMapByPath(path: string): PixelMap | undefined {
    if (!path) {
      Log.warn(TAG, 'getPixelMapByPath get invalid path');
      return undefined;
    }
    const begin = Date.now();
    const pixelMap = image.createImageSource(path)?.createPixelMapSync();
    Log.info(TAG, `getPixelMapByPath cost ${Date.now() - begin}ms, ${pixelMap}`);
    return pixelMap;
  }

  public static async savePixelMap(pixelMap: PixelMap, path: string): Promise<boolean> {
    if (!pixelMap || !path) {
      Log.warn(TAG, 'savePixelMap get invalid params');
      return false;
    }
    const imageBytes = await ImageUtils.transferPixelMap2Buffer(pixelMap);
    if (!imageBytes) {
      Log.warn(TAG, 'savePixelMap get invalid bytes');
      return false;
    }
    const saveResult = FileUtils.putBytesToFile(imageBytes, path);
    if (!saveResult) {
      Log.warn(TAG, `savePixelMap failed`);
    }
    return saveResult;
  }

  // 图片分割
  public static async clonePixelMap(
    pixelMap: PixelMap,
    areaInfo: AreaInfo
  ): Promise<PixelMap> {
    const xRate = areaInfo.leftEnd - areaInfo.leftStart;
    const yRate = areaInfo.topEnd - areaInfo.topStart;
    if (xRate <= 0 || xRate > 1 || yRate <= 0 || yRate > 1) {
      Log.warn(TAG, 'clonePixelMap get invalid xRate yRate');
      return pixelMap;
    }
    const imageInfo = pixelMap.getImageInfoSync();
    const width = imageInfo.size.width;
    const height = imageInfo.size.height;
    const sizeWidth = Math.floor(width * xRate);
    const sizeHeight = Math.floor(height * yRate);
    const area: image.PositionArea = {
      pixels: new ArrayBuffer(pixelMap.getPixelBytesNumber() * xRate * yRate),
      offset: 0,
      stride: sizeWidth * 4,
      region: {
        x: width * areaInfo.leftStart,
        y: height * areaInfo.topStart,
        size: {
          width: sizeWidth,
          height: sizeHeight
        }
      }
    };

    await pixelMap.readPixels(area);

    const options: image.InitializationOptions = {
      size: {
        width: sizeWidth,
        height: sizeHeight
      }
    };
    // 根据初始化选项和缓冲区数组，生成新PixelMap。
    return image.createPixelMapSync(area.pixels, options);
  }

  // 组件信息
  public static getComponentInfo(componentId: string): ComponentInfo {
    const componentInfo: componentUtils.ComponentInfo = componentUtils.getRectangleById(componentId);
    const size = componentInfo.size;
    const windowOffset = componentInfo.windowOffset;

    return {
      width: px2vp(size.width),
      height: px2vp(size.height),
      x: px2vp(windowOffset.x),
      y: px2vp(windowOffset.y),
    };
  }

  // 组件截图
  public static async snapshot(componentId: string): Promise<PixelMap | undefined> {
    const pixelMap = await componentSnapshot.get(componentId, {
      scale: 2, waitUntilRenderFinished: true
    })
      .catch((err: BusinessError) => {
        Log.logErrorMsg(TAG, 'componentSnapshot error', err);
        return undefined;
      });

    return pixelMap;
  }

  // 图片反色
  public static async getReverseColor(pixelMap: PixelMap): Promise<string> {
    const colorPicker = await effectKit.createColorPicker(pixelMap);
    const color = colorPicker.getLargestProportionColor();
    if (!color) {
      Log.error(TAG, 'getReverseColor getLargestProportionColor error');
      return '';
    }
    const reverseColor = `rgb(${255 - color.red},${255 - color.green},${255 - color.blue})`
    return reverseColor;
  }

  // 图片亮度
  public static async getBrightness(pixelMap: PixelMap): Promise<number> {
    const colorPicker = await effectKit.createColorPicker(pixelMap);
    const color = colorPicker.getLargestProportionColor();
    if (!color) {
      Log.error(TAG, 'getBrightness getLargestProportionColor error');
      return 0;
    }
    const max = Math.max(color.red, color.green, color.blue);
    const bright = max / 255;

    return bright;
  }

  // 将pixelMap转成图片格式
  private static async transferPixelMap2Buffer(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
    return new Promise((resolve, reject) => {
      /**
       * 设置打包参数
       * format：图片打包格式，只支持 jpg 和 webp
       * quality：JPEG 编码输出图片质量
       * bufferSize：图片大小，默认 10M
       */
      let packOpts: image.PackingOption = {
        format: 'image/jpeg', quality: 98
      };
      // 创建ImagePacker实例
      const packer = image.createImagePacker();
      packer.packing(pixelMap, packOpts).then((buffer: ArrayBuffer) => {
        resolve(buffer);
        packer?.release();
      }).catch((err: BusinessError) => {
        reject();
        packer?.release();
      })
    })
  }

  private static async getPhotoAsset(context: Context, uri: string): Promise<photo.PhotoAsset | undefined> {
    try {
      let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo(photo.PhotoKeys.URI, uri);
      let fetchOptions: photo.FetchOptions = {
        fetchColumns: [photo.PhotoKeys.TITLE],
        predicates: predicates
      };
      let phAccessHelper = photo.getPhotoAccessHelper(context);
      let fetchResult: photo.FetchResult<photo.PhotoAsset> = await phAccessHelper.getAssets(fetchOptions);
      let photoAsset: photo.PhotoAsset = await fetchResult.getFirstObject();
      fetchResult.close();
      Log.info(TAG, 'getPhotoAsset successfully');
      return photoAsset;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getPhotoAsset', err);
    }
    return undefined;
  }

  private static async getImageData(context: Context, photoAsset: photo.PhotoAsset): Promise<ArrayBuffer | undefined> {
    return new Promise<ArrayBuffer | undefined>(async (resolve: Function) => {
      try {
        // 请求图片资源数据
        let options: photo.RequestOptions = {
          deliveryMode: photo.DeliveryMode.HIGH_QUALITY_MODE,
        }
        const callback: photo.MediaAssetDataHandler<ArrayBuffer> = {
          onDataPrepared(data: ArrayBuffer) {
            if (!data) {
              Log.warn(TAG, `getImageData get invalid data`);
              resolve(undefined);
              return;
            }
            Log.info(TAG, `getImageData success size=${data.byteLength}`);
            resolve(data);
          }
        }
        const requestId = await photo.MediaAssetManager.requestImageData(context, photoAsset, options, callback);
        Log.info(TAG, `getImageData requestImageData successfully: ${requestId}`);
      } catch (err) {
        Log.error(TAG, `requestImageData getErr: ${err?.code}, ${err?.message}`);
      }
    });
  }
}

export class ComponentInfo {
  public width: number = 150;
  public height: number = 150;
  public x: number = 0;
  public y: number = 0;
}


export class AreaInfo {
  public topStart: number = 0;
  public topEnd: number = 1;
  public leftStart: number = 0;
  public leftEnd: number = 1;
}