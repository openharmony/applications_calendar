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
import { AgendaCardGroup, AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardSingleDayViewModel, CompressedDayData } from '../../monthCard/viewModel/components/CardSingleDayViewModel';
import { InitCardView4x6 } from '../../view/InitCardView';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { DIMENSION_6_4 } from '../../utils/CardJumpUtils';
import { decompressData, crossDayExceptionCheckAndRetry } from '../../utils/CardUtils';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { WeekDayView } from './components/weekView/WeekDayView';
import { CardAgendaItem } from './components/CardAgendaItem';
import { i18n } from '@kit.LocalizationKit';
import { HashMap } from '@kit.ArkTS';
import { CardAction } from '../../common/CardAction';
import { CardDeduplicateProcessor } from '../common/CardDeduplicateProcessor';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';


const TAG: string = 'AgendaCardView4x6';

@Component
export struct AgendaCardView4x6 {
  // 当前 julianDay
  @State julianDayOfNow: number = 0;

  @State @Watch('onActiveDayChange') activeDay: number = 0

  // 按天分组后的所有日程组
  @State agendaGroupList: Array<AgendaCardGroup> = [];

  // 跳转到第二天的按钮 显示开关
  @State showJumpTomorrowButton: boolean = false;

  // 是否显示日程列表
  @State isShowAgendaList: boolean = false;

  // 7 天有未过期的日程
  @State weekHasNotExpireAgenda: boolean = false;

  // 第一次创建卡片，数据处理是否完成
  @LocalStorageProp('isDataProcessedFirstTime') isDataProcessedFirstTime: boolean = false;

  // 今天没有日程时显示的文本
  @State agendaInfoText: Resource | string = $r('app.string.no_schedule_today_relax_text');

  // 是否进入日历隐私授权
  @LocalStorageProp('isAgreeStatement') isAgreeStatement: boolean = true;

  // 卡片数据代理返回的 JSON 数组
  @LocalStorageProp('agendaObjList') @Watch('onAgendaObjListChange') agendaObjList: Array<object> | string = [];

  // 增量日程数据
  @LocalStorageProp('agendaAddedList') @Watch('onAgendaAddedListChange') agendaAddedList: string = '';

  // 今日日程查询
  @LocalStorageProp('todayAgendaObjList') @Watch('onTodayAgendaObjListChange') todayAgendaObjList: Array<AgendaCardInfo> | string = [];

  @LocalStorageProp('agendaRefresh') @Watch('onAgendaRefresh') agendaRefresh: string = '';

  // 设备规格
  @LocalStorageProp('deviceLayout') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @LocalStorageProp('formId') formId: string = '';

  // 一周开始日
  @LocalStorageProp('startOfWeek') startOfWeek: number = -1;

  // 周末
  @LocalStorageProp('weekends') weekends: number[] = [];

  @LocalStorageProp('curMonthVM') @Watch('onCurMonthVMChange') curMonthVM: string = '';

  @LocalStorageProp('isDoubleUpSingleAgreeStatement') isDoubleUpSingleAgreeStatement: boolean = false;

  @State monthlyData: CardSingleDayViewModel[] = [];

  // 是否是回收后恢复卡片场景
  @State isRecoverFromRecycle: boolean = false;

  // 单月行数
  @State rowNum: number = 6;

  // 未过期日程的条数, 用于处理吸顶时列表高度不够的问题 该值为-1则不处理
  @State unexpiredAgendaCounts: number = -1;

  // 按天拆分后的日程数组
  private agendaListSplitByDay: Array<AgendaCardInfo> = [];

  // 日程组标题 map, <儒略日日期， 日程在agendaGroupList的位置>
  private agendaGroupMap: Map<number, number> = new Map<number, number>();

  // 全部日程列表
  private agendaList: AgendaCardInfo[] = [];

  // 日程列表控制器
  private scroller: Scroller = new Scroller();

  @LocalStorageProp('language') @Watch('onLanguageChange') language: string = i18n.System.getSystemLocale();

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();

  /** 存储加桌或刷新时的儒略日,便于校验卡片回收恢复场景下是否需要刷新重试 */
  @LocalStorageProp('currentJulianDay') curJulianDay: number = 0;

  @State is24HourClock: boolean = I18nUtil.is24HourClock();

  /**
   * 点击动作切换选中天
   */
  private onActiveDayChange() {
    this.filterCurAgendaGroupList(); // 首帧内处理当天动作，防止出现日程内容残影
  }

  /**
   * 今天日程变更回调
   */
  onTodayAgendaObjListChange() {
    try {
      // clean说明是清空暂存数据，不处理
      if ('clean' === this.todayAgendaObjList) {
        Log.info(TAG, `formId: ${this.formId} onTodayAgendaObjListChange todayAgendaObjList clean`);
        return;
      }

      // 处理日程数据
      this.doTodayAgendaObjListChange();

      // 消费完回调以清除增量数据
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.REMOVE_ADDED_4X6,
          name: 'todayAgendaObjList'
        }
      });
    } catch (e) {
      Log.logErrorMsg(TAG, 'onTodayAgendaObjListChange', e)
    }
  }

  /**
   * 今天日程变更，触发文本变更
   */
  doTodayAgendaObjListChange() {
    Log.info(TAG, `todayAgendaObjList length is ${this.todayAgendaObjList.length}`);
    // 数据无今天日程(从当前时间查起的)
    this.filterCurAgendaGroupList();
    this.refreshAgendaDot();
  }

  private onLanguageChange() {
    Log.info(TAG, 'onLanguageChange:' + this.language);
  }

  private onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange: ${this.timeZone}`);
    CalendarDate.timeZone = this.timeZone;
    this.onAgendaObjListChange();
  }

  onFormRecover(statusData: string): void {
    Log.info(TAG, `formId: ${this.formId} onFormRecover`);
    this.isRecoverFromRecycle = true;
  }

  onCurMonthVMChange() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    this.activeDay = FormUtils.getCurrentJulianDay()
    if (EmptyUtils.isNotOrEmptyString(this.curMonthVM)) {
      Log.error(TAG, `curMonthVM is null!`);
      return;
    }
    try {
      const monthData: CompressedDayData[] = JSON.parse(this.curMonthVM);
      let monthlyData = monthData.map(dayData => decompressData(dayData));
      // 判断是否有日程，有日程的显示红点
      monthlyData.forEach(dayModel => {
        dayModel.julianDay = DateUtil.date2julianDay(dayModel.year, dayModel.month, dayModel.day);
        dayModel.showAgendaDot = this.agendaGroupMap.has(dayModel.julianDay);
      })
      this.monthlyData = monthlyData;
      this.rowNum = this.monthlyData.length / 7;
      Log.info(TAG, `formId: ${this.formId} display year = ${this.monthlyData[10]?.year}, month = ${this.monthlyData[10]?.month}`);
    } catch (error) {
      Log.logErrorMsg(TAG, `monthData parse error`, error);
    }
  }

  // 刷新日程红点
  private refreshAgendaDot() {
    Log.info(TAG, 'refreshAgendaDot this.agendaGroupMap.size:' + this.agendaGroupMap.size);
    this.monthlyData.forEach(dayModel => {
      dayModel.showAgendaDot = this.agendaGroupMap.has(dayModel.julianDay);
    })
  }

  hasAgendaList(): boolean {
    return this.agendaGroupList[this.agendaGroupMap.get(this.activeDay) as number]?.items?.length > 0;
  }

  aboutToAppear() {
    Log.info(TAG, `formId: ${this.formId} aboutToAppear start`);
    this.initAgendas();
    if (this.curMonthVM !== '') {
      this.onCurMonthVMChange();
    }
    crossDayExceptionCheckAndRetry(this, this.curJulianDay);
    Log.info(TAG, `formId: ${this.formId} aboutToAppear end.`);
  }

  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`);
  }

  onAgendaRefresh() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    Log.info(TAG, `formId: ${this.formId} onAgendaRefresh julianDayOfNow = ${FormUtils.julianDay2Date(this.julianDayOfNow)}`);
  }

  @Builder
  NoAgendaCardView() {
    Column() {
      WeekDayView({
        activeDay: this.activeDay,
        curMonthVM: this.monthlyData,
        isAgreeStatement: false
      });

      Column() {
        Image($r('app.media.ic_not_yet_authorized'))
          .width(96)
          .height(96)
          .draggable(false)
        Text($r('app.string.not_yet_authorized'))
          .fontSize(14)
          .maxFontScale(1)
          .opacity(0.6)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({
        bottom: 16
      })
    }
    .padding({ top: 12, left: 15, right: 12 })
    .backgroundColor($r('app.color.color_card_bg'))
  }

  @Builder
  NoExpireAgendaView() {
    Column() {
      WeekDayView({
        activeDay: this.activeDay,
        curMonthVM: this.monthlyData,
        isAgreeStatement: true
      });

      // 选中天存在日程，且不显示全部过期日程场景
      if (this.isShowAgendaList &&
        this.agendaGroupList[this.agendaGroupMap.get(this.activeDay) as number]?.items?.length > 0) {
        // 日程行
        this.OneDayAgendaList();
      } else {
        Row() {
          this.buildNoAgenda();
        }
        .layoutWeight(1)
        .padding({
          bottom: 16
        })
      }
    }
    .padding({ top: 12, left: 12, right: 12 })
    .backgroundColor(this.hasAgendaList() ? $r('app.color.color_card_bg') : $r('app.color.color_card_bg_ext'))
    .transition(this.isRecoverFromRecycle
      ? TransitionEffect.IDENTITY
      : TransitionEffect.OPACITY.combine(TransitionEffect.rotate({} as RotateOptions)).animation({ duration: 300 }))
    .overlay(this.gradientBuilder(), {
      align: Alignment.Bottom,
    })
  }

  @Builder
  buildNoAgenda() {
    RelativeContainer() {
      Column() {
        Image($r('app.media.ic_no_agenda'))
          .width(140)
          .height(140)
          .draggable(false)
        Text(this.agendaInfoText)
          .fontSize(14)
          .maxFontScale(1)
          .opacity(0.6)
      }
      .alignRules({
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        center: { anchor: '__container__', align: VerticalAlign.Center },
      })
      .offset({ y: -40 }) // UX要求减去下方文字后居中,设置Y轴向上偏移

      // 如果今天的日程全部过期 && 选中今天 && 明天存在日程
      if (this.showJumpTomorrowButton) {
        Row() {
          Text($r('app.string.view_tomorrow_schedule_text'))
            .fontSize(14)
            .maxFontScale(1)
            .fontColor($r('app.color.red_common'))
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(14)
            .fontColor([$r('app.color.red_common')])
            .margin({ left: 8 });
        }
        .alignItems(VerticalAlign.Center)
        .height(40)
        .margin({ bottom: 16 })
        .alignRules({
          bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
          middle: { anchor: '__container__', align: HorizontalAlign.Center },
        })
        .onClick(() => {
          // 跳转到第二天的月视图
          const date = FormUtils.julianDay2Date(this.activeDay + 1);
          jumpToMonthView(this, date.getFullYear(), date.getMonth(), date.getDate(), this.formId);
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  gradientBuilder() {
    Row() {
    }
    .height(24)
    .width(this.hasAgendaList() ? '100%' : 0)
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
  OneDayAgendaList() {
    List({ scroller: this.scroller }) {
      ForEach(this.agendaGroupList[this.agendaGroupMap.get(this.activeDay) as number].items,
        (cardAgenda: AgendaCardInfo, index: number | undefined) => {
          ListItem() {
            CardAgendaItem({
              agenda: cardAgenda,
              deviceLayout: this.deviceLayout,
              formId: this.formId,
              isFinal: index ===
                this.agendaGroupList[this.agendaGroupMap.get(this.activeDay) as number].items.length - 1,
              isRTL: i18n.isRTL(this.language),
              dimension: DIMENSION_6_4,
              // 当前现实时间 == 视图选中天 且 日程出于过期状态 才标记为过期日程
              isExpired: (this.julianDayOfNow === this.activeDay && cardAgenda.mEnd < Date.now()) ? true : false,
              timeZone: this.timeZone,
              is24HourClock: this.is24HourClock
            })
          }
        })
      ListItem() {
      }
      .width('100%')
      .id(TAG + '_blank_item')
      // 此处高度为 日程个数 * (单条日程高度 + 底部边距) - 底部、顶部间距和
      .height(this.unexpiredAgendaCounts == -1 ? '0%' : 'calc(100% - ' + (this.unexpiredAgendaCounts * (78 + 8) - 8) + 'vp)')
    }
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .padding({ top: 4, bottom: 12 })
    .scrollBar(BarState.Off)
    .borderRadius({ topLeft: 12, topRight: 12 })
    .width('100%')
    .align(Alignment.Top)
    .layoutWeight(1)
  }

  build() {
    Column() {
      if (!this.isAgreeStatement && !this.isDoubleUpSingleAgreeStatement) {
        // 未授权，未进入过日历的默认样式
        this.NoAgendaCardView();
      } else if (!this.isDataProcessedFirstTime) {
        // 初次尚未加载到数据
        InitCardView4x6();
      } else {
        // 正常情况
        this.NoExpireAgendaView()
      }
    }
    .accessibilityText(this.getAccessibilityText())
    .accessibilityLevel('yes')
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} build is click, jumpToMonthView date: ${this.activeDay}`);
      const date = FormUtils.julianDay2Date(this.activeDay);
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
    this.agendaList = this.parseObjToAgendaArray();
    this.initAgendaParam();
    this.agendaListSplitByDay = FormUtils.groupAgendaByDayAll(this.agendaList, this.julianDayOfNow);
    this.getAgendaGroupList();
    this.is24HourClock = I18nUtil.is24HourClock();
    // 刷新日程红点
    this.refreshAgendaDot();
    Log.info(TAG, `formId: ${this.formId} initAgendas end.`);
  }

  /**
   * 将数据代理查询的Object数组转化为类数组
   * @returns 转化后的 AgendaCardInfo 数组
   */
  private parseObjToAgendaArray(): Array<AgendaCardInfo> {
    Log.info(TAG, `formId: ${this.formId} parseObjToAgendaArray start.`);
    let agendaList: AgendaCardInfo[] = [];
    if (!(this.agendaObjList instanceof Array)) {
      return agendaList;
    }
    // 数据对象转换
    this.agendaObjList.forEach((agendaObj: object) => {
      let agenda: AgendaCardInfo = new AgendaCardInfo();
      agenda.parseFromObj(agendaObj);
      agendaList.push(agenda);
    })
    // 根据mId进行数据去重(跨天日程会查到两次)
    agendaList = this.deduplicateListById(agendaList);
    Log.info(TAG, `formId: ${this.formId} parseObjToAgendaArray agendaList.length: ${agendaList.length}`);
    return CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(agendaList);
  }

  /**
   * 根据mId对数据去重
   * @param list
   * @returns
   */
  deduplicateListById(list: AgendaCardInfo[]) {
    let tempMap: HashMap<number, AgendaCardInfo> = new HashMap<number, AgendaCardInfo>();
    for (let item of list) {
      tempMap.set(item.mId, item);
    }
    let newList: AgendaCardInfo[] = Array.from(tempMap.values());
    Log.info(TAG, `formId: ${this.formId} deduplicateListById before:${list.length},after:${newList.length}`);
    return newList;
  }

  /**
   * 日程改变回调
   */
  onAgendaObjListChange() {
    try {
      // clean说明是清空暂存数据，不处理
      if ('clean' === this.agendaObjList) {
        Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange agendaObjList clean`);
        return;
      }
      // 处理日程数据
      this.doAgendaObjListChange();
      // 数据代理数据消费完不能清除，会与卡片框架恢复机制冲突
    } catch (e) {
      Log.logErrorMsg(TAG, 'onAgendaObjListChange', e)
    }
  }

  /**
   * 处理日程变更
   */
  doAgendaObjListChange() {
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange agendaObjList.length : ${this.agendaObjList.length}`);

    this.initAgendas();
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
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_MONTH_VIEW,
      }
    });
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange end.`);
    // 因为无5秒复位，所以卡片当前日程可能不是今天，故检测到刷新需要复位，避免数据代理的查询覆盖了点击查询，导致选中日刷新后只有几条数据
    this.activeDay = this.julianDayOfNow;
  }

  /**
   * 点击日程后，触发增量日程改变回调
   */
  onAgendaAddedListChange() {
    Log.info(TAG, `onAgendaAddedListChange this.agendaAddedList = ${this.agendaAddedList.length}`);
    try {
      // 无增量数据
      if (!this.agendaAddedList) {
        return;
      }
      // clean说明是清空暂存数据，不处理
      if ('clean' === this.agendaAddedList) {
        return;
      }
      this.doAgendaAddedListChange();
      // 4.消费完清除增量数据
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.REMOVE_ADDED_4X6,
          name: 'agendaAddedList'
        }
      });
    } catch (e) {
      Log.logErrorMsg(TAG, 'onAgendaAddedListChange', e)
    }
  }

  /**
   * 将增量日程更新到页面中
   */
  doAgendaAddedListChange() {
    Log.info(TAG, `formId: ${this.formId} onAgendaAddedListChange agendaAddedList string.length : ${this.agendaAddedList?.length}`);
    let newList: AgendaCardInfo[] = JSON.parse(this.agendaAddedList);
    Log.info(TAG, 'newList.length:' + newList.length);
    // 1.增加日程数据到数组，去重，并排序
    // 新增并去重
    let tempMap: HashMap<number, AgendaCardInfo> = new HashMap<number, AgendaCardInfo>();
    for (let item of newList) {
      tempMap.set(item.mId, item);
    }
    for (let item of this.agendaList) {
      if (tempMap.hasKey(item.mId)) {
        continue;
      }
      newList.push(item);
    }
    this.agendaList = newList;
    // 排序
    this.agendaList = this.agendaList.sort((a, b) => {
      return a.mBegin - b.mBegin;
    })
    // 2.日程分组
    this.agendaListSplitByDay = [];
    this.agendaGroupList = [];
    this.agendaGroupMap = new Map<number, number>();
    const julianDayOfNow = FormUtils.getCurrentJulianDay();
    this.agendaListSplitByDay = FormUtils.groupAgendaByDayAll(this.agendaList, julianDayOfNow);
    this.getAgendaGroupList();
    // 3.刷新日程红点
    this.refreshAgendaDot();
    Log.info(TAG, `formId: ${this.formId} onAgendaAddedListChange end.`);
  }

  /**
   * 初始化日程参数
   */
  private initAgendaParam() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    Log.info(TAG, `formId: ${this.formId} julianDayOfNow is changed to ${FormUtils.julianDay2Date(this.julianDayOfNow)}`);
    this.agendaListSplitByDay = [];
    this.agendaGroupList = [];
    this.agendaGroupMap = new Map<number, number>();
    this.agendaInfoText = $r('app.string.no_schedule_today_relax_text');
  }

  /**
   * 获取日程组对象数组
   */
  private getAgendaGroupList() {
    if (this.agendaListSplitByDay.length === 0) {
      return;
    }
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
    this.filterCurAgendaGroupList();
    Log.info(TAG, `this.agendaGroupMap.size: ${this.agendaGroupMap.size}`);
    this.weekHasNotExpireAgenda = this.agendaGroupList.length !== 0;
    Log.info(TAG, `formId: ${this.formId} getAgendaGroupList agendaGroupList.length: ${this.agendaGroupList.length}`);
  }

  /**
   * 过滤当天的日程组
   * 本函数主要输出 showJumpTomorrowButton 和 agendaInfoText 处理列表吸顶
   * agendaInfoText = '今天没有日程安排，放松一下~' // 选中今天 且今天 没有日程安排
   * agendaInfoText = '没有日程' // 选中非今天 且当天 没有日程
   * agendaInfoText = '今天辛苦了，好好休息吧！' // 选中今天 且今天 日程全部过期
   * showJumpTomorrowButton = true // 今天没有日程 或 今天日程全部过期
   * 选中天为今天 && 没有有全天日程 处理吸顶 吸顶到未过期的日程
   */
  private filterCurAgendaGroupList() {
    const today = this.julianDayOfNow;
    const activeDay = this.activeDay;
    const isTodayActive = activeDay === today;
    const agendaMap = this.agendaGroupMap;

    // 日志记录：输入参数
    Log.info(TAG, `filterCurAL julianDayOfNow=${today}, activeDay=${activeDay}`);

    // 0. 选中天没有日程
    if (!agendaMap.has(activeDay)) {
      this.agendaInfoText = isTodayActive
        ? $r('app.string.no_schedule_today_relax_text')
        : $r('app.string.agenda_empty_text');

      const tomorrowIndex = agendaMap.get(today + 1) as number | undefined;
      const isTomorrowAgendaExist = tomorrowIndex !== undefined &&
        this.agendaGroupList[tomorrowIndex]?.items?.length > 0;

      this.showJumpTomorrowButton = isTodayActive && isTomorrowAgendaExist;
      this.isShowAgendaList = false;
      this.unexpiredAgendaCounts = -1;

      Log.info(TAG, `filterCurAL No agenda on active day, ` +
        `showJumpTomorrowButton=${this.showJumpTomorrowButton}, isShowAgendaList=${this.isShowAgendaList}`);
      return;
    }

    // 1. 选中天不是今天 → 直接跳转到第一天（默认显示）
    if (!isTodayActive) {
      this.showJumpTomorrowButton = false;
      this.isShowAgendaList = true;
      this.scroller.scrollToIndex(0);
      this.unexpiredAgendaCounts = -1;

      Log.info(TAG, `filterCurAL Active day is not today, showing agenda list at index 0`);
      return;
    }

    // 2. 选中天是今天，且有日程
    const index = agendaMap.get(today) as number;
    const groupItems = this.agendaGroupList[index]?.items || [];

    // 判断当天最大结束时间是否已过期
    const maxEnd = groupItems.length > 0
      ? Math.max(...groupItems.map(item => item.mEnd))
      : 0;

    const isAllAgendaExpire = maxEnd <= Date.now();

    if (isAllAgendaExpire) {
      this.agendaInfoText = $r('app.string.worked_goot_rest_text');
      const tomorrowIndex = agendaMap.get(today + 1) as number | undefined;
      const isTomorrowAgendaExist = tomorrowIndex !== undefined &&
        this.agendaGroupList[tomorrowIndex]?.items?.length > 0;

      this.showJumpTomorrowButton = isTomorrowAgendaExist;
      this.isShowAgendaList = false;
      this.unexpiredAgendaCounts = -1;

      Log.info(TAG, `filterCurAL All agendas expired today, ` +
        `showJumpTomorrowButton=${this.showJumpTomorrowButton}, isShowAgendaList=${this.isShowAgendaList}`);
      return;
    }

    // 3. 当天存在全天日程或跨天中间日程 → 不做吸顶处理
    const hasAllDayAgenda = groupItems.some(item =>
    item.mIsAllDay === true ||
      (item.mIsMultiDayEvent && item.mFlag === AgendaCardInfo.FLAG_MID)
    );

    if (hasAllDayAgenda) {
      this.isShowAgendaList = true;
      this.scroller.scrollToIndex(0);
      this.unexpiredAgendaCounts = -1;

      Log.info(TAG, `filterCurAL Today has all-day or mid-day agenda, showing list at index 0`);
      return;
    }

    // 4. 正常情况：找最近未过期的日程，吸顶显示
    const now = Date.now();
    const nextUnexpiredIndex = groupItems.findIndex(item => item.mEnd > now);
    const unexpiredCount = groupItems.filter(item => item.mEnd > now).length;

    this.unexpiredAgendaCounts = nextUnexpiredIndex === 0 ? -1 : unexpiredCount; // 没有过期日程 不处理吸顶
    this.isShowAgendaList = true;
    this.scroller.scrollToIndex(nextUnexpiredIndex === -1 ? 0 : nextUnexpiredIndex);

    Log.info(TAG, `filterCurAL Scroll to index ${nextUnexpiredIndex}, unexpired count=${unexpiredCount}`);
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
      'faType': 'AgendaCard4x6'
    }
  });
}
