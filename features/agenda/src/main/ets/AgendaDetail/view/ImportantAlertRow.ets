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

import {
  behaviorEvents,
  BigFontSize, FontSizeScaleUtils, HiEventParamsConfirm, ReportHiEventParams, ReportUtil } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { addSwitchText, broadcastSwitchStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';

@Component
export struct ImportantAlertRow {
  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 重要提醒开关
  @Prop isImportantAlert: boolean;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Prop toggleEnabled: boolean = true;

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  build() {
    Row() {
      Text($r('app.string.important'))
        .layoutWeight(1)
        .align(Alignment.Start)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .opacity(this.toggleEnabled ? 1 : $r('sys.float.alpha_disable'))
        .lineHeight(28)
      Toggle({ type: ToggleType.Switch, isOn: $$this.isImportantAlert })
        .selectedColor(this.themeColor)
        .enabled(this.toggleEnabled)
        .hoverEffect(HoverEffect.None)
        .onChange(isOn => {
          let params: ReportHiEventParams = {
            IS_ON: isOn ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE
          }
          ReportUtil.reportBehaviorEvent(behaviorEvents.agendaImportantAlertButton, params);
          broadcastSwitchStatus(isOn);
          this.importantAlertToggleOnChange(isOn);
        })
        .margin({ top: 9 })
    }
    .enabled(this.toggleEnabled)
    .accessibilityText(addSwitchText($r('app.string.important'), this.isImportantAlert))
    .accessibilityGroup(true)
    .onClick(() => {
      this.isImportantAlert = !this.isImportantAlert
    })
    .hoverEffect(HoverEffect.None)
    .borderRadius($r('sys.float.corner_radius_level8'))
    .constraintSize({ minHeight: 48 })
    .width('100%')
    .padding({
      start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
      end: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8)
    })
    .margin({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 5)
    })
  }

  private importantAlertToggleOnChange: (isOn: boolean) => void = (isOn: boolean): void => {
  };
}