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
  CalendarDate,
  CommonInnerEvent, CompId, GlobalData, GlobalDataKeys, I18nUtil, Log, statisticEvents, TabType } from '@app/common';
import emitter from '@ohos.events.emitter';
import { ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';

/**
 * 视图中回到今天按钮
 *
 * @since 2023-03-29
 */
const TAG = 'BackToTodayButton';

@Component
export struct BackToTodayButton {
  // 按钮中心日期
  @State dayText: string = JSON.stringify(new CalendarDate().getDate());

  // 系统地区
  @StorageProp('systemRegion') systemRegion: string = 'CN';

  @StorageProp('language') @Watch('onLanguageChange') language: string = 'zh';

  @StorageLink('themeColor') themeColor: string = '';

  @StorageLink('tabIndex') @Watch('onTabIndexChange') tabsIndex: number = TabType.MONTH;

  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayDate: number = 0;

  @State opacityValue: number = 1;

  @State scaleValue: number = 1;

  @State hitTestMode: HitTestMode = HitTestMode.Default; // 默认可点击

  @State isChineseLanguage: boolean = I18nUtil.isChineseLanguage(this.language);

  @Consume @Watch('onAnimationChange') isAnimation: boolean;

  private readonly ANIMATION_TIME: number = 500; // 回到今天动效时间

  private readonly ANIMATION_DELAY: number = 1000; // 回到今天显示的延迟

  private lastShowFlag: boolean = false;

  private isBeforeAnimation: boolean = false;

  onTabIndexChange() {
    this.updateState(true);
  }

  onDisplayDateChange() {
    this.updateState();
  }

  onLanguageChange() {
    this.isChineseLanguage = I18nUtil.isChineseLanguage(this.language);
  }

  updateShowFlag(): boolean {
    // 年视图不显示
    if (this.tabsIndex === TabType.YEAR || this.tabsIndex === TabType.MONTH) {
      return false;
    }
    // 当天不显示
    if (this.isToday()) {
      return false;
    }
    return true;
  }

  updateProp() {
    this.opacityValue = this.lastShowFlag ? 1 : 0;
    this.hitTestMode = this.lastShowFlag ? HitTestMode.Default : HitTestMode.None;
  }

  updateState(needHide: boolean = false) {
    // 在动画中不触发此效果
    if (this.isAnimation) {
      return;
    }

    if (needHide && this.lastShowFlag) {
      this.animationBackToToday(false);
    }

    // 年视图 或者 非当天 都不显示
    const showFlag = this.updateShowFlag();

    // 回到今天出现动画
    if (this.lastShowFlag !== showFlag) {
      this.animationBackToToday(showFlag);
    }
  }

  /**
   * 回到今天隐藏显示动画
   * @param showFlag  隐藏还是显示
   */
  animationBackToToday(showFlag: boolean) {
    Log.info(TAG, `updateState from ${this.lastShowFlag} to ${showFlag}}`)
    this.lastShowFlag = showFlag;
    animateTo({
      duration: this.ANIMATION_TIME, curve: Curve.FastOutSlowIn,
    }, () => {
      this.updateProp();
    });
  }

  onAnimationChange() {
    //处于相同状态中不需要触发
    if (this.isBeforeAnimation === this.isAnimation) {
      this.isBeforeAnimation = this.isAnimation;
      return;
    }

    this.isBeforeAnimation = this.isAnimation;
    Log.info(TAG, `animaition change by ${this.isBeforeAnimation} ${this.isAnimation}`);

    // 年视图 或者 非当天 都不显示 , 新添加在动画中不显示
    const showFlag = this.updateShowFlag() && !this.isAnimation;
    if (showFlag === this.lastShowFlag) {
      return;
    }
    this.animationBackToToday(showFlag);

  }

  // 增加订阅
  aboutToAppear() {
    const showFlag = this.updateShowFlag();
    Log.info(TAG, `aboutToAppear showFlag:${showFlag}}`)
    this.lastShowFlag = showFlag;

    //日期变化需要重新判断按钮是否显示
    this.dateChangeHandler = () => {
      this.updateState()
    };
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED }, this.dateChangeHandler);
    this.updateProp();
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SYSTEM_DATE_CHANGED, this.dateChangeHandler);
  }

  build() {
    Stack() {
      Row()
        .height(48)
        .width(48)
        .borderRadius(24)
        .backgroundColor(this.themeColor)
        .shadow({ radius: 24, color: this.themeColor.replace('#', '#0f'), offsetY: 24 }) //'#0f000000'
      Text(this.systemRegion === 'CN' && this.isChineseLanguage ?
      $r('app.string.go_back_today') : this.dayText)
        .fontColor($r('sys.color.comp_background_primary_contrary'))
        .fontSize($r('sys.float.Title_M'))
        .fontWeight(FontWeight.Bold)
    }
    .width(48)
    .height(48)
    .onClick(() => this.onBackToToday())
    .zIndex(2)
    .markAnchor({ x: 24, y: 104 }) // 相对自身大小偏移 x = 48 / 2, y = 48 + 56
    .position({ x: '50%', y: '100%' })
    .opacity(this.opacityValue)
    .scale({
      x: this.scaleValue,
      y: this.scaleValue,
      centerX: 24,
      centerY: 24
    })
    .hitTestBehavior(this.hitTestMode)
    .id(CompId.BACK_TO_TODAY)
  }

  // 日期变动刷新
  private dateChangeHandler: () => void = () => {
  };

  // 点击事件
  private onBackToToday: () => void = () => {
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

  private isToday(): boolean {
    const displayDate: CalendarDate = new CalendarDate(this.displayDate);
    const currentDate: CalendarDate = new CalendarDate();
    const isToday = (displayDate.getFullYear() === currentDate.getFullYear())
      && (displayDate.getMonth() === currentDate.getMonth())
      && (displayDate.getDate() === currentDate.getDate());
    Log.debug(TAG, `isToday ${isToday}`)
    return isToday;
  }
}
