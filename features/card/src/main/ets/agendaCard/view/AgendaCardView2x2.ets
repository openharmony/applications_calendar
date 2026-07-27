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
import i18n from '@ohos.i18n';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import {
  AgendaCardGroup,
  AgendaCardInfo,
  AgendaFormType2x2,
  FormUtils,
} from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CARD_AGENDA, DIMENSION_2_2, jumpToAgendaDetail, jumpToServiceApp } from '../../utils/CardJumpUtils';
import { getAccountColor, crossDayExceptionCheckAndRetry } from '../../utils/CardUtils';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { CardUiUtils } from '../../utils/CardUiUtils';
import { RedDot } from './components/RedDot';
import { DayAgendaNumInfo } from '../common/DayAgendaNumInfo';
import { isChineseCalendar } from '@app/common';
import { OneKeyServicePlaceholder } from './components/CardAgendaItem';
import { CardType } from './components/CardAgendaItem';
import { parseObjToAgendaArray } from '../../utils/CardUtils'
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';
import { TimeStrViewModel } from '../viewModel/TimeStrViewModel';
import { CardAction } from '../../common/CardAction';

const TAG: string = 'AgendaCardView2x2';

const ACTION_HAG_PREFIX: string = 'action';

const ABILITY_HAG_PREFIX: string = 'ability';

@Extend(Text)
function textStyle(isSmallUp: boolean, deviceLayout: DeviceLayout) {
  .fontColor($r('sys.color.font_secondary'))
  .opacity($r('sys.float.alpha_secondary'))
  .fontSize(isSmallUp ? '10vp' : deviceLayout.cardAgendaTimeFontFixedSize)
  .maxFontScale(1)
  .fontWeight(FontWeight.Regular)
  .maxLines(1)
  .lineHeight(16)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 0 });
}

@Extend(Text)
function oneKeyServiceTextStyle(deviceLayout: DeviceLayout) {
  .fontColor($r('sys.color.font_secondary'))
  .opacity($r('sys.float.alpha_secondary'))
  .fontSize(deviceLayout.cardAgendaTimeFontFixedSize)
  .maxFontScale(1)
  .fontWeight(FontWeight.Regular)
  .maxLines(1)
  .lineHeight(14)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .margin({ top: 0 })
}

@Component
export struct AgendaCardView2x2 {
  // 当前 julianDay
  @State julianDayOfNow: number = 0;

  // 按天分组后的所有日程组
  @State agendaGroupList: Array<AgendaCardGroup> = [];

  // 是否进入日历隐私授权
  @LocalStorageProp('isAgreeStatement') @Watch('isAgreeStatementChange') isAgreeStatement: boolean = true;

  // 没有日程时显示的文本
  @State agendaInfoText: Resource = $r('app.string.no_agenda_today');

  // 是否展示明天的日程组
  @State isTomorrow: boolean = false;

  // 卡片数据代理返回的 JSON 数组
  @LocalStorageProp('agendaObjList') @Watch('onAgendaObjListChange') agendaObjList: Array<AgendaCardInfo> = [];

  @LocalStorageProp('todayAgendaObjList') @Watch('onTodayAgendaObjListChange') todayAgendaObjList: Array<AgendaCardInfo> = [];

// 卡片数据代理返回的 JSON 数组 - 按天分组
@LocalStorageProp('dayAgendaNumInfo') @Watch('onDayAgendaNumInfoChange') dayAgendaNumInfo: DayAgendaNumInfo[] = [];

@LocalStorageProp('isDoubleUpSingleAgreeStatement') isDoubleUpSingleAgreeStatement: boolean = false;

// 今日有未过期的日程
@State todayHasNotExpireAgenda: boolean = false;

  // 凌晨更新
  @LocalStorageProp('agendaRefresh') @Watch('onAgendaRefresh') agendaRefresh: string = '';

  @LocalStorageProp('deviceLayout') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @LocalStorageProp('formId') formId: string = '';

  @LocalStorageProp('needCommerce') needCommerce: boolean = false;

  @State oldAgendaObjList: Array<AgendaCardInfo> = [];

  @State dateTimeOld: CalendarDate = new CalendarDate();

  @State agendaFormType: AgendaFormType2x2 = AgendaFormType2x2.NO_SCHEDULE;

  @State oneKeyServiceAgenda: AgendaCardInfo = new AgendaCardInfo();

  @LocalStorageProp('language') @Watch('onLanguageChange') language: string = i18n.System.getSystemLocale();

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();

  // 按天拆分后的日程数组
  private agendaListSplitByDay: Array<AgendaCardInfo> = [];

  // 日程组标题 map, <儒略日日期， 日程在日程组list的位置>
  private agendaGroupMap: Map<number, number> = new Map<number, number>();

  /** 存储加桌或刷新时的儒略日,便于校验卡片回收恢复场景下是否需要刷新重试 */
  @LocalStorageProp('currentJulianDay') curJulianDay: number = 0;

  @Provide agendaNumsMap: Map<number, number> = new Map<number, number>();

  /** 监听日历应用历法改变 用于判断农历日期的显隐性 */
  @LocalStorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = 0;

  /** 卡片上的农历日期显示 */
  @State lunarDateStr: string = '';

  isAgreeStatementChange() {
    Log.info(TAG, `isAgreeStatement = ${this.isAgreeStatement}`);
  }

  aboutToAppear() {
    Log.log(TAG, `formId: ${this.formId} aboutToAppear start`);
    this.initAgendas();
    this.onSubscriptionCalendarChange();
    crossDayExceptionCheckAndRetry(this, this.curJulianDay);
    Log.log(TAG, `formId: ${this.formId} aboutToAppear end`);
  }

  /**
   * 更新要显示的日程列表
   * @param now 当前时间
   * @param agendaList 需要更新的日程列表
   * @param textInfo 需要展示的信息
   * @param isTomorrowList 是否是明天的日程组
   * @param showTomorrow 是否展示的是明天的日程
   */
  updateAgendaList(now: number, agendaList: AgendaCardGroup[], textInfo: Resource,
                   isTomorrowList: boolean = false, showTomorrow: boolean = false) {
    // 如果是明天的日程组只需要判空展示
    if (isTomorrowList) {
      if (agendaList.length !== 0) {
        this.agendaGroupList = agendaList;
      } else {
        this.agendaInfoText = textInfo;
        this.agendaGroupList = [];
      }
      this.isTomorrow = showTomorrow;
      return;
    }

    if (agendaList.length !== 0) {
      // 今天有日程则判断当天日程最大的结束时间是否大于当前时间
      const maxEnd = Math.max(...(agendaList[0].items.map(item => item.mEnd)));
      if (maxEnd <= now) {
        this.agendaInfoText = textInfo;
        this.agendaGroupList = [];
      } else {
        agendaList[0].items = agendaList[0].items.filter((info: AgendaCardInfo) => info.mEnd > now);
        this.agendaGroupList = agendaList;
      }
    } else {
      this.agendaInfoText = $r('app.string.no_agenda_today');
      this.agendaGroupList = [];
    }
    this.isTomorrow = showTomorrow;
  }

  @Builder
  gradientBuilder() {
    Row() {
    }
    .height(24)
    .width('100%')
    .border({ radius: { bottomLeft: 12, bottomRight: 12 } })
    .linearGradient({
      angle: 180,
      colors: [
        [$r('app.color.id_color_card_gradient_start'), 0],
        [$r('app.color.id_color_card_gradient'), 0.5],
      ]
    })
    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
  }

  @Builder
  buildForEachAgendas() {
    List() {
      ForEach(this.agendaGroupList, (agendaGroup: AgendaCardGroup, index: number | undefined) => {
        ListItem() {
          Column() {
            BuildOneDayGroup({
              group: agendaGroup,
              deviceLayout: this.deviceLayout,
              formId: this.formId,
              isRTL: i18n.isRTL(this.language),
              timeZone: this.timeZone
            })
          }
        }
      }, (agendaGroup: AgendaCardGroup, index: number) => `${index}-${this.getUniqueTagByAgendaGroup(agendaGroup, this.timeZone)}`)
    }
    .scrollBar(BarState.Off)
    .borderRadius({ bottomLeft: 18, bottomRight: 18 })
  }

  @Builder
  agendaCardView() {
    if (this.agendaFormType === AgendaFormType2x2.NO_SCHEDULE) {
      TitleZeroAgendaMessage({
        julianDayOfNow: this.julianDayOfNow,
        agendaInfoText: this.agendaInfoText,
        isRTL: i18n.isRTL(this.language),
        lunarDateStr: this.lunarDateStr
      })
    } else if (this.agendaFormType === AgendaFormType2x2.ONE_SCHEDULE) {
      TitleOneAgendaMessage({ julianDayOfNow: this.julianDayOfNow, isRTL: i18n.isRTL(this.language) })
      Row() {
        this.buildForEachAgendas();
      }
      .margin({ top: -16 })
      .padding({ bottom: 12 })
      .alignItems(VerticalAlign.Bottom)
      .layoutWeight(1)
    } else if (this.agendaFormType === AgendaFormType2x2.MULTI_SCHEDULE) {
      TitleMessage({
        realTime: FormUtils.julianDay2Date(this.julianDayOfNow),
        isTomorrow: this.isTomorrow,
        isRTL: i18n.isRTL(this.language),
        count: CardUiUtils.getAgendaCountFromGroupList(this.agendaGroupList)
      })
      Row() {
        this.buildForEachAgendas();
      }
      .overlay(this.gradientBuilder(), {
        align: Alignment.Bottom,
      })
      .alignItems(VerticalAlign.Top)
      .padding({ top: 16, bottom: 12 })
      .layoutWeight(1)
    } else if (this.agendaFormType === AgendaFormType2x2.MEETING_SCHEDULE) {
      OneKeyServiceAgenda({ agenda: this.oneKeyServiceAgenda, formId: this.formId, deviceLayout: this.deviceLayout })
    }
  }

  build() {
    Column() {
      if (this.isAgreeStatement || this.isDoubleUpSingleAgreeStatement) {
        this.agendaCardView();
      } else {
        TitleZeroAgendaMessage({ julianDayOfNow: this.julianDayOfNow, agendaInfoText: $r('app.string.not_yet_authorized'), isRTL: i18n.isRTL(this.language) })
      }
    }
    .accessibilityLevel('yes')
    .accessibilityText(this.getAccessibilityText())
    .backgroundColor($r('app.color.color_card_bg_ext'))
    .padding({
      top: 4,
      right: 4,
      left: 4
    })
    .width('100%')
    .height('100%')
    .onClick(() => {
      Log.info(TAG, `formId:${this.formId} build is click, jumpToMonthView/jumpToAgendaDetail agendaFormType: ${this.agendaFormType}`);
      if (this.agendaFormType == AgendaFormType2x2.MEETING_SCHEDULE) {
        Log.info(TAG, `formId: ${this.formId},meeting agenda is click`);
        jumpToAgendaDetail(this, this.oneKeyServiceAgenda, CARD_AGENDA, DIMENSION_2_2, this.needCommerce);
      } else {
        const date = this.isTomorrow
          ? FormUtils.julianDay2Date(this.julianDayOfNow + 1)
          : FormUtils.julianDay2Date(this.julianDayOfNow);
        jumpToMonthView(this, date.getFullYear(), date.getMonth(), date.getDate(), this.formId);
      }
    })
  }

  /**
   * 用于控制列表显示刷新，防止多次刷新抖动
   * @param agendaGroup
   * @returns
   */
  private getUniqueTagByAgendaGroup(agendaGroup: AgendaCardGroup, timeZone: string): string {
    let tag: string = String(agendaGroup.julianDay);
    agendaGroup.items.forEach((item: AgendaCardInfo) => {
      tag += item.mTitle + item.mDisplayColor + item.mLocation + item.mBegin + item.mEnd + item.mHwextServiceVerified +
        (item.mAttachmentCount === 0) + timeZone;
    })
    return tag;
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
   * 初始化日程参数
   */
  private initAgendaParam() {
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    this.onSubscriptionCalendarChange();
    Log.info(TAG, `formId: ${this.formId} julianDayOfNow is changed to ${FormUtils.julianDay2Date(this.julianDayOfNow)}`);
    this.agendaListSplitByDay = [];
    this.agendaGroupList = [];
    this.isTomorrow = false;
    this.agendaGroupMap = new Map<number, number>();
  }

  /**
   * 初始化帐户列表
   */
private initAgendas() {
Log.info(TAG, `formId: ${this.formId}, timeZone= ${this.timeZone} initAgendas start.`);
let agendaList: AgendaCardInfo[] = parseObjToAgendaArray(this.agendaObjList, this.formId);
this.initAgendaParam();
this.agendaListSplitByDay = FormUtils.groupAgendaByDay(agendaList, this.julianDayOfNow);
this.getAgendaGroupList();
}

  /**
   * 日程改变回调
   */
  private onAgendaObjListChange() {
    Log.info(TAG, `formId: ${this.formId} onAgendaObjListChange agendaObjList.length: ${this.agendaObjList?.length}`);
    // 主要用于刷新时区数据
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_TIME_ZONE,
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

    // 确定卡片类型
    if (!this.agendaGroupList || this.agendaGroupList?.length == 0) {
      this.agendaFormType = AgendaFormType2x2.NO_SCHEDULE;
    } else {
      let isShow: boolean = false;

      // 有日程在开会前15分钟展示入会卡片
      for (let i = 0; i < this.agendaGroupList[0].items.length; i++) {
        if (this.agendaGroupList[0].items[i].canShowOneKeyService(this.formId)) {
          this.oneKeyServiceAgenda = this.agendaGroupList[0].items[i];
          this.agendaFormType = AgendaFormType2x2.MEETING_SCHEDULE;
          isShow = true;
          return;
        }
      }

      if (!isShow) {
        if (this.agendaGroupList[0].items?.length === 1) {
          this.agendaFormType = this.isTomorrow ? AgendaFormType2x2.MULTI_SCHEDULE : AgendaFormType2x2.ONE_SCHEDULE;
        } else {
          this.agendaFormType = AgendaFormType2x2.MULTI_SCHEDULE;
        }
      }
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
    Log.info(TAG, `formId: ${this.formId} onAgendaRefresh agendaObjList.length: ${this.agendaObjList?.length}`);
    if (this.agendaObjList?.length < 1) {
      this.onAgendaObjListChange();
    }
    this.julianDayOfNow = FormUtils.getCurrentJulianDay();
    // 跨天刷新后,没有入口调用农历日期更新,此处会对julianDayOfNow进行重新赋值，因此在这里做业务处理
    this.onSubscriptionCalendarChange();
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
   * 获取日程组对象数组
   */
  private getAgendaGroupList() {
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
    this.filterAgendaGroupList();
  }

  /**
   * 过滤要展示的日程组
   */
  private filterAgendaGroupList() {
    // 当前时间
    const now = new CalendarDate().getTime();
    // 当天18：00
    const deadLineTime = new CalendarDate(new CalendarDate().setHours(18, 0, 0, 0)).getTime();
    // 当天日程组
    const todayAgendaList = this.agendaGroupList.filter(item => item.julianDay === this.julianDayOfNow);
    // 明天日程组
    const tomorrowAgendaList = this.agendaGroupList.filter(item => item.julianDay === this.julianDayOfNow + 1);
    // 今天和明天都没有日程时显示”今日无日程“
    if (todayAgendaList.length === 0 && tomorrowAgendaList.length === 0) {
      this.todayHasNotExpireAgenda = false;
      this.agendaInfoText = $r('app.string.no_agenda_today');
      return;
    }

    // 判断当前时间是否小于等于当天的18：00
    if (now <= deadLineTime) {
      this.updateAgendaList(now, todayAgendaList, $r('app.string.today_agenda_is_all_done'));
    } else {
      // 判断当天日程组最后一条结束时间是否大于等于当前时间
      if (todayAgendaList.length !== 0 && todayAgendaList[0].items.length !== 0 &&
        todayAgendaList[0].items[todayAgendaList[0].items.length - 1].mEnd >= now) {
        this.updateAgendaList(now, todayAgendaList, $r('app.string.today_agenda_is_all_done'));
      } else {
        this.updateAgendaList(now, tomorrowAgendaList, $r('app.string.today_agenda_is_all_done'), true, tomorrowAgendaList.length !== 0);
      }
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
 *  无日程时卡片展示信息
 */
@Component
struct TitleZeroAgendaMessage {
  @Prop julianDayOfNow: number = 0;

  @Prop agendaInfoText: Resource;

  @Prop isRTL: boolean;

  @Prop lunarDateStr: string;

  build() {
    Column() {
      Row() {
        Text(FormUtils.getWeekSmallMessage(FormUtils.julianDay2Date(this.julianDayOfNow)))
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_primary'))
          .fontSize($r('sys.float.ohos_id_text_size_body3'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Regular)
      }.width('100%')

      Row() {
        Text(`${FormUtils.julianDay2Date(this.julianDayOfNow).getDate()}`)
          .fontColor($r('app.color.red_common'))
          .fontSize(40)
          .maxFontScale(1)
          .lineHeight(40)
          .fontWeight(FontWeight.Bold)
      }.width('100%').margin({ left: !this.isRTL ? -2 : undefined, right: this.isRTL ? -2 : undefined, top: 4 })


      Column() {
        Text(this.lunarDateStr)
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_secondary'))
          .fontSize($r('sys.float.Body_S'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Regular)
          .margin({
            bottom: 4
          })

        Text(this.agendaInfoText)
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_secondary'))
          .fontSize($r('sys.float.Body_S'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Regular)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }.width('100%').layoutWeight(1).justifyContent(FlexAlign.End).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .padding({
      left: 8,
      right: 8,
      top: 8,
      bottom: 12
    })
  }
}

/**
 *  单个日程组：标题组件
 */
@Component
struct TitleOneAgendaMessage {
  @Prop julianDayOfNow: number = 0;

  @Prop isRTL: boolean;

  build() {
    Column() {
      Row() {
        Text(FormUtils.getWeekSmallMessage(FormUtils.julianDay2Date(this.julianDayOfNow)))
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_primary'))
          .fontSize($r('sys.float.ohos_id_text_size_body3'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Regular)
      }.width('100%')

      Row() {
        Text(`${FormUtils.julianDay2Date(this.julianDayOfNow).getDate()}`)
          .fontColor($r('app.color.red_common'))
          .fontSize(40)
          .maxFontScale(1)
          .lineHeight(40)
          .fontWeight(FontWeight.Bold)
      }.width('100%').margin({ left: !this.isRTL ? -2 : undefined, right: this.isRTL ? -2 : undefined, top: 4 })
    }
    .padding(8)
  }
}

/**
 * 单个日程组：标题组件
 */
@Component
struct TitleMessage {
  @Prop realTime: CalendarDate;

  // 是否是今天的标题
  @Prop isTomorrow: boolean;

  @Prop isRTL: boolean;

  @Prop count: number;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  @Consume agendaNumsMap: Map<number, number>;

  build() {
    if (!this.isTomorrow) {
      Row() {
        Text(this.realTime.getDate().toString())
          .fontColor($r('app.color.red_common'))
          .fontSize(this.isSmallUp ? $r('sys.float.Subtitle_M') : $r('sys.float.Subtitle_L'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .opacity(0.9)

        Text($r('app.string.day_view'))
          .fontSize(this.isSmallUp ? $r('sys.float.Body_M') : $r('sys.float.Body_L'))
          .maxFontScale(1)
          .fontColor($r('app.color.red_common'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .opacity(0.9)
          .visibility(i18n.System.getSystemLanguage() === 'en-Latn-US' ? Visibility.None : Visibility.Visible)

        Text(FormUtils.getWeekSmallMessage(this.realTime))
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_primary'))
          .fontSize(this.isSmallUp ? $r('sys.float.Body_M') : $r('sys.float.Body_L'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .margin({ left: !this.isRTL ? 4 : undefined, right: this.isRTL ? 4 : undefined })

        RedDot({ count: this.agendaNumsMap.get(this.realTime.getJulianDay()) ?? 0 })
      }
      .padding({ left: 8, right: 8, top: 8 })
      .width('100%')
    } else {
      Row() {
        Text($r('app.string.tomorrow'))
          .fontSize($r('sys.float.Body_L'))
          .maxFontScale(1)
          .fontColor($r('app.color.red_common'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .opacity(0.9)

        RedDot({ count: this.agendaNumsMap.get(this.realTime.getJulianDay() + 1) ?? 0 })
      }
      .padding({ left: 8, right: 8, top: 8 })
      .width('100%')
    }
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

  @Prop isRTL: boolean;

  @Prop timeZone: string;

  build() {
    Column() {
      List() {
        ForEach(this.group.items, (cardAgenda: AgendaCardInfo, index: number | undefined) => {
          this.buildForEach(cardAgenda)
        })
      }
    }
  }

  @Builder
  buildForEach(cardAgenda: AgendaCardInfo) {
    ListItem() {
      CardAgendaItem({
        agenda: cardAgenda,
        deviceLayout: this.deviceLayout,
        formId: this.formId,
        isRTL: this.isRTL,
        timeZone: this.timeZone
      })
    }
  }
}

/**
 * 单个日程组件
 */
@Component
struct CardAgendaItem {
  // 是否完成计算行数: 行数决定位置时间和账户颜色框的位置显示
  @State calculateRowCountFinished: boolean = true;

  // @State 不支持直接使用 ResourceStr，使用数组规避    -- 标题
  @State titleStrList: Array<ResourceStr> = [];

  @LocalStorageProp('needCommerce') needCommerce: boolean = false;

  // 日程实例
  @Prop @Watch('agendaChange') agenda: AgendaCardInfo = new AgendaCardInfo();

  // 0 -- 1行标题 无地址   1  --- 1行标题 有地址  2  --- 2行标题  无地址  3 -- 2行标题  有地址
  @State @Watch('typeChange') type: number = 0;

  @State lineHeight: number = 16;

  @Prop formId: string;

  @Prop deviceLayout: DeviceLayout;

  @Prop isRTL: boolean;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  @State accountColor: number = this.agenda.mDisplayColor;

  private newLine: string = '\n';

  /* 用于防止卡片高度突变与闪烁, 标识位 */
  private titleTypeFlag: number = 0;

  @Prop @Watch('onTimeZoneChange') timeZone: string;

  @State timeStrViewModel: TimeStrViewModel = new TimeStrViewModel();

  onTimeZoneChange() {
    this.timeStrViewModel.parseTimeStr();
  }

  aboutToAppear() {
    this.lineHeight = this.deviceLayout.cardLineHeightTypeZero2X2;
    this.transTitleMessage();
    if (this.agenda?.mLocation || this.agenda.isOnlineMeeting()) {
      this.type = 1;
    }
    this.accountColor = getAccountColor(this.agenda.mDisplayColor);
    this.timeStrViewModel = new TimeStrViewModel(this.agenda);
    Log.info(TAG, `CardAgendaItem aboutToAppear type: ${this.type}, is24hours: ${I18nUtil.is24HourClock()}`);
  }

  agendaChange() {
    this.transTitleMessage();
    this.timeStrViewModel.parseTimeStr();
    if (this.agenda?.mLocation || this.agenda.isOnlineMeeting()) {
      this.type = 1;
    } else {
      this.type = 0;
    }
    if(this.titleTypeFlag > 1) {
      this.type += this.titleTypeFlag;
    }
    Log.warn(TAG, `agendaChange type = ${this.type}`);
  }

  typeChange() {
    this.lineHeight = this.type == 0 ?
    this.deviceLayout.cardLineHeightTypeZero2X2 : (this.type == 1 ?
      this.deviceLayout.cardLineHeightTypeOne2X2 : (this.type == 2 ?
        this.deviceLayout.cardLineHeightTypeTwo2X2 : this.deviceLayout.cardLineHeightTypeThree2X2));
  }

  /**
   * 账户标签组件
   */
  @Builder
  AccountDivider() {
    Circle()
      .width(7)
      .height(7)
      .alignSelf(ItemAlign.Center)
      .stroke(this.accountColor)
      .fillOpacity(0)
      .strokeWidth(1.8)
      .margin({ left: !this.isRTL ? 2 : undefined, right: this.isRTL ? 2 : undefined })

    Column()
      .width(1)
      .height(this.lineHeight)
      .backgroundColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_tertiary'))
      .borderRadius(1.5)
      .margin({ top: 6, left: !this.isRTL ? 2 : undefined, right: this.isRTL ? 2 : undefined })
  }

  /**
   * 日程标题组件
   */
  @Builder
  AgendaTitle() {
    Row() {
      // 文本截断是按字截断。例如，英文以单词为最小单位进行截断，若需要以字母为单位进行截断，可在字母间添加零宽空格：\u200B。
      // 从API version 11开始，建议优先组合wordBreak属性设置为WordBreak.BREAK_ALL方式实现字母为单位进行截断。
      Text(this.titleStrList[0])
        .wordBreak(WordBreak.BREAK_ALL)
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_primary'))
        .fontFeature('\"ss08\" 1')
        .fontSize(this.isSmallUp ? $r('sys.float.Body_S') : $r('sys.float.Body_M'))
        .maxFontScale(1)
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
        .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
          this.titleTypeFlag = 0;
          if (nv.height && nv.height > 20 && this.type < 2) {
            this.type += 2;
            this.titleTypeFlag = 2; // 记录为两行标题情况
          }
          this.calculateRowCountFinished = true;
        })
        .constraintSize({ maxWidth: this.agenda?.mAttachmentCount > 0 ? 'calc(100% - 16vp)' : '100%' })

      if (this.agenda?.mAttachmentCount > 0) {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize(this.isSmallUp ? $r('sys.float.Body_S') : $r('sys.float.Body_M'))
          .fontColor([$r('sys.color.font_primary')])
          .width(16)
          .draggable(false)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ top: 3 })

    Row() {
      if (this.agenda.mIsAllDay || (this.agenda.mIsMultiDayEvent && this.agenda.mFlag === AgendaCardInfo.FLAG_MID)) {
        Text(this.timeStrViewModel?.timeStrStart).textStyle(this.isSmallUp, this.deviceLayout);
      } else {
        Text(this.timeStrViewModel?.timeStrStart).textStyle(this.isSmallUp, this.deviceLayout);
        Text('-').textStyle(this.isSmallUp, this.deviceLayout);
        Text(this.timeStrViewModel?.timeStrEnd).textStyle(this.isSmallUp, this.deviceLayout);
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Bottom)
    .padding({ top: 2 })
  }

  /**
   * 日程地点组件
   */
  @Builder
  AgendaLocation() {
    Text(this.agenda.mLocation.split(this.newLine)[0] ?? '')
      .fontColor($r('sys.color.font_secondary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize(this.deviceLayout.cardAgendaLocationFontSize)
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
  }

  @Builder
  buildAgendaLocation() {
    Row() {
      if (this.agenda?.mLocation) {
        this.AgendaLocation();
      } else if (this.agenda.isOnlineMeeting()) {
        OneKeyServicePlaceholder({
          info: this.agenda,
          deviceLayout: this.deviceLayout,
          agendaCardType: CardType.AGENDA_CARD_2X2
        })
      }
    }
    .padding({ top: 2 })
    .visibility(this.agenda?.mLocation || this.agenda.isOnlineMeeting() ? Visibility.Visible : Visibility.None)
  }

  build() {
    Row() {
      Column() {
        this.AccountDivider()
      }
      .padding({ left: !this.isRTL ? 8 : undefined, right: this.isRTL ? 8 : undefined, top: 2 })
      .justifyContent(FlexAlign.Center)

      Column() {
        this.AgendaTitle();
        this.buildAgendaLocation();
      }
      .padding({ left: 8, right: 8 })
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    }
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(this.type == 0 ? 50 : (this.type == 1 ? 66 : (this.type == 2 ? 68 : 84)))
    .padding({ top: 4 })
    .borderRadius(14)
    .onClick(() => {
      Log.info(TAG, `formId: ${this.formId} click agendaTitle: ${maskString(this.agenda.mTitle)}, ` +
        `startTime: ${this.agenda.mBegin}, endTime = ${this.agenda.mEnd}, eventUuid: ${maskString(this.agenda.mEventUuid)}`);
      jumpToAgendaDetail(this, this.agenda, CARD_AGENDA, DIMENSION_2_2, this.needCommerce);
    })
    .visibility(this.calculateRowCountFinished ? Visibility.Visible : Visibility.Hidden)
    .stateStyles({
      pressed: {
        .backgroundColor('#1a000000')
      },
      normal: {
        .backgroundColor('#00000000')
      }
    })
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
      Log.info(TAG, `onSizeChange nv_width=${nv.width}`);
      if (nv && nv.width && nv.width < 140) {
        this.deviceLayout.cardAgendaTimeFontFixedSize = '10vp';
      }
    })
  }

  /**
   * 获取显示的标题信息
   */
  private transTitleMessage() {
    this.titleStrList = [];
    this.titleStrList.push(this.agenda.getTitle());
    Log.info(TAG, `transTitleMessage agendaTitle: ${maskString(this.agenda.mTitle)}, beginTime: ${this.agenda.mBegin}, ` +
      `startDay: ${this.agenda.mDay}, currentJulianDay: ${FormUtils.getCurrentJulianDay()}`);
  }
}

/**
 * 一键服务日程
 */
@Component
export struct OneKeyServiceAgenda {
// 日程实例
@Prop @Watch('agendaChange') agenda: AgendaCardInfo = new AgendaCardInfo();

  // @State 不支持直接使用 ResourceStr，使用数组规避    -- 标题
  @State titleStrList: Array<ResourceStr> = [];

  @Prop formId: string;

  // 卡片标题
  @State cardTitle: Resource = $r('app.string.coming_soon');

  @Prop deviceLayout: DeviceLayout;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  // 加入会议按钮
  private btnStr: Resource = $r('app.string.join_the_meeting');

private getTitleFontSize() {
if (this.isSmallUp) {
return '14vp';
}

return this.deviceLayout.cardAgendaTitleFontSize;
}

  @Prop @Watch('onTimeZoneChange') timeZone: string;

  @State timeStrViewModel: TimeStrViewModel = new TimeStrViewModel();

  onTimeZoneChange() {
    this.timeStrViewModel.parseTimeStr();
  }

  aboutToAppear() {
    this.transCardTitle();
    this.transTitleMessage();
    this.timeStrViewModel = new TimeStrViewModel(this.agenda);
  }

  agendaChange() {
    this.transCardTitle();
    this.transTitleMessage();
    this.timeStrViewModel = new TimeStrViewModel(this.agenda);
  }

  onBtnClick() {
    Log.info(TAG, `OneKeyServiceAgenda onBtnClick mHwextServiceUri.length:${this.agenda?.mHwextServiceUri?.length}`);
    if (!this.agenda.mHwextServiceUri) {
      return;
    }
    let want: Want = {};
    const serviceUri: string = this.agenda.mHwextServiceUri;
    if (serviceUri.startsWith(ACTION_HAG_PREFIX) || serviceUri.startsWith(ABILITY_HAG_PREFIX)) {
      const allParts: string[] = serviceUri.split('//');
      if (allParts?.length < 2) {
        Log.error(TAG, 'oneKeyServiceComponent uri format error');
        return;
      }
      const wantParts: string[] = allParts[1].split('/');
      const bundleName: string = wantParts[0];
      const abilityName: string = wantParts[1];
      const action: string = wantParts[2];
      const parameters: string = wantParts[3];
      if (!bundleName || !abilityName) {
        Log.error(TAG, 'oneKeyServiceComponent no bundle name or ability name');
        return;
      }
      want = { bundleName, abilityName };
      if (action) {
        want.action = action;

        if (parameters) {
          want.parameters = JSON.parse(parameters);
        }
      }
    } else {
      want = { uri: serviceUri }
    }
    jumpToServiceApp(this, want);
  }

  @Builder
  buildAgendaTitleAndTime() {
    Text(this.cardTitle)
      .fontColor($r('app.color.red_common'))
      .lineHeight(16)
      .fontSize($r('sys.float.ohos_id_text_size_body3'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Medium)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('title')

Text(this.titleStrList[0])
.fontColor($r('sys.color.font_primary'))
.fontFeature('\"ss08\" 1')
.opacity($r('sys.float.alpha_primary'))
.fontSize(this.getTitleFontSize())
.maxFontScale(1)
.fontWeight(FontWeight.Bold)
.lineHeight(this.isSmallUp ? 16 : 20)
.textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(this.deviceLayout.cardAgendaTitleMaxLines)
      .alignRules({
        top: { anchor: 'title', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('agendaTitle')

    Row() {
      Text(this.timeStrViewModel?.timeStrStart).oneKeyServiceTextStyle(this.deviceLayout)
      Column() {
        Text('-')
          .fontColor($r('sys.color.font_secondary'))
          .opacity($r('sys.float.alpha_secondary'))
          .fontSize($r('sys.float.Caption_M'))
          .maxFontScale(1)
          .fontWeight(FontWeight.Regular)
          .maxLines(1)
          .lineHeight(14)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Center)

      Text(this.timeStrViewModel?.timeStrEnd).oneKeyServiceTextStyle(this.deviceLayout)
    }
    .alignRules({
      top: { anchor: 'agendaTitle', align: VerticalAlign.Bottom },
      left: { anchor: '__container__', align: HorizontalAlign.Start }
    })
    .id('time')
  }

  build() {
    RelativeContainer() {
      this.buildAgendaTitleAndTime()

Row() {
Text(this.agenda.getOneKeyServiceBtnStr())
.fontColor($r('app.color.red_common'))
.fontWeight(FontWeight.Medium)
.fontSize(14)
.maxFontScale(1)
}
      .justifyContent(FlexAlign.Center)
      .borderRadius(40)
      .border({ width: 1, color: $r('app.color.red_common') })
      .height('28%')
      .width('100%')
      .onClick(() => this.onBtnClick())
      .alignRules({
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .id('button')
    }
    .padding({
      left: 8,
      right: 8,
      top: 8,
      bottom: 12
    })
    .width('100%')
    .height('100%')
  }

  /**
   * 判断当前时间获取卡片标题
   */
  private transCardTitle() {
    const now = new Date().getTime();
    Log.info(TAG, `now time = ${now} this.agenda.mBegin = ${this.agenda.mBegin}`)
    if (now >= this.agenda.mBegin) {
      this.cardTitle = $r('app.string.on_going');
    } else {
      this.cardTitle = $r('app.string.coming_soon');
    }
  }

  /**
   * 获取显示的标题信息
   */
  private transTitleMessage() {
    this.titleStrList = [];
    if (this.agenda.mTitle === undefined || this.agenda?.mTitle?.length === 0) {
      this.titleStrList.push($r('app.string.no_title_label'));
      Log.info(TAG, 'transTitleMessage agendaTitle: null');
    } else {
      this.titleStrList.push(this.agenda.mTitle);
      Log.info(TAG, `transTitleMessage agendaTitle: ${maskString(this.agenda.mTitle)}`);
    }
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
      'faType': 'AgendaCard2x2'
    }
  });
}