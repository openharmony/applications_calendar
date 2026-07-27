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
import {
  AgendaCardGroup,
  AgendaCardInfo,
  FormUtils
} from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { DIMENSION_4_4 } from '../../utils/CardJumpUtils';
import { CardSingleDayViewModel, CompressedDayData } from '../../monthCard/viewModel/components/CardSingleDayViewModel';
import i18n from '@ohos.i18n';
import { InitCardView2x4_4x4 } from '../../view/InitCardView';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { decompressData, crossDayExceptionCheckAndRetry } from '../../utils/CardUtils';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { CardAction } from '../../common/CardAction';
import { CardAgendaItem } from './components/CardAgendaItem';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { NoAgendaCardView } from './components/NoAgendaCardView';
import { RedDot } from './components/RedDot';
import { CardUiUtils } from '../../utils/CardUiUtils';
import { DayAgendaNumInfo } from '../common/DayAgendaNumInfo';
import { isChineseCalendar } from '@app/common';
import { parseObjToAgendaArray } from '../../utils/CardUtils'

const TAG: string = 'AgendaCardView4x4';

const maxLimitDays: number = 6; // 限制卡片最多只展示最近七天日程

@Component
export struct AgendaCardView4x4 {
  // 当前 julianDay
  @State julianDayOfNow: number = 0;

  // 按天分组后的所有日程组
  @State agendaGroupList: Array<AgendaCardGroup> = [];

  // 今日有未过期的日程
  @State todayHasNotExpireAgenda: boolean = false;

  // 7 天有未过期的日程
  @State weekHasNotExpireAgenda: boolean = false;

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

  private julianDayOfEnd: number = this.julianDayOfNow + 6;

  // 按天拆分后的日程数组
  private agendaListSplitByDay: Array<AgendaCardInfo> = [];

  // 日程组标题 map, <儒略日日期， 日程在agendaGroupList的位置>
  private agendaGroupMap: Map<number, number> = new Map<number, number>();

  // 全部日程列表
  private agendaList: AgendaCardInfo[] = [];

  /** 存储加桌或刷新时的儒略日,便于校验卡片回收恢复场景下是否需要刷新重试 */
  @LocalStorageProp('currentJulianDay') curJulianDay: number = 0;

  @Provide agendaNumsMap: Map<number, number> = new Map<number, number>();

  /** 监听日历应用历法改变 用于判断农历日期的显隐性 */
  @LocalStorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = 0;

  @State is24HourClock: boolean = I18nUtil.is24HourClock();

  /** 卡片上的农历日期显示 */
  @State lunarDateStr: string = '';

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
    try {
      const monthData: CompressedDayData[] = JSON.parse(this.curMonthVM);
      this.monthlyData = monthData.map(dayData => decompressData(dayData));
      this.rowNum = this.monthlyData.length / 7;
      Log.info(TAG, `formId: ${this.formId} display year = ${this.monthlyData[10]?.year}, month = ${this.monthlyData[10]?.month}`);
    } catch (error) {
      Log.logErrorMsg(TAG, 'curMonthVM parse error', error);
    }
  }

  isAgreeStatementChange() {
    Log.info(TAG, `isAgreeStatement = ${this.isAgreeStatement}`);
  }

  aboutToAppear() {
    Log.info(TAG, `formId: ${this.formId} aboutToAppear start`);
    this.initAgendas();
    this.judgeShowMessage();
    if (this.curMonthVM !== '') {
      this.onCurMonthVMChange();
    }
    this.onSubscriptionCalendarChange();
    crossDayExceptionCheckAndRetry(this, this.curJulianDay);
    Log.info(TAG, `formId: ${this.formId} aboutToAppear end.`);
  }

  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`);
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

  @Builder
  NoExpireAgendaView() {
    Column() {
      // 日程行
      this.agendaDetail();
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

  @Builder
  agendaDetail() {
      List() {
        this.buildAgendaGroupList();
      }
      .sticky(StickyStyle.Header)
      .scrollBar(BarState.Off)
      .onSizeChange((ov, nv) => {
        Log.info(TAG, `newHeightOfList is ${nv.height}`)
      })
      .align(Alignment.Top)
      .padding({ bottom: 1 })
      .layoutWeight(1)
  }

  @Builder
  buildAgendaGroupList() {
    ForEach(this.agendaGroupList, (agendaGroup: AgendaCardGroup, index: number | undefined) => {
      BuildOneDayGroup({
        group: agendaGroup,
        deviceLayout: this.deviceLayout,
        formId: this.formId,
        julianDayOfNow: this.julianDayOfNow,
        isIntent: false,
        agendaInfoText: this.agendaInfoText,
        todayHasNotExpireAgenda: this.todayHasNotExpireAgenda,
        isRTL: i18n.isRTL(this.language),
        timeZone: this.timeZone,
        is24HourClock: this.is24HourClock
      })
    }, (index: number) => `${Date.now()}-${index}`)
  }

  build() {
    Column() {
      if (!this.isAgreeStatement && !this.isDoubleUpSingleAgreeStatement) {
        // 未授权，未进入过日历的默认样式
        NoAgendaCardView({
          today: this.julianDayOfNow,
          days: this.monthlyData,
          rowNum: this.rowNum,
          startOfWeek: this.startOfWeek,
          weekends: this.weekends,
          deviceLayout: this.deviceLayout,
          isShowText: $r('app.string.not_yet_authorized'),
          isRTL: i18n.isRTL(this.language)
        })
      } else if (!this.isDataProcessedFirstTime) {
        // 初次尚未加载到数据
        InitCardView2x4_4x4({ cardType: 'agendaCard' });
      } else if (!this.weekHasNotExpireAgenda) {
        // 未来七天没日程
        NoAgendaCardView({
          today: this.julianDayOfNow,
          days: this.monthlyData,
          rowNum: this.rowNum,
          startOfWeek: this.startOfWeek,
          weekends: this.weekends,
          deviceLayout: this.deviceLayout,
          isShowText: $r('app.string.no_agenda_week'),
          isRTL: i18n.isRTL(this.language),
          lunarDateStr: this.lunarDateStr
        })
      } else {
        // 正常情况
        this.NoExpireAgendaView()
      }
    }
    .accessibilityText(this.getAccessibilityText())
    .accessibilityLevel('yes')
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} build is click, jumpToMonthView date: ${this.julianDayOfNow}`);
      const date = FormUtils.julianDay2Date(this.julianDayOfNow);
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
   * 初始化帐户列表
   */
  private initAgendas() {
    Log.info(TAG, `formId: ${this.formId}, timeZone= ${this.timeZone} initAgendas start.`);
    this.agendaList = parseObjToAgendaArray(this.agendaObjList, this.formId);
    this.initAgendaParam();
    this.agendaListSplitByDay = FormUtils.groupAgendaByDay(this.agendaList, this.julianDayOfNow, false);
    this.getAgendaGroupList();
    this.is24HourClock = I18nUtil.is24HourClock();
    this.judgeShowMessage();
    Log.info(TAG, `formId: ${this.formId} initAgendas end.`);
  }

  /**
   * 不显示星期
   */
  private hideWeek(day: number) {
    const index: number | undefined = this.agendaGroupMap.get(day);
    Log.info(TAG, `hideWeek: julianDay is ${day}, index is ${index}.`);
    if (index !== undefined && this.agendaGroupList[index]) {
      // index超出范围报错
      // TypeError: Obj is not a Valid object.
      this.agendaGroupList[index].isShowWeek = false;
    }
  }

  /**
   * 获取卡片内容显隐性
   */
  private judgeShowMessage() {
    try {
      Log.info(TAG, `formId: ${this.formId} judgeShowMessage: agendaGroupList.length= ${this.agendaGroupList?.length}, ` +
        `julianDayOfNow= ${this.julianDayOfNow}, agendaGroupMap.keys= [${Array.from(this.agendaGroupMap?.keys() ?? []).join()}]`);

      // 前天到今天日程标题：不显示星期
      for (let day = this.julianDayOfNow - 2; day <= this.julianDayOfNow; day++) {
        this.hideWeek(day);
      }

      // 明天到后天日程标题：不显示星期
      for (let day = this.julianDayOfNow + 1; day <= this.julianDayOfNow + 2; day++) {
        this.hideWeek(day);
      }
    } catch (err) {
      Log.info(TAG, `judgeShowMessage error is ${err}.`);
    }

    Log.info(TAG, `formId: ${this.formId} judgeShowMessage end.`);
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

  /**
   * 初始化日程参数
   */
  private initAgendaParam() {
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
  private getAgendaGroupList() {
    Log.info(TAG, `formId: ${this.formId} getAgendaGroupList agendaListSplitByDay.length: ${this.agendaListSplitByDay?.length}`);
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

    Log.info(TAG, `getAgendaGroupList:
        this agendaGroupMap keys is ${Array.from(this.agendaGroupMap?.keys() ?? []).join()}.`);

    // 过滤最近七天内的日程组
    this.agendaGroupList = this.agendaGroupList.filter((item) => {
      return item.julianDay <= this.julianDayOfNow + maxLimitDays;
    })
    this.filterCurAgendaGroupList();

    this.weekHasNotExpireAgenda = false;
    for (const group of this.agendaGroupList) {
      if (group.items.length > 0) {
        this.weekHasNotExpireAgenda = true;
      }
    }
    Log.info(TAG, `weekHasNotExpireAgenda ${this.weekHasNotExpireAgenda}`)
    Log.info(TAG, `formId: ${this.formId} getAgendaGroupList agendaGroupList.length: ${this.agendaGroupList.length}`);
  }

  /**
   * 过滤当天的日程组
   */
  private filterCurAgendaGroupList() {
    const now = new Date().getTime(); // 当前时间

    if (this.agendaGroupMap.has(this.julianDayOfNow)) {
      const index: number = this.agendaGroupMap.get(this.julianDayOfNow) as number;
      // 今天有日程则判断当天日程最大的结束时间是否大于当前时间
      const maxEnd = Math.max(...(this.agendaGroupList[index].items.map(item => item.mEnd)));
      if (maxEnd <= now) {
        this.agendaInfoText = $r('app.string.today_agenda_is_all_done');
        this.todayHasNotExpireAgenda = false;
      } else {
        this.todayHasNotExpireAgenda = true;
        this.agendaGroupList[index].items =
          this.agendaGroupList[index].items.filter((info: AgendaCardInfo) => info.mEnd > now);
      }
    } else {
      // 今天没有日程时显示”今日无日程“
      this.todayHasNotExpireAgenda = false;
      this.agendaInfoText = $r('app.string.no_agenda_today');
      // 无日程需要有空数组占位
      this.agendaGroupList.unshift(new AgendaCardGroup(FormUtils.getCurrentJulianDay(), []))
      // 重新排列map和list的对应位置
      this.agendaGroupMap = new Map<number, number>();
      this.agendaGroupList.forEach((item: AgendaCardGroup, index: number) => {
        this.agendaGroupMap.set(item.julianDay, index);
      })

      Log.info(TAG, `filterCurAgendaGroupList:
        this agendaGroupMap keys is ${Array.from(this.agendaGroupMap?.keys() ?? []).join()}.`);
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
 * 单个日程组：标题头时间组件
 */
@Component
struct TitleDateMessage {
  // 日程组内容
  @Prop realTime: CalendarDate;

  @Prop isRTL: boolean;

  @Prop formId: string;

  @Prop count: number;

  @Consume agendaNumsMap: Map<number, number>;

  build() {
    Row() {
      Text(`${this.realTime.toLocaleString(i18n.System.getSystemLanguage(), {month: 'long', day: 'numeric'})}`)
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
    .backgroundColor($r('app.color.color_card_bg'))
    .padding({ bottom: 4 })
    .backgroundColor($r('app.color.color_card_bg'))
    .pixelRound({ top: PixelRoundCalcPolicy.FORCE_FLOOR, bottom: PixelRoundCalcPolicy.FORCE_CEIL })
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} TitleDateMessage is click, jumpToMonthView date: ${this.realTime}`);
      jumpToMonthView(this, this.realTime.getFullYear(),
        this.realTime.getMonth(), this.realTime.getDate(), this.formId);
    })
  }
}

/**
 * 单个日程组：标题组件
 */
@Component
struct TitleMessage {
  // 日程组内容
  @Prop group: AgendaCardGroup = new AgendaCardGroup(0, []);

  // 今天日期
  @Prop julianDayOfNow: number = 0;

  @Link formId: string;

  @Prop isIntent: boolean;

  @Prop isRTL: boolean;

  @Prop count: number;

  @Consume agendaNumsMap: Map<number, number>;

  aboutToAppear(): void {
  }

  build() {
    Row() {
      // 显示 x月x日  / 明天  / 后天
      Text(FormUtils.getDayMessage(this.group?.julianDay, this.group?.date))
        .fontSize(16)
        .maxFontScale(1)
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_primary'))
        .lineHeight(21)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)

      if (this.group?.isShowWeek) {
        // 星期x
        Text(FormUtils.getWeekMessage(this.group?.date))
          .fontSize(16)
          .maxFontScale(1)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .opacity($r('sys.float.alpha_primary'))
          .lineHeight(21)
          .margin({ left: this.isRTL ? undefined : 4, right: this.isRTL ? 4 : undefined })
      }

      RedDot({ count: this.agendaNumsMap.get(this.group?.julianDay) ?? 0 })
    }
    .width('100%')
    .padding({ bottom: 4 })
    .backgroundColor($r('app.color.color_card_bg'))
    .pixelRound({ top: PixelRoundCalcPolicy.FORCE_FLOOR, bottom: PixelRoundCalcPolicy.FORCE_CEIL })
    .stateStyles({
      pressed: {
        .backgroundColor('#1a000000')
      },
      normal: {
        .backgroundColor($r('app.color.color_card_bg'))
      }
    })
    .onClick(() => {
      jumpToMonthView(this,
        this.group.date.getFullYear(),
        this.group.date.getMonth(),
        this.group.date.getDate(),
        this.formId);
    })
  }
}

/**
 * 单个日程组：日程列表内容
 */
@Component
struct BuildOneDayGroup {
  // 日程组内容
  @Prop group: AgendaCardGroup = new AgendaCardGroup(0, []);

  @Prop deviceLayout: DeviceLayout;

  @Prop formId: string;

  @Prop isIntent: boolean = false;

  @Prop julianDayOfNow: number = 0;

  @Prop agendaInfoText: ResourceStr = '';

  @Prop todayHasNotExpireAgenda: boolean = false;

  @Prop isRTL: boolean;

  @Prop timeZone: string;

  @Prop is24HourClock: boolean;

  aboutToAppear(): void {
    Log.warn(TAG, `BuildOneDayGroup, julianDay: ${this.group.julianDay}, items: ${this.group.items.length}`);
  }

  @Builder
  itemGroupHeader() {
    if (this.group.julianDay === FormUtils.getCurrentJulianDay() && !this.isIntent) {
      // 今天的日期行
      TitleDateMessage({
        realTime: FormUtils.julianDay2Date(this.julianDayOfNow),
        formId: this.formId,
        isRTL: this.isRTL,
        count: CardUiUtils.getAgendaCount(this.group),
      })
    } else if (this.group.julianDay !== FormUtils.getCurrentJulianDay() || this.isIntent) {
      TitleMessage({
        group: this.group,
        julianDayOfNow: this.julianDayOfNow,
        formId: this.formId,
        isIntent: this.isIntent,
        isRTL: this.isRTL,
        count: CardUiUtils.getAgendaCount(this.group),
      })
    }
  }

  @Builder
  todayNoAgenda() {
    Row() {
      Text(this.agendaInfoText)
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_primary'))
        .fontSize(14)
        .maxFontScale(1)
        .fontWeight(FontWeight.Regular)
        .lineHeight(19)
    }
    .justifyContent(FlexAlign.Center)
    .height(48)
    .width('100%')
    .padding({ top: 16 })
  }

  build() {
    ListItemGroup({ header: this.itemGroupHeader() }) {
      if (this.group.julianDay === FormUtils.getCurrentJulianDay() && !this.todayHasNotExpireAgenda && !this.isIntent) {
        this.todayNoAgenda()
      } else {
        this.forEachAgendaGroup();
      }
    }
    .width('100%')
    .padding({ bottom: 12 })
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} BuildOneDayGroup is click, jumpToMonthView date: ${this.julianDayOfNow}`);
      // 默认跳到月视图
      const date = FormUtils.julianDay2Date(this.julianDayOfNow);
      jumpToMonthView(this, date.getFullYear(), date.getMonth(), date.getDate(), this.formId);
    })
  }

  @Builder
  forEachAgendaGroup() {
    ForEach(this.group.items, (cardAgenda: AgendaCardInfo, index: number | undefined) => {
      ListItem() {
        CardAgendaItem({
          agenda: cardAgenda,
          deviceLayout: this.deviceLayout,
          formId: this.formId,
          isFinal: index === this.group.items.length - 1,
          isRTL: this.isRTL,
          dimension: DIMENSION_4_4,
          timeZone: this.timeZone,
          is24HourClock: this.is24HourClock
        })
      }
    })
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
      'faType': 'AgendaCard4x4',
      'formId': formId
    }
  });
}
