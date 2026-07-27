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
  AccountUtils,
  AgendaEventInfo,
  AgendaEventInfoWrap,
  behaviorEvents,
  CalendarAccessLevel,
  CalendarAccountType,
  CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  CalendarService,
  EmptyUtils,
  EventService,
  GlobalThis,
  Log,
  ReminderService,
  ReportHiEventParams,
  ReportUtil,
} from '@app/common';
import { BaseProcessor } from '../core/BaseProcessor';
import { InnerImportData } from './ImportHelper';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import { InsertListener } from './InsertListener';
import { ImportRequest } from './ImportRequest';
import { SimpleAccount } from '../interface/SimpleAccount';
import { ImportExportErrorCode, ImportType } from '../interface/BusinessConstant';

// 日程及提醒等入库，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG = 'InsertProcessor'
const IS_ACCOUNT = 1;
const NOT_ACCOUNT = 0;

/**
 * 将日程数据插入数据库处理器
 */
export class InsertProcessor extends BaseProcessor {
  private importData: InnerImportData;
  private simpleAccount: SimpleAccount;
  private importType: ImportType;
  private insertListener: InsertListener;
  private request: ImportRequest;
  private accountList: CalendarContract.Accounts[] = [];

  constructor(importData: InnerImportData, simpleAccount: SimpleAccount, importType: ImportType,
              insertListener: InsertListener, request: ImportRequest) {
    super();
    this.importData = importData;
    this.simpleAccount = simpleAccount;
    this.importType = importType;
    this.insertListener = insertListener;
    this.request = request;
  }

  public isWaitingState(): boolean {
    return false;
  }

  public async run(): Promise<boolean> {
    this.insertListener.onSaveStart(this.request, this.request.jobId);
    if (ImportType.ACCOUNT_IMPORT === this.importType) {
      Log.info(TAG, `run save account`);
      if (this.isCancelled()) {
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_INSERT_ACCOUNT_FAILED);
        Log.warn(TAG, `run task isCancelled`);
        return false;
      }
      const accountId = await this.insertAccount();
      if (accountId < 1) {
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_INSERT_ACCOUNT_FAILED);
        return false;
      }
      Log.info(TAG, `run insertAccount result is success`);
      if (EmptyUtils.isEmptyArray(this.importData.getAllEvents())) {
        Log.info(TAG, `run no event need insert`);
        this.insertListener.onSaveSuccess(this.request, this.request.jobId);
        return false;
      }
      const insertCount: number = await this.insertEvents(accountId);
      Log.warn(TAG, `run insert event count need insert count is ${this.importData.getAllEvents().length}
        insert suc count is ${insertCount}`);
      if (insertCount < this.importData.getAllEvents().length) {
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_INSERT_EVENT_COUNT_NOT_MATCH);
        return false;
      }
      this.insertListener.onSaveSuccess(this.request, this.request.jobId);
      return true;
    } else {
      Log.info(TAG, `run save events`);
      const account = await this.queryAccount(this.simpleAccount.mAccountId);
      if (!account) {
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_ACCOUNT_NOT_EXIST);
        Log.warn(TAG, `run no account query for id ${this.simpleAccount.mAccountId}`);
        return false;
      }
      if (EmptyUtils.isEmptyArray(this.importData.getAllEvents())) {
        Log.warn(TAG, `run save events events is empty`);
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_INSERT_NO_EVENTS);
        return false;
      }
      const insertCount: number = await this.insertEvents(account.id);
      Log.warn(TAG, `run insert event count need insert count is ${this.importData.getAllEvents().length}
        insert suc count is ${insertCount}`);
      if (insertCount < this.importData.getAllEvents().length) {
        this.insertListener.onSaveFailed(this.request, this.request.jobId,
          ImportExportErrorCode.IMPORT_INSERT_EVENT_COUNT_NOT_MATCH);
        return false;
      }
      this.insertListener.onSaveSuccess(this.request, this.request.jobId);
      return true;
    }
  }

  // 分享打点
  reportUtil(isAccount: number, events: number) {
    let params: ReportHiEventParams = {
      IS_ACCOUNT: isAccount,
      SHARE_AGENDAS: events
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.receiveShareAgendaOrAccount, params);
  }

  protected getType(): number {
    return 0;
  }

  protected isImportType(): boolean {
    return true;
  }

  private async queryAccount(accountId: number): Promise<CalendarContract.Accounts | undefined> {
    if (this.isCancelled()) {
      return;
    }
    return await CalendarService.INSTANCE.queryCalendarById(accountId);
  }

  private async insertAccount(): Promise<number> {
    if (this.isCancelled()) {
      return 0;
    }
    let accountCreated: ValuesBucket = {};
    accountCreated[CalendarContract.SyncColumns.ACCOUNT_TYPE] = CalendarAccountType.CUSTOM_ACCOUNT_TYPE;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME] = this.simpleAccount.mAccountDisplayName;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_COLOR] = this.simpleAccount.mAccountColor;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_ACCESS_LEVEL] = CalendarAccessLevel.CAL_ACCESS_OWNER;
    accountCreated[CalendarContract.AccountColumns.VISIBLE] = 1;
    accountCreated[CalendarContract.AccountColumns.CAN_REMINDER] = this.simpleAccount.mAlarmEnable ? 1 : 0;
    let accountId: number = await CalendarService.INSTANCE.insertCalendar(accountCreated) as number;
    if (accountId < 1) {
      Log.warn(TAG, `insertAccount error`);
    }
    return accountId;
  }

  private async isSameEvent(event: AgendaEventInfo, localEvent: AgendaEventInfo[]): Promise<boolean> {
    for (let agendaEventInfo of localEvent ) {
      if (event.mTitle === agendaEventInfo.mTitle &&
        event.mBegin === agendaEventInfo.mBegin) {
        if (event.mLanguageResources !== agendaEventInfo.mLanguageResources &&
          await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
          const value = {} as ValuesBucket;
          value[CalendarContract.EventsColumns.LANGUAGE_RESOURCES] = event.mLanguageResources;
          await EventService.INSTANCE.updateByEventId(agendaEventInfo.mId, value);
        }
        return true;
      }
    }
    return false;
  }

  private async insertEvents(calendarId: number): Promise<number> {
    const account = await this.queryAccount(this.simpleAccount.mAccountId);
    const isHolidayAccount: boolean = CalendarAccountType.HOLIDAY_ACCOUNT_TYPE === account?.accountType;
    let accounts: CalendarContract.Accounts[] = await CalendarService
      .INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    this.accountList = AccountUtils.sortAccountListInAccPage(accounts);
    let defaultAccountId = this.accountList[0].id;
    let localEvent: AgendaEventInfo[] = [];
    if (isHolidayAccount) {
      localEvent = await EventService.INSTANCE.queryEventByAccountId(calendarId);
    }
    let insertSuccessCount: number = 0;
    for (let event of this.importData.getAllEvents()) {
      if (this.isCancelled()) {
        Log.info(TAG, 'insertEvents task cancel');
        return insertSuccessCount;
      }
      if (isHolidayAccount && await this.isSameEvent(event, localEvent)) {
        insertSuccessCount++;
        continue;
      }
      // 重要日/普通日程时间处理
      let startTime: number = event.mBegin;
      let endTime: number = event.mEnd;
      const value: Record<string, string | Number> = {
        'title': event.mTitle.length === 0 ? GlobalThis.getResourceStr($r('app.string.no_title_label')) : event.mTitle,
        'dtstart': startTime,
        'dtend': endTime,
        'calendar_id': event.isImportantEvent() ? defaultAccountId : calendarId,
        'eventTimezone': event.eventTimeZone,
        'description': event.mDescription,
        [CalendarContract.EventsColumns.SERVICE_DESCRIPTION]: event.mHwextServiceDescription,
        [CalendarContract.EventsColumns.SERVICE_VERIFIED]: event.mHwextServiceVerified ? 2 : 0,
        [CalendarContract.EventsColumns.SERVICE_TYPE]: event.mHwextServiceType,
        [CalendarContract.EventsColumns.SERVICE_CP_BZ_URI]: event.mHwextServiceUri,
        'allDay': event.mIsAllDay ? 1 : 0,
        'eventLocation': event.mLocation,
        'important_event_type': event.mImportantEventType,
        'event_time_stamp': Date.now(),
        [CalendarContract.EventsColumns.RRULE]: event.mRepeatRule,
        [CalendarContract.EventsColumns.EVENT_CALENDAR_TYPE]: event.mEventCalendar,
        [CalendarContract.EventsColumns.EXDATE]: event.exDate,
      };
      if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES)) {
        value[CalendarContract.EventsColumns.LANGUAGE_RESOURCES] = event.mLanguageResources;
      }
      let newEventId: number = await EventService.INSTANCE.insertEvent(value) as number;
      if (newEventId < 1) {
        Log.warn(TAG, `insertEvents failed `);
        continue;
      }
      insertSuccessCount++;
      const agendaWarp: AgendaEventInfoWrap = event as AgendaEventInfoWrap;
      if (EmptyUtils.isNotEmptyArray(agendaWarp?.reminders)) {
        const insertRemindResult: boolean = await this.insertRemainders(agendaWarp?.reminders, newEventId);
        if (!insertRemindResult) {
          Log.warn(TAG, `insertRemindResult false`);
        }
      }
    }
    return insertSuccessCount;
  }

  private async insertRemainders(remainders: Array<CalendarContract.Reminders>, eventId: number): Promise<boolean> {
    return await ReminderService.INSTANCE.insertReminderArray(eventId, remainders);
  }
}