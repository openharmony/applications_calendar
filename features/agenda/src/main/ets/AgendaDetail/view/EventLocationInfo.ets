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
import { AgendaUtil, BigFontSize, Log } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

const TAG = 'EventLocationInfo';

@Component
export struct EventLocationInfo {
  @Prop mLocation: string = '';

  @Prop mLatitude: number = -1;

  @Prop mLongitude: number = -1;

  @Prop disableCopy: boolean = false;

  @Prop isLongClickPreview: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @LocalStorageLink('uiAbilityContext') context: common.UIAbilityContext | undefined = undefined;

  private onClickHandler: () => void = () => {
  };

  private isPreview: boolean = false;

  build() {
    Row() {
      SymbolGlyph($r('sys.symbol.local'))
        .fontSize(14)
        .margin({ end: LengthMetrics.vp(8) })
        .fontColor([$r('sys.color.icon_secondary')])
        .alignSelf(ItemAlign.Start)
        .flexShrink(1)
      Text(AgendaUtil.getLocation(this.mLocation))
        .fontWeight(FontWeight.Regular)
        .decoration(
          (this.isLongClickPreview || this.isPreview) ?
            { type: TextDecorationType.None, color: $r('sys.color.font_secondary') } :
            { type: TextDecorationType.Underline, color: $r('sys.color.font_secondary') })
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .flexShrink(1)
        .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
        .onClick(() => {
          if (this.isPreview) {
            this.onClickHandler();
          } else {
            if (this.isLongClickPreview) {
              return;
            }
            AgendaUtil.jumpMapLocationInfoPage(this.mLocation, this.mLatitude, this.mLongitude, this.context);
          }
        })
    }
    .onAppear(() => {
      Log.info(TAG, `agenda location row appear`);
    })
    .width('100%')
    .backgroundColor(Color.Transparent)
    .alignSelf(ItemAlign.Start)
  }
}