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

import { CalendarDate } from '../date/CalendarDate';
import { DataShareResultUtil } from '../dao/util/DataShareResultSetUtil';
import { InnerResultSet } from '../dao/util/InnerResultSet';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { MILLS_PER_DAY, MILLS_PER_MINUTE, DateUtil } from '../util/DateUtil';
import { Log } from '../default/common/Log';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'AgendaFormCommonStruct';

/** 会议日程 */
const MEETING_AGENDA: string = 'Meeting';

// 日程服务类型-->一键服务按钮文字map
export interface EventObjectParam {
  id: number;
  event_id: number;
  calendar_id: number;
  calendar_color: number;
  account_type: string;
  title: string;
  eventLocation: string;
  description: string;
  startDay: number;
  endDay: number;
  begin: number;
  end: number;
  allDay: number;
  service_type: string;
  service_verified: number;
  service_cp_bz_uri: string;
  creator: string;
  event_uuid?: string;
  instanceUuid?: string;
  attachment_count: number;
  mCalendarUuid: string;
}

/**
 * 卡片日程组
 */
export class AgendaCardGroup {
  // 分组标题内容：日期 （儒略日日期）
  public julianDay: number;
  // 日期
  public date: CalendarDate;
  // 分组下的日程数组
  public items: AgendaCardInfo[];
  // 是否显示日期
  public isShowDay: boolean = true;
  // 是否显示星期
  public isShowWeek: boolean = true;
  // 是否显示日程数量
  public isShowCount: boolean = true;

  constructor(julianDay: number, items: AgendaCardInfo[]) {
    this.julianDay = julianDay;
    this.items = items;
    this.date = DateUtil.julianDay2Date(julianDay);
  }
}

/**
 * 卡片日程类
 */
export class AgendaCardInfo {
  public static FLAG_START: number = 0;
  public static FLAG_MID: number = 1;
  public static FLAG_END: number = 2;
  // 生日帐户类型
  public static BIRTHDAY_ACCOUNT_CORE_TYPE = 'birthday';
  // 双框架生日账户的accountType
  public static DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE = 'com.OpenHarmony.OpenHarmony.birthday'
  // 日程服务类型-->一键服务按钮文字map 此处只给卡片页面使用，卡片不支持导包，不支持枚举类方式引用
  private static SERVICE_TYPE_MAP: Map<string, Resource> = new Map([
    ['Meeting', $r('app.string.join_the_meeting')],
    ['Watching', $r('app.string.watch_now')],
    ['Repayment', $r('app.string.repay_now')],
    ['Live', $r('app.string.start_live_broadcast')],
    ['Shopping', $r('app.string.start_shopping')],
    ['Trip', $r('app.string.view_now')],
    ['Class', $r('app.string.start_the_class')],
    ['SportsEvents', $r('app.string.watch_now')],
    ['SportsExercise', $r('app.string.start_exercising')],
  ]);
  public static MINUTES_BEFORE_MEETING: number = 15; // 开会前15分钟,用于一键入会按钮的显示
  public mId: number = 0;
  public mEventId: number = 0;
  public mCalendarId: number = 0;
  public mDisplayColor: number = 0;
  public mDay: number = 0;
  public mTitle: string = '';
  public mLocation: string = '';
  public mDescription: string = '';
  public mStartDay: number = 0;
  public mEndDay: number = 0;
  public mIsMultiDayEvent: boolean = false;
  public mFlag: number = 0;
  public mBegin: number = 0;
  public mEnd: number = 0;
  public mIsAllDay: boolean = false;
  public mHwextServiceType: string = '';
  public mHwextServiceVerified: boolean = false;
  public mHwextServiceUri: string = '';
  public mCalendarType: string = '';
  public mCreator: string = '';
  public mEventUuid: string = '';
  public mInstanceUuid: string = '';
  public mAttachmentCount: number = 0;
  public mCalendarUuid: string = '';

  constructor(sourceData?: AgendaCardInfo) {
    if (sourceData == null) {
      return;
    }
    this.mId = sourceData.mId;
    this.mEventId = sourceData.mEventId;
    this.mCalendarId = sourceData.mCalendarId;
    this.mInstanceUuid = sourceData.mInstanceUuid;
    this.mStartDay = sourceData.mStartDay;
    this.mTitle = sourceData.mTitle;
    this.mLocation = sourceData.mLocation;
    this.mDescription = sourceData.mDescription;
    this.mBegin = sourceData.mBegin;
    this.mEnd = sourceData.mEnd;
    this.mDisplayColor = sourceData.mDisplayColor;
    this.mEndDay = sourceData.mEndDay;
    this.mIsAllDay = sourceData.mIsAllDay;
    this.mFlag = sourceData.mFlag;
    this.mDay = sourceData.mDay;
    this.mIsMultiDayEvent = sourceData.mIsMultiDayEvent;
    this.mHwextServiceType = sourceData.mHwextServiceType;
    this.mHwextServiceUri = sourceData.mHwextServiceUri;
    this.mHwextServiceVerified = sourceData.mHwextServiceVerified;
    this.mCalendarType = sourceData.mCalendarType;
    this.mCreator = sourceData.mCreator;
    this.mAttachmentCount = sourceData.mAttachmentCount;
    this.mCalendarUuid = sourceData.mCalendarUuid;
    this.mEventUuid = sourceData.mEventUuid;
  }

  parseFromObj(eventObj: object) {
    const temp: EventObjectParam = eventObj as EventObjectParam;
    this.mId = temp.id;
    this.mEventId = temp.event_id;
    this.mCalendarId = temp.calendar_id ?? 0;
    this.mInstanceUuid = temp.instanceUuid ?? '';
    this.mDisplayColor = temp.calendar_color ?? 0;
    this.mTitle = temp.title;
    this.mLocation = temp.eventLocation;
    this.mDescription = temp.description;
    this.mStartDay = temp.startDay;
    this.mEndDay = temp.endDay;
    this.mIsMultiDayEvent = this.mStartDay !== this.mEndDay;
    this.mBegin = temp.begin;
    this.mEnd = temp.end;
    this.mIsAllDay = temp.allDay ? temp.allDay === 1 : false;
    this.mHwextServiceType = temp.service_type;
    this.mHwextServiceVerified = temp.service_verified ? temp.service_verified === 2 : false;
    this.mHwextServiceUri = temp.service_cp_bz_uri;
    this.mCalendarType = temp.account_type;
    this.mCreator = temp.creator;
    this.mCalendarUuid = temp.mCalendarUuid ?? '';
    this.mEventUuid = temp.event_uuid ?? '';
    this.mAttachmentCount = temp.attachment_count ?? 0;
  }

  parseFromCursor(cursor: InnerResultSet) {
    this.mId = DataShareResultUtil.getColumnLongData(cursor, '_id', 0);
    this.mEventId = DataShareResultUtil.getColumnLongData(cursor, 'event_id', 0);
    this.mBegin = DataShareResultUtil.getColumnLongData(cursor, 'begin', 0);
    this.mEnd = DataShareResultUtil.getColumnLongData(cursor, 'end', 0);
    this.mStartDay = DataShareResultUtil.getColumnLongData(cursor, 'startDay', 0);
    this.mEndDay = DataShareResultUtil.getColumnLongData(cursor, 'endDay', 0);
    this.mTitle = DataShareResultUtil.getColumnStringData(cursor, 'title', '');
    this.mLocation = DataShareResultUtil.getColumnStringData(cursor, 'eventLocation', '');
    this.mDescription = DataShareResultUtil.getColumnStringData(cursor, 'description', '');
    this.mDisplayColor = -12213274;
    this.mCalendarId = DataShareResultUtil.getColumnLongData(cursor, 'calendar_id', 0);
    this.mIsMultiDayEvent = this.mStartDay !== this.mEndDay;
    this.mIsAllDay = DataShareResultUtil.getColumnLongData(cursor, 'allDay', 0) === 1;
    this.mCreator = DataShareResultUtil.getColumnStringData(cursor, 'creator', '');
    this.mInstanceUuid = DataShareResultUtil.getColumnStringData(cursor, 'instanceUuid', '');

    this.mHwextServiceUri =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.SERVICE_CP_BZ_URI, '');

    this.mHwextServiceVerified =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.SERVICE_VERIFIED, 0) === 2;

    this.mHwextServiceType =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.SERVICE_TYPE, '');

    this.mAttachmentCount =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.ATTACHMENT_COUNT, 0);

    this.mEventUuid =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.UUID, '');

    this.mCalendarUuid =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.CALENDAR_UUID, '');
  }

  // 一键入会
  isOnlineMeeting(): boolean {
    return this.mHwextServiceType === MEETING_AGENDA;
  }

  getOneKeyServiceBtnStr(): Resource {
    Log.info(TAG, 'canShowOneKeyService Show Join Meeting Button');
    return AgendaCardInfo.SERVICE_TYPE_MAP.get(this.mHwextServiceType) || $r('app.string.join_the_meeting');
  }

  isOutDate(): boolean {
    return Date.now() >= this.mEnd;
  }

  canShowOneKeyService(formId: string): boolean {
    if (!this.mHwextServiceVerified) {
      Log.warn(TAG, 'canShowOneKeyService mHwextServiceVerified is false, do not show button');
      return false;
    }

    if (AgendaCardInfo.SERVICE_TYPE_MAP.has(this.mHwextServiceType)) {
      // 开会前15分钟可见一键服务按钮
      const startTime: number = this.mBegin - MILLS_PER_MINUTE * AgendaCardInfo.MINUTES_BEFORE_MEETING;
      Log.info(TAG, `canShowOneKeyService formId: ${formId} OnlineMeeting startTime: ${startTime}, nowDate: ${Date.now()}`);
      return !this.isOutDate() && (Date.now() >= startTime);
    }
    return false;
  }

  /**
   * 判断日程账户是否是生日账户，当前仅兼容单、双框架
   * @returns
   */
  isBirthDay(): boolean {
    return this.mCalendarType === AgendaCardInfo.BIRTHDAY_ACCOUNT_CORE_TYPE ||
      this.mCalendarType === AgendaCardInfo.DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE;
  }

  getTitle(): ResourceStr {
    if (this.isBirthDay()) {
      if (!this.mTitle || this.mTitle === '') {
        return $r('app.string.no_name_birthday');
      }
      let birthDay = $r('app.string.somebody_birthday', this.mTitle);
      return birthDay;
    }
    if (!this.mTitle || this.mTitle === '') {
      return $r('app.string.no_title_label');
    }
    return this.mTitle;
  }
}


/**
 * 卡片公共方法
 */
export class FormUtils {
  // 星期资源映射
  public static weekMap: Map<number, ResourceStr> = new Map<number, ResourceStr>([
    [1, $r('app.string.Monday')],
    [2, $r('app.string.Tuesday')],
    [3, $r('app.string.Wednesday')],
    [4, $r('app.string.Thursday')],
    [5, $r('app.string.Friday')],
    [6, $r('app.string.Saturday')],
    [0, $r('app.string.Sunday')],
  ]);
  // 星期资源映射,英文缩写
  public static weekSmallMap: Map<number, ResourceStr> = new Map<number, ResourceStr>([
    [1, $r('app.string.MondaySmall')],
    [2, $r('app.string.TuesdaySmall')],
    [3, $r('app.string.WednesdaySmall')],
    [4, $r('app.string.ThursdaySmall')],
    [5, $r('app.string.FridaySmall')],
    [6, $r('app.string.SaturdaySmall')],
    [0, $r('app.string.SundaySmall')],
  ]);

  /**
   * 将负数十进制颜色转化为十六进制颜色
   *
   * @param sourceColor 负数十进制颜色
   */
  static HexColor(sourceColor: number): string {
    return (~(sourceColor) ^ 0xFFFFFF).toString(16);
  }

  /**
   * 将 Date 转化为需要显示的日期信息（卡片目前无法导包，需要手动拼接字符串，且无法跟语言绑定）
   */
  static getDayMessage(julianDay: number, date: CalendarDate): ResourceStr {
    const julianDayOfNow: number = FormUtils.getCurrentJulianDay();
    if (julianDay === julianDayOfNow - 2) {
      return $r('app.string.the_day_before_yesterday');
    } else if (julianDay === julianDayOfNow - 1) {
      return $r('app.string.yesterday');
    } else if (julianDay === julianDayOfNow) {
      return $r('app.string.today');
    } else if (julianDay === julianDayOfNow + 1) {
      return $r('app.string.tomorrow');
    } else if (julianDay === julianDayOfNow + 2) {
      return $r('app.string.the_day_after_tomorrow');
    } else {
      const lang: string = i18n.System.getSystemLanguage();
      return `${date.toLocaleString(lang, { month: 'long', day: 'numeric' })}`;
    }
  }

  /**
   * 将 Date 转化为需要显示的星期信息（卡片目前无法导包，需要手动拼接字符串，且无法跟语言绑定）
   */
  static getWeekMessage(date: CalendarDate): ResourceStr | undefined {
    const weekNum: number = date.getDay();
    return FormUtils.weekMap.get(weekNum);
  }

  /**
   * 将 Date 转化为需要显示的星期信息,英文模式显示缩略星期
   */
  static getWeekSmallMessage(date: CalendarDate): ResourceStr | undefined {
    const weekNum: number = date.getDay();
    return FormUtils.weekSmallMap.get(weekNum);
  }

  /**
   * 将count转化为卡片需要显示的字符串
   *
   * @param count 日程数量
   */
  static getAgendaCount(count: number) {
    if (count > 99) {
      return '99+';
    } else {
      return count.toString();
    }
  }

  /**
   * 获取当天的儒略日日期
   */
  static getCurrentJulianDay(): number {
    return new CalendarDate().getJulianDay();
  }

  /**
   * 儒略日转 jsDate日期
   *
   * @param julianDay 儒略日
   */
  static julianDay2Date(julianDay: number): CalendarDate {
    return DateUtil.julianDay2Date(julianDay);
  }

  /**
   * 按天对日程分组，并去除小于当天的日程项
   *
   * @param originList 待分组日程项
   * @param rangeBegin 分组的范围开始
   * @param rangeEnd 分组的范围结束
   * @param allDayOnTop 全天日程是否置顶
   */
  static groupAgendaByDay(
    originList: AgendaCardInfo[],
    julianDayBegin: number,
    allDayOnTop: boolean = true
  ): AgendaCardInfo[] {
    const res: AgendaCardInfo[] = [];
    const startDay: number = Math.min(...originList.map((item: AgendaCardInfo) => item.mStartDay));
    const startJulianDay: number = Math.max(startDay, julianDayBegin);
    let tempEndDay: number = Math.max(...originList.map((item: AgendaCardInfo) => item.mEndDay));
    // 取当前儒略日加6天,与原始数据取交集,共展示7天
    const endJulianDay: number = julianDayBegin + 6;
    tempEndDay = Math.min(tempEndDay, endJulianDay);
    Log.warn(TAG, `groupAgendaByDay julianDayBegin= ${julianDayBegin}, startJulianDay= ${startJulianDay}, endDay= ${tempEndDay}`);
    for (let day = startJulianDay; day <= tempEndDay; day++) {
      const oneDayList: AgendaCardInfo[] = [];
      for (let item of originList) {
        if ((item.mStartDay > day) || (item.mEndDay < day)) {
          continue;
        }

        const info: AgendaCardInfo = new AgendaCardInfo(item);
        info.mDay = day;
        info.mFlag = AgendaCardInfo.FLAG_MID;
        const startOfDay: number = DateUtil.julianDay2Date(day).getTime();
        const endOfDay: number = startOfDay + MILLS_PER_DAY;
        const beginInDay: boolean = info.mBegin >= startOfDay && info.mBegin <= endOfDay;
        const endInDay: boolean = info.mEnd >= startOfDay && info.mEnd <= endOfDay;
        if (beginInDay && endInDay) {
          info.mFlag = AgendaCardInfo.FLAG_MID;
        } else if (beginInDay) {
          info.mFlag = AgendaCardInfo.FLAG_START;
        } else if (endInDay) {
          info.mFlag = AgendaCardInfo.FLAG_END;
        }
        oneDayList.push(info);
      }

      FormUtils.agendaListSort(oneDayList, allDayOnTop);

      for (const item of oneDayList) {
        res.push(item);
      }
    }
    return res;
  }

  /**
   * 日程排序（根据开始结束时间及是否全天日程排序）
   * @param list
   * @param allDayOnTop 全天日程是否置顶，若为false，则全天日程置底
   */
  static agendaListSort(list: AgendaCardInfo[], allDayOnTop: boolean = true): AgendaCardInfo[] {
    if (!list || list.length === 0) {
      Log.warn(TAG, `agendaListSort list is empty`);
      return [];
    }
    const getTitle = (item: AgendaCardInfo): string => {
      return item.mTitle ?? '';
    };
    return list.sort((a: AgendaCardInfo, b: AgendaCardInfo) => {
      // 1.如果都是全天日程
      if (a.mIsAllDay && b.mIsAllDay) {
        return getTitle(a).localeCompare(getTitle(b));
      }
      // 2.如果其一是全天日程，根据allDayOnTop判断排序
      if (a.mIsAllDay) {
        return allDayOnTop ? -1 : 1;
      }
      if (b.mIsAllDay) {
        return allDayOnTop ? 1 : -1;
      }
      // 3.如果都是普通日程
      if (a.mBegin !== b.mBegin) {
        return a.mBegin - b.mBegin;
      }
      if (a.mEnd !== b.mEnd) {
        return a.mEnd - b.mEnd;
      }
      return getTitle(a).localeCompare(getTitle(b));
    });
  }

  /**
   * 按天对日程分组
   * @param originList 待分组日程项
   */
  static groupAgendaByDayAll(
    originList: AgendaCardInfo[],
    julianDayOfNow: number
  ): AgendaCardInfo[] {
    const res: AgendaCardInfo[] = [];
    const tempStartDay: number = Math.min(...originList.map((item: AgendaCardInfo) => item.mStartDay));
    const tempEndDay: number = Math.max(...originList.map((item: AgendaCardInfo) => item.mEndDay));
    // 获取当天的儒略日 然后+6 -6
    const startJulianDay = julianDayOfNow - 6;
    const endJulianDay = julianDayOfNow + 6;
    const startDay: number = Math.max(tempStartDay, startJulianDay);
    const endDay: number = Math.min(tempEndDay, endJulianDay);
    Log.warn(TAG, `groupAgendaByDayAll julianDay= ${julianDayOfNow}, startDay= ${startDay}, endDay= ${endDay}`);
    for (let day = startDay; day <= endDay; day++) {
      const oneDayList: AgendaCardInfo[] = [];
      for (let item of originList) {
        if ((item.mStartDay > day) || (item.mEndDay < day)) {
          continue;
        }

        const info: AgendaCardInfo = new AgendaCardInfo(item);
        info.mDay = day;
        info.mFlag = AgendaCardInfo.FLAG_MID;
        const startOfDay: number = FormUtils.julianDay2Date(day).getTime();
        const endOfDay: number = startOfDay + MILLS_PER_DAY;
        const beginInDay: boolean = info.mBegin >= startOfDay && info.mBegin <= endOfDay;
        const endInDay: boolean = info.mEnd >= startOfDay && info.mEnd <= endOfDay;
        if (beginInDay && endInDay) {
          info.mFlag = AgendaCardInfo.FLAG_MID;
        } else if (beginInDay) {
          info.mFlag = AgendaCardInfo.FLAG_START;
        } else if (endInDay) {
          info.mFlag = AgendaCardInfo.FLAG_END;
        }
        oneDayList.push(info);
      }

      FormUtils.agendaListSort(oneDayList)
      for (const item of oneDayList) {
        res.push(item);
      }
    }
    return res;
  }

  /**
   * 对比刷新数据   相同true  不同 false
   *
   * @param agendaListOld 旧数据
   * @param agendaListNew 新数据
   * @param dateOld 旧日期
   * @param dateNew 新日期
   * @returns 结果
   */
  static compareDataArray(agendaListOld: AgendaCardInfo[], agendaListNew: AgendaCardInfo[],
                          dateTimeOld: CalendarDate | undefined, dateTimeNew: CalendarDate,
                          isNeedValidMeeting: boolean = true): boolean {
    if (!dateTimeOld) {
      return false;
    }
    const dateOld = dateTimeOld.getJulianDay();
    const dateNew = dateTimeNew.getJulianDay();
    if ((dateOld != dateNew) || (agendaListOld?.length != agendaListNew?.length)) {
      return false;
    }
    if (agendaListNew?.length == 0) {
      return false;
    }
    // 创建一个 Map 来存储新日程的 eventId 到对象的映射
    const newAgendaMap = new Map<number, AgendaCardInfo>();
    agendaListNew.forEach(agenda => {
      newAgendaMap.set(agenda.mEventId, agenda);
    });
    // 遍历旧日程，检查每个日程是否存在且匹配
    for (let i = 0; i < agendaListOld.length; i++) {
      const oldAgenda = agendaListOld[i];
      const newAgenda = newAgendaMap.get(oldAgenda.mEventId);
      if (!newAgenda || !FormUtils.compareData(oldAgenda, newAgenda)) {
        return false;
      }
    }
    if (isNeedValidMeeting) {
      // 会议前十分需要显示加入会议逻辑判定
      for (let i = 0; i < agendaListNew.length; i++) {
        // true 表示会议日程需要重刷新
        if (FormUtils.compareMeetingAgenda(agendaListNew[i], dateTimeNew)) {
          return false;
        }
      }
    }
    return true;
  }

  /**
   * 按天日程转化为所有日程列表
   *
   * @param agendaGroupList 按天日程
   * @returns agendaObjList 日程列表
   */
  static agendaGroupList2agendaObjList(agendaGroupList: AgendaCardGroup[]): AgendaCardInfo[] {
    return agendaGroupList.reduce((a: AgendaCardInfo[], c) => a.concat(c.items), []);
  }

  static compareMeetingAgenda(agenda: AgendaCardInfo, dateTimeNew: CalendarDate): boolean {
    // 会议中
    if (agenda.isOnlineMeeting()) {
      return true;
    }

    // 此刻时间点在会议开始15分钟以内
    const tenMinutesAgo = agenda.mBegin - MILLS_PER_MINUTE * 15;
    return (dateTimeNew.getTime() > tenMinutesAgo) && dateTimeNew.getTime() <= agenda.mBegin;
  }

  static compareData(agendaOld: AgendaCardInfo, agendaNew: AgendaCardInfo): boolean {
    return (agendaOld.mEventId == agendaNew.mEventId) &&
      (agendaOld.mCalendarId == agendaNew.mCalendarId) &&
      (agendaOld.mDisplayColor == agendaNew.mDisplayColor) &&
      (agendaOld.mTitle == agendaNew.mTitle) &&
      (agendaOld.mLocation == agendaNew.mLocation) &&
      (agendaOld.mDescription == agendaNew.mDescription) &&
      (agendaOld.mStartDay == agendaNew.mStartDay) &&
      (agendaOld.mEndDay == agendaNew.mEndDay) &&
      (agendaOld.mIsMultiDayEvent == agendaNew.mIsMultiDayEvent) &&
      (agendaOld.mBegin == agendaNew.mBegin) &&
      (agendaOld.mEnd == agendaNew.mEnd) &&
      (agendaOld.mIsAllDay == agendaNew.mIsAllDay) &&
      (agendaOld.mHwextServiceType == agendaNew.mHwextServiceType) &&
      (agendaOld.mHwextServiceVerified == agendaNew.mHwextServiceVerified) &&
      (agendaOld.mHwextServiceUri == agendaNew.mHwextServiceUri) &&
      (agendaOld.mAttachmentCount == agendaNew.mAttachmentCount);
  }
}

export class Want {
  public bundleName?: string;
  public abilityName?: string;
  public deviceId?: string;
  public uri?: string;
  public type?: string;
  public flags?: number;
  public action?: string;
  public parameters?: Record<string, Object>
  public entities?: Array<string>;
  public moduleName?: string;
}

/**
 * 一键服务按钮类型
 */
export enum OneKeyServiceButtonType {
  LARGE,

  SMALL,
}

/**
 * 2*2卡片类型   卡片展示 0 -- 日程数量为空   1 -- 日程数量为1   2 -- 存在多个日程  3 -- 当前有正在进行的会议日程
 */
export enum AgendaFormType2x2 {
  NO_SCHEDULE,

  ONE_SCHEDULE,

  MULTI_SCHEDULE,

  MEETING_SCHEDULE
}