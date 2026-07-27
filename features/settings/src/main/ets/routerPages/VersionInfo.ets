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

import { BigFontSize, DeviceConfig, FontSizeScaleUtils, Log } from '@app/common';
import { bundleManager } from '@kit.AbilityKit';

const TAG = 'VersionInfo';
@Component
export struct VersionInfo {
  @State versionName: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private async getsVersion() {

    try {
      const bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.versionName = bundleInfo.versionName;
      Log.info(TAG, 'Calendar version: ' + this.versionName);
    } catch (error) {
      Log.logErrorMsg(TAG, 'getsVersion', error);
    }
  }

  aboutToAppear(): void {
    this.getsVersion();
  }

  build() {
    Row() {
      Column() {
        Text($r('app.string.version_info'))
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .maxLines(2)
        Text(this.versionName)
          .fontSize(14)
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 2 })
      }
      .accessibilityGroup(true)
      .flexShrink(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 8 })
    }
    .constraintSize({
      minHeight: this.needCommerce ? 56 : 64
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      right: $r('sys.float.padding_level4'),
      left: $r('sys.float.padding_level4')
    })
    .borderRadius($r('sys.float.corner_radius_level7'))
    .stateStyles({
      normal: {
        .backgroundColor($r('app.color.default_background'))
      }
    })
    .hoverEffect(HoverEffect.None)
  }
}