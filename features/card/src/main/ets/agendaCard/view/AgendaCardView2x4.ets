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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { CardSingleDayViewModel, CompressedDayData } from '../../monthCard/viewModel/components/CardSingleDayViewModel';
import {
  AgendaCardGroup,
  AgendaCardInfo,
  FormUtils,
  OneKeyServiceButtonType,
  Want
} from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { DIMENSION_2_4, jumpToServiceApp } from '../../utils/CardJumpUtils';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import i18n from '@ohos.i18n';
import { InitCardView2x4_4x4 } from '../../view/InitCardView';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { decompressData, crossDayExceptionCheckAndRetry } from '../../utils/CardUtils';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { CardAction } from '../../common/CardAction';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { CardUiUtils } from '../../utils/CardUiUtils';
import { CardAgendaItem } from './components/CardAgendaItem';
import { RedDot } from './components/RedDot';
import { WIDTH_ONE_IN_FIVE, WIDTH_ONE_IN_SEVEN, WIDTH_ONE_IN_SIXTH, WIDTH_QUARTER } from '../../common/CardConsts';
import { DayAgendaNumInfo } from '../common/DayAgendaNumInfo';
import { isChineseCalendar } from '@app/common';
import { parseObjToAgendaArray } from '../../utils/CardUtils'

const TAG: string = 'AgendaCardView2x4';

@Component
export struct AgendaCardView2x4 {
  // 当前 julianDay
  @State julianDayOfNow: number = 0;

  // 按天分组后的所有日程组
  @State agendaGroupList: Array<AgendaCardGroup> = [];

  // 今日有未过期的日程
  @State todayHasNotExpireAgenda: boolean = false;

  // 第一次创建卡片，数据处理是否完成
  @LocalStorageProp('isDataProcessedFirstTime') isDataProcessedFirstTime: boolean = false;

  // 没有日程时显示的文本
  @State agendaInfoText: Resource = $r('app.string.no_agenda_today');

  // 是否进入日历隐私授权
  @LocalStorageProp('isAgreeStatement') @Watch('isAgreeStatementChange') isAgreeStatement: boolean = true;

  // 卡片数据代理返回的 JSON 数组
  @LocalStorageProp('agendaObjList') @Watch('onAgendaObjListChange') agendaObjList: Array<AgendaCardInfo> = [];

  @LocalStorageProp('todayAgendaObjList') @Watch('onTodayAgendaObjListChange') todayAgendaObjList: Array<AgendaCardInfo> = [];

  // 卡片数据代理返回的 JSON 数组 - 按天分组
  @LocalStorageProp('dayAgendaNumInfo') @Watch('onDayAgendaNumInfoChange') dayAgendaNumInfo: DayAgendaNumInfo[] = [];

  @LocalStorageProp('agendaRefresh') @Watch('onAgendaRefresh') agendaRefresh: string = '';

  @LocalStorageProp('deviceLayout') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @LocalStorageProp('formId') formId: string = '';

  // 一周开始日
  @LocalStorageProp('startOfWeek') startOfWeek: number = -1;

  // 周末
  @LocalStorageProp('weekends') weekends: number[] = [];

  @LocalStorageProp('curMonthVM') @Watch('onCurMonthVMChange') curMonthVM: string = '';

  @State monthlyData: CardSingleDayViewModel[] = [];

  @LocalStorageProp('isDoubleUpSingleAgreeStatement') isDoubleUpSingleAgreeStatement: boolean = false;

  @State oldAgendaObjList: Array<AgendaCardInfo> = [];

  @State dateTimeOld: CalendarDate = new CalendarDate();

  // 是否是回收后恢复卡片场景
  @State isRecoverFromRecycle: boolean = false;

  // 单月行数
  @State rowNum: number = 6;

  @LocalStorageProp('language') @Watch('onLanguageChange') language: string = i18n.System.getSystemLocale();

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();

  // 按天拆分后的日程数组
  private agendaListSplitByDay: Array<AgendaCardInfo> = [];

  // 日程组标题 map, <儒略日日期， 日程在日程组list的位置>
  private agendaGroupMap: Map<number, number> = new Map<number, number>();

  // 全部日程列表
  private agendaList: AgendaCardInfo[] = [];

  /** 存储加桌或刷新时的儒略日,便于校验卡片回收恢复场景下是否需要刷新重试 */
  @LocalStorageProp('currentJulianDay') curJulianDay: number = 0;

  @Provide agendaNumsMap: Map<number, number> = new Map<number, number>();

  /** 监听日历应用历法改变 用于判断农历日期的显隐性 */
  @LocalStorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = 0;

  /** 卡片上的农历日期显示 */
  @State lunarDateStr: string = '';

  @State is24HourClock: boolean = I18nUtil.is24HourClock();

  onFormRecover(statusData: string): void {
    Log.info(TAG, `formId: ${this.formId} onFormRecover`);
    this.isRecoverFromRecycle = true;
  }

  onCurMonthVMChange() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    if (EmptyUtils.isNotOrEmptyString(this.curMonthVM)) {
      Log.error(TAG, `curMonthVM is null!`);
      return;
    }
    const monthData: CompressedDayData[] = JSON.parse(this.curMonthVM);
    this.monthlyData = monthData.map(dayData => decompressData(dayData));
    this.rowNum = this.monthlyData.length / 7;
    Log.info(TAG, `formId: ${this.formId} display year = ${this.monthlyData[10]?.year}, month = ${this.monthlyData[10]?.month}`);
  }

  isAgreeStatementChange() {
    Log.info(TAG, `isAgreeStatement = ${this.isAgreeStatement}`);
  }

  aboutToAppear() {
    Log.info(TAG, `formId: ${this.formId} aboutToAppear start`);
    this.initAgendas();
    if (this.curMonthVM !== '') {
      this.onCurMonthVMChange();
    }
    this.onSubscriptionCalendarChange();
    crossDayExceptionCheckAndRetry(this, this.curJulianDay);
    Log.info(TAG, `formId: ${this.formId} aboutToAppear end`)
  }

  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`);
  }

  /**
   * 初始化帐户列表
   */
  initAgendas() {
    Log.info(TAG, `formId: ${this.formId}, timeZone= ${this.timeZone} initAgendas start.`);
    this.agendaList = parseObjToAgendaArray(this.agendaObjList, this.formId);
    this.initAgendaParam();
    this.agendaListSplitByDay = FormUtils.groupAgendaByDay(this.agendaList, this.julianDayOfNow, false);
    this.getAgendaGroupList();
    this.is24HourClock = I18nUtil.is24HourClock();
  }

  /**
   * 日程改变回调
   */
  onAgendaObjListChange() {
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange agendaObjList.length: ${this.agendaObjList?.length}`);
    // 刷新月视图数据
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_MONTH_VIEW,
      }
    });

    this.initAgendas();

    // 新旧数据相同不做处理，避免抖动
    const filterAgendaObjList = FormUtils.agendaGroupList2agendaObjList(this.agendaGroupList);
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange oldAgendaObjList ${this.oldAgendaObjList.length}`);
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange newAgendaObjList ${filterAgendaObjList.length}`);
    if (FormUtils.compareDataArray(this.oldAgendaObjList, filterAgendaObjList, this.dateTimeOld, new CalendarDate())) {
      Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange no need changed`);
      return;
    } else {
      this.oldAgendaObjList = filterAgendaObjList;
      this.dateTimeOld = new CalendarDate()
    }

    if (this.isDataProcessedFirstTime) {
      this.isRecoverFromRecycle = false;
    } else {
      this.isDataProcessedFirstTime = true;
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.FINISH_FIRST_DATA_PROCESSING,
        }
      });
    }
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange end.`);
  }

  onTodayAgendaObjListChange() {
    Log.info(TAG, `todayAgendaObjList length is ${this.todayAgendaObjList.length}`);
    if (!this.todayHasNotExpireAgenda) {
      // 存在没过期的日程，则已全部完成
      if (this.todayAgendaObjList.length > 0) {
        this.agendaInfoText = $r('app.string.today_agenda_is_all_done');
      }
    }
  }

  onDayAgendaNumInfoChange() {
    this.agendaNumsMap = CardUiUtils.dayAgendaNumInfo2agendaNumsMap(this.dayAgendaNumInfo);
    Log.info(TAG, `formId: ${this.formId}, agendaNumsMap.size: ${this.agendaNumsMap.size}`);
  }

  onAgendaRefresh() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    // 跨天刷新后,没有入口调用农历日期更新,此处会对julianDayOfNow进行重新赋值，因此在这里做业务处理
    this.onSubscriptionCalendarChange();
    Log.info(TAG, `formId: ${this.formId} onAgendaRefresh julianDayOfNow = ${FormUtils.julianDay2Date(this.julianDayOfNow)}`);
  }

  private onLanguageChange() {
    Log.info(TAG, 'onLanguageChange' + this.language);
  }

  private onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange: ${this.timeZone}`);
    CalendarDate.timeZone = this.timeZone;
    this.onAgendaObjListChange();
  }

  /**
   * 初始化日程参数
   */
  initAgendaParam() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    this.onSubscriptionCalendarChange();

    Log.info(TAG, `formId: ${this.formId} julianDayOfNow is changed to ${FormUtils.julianDay2Date(this.julianDayOfNow)}`);
    this.agendaListSplitByDay = [];
    this.agendaGroupList = [];
    this.agendaGroupMap = new Map<number, number>();
  }

  /**
   * 获取日程组对象数组
   */
  getAgendaGroupList() {
    this.agendaListSplitByDay.forEach((agenda: AgendaCardInfo) => {
      const julianDay: number = agenda.mDay;
      if (this.agendaGroupMap.has(julianDay)) {
        const index: number = this.agendaGroupMap.get(julianDay) as number;
        this.agendaGroupList[index].items.push(agenda);
      } else {
        let tempGroup: AgendaCardGroup = new AgendaCardGroup(julianDay, []);
        tempGroup.items.push(agenda);
        const arrayLength: number = this.agendaGroupList.push(tempGroup);
        this.agendaGroupMap.set(julianDay, arrayLength - 1);
      }
    })

    // 过滤当天日程
    this.agendaGroupList = this.agendaGroupList.filter((item) => {
      return item.julianDay === this.julianDayOfNow;
    })

    this.todayHasNotExpireAgenda = this.agendaGroupList.length !== 0;
    this.filterAgendaGroupList();
  }

  @Builder
  NoExpireAgendaView() {
    Column() {
      TitleMessage({
        realTime: FormUtils.julianDay2Date(this.julianDayOfNow),
        isRTL: i18n.isRTL(this.language),
        count: CardUiUtils.getAgendaCountFromGroupList(this.agendaGroupList),
      })
      this.OneDayAgendaList();
    }
    .padding({ top: 12, left: 12, right: 12 })
    .backgroundColor($r('app.color.color_card_bg'))
    .transition(this.isRecoverFromRecycle
      ? TransitionEffect.IDENTITY
      : TransitionEffect.OPACITY.combine(TransitionEffect.rotate({} as RotateOptions)).animation({ duration: 300 }))
    .overlay(this.gradientBuilder(), {
      align: Alignment.Bottom,
    })
  }

  @Builder
  OneDayAgendaList() {
    List() {
      ForEach(this.agendaGroupList[0].items, (cardAgenda: AgendaCardInfo, index: number | undefined) => {
        ListItem() {
          CardAgendaItem({
            agenda: cardAgenda,
            deviceLayout: this.deviceLayout,
            formId: this.formId,
            isFinal: index === this.agendaGroupList[0].items.length - 1,
            isRTL: i18n.isRTL(this.language),
            dimension: DIMENSION_2_4,
            timeZone: this.timeZone,
            is24HourClock: this.is24HourClock
          })
        }
      })
    }
    .padding({ top: 4, bottom: 12 })
    .scrollBar(BarState.Off)
    .borderRadius({ topLeft: 12, topRight: 12 })
    .width('100%')
    .align(Alignment.Top)
    .layoutWeight(1)
  }

  @Builder
  gradientBuilder() {
    Row() {
    }
    .height(24)
    .width('100%')
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.id_color_card_gray_gradient_start'), 0],
        [$r('app.color.id_color_card_gray_gradient'), 0.5],
      ]
    })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  build() {
    Column() {
      if (!this.isAgreeStatement && !this.isDoubleUpSingleAgreeStatement) {
        // 未授权，未进入过日历的默认样式
        NoAgendaCardView({
          today: this.julianDayOfNow,
          deviceLayout: this.deviceLayout,
          julianDayOfNow: this.julianDayOfNow,
          days: this.monthlyData,
          rowNum: this.rowNum,
          startOfWeek: this.startOfWeek,
          weekends: this.weekends,
          agendaInfoText: $r('app.string.not_yet_authorized'),
          isRTL: i18n.isRTL(this.language)
        })
      } else if (!this.isDataProcessedFirstTime) {
        // 初次尚未加载到数据
        InitCardView2x4_4x4({ cardType: 'agendaCard' });
      } else if (!this.todayHasNotExpireAgenda) {
        // 没有未过期日程
        NoAgendaCardView({
          today: this.julianDayOfNow,
          deviceLayout: this.deviceLayout,
          julianDayOfNow: this.julianDayOfNow,
          days: this.monthlyData,
          rowNum: this.rowNum,
          startOfWeek: this.startOfWeek,
          weekends: this.weekends,
          agendaInfoText: this.agendaInfoText,
          isRTL: i18n.isRTL(this.language),
          lunarDateStr: this.lunarDateStr
        });
      } else {
        // 正常情况
        this.NoExpireAgendaView();
      }
    }
    .accessibilityText(this.getAccessibilityText())
    .accessibilityLevel('yes')
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} build is click, jumpToMonthView date: ${this.julianDayOfNow}`);
      const date = DateUtil.julianDay2Date(this.julianDayOfNow);
      jumpToMonthView(this, date.getFullYear(), date.getMonth(), date.getDate(), this.formId);
    })
    .width('100%')
    .height('100%')
  }

  getAccessibilityText(): string {
    // todo 待提翻
    if (!this.isAgreeStatement) {
      return '请打开日历进行授权';
    }

    if (this.agendaGroupList.length === 0) {
      return '今日无日程';
    }

    let timeOption: DateTimeOptions = {
      day: 'numeric',
      weekday: 'long',
      hour: 'numeric',
      minute: '2-digit',
      hour12: !I18nUtil.is24HourClock()
    };

    const now = new CalendarDate();
    const date = DateUtil.intlDateFormatChineseStyle(now, timeOption);
    let size = 0;
    this.agendaGroupList.forEach(item => {
      size += item.items.length;
    })
    return `${date},有${size}条临近日程`;
  }

  /**
   * 过滤要展示的日程组
   */
  private filterAgendaGroupList() {
    const now = new Date().getTime(); // 当前时间

    // 今天没有日程时显示”今日无日程“
    if (this.agendaGroupList.length === 0) {
      this.todayHasNotExpireAgenda = false;
      this.agendaInfoText = $r('app.string.no_agenda_today');
      return;
    } else {
      // 今天有日程则判断当天日程最大的结束时间是否大于当前时间
      const maxEnd = Math.max(...(this.agendaGroupList[0].items.map(item => item.mEnd)));
      if (maxEnd <= now) {
        this.agendaInfoText = $r('app.string.today_agenda_is_all_done');
        this.todayHasNotExpireAgenda = false;
        this.agendaGroupList = [];
      } else {
        this.todayHasNotExpireAgenda = true;
        this.agendaGroupList[0].items = this.agendaGroupList[0].items.filter((info: AgendaCardInfo) => info.mEnd > now);
      }
      Log.info(TAG, `filterAgendaGroupList agendaGroupList.length = ${this.agendaGroupList.length}`);
    }
  }

  onSubscriptionCalendarChange() {
    Log.info(TAG, `onSubscriptionCalendarChange subscriptionCalendar= ${this.subscriptionCalendar}`);
    if (isChineseCalendar(this.subscriptionCalendar)) {
      this.lunarDateStr = CardUiUtils.getLunarText(this.julianDayOfNow);
    } else {
      this.lunarDateStr = '';
    }
  }
}

/**
 *  无日程时卡片视图
 */
@Component
struct NoAgendaCardView {
  @Prop today: number = FormUtils.getCurrentJulianDay();

  @Prop julianDayOfNow: number = 0;

  @Prop days: CardSingleDayViewModel[] = [];

  @Prop rowNum: number = 6;

  @Prop startOfWeek: number = -1;

  @Prop weekends: number[] = [];

  @Prop deviceLayout: DeviceLayout;

  @Prop agendaInfoText: Resource;

  @Prop isRTL: boolean;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  @Prop lunarDateStr: string;

  private weekTitles: Resource[] = [
    $r('app.string.Card_Sun'),
    $r('app.string.Card_Mon'),
    $r('app.string.Card_Tue'),
    $r('app.string.Card_Wed'),
    $r('app.string.Card_Thu'),
    $r('app.string.Card_Fri'),
    $r('app.string.Card_Sat')
  ]

  aboutToAppear() {
    let time: CalendarDate = FormUtils.julianDay2Date(this.today);
    Log.info(TAG, `show date = ${time}`);
  }

  build() {
    RelativeContainer() {
      this.buildLeft();

      this.buildRight();
    }
    .width('100%')
    .padding(12)
    .backgroundColor($r('app.color.color_card_bg_ext'))
  }

  @Builder
  buildRight() {
    Flex({
      direction: FlexDirection.Row,
      wrap: FlexWrap.NoWrap,
      justifyContent: FlexAlign.SpaceAround,
    }) {
      ForEach(this.weekTitles, (item: Resource, index: number) => {
        Text(this.weekTitles[(this.startOfWeek + index) % 7])
          .fontSize(this.deviceLayout.noAgendaCardWeekTitleFontSize)
          .maxFontScale(1)
          .fontColor($r('sys.color.font_primary'))
          .opacity(this.weekends?.includes((this.startOfWeek + index) % 7) ? $r('sys.float.alpha_tertiary') : $r('sys.float.alpha_primary'))
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Medium)
          .height(12)
      })
    }
    .margin({ left: this.isRTL ? undefined : 8, right: this.isRTL ? 8 : undefined })
    .alignRules({
      top: { anchor: '__container__', align: VerticalAlign.Top },
      right: { anchor: '__container__', align: HorizontalAlign.End },
      left: { anchor: 'week', align: HorizontalAlign.End }
    })
    .id('weekTitle')
    .width('56%')

    RelativeContainer() {
      ForEach(new Array(this.rowNum).fill(''), (item: string, index: number) => {
        this.forEachWeekDays(index)
      })
    }
    .width('56%')
    .margin({ left: this.isRTL ? undefined : 8, right: this.isRTL ? 8 : undefined })
    .offset({ top: this.deviceLayout.noAgendaCardMonthViewTopOffset })
    .alignRules({
      top: { anchor: 'weekTitle', align: VerticalAlign.Bottom },
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
      right: { anchor: '__container__', align: HorizontalAlign.End },
      left: { anchor: 'week', align: HorizontalAlign.End }
    })
    .id('monthViewBase')
  }

  @Builder
  forEachWeekDays(index: number) {
    ForEach(new Array(7).fill(''), (item: string, num: number) => {
      if (this.days[index * 7 + num]) {
        this.buildSigDay(index * 7 + num);
      }
    })
  }

  @Builder
  buildLeft() {
    Text(FormUtils.getWeekMessage(FormUtils.julianDay2Date(this.today)))
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_primary'))
      .fontSize($r('sys.float.ohos_id_text_size_body3'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.Start)
      .width('40%')
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }

      })
      .id('week')

    Text(`${FormUtils.julianDay2Date(this.today).getDate()}`)
      .fontColor($r('app.color.red_common'))
      .fontSize(40)
      .maxFontScale(1)
      .lineHeight(40)
      .fontWeight(FontWeight.Bold)
      .textAlign(TextAlign.Start)
      .margin({ left: this.isRTL ? undefined : -2, right: this.isRTL ? -2 : undefined, top: 4 })
      .alignRules({
        top: { anchor: 'week', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('date')

    Text(this.lunarDateStr)
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize($r('sys.float.Body_S'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.Start)
      .margin({ bottom: 4 })
      .alignRules({
        bottom: { anchor: 'info', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('day')

    Text(this.agendaInfoText)
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize($r('sys.float.Body_S'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.Start)
      .maxLines(2)
      .width('40%')
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('info')
  }

  @Builder
  buildCircle() {
    Column()
      .width('90%')
      .aspectRatio(1)
      .backgroundColor($r('app.color.red_common'))
      .alignSelf(ItemAlign.Center)
      .borderRadius('50%')
  }

  @Builder
  buildSigDay(index: number) {
    if (this.days[index].isToday) {
      Stack() {
        this.buildCircle()
        Text(this.days[index].day.toString())
          .fontSize(this.deviceLayout.noCardAgendaFontSize - (this.isSmallUp ? 2 : 0))
          .maxFontScale(1)
          .visibility(this.days[index].isCurrentMonth ? Visibility.Visible : Visibility.Hidden)
          .fontColor(this.days[index].isToday ? '#FFFFFF' : $r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
      }
      .width(WIDTH_ONE_IN_SEVEN)
      .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
      .alignRules({
        top: {
          anchor: index / 7 === 0 ? 'monthViewBase' : `monthView${index - 7}`,
          align: index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
        },
        left: {
          anchor: index % 7 === 0 ? 'monthViewBase' : `monthView${index - 1}`,
          align: index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
        }
      })
      .id(`monthView${index}`)
    } else {
      Text(this.days[index].day.toString())
        .fontSize(this.deviceLayout.noCardAgendaFontSize - (this.isSmallUp ? 2 : 0))
        .maxFontScale(1)
        .visibility(this.days[index].isCurrentMonth ? Visibility.Visible : Visibility.Hidden)
        .fontColor(this.days[index].isToday ? '#FFFFFF' : $r('sys.color.font_primary'))
        .opacity(this.days[index].isWeekends && !this.days[index].isToday ? 0.4 : 0.9)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(WIDTH_ONE_IN_SEVEN)
        .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
        .alignRules({
          top: {
            anchor: index / 7 === 0 ? 'monthViewBase' : `monthView${index - 7}`,
            align: index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
          },
          left: {
            anchor: index % 7 === 0 ? 'monthViewBase' : `monthView${index - 1}`,
            align: index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
          }
        })
        .id(`monthView${index}`)
    }
  }
}

/**
 * 单个日程组：标题组件
 */
@Component
struct TitleMessage {
  // 日程组内容
  @Prop realTime: CalendarDate;

  @Prop isRTL: boolean;

  @Prop count: number;

  @Consume agendaNumsMap: Map<number, number>;

  build() {
    Row() {
      Text(`${this.realTime.toLocaleString(i18n.System.getSystemLanguage(), { month: 'long', day: 'numeric' })}`)
        .fontColor($r('app.color.red_common'))
        .fontSize($r('sys.float.Subtitle_L'))
        .maxFontScale(1)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .opacity($r('sys.float.alpha_primary'))

      Text(FormUtils.getWeekMessage(this.realTime))
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_primary'))
        .fontSize($r('sys.float.Body_L'))
        .maxFontScale(1)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .margin({ left: this.isRTL ? undefined : 4, right: this.isRTL ? 4 : undefined })

      RedDot({ count: this.agendaNumsMap.get(this.realTime.getJulianDay()) ?? 0 })
    }
    .width('100%')
  }
}

/**
 * 跳转到月视图
 */
function jumpToMonthView(obj: FormUtils, year: number, month: number, day: number, formId: string) {
  Log.info(TAG, `formId: ${formId} Jump to month view, year: ${year}, month: ${month + 1}, day: ${day}`);
  postCardAction(obj, {
    'action': 'router',
    'bundleName': 'com.ohos.calendar',
    'abilityName': 'MainAbility',
    'params': {
      'action': 'CLICK_MONTH_FORM_HEADER',
      'tabIndex': '1',
      'year': year,
      'month': month,
      'day': day,
      'faType': 'AgendaCard2x4'
    }
  });
}