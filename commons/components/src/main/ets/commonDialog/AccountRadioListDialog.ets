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

import { AccountRadioList, AccountRadioListOption } from '../radioList/AccountRadioList';
import { BigFontSize, CompId, DeviceConfig, FontSizeScaleUtils, getAccessibilityText, GlobalThis } from '@app/common';
import { HighlightButton } from '../button/HighlightButton';
import { NormalButton } from '../button/NormalButton';

/**
 * 帐户弹框组件
 */
@Component
export struct AccountRadioListDialog {
  // list初始选中的值
  @Link checkValue: number;

  @Prop titleHeight: number;

  @Prop listMarginBottom: number;

  @Prop buttonHeight: number;

  @Prop buttonMarginBottom: Resource;

  @Prop strokeWidth: number;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  private concatAccessibilityText: string = '';

  // 弹框标题
  private title: ResourceStr = '';

  // list选项配置
  private options: AccountRadioListOption[] = [];

  // 单选框的所属群组名称
  private readonly radioGroup: string = '';

  // 延时发布选项变更，避免弹框动画卡顿
  private DELAY: number = 200;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  build() {
    Column() {
      Text(this.title)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE,
          px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
        ))
        .fontWeight(FontWeight.Bold)
        .height(this.titleHeight)
        .alignSelf(ItemAlign.Center)
        .margin({ left: 24, right: 24 })
      AccountRadioList({
        options: this.options,
        groupName: this.radioGroup,
        checkValue: $checkValue,
        strokeWidth: this.strokeWidth,
        onChange: (value: number) => {
          this.cancel();
          setTimeout(() => {
            this.onChange(value);
          }, this.DELAY);
        }
      })
        .layoutWeight(1)
        .margin({ left: 4, right: 4, bottom: this.listMarginBottom })
      this.buttonBuilder();
    }
    .accessibilityText(this.concatAccessibilityText)
  }

  @Builder
  buttonBuilder() {
    Row() {
      if (this.needCommerce) {
        HighlightButton({
          label: $r('app.string.cancel_dialog_button'),
          compId: CompId.CANCEL,
          onButtonClick: () => {
            this.cancel();
          }
        })
      } else {
        NormalButton({
          label: $r('app.string.cancel_dialog_button'),
          compId: CompId.CANCEL,
          onButtonClick: () => {
            this.cancel();
          }
        })
      }
    }
    .margin({
      top: $r('sys.float.padding_level4'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      bottom: this.buttonMarginBottom
    })
  }

  aboutToAppear(): void {
    this.concatAccessibilityText = getAccessibilityText(this.title, this.options.length);
  }

  // 关闭弹窗
  private cancel: () => void = () => {
  };

  // 选中项发生变化
  private onChange: (value: number) => void = (value: number) => {
  };
}
