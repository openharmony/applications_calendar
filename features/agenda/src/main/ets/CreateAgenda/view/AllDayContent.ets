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

import { AgendaEventInfo, BigFontSize, FontSizeScaleUtils } from '@app/common';
import {
  addSwitchText,
  broadcastSwitchStatus,
  switchOpenText
} from '@app/common/src/main/ets/util/AccessibilityUtil';

/**
 * 全天日程开关组件
 *
 * @since 2024-11-11
 */
@Component
export struct AllDayContent {
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //标题地点输入光标颜色
  @StorageProp('themeColor') themeColor: string = '';

  @Link eventInfo: AgendaEventInfo;

  @Link isToggleOn: boolean;

  build() {
    Row() {
      Text($r('app.string.all_day'))
        .layoutWeight(1)
        .align(Alignment.Start)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
      Toggle({ type: ToggleType.Switch, isOn: $$this.isToggleOn })
        .selectedColor(this.themeColor)
        .hoverEffect(HoverEffect.None)
        .onChange(isOn => {
          this.isToggleOn = Boolean(isOn);
          this.toggleOnChange();
        })
    }.constraintSize({ minHeight: 48 })
    .accessibilityText(addSwitchText($r('app.string.all_day'), this.isToggleOn))
    .accessibilityDescription(switchOpenText(this.isToggleOn)) //设置为单指双击即可关闭/打开
    .accessibilityGroup(true)
    .onClick(() => {
      broadcastSwitchStatus(!this.isToggleOn);
      this.isToggleOn = !this.isToggleOn;
      this.toggleOnChange();
    })
    .padding({ right: this.isChangeLayout() ? 12 : 8, left: this.isChangeLayout() ? 12 : 8 })
    .margin({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      left: 0,
      right: 0
    })
  }

  private isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  private toggleOnChange: () => void = (): void => {
  };
}