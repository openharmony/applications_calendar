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

import { Action, eventAction } from '../groupConfig/declare';
import { DefaultRemindTime } from '../dialogs/DefaultRemindTime';
import { BigFontSize, CommonInnerEvent, DeviceConfig, EmitterCollector, FontSizeScaleUtils } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { DEFAULT_REMINDER_OPTIONS } from '@app/common.components';

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct DefaultReminderTimeItem {
  // 默认提醒时间
  @StorageLink('defaultRemindTime') @Watch('onDefaultRemindTimeChange') defaultRemindTime: number = 10;

  @State displayDefaultRemindTime: number = 10;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  // 主标题
  private title: ResourceStr = '';

  // 描述
  private description: ResourceStr = '';

  // 触发的行为类型，赋初值防止ArkTS报错
  private action: Action = eventAction.DIALOG;

  // 设置项key值
  private settingKey: string = '';

  // 设置项的默认值
  private defaultVal: string | number = '';

  private compId: string = '';

  @State menuShow: boolean = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  // 格式化附加信息
  formatExtraInfo() {
    let that = this;
    return DEFAULT_REMINDER_OPTIONS.find(item => {
      return item.value === that.displayDefaultRemindTime;
    })?.label;
  }

  @Builder
  defaultReminderBuild() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 8 })
      }
    }
    .flexShrink(this.isChangeLayout() ? 0 : 1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: 8 })

    Row() {
      Text(this.formatExtraInfo())
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 24 })
      .clip(true)
    }
    .flexShrink(0)
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  buildMenu() {
    Column() {
      DefaultRemindTime({
        callback: (value: number) => {
          this.displayDefaultRemindTime = value;
          this.menuShow = false;
        }
      })
    }
    .width(224)
  }

  build() {
    Row() {
      Column() {
        this.defaultReminderBuild();
      }
      .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .constraintSize({
        minHeight: this.rowMinHeight
      })
      .padding({
        top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4')
      })
      .stateStyles({
        pressed: {
          .backgroundColor(this.action !== eventAction.SWITCH ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius(14)
      .id(this.compId)

      Row() {
        this.defaultReminderBuild();
      }
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .constraintSize({
        minHeight: this.rowMinHeight
      })
      .padding({
        top: 4,
        bottom: 4,
        left: 8,
        right: 8
      })
      .stateStyles({
        pressed: {
          .backgroundColor(this.action !== eventAction.SWITCH
            ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius(14)
      .id(this.compId)
    }
    .bindMenu(this.menuShow, this.buildMenu(), {
      placement: Placement.BottomRight,
      onDisappear: () => {
        this.menuShow = false;
      }
    })
    .onClick(() => {
      this.menuShow = true;
    })
    .borderRadius(14)
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .width('100%')
  }

  aboutToAppear() {
    this.displayDefaultRemindTime = this.defaultRemindTime;
    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_STATUSBAR }, () => {
      this.menuShow = false;
    });
    this?.onMounted();
  }

  private onDefaultRemindTimeChange(): void {
    this.displayDefaultRemindTime = this.defaultRemindTime;
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  // 事件
  private event: Function = () => {
    if (this.openDialog) {
      this.openDialog(this.settingKey);
    }
  };

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 打开弹框
  private openDialog: Function = () => {
  };
}
