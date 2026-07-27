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

import { BigFontSize, DeviceConfig, FontSizeScaleUtils, ThrottleFunction } from '@app/common';
import { HighlightButton, NormalButton, RadioList, RadioListDialogOption } from '@app/common.components';
import { getAccessibilityText } from '@app/common/src/main/ets/util/CommonUtils';
import { KeyCode } from '@kit.InputKit';

const TAG: string = 'DeleteAgendaRadio';

// 弹窗选项默认个数
const RADIO_DEFAULT_LENGTH: number = 2;
const TWO_RADIO_DEFAULT_LENGTH: number = 98;
const THREE_RADIO_DEFAULT_LENGTH_3: number = 146;

export enum DeleteMode {
  ONLY_THIS_AGENDA = 0,
  THIS_AND_FUTURE_AGENDA = 1,
  ALL_AGENDAS = 2
}

/**
 * 删除重复日程单选框
 *
 * @since 2024-03-25
 */
@CustomDialog
export struct DeleteAgendaRadio {
  controller: CustomDialogController = new CustomDialogController({ builder: null });

  @State isBackToPage: boolean = false;

  @State checkValue: number = DeleteMode.ONLY_THIS_AGENDA;

  @Prop title: ResourceStr;

  @Prop confirmText: ResourceStr = $r('app.string.delete_dialog_button');

  @Prop cancelText: ResourceStr = $r('app.string.cancel_dialog_button');

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  private showCloudSyncTip: boolean = true;

  private isFirstRepeatAgenda: boolean = false;

  private concatAccessibilityText: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // list选项配置
  private deleteAgendaRadioOptions: RadioListDialogOption[] = [
    { label: $r('app.string.only_this_agenda'), value: DeleteMode.ONLY_THIS_AGENDA },
    { label: $r('app.string.this_and_future_agenda'), value: DeleteMode.THIS_AND_FUTURE_AGENDA },
    { label: $r('app.string.all_agendas'), value: DeleteMode.ALL_AGENDAS },
  ];

  private deleteAgendaRadioOptionsMap: Map<number, ResourceStr> = new Map();

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  confirm: (deleteMode: number) => void = (deleteMode: number): void => {
  };

  cancel: () => void = (): void => {
  };

  aboutToAppear(): void {
    this.initEffectiveDateOptionMap();
    this.concatAccessibilityText = getAccessibilityText(this.title, this.deleteAgendaRadioOptions.length);
  }

  @Builder
  RadioHeader() {
    Text(this.title)
      .textAlign(TextAlign.Center)
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE,
        24
      ))
      .fontWeight(FontWeight.Bold)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(4)
      .margin({
        top: $r('sys.float.padding_level6'),
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4'),
        bottom: this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? $r('sys.float.padding_level4') : 0
      })
      .alignSelf(ItemAlign.Center)
      .wordBreak(WordBreak.BREAK_WORD)
  }

  @Builder
  RadioContent() {
    Row() {
      RadioList({
        groupName: 'DeleteAgendaRadioList',
        options: this.deleteAgendaRadioOptions,
        isBackToPage: this.isBackToPage,
        checkValue: this.checkValue,
        onChange: (value: number) => {
          this.checkValue = value;
        }
      })
    }
    .constraintSize({ maxHeight: 200 })
    .height(this.deleteAgendaRadioOptions.length === RADIO_DEFAULT_LENGTH ?
      TWO_RADIO_DEFAULT_LENGTH * this.fontSizeScale : THREE_RADIO_DEFAULT_LENGTH_3 * this.fontSizeScale)
  }

  @Builder
  RadioFooter() {
    Row() {
      if (this.needCommerce) {
        HighlightButton({
          label: this.cancelText,
          onButtonClick: () => {
            this.controller.close();
            this.cancel();
          }
        })
      } else {
        NormalButton({
          label: this.cancelText,
          onButtonClick: () => {
            this.controller.close();
            this.cancel();
          }
        })
      }
      if (this.needCommerce) {
        Blank().width($r('sys.float.padding_level8'));
        HighlightButton({
          label: this.confirmText,
          isWarning: true,
          isFocus: true,
          onButtonClick: () => {
            this.controller.close();
            this.confirm(this.checkValue);
          }
        })
      } else {
        Divider()
          .vertical(true)
          .strokeWidth('2px')
          .height(24)
          .color($r('sys.color.comp_divider'))
          .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
        NormalButton({
          label: this.confirmText,
          isWarning: true,
          onButtonClick: () => {
            this.controller.close();
            this.confirm(this.checkValue);
          }
        })
      }
    }
    .height(56)
    .margin({ top: $r('sys.float.padding_level4') })
    .padding({ bottom: $r('sys.float.padding_level8') })
  }

  build() {
    Column() {
      this.RadioHeader();
      if (this.showCloudSyncTip) {
        Text($r('app.string.delete_with_cloudDevices'))
          .fontSize(16)
          .alignSelf(ItemAlign.Start)
          .margin({
            left: $r('sys.float.padding_level4'),
            right: $r('sys.float.padding_level4'),
            top: $r('sys.float.padding_level4')
          })
      }
      this.RadioContent();
      this.RadioFooter();
    }
    .borderRadius($r('sys.float.corner_radius_level16'))
    .padding({
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .accessibilityText(this.concatAccessibilityText)
  }

  private initEffectiveDateOptionMap() {
    if (this.isFirstRepeatAgenda) {
      this.deleteAgendaRadioOptions = [
        { label: $r('app.string.only_this_agenda'), value: DeleteMode.ONLY_THIS_AGENDA },
        { label: $r('app.string.all_agendas'), value: DeleteMode.ALL_AGENDAS },
      ];
    }
    this.deleteAgendaRadioOptions.forEach((item: RadioListDialogOption) => {
      this.deleteAgendaRadioOptionsMap.set(item.value, item.label);
    });
  }
}