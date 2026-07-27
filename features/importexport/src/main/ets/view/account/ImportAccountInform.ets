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

const TAG: string = 'ImportAccountInform';

/**
 * 提醒按钮
 *
 */
@Component
export struct ImportAccountInform {
  @StorageLink('themeColor') themeColor: string = '';

  @Link isInform: boolean;

  build() {
    Column() {

      Row() {
        Text($r('app.string.preferences_alerts_title'))
          .fontSize(14)
          .opacity(0.6)
          .align(Alignment.Start)
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({ top: 24, bottom: 8 })
      }
      .padding({ left: 12, right: 12 })
      .height(56)
      .width(328)

      Row() {
        Column() {
          Text($r('app.string.schedule_reminder'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .backgroundColor(Color.Transparent)
        }
        .flexShrink(1)

        Row() {
          Toggle({ type: ToggleType.Switch, isOn: true })
            .selectedColor(this.themeColor)
            .onChange((isOn: boolean) => {
              this.isInform = !this.isInform;
            })
        }
        .flexShrink(0)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .height(56)
      .width(328)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(20)
      .padding({
        top: 4,
        bottom: 4,
        left: 12,
        right: 12
      })
    }
  }
}