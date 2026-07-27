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

import { WeekTitleView } from './WeekTitleView';
import { DateView } from './DateView';
import { GanttView } from './GanttView';
import { RootViewModel } from '../viewmodel/RootViewModel';
import { TabType } from '@app/common/src/main/ets/default/common/declare';
import { CHINESE_HOLIDAY_STATE_VALUE, CombineAnimateParam, CommonInnerEvent, CompId, EmitterCollector, GlobalDataKeys, I18nUtil, Log,
  SafeUtil } from '@app/common';
import { RootModel } from '../model/RootModel';
import { emitter } from '@kit.BasicServicesKit';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { SelectedAgendaView } from './SelectedAgendaView';
import { focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'WeekView';

// 周/日视图
@Component({ freezeWhenInactive: true })
export struct WeekView {
  @Consume navPathStack: NavPathStack;

  @StorageLink('tabIndex') curTab: TabType = TabType.WEEK;

  @Provide rootVM: RootViewModel = new RootViewModel(this.curTab);

  @StorageLink('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = 0;

  @StorageProp('systemRegion') @Watch('onSystemRegion') systemRegion: string = 'CN';

  @StorageLink('weekends') @Watch('onWeekendsChange') weekends: number[] = [-1];

  @StorageLink('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = -1;

  @StorageProp('showWeekNumber') @Watch('onShowWeekNumberChange') showWeekNumber: boolean = false;

  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  // 窗口宽度
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  //中国节假日开关状态
  @StorageProp('CHINESE_HOLIDAY_STATE') @Watch('onChineseHolidayStateChange') chineseHolidayState:
    CHINESE_HOLIDAY_STATE_VALUE = AppStorage.get('CHINESE_HOLIDAY_STATE') ?? CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN;

  // 显示隐藏日程列表
  @Consume @Watch('onAgendaListStateChange') hideAgendaWindowDay: boolean;

  @Consume needShowHideButton: boolean; // 是否需要显示详情开合按钮

  @Consume weekDateAnimate: CombineAnimateParam;

  @Consume weekWeekTitleViewAnimate: CombineAnimateParam;

  @Consume weekGanttAnimate: CombineAnimateParam;

  @Consume('SelectedAgendaViewAnimateParam') selectedAgendaViewAnimateParam: CombineAnimateParam;

  @State rootLoaded: boolean = false;

  @Provide dragEventState: DragEventState = new DragEventState();

  private traceEvent: string = traceEvents.weekViewSwipe;

  //刷新视图用标志位
  private swiperFlag: boolean = false;

  private ganttSwiperFlag: boolean = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.weekViewAppear, 0);
    this.rootVM.init(this.windowWidth);
    this.hideAgendaWindowDay = this.rootVM.hideAgendaWindow;
    this.needShowHideButton = true;
    RootModel.instance().language = this.language;
    this.emitterCollector.on({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB },
      (eventData: emitter.EventData) => {
        const tabIndex: TabType = eventData?.data?.tabIndex as TabType;
        if (tabIndex !== TabType.WEEK && tabIndex !== TabType.DAY) {
          return;
        }
        this.curTab = tabIndex;
        this.onTabChange();
      }
    );
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_START_OF_WEEK }, this.startOfWeekChangeHandler);
    // 其它历法变更：通过 emitter 广播触发，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_OTHER_CALENDAR }, this.subscriptionCalendarChangeHandler);
    // 显示周数变更：通过 emitter 广播触发，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
    this.emitterCollector.on({ eventId: CommonInnerEvent.SETTINGS_SHOW_WEEK_NUMBER }, this.showWeekNumberChangeHandler);
    hiTraceMeter.finishTrace(traceEvents.weekViewAppear, 0);
  }

  aboutToDisappear() {
    this.emitterCollector.off();
    this.rootVM.destroy();
  }

  @Builder
  WeekViewSwiper() {
    Swiper(this.rootVM.dateSwiperController) {
      ForEach(RootModel.instance().SWIPER_ARRAY, (_: number, index: number) => {
        DateView({ dateVM: this.rootVM.dateVMs[index], dateViewAnimate: this.weekDateAnimate })
      })
    }
    .id(CompId.WEEK_VIEW_SWIPER)
    .accessibilityLevel('no')
    .cachedCount(0) // 动态模型下缓存耗时长
    .duration(RootModel.instance().SWIPER_DURATION)
    .size({ width: this.rootVM.weekTitleVM.rootWidth, height: this.rootVM.dateHeight })
    .margin({ bottom: RootModel.instance().DATE_MARGIN_BOTTOM })
    .indicator(false)
    .onAnimationStart((index: number, targetIndex: number) => {
      hiTraceMeter.startTrace(this.traceEvent, 0);
      this.handleAnimationStart(index, targetIndex);
    })
    .onAnimationEnd((index: number) => {
      this.rootVM.onDateSwiperAnimationEnd(index)
      this.handleFocus(index);
      hiTraceMeter.finishTrace(this.traceEvent, 0);
    })
    .onChange((index: number) => {
      this.rootVM.swiperIndex = index;
      this.handleSwiperChange(index);
    })
    .index(this.rootVM.swiperIndex)
    .pageFlipMode(PageFlipMode.SINGLE)
  }

  @Builder
  GanttView() {
    Row() {
      Swiper(this.rootVM.ganttSwiperController) {
        ForEach(RootModel.instance().SWIPER_ARRAY, (_: number, index: number) => {
          GanttView({
            ganttVM: this.rootVM.ganttVMs[index],
            swipeIndex: index,
            mTabType: this.rootVM.tabType,
            ganttViewAnimate: this.weekGanttAnimate,
          })
        })
      }
      .id(CompId.GANTT_VIEW_SWIPER)
      .cachedCount(0) // 动态模型下缓存耗时长
      .duration(RootModel.instance().SWIPER_DURATION)
      .size({ width: this.rootVM.ganttWidth, height: this.rootVM.bottomHeight })
      .margin({ left: this.rootVM.dayGanttViewMargin, right: this.rootVM.dayGanttViewMargin })
      .indicator(false)
      .onAnimationStart((index: number, targetIndex: number) => {
        hiTraceMeter.startTrace(this.traceEvent, 0);
        this.handleAnimationGanttStart(index, targetIndex);
      })
      .borderRadius($r('sys.float.corner_radius_level8'))
      .onAnimationEnd((index: number) => {
        this.rootVM.onGanttSwiperAnimationEnd(index);
        this.handleFocus(this.rootVM.dateSwiperIndex);
        hiTraceMeter.finishTrace(this.traceEvent, 0);
      })
      .onChange((index: number) => {
        this.rootVM.gantIndex = index;
        this.handleGanttSwiperChange(index);
      })
      .index(this.rootVM.gantIndex)

      SelectedAgendaView()
    }
  }

  private handleFocus(index: number) {
    let cellVMs = this.rootVM?.dateVMs[index]?.cellVMs;
    const cellVM = cellVMs?.filter(item => item.isSelect);
    focusComponentById(cellVM[0]?.compId, 300)
  }

  build() {
    Scroll() {
      if (this.rootLoaded) {
        Column() {
          WeekTitleView({ weekTitleViewAnimate: this.weekWeekTitleViewAnimate, viewModel: this.rootVM.weekTitleVM });
          this.WeekViewSwiper();
          this.GanttView();
        }
        .size({ width: '100%', height: '100%' })
        .constraintSize({ minHeight: this.rootVM.MIN_GANTT_VIEW_HEIGHT })
        .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
          this.handleAreaChange(ov, nv);

        })
      }
    }
    .onAppear(() => {
      this.rootLoaded = true;
    })
    .size({ width: '100%', height: '100%' })
    .padding({ top: 12 })
    .id(CompId.WEEK_VIEW_ROOT)
    .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
    .tabIndex(-1)
  }

  handleAreaChange(ov: SizeOptions, nv: SizeOptions) {
    if (ov.width === nv.width && ov.height === nv.height) {
      return;
    }

    Log.log(TAG, `handleAreaChange width = ${nv.width}, height = ${nv.height}`);
    this.rootVM.onSizeChange({ width: nv.width as number, height: nv.height as number });
  }

  handleAnimationStart(index: number, targetIndex: number) {
    Log.log(TAG, `onAnimationStart startIndex ${index} , endIndex ${targetIndex}, swiperFlag ${this.swiperFlag}`);
    //添加标志位用于确定是否执行过AnimationStart
    if (this.swiperFlag) {
      return;
    }
    if (index === targetIndex) {
      return;
    }
    this.swiperFlag = !this.swiperFlag;
    this.rootVM.changeWeekBySwiper(index, targetIndex)
  }

  handleSwiperChange(index: number) {
    Log.log(TAG, `onChange Index ${index} , swiperFlag ${this.swiperFlag}`);

    //标志位判断是否执行过AnimationStart
    if (this.swiperFlag) {
      //执行过AnimationStart,无需再次刷新
      this.swiperFlag = false;
      return;
    }
    //未执行过则需要刷新,更改标志位标志正在刷新
    this.swiperFlag = !this.swiperFlag;
    this.rootVM.changeWeekBySwiper(this.rootVM.dateSwiperIndex, index);
    this.swiperFlag = !this.swiperFlag;
  }

  handleAnimationGanttStart(index: number, targetIndex: number) {
    Log.log(TAG,
      `onAnimationGanttStart startIndex ${index} , endIndex ${targetIndex}, swiperFlag ${this.ganttSwiperFlag}`);
    //添加标志位用于确定是否执行过AnimationStart
    if (this.ganttSwiperFlag) {
      return;
    }
    if (index === targetIndex) {
      return;
    }
    this.ganttSwiperFlag = !this.ganttSwiperFlag;
    this.rootVM.changeDayBySwiper(index, targetIndex)
  }

  handleGanttSwiperChange(index: number) {
    Log.log(TAG, `onChange Index ${index} , swiperFlag ${this.ganttSwiperFlag}`);
    //执行过AnimationStart,无需再次刷新
    if (this.ganttSwiperFlag) {
      this.ganttSwiperFlag = !this.ganttSwiperFlag;
      return;
    }
    // 日视图翻页动画用
    if (this.rootVM.dateSwipeFlag) {
      this.rootVM.dateSwipeFlag = false;
      return;
    }
    //未执行过则需要刷新,更改标志位标志正在刷新
    this.ganttSwiperFlag = !this.ganttSwiperFlag;
    this.rootVM.changeDayBySwiper(this.rootVM.ganttSwiperIndex, index);
    this.ganttSwiperFlag = !this.ganttSwiperFlag;
  }

  onTabChange(): void {
    if (this.curTab != TabType.WEEK && this.curTab != TabType.DAY) {
      this.rootLoaded = false;
    } else {
      SafeUtil.setTimeout(() => {
        this.rootLoaded = true;
      }, 16); // 延迟一帧送显
    }
    this.rootVM.onTabChange(this.curTab);
    this.traceEvent = this.curTab === TabType.WEEK ? traceEvents.weekViewSwipe : traceEvents.dayViewSwipe;
    if (this.curTab === TabType.DAY) {
      this.hideAgendaWindowDay = this.rootVM.hideAgendaWindow;
      this.needShowHideButton = true;
      this.selectedAgendaViewAnimateParam.visibility = true;
    } else if (this.curTab === TabType.WEEK) {
      this.selectedAgendaViewAnimateParam.visibility = false;
    }
  }

  onStartOfWeekChange(): void {
    this.rootVM.onStartOfWeekChange(this.startOfWeek);
  }

  // 一周开始日变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private startOfWeekChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const startOfWeek = AppStorage.get<number>(GlobalDataKeys.START_OF_WEEK) ?? 0;
    this.rootVM.onStartOfWeekChange(startOfWeek);
  };

  // 其它历法变更事件处理, 绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private subscriptionCalendarChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const subscriptionCalendar = AppStorage.get<number>(GlobalDataKeys.SUBSCRIPTION_CALENDAR) ?? -1;
    this.rootVM.onSubscriptionCalendarChange(subscriptionCalendar);
  };

  // 显示周数变更事件处理，绕过 freezeWhenInactive 导致 @Watch 不触发的问题
  private showWeekNumberChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const showWeekNumber = AppStorage.get<boolean>(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON) ?? false;
    this.rootVM.onShowWeekNumberChange(showWeekNumber);
  };

  onWeekendsChange(): void {
    this.rootVM.onWeekendsChange(this.weekends);
  }

  onSubscriptionCalendarChange(): void {
    this.rootVM.onSubscriptionCalendarChange(this.subscriptionCalendar);
  }

  onSystemRegion(): void {
    Log.info(TAG, 'onSystemRegion:' + this.systemRegion);
    this.rootVM.onSystemRegionChange(this.systemRegion);
    // 地区变更，触发地区默认的一周开始日变更
    Log.info(TAG, 'onStartOfWeekChange by onSystemRegionChange');
    this.onStartOfWeekChange();
  }

  onChineseHolidayStateChange(): void {
    this.rootVM.onChineseHolidayStateChange(this.chineseHolidayState);
  }

  onShowWeekNumberChange(): void {
    this.rootVM.onShowWeekNumberChange(this.showWeekNumber);
  }

  onLanguageChange(): void {
    RootModel.instance().language = this.language;
    this.rootVM.onLanguageChange(this.language);
  }

  onAgendaListStateChange(): void {
    if (this.curTab !== TabType.DAY) {
      return;
    }
    const isMirror = I18nUtil.isUyghurLanguage(this.language);
    const offsetX = (isMirror ? -1 : 1) * this.rootVM.weekTitleVM.rootWidth / 2;
    this.selectedAgendaViewAnimateParam.translateOptions = { x: offsetX, y: 0, z: 0 };
    this.selectedAgendaViewAnimateParam.translateAnimateParam = {
      duration: 300, curve: Curve.Friction
    };
    // 日程详情显隐
    this.rootVM.onAgendaListStateChange(this.hideAgendaWindowDay);
  }
}

export class DragEventState {
  public dragEventId: number = 0;
  public dragEventInstanceStartMill: number = 0;
  public dragEventIsMultiDayEvent: boolean = false;
}