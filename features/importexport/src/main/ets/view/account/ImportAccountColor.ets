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
import { AccountColor, AccountUtils,
  BigFontSize,
  DialogControllerOptions, FontSizeScaleUtils, GlobalThis } from '@app/common/index';

const STROKE_WIDTH_UP: number = 7;
const STROKE_WIDTH: number = 4;

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 帐户详情界面——账户信息展示内容
 */
@Component
export struct ImportAccountColor {
  @State isArrowDown: boolean = true;

  @Link calendarColor: number;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 账户可以选择的所有颜色
  private allAccountColor: number[] = [
    AccountColor.RED,
    AccountColor.DARK_ORANGE,
    AccountColor.LIGHT_ORANGE,
    AccountColor.GREEN,
    AccountColor.TURQUOISE,
    AccountColor.PURPLE,
    AccountColor.BLUE
  ];

  /**
   * 颜色选择器组件
   */
  build() {
    Column() {
      Row() {
        Text($r('app.string.selected_color_cvaa'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            14
          ))
          .opacity(0.6)
          .align(Alignment.Start)
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({ top: 24, bottom: 8 })
      }
      .padding({ left: 12, right: 12 })
      .constraintSize({ minHeight: 56 })
      .width('100%')

      Column() {
        Row() {
          Row() {
            Circle()
              .width(20)
              .height(20)
              .fill(this.calendarColor)
            Text(AccountUtils.getAccountColorName(this.calendarColor))
              .fontColor($r('sys.color.font_primary'))
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ left: 12 })
          }

          Blank()

          SymbolGlyph(this.isArrowDown ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
            .margin({ left: 8 })
        }

        .padding({ left: 12, right: 12 })
        .constraintSize({ minHeight: 64 })
        .width('100%')
        .borderRadius(20)
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.interactive_click'))
          },
          normal: {
            .backgroundColor(Color.Transparent)
          }
        })
        .onClick(() => {
          this.isArrowDown = !this.isArrowDown;
        })

        Row() {
          Row() {
            Flex({
              direction: FlexDirection.Row,
              justifyContent: FlexAlign.SpaceAround,
              alignItems: ItemAlign.Center
            }) {
              ForEach(this.allAccountColor, (item: number, index) => {
                RadioButton({
                  radioColor: item,
                  calendarColor: $calendarColor
                })
              })
            }
          }
          .padding({ left: 8, right: 8 })
          .width('100%')
          .constraintSize({ minHeight: 48 })
        }
        .visibility(this.isArrowDown ? Visibility.None : Visibility.Visible)
      }
      .padding({
        left: 4,
        right: 4,
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(16)
    }
  }
}

/**
 * 颜色选中框子组件
 */
@Component
struct RadioButton {
  @Link calendarColor: number;

  private radioColor: number = 0;

  build() {
    Circle()
      .height(20)
      .width(20)
      .fill(this.calendarColor === this.radioColor ? $r('app.color.default_background') : this.radioColor)
      .stroke(this.radioColor)
      .strokeLineJoin(LineJoinStyle.Round)
      .strokeWidth(this.calendarColor === this.radioColor ? STROKE_WIDTH_UP : STROKE_WIDTH)
      .accessibilityText(GlobalThis.getResourceStr(
        AccountUtils.getAccountColorName(this.radioColor)))
      .onClick(() => {
        this.calendarColor = this.radioColor;
      })
  }
}
