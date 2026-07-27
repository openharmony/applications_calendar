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

import { emitter } from '@kit.BasicServicesKit';
import {
  ARABIC_LANGUAGE,
  ButtonLayoutParam,
  CalendarDate,
  CalendarLayoutManager,
  CalendarUtils,
  CommonInnerEvent,
  CompId,
  EmitterCollector,
  GlobalData,
  GlobalDataKeys,
  I18nUtil,
  NumberFormatManager,
  ReportHiEventParams,
  ReportUtil,
  statisticEvents,
  TabType
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI'; // 放置于主页右上角工具栏的回到今天按钮

// 放置于主页右上角工具栏的回到今天按钮
@Component
export struct BackToTodayToolbarButton {
  @StorageProp('language') @Watch('onLanguageChange') language: string = 'zh';

  @StorageLink('tabIndex') tabsIndex: number = TabType.MONTH;

  @StorageProp('themeColor') themeColor: string = '';
  // 按钮中心日期
  @State dayText: ResourceStr = $r('app.string.go_back_today');
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;
  @State isToday: boolean = false;
  private isChineseLanguage: boolean = I18nUtil.isChineseLanguage(this.language);
  private isAR: boolean = this.language.includes(ARABIC_LANGUAGE);
  private buttonColor = $r('sys.color.comp_background_tertiary');

  private isForMainPage: boolean = true;
  private emitterController: EmitterCollector = new EmitterCollector();

  @State buttonLayout: ButtonLayoutParam = CalendarLayoutManager.getInstance().buttonLayout;

  onLanguageChange() {
    this.isChineseLanguage = I18nUtil.isChineseLanguage(this.language);
    this.isAR = this.language.includes(ARABIC_LANGUAGE);
    NumberFormatManager.instance().onLanguageChange(this.language);
    this.updateDayText();
  }

  onDateChange(isInit: boolean = false) {
    if (isInit || (!this.isChineseLanguage)) {
      this.updateDayText();
    }
    this.isToday = CalendarUtils.isSameDay(this.displayDate, Date.now());
  }

  onDateJump(data: emitter.EventData) {
    if (!data || !data.data) {
      return;
    }
    const displayDate: number = data.data['dateTime'] ?? Date.now();
    if (!this.isChineseLanguage) {
      this.updateDayText();
    }
    this.isToday = CalendarUtils.isSameDay(displayDate, Date.now());
  }

  updateDayText() {
    this.dayText = this.isChineseLanguage ? '今' :
      this.isAR ? NumberFormatManager.instance().numberFormat(new CalendarDate().getDate()):
    '' + new CalendarDate().getDate();
  }

  aboutToAppear(): void {
    this.onDateChange(true);
    this.timeChangeHandler = (): void => this.onDateChange();
    this.displayDateChangeHandler = (): void => this.onDateChange();
    this.backToTodayChangeHandler = (): void => this.onDateChange();
    this.jumpDateChangeHandler = (data: emitter.EventData): void => this.onDateJump(data);
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.timeChangeHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.timeChangeHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE }, this.displayDateChangeHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.BACK_TO_TODAY }, this.backToTodayChangeHandler);
    this.emitterController.on({ eventId: CommonInnerEvent.JUMP_TO_SOMEDAY }, this.jumpDateChangeHandler);
  }

  aboutToDisappear(): void {
    this.emitterController.off();
  }

  build() {
    Button({ type: ButtonType.Circle }) {
      Text(this.dayText)
        .fontColor(this.themeColor)
        .maxFontSize(this.buttonLayout.backTextSize)
        .minFontSize('10vp')
        .maxLines(1)
        .fontWeight(FontWeight.Medium)
        .focusable(true)
        .focusBox({
          margin: LengthMetrics.px(12),
        })
    }
    .onClick(() => {
      if (this.isForMainPage) {
        this.onBackToToday();
      } else {
        this.onButtonClick();
      }
    })
    .id(CompId.BACK_TO_TODAY)
    .focusable(true)
    .backgroundColor(this.buttonColor)
    .margin({ start: LengthMetrics.vp(8) })
    .width(this.buttonLayout.buttonHeight)
    .height(this.buttonLayout.buttonHeight)
    .visibility((!this.isToday || !this.isForMainPage) ? Visibility.Visible : Visibility.None)
  }

  private onButtonClick: () => void = () => {
  };

  // 点击事件
  private onBackToToday: () => void = () => {
    // 同一天不触发回到今天
    if (CalendarUtils.isSameDay(Date.now(), GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number)) {
      return;
    }
    // 1. 修改全局 DisplayDay
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
    // 2. 触发事件,通知各个模块响应 回到今天
    emitter.emit({ eventId: CommonInnerEvent.BACK_TO_TODAY });
    // 3. 打点操作
    let params: ReportHiEventParams = {
      SOURCE_PAGE: this.tabsIndex
    }
    ReportUtil.reportStatisticEvent(statisticEvents.backToToday, params);
  };

  // 处理系统时间变化
  private timeChangeHandler: () => void = (): void => {
  };

  // 处理显示时间变化
  private displayDateChangeHandler: () => void = (): void => {
  };

  // 处理回到今天变化
  private backToTodayChangeHandler: () => void = (): void => {
  };

  // 处理日期跳转变化
  private jumpDateChangeHandler: (data: emitter.EventData) => void = (): void => {
  };
}