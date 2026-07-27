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

import UTD from '@ohos.data.uniformTypeDescriptor';
import {
  AgendaEventInfo,
  behaviorEvents,
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ModeUtil,
  PreferencesUtil,
  statisticEvents,
  TabType,
  UnusualMode,
  YearAnimateParam
} from '@app/common';
import { YearView } from '@app/feature.yearview';
import { MonthlyView } from '@app/feature.monthview';
import lazy { WeekView } from '@app/feature.weekview';
import emitter from '@ohos.events.emitter';
import data_preferences from '@ohos.data.preferences';
import { ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { CreateAgendaPageSource } from '@app/feature.agenda';
import { componentUtils } from '@kit.ArkUI';
import { YearViewLayoutModel } from '@app/feature.yearview/src/main/ets/layoutmodel/YearViewLayoutModel';
import lazy { parseDataFromUdmf, verifyDataFromUdmf } from '@app/common/src/main/ets/default/util/ShareUtils';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';

const TAG = `MainTabComp`

@Component
export struct MainTabComponent {
  @Consume navPathStack: NavPathStack;

  // tabIndex的本地缓存
  @StorageLink('tabIndexPreferences') tabIndexPreferences: data_preferences.Preferences | null = null;

  // tab页签索引，无缓存情况下首次进入日历应用显示月视图
  @StorageLink('tabIndex') tabsIndex: number = TabType.MONTH;

  // 是否是HiCar模式
  @StorageProp('unusualMode') @Watch('unusualModeOnChange') unusualMode: UnusualMode | undefined =
    AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  private unusualModeOnChange() {
    // 非HiCar模式并且非上下小折叠模式，或者tab是月视图，就返回
    if (!ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) || this.tabsIndex === TabType.MONTH) {
      return;
    }
    this.changeTabsIndex(TabType.MONTH)
  }

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Consume isOnDropAllowed: boolean;

  @Provide('yearViewAnimateParam') yearViewAnimateParam: CombineAnimateParam = new CombineAnimateParam();

  // 天干地支和农历图例动效单独控制
  @Provide yearLegendAnimateParam: CombineAnimateParam = new CombineAnimateParam();

  @Provide monthWeekTitleViewAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide monthDateViewAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide monthAgendaViewAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide weekWeekTitleViewAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide weekDateAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide weekGanttAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide dayWeekTitleViewAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide dayDateAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide dayGanttAnimate: CombineAnimateParam = new CombineAnimateParam();

  @Provide yearAnimationParam: YearAnimateParam = new YearAnimateParam();

  // 横屏日视图日程详情动效
  @Provide SelectedAgendaViewAnimateParam: CombineAnimateParam = new CombineAnimateParam();

  @State layouts: TabContentLayout[] = [{ zIndex: 0 }];

  // Tabs组件控制器
  private tabsController: TabsController = new TabsController();

  // tab页签索引，无缓存情况下首次进入日历应用显示月视图
  private initTabIndex: number = this.setTabIndex(this.tabsIndex);

  private distanceY: number = 0;

  // 总动画持续时长, ms
  private readonly TOTAL_ANIMATION_DURATION = 400;

  private tables: TabTransfer[] = [
    new TabTransfer(TabType.YEAR, [TabType.MONTH],
      () => { this.YearToMonth() },
      () => { this.changeVisibleByIndex(TabType.MONTH) },
      () => { this.monthFinish() }
    ),

    new TabTransfer(TabType.YEAR, [TabType.WEEK],
      () => { this.yearToWeek() },
      () => { this.changeVisibleByIndex(TabType.WEEK) },
      () => { this.weekFinish() }
    ),

    new TabTransfer(TabType.MONTH, [TabType.YEAR],
      () => { this.monthToYear() },
      () => { this.changeVisibleByIndex(TabType.YEAR) },
      () => { this.yearFinish() }
    ),

    new TabTransfer(TabType.MONTH, [TabType.WEEK],
      () => { this.monthToWeek() },
      () => { this.changeVisibleByIndex(TabType.WEEK) },
      () => { this.weekFinish() }
    ),

    new TabTransfer(TabType.WEEK, [TabType.YEAR],
      () => { this.weekToYear() },
      () => { this.changeVisibleByIndex(TabType.YEAR) },
      () => { this.yearFinish() }
    ),

    new TabTransfer(TabType.WEEK, [TabType.MONTH],
      () => { this.weekToMonth() },
      () => { this.changeVisibleByIndex(TabType.MONTH) },
      () => { this.monthFinish() }
    ),
  ]

  private eventSwitchTabHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  aboutToAppear() {
    let index: Object | undefined = GlobalThis.getInstance().abilityWant?.parameters?.tabIndex;
    this.tabsIndex = index ? Number(index) : GlobalData.instance().get(GlobalDataKeys.TAB_INDEX) as number;
    let prepareContinue = PreferencesUtil.getBooleanValueSync('tabIndex', 'prepareContinueState');
    if (prepareContinue) {
      Log.info(TAG, `prepare continue state`);
      this.tabsIndex = PreferencesUtil.getNumberValueSync('tabIndex', 'tabIndex');
      PreferencesUtil.putBooleanValueSync('tabIndex', 'prepareContinueState', false); // 禁用预备接续
    }
    if (this.tabsIndex === null || this.tabsIndex === undefined || isNaN(this.tabsIndex)) {
      this.tabsIndex = TabType.MONTH;
    }
    this.unusualModeOnChange();
    this.initTabIndex = this.setTabIndex(this.tabsIndex);
    Log.log(TAG, `index: ${index}, this.tabsIndex : ${this.tabsIndex}`)

    this.initTabAnimController();
    //接收订阅事件时的回调处理
    this.eventSwitchTabHandler = (eventData: emitter.EventData) => {
      Log.log(TAG, 'callback')
      if (!eventData.data) {
        return;
      }
      Log.log(TAG, `onEvent: receive oldTabIndex:${eventData.data.oldTabIndex} tabIndex:${eventData.data.tabIndex}`);

      if (eventData.data.oldTabIndex &&
        eventData.data.tabIndex === TabType.YEAR ) {
        this.initYearAnimationParam();
      }
      this.changeTabsIndex(eventData.data.tabIndex)
    };
    emitter.on({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, this.eventSwitchTabHandler);
    emitter.on({ eventId: CommonInnerEvent.MONTH_VIEW_SELECT_DAY }, this.onMonthViewSelectDayChange);

    // 根据初始值 设定布局参数
    for (let index = TabType.YEAR; index <= TabType.WEEK; ++index) {
      this.layouts[index] = { zIndex: 1 };
    }
    this.layouts[this.setTabIndex(this.tabsIndex)].zIndex = 2;
    Log.log(TAG, `layouts: ${JSON.stringify(this.layouts)}`)
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SWITCH_MAIN_PAGE_TAB, this.eventSwitchTabHandler);
    emitter.off(CommonInnerEvent.MONTH_VIEW_SELECT_DAY, this.onMonthViewSelectDayChange);
  }

  // getRectangleById接口不稳定, 直接让月视图选中天组件将自身位置信息发送过来
  onMonthViewSelectDayChange = (eventData: emitter.EventData) => {
    if (!eventData.data) {
      return;
    }
    Log.log(TAG, 'onEvent: receive DistanceY ' + eventData.data.DistanceY);
    if (eventData.data.DistanceY) {
      this.distanceY = eventData.data.DistanceY as number;
    }
  }

  YearToMonth() {
    this.setYearViewParam();

    // 周标题 一起放缩
    this.monthWeekTitleViewAnimate.opacity = 0;
    this.monthWeekTitleViewAnimate.opacityAnimateParam = { duration: 50, delay: 50, curve: Curve.Sharp }
    this.monthWeekTitleViewAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.monthWeekTitleViewAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.monthWeekTitleViewAnimate.translateOptions = { x: 0, y: 0 };
    this.monthWeekTitleViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthWeekTitleViewAnimate: ' + JSON.stringify(this.monthDateViewAnimate))
    // 日期视图 放缩,透明度变化
    this.monthDateViewAnimate.opacity = 0;
    this.monthDateViewAnimate.opacityAnimateParam = { duration: 50, delay: 50, curve: Curve.Sharp }
    this.monthDateViewAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.monthDateViewAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.monthDateViewAnimate.translateOptions = { x: 0, y: 0 };
    this.monthDateViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthDateViewAnimate: ' + JSON.stringify(this.monthDateViewAnimate))
    // 日程列表从屏幕下方移入
    this.monthAgendaViewAnimate.opacity = 0;
    this.monthAgendaViewAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp };
    this.monthAgendaViewAnimate.translateOptions = { y: 350, x: 0 };
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthAgendaViewAnimate: ' + JSON.stringify(this.monthAgendaViewAnimate))
  }

  yearToWeek() {
    this.setYearViewParam();

    // 周视图周标题放缩入场
    this.weekWeekTitleViewAnimate.opacity = 0;
    this.weekWeekTitleViewAnimate.opacityAnimateParam = { duration: 50, delay: 50, curve: Curve.Sharp }
    this.weekWeekTitleViewAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.weekWeekTitleViewAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };

    // 周视图日期放缩入场
    this.weekDateAnimate.opacity = 0;
    this.weekDateAnimate.opacityAnimateParam = { duration: 150, delay: 150, curve: Curve.Sharp }
    this.weekDateAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.weekDateAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };

    // 甘特图从屏幕下方出现
    this.weekGanttAnimate.translateOptions = { x: 0, y: 350, z: 0 };
    this.weekGanttAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.weekGanttAnimate.opacity = 0;
    this.weekGanttAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp };
    Log.info(TAG, 'weekGanttAnimate: ' + JSON.stringify(this.weekGanttAnimate));
    // 宽屏日程列表从屏幕下方入场
    this.SelectedAgendaViewAnimateParam.translateOptions = { y: 350, x: 0 };
    this.SelectedAgendaViewAnimateParam.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.SelectedAgendaViewAnimateParam.opacity = 0;
    this.SelectedAgendaViewAnimateParam.opacityAnimateParam = { duration: 100, curve: Curve.Sharp };
  }

  monthToYear() {
    // 周标题 一起放缩
    this.monthWeekTitleViewAnimate.opacity = 0;
    this.monthWeekTitleViewAnimate.opacityAnimateParam = { duration: 50, delay: 100, curve: Curve.Sharp }
    this.monthWeekTitleViewAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.monthWeekTitleViewAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.monthWeekTitleViewAnimate.translateOptions = { x: 0, y: 0 };
    Log.info(TAG, 'monthWeekTitleViewAnimate: ' + JSON.stringify(this.monthWeekTitleViewAnimate))
    // 日期视图 放缩,透明度变化
    this.monthDateViewAnimate.opacity = 0;
    this.monthDateViewAnimate.opacityAnimateParam = { duration: 50, delay: 100, curve: Curve.Sharp }
    this.monthDateViewAnimate.scaleOption = {
      x: 0.3,
      y: 0.3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.monthDateViewAnimate.scaleAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.monthDateViewAnimate.translateOptions = { x: 0, y: 0 };
    Log.info(TAG, 'monthDateViewAnimate: ' + JSON.stringify(this.monthDateViewAnimate))
    this.monthAgendaViewAnimate.opacity = 0;
    this.monthAgendaViewAnimate.opacityAnimateParam = { duration: 50, delay: 100, curve: Curve.Sharp };
    this.monthAgendaViewAnimate.translateOptions = { y: 350, x: 0 };
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthAgendaViewAnimate: ' + JSON.stringify(this.monthAgendaViewAnimate));

    // 年视图组件多，初次切换创建时间长，临时修改动效时长，确保在600的完成时间内完成动画，同时保证一定的动效曲线。
    this.yearViewAnimateParam.opacity = 0;
    this.yearViewAnimateParam.opacityAnimateParam = { duration: 50, delay: 100, curve: Curve.Sharp };
    this.yearViewAnimateParam.scaleOption = {
      x: 3,
      y: 3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.yearViewAnimateParam.scaleAnimateParam = { duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction };
    // 天干地支不透明度变化
    this.yearLegendAnimateParam.opacity = 0;
    this.yearLegendAnimateParam.opacityAnimateParam = { duration: 50, curve: Curve.Sharp };
  }

  monthToWeek() {
    this.monthToWeekDayInit();

    // 周视图 周标题 透明度变化动效, 不放缩
    this.weekWeekTitleViewAnimate.opacity = 0;
    this.weekWeekTitleViewAnimate.opacityAnimateParam = { duration: 150, delay: 100, curve: Curve.Sharp }
    this.weekWeekTitleViewAnimate.scaleOption = {
      x: 1,
      y: 1,
      centerX: 0,
      centerY: 0
    };
    this.weekWeekTitleViewAnimate.translateOptions = { x: 0, y: 0, z: 0 };

    this.weekDateAnimate.opacity = 0;
    this.weekDateAnimate.opacityAnimateParam = { duration: 150, delay: 100, curve: Curve.Sharp }
    this.weekDateAnimate.scaleOption = {
      x: 1,
      y: 1,
      centerX: 0,
      centerY: 0
    };
    this.weekDateAnimate.translateOptions = { x: 0, y: 0, z: 0 };

    this.weekGanttAnimate.opacity = 0;
    this.weekGanttAnimate.opacityAnimateParam = { duration: 100, delay: 100, curve: Curve.Sharp };
    this.weekGanttAnimate.scaleOption = {
      x: 1,
      y: 1,
      centerX: 0,
      centerY: 0
    };
    this.weekGanttAnimate.translateOptions = { x: 0, y: 100, z: 0 };
    this.weekGanttAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    if (this.tabsIndex === TabType.DAY) {
      this.SelectedAgendaViewAnimateParam.opacity = 0;
      this.SelectedAgendaViewAnimateParam.opacityAnimateParam = { duration: 100, delay: 100, curve: Curve.Sharp };
      this.SelectedAgendaViewAnimateParam.scaleOption = {
        x: 1,
        y: 1,
        centerX: 0,
        centerY: 0
      };
      this.SelectedAgendaViewAnimateParam.translateOptions = { x: 0, y: 125, z: 0 };
      this.SelectedAgendaViewAnimateParam.translateAnimateParam = {
        duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
      };
    }
  }

  // 月视图到周日视图初始化参数
  monthToWeekDayInit() {
    if (MonthlyViewStateManager.getInstance()?.weekState?.isWeekShow) {
      this.monthWeekTitleViewAnimate.visibility = false;
      this.monthDateViewAnimate.visibility = false;
      this.monthAgendaViewAnimate.visibility = false;
    }

    // 月视图 周标题 透明度变化
    this.monthWeekTitleViewAnimate.opacity = 0;
    this.monthWeekTitleViewAnimate.opacityAnimateParam = { duration: 50, curve: Curve.Sharp }
    // 不放缩
    this.monthWeekTitleViewAnimate.scaleOption = { x: 1, y: 1 };
    this.monthWeekTitleViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthWeekTitleViewAnimate: ' + JSON.stringify(this.monthWeekTitleViewAnimate))

    this.monthDateViewAnimate.opacity = 0; // 透明度变化，避免和日视图重叠
    this.monthDateViewAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.monthDateViewAnimate.scaleOption = {
      x: 1,
      y: 1,
      centerX: 0,
      centerY: 0
    } // 不放缩
    this.monthDateViewAnimate.translateOptions = { y: -this.distanceY }; // 上移
    this.monthDateViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthDateViewAnimate: ' + JSON.stringify(this.monthDateViewAnimate));
    this.monthAgendaViewAnimate.opacity = 0; // 透明度变化，避免和日视图重叠
    this.monthAgendaViewAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.monthAgendaViewAnimate.translateOptions = { y: -this.distanceY } // 日程列表跟随日期视图上移
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthAgendaViewAnimate: ' + JSON.stringify(this.monthAgendaViewAnimate));
  }

  weekToYear() {
    this.weekWeekTitleViewAnimate.visibility = false; // 直接隐藏周标题避免重影
    this.weekDateAnimate.visibility = false; //直接隐藏周视图日期避免重影
    this.SelectedAgendaViewAnimateParam.visibility = false; // 直接隐藏横屏日视图日程详情避免重影
    this.setWeekDateViewParam(true);
    this.weekGanttAnimate.translateOptions = { y: 350, x: 0 };
    this.weekGanttAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.weekGanttAnimate.opacity = 0;
    this.weekGanttAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp };
    Log.info(TAG, 'weekGanttAnimate: ' + JSON.stringify(this.weekGanttAnimate));

    this.setYearViewParam();
  }

  weekToMonth() {
    this.weekDateAnimate.visibility = false; //直接隐藏周视图日期避免重影
    this.weekWeekTitleViewAnimate.visibility = false;
    this.SelectedAgendaViewAnimateParam.visibility = false; // 直接隐藏横屏日视图日程详情避免重影
    // 周标题 透明度变化
    this.monthWeekTitleViewAnimate.opacity = 0;
    this.monthWeekTitleViewAnimate.opacityAnimateParam = { duration: 150, delay: 150, curve: Curve.Sharp }
    // 不放缩
    this.monthWeekTitleViewAnimate.scaleOption = { x: 1, y: 1 };
    this.monthWeekTitleViewAnimate.translateOptions = { x: 0, y: 0 };
    Log.info(TAG, 'monthWeekTitleViewAnimate: ' + JSON.stringify(this.monthWeekTitleViewAnimate))

    this.monthDateViewAnimate.opacity = 0; // 透明度变化，避免和月视图重叠
    this.monthDateViewAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.setMonthViewDateViewScale(false); // 不放缩
    this.monthDateViewAnimate.translateOptions = { y: -this.distanceY }
    this.monthDateViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    Log.info(TAG, 'monthDateViewAnimate: ' + JSON.stringify(this.monthDateViewAnimate));
    this.monthAgendaViewAnimate.opacity = 0;
    this.monthAgendaViewAnimate.translateOptions = { y: -this.distanceY } // 日程列表跟随日期视图上移
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };

    // 周日视图 周标题 透明度变化动效, 不放缩
    this.weekWeekTitleViewAnimate.opacity = 0;
    this.weekWeekTitleViewAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.weekWeekTitleViewAnimate.scaleOption = { x: 1, y: 1 };
    this.weekWeekTitleViewAnimate.translateOptions = { x: 0, y: 0 };
    this.weekDateAnimate.opacity = 0;
    this.weekDateAnimate.opacityAnimateParam = { duration: 50, curve: Curve.Sharp }
    this.weekGanttAnimate.opacity = 0;
    this.weekGanttAnimate.translateOptions = { y: 350 }
    this.weekGanttAnimate.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
    this.weekGanttAnimate.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.SelectedAgendaViewAnimateParam.opacityAnimateParam = { duration: 100, curve: Curve.Sharp }
    this.SelectedAgendaViewAnimateParam.translateOptions = { y: 350 }
    this.SelectedAgendaViewAnimateParam.translateAnimateParam = {
      duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction
    };
  }

  weekFinish() {
    this.weekWeekTitleViewAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.weekDateAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.weekGanttAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.weekWeekTitleViewAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.weekDateAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.weekGanttAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.weekWeekTitleViewAnimate.opacity = 1;
    this.weekDateAnimate.opacity = 1;
    this.weekGanttAnimate.opacity = 1;
    this.SelectedAgendaViewAnimateParam.translateOptions = { x: 0, y: 0, z: 0 };
    this.SelectedAgendaViewAnimateParam.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.SelectedAgendaViewAnimateParam.opacity = 1;
  }

  monthFinish() {
    this.monthWeekTitleViewAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.monthAgendaViewAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.monthDateViewAnimate.translateOptions = { x: 0, y: 0, z: 0 };
    this.monthWeekTitleViewAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.monthAgendaViewAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.monthDateViewAnimate.scaleOption = { x: 1, y: 1, centerX: 0, centerY: 0 };
    this.monthWeekTitleViewAnimate.opacity = 1;
    this.monthAgendaViewAnimate.opacity = 1;
    this.monthDateViewAnimate.opacity = 1;
  }

  yearFinish() {
    // 切换到年后需要重新设置一下月的动效,用于防止年点击其他月份切换到月触发组件构建导致动效参数更新不及时
    this.YearToMonth();
  }

  changeVisibleByIndex(tabType: TabType) {
    this.yearVisibleChange(tabType === TabType.YEAR);
    this.monthVisibleChange(tabType === TabType.MONTH);
    this.weekVisibleChange(tabType === TabType.WEEK);
  }

  yearVisibleChange(isVisibility: boolean) {
    this.yearViewAnimateParam.visibility = isVisibility;
    this.yearLegendAnimateParam.visibility = isVisibility;
  }

  monthVisibleChange(isVisibility: boolean) {
    this.monthWeekTitleViewAnimate.visibility = isVisibility;
    this.monthDateViewAnimate.visibility = isVisibility;
    this.monthAgendaViewAnimate.visibility = isVisibility;
  }

  weekVisibleChange(isVisibility: boolean) {
    this.weekWeekTitleViewAnimate.visibility = isVisibility;
    this.weekDateAnimate.visibility = isVisibility;
    this.weekGanttAnimate.visibility = isVisibility;
    this.SelectedAgendaViewAnimateParam.visibility = isVisibility;
  }

  /**
   * 改变Tabs的索引值
   *
   * @param index 索引值
   * @param isTabChangeCallback 是否点击tab页签触发change
   */
  async changeTabsIndex(index: number, isTabChangeCallback: boolean = false): Promise<void> {
    Log.log(TAG, 'changeTabsIndex：' + index);
    if (!this.tabIndexPreferences) {
      return;
    }
    if (this.tabsIndex !== index) {
      ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchTab,
        { SOURCE_PAGE: this.tabsIndex, TARGET_PAGE: index })
    }
    this.initTabIndex = this.setTabIndex(index);
    GlobalData.instance().set(GlobalDataKeys.TAB_INDEX, index);
    this.tabsController.changeIndex(this.initTabIndex);
    try {
      this.tabIndexPreferences.putSync('tabIndex', index);
      await this.tabIndexPreferences.flush();
      Log.log(TAG, `save index into preferences success`);
    } catch (error) {
      Log.error(TAG, `save index into preferences err,code :${error?.code}, message:${error?.message}`);
    }
  }

  setTabIndex(index: number) {
    return Math.min(index, 2);
  }

  // 用于初始化年视图宽高
  initYearAnimationParam() {
    const selfInfo = componentUtils.getRectangleById(CompId.MAIN_TAB_COMPONENT);
    const width = px2vp(selfInfo.size.width);
    const height = px2vp(selfInfo.size.height);

    this.yearAnimationParam.componentWidth = width;
    this.yearAnimationParam.componentHeight = height - 30;
    YearViewLayoutModel.instance().onSizeChange(
      Math.round(width), Math.round(height));
    const colCount = YearViewLayoutModel.instance().gridProp.value.colCount;
    const minHeight = YearViewLayoutModel.instance().gridProp.value.minHeight;
    const displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    this.yearAnimationParam.changeYearAnimationParam(displayDate, colCount, minHeight, true);

  }

  //初始化年视图动效参数
  initYearAnimateParam() {
    if (this.tabsIndex === TabType.YEAR) {
      this.yearViewAnimateParam.visibility = true;
      this.yearLegendAnimateParam.visibility = true;
    } else {
      this.yearViewAnimateParam.visibility = false;
      this.yearLegendAnimateParam.visibility = false;
    }
    Log.info(TAG, 'yearViewAnimateParam init is ' + JSON.stringify(this.yearViewAnimateParam));
  }

  //初始化月视图动效参数
  initMonthAnimateParam() {
    if (this.tabsIndex === TabType.MONTH) {
      // 控制不出现动效
      this.monthDateViewAnimate.visibility = true;
      this.monthWeekTitleViewAnimate.visibility = true;
      this.monthAgendaViewAnimate.visibility = true;
    } else {
      this.monthDateViewAnimate.visibility = false;
      this.monthAgendaViewAnimate.visibility = false;
      this.monthWeekTitleViewAnimate.visibility = false;
    }
    Log.info(TAG, 'monthWeekTitleViewAnimate init is ' + JSON.stringify(this.monthWeekTitleViewAnimate));
    Log.info(TAG, 'monthAgendaViewAnimate init is ' + JSON.stringify(this.monthAgendaViewAnimate));
    Log.info(TAG, 'monthDateViewAnimate init is ' + JSON.stringify(this.monthDateViewAnimate));
  }

  //初始化周视图动效参数
  initWeekAnimateParam() {
    if (this.tabsIndex === TabType.WEEK || this.tabsIndex === TabType.DAY) {
      this.weekDateAnimate.visibility = true;
      this.weekGanttAnimate.visibility = true;
      this.weekWeekTitleViewAnimate.visibility = true;
      this.SelectedAgendaViewAnimateParam.visibility = true;
    } else {
      this.weekDateAnimate.visibility = false;
      this.weekGanttAnimate.visibility = false;
      this.weekWeekTitleViewAnimate.visibility = false;
      this.SelectedAgendaViewAnimateParam.visibility = false;
    }
    Log.info(TAG, 'weekDateAnimate init is ' + JSON.stringify(this.weekDateAnimate));
    Log.info(TAG, 'weekGanttAnimate init is ' + JSON.stringify(this.weekGanttAnimate));
  }

  build() {
    /* 年月视图 */
    Tabs({
      index: this.initTabIndex, controller: this.tabsController
    }) {
      TabContent() {
        YearView()
      }
      .zIndex(this.layouts[TabType.YEAR].zIndex)
      .tabBar(new SubTabBarStyle(''))

      TabContent() {
        MonthlyView()
      }
      .zIndex(this.layouts[TabType.MONTH].zIndex)
      .tabBar(new SubTabBarStyle(''))

      TabContent() {
        WeekView()
      }
      .zIndex(this.layouts[TabType.WEEK].zIndex)
      .tabBar(new SubTabBarStyle(''))
    }
    .vertical(false)
    .barHeight(0) // 将原始的bar高度强制设置为0,避免默认占用空间
    .customContentTransition(this.baseCustomAnimation)
    .barMode(BarMode.Scrollable)
    .animationDuration(0)
    .onChange((index: TabType) => {
      Log.log(TAG, "onChange：" + index);
    })
    .width('100%')
    .height('100%')
    .layoutWeight(1)
    .zIndex(1)
    .id(CompId.MAIN_TAB_COMPONENT)
    .allowDrop(this.isOnDropAllowed ? [UTD.UniformDataType.PLAIN_TEXT] : [])
    .onDrop((dragEvent?: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDrop);
      if (!this.isOnDropAllowed) {
        return;
      }
      this.processDataFromUdmf(dragEvent as DragEvent);
    })
    .focusable(this.tabsIndex === TabType.MONTH || this.tabsIndex === TabType.YEAR
      ? undefined : false)
  }

  //年视图初始无动效
  private initYearViewAnimateParam() {
    this.yearViewAnimateParam.opacity = 1;
    this.yearViewAnimateParam.scaleOption = { x: 1, y: 1 }

    this.yearLegendAnimateParam.opacity = 1;
    this.yearLegendAnimateParam.scaleOption = { x: 1, y: 1 }
  }

  //月视图初始无动效
  private initMonthViewAnimateParam() {
    this.monthDateViewAnimate.opacity = 1;
    this.monthDateViewAnimate.scaleOption = { x: 1, y: 1 }

    this.monthWeekTitleViewAnimate.opacity = 1;
    this.monthWeekTitleViewAnimate.scaleOption = { x: 1, y: 1 }

    this.monthAgendaViewAnimate.opacity = 1;
    this.monthAgendaViewAnimate.scaleOption = { x: 1, y: 1 }
  }

  //周视图初始无动效
  private initWeekViewAnimateParam() {
    this.weekDateAnimate.opacity = 1;
    this.weekDateAnimate.scaleOption = { x: 1, y: 1 }
    this.weekDateAnimate.translateOptions = { x: 0, y: 0 };

    this.weekGanttAnimate.opacity = 1;
    this.weekGanttAnimate.scaleOption = { x: 1, y: 1 }
    this.weekGanttAnimate.translateOptions = { x: 0, y: 0 };

    this.weekWeekTitleViewAnimate.opacity = 1;
    this.weekWeekTitleViewAnimate.scaleOption = { x: 1, y: 1 }
    this.weekWeekTitleViewAnimate.translateOptions = { x: 0, y: 0 };

    this.SelectedAgendaViewAnimateParam.opacity = 1;
    this.SelectedAgendaViewAnimateParam.scaleOption = { x: 1, y: 1 }
    this.SelectedAgendaViewAnimateParam.translateOptions = { x: 0, y: 0 };
  }

  // 从不同Tab初始化时, 需要设定不同的初始值, 1: 保证创建过程无动效, 2:保证切换时，初始动效值
  private initTabAnimController() {
    this.initYearViewAnimateParam();
    this.initMonthViewAnimateParam();
    this.initWeekViewAnimateParam();

    this.initYearAnimateParam();
    this.initMonthAnimateParam();
    this.initWeekAnimateParam();
  }

  // 年视图与其它视图切换时动效一致
  private setYearViewParam() {
    this.yearViewAnimateParam.opacity = 0;
    this.yearViewAnimateParam.opacityAnimateParam = { duration: 50, delay: 50, curve: Curve.Sharp };
    this.yearViewAnimateParam.scaleOption = {
      x: 3,
      y: 3,
      centerX: this.yearAnimationParam.centerX,
      centerY: this.yearAnimationParam.centerY
    };
    this.yearViewAnimateParam.scaleAnimateParam = { duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction };
    // 天干地支不透明度变化
    this.yearLegendAnimateParam.opacity = 0;
    this.yearLegendAnimateParam.opacityAnimateParam = { duration: 50, curve: Curve.Sharp };
    Log.info(TAG, "yearViewAnimateParam is " + JSON.stringify(this.yearViewAnimateParam))
  }

  private setMonthViewDateViewScale(needScale: boolean) {
    if (needScale) {
      this.monthDateViewAnimate.scaleOption = {
        x: 0.3,
        y: 0.3,
        centerX: this.yearAnimationParam.centerX,
        centerY: this.yearAnimationParam.centerY
      }
    } else {
      this.monthDateViewAnimate.scaleOption = {
        x: 1,
        y: 1,
        centerX: 0,
        centerY: 0
      }
    }
  }

  private setWeekDateViewParam(needAnimate: boolean) {
    if (needAnimate) {
      this.weekDateAnimate.opacity = 0;
      this.weekDateAnimate.opacityAnimateParam = { duration: 150, delay: 150, curve: Curve.Sharp }
      this.weekDateAnimate.scaleOption = {
        x: 0.3,
        y: 0.3,
        centerX: this.yearAnimationParam.centerX,
        centerY: this.yearAnimationParam.centerY
      };
      this.weekDateAnimate.scaleAnimateParam = { duration: this.TOTAL_ANIMATION_DURATION, curve: Curve.Friction };
    } else {
      this.weekDateAnimate.opacity = 1;
      this.weekDateAnimate.scaleOption = {
        x: 1,
        y: 1,
        centerX: 0,
        centerY: 0
      };
    }
    Log.info(TAG, "weekDateAnimate: " + JSON.stringify(this.weekDateAnimate));
  }

  /**
   * 跳转到日程列表
   * @param eventInfo 携带的预置日程信息
   */
  private jumpToCreateAgenda(eventInfo: AgendaEventInfo) {
    let eventData: emitter.EventData = {
      data: {
        'eventInfo': JSON.stringify(eventInfo),
        'intent': CreateAgendaPageSource.NLU_CREATE_AGENDA_PAGE,
        'action': 'CLICK_CREATE_EVENT'
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
  }

  /**
   * 处理拖拽事件
   * @param event
   */
  private async processDataFromUdmf(event: DragEvent) {
    if (verifyDataFromUdmf(event)) {
      const eventInfo: AgendaEventInfo = await parseDataFromUdmf(event);
      this.jumpToCreateAgenda(eventInfo);
      return;
    }
  }

  private baseCustomAnimation: (from: number, to: number) => TabContentAnimatedTransition = (from: number, to: number) => {
    Log.log(TAG, "baseCustomAnimation, from: " + from + ", to: " + to)

    // 转场动画参数需要先设置, 再在闭包内触发动画, 否则可能出现未使用更新后参数执行动画的问题
    this.tables.forEach(value => {
      if (value.currentTab === from) {
        if (value.targetTab.indexOf(to) !== -1) {
          value.setAnimParam();
        }
      }
    })

    return {
      timeout: 500,
      // Called when custom content transition animation start.
      transition: (proxy: TabContentTransitionProxy) => {
        Log.log(TAG, "from: " + proxy.from + ", to: " + proxy.to)
        animateTo({
          duration: this.TOTAL_ANIMATION_DURATION,
          onFinish: () => {
            Log.log(TAG, "finishTransition");

            this.tables.forEach(value => {
              if (value.currentTab === from) {
                if (value.targetTab.indexOf(to) !== -1 && value.finishFunc) {
                  value.finishFunc();
                }
              }
            })
            proxy.finishTransition()
          }
        }, () => {
          this.layouts[from].zIndex = 1;
          this.layouts[to].zIndex = 2;
          // 通知页面内部开始执行动画

          this.tables.forEach(value => {
            if (value.currentTab === from) {
              if (value.targetTab.indexOf(to) !== -1) {
                value.changeFunc();
              }
            }
          })
        })
      }
    } as TabContentAnimatedTransition;
  }
}

// 定义每个TabContent的相关属性
interface TabContentLayout {
  zIndex: number;
}

class itTmp {
  $rect: Array<number> = []
}

class TabTransfer {
  public currentTab: TabType;

  public setAnimParam: Function;

  public changeFunc: Function;

  public finishFunc?: Function;

  public targetTab: TabType[];

  constructor(currentTab: TabType, targetTab: TabType[], setAnimParam: Function,
              changeFunc: Function, finishFunc?: Function) {
    this.currentTab = currentTab;
    this.targetTab = targetTab;
    this.setAnimParam = setAnimParam;
    this.changeFunc = changeFunc;
    this.finishFunc = finishFunc;
  }
}