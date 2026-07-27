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
import { SettingStore } from '../Storage';
import {
  behaviorEvents,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  GlobalDataKeys,
  GlobalThis, Log, ReportHiEventParams, ReportUtil, } from '@app/common';
import { BigFontSize, FontSizeScaleUtils } from '@app/common';
import { accessibility } from '@kit.AccessibilityKit';
import { addSwitchText, broadcastSwitchStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'GroupItem';

// 提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 设置单元(族)单个设置项
 *
 * @since 2022-07-25
 */
@Component
export struct GroupItem {
  // Toggle组件状态
  @State isToggleOn: boolean = false;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    autoCancel: false,
    customStyle: true
  };

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) isOpenAccessibilityScreenReader: boolean = false;

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

  private timeoutId: number = 0;

  @Builder
  dialogItemBuilder() {
    if ((this.formatExtraInfo()) instanceof Array) {
      Flex({ justifyContent: FlexAlign.End, wrap: FlexWrap.Wrap }) {
        ForEach(this.formatExtraInfo(), (info: string) => {
          Text(info)
            .fontSize($r('sys.float.Body_M'))
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ left: 2 })
        })
      }
      .constraintSize({
        maxWidth: 200
      })
    } else {
      Text(this.formatExtraInfo())
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
    }

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

  @Builder
  switchItemBuilder() {
    Toggle({ type: ToggleType.Switch, isOn: this.isToggleOn }).selectedColor(this.themeColor)
      .onChange(isOn => {
        Log.info(TAG, `onSwitchChange key is ${this.settingKey} new value is ${isOn} oldValue is ${this.isToggleOn?.valueOf()}`);
        this.switchChange(isOn);
      })
      .margin(0)
      .hoverEffect(HoverEffect.None)
  }

  private switchChange(isOn: boolean) {
    this.isToggleOn = Boolean(isOn);

    SettingStore.INSTANCE.set(this.settingKey, Number(isOn));

    let callEvents = (isOn: boolean): void => this.event(isOn);
    callEvents(isOn);
  }

  private getAccessibilityText(): string {
    const baseAccessibilityText = this.getBaseAccessibilityText();
    if (this.action === eventAction.SWITCH) {
      return addSwitchText(baseAccessibilityText, this.isToggleOn);
    }
    return baseAccessibilityText;
  }

  private getBaseAccessibilityText(): string {
    let title = '';
    let description = '';
    if (typeof this.title === 'string') {
      title = this.title;
    } else {
      title = GlobalThis.getResourceStr(this.title);
    }
    if (typeof this.description === 'string') {
      description = this.description;
    } else {
      description = GlobalThis.getResourceStr(this.description);
    }
    return title + description;
  }

  build() {
    Row() {
      this.titleBuilder()

      Row() {
        if (this.action === eventAction.ROUTER || this.action === eventAction.DIALOG) {
          this.dialogItemBuilder()
        } else if (this.action === eventAction.SWITCH) {
          this.switchItemBuilder()
        }
      }
      .flexShrink(0)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .constraintSize({ minHeight: this.rowMinHeight })
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .focusBox({
      margin: LengthMetrics.px(-4),
    })
    .hoverEffect(HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor(this.action !== eventAction.SWITCH
          ? $r('sys.color.interactive_click') : $r('app.color.default_background'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .borderRadius($r('sys.float.corner_radius_level7'))
    .accessibilityText(this.getAccessibilityText())
    .accessibilityGroup(true)
    .onClick(this.action !== eventAction.SWITCH ? () => {
      this.event()
    } : () => {
      if (this.isOpenAccessibilityScreenReader) {
        Log.info(TAG, `onClick key is ${this.settingKey} new value is ${!this.isToggleOn} oldValue is ${this.isToggleOn?.valueOf()}`);
        broadcastSwitchStatus(!this.isToggleOn);
        this.switchChange(!this.isToggleOn);
      }
    })
    .id(this.compId)
  }

  @Builder
  titleBuilder() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: $r('sys.float.padding_level1') });
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: $r('sys.float.padding_level2') });
      }
    }
    .accessibilityLevel('no')
    .flexShrink(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: $r('sys.float.padding_level4') })
  }

  async aboutToAppear() {
    await this.init();
    this?.onMounted();
  }

  // 事件
  private event: Function = () => {
  };

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 格式化附加信息
  private formatExtraInfo: Function = () => ('');

  // 打开弹框
  private openDialog: Function = () => {
  };

  private async init() {
    if (this.action === eventAction.SWITCH) {
      const value = await SettingStore.INSTANCE.get(this.settingKey, this.defaultVal);
      this.isToggleOn = Boolean(value);
      Log.info(TAG, `settingKey: ${this.settingKey}, value: ${value}, isToggleOn: ${this.isToggleOn}`);
      let params: ReportHiEventParams = {};
      let reportValue = this.isToggleOn ? 1 : 0;
      switch (this.compId) {
        case CompId.SETTINGS_IMPORTANT_DAYS:
          params.SETTINGS_IMPORTANT_DAY = reportValue;
          break;
        case CompId.SETTINGS_SHOW_WEEK_NUMBER:
          params.SETTINGS_SHOW_WEEKS = reportValue;
          break;
        case CompId.SETTINGS_LOCK_TIME_ZONE:
          params.SETTINGS_LOCK_TIME_ZONE = reportValue;
          break;
        case CompId.SHARE_SWITCH:
          params.SETTINGS_RECEIVE_SHARED_CALENDARS = reportValue;
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.SettingStatus, params);
    }
  }

  aboutToDisappear(): void {
  }
}
