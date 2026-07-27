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

import { WindowSizeManager } from '@app/common';
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ImageCompressConstants, ImageUtil, runWithAnimation } from '@app/common/src/main/ets/util/ImageUtil';
import { image } from '@kit.ImageKit';

export default function ImageUtilTest() {
  describe('ImageUtilTest', () => {
    let windowSizeManager = WindowSizeManager.getInstance();
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('getPhotoImagePixelMapTest_01', 0, async () => {
      const openPhotoPicker : Function = mocker.mockFunc(ImageUtil, ImageUtil.openPhotoPicker);
      when(openPhotoPicker)(ArgumentMatchers.any).afterReturn(undefined);

      let data = await ImageUtil.getPhotoImagePixelMap();

      expect(data).assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.openPhotoPicker);
    });

    it('getPhotoImagePixelMapTest_02', 0, async () => {
      const openPhotoPicker : Function = mocker.mockFunc(ImageUtil, ImageUtil.openPhotoPicker);
      when(openPhotoPicker)(ArgumentMatchers.any).afterReturn(1);
      const getPixelMap : Function = mocker.mockFunc(ImageUtil, ImageUtil.getPixelMap);
      when(getPixelMap)(ArgumentMatchers.any).afterReturn(undefined);

      let data = await ImageUtil.getPhotoImagePixelMap();

      expect(data).assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.openPhotoPicker);
      mocker.ignoreMock(ImageUtil, ImageUtil.getPixelMap);
    });

    it('getPhotoImagePixelMapTest_03', 0, async () => {
      const openPhotoPicker : Function = mocker.mockFunc(ImageUtil, ImageUtil.openPhotoPicker);
      when(openPhotoPicker)(ArgumentMatchers.any).afterReturn(1);
      const getPixelMap : Function = mocker.mockFunc(ImageUtil, ImageUtil.getPixelMap);
      when(getPixelMap)(ArgumentMatchers.any).afterReturn(111);
      const resizePixelMap : Function = mocker.mockFunc(ImageUtil, ImageUtil.resizePixelMap);
      when(resizePixelMap)(ArgumentMatchers.any).afterReturn(222);

      let data = await ImageUtil.getPhotoImagePixelMap();

      expect(data).assertEqual(222);
      mocker.ignoreMock(ImageUtil, ImageUtil.openPhotoPicker);
      mocker.ignoreMock(ImageUtil, ImageUtil.getPixelMap);
      mocker.ignoreMock(ImageUtil, ImageUtil.resizePixelMap);
    });

    it('getPixelMapTest_01', 0, async () => {
      let data = await ImageUtil.getPixelMap(new ArrayBuffer(100));
      expect(data).assertUndefined();
    });

    it('resizePixelMapTest_01', 0, async () => {
      let pixelMap = { } as image.PixelMap;
      const getImageSize : Function = mocker.mockFunc(ImageUtil, ImageUtil.getImageSize);
      when(getImageSize)(ArgumentMatchers.any).afterReturn(undefined);

      let data = await ImageUtil.resizePixelMap(pixelMap, 100, 100);
      expect(data).assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.getImageSize);
    });

    it('resizePixelMapTest_02', 0, async () => {
      let pixelMap = {
        scale(x: number, y: number): Promise<void> {
          return new Promise<void>((resolve) => {
            resolve();
          });
        }
      } as image.PixelMap;

      let size = {height: 100, width: 100} as image.Size;
      const getImageSize : Function = mocker.mockFunc(ImageUtil, ImageUtil.getImageSize);
      when(getImageSize)(ArgumentMatchers.any).afterReturn(size);

      let data = await ImageUtil.resizePixelMap(pixelMap, 50, 100);
      expect(data).not().assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.getImageSize);
    });

    it('resizePixelMapTest_03', 0, async () => {
      let pixelMap = {
        scale(x: number, y: number): Promise<void> {
          return new Promise<void>((resolve) => {
            resolve();
          });
				}
      } as image.PixelMap;

      let size = {height: 100, width: 100} as image.Size;
      const getImageSize : Function = mocker.mockFunc(ImageUtil, ImageUtil.getImageSize);
      when(getImageSize)(ArgumentMatchers.any).afterReturn(size);

      let data = await ImageUtil.resizePixelMap(pixelMap, 100, 50);
      expect(data).not().assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.getImageSize);
    });

    it('getImageSize_01', 0, async () => {
      let pixelMap = { } as image.PixelMap;

      const getImageInfo : Function = mocker.mockFunc(pixelMap, pixelMap.getImageInfo);
      when(getImageInfo)(ArgumentMatchers.any).afterThrow('mock');

      let data = await ImageUtil.getImageSize(pixelMap);
      expect(data).assertUndefined();
      mocker.ignoreMock(ImageUtil, ImageUtil.getImageSize);
    });

    it('ImageCompressConstantsTest_01', 0, () => {
      expect(ImageCompressConstants.PICTURE_QUALITY_MAX).assertEqual(100);
      expect(ImageCompressConstants.DICHOTOMY_ACCURACY).assertEqual(10);
      expect(ImageCompressConstants.REDUCE_SCALE).assertEqual(0.4);
      expect(ImageCompressConstants.SPACE_TEN).assertEqual(10);
      expect(ImageCompressConstants.BYTE_CONVERSION).assertEqual(1024);
    });

    it('runWithAnimationTest_01', 0, () => {
      let start = 0;
      runWithAnimation(() => {
        start = 100;
      });

      expect(start).assertEqual(100);
    });

  });
}