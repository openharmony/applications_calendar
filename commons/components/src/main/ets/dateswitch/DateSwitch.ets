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
  BigFontSize,
  CalendarUtils,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  GlobalDataKeys,
  ThrottleFunction,
  TIPS_HOVER_DELAY
} from '@app/common';

import { style } from './style';
import { LengthMetrics } from '@kit.ArkUI';
import { TipsPopup } from '../TipsPopup';
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'DateSwitch';
export const MIN_WIDTH_VP = 560; // PC 分屏-避免日期和当前组件重叠的宽度

/**
 * 日期切换自定义控件
 *
 * @since 2022-03-21
 */
@Component
export struct DateSwitch {
  // 按钮文字
  @State buttonText: Resource = $r('app.string.today');

  // 下拉框日期文字信息
  @State dropdownText: string = '';

  // 下拉框日期文字信息
  @State leftTips: boolean = false;
  @State rightTips: boolean = false;
  @State backTips: boolean = false;
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 主题色
  @StorageLink('themeColor') themeColor: string = '#00ffffff';
  @StorageLink('windowFocused') windowFocused: boolean = true;
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;
  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 100;

  private emitterController: EmitterCollector = new EmitterCollector();

  @State isToday: boolean = true;

  @LocalStorageLink('windowWidth') @Watch('windowWidthChange') windowWidth: number = 0;

  @State isMinSplitScreen: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 刷新当天状态
  private refreshTimeStateHandler: () => void = (): void => {
    this.isToday = CalendarUtils.isSameDay(this.displayDate, Date.now());
  };

  // 跳转到指定日期刷新当天状态
  private dateJumpRefreshTimeStateHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    if (!data || !data.data) {
      return;
    }
    const displayDate: number = data.data['dateTime'] ?? Date.now();
    this.isToday = CalendarUtils.isSameDay(displayDate, Date.now());
  };

  subscribeEvents(): void {
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.refreshTimeStateHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.refreshTimeStateHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE }, this.refreshTimeStateHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, this.refreshTimeStateHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, this.dateJumpRefreshTimeStateHandler);
  }

  unsubscribeEvents(): void {
    this.emitterController.off();
  }

  aboutToAppear() {
    this.subscribeEvents();
    this.refreshTimeStateHandler();
    this.windowWidthChange();
  }

  aboutToDisappear() {
    this.unsubscribeEvents();
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  windowWidthChange() {
    this.isMinSplitScreen = this.windowWidth < MIN_WIDTH_VP;
  }

  getShadow() {
    return this.isDarkMode ?
      { radius: 2, color: '#ccffffff', offsetX: 0, offsetY: 0, } as ShadowOptions :
      ShadowStyle.OUTER_DEFAULT_SM
  }

  build() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .rotate({ y: 1, angle: 180 })
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
      }
      .width(this.isMinSplitScreen ? 22 : 28)
      .height(28)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .margin({ start: this.isMinSplitScreen ? LengthMetrics.vp(0) : LengthMetrics.vp(8) })
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        ThrottleFunction.instance().throttle(TAG, (): void => {
          this.onClickLeftArrow();
        }, this.DELAY)
      })
      .onHover((isHover: boolean) => {
        ThrottleFunction.instance().debounce(TAG + 'leftTips', () => {
          this.leftTips = isHover;
        }, isHover ? TIPS_HOVER_DELAY : 0);
      })
      .bindPopup(this.leftTips, {
        builder: this.PopupComp($r('app.string.page_left')), // 待提翻
        popupColor: $r('sys.color.ohos_id_color_card_bg'),
        backgroundBlurStyle: BlurStyle.NONE,
        shadow: this.getShadow(),
        mask: false,
        enableArrow: false
      })
      .id(CompId.DATE_SWITCH_LEFT_ARROW)

      Button({ type: ButtonType.Normal }) {
        Text(this.buttonText)
          .fontColor(this.isToday ? $r('sys.color.font_primary') : this.themeColor)
          .fontWeight(style.button.fontWeight)
          .maxFontSize($r('sys.float.Body_L'))
          .minFontSize('10vp')
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
          .maxLines(1)
      }
      .padding({ start: LengthMetrics.vp(2), end: LengthMetrics.vp(2) })
      .backgroundColor(Color.Transparent)
      .height(28)
      .onClick(() => {
        this.onClickButton();
      })
      .focusable(true)
      .id(CompId.BUTTON_BACK_TO_TODAY)
      .width(48)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .margin({
        start: this.isMinSplitScreen ? LengthMetrics.vp(0) : LengthMetrics.vp(4),
        end: this.isMinSplitScreen ? LengthMetrics.vp(0) : LengthMetrics.vp(4)
      })
      .onHover((isHover: boolean) => {
        ThrottleFunction.instance().debounce(TAG + 'backTips', () => {
          this.backTips = isHover;
        }, isHover ? TIPS_HOVER_DELAY : 0);
      })
      .bindPopup(this.backTips, {
        builder: this.PopupComp($r('app.string.back_to_today')),
        popupColor: $r('sys.color.ohos_id_color_card_bg'),
        backgroundBlurStyle: BlurStyle.NONE,
        shadow: this.getShadow(),
        mask: false,
        enableArrow: false
      })

      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
      }
      .width(this.isMinSplitScreen ? 22 : 28)
      .height(28)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .margin({ end: this.isMinSplitScreen ? LengthMetrics.vp(0) : LengthMetrics.vp(8) })
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        ThrottleFunction.instance().throttle(TAG, (): void => {
          this.onClickRightArrow();
        }, this.DELAY)
      })
      .onHover((isHover: boolean) => {
        ThrottleFunction.instance().debounce(TAG + 'rightTips', () => {
          this.rightTips = isHover;
        }, isHover ? TIPS_HOVER_DELAY : 0);
      })
      .bindPopup(this.rightTips, {
        builder: this.PopupComp($r('app.string.page_right')), // 待提翻
        popupColor: $r('sys.color.ohos_id_color_card_bg'),
        backgroundBlurStyle: BlurStyle.NONE,
        shadow: this.getShadow(),
        mask: false,
        enableArrow: false
      })
      .id(CompId.DATE_SWITCH_RIGHT_ARROW)
    }
    .backgroundColor(Color.Transparent)
    .border({ radius: $r('sys.float.corner_radius_level10') })
    .height(40)
    .width(this.isMinSplitScreen ? 92 : 128)
    .justifyContent(FlexAlign.Center)
    .opacity(!this.windowFocused && this.needCommerce ? 0.4 : 1)
  }

  // 点击按钮
  private onClickButton: () => void = () => {
  };

  // 点击左箭头
  private onClickLeftArrow: () => void = () => {
  };

  // 点击右箭头
  private onClickRightArrow: () => void = () => {
  };
}

