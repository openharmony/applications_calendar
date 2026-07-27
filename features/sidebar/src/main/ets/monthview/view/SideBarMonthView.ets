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
  CalendarDate,
  CalendarUtils,
  CommonInnerEvent,
  CompId,
  DateManager,
  DateTitleUtil,
  DateUtil,
  DayData,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ReportUtil,
  statisticEvents,
  TabType,
  ThrottleFunction
} from '@app/common';
import { SideBarMonthViewLayout } from '../model/SideBarMonthViewLayout';
import { SideBarMonthViewModel } from '../model/SideBarMonthViewModel';
import { WeekTitleViewModel } from '../model/WeekTitleViewModel';
import { SingleMonthView } from './SingleMonthView';
import emitter from '@ohos.events.emitter';
import { ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = '[SideBar][MonthView]';

/**
 * Year View
 * The single year view is a super-large component. When slide the view, the entire page cannot be redrawn.
 * @since 2022-03-01
 */
@Preview
@Component
export struct SideBarMonthView {
  // PC上今天两侧箭头触发刷新
  @Watch('onDisplayDateChange') @Link displayDate: number;

  @Consume @Watch('onShowLeftBarChanged') isShowLeftBar: boolean;

  // tab页签索引
  @StorageProp('tabIndex') tabsIndex: number = TabType.MONTH;

  // 一周起始日
  @StorageProp('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = 0;

  // 显示/隐藏班休信息

  // 系统地区
  @StorageProp('systemRegion') systemRegion: string = 'CN';

  // 周末
  @StorageLink('weekends') weekends: number[] = [];

  // 主题色
  @StorageProp('themeColor') themeColor: string = '';

  //系统语言
  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  // 系统时间当天的时间戳
  @StorageProp(GlobalDataKeys.CURRENT_DATE) @Watch('onCurrentDateChange') currentDate: number = 0;

  @State currentIndex: number = 1;

  @State swipeCount: number = 3; // need move into view model in the future

  @State viewModel: SideBarMonthViewModel = new SideBarMonthViewModel(new CalendarDate(this.displayDate));

  private layout: SideBarMonthViewLayout = SideBarMonthViewLayout.getInstance();

  // 每帧时长，KLV目前是1s/帧率，去各种设备最大值，klv的16.7.
  readonly MAX_IDEAL_FRAME_TIME: number = 17;

  private swiperController: SwiperController = new SwiperController();

  private readonly yearMonthArray: number[] = new Array<number>();

  private yearBorderColor: string = '#ffd9d9d9';

  private nowDate = new CalendarDate(DateUtil.getStartOfDayTimeStamp());

  aboutToAppear() {
    for (let index = 0; index < this.swipeCount; ++index) {
      this.yearMonthArray.push(index);
    }
  }

  onLanguageChange(): void {
    this.viewModel.onLanguageChange(this.language);
  }

  onCurrentDateChange(): void {
    // 实时时间 变更，状态机记录
    let currentDate = new CalendarDate(this.currentDate);

    //当年月日变化时需要更新视图
    if (currentDate.getDate() !== this.nowDate.getDate()
      || currentDate.getMonth() !== this.nowDate.getMonth()
      || currentDate.getFullYear() !== this.nowDate.getFullYear()) {
      this.yearMonthArray.forEach((index: number) => {
        this.viewModel.singleMonthVMs[index].updateDate(this.nowDate, currentDate);
      })
      this.nowDate = currentDate;
    }

  }

  onShowLeftBarChanged() {
    // only switch to YEAR start work
    if (!this.isShowLeftBar) {
      return;
    }
    // 当侧边栏打开后,开始刷新数据
    this.currentIndex = this.viewModel.updateBySelectedDate();
    Log.log(TAG, "this.currentIndex: " + this.currentIndex);
  }

  onStartOfWeekChange() {
    let startOfWeek = this.startOfWeek;
    if (startOfWeek === -1) { // switch default
      startOfWeek = DateUtil.getDefaultStartOfWeek();
    }
    WeekTitleViewModel.getInstance().onStartOfWeekChange(startOfWeek);
    this.viewModel.onStartOfWeekChange(startOfWeek);
  }

  // 状态改变触发刷新
  onDisplayDateChange() {
    setTimeout(() => this.handleDisplayDateChangeAfterDelay(), this.MAX_IDEAL_FRAME_TIME);
  }

  // 侧边栏mini月视图绘制任务重，挪后一帧处理，优化响应时延。
  handleDisplayDateChangeAfterDelay(): void {
    const curYear: number = this.viewModel.curDisplayDay.solarYear;
    const curMonth: number = this.viewModel.curDisplayDay.solarMonth;
    const targetDate: CalendarDate = new CalendarDate(this.displayDate);
    const targetYear: number = targetDate.getFullYear();
    const targetMonth: number = targetDate.getMonth() + 1;
    const subMonth: number = (targetYear - curYear) * 12 + targetMonth; //计算相差月份
    Log.info(TAG, `onDisplayDateChange: cur:${curYear} to ${targetYear}, ${curMonth} to ${targetMonth}`);
    if (targetYear === curYear && targetMonth === curMonth) {
      Log.info(TAG, `not need change`);
    } else if (subMonth > curMonth + 1 || subMonth < curMonth - 1) {
      // over swipe range, need jump
      this.viewModel.updateByYearMonth(targetYear, targetMonth);
      this.viewModel.curDisplayDay = DayData.buildByDate(new CalendarDate(this.displayDate));
      this.currentIndex = 1;
    } else {
      let targetIndex = 0;
      if (subMonth === curMonth + 1) {
        // swipe to right
        targetIndex = this.currentIndex < this.swipeCount - 1 ? this.currentIndex + 1 : 0;
      } else if (subMonth === curMonth - 1) {
        // swipe to left
        targetIndex = this.currentIndex > 0 ? this.currentIndex - 1 : this.swipeCount - 1;
      }
      this.viewModel.updateBySwipe(this.currentIndex, targetIndex)
      this.currentIndex = targetIndex;
    }

    // 响应选中日期变化
    this.viewModel.singleMonthVMs.forEach((item) => {
      item.onSelectedDateChange();
    })
  }

  build() {
    Column() {
      MiniDateSwitch({
        displayDate: this.displayDate,
        buttonText: $r('app.string.today'),
        onClickLeftArrow: () => {
          GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE
            , DateUtil.getOffsetMonthTimeStamp(this.displayDate, -1));
          //额外进行广播通知当前日期改变
          emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
        },
        onClickRightArrow: () => {
          GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE
            , DateUtil.getOffsetMonthTimeStamp(this.displayDate, 1));
          //额外进行广播通知当前日期改变
          emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
        }
      })

      Swiper(this.swiperController) {
        ForEach(this.yearMonthArray, (index: number) => {
          SingleMonthView({
            viewModel: this.viewModel.singleMonthVMs[index],
            displayMonth: this.viewModel.singleMonthVMs[index].month,
            dateSelected: this.dateSelected
          })
        }, (index: number) => index.toString())
      }
      .id(CompId.SIDEBAR_DATE_INFO)
      .index(this.currentIndex)
      .autoPlay(false)
      .indicator(false) // 默认开启指示点
      .loop(true) // 默认开启循环播放
      .duration(300)
      .vertical(false)
      .cachedCount(0) //swiper缓存数量，默认值为1，PC上因为整机20窗负载问题，暂时切换为0
      .onChange((index: number) => {
        Log.debug(TAG, "from：" + this.currentIndex + " to:" + index);
        this.onChange(index);
      })
      .layoutWeight(1)
      .margin({
        left: this.layout.monthWidthMargin,
        right: this.layout.monthWidthMargin
      })
      .tabIndex(-1)
    }
    .padding({
      left: this.layout.monthWidthMargin,
      right: this.layout.monthWidthMargin,
      top: this.layout.monthTopMargin,
      bottom: this.layout.monthBottomMargin
    })
    .width('100%')
    .layoutWeight(1)
    .height(this.layout.sidebarMonthHeight)
  }

  // selectMonth 自然月
  dateSelected: Function = (displayMills: number) => {
    this.changeDisplayDate(displayMills);
    this.jumpMonthTab();
  };

  private changeDisplayDate(displayMills: number) {
    if (displayMills === -1) { // 传值为-1则不进行跳转,-1为正常无法出现的displayDate值,仅作为跳过逻辑用传值
      return;
    }
    // 开始进行日期跳转
    Log.log(TAG, 'miniDateSelected set displayDate:' + displayMills);
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, displayMills);
    //额外进行广播通知当前日期改变
    emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
  }

  private jumpMonthTab() {
    if (this.tabsIndex === TabType.MONTH) { //已经在月视图不用多此一举进行跳转
      return;
    }
    let eventData: emitter.EventData = {
      data: {
        'tabIndex': TabType.MONTH,
      }
    };
    Log.log(TAG, `dateSelected emit`);
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData)
    ReportUtil.reportStatisticEvent(statisticEvents.yearClickDate);
  }

  // 限流，刷新视图
  private onChange: (index: number) => void = (index: number) => {
    Log.debug(TAG, "from：" + this.currentIndex + " to:" + index);
    if (this.currentIndex === index) {
      return;
    }

    this.viewModel.updateBySwipe(this.currentIndex, index);
    this.currentIndex = index;
    ThrottleFunction.instance().throttle(TAG, (): void => {
      const displayDate = this.viewModel.curDisplayDay.getDate();
      Log.debug(TAG, `new displayDate: ${displayDate.toLocaleDateString()}}`);
      // 获取滑动之后的目标年
      let targetYear = displayDate.getFullYear()
      // 获取滑动之后的目标月
      let targetMonth = displayDate.getMonth()
      // 获取当前选中的日
      let selectDay = DateManager.getInstance().selectedDay
      let targetDate: number = new CalendarDate(targetYear, targetMonth, selectDay.solarDay).getTime()

      if (DateUtil.isSelectDayInit(targetYear)) {
        targetDate = DateUtil.dateToStamp(targetYear, targetMonth, 1);
      }
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, targetDate); // 通知其它界面变化
      //额外进行广播通知当前日期改变
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
      let params: ReportHiEventParams = {
        SOURCE_PAGE: TabType.MINI_MONTH,
        TYPE: 0,
      }
      ReportUtil.reportStatisticEvent(statisticEvents.mainPageSwitchView, params);
    }, 200);
  };
}

@Component
export struct MiniDateSwitch {
  // 文本文字
  @State buttonText: Resource = $r('app.string.today');

  @Link displayDate: number;

  //系统语言
  @StorageLink('language') language: string = '';

  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 100;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private layout: SideBarMonthViewLayout = SideBarMonthViewLayout.getInstance();

  @Styles
  focusStyles(){
    .focusable(true)
    .focusBox({
      margin: LengthMetrics.vp(-1)
    })
  }

  //左箭头
  @Builder
  buildLeftArrow() {
    Button({ type: ButtonType.Normal }) {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize('20vp')
        .fontColor([$r('sys.color.icon_primary')])
        .focusStyles()
    }
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
    .width(20)
    .height(this.layout.sidebarDateSwitchHeight)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      ThrottleFunction.instance().throttle(TAG, (): void => {
        this.onClickLeftArrow();
      }, this.DELAY)
    })
    .hoverEffect(HoverEffect.Highlight)
    .id(CompId.SIDEBAR_DATE_SWITCH_LEFT_ARROW)
  }

  //年、月
  @Builder
  buildDateInfo() {
    Text(DateTitleUtil.formatTitle(this.displayDate, TabType.MINI_MONTH, this.language))
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      .fontColor($r('sys.color.font_primary'))
      .height(this.layout.sidebarDateSwitchHeight)
      .textAlign(TextAlign.Center)
      .fontFamily('HarmonyHeiTi')
      .id(CompId.SIDEBAR_DATE_INFO)
      .gesture(
        GestureGroup(GestureMode.Parallel,
          TapGesture({ count: 2 })
            .onAction(() => {
              ThrottleFunction.instance()
                .throttle(TAG, () => {
                  // 同一天不触发回到今天
                  if (CalendarUtils.isSameDay(Date.now(),
                    GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number)) {
                    return;
                  }
                  // 1. 修改全局 DisplayDay
                  GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
                  // 2. 触发事件,通知各个模块响应 回到今天
                  emitter.emit({ eventId: CommonInnerEvent.BACK_TO_TODAY });
                }, 1000);
            })
        )
      )
  }

  //右箭头
  @Builder
  buildRightArrow() {
    Button({ type: ButtonType.Normal }) {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize('20vp')
        .fontColor([$r('sys.color.icon_primary')])
        .focusStyles()
    }
    .width(20)
    .height(this.layout.sidebarDateSwitchHeight)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      ThrottleFunction.instance().throttle(TAG, (): void => {
        this.onClickRightArrow();
      }, this.DELAY)
    })
    .hoverEffect(HoverEffect.Highlight)
    .id(CompId.SIDEBAR_DATE_SWITCH_RIGHT_ARROW)
  }

  build() {
    Row() {
      this.buildLeftArrow();
      this.buildDateInfo();
      this.buildRightArrow();
    }.justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level5') })
    .renderGroup(true)
  }

  // 点击左箭头
  private onClickLeftArrow: () => void = () => {
  };

  // 点击右箭头
  private onClickRightArrow: () => void = () => {
  };
}