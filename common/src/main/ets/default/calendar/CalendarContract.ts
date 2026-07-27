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

import { InnerResultSet } from '../../dao/util/InnerResultSet';
import { Log } from '../common/Log';

// 数据库resultset转换，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG = 'CalendarContract';

/**
 * Contains variety of calendar functions for manager calendar provider data, such as query insert delete and update,
 * and some contract constants.
 */

export namespace CalendarContract {
  /**
   * Calendar table base attributes.
   *
   */
  export enum BaseColumns {
    /**
     * Indicates the total number of fields.
     */
    COUNT = '_count',

    /**
     * Indicates the calendar ID.
     */
    ID = '_id'
  }

  /**
   * Calendar Account table attributes.
   *
   */
  export enum AccountColumns {
    /**
     * Indicates the account ID.
     */
    ID = '_id',

    /**
     * Application name written by three parties
     */
    NAME = 'name',

    /**
     * Indicates the account name.
     *
     */
    ACCOUNT_NAME = 'account_name',

    /**
     * Indicates the account type.
     *
     */
    ACCOUNT_TYPE = 'account_type',

    /**
     * Indicates the calendar color.
     */
    CALENDAR_COLOR = 'calendar_color',

    /**
     * Indicates the calendar color index.
     */
    CALENDAR_COLOR_INDEX = 'calendar_color_index',

    /**
     * Indicates the display name of the calendar account.
     */
    CALENDAR_DISPLAY_NAME = 'calendar_displayName',

    /**
     * Specifies whether events associated with the calendar are visible.
     */
    VISIBLE = 'visible',

    /**
     * Indicates the time location.
     */
    CALENDAR_LOCATION = 'calendar_location',

    /**
     * Indicates the time zone.
     */
    CALENDAR_TIMEZONE = 'calendar_timezone',

    /**
     * Specifies whether the event is a synchronized event.
     */
    SYNC_EVENTS = 'sync_events',

    /**
     * Account owner
     */
    OWNER_ACCOUNT = 'ownerAccount',

    /**
     * Indicates the reminder type.
     */
    ALLOWED_REMINDERS = 'allowedReminders',

    /**
     * Specifies whether the calendar account is in the idle state.
     */
    ALLOWED_AVAILABILITY = 'allowedAvailability',

    /**
     * Indicates the participant type.
     */
    ATTENDEE_TYPES = 'allowedAttendeeTypes',

    /**
     * Specifies whether the calendar is the primary calendar of the account.
     */
    IS_PRIMARY = 'isPrimary',

    /**
     * Can the account be reminded
     */
    CAN_REMINDER = 'canReminder',

    /**
     * Account permissions
     */
    CALENDAR_ACCESS_LEVEL = 'calendar_access_level',

    /**
     * Account creator
     */
    CREATOR = 'creator',

    /**
     * UUID
     */
    UUID = 'uuid'
  }

  /**
   * Calendar Account table sync attributes.
   *
   */
  export enum AccountSyncColumns {
    /**
     * Indicates synchronization type 1.
     */
    CAL_SYNC1 = 'cal_sync1',

    /**
     * Indicates synchronization type 2.
     */
    CAL_SYNC2 = 'cal_sync2',

    /**
     * Indicates synchronization type 3.
     */
    CAL_SYNC3 = 'cal_sync3',

    /**
     * Indicates synchronization type 4.
     */
    CAL_SYNC4 = 'cal_sync4',

    /**
     * Indicates synchronization type 5.
     */
    CAL_SYNC5 = 'cal_sync5',

    /**
     * Indicates synchronization type 6.
     */
    CAL_SYNC6 = 'cal_sync6',

    /**
     * Indicates synchronization type 7.
     */
    CAL_SYNC7 = 'cal_sync7',

    /**
     * Indicates synchronization type 8.
     */
    CAL_SYNC8 = 'cal_sync8',

    /**
     * Indicates synchronization type 9.
     */
    CAL_SYNC9 = 'cal_sync9',

    /**
     * Indicates synchronization type 10.
     */
    CAL_SYNC10 = 'cal_sync10'
  }

  /**
   * Calendar Events table general attributes.
   *
   */
  export enum EventsColumns {
    /**
     * Indicates the agenda ID.
     */
    ID = '_id',

    /**
     * Indicates the account uuid.
     */
    CALENDAR_UUID = 'calendar_uuid',

    /**
     * Indicates the account ID.
     */
    CALENDAR_ID = 'calendar_id',

    /**
     * Indicates the title of the calendar event.
     */
    TITLE = 'title',

    /**
     * Indicates the event description.
     */
    DESCRIPTION = 'description',

    /**
     * Indicates the event position.
     */
    EVENT_LOCATION = 'eventLocation',

    /**
     * Indicates the event status.
     */
    EVENT_STATUS = 'eventStatus',

    /**
     * Indicates the owner state.
     */
    OWNER_ATTENDEE_STATUS = 'selfAttendeeStatus',

    /**
     * Indicates the synchronization data 1.
     */
    EXTEND_DATA1 = 'sync_data1',

    /**
     * Indicates the synchronization data 2.
     */
    EXTEND_DATA2 = 'sync_data2',

    /**
     * Indicates the synchronization data 3.
     */
    EXTEND_DATA3 = 'sync_data3',

    /**
     * Indicates the synchronization data 4.
     */
    EXTEND_DATA4 = 'sync_data4',

    /**
     * Indicates the synchronization data 5.
     */
    EXTEND_DATA5 = 'sync_data5',

    /**
     * Indicates the synchronization data 6.
     */
    EXTEND_DATA6 = 'sync_data6',

    /**
     * Indicates the synchronization data 7.
     */
    EXTEND_DATA7 = 'sync_data7',

    /**
     * Indicates the synchronization data 8.
     */
    EXTEND_DATA8 = 'sync_data8',

    /**
     * Indicates the synchronization data 9.
     */
    EXTEND_DATA9 = 'sync_data9',

    /**
     * Indicates the synchronization data 10.
     */
    EXTEND_DATA10 = 'sync_data10',

    /**
     * Indicates the start time of the event.
     */
    EVENT_START_TIME = 'dtstart',

    /**
     * Indicates the end time of the event.
     */
    EVENT_END_TIME = 'dtend',

    /**
     * Indicates the event duration.
     */
    DURATION = 'duration',

    /**
     * Indicates the start time zone.
     */
    START_TIMEZONE = 'eventTimezone',

    /**
     * Indicates the DTSTART.
     */
    DTSTART = 'dtstart',

    /**
     * Indicates the DTEND.
     */
    DTEND = 'dtend',

    /**
     * Indicates the LAST_DATE.
     */
    LAST_DATE = 'lastDate',

    /**
     * Indicates the end time zone.
     */
    END_TIMEZONE = 'eventEndTimezone',

    /**
     * Specifies whether the event is a whole-day event.
     */
    ALL_DAY = 'allDay',

    /**
     * Indicates the permission level.
     */
    PERMISSION_LEVEL = 'accessLevel',

    /**
     * Indicates the status of the person involved in the event.
     */
    AVAILABLE_STATUS = 'availability',

    /**
     * Specifies whether the alarm clock reminder is enabled.
     */
    HAS_ALARM = 'hasAlarm',

    /**
     * Specifies whether extended attributes are included.
     */
    HAS_EXTENDED_ATTRIBUTES = 'hasExtendedProperties',

    /**
     * Indicates the recurrence rule.
     */
    RRULE = 'rrule',

    /**
     * Indicates the interval at which the event repeats.
     */
    RDATE = 'rdate',

    /**
     * Indicates the exclude recurrence rule.
     */
    EXRULE = 'exrule',

    /**
     * Indicates the exclude dates for rule.
     */
    EXDATE = 'exdate',

    /**
     * Indicates the initial ID.
     */
    INITIAL_ID = 'original_id',

    /**
     * Indicates the initial synchronization ID.
     */
    INITIAL_SYNC_ID = 'original_sync_id',

    /**
     * Event timeStamp of updated
     */
    EVENT_TIME_STAMP = 'event_time_stamp',

    /**
     * Specifies whether participant information is included.
     */
    HAS_ATTENDEE_INFO = 'hasAttendeeData',

    /**
     * Indicates whether service uri legal.
     */
    SERVICE_VERIFIED = 'service_verified',

    /**
     * Indicates the service type of event.
     */
    SERVICE_TYPE = 'service_type',

    /**
     * Indicates the One click service uri passed in by applications.
     */
    SERVICE_CP_BZ_URI = 'service_cp_bz_uri',

    /**
     * Indicates the One click service uri for management passed in by applications.
     */
    SERVICE_CP_MNG_URI = 'service_cp_mng_uri',

    /**
     * Indicates the service description of event.
     */
    SERVICE_DESCRIPTION = 'service_description',

    /**
     * Indicates the Minimum version of one click service.
     */
    SERVICE_MIN_VERSION = 'service_support_min_version',

    /**
     * Indicates the important type.
     */
    IMPORTANT_EVENT_TYPE = 'important_event_type',

    /**
     * Indicates event_image_type.
     */
    EVENT_IMAGE_TYPE = 'event_image_type',

    /**
     * 农历日程或阳历
     */
    EVENT_CALENDAR_TYPE = 'event_calendar_type',

    /**
     * 提醒类型
     */
    HW_EXT_ALERT_TYPE = 'hwext_alert_type',

    /**
     * uuid
     */
    UUID = 'uuid',

    /**
     * 唯一标识符
     */
    IDENTIFIER = 'identifier',

    /**
     * 数据迁移旧的eventId
     */
    OLD_EVENT_ID = 'old_event_id',

    /**
     * event经度
     */
    LOCATION_LONGITUDE = 'location_longitude',

    /**
     * event纬度
     */
    LOCATION_LATITUDE = 'location_latitude',

    /**
     * event所属应用
     */
    CREATOR = 'creator',

    /**
     * event附件数量
     */
    ATTACHMENT_COUNT = 'attachment_count',

    /**
     * event语言资源
     */
    LANGUAGE_RESOURCES = 'language_resources',
  }

  /**
   * 重要日类型
   */
  export enum EventImportantStatus {
    /**
     * Indicates the tentative state.
     */
    EVENT_NORMAL = 0,

    /**
     * Indicates the confirmed state.
     */
    EVENT_STATUS_CONFIRMED = 1,

    /**
     * Indicates the canceled state.
     */
    EVENT_STATUS_CANCELED = 2
  }

  /**
   * Indicates event status classification.
   */
  export enum EventsEventStatus {
    /**
     * Indicates the tentative state.
     */
    EVENT_STATUS_TENTATIVE = 0,

    /**
     * Indicates the confirmed state.
     */
    EVENT_STATUS_CONFIRMED = 1,

    /**
     * Indicates the canceled state.
     */
    EVENT_STATUS_CANCELED = 2
  }

  /**
   * Indicates the permission level classification.
   */
  export enum EventsPermission {
    /**
     * Indicates the default permission.
     */
    PERMISSION_DEFAULT = 0,

    /**
     * Indicates the confidential permission.
     */
    PERMISSION_CONFIDENTIAL = 1,

    /**
     * Indicates the private permission.
     */
    PERMISSION_PRIVATE = 2,

    /**
     * Indicates the public permission.
     */
    PERMISSION_PUBLIC = 3
  }

  /**
   * Indicates the status classification of the person involved in the event.
   */
  export enum EventStatus {
    /**
     * Indicates the busy state.
     */
    STATUS_BUSY = 0,

    /**
     * Indicates the idle state.
     */
    STATUS_FREE = 1,

    /**
     * Indicates the tentative state.
     *
     */
    STATUS_TENTATIVE = 2
  }

  /**
   * Calendar CalendarAlerts table general attributes.
   *
   */
  export enum CalendarAlertsColumns {
    /**
     * Indicates the agenda ID.
     */
    ID = '_id',

    /**
     * Indicates the agenda ID.
     */
    EVENT_ID = 'event_id',

    /**
     * Indicates the agenda begin time.
     */
    BEGIN = 'begin',

    /**
     * Indicates the agenda end time.
     */
    END = 'end',

    /**
     * Indicates the agenda alarm time.
     */
    ALARM_TIME = 'alarmTime',

    /**
     * Indicates the agenda creation time.
     */
    CREATION_TIME = 'creationTime',

    /**
     * Indicates the agenda received time.
     */
    RECEIVED_TIME = 'receivedTime',

    /**
     * Indicates the agenda notify time.
     */
    NOTIFY_TIME = 'notifyTime',

    /**
     * Indicates the agenda state.
     */
    STATE = 'state',

    /**
     * Indicates the agenda remind in advance.
     */
    MINUTES = 'minutes'

  }

  /**
   * Calendar Instances table general attributes.
   *
   */
  export enum InstancesColumns {
    /**
     * Indicates the event ID.
     */
    EVENT_ID = 'event_id',

    /**
     * Indicates the start time of the instance.
     */
    INSTANCE_BEGIN = 'begin',

    /**
     * Indicates the end time of the instance.
     */
    INSTANCE_END = 'end',

    /**
     * Indicates the start date of the instance.
     */
    INSTANCE_START_DAY = 'startDay',

    /**
     * Indicates the end date of the instance.
     *

     */
    INSTANCE_END_DAY = 'endDay',

    /**
     * Indicates the instance start time calculated from 00:00 on the current day
     * in the time zone where the calendar is located, in minutes.
     */
    INSTANCE_START_MINUTE = 'startMinute',

    /**
     * Indicates the instance end time calculated from 00:00 on the current day
     * in the time zone where the calendar is located, in minutes.
     */
    INSTANCE_END_MINUTE = 'endMinute'
  }

  /**
   * Calendar Participants table general attributes.
   *
   */
  export enum ParticipantsColumns {
    /**
     * Indicates the event ID.
     *
     */
    EVENT_ID = 'event_id',

    /**
     * Indicates the participant name.
     */
    PARTICIPANT_NAME = 'attendeeName',

    /**
     * Indicates the email address of the participant.
     */
    PARTICIPANT_EMAIL = 'attendeeEmail',

    /**
     * Indicates the role of the participant.
     */
    PARTICIPANT_ROLE_TYPE = 'attendeeRelationship',

    /**
     * Indicates the type of the participant.
     */
    PARTICIPANT_TYPE = 'attendeeType',

    /**
     * Indicates the status of the participant.
     */
    PARTICIPANT_STATUS = 'attendeeStatus'
  }

  /**
   * Indicates the role of the participant.
   */
  export enum ParticipantsROLE {
    /**
     * Indicates an unknown role.
     */
    ROLE_NONE = 0,

    /**
     * Indicates a participant.
     */
    ROLE_ATTENDEE = 1,

    /**
     * Indicates an organizer.
     */
    ROLE_ORGANIZER = 2,

    /**
     * Indicates a performer.
     */
    ROLE_PERFORMER = 3,

    /**
     * Indicates a speaker.
     */
    ROLE_SPEAKER = 4,
  }

  /**
   * Indicates the type of the participant.
   */
  export enum ParticipantsType {
    /**
     * Indicates an unknown type.
     */
    TYPE_NONE = 0,

    /**
     * Indicates a required participant.
     */
    TYPE_REQUIRED = 1,

    /**
     * Indicates an optional participant.
     */
    TYPE_OPTIONAL = 2,

    /**
     * Indicates the resource type.
     */
    TYPE_RESOURCE = 3,
  }

  /**
   * Indicates the status of the participant.
   */
  export enum ParticipantsStatus {
    /**
     * Indicates an unknown state.
     */
    PARTICIPANT_STATUS_NONE = 0,

    /**
     * Indicates the accepted state.
     */
    PARTICIPANT_STATUS_ACCEPTED = 1,

    /**
     * Indicates the rejected state.
     */
    PARTICIPANT_STATUS_DECLINED = 2,

    /**
     * Indicates the invited state.
     */
    PARTICIPANT_STATUS_INVITED = 3,

    /**
     * Indicates the tentative state.
     */
    PARTICIPANT_STATUS_TENTATIVE = 4,
  }

  /**
   * Calendar Reminders table general attributes.
   *
   */
  export enum RemindersColumns {
    /**
     * Indicates the reminder ID.
     */
    ID = '_id',

    /**
     * Indicates the event ID.
     *
     */
    EVENT_ID = 'event_id',

    /**
     * Indicates the event UUID.
     *
     */
    EVENT_UUID = 'eventUuid',

    /**
     * Indicates the number of minutes that the reminder is sent before an event occurs.
     *
     */
    REMIND_MINUTES = 'minutes',

    /**
     * Indicates the reminder type.
     *
     */
    REMIND_TYPE = 'method'
  }

  /**
   * Calendar Reminders table general attributes.
   *
   */
  export enum RemindersRemindType {
    /**
     * Indicates the default type.
     *
     */
    TYPE_DEFAULT = 0,

    /**
     * Indicates an alert.
     *
     */
    TYPE_ALERT = 1,

    /**
     * Indicates an email.
     *
     */
    TYPE_EMAIL = 2,

    /**
     * Indicates an SMS.
     *
     */
    TYPE_SMS = 3,

    /**
     * Indicates an alarm clock reminder.
     *
     */
    TYPE_ALARM = 4
  }

  /**
   * Indicates the default reminder duration, in minutes.
   *
   */
  export const REMIND_MINUTES_NO_REMINDER = -1;

  /**
   * Calendar Attendees table general attributes.
   *
   */
  export enum AttendeesColumns {
    /**
     * Indicates the reminder ID.
     */
    ID = '_id',

    /**
     * Indicates the event ID.
     *
     */
    EVENT_ID = 'event_id',

    /**
     * Indicates the attendee Name.
     *
     */
    ATTENDEE_NAME = 'attendeeName',

    /**
     * Indicates the attendee Email.
     *
     */
    ATTENDEE_EMAIL = 'attendeeEmail',

    /**
     * Indicates the attendee Status.
     *
     */
    ATTENDEE_STATUS = 'attendeeStatus',

    /**
     * Indicates the attendee Relationship.
     *
     */
    ATTENDEE_RELATIONSHIP = 'attendeeRelationship',

    /**
     * Indicates the attendee Type.
     *
     */
    ATTENDEE_TYPE = 'attendeeType',

    /**
     * Indicates the attendee Identity.
     *
     */
    ATTENDEE_IDENTITY = 'attendeeIdentity',

    /**
     * Indicates the attendee Id Namespace.
     *
     */
    ATTENDEE_ID_NAMESPACE = 'attendeeIdNamespace',
  }

  /**
   * Provides constants for information synchronization.
   *
   */
  export enum SyncColumns {
    /**
     * Indicates the account name.
     *
     */
    ACCOUNT_NAME = 'account_name',

    /**
     * Indicates the account type.
     *
     */
    ACCOUNT_TYPE = 'account_type',

    /**
     * Indicates the synchronization ID.
     *
     */
    SYNC_ID = '_sync_id',

    /**
     * Indicates the dirty information.
     *
     */
    DIRTY = 'dirty',

    /**
     * Indicates the name of the calling bundle.
     *
     */
    MUTATORS = 'mutators',

    /**
     * Indicates the deleted state.
     *
     */
    DELETED = 'deleted'
  }


  export enum CalendarMetaDataColumns {
    ID = '_id',
    MIN_INSTANCE = 'minInstance',
    MAX_INSTANCE = 'maxInstance',
  }

  export enum MeetingInfoColumns {
    TABLE_NAME = 'MeetingInfo',
    INSTANCE_ID = 'instance_id',
    EVENT_ID = 'event_id',
    // 会议开始时间
    BEGIN = 'begin',
    // 备忘录跳转凭据
    LINK = 'link'
  }

  /*
 * CalendarCacheColumns
 */
  export enum CalendarCacheColumns {
    ID = '_id',
    UUID = 'uuid',
    KEY = 'key',
    VALUE = 'value',
  }

  /*
   * LockTimeZoneKeys
   */
  export enum LockTimeZoneKeys {
    PRE_LOCKED_TIME_ZONE = 'timezoneInstancesPrevious',
    TIMEZONE_TYPE = 'timezoneType',
    CURRENT_LOCKED_TIME_ZONE = 'timezoneInstances',
  }


  /**
   * Calendar table names
   *
   */
  export enum Tables {
    /**
     * Indicates the name of the Events table.
     *
     */
    EVENTS = 'Events',

    /**
     * Indicates the name of the Calendars table.
     *
     */
    CALENDARS = 'Calendars',

    /**
     * Indicates the name of the Instances table.
     *
     */
    INSTANCES = 'Instances',

    /**
     * Indicates the name of the Participants table.
     *
     */
    PARTICIPANTS = 'Participants',

    /**
     * Indicates the name of the Reminders table.
     *
     */
    REMINDERS = 'Reminders',

    /**
     * Indicates the name of the CalendarAlerts table.
     *
     */
    CALENDAR_ALERTS = 'CalendarAlerts',

    /**
     * Indicates the name of the Attendees table.
     *
     */
    ATTENDEES = 'Attendees',

    /**
     * Indicates the name of the CalendarMetaData table.
     *
     */
    CALENDAR_META_DATA = 'CalendarMetaData',

    /**
     * Indicates the name of the ShareMember table.
     *
     */
    SHARE_MEMBER = 'ShareMember',

    /**
     * Indicates the name of the ShareRelation table.
     *
     */
    SHARE_RELATION = 'ShareRelation',

    /**
     * Indicates the name of the MemberIdentity table.
     *
     */
    MEMBER_IDENTITY = 'MemberIdentity',

    /**
     * Indicates the name of the MessageCenter table.
     *
     */
    MESSAGE_CENTER = 'MessageCenter',

    /**
     * Indicates the name of the ShareMemberRecord table.
     *
     */
    SHARE_MEMBER_RECORD = 'ShareMemberRecord',

    /**
     * Indicates the name of the MessageCalendar table.
     *
     */
    MESSAGE_CALENDAR = 'MessageCalendar',

    /**
     * Indicates the name of the MessageAgenda table.
     *
     */
    MESSAGE_AGENDA = 'MessageAgenda',

    /**
     * Indicates the name of the MessageAgendaRemind table.
     *
     */
    MESSAGE_AGENDA_REMIND = 'MessageAgendaRemind',

    /**
     * Indicates the name of the MeetingInfo table.
     *
     */
    MEETING_INFO = 'MeetingInfo',

    /**
     * Indicates the name of the CalendarCache table.
     *
     */
    CALENDAR_CACHE = 'CalendarCache',

    /**
     * Indicates the name of the Schedule table.
     *
     */
    SCHEDULE = 'Schedule',

    /**
     * Indicates the name of the Course table.
     *
     */
    COURSE = 'Course',

    /**
     * Indicates the name of the CourseTime table.
     *
     */
    COURSE_TIME = 'CourseTime',
    /**
     * Indicates the name of the CourseInstance table.
     *
     */
    COURSE_INSTANCE = 'CourseInstance',
    /**
     * Indicates the name of the ScheduleCache table.
     *
     */
    SCHEDULE_CACHE = 'ScheduleCache',
    /**
     * Indicates the name of the EventAttachments table.
     *
     */
    EVENT_ATTACHMENTS = 'event_attachments',
  }

  /**
   * Describes a calendar abstract entity.
   *
   */
  export class CalendarEntity {
    /**
     * A default account type that indicates calendar does not associated with any account.
     */
    public static ACCOUNT_TYPE_LOCAL: 'LOCAL';
    /**
     * An optional URI parameter that indicates if caller is a sync adapter.
     */
    public static IS_SYNC_ADAPTER: 'caller_is_syncadapter';
    public id: number = 0;
  }

  /**
   * Calendar contract Accounts entity, include database table columns' name.
   *
   */
  export class Accounts extends CalendarEntity {
    public creator: string = '';
    public accountName: string = '';
    public accountType: string = '';
    public name: string = '';
    public calendarDisplayName: string = '';
    public calendarColor: number = 0;
    public calendarAccessLevel: number = 0;
    public visible: number = 0;
    public canReminder: number = 1;
    public uuid: string = '';

    /**
     * 将查询结果转化为 Accounts 对象
     *
     * @param resultSet 查询结果
     */
    static parseAccountByResultSet(resultSet: InnerResultSet, columns?: string[]): Accounts | undefined {
      if (columns && columns.length > 0) {
        return CalendarContract.Accounts.parseAccountWithColumns(resultSet, columns);
      }
      const accounts = new Accounts();
      try {
        accounts.id = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.BaseColumns.ID));
        accounts.accountName = resultSet.getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_NAME));
        accounts.accountType = resultSet.getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_TYPE));
        accounts.name = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.NAME));
        accounts.calendarDisplayName = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME));
        // 三方写入的calendarDisplayName为空，这里设置为accountName
        if (!accounts.calendarDisplayName) {
          accounts.calendarDisplayName = accounts.accountName;
        }
        accounts.calendarColor = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_COLOR));
        accounts.calendarAccessLevel = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL));
        accounts.visible = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.VISIBLE));
        accounts.canReminder = resultSet
          .getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CAN_REMINDER));
        accounts.creator = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CREATOR));
        accounts.uuid = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.UUID));
        return accounts;
      } catch (err) {
        Log.error(TAG, `parseAccountByResultSet error ${err?.message}`);
        return undefined;
      }
    }

    private static parseAccountWithColumns(resultSet: InnerResultSet, columns: string[]): Accounts | undefined {
      const accounts = new Accounts();
      try {
        if (columns.includes(CalendarContract.AccountColumns.UUID)) {
          accounts.uuid = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.UUID));
        }
        if (columns.includes(CalendarContract.BaseColumns.ID)) {
          accounts.id = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.BaseColumns.ID));
        }
        if (columns.includes(CalendarContract.SyncColumns.ACCOUNT_NAME)) {
          accounts.accountName = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_NAME));
        }
        if (columns.includes(CalendarContract.SyncColumns.ACCOUNT_TYPE)) {
          accounts.accountType = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_TYPE));
        }
        if (columns.includes(CalendarContract.AccountColumns.NAME)) {
          accounts.name = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.NAME));
        }
        if (columns.includes(CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME)) {
          accounts.calendarDisplayName = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME));
        }
        if (columns.includes(CalendarContract.AccountColumns.CALENDAR_COLOR)) {
          accounts.calendarColor = resultSet
            .getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_COLOR));
        }
        if (columns.includes(CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL)) {
          accounts.calendarAccessLevel = resultSet
            .getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL));
        }
        if (columns.includes(CalendarContract.AccountColumns.VISIBLE)) {
          accounts.visible = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.VISIBLE));
        }
        if (columns.includes(CalendarContract.AccountColumns.CAN_REMINDER)) {
          accounts.canReminder = resultSet
            .getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CAN_REMINDER));
        }
        if (columns.includes(CalendarContract.AccountColumns.CREATOR)) {
          accounts.creator = resultSet
            .getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CREATOR));
        }
        return accounts;
      } catch (err) {
        Log.error(TAG, `parseAccountWithColumns error ${err?.message}`);
        return undefined;
      }
    }

    /**
     * 将查询结果转化为 Accounts 对象
     *
     * @param resultSet 查询结果
     */
    parseAccounts(resultSet: InnerResultSet): void {
      try {
        this.id = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.BaseColumns.ID));
        this.accountName = resultSet.getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_NAME));
        this.accountType = resultSet.getString(resultSet.getColumnIndex(CalendarContract.SyncColumns.ACCOUNT_TYPE));
        this.name = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.NAME));
        this.calendarDisplayName = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME));
        // 三方写入的calendarDisplayName为空，这里设置为accountName
        if (!this.calendarDisplayName) {
          this.calendarDisplayName = this.accountName;
        }
        this.calendarColor = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_COLOR));
        this.calendarAccessLevel = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL));
        this.visible = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.VISIBLE));
        this.canReminder = resultSet.getLong(resultSet.getColumnIndex(CalendarContract.AccountColumns.CAN_REMINDER));
        this.creator = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.CREATOR));
        this.uuid = resultSet.getString(resultSet.getColumnIndex(CalendarContract.AccountColumns.UUID));
      } catch (err) {
        Log.error(TAG, 'parseAccounts resultSet has some error = ' + err?.message);
      }
    }
  }

  /**
   * Describes a calendar event entity, including the column name of the database table.
   *
   */
  export class Events extends CalendarEntity {
    public accId: number = 0;
    public title: string = '';
    public description: string = '';
    public eventPosition: string = '';
    public eventStatus: number = 0;
    public eventStartTime: number = 0;
    public eventEndTime: number = 0;
    public duration: string = '';
    public isAllDay: boolean = false;
    public availableStatus: number = 0;
    public hasAlarm: boolean = false;
    public recurRule: string = '';
    public recurDate: string = '';
    public initialId: string = '';
    public hasAttendeeInfo: boolean = false;
  }

  /**
   * Describes a calendar instance entity, including the column name of the database table.
   */
  export class Instances extends CalendarEntity {
    public instanceBegin: number = 0;
    public instanceEnd: number = 0;
    public eventId: number = 0;
    public instanceStartDay: number = 0;
    public instanceEndDay: number = 0;
    public instanceStartMinute: number = 0;
    public instanceEndMinute: number = 0;
  }

  /**
   * Describes a calendar participant entity, including the column name of the database table.
   */
  export class Participants extends CalendarEntity {
    public eventId: number = 0;
    public participantName: string = '';
    public participantEmail: string = '';
    public participantRoleType: number = 0;
    public participantType: number = 0;
    public participantStatus: number = 0;
  }

  /**
   * Describes a calendar reminder entity, including the column name of the database table.
   */
  export class Reminders extends CalendarEntity {
    public eventId: number = 0;
    public eventUuid: string = '';
    public remindMinutes: number = 0;
    public remindType: number = 0;
    public syncId: string = '';
  }

  /**
   * Describes a calendar Attendees entity, including the column name of the database table.
   */
  export class Attendees extends CalendarEntity {
    public eventId: number = 0;
    public attendeeName: string = '';
    public attendeeEmail: string = '';
    public attendeeStatus: number = 0;
    public attendeeRelationship: number = 0;
    public attendeeType: number = 0;
    public attendeeIdentity: string = '';
    public attendeeIdNamespace: string = '';
  }

  export class MeetingInfo extends CalendarEntity {
    public eventId: number = 0;
    public instanceId: number = 0;
    public begin: number = 0;
    public link: string = '';
  }

  /**
   * Describes a calendar CalendarAlerts entity, including the column name of the database table.
   */
  export class CalendarAlerts extends CalendarEntity {
    public eventId: number = 0;
    public begin: number = 0;
    public end: number = 0;
    public alarmTime: number = 0;
    public creationTime: number = 0;
    public receiveTime: number = 0;
    public notifyTime: number = 0;
    public state: number = 0;
  }

  /**
   * Describes a calendar Attendees entity, including the column name of the database table.
   */
  export class CalendarMetaData extends CalendarEntity {
    public minInstance: number = 0;
    public maxInstance: number = 0;
  }


  /**
   * Attributes of non-recursive calendar event.
   */
  export class AppletEntity {
    public title: string = '';
    public startTime: number = 0;
    public allDay: boolean = false;
    public description: string = '';
    public location: string = '';
    public endTime: string = '';
    public alarm: boolean = false;
    public alarmOffset: number = 0;
  }

  /**
   * Attributes of recursive calendar event.
   */
  export class AppletRepeatEntity extends AppletEntity {
    public repeatInterval: string = '';
    public repeatEndTime: number = 0;
  }

  /**
   * Describes parameter index of CalendarAlert table
   */
  export class CalendarAlertsIndex {
    public id: number = 0;
    public eventId: number = 0;
    public begin: number = 0;
    public end: number = 0;
    public alarmTime: number = 0;
    public creationTime: number = 0;
    public receivedTime: number = 0;
    public notifyTime: number = 0;
    public state: number = 0;
    public minutes: number = 0;
  }

  /**
   * Describes parameter index of Event table
   */
  export class EventsIndex {
    public id: number = 0;
    public title: number = 0;
  }

  /**
   * 日程类型：普通、纪念日、倒数日...
   */
  export enum EventImportantType {
    NORMAL = 0,
    ANNIVERSARIES = 1,
    COUNTDOWN = 2,
    HOLIDAY = 10
  }

  /**
   * 重要日卡片数据
   */
  export class ImportantConfig {
    public backgroundId: string = '';
    public texturesId: string = '';
    public layoutId: string = '';
    public fontId: string = '';
    public color: string = '';
    public topBright: number = 1;
    public bottomBright: number = 1;
    public opacity: number = 1;
  }


  /**
   * Tag 表 关联的类型
   */
  export enum TagType {
    EVENT = 0,
    ACCOUNT = 1,
  }

  /**
   * 数据状态
   */
  export enum DataState {
    NORMAL = 0,
    DELETED = 1,
    INVISIBLE = 2,
    // 数据的子数据没有处理完的状态
    PRE = 3,
  }

  /**
   * 日程日历类型
   */
  export enum AgendaCalendarType {
    // 公历
    SOLAR = 0,
    // 农历
    LUNAR = 1,
  }

  /**
   * 日程提醒类型
   */
  export enum AgendaAlertType {
    // 普通提醒
    NORMAL = 0,
    // 重要提醒
    IMPORTANT = 1,
  }

  /**
   * 一键服务校验状态
   */
  export enum ServiceVerifyState {
    ILLEGAL = 0,

    NOT_VERIFY = 1,
    // 校验OK
    VERIFIED = 2,
  }

  /**
   * 一键服务服务类型
   */
  export enum HwExtServiceType {
    Meeting = 'Meeting',
  }

  /**
   * 日程帐户类型，同calendarManager.CalendarType
   */
  export enum CalendarType {
    LOCAL = 'local',
    EMAIL = 'email',
    BIRTHDAY = 'birthday',
    SUBSCRIBED = 'subscribed'
  }
}



