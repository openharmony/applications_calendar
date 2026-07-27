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

import { CalendarContract } from '../default/calendar/CalendarContract';
import { CornerType } from './CornerType';
import { DateUtil, MILLS_PER_DAY, MILLS_PER_MINUTE } from '../util/DateUtil';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import { MINUTES_BEFORE_MEETING, SERVICE_TYPE_MAP } from './Constants';
import { I18nUtil } from '../util/I18nUtil';
import { DataShareResultUtil } from '../dao/util/DataShareResultSetUtil';
import { InnerResultSet } from '../dao/util/InnerResultSet';
import { AgendaUtil } from './AgendaUtil';
import { NotifyHandlerEnum } from './share/ShareEnum';
import { EmptyUtils } from '../util/EmptyUtils';
import { CalendarDate } from '../date/CalendarDate';
import { AccountUtils } from '../account/AccountUtils';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'AgendaEventInfo';

/**
 * Event bean. DayFormAbility 中无法导入 feature中的包，临时放在 common 层
 *
 * @since 2022-09-01
 */
export class AgendaEventInfo {
  public static FLAG_START: number = 0;
  public static FLAG_MID: number = 1;
  public static FLAG_END: number = 2;
  public mId: number = 0;
  public mCalendarId: number = 0;
  public mCalendarUuid: string = '';
  public mTitle: string = '';
  public mLocation: string = '';
  public mDescription: string = '';
  public mStartDay: number = 0;
  public mEndDay: number = 0;
  public rDate: string = '';
  public exRule: string = '';
  public exDate: string = '';
  public lastDate: number = 0;
  public eventTimeZone: string = ''; // 日程时区
  public accessLevel: number = 0;
  public hasAlarm: string = '';
  public status: string = '';
  public alertType: number = 0;
  public duration: string = '';
  public imageType: string = '';
  public mFlag: number = 0;
  public mDisplayColor: number = 0;
  public mDay: number = 0;
  public mEventType: number = 0;
  public mBegin: number = 0;
  public mEnd: number = 0;
  // 重要日挪移计算Instances时，需要记录其原始的日程开始结束时间，其他场景无需关注此值
  public mOriginalBegin: number = 0;
  public mOriginalEnd: number = 0;
  public mIsAllDay: boolean = false;
  public mIsMultiDayEvent: boolean = false;
  public mIsSetDayHead: boolean = false;
  public mEventCalendar: number = 0;
  public mEventImageType: string = '';
  public mIsCanceled: boolean = false;
  public mSelfAttendeeStatus: boolean = false;
  public mIsMeetingEvent: boolean = false;
  public mPosition: number = 0;
  public mRepeatRule: string = '';
  public mEventTimeStamp: number = 0;
  public mImportantEventType: number = 0;
  public mHwextServiceType: string = '';
  public mHwextServiceVerified: boolean = false;
  public mHwextServiceUri: string = '';
  public mHwextServicePkgName: string = '';
  public mHwextServiceMinVersion: string = '';
  public mHwextServiceDescription: string = '';
  public mCornerType: number = 0;
  public checkValuesArray: CalendarContract.Reminders[] = [];
  public mAttendeeList: Array<CalendarContract.Attendees> = [];
  public mIsHoliday?: boolean;
  // 是否为 共享日程
  public isShareAgenda = false;
  // 是否是来自消息的资源
  public isMessageResource = false;
  // 是否是发起者
  public isShareAgendaInitiator = false;
  public uuid: string = '';
  // 日程唯一标识，三方写入可指定
  public identifier: string = '';
  // 是否冲突
  public isConflict: boolean = false;
  // 判断是否是联系人生日日程, 是在accounts中获取到的, 不是直接从数据库里获取到的, 当前仅在穿戴业务使用.
  public isBirthDay: boolean = false;
  // 迁移旧的eventId
  public oldEventId: number = 0;
  // event表的dtStart
  public eventStart: number = 0;
  // 用户操作状态(共享日程当前用户为受邀者时)，0拒绝 1待定 2接受
  public userHandler: NotifyHandlerEnum = NotifyHandlerEnum.DEFAULT;
  // event纬度
  public mLatitude: number = -1;
  public mLatitudeStr: string = '';
  // event经度
  public mLongitude: number = -1;
  public mLongitudeStr: string = '';

  // event附件数量
  public mAttachmentCount: number = 0;

  // event语言资源
  public mLanguageResources: string = '';
  public mLanguageRecord: Record<string, string> = {};

  public mCreator: string = '';

  constructor(sourceData?: AgendaEventInfo) {
    if (sourceData == null) {
      return;
    }
    this.mId = sourceData.mId;
    this.mCalendarUuid = sourceData.mCalendarUuid;
    this.mCalendarId = sourceData.mCalendarId;
    this.mTitle = sourceData.mTitle;
    this.mLocation = AgendaUtil.getLocation(sourceData.mLocation);
    this.mDescription = sourceData.mDescription;
    this.mStartDay = sourceData.mStartDay;
    this.mEndDay = sourceData.mEndDay;
    this.rDate = sourceData.rDate;
    this.exRule = sourceData.exRule;
    this.exDate = sourceData.exDate;
    this.lastDate = sourceData.lastDate;
    this.eventTimeZone = sourceData.eventTimeZone;
    this.accessLevel = sourceData.accessLevel;
    this.hasAlarm = sourceData.hasAlarm;
    this.status = sourceData.status;
    this.alertType = sourceData.alertType;
    this.duration = sourceData.duration;
    this.imageType = sourceData.imageType;
    this.mFlag = sourceData.mFlag;
    this.mDisplayColor = sourceData.mDisplayColor;
    this.mDay = sourceData.mDay;
    this.mEventType = sourceData.mEventType;
    this.mBegin = sourceData.mBegin;
    this.mEnd = sourceData.mEnd;
    this.mOriginalBegin = sourceData.mOriginalBegin;
    this.mOriginalEnd = sourceData.mOriginalEnd;
    this.mIsAllDay = sourceData.mIsAllDay;
    this.mIsMultiDayEvent = sourceData.mIsMultiDayEvent;
    this.mIsSetDayHead = sourceData.mIsSetDayHead;
    this.mEventCalendar = sourceData.mEventCalendar;
    this.mEventImageType = sourceData.mEventImageType;
    this.mIsCanceled = sourceData.mIsCanceled;
    this.mSelfAttendeeStatus = sourceData.mSelfAttendeeStatus;
    this.mIsMeetingEvent = sourceData.mIsMeetingEvent;
    this.mPosition = sourceData.mPosition;
    this.mRepeatRule = sourceData.mRepeatRule;
    this.mEventTimeStamp = sourceData.mEventTimeStamp;
    this.mImportantEventType = sourceData.mImportantEventType;
    this.mHwextServiceType = sourceData.mHwextServiceType;
    this.mHwextServiceVerified = sourceData.mHwextServiceVerified;
    this.mHwextServiceUri = sourceData.mHwextServiceUri;
    this.mHwextServicePkgName = sourceData.mHwextServicePkgName;
    this.mHwextServiceMinVersion = sourceData.mHwextServiceMinVersion;
    this.mHwextServiceDescription = sourceData.mHwextServiceDescription;
    this.mCornerType = sourceData.mCornerType;
    this.checkValuesArray = sourceData.checkValuesArray;
    this.mAttendeeList = sourceData.mAttendeeList;
    this.mIsHoliday = sourceData.mIsHoliday;
    this.isShareAgenda = sourceData.isShareAgenda;
    this.isMessageResource = sourceData.isMessageResource;
    this.isShareAgendaInitiator = sourceData.isShareAgendaInitiator;
    this.uuid = sourceData.uuid; // event_UUID
    this.identifier = sourceData.identifier;
    this.isConflict = sourceData.isConflict;
    this.isBirthDay = sourceData.isBirthDay;
    this.oldEventId = sourceData.oldEventId;
    this.eventStart = sourceData.eventStart;
    this.userHandler = sourceData.userHandler;
    this.mLatitude = sourceData.mLatitude;
    this.mLatitudeStr = sourceData.mLatitudeStr;
    this.mLongitude = sourceData.mLongitude;
    this.mLongitudeStr = sourceData.mLongitudeStr;
    this.mCreator = sourceData.mCreator;
    this.mAttachmentCount = sourceData.mAttachmentCount;
    this.mLanguageResources = sourceData.mLanguageResources;
  }

  public static buildEventInfo(ds: InnerResultSet) {
    try {
      const eventInfo: AgendaEventInfo = new AgendaEventInfo();
      eventInfo.mId = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.ID, 0);

      eventInfo.mBegin = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.DTSTART, 0);

      eventInfo.mEnd = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.DTEND, 0);

      eventInfo.mOriginalBegin = eventInfo.mBegin;

      eventInfo.mOriginalEnd = eventInfo.mEnd;

      eventInfo.mTitle = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.TITLE, '');

      eventInfo.mLocation =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.EVENT_LOCATION, '');

      eventInfo.mDescription =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.DESCRIPTION, '');

      eventInfo.mHwextServiceDescription =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.SERVICE_DESCRIPTION, '');

      eventInfo.mDisplayColor = -12213274;
      eventInfo.mSelfAttendeeStatus =
        DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.OWNER_ATTENDEE_STATUS, 0) === 1;

      eventInfo.mCalendarUuid =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.CALENDAR_UUID, '');

      eventInfo.mCalendarId = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.CALENDAR_ID, 0);

      eventInfo.mIsAllDay = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.ALL_DAY, 0) === 1;

      eventInfo.mCornerType = CornerType.CORNER_NONE;

      eventInfo.mRepeatRule = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.RRULE, '');

      eventInfo.eventTimeZone =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.START_TIMEZONE, '');

      eventInfo.mCreator =
        DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.CREATOR, '');

      AgendaEventInfo.buildEventInfoSub(eventInfo, ds);
      return eventInfo;
    } catch (error) {
      Log.logErrorMsg(TAG, 'buildEventInfo', error);
      throw new Error(error);
    }
  }

  private static buildEventInfoSub(eventInfo: AgendaEventInfo, ds: InnerResultSet) {
    eventInfo.accessLevel =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.PERMISSION_LEVEL, 0);

    eventInfo.hasAlarm = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.HAS_ALARM, '');

    eventInfo.lastDate = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.LAST_DATE, 0);

    eventInfo.duration = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.DURATION, '');

    eventInfo.status = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.EVENT_STATUS, '');

    eventInfo.imageType =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.EVENT_IMAGE_TYPE, '');

    eventInfo.alertType =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE, 0);

    eventInfo.mEventCalendar =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE, 0);

    eventInfo.mEventTimeStamp =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.EVENT_TIME_STAMP, 0);

    eventInfo.mImportantEventType =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE, 0);

    eventInfo.mHwextServiceUri =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.SERVICE_CP_BZ_URI, '');

    // 0 1 2 2显示
    eventInfo.mHwextServiceVerified =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.SERVICE_VERIFIED, 0) === 2;
    AgendaEventInfo.buildEventInfoDateSub(ds, eventInfo);
  }

  private static buildEventInfoDateSub(ds: InnerResultSet, eventInfo: AgendaEventInfo) {
    eventInfo.mHwextServiceType =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.SERVICE_TYPE, '');

    eventInfo.uuid = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.UUID, '');

    eventInfo.rDate = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.RDATE, '');

    eventInfo.exRule = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.EXRULE, '');

    eventInfo.exDate = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.EXDATE, '');

    eventInfo.identifier = DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.IDENTIFIER, '');

    eventInfo.oldEventId = DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.OLD_EVENT_ID, 0);

    eventInfo.mLatitudeStr =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.LOCATION_LATITUDE, '');
    eventInfo.mLongitudeStr =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.LOCATION_LONGITUDE, '');
    eventInfo.mAttachmentCount =
      DataShareResultUtil.getColumnLongData(ds, CalendarContract.EventsColumns.ATTACHMENT_COUNT, 0);
    eventInfo.mLanguageResources =
      DataShareResultUtil.getColumnStringData(ds, CalendarContract.EventsColumns.LANGUAGE_RESOURCES, '');
    eventInfo.setHolidayTile();
  }

  /**
   * 对传入的经纬度进行校验并返回
   *
   * @param location: 地址经纬度数据
   * @return 如果传入的经纬度为空或不能转为数字则返回-1，否则返回number
   */
  public static getLocation(location: string): number {
    const invalidLocation: number = -1;
    if (EmptyUtils.isNotOrEmptyString(location, true)) {
      return invalidLocation;
    }
    let locationNum: number = Number(location);
    return isNaN(locationNum) ? invalidLocation : locationNum;
  }

  parseFromCursor(cursor: InnerResultSet) {
    this.mId = DataShareResultUtil.getColumnLongData(cursor, 'event_id', 0);
    this.mBegin = DataShareResultUtil.getColumnLongData(cursor, 'begin', 0);
    this.mEnd = DataShareResultUtil.getColumnLongData(cursor, 'end', 0);
    this.mOriginalBegin = this.mBegin;
    this.mOriginalEnd = this.mEnd;
    this.mStartDay = DataShareResultUtil.getColumnLongData(cursor, 'startDay', 0);
    this.mEndDay = DataShareResultUtil.getColumnLongData(cursor, 'endDay', 0);
    this.mTitle = DataShareResultUtil.getColumnStringData(cursor, 'title', '');
    this.mLocation = DataShareResultUtil.getColumnStringData(cursor, 'eventLocation', '');
    this.mDescription = DataShareResultUtil.getColumnStringData(cursor, 'description', '');
    this.mEventImageType = DataShareResultUtil.getColumnStringData(cursor, 'event_image_type', '');
    this.mSelfAttendeeStatus = DataShareResultUtil.getColumnLongData(cursor, 'selfAttendeeStatus', 0) === 1;
    this.mDisplayColor = -12213274;
    this.mCalendarUuid = DataShareResultUtil.getColumnStringData(cursor, 'calendar_uuid', '');
    this.mCalendarId = DataShareResultUtil.getColumnLongData(cursor, 'calendar_id', 0);
    this.mIsMultiDayEvent = this.mStartDay !== this.mEndDay;
    this.mIsAllDay = DataShareResultUtil.getColumnLongData(cursor, 'allDay', 0) === 1;
    this.mCornerType = CornerType.CORNER_NONE;
    this.mRepeatRule = DataShareResultUtil.getColumnStringData(cursor, 'rrule', '');
    this.identifier = DataShareResultUtil.getColumnStringData(cursor, 'identifier', '');
    this.mEventTimeStamp =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.EVENT_TIME_STAMP, 0);

    this.mImportantEventType =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE, 0);

    this.mHwextServiceUri =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.SERVICE_CP_BZ_URI, '');

    this.mHwextServiceVerified =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.SERVICE_VERIFIED, 0) === 2;

    this.mHwextServiceType =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.SERVICE_TYPE, '');

    this.eventTimeZone =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.START_TIMEZONE, '');

    this.mCreator = DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.CREATOR, '');

    this.eventStart =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.DTSTART, 0);

    this.uuid = DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.UUID, '');

    this.alertType = cursor.getLong(cursor.getColumnIndex(CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE));
    let index = cursor.getColumnIndex(CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE);
    if (index >= 0) {
      this.mEventCalendar = cursor.getLong(cursor.getColumnIndex(CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE));
    }
    this.mAttachmentCount =
      DataShareResultUtil.getColumnLongData(cursor, CalendarContract.EventsColumns.ATTACHMENT_COUNT, 0);
    this.mLanguageResources =
      DataShareResultUtil.getColumnStringData(cursor, CalendarContract.EventsColumns.LANGUAGE_RESOURCES, '');
    this.setHolidayTile();
  }

  setFlag(day: number) {
    this.mDay = day;
    this.mFlag = AgendaEventInfo.FLAG_MID;

    const startOfDay: number = DateUtil.julianDay2Date(day).getTime();
    const endOfDay: number = startOfDay + MILLS_PER_DAY;
    const beginInDay: boolean = this.mBegin >= startOfDay && this.mBegin <= endOfDay;
    const endInDay: boolean = this.mEnd >= startOfDay && this.mEnd <= endOfDay;

    if (beginInDay && endInDay) {
      this.mFlag = AgendaEventInfo.FLAG_MID;
    } else if (beginInDay) {
      this.mFlag = AgendaEventInfo.FLAG_START;
    } else if (endInDay) {
      this.mFlag = AgendaEventInfo.FLAG_END;
    }
  }

  isOnlineMeeting(): boolean {
    const serviceType = GlobalThis.getInstance().serviceType;

    if (!this.mHwextServiceVerified) {
      return false;
    }
    return serviceType.includes(this.mHwextServiceType)
  }

  getOneKeyServiceBtnStr(): Resource {
    return SERVICE_TYPE_MAP.get(this.mHwextServiceType) || $r('app.string.join_the_meeting');
  }

  isOutDate(): boolean {
    return Date.now() >= this.mEnd;
  }

  isOneKeyService(): boolean {
    if (!this.mHwextServiceVerified) {
      return false;
    }

    if (SERVICE_TYPE_MAP.has(this.mHwextServiceType)) {
      return true;
    }

    return false;
  }

  canShowOneKeyService(): boolean {
    if (!this.mHwextServiceVerified) {
      return false;
    }

    if (SERVICE_TYPE_MAP.has(this.mHwextServiceType)) {
      if (this.mIsAllDay) { // 全天日程通过儒略日进行比较
        const nowDay = DateUtil.getJulianDay();
        // 因当前存在跨天日程分组后中间日程被设为全天日程的情况,故通过儒略日进行计算
        return this.mStartDay <= nowDay && this.mEndDay >= nowDay;
      }

      // 开会前15分钟可见一键入会按钮
      const startTime: number = this.mBegin - MILLS_PER_MINUTE * MINUTES_BEFORE_MEETING;

      return !this.isOutDate() && (Date.now() >= startTime);
    }

    return false;
  }

  getEditAblePropStr(): string {
    // id 保证数据唯一性 其它属性保证编辑相关后可触发日程列表刷新
    return `${this.mId}-${this.mDay}-${this.mTitle}-${this.mOriginalBegin}-${this.mBegin}-
    ${this.mEnd}-${this.mLocation}-${this.mDisplayColor}-${this.mIsSetDayHead}-
    ${this.alertType}-${this.mRepeatRule}-${this.mDescription}-${this.mEventCalendar}-${this.isConflict}-
    ${this.uuid}-${this.mAttachmentCount === 0}`;
  }

  public isValid(): boolean {
    return this.mId > 0 && this.mCalendarId > 0;
  }

  public isImportantEvent(): boolean {
    return this.isImportantAnniversaries() || this.isImportantCountDown();
  }

  public isRepeatEvent(): boolean {
    if (this.mRepeatRule) {
      return this.mRepeatRule.length > 0;
    }
    return false;
  }

  /**
   * 是否农历日程
   *
   * @returns true 农历 false 阳历
   */
  public isLunarEvent(): boolean {
    return this.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR;
  }

  public isImportantAnniversaries() {
    return this.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES;
  }

  public isImportantCountDown() {
    return this.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
  }

  public isHoliday(): boolean {
    return this.mTitle != '' &&
      (this.mIsHoliday || this.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY)
  }

  // 是否联系人生日日程
  public isContactBirthday(): boolean {
    let isBirthDay = AccountUtils.isBirthDayAccountById(this.mCalendarId);
    return this.mTitle != '' && isBirthDay;
  }

  getAccessibilityText(): string {
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
    };

    let timeOption: DateTimeOptions = {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !I18nUtil.is24HourClock()
    };
    let beginDate: CalendarDate = new CalendarDate(this.mBegin);
    let endDate: CalendarDate = new CalendarDate(this.mEnd);
    let yearMonth = DateUtil.intlDateFormat(beginDate, dateOption);

    let top = '';
    let bottom = '';
    let sep = '';
    if (this.mIsAllDay || (this.mIsMultiDayEvent && this.mFlag === AgendaEventInfo.FLAG_MID)) {
      top = GlobalThis.getResourceStr($r('app.string.all_day'));
    } else if (this.mIsMultiDayEvent && this.mFlag === AgendaEventInfo.FLAG_START) {
      top = DateUtil.intlDateFormatChineseStyle(beginDate, timeOption);
      bottom = GlobalThis.getResourceStr($r('app.string.start_date'))
    } else if (this.mIsMultiDayEvent && this.mFlag === AgendaEventInfo.FLAG_END) {
      top = DateUtil.intlDateFormatChineseStyle(endDate, timeOption);
      bottom = GlobalThis.getResourceStr($r('app.string.end_date'));
    } else {
      top = DateUtil.intlDateFormatChineseStyle(beginDate, timeOption);
      bottom = DateUtil.intlDateFormatChineseStyle(endDate, timeOption);
      sep = '至';
    }
    let title = AgendaUtil.filterEmLabel(this.mTitle);
    title = title ? title : GlobalThis.getResourceStr($r('app.string.no_title_label'));
    return yearMonth + top + sep + bottom + ',' + title + ',' + this.mLocation;
  }

  // instance实例是否是第一个重复的日程
  public isFirstRepeatAgenda() {
    return this.isRepeatEvent() && this.mBegin === this.mOriginalBegin;
  }

  public hashcode() {
    return `${this.mBegin}:${this.mEnd}:${this.mCalendarId}:${this.mTitle}` +
      `:${this.mLocation}:${this.mImportantEventType}:${this.mIsAllDay}`;
  }

  /**
   * 判断日程是否是重复日程的第一个
   * @param event 重复日程
   * @param instanceStartMill 重复日程实例的时间
   * @returns
   */
  public static isFirstRepeatAgenda(event: AgendaEventInfo, instanceStartMill: number): boolean {
    if (!event.isRepeatEvent()) {
      return false;
    }
    return event.mBegin === instanceStartMill;
  }


  /**
   * 深克隆用
   * @param oldAgendaEventInfo
   * @returns
   */
  public static deepCloneAgendaEventInfo(oldAgendaEventInfo: AgendaEventInfo): AgendaEventInfo {
    let newAgendaEventInfo = new AgendaEventInfo(oldAgendaEventInfo);
    newAgendaEventInfo.checkValuesArray = AgendaEventInfo.deepCloneReminders(oldAgendaEventInfo.checkValuesArray);
    newAgendaEventInfo.mAttendeeList = AgendaEventInfo.deepCloneAttendees(oldAgendaEventInfo.mAttendeeList);
    return newAgendaEventInfo;
  }

  static batchDeepCloneAgenda(oldList: AgendaEventInfo[]): AgendaEventInfo[] {
    const resultList: AgendaEventInfo[] = [];
    if (!oldList || oldList.length === 0) {
      return resultList;
    }
    oldList.forEach((oldItem: AgendaEventInfo) => {
      const newItem: AgendaEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(oldItem);
      resultList.push(newItem);
    });
    return resultList;
  }

  static deepCloneReminders(oldCheckValuesArray: CalendarContract.Reminders[]): CalendarContract.Reminders[] {
    let newCheckValuesArray: CalendarContract.Reminders[] = [];
    oldCheckValuesArray.forEach((oldCheckValues: CalendarContract.Reminders) => {
      let newCheckValues: CalendarContract.Reminders = new CalendarContract.Reminders();
      newCheckValues.eventId = oldCheckValues.eventId;
      newCheckValues.remindMinutes = oldCheckValues.remindMinutes;
      newCheckValues.remindType = oldCheckValues.remindType;
      newCheckValues.syncId = oldCheckValues.syncId;
      newCheckValues.id = oldCheckValues.id;
      newCheckValuesArray.push(newCheckValues);
    })
    return newCheckValuesArray;
  }

  static deepCloneAttendees(oldCheckValuesArray: CalendarContract.Attendees[]): CalendarContract.Attendees[] {
    let newCheckValuesArray: CalendarContract.Attendees[] = [];
    oldCheckValuesArray.forEach((oldCheckValues: CalendarContract.Attendees) => {
      let newCheckValues: CalendarContract.Attendees = new CalendarContract.Attendees();
      newCheckValues.eventId = oldCheckValues.eventId;
      newCheckValues.attendeeName = oldCheckValues.attendeeName;
      newCheckValues.attendeeEmail = oldCheckValues.attendeeEmail;
      newCheckValues.attendeeIdNamespace = oldCheckValues.attendeeIdNamespace;
      newCheckValues.attendeeIdentity = oldCheckValues.attendeeIdentity;
      newCheckValues.attendeeRelationship = oldCheckValues.attendeeRelationship;
      newCheckValues.attendeeStatus = oldCheckValues.attendeeStatus;
      newCheckValues.attendeeType = oldCheckValues.attendeeType;
      newCheckValuesArray.push(newCheckValues);
    })
    return newCheckValuesArray;
  }

  // 是否支持分享
  isSupportShare(): boolean {
    return !this.isHoliday() && !this.isContactBirthday();
  }

  setHolidayTile() {
    try {
      if (EmptyUtils.isNotOrEmptyString(this.mLanguageResources)) {
        return;
      }
      this.mLanguageRecord = JSON.parse(this.mLanguageResources);
      if (EmptyUtils.isEmptyArray(this.mLanguageRecord)) {
        Log.warn(TAG, 'setHolidayTile mLanguageRecord is empty');
        return;
      }
      // 优先获取对应语言下面的，没有就获取默认语言下的
      let holidayName = this.mLanguageRecord[this.parseLanguage()];
      if (EmptyUtils.isNotOrEmptyString(holidayName)) {
        holidayName = this.mLanguageRecord['default'];
        if (EmptyUtils.isNotEmptyString(holidayName)) {
          this.mTitle = holidayName;
        }
        return;
      }
      this.mTitle = holidayName;
    } catch (err) {
      Log.logErrorMsg(TAG, 'setHolidayTile', err);
    }
  }

  private parseLanguage(language?: string | undefined): string {
    if (!language) {
      language = i18n.System.getSystemLanguage();
    }
    const languageList = language.split('-');
    if (languageList.length > 0) {
      language = languageList[0];
    }
    return language.toUpperCase();
  }
}