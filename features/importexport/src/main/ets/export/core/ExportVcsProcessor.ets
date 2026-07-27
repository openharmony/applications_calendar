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
  AgendaService,
  behaviorEvents,
  CalendarContract,
  CalendarService,
  EmptyUtils,
  EventService,
  TimeZoneUtil,
  GlobalThis,
  I18nUtil,
  Log,
  ReminderService,
  ReportHiEventParams,
  ReportUtil,
  traceEvents,
  UTC,
  HolidayUtil
} from '@app/common';
import { ExportListener } from '../../ExportListener';
import { BaseProcessor, TaskState } from '../../core/BaseProcessor';
import { ExportVcsRequest } from './ExportVcsRequest';
import { CalendarInfo } from '../../vcalendar/CalendarInfo';
import { NEW_LINE, V_SPLIT, VERSION_10, VERSION_20 } from '../../vcalendar/VCalendarConstants';
import { CalendarBuilder } from '../../vcalendar/export/builder/CalendarBuilder';
import { getCalendarBuilder } from '../../vcalendar/CalendarFactory';
import HashMap from '@ohos.util.HashMap';
import common from '@ohos.app.ability.common';
import { ShareEventVcsBean } from '../../interface/ShareEventVcsBean';
import { CustomTime, FormatBit, FormatTime, SplitOption } from '@app/feature.repeatrule';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { i18n } from '@kit.LocalizationKit';
import { ExportType, ImportExportErrorCode, ShareType } from '../../interface/BusinessConstant';
import { ExportProgressListener } from '../../ExportProgressListener';
import { runTaskAsync } from '@app/common/src/main/ets/util/TaskPool';
import { collections, taskpool } from '@kit.ArkTS';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';

const TAG = 'ExportVcsProcessor';
// 分享打点，是账户
const IS_ACCOUNT = 1;
const NOT_ACCOUNT = 0;
const maxIdsPerQuery = 1000;// 每次查询的最大ids数量
const maxCharNum = 10;// 分享面板最大展示标题字数

/*
 * 导出日程,账户为vcs文件处理器
 */
export class ExportVcsProcessor extends BaseProcessor {
  private mExportRequest: ExportVcsRequest;
  private mListener: ExportListener<ShareEventVcsBean>;
  private task: taskpool.Task | undefined = undefined;

  private onExportProgressChanged: (totalEventCount: number, processedEventCount: number) =>
    void = (totalEventCount: number, processedEventCount: number) => {
    this.mListener.onExportProgressChanged(this.mJobId, totalEventCount, processedEventCount);
  };

  constructor(exportRequest: ExportVcsRequest, context: common.UIAbilityContext | null, listener: ExportListener<ShareEventVcsBean>, jobId: number) {
    super();
    this.mExportRequest = exportRequest;
    this.mContext = context;
    this.mListener = listener;
    this.mJobId = jobId;
  }

  public getType(): number {
    return 0;
  }

  public isImportType(): boolean {
    return false;
  }

  public getListener(): ExportListener<ShareEventVcsBean> {
    return this.mListener;
  }

  public async run(): Promise<boolean> {
    if (this.mExportRequest.isCanceled()) {
      Log.warn(TAG, `run task isCanceled`);
      return false;
    }
    if (!this.mExportRequest.isWaiting()) {
      Log.warn(TAG, `run unexpect state ${this.mExportRequest.getStatus()}`);
      return false;
    }
    this.mExportRequest.setStatus(TaskState.STATE_RUNNING);
    try {
      return await this.runInternal();
    } catch (err) {
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.NO_SUCH_ACCOUNT);
      Log.warn(TAG, `run error ${err.message}}`);
      return false;
    }
  }

  protected onTaskCanceled(): void {
    if (this.task) {
      try {
        taskpool.cancel(this.task);
      } catch (err) {
        Log.logErrorMsg(TAG, `onTaskCanceled error`, err);
      }
    }
  }

  // 分享打点
  reportUtil(events: number) {
    let isAccount: number = NOT_ACCOUNT;
    let shareAgendas: number = events;
    if (this.mExportRequest.exportType === ExportType.ACCOUNT_EXPORT) {
      isAccount = IS_ACCOUNT;
    }
    let params: ReportHiEventParams = {
      IS_ACCOUNT: isAccount,
      SHARE_AGENDAS: shareAgendas
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.triggerShareAgendaOrAccount, params);
  }

  public setRequestStatus(status: TaskState): void {
    super.setRequestStatus(status);
    this.mExportRequest.setStatus(status);
  }

  /**
   * Gets the calendar version.
   *
   * @return Version.
   */
  protected getCalendarVersion(): string {
    if (ExportType.ACCOUNT_EXPORT == this.mExportRequest.exportType || ExportType.EVENTS_EXPORT == this.mExportRequest.exportType) {
      return VERSION_20;
    }
    return VERSION_10;
  }

  private async runInternal(): Promise<boolean> {
    hiTraceMeter.startTrace(traceEvents.exportVcs, 0);
    Log.info(TAG, "runInternal: start export");
    let account: CalendarContract.Accounts | undefined = new CalendarContract.Accounts();
    let events: Array<AgendaEventInfo> = new Array();
    let reminderMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
    // 导出账户
    if (ExportType.ACCOUNT_EXPORT == this.mExportRequest.exportType) {
      account = await this.queryAccountInfo(events, reminderMap);
      if (!account) {
        this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.NO_SUCH_ACCOUNT);
        return false;
      }
    } else if (ExportType.EVENTS_EXPORT == this.mExportRequest.exportType ||
      ExportType.EVENT_VCS_EXPORT == this.mExportRequest.exportType) { // 批量导出日程
      const queryResult = await this.queryEventAndReminds(0, this.mExportRequest.getEventIds(), events, reminderMap, false);
      if (!queryResult) {
        this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_NO_SUCH_EVENTS);
        hiTraceMeter.finishTrace(traceEvents.exportVcs, 0);
        return false;
      }
    } else {
      Log.error(TAG, `runInternal not support such export_type`);
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_TYPE_NO_MATCH);
      hiTraceMeter.finishTrace(traceEvents.exportVcs, 0);
      return false;
    }
    let timeZone: string = TimeZoneUtil.getCurrentTimeZone();
    // 版本1.0的需要event的时区
    if (ExportType.EVENT_VCS_EXPORT == this.mExportRequest.exportType) {
      timeZone = events[0].eventTimeZone;
    }

    this.task = new taskpool.Task(startExport, timeZone, this.getCalendarVersion(),
      this.mExportRequest.getPath(),  this.mExportRequest.getIcsPath(), account, events, new Map(reminderMap));
    this.task.onReceiveData(this.onExportProgressChanged);
    const eventResult = await taskpool.execute(this.task, taskpool.Priority.MEDIUM) as AgendaEventInfo[];

    if (this.isCancelled()) {
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_USER_CANCEL);
      return false;
    }
    if (eventResult) {
      events = eventResult.map(item => new AgendaEventInfo(item));
      this.callExportProcessed(events, account);
      this.reportUtil(events.length);
    } else {
      this.mListener.onExportFailed(this.mExportRequest, this.mJobId, ImportExportErrorCode.EXPORT_BUILD_FILE_FAILED);
      return false;
    }
    hiTraceMeter.finishTrace(traceEvents.exportVcs, 0);
    return true;
  }

  private async queryAccountInfo(events: AgendaEventInfo[],
                                 reminderMap: HashMap<number,
                                 CalendarContract.Reminders[]>): Promise<CalendarContract.Accounts | undefined> {
    const accountId: number = this.mExportRequest.getAccountId();
    Log.info(TAG, `queryAccountInfo`);
    const account = await CalendarService.INSTANCE.queryCalendarById(accountId);
    if (!account) {
      Log.warn(TAG, `queryAccountInfo not matched Account`);
      hiTraceMeter.finishTrace(traceEvents.exportVcs, 0);
      return undefined;
    }
    await this.queryEventAndReminds(account.id, this.mExportRequest.getEventIds(), events, reminderMap, true);
    return account;
  }

  private callExportProcessed(events: AgendaEventInfo[], account?: CalendarContract.Accounts) {
    const shareTitle: string = this.buildShareTitle(events, account);
    let eventText: string | undefined = undefined;
    Log.warn(TAG, `callExportProcessed shareType is ${this.mExportRequest.shareType}`);
    if (this.mExportRequest.shareType == ShareType.TEXT_AND_VCS) {
      eventText = buildTextByEventInfo(events[0]);
      this.mListener.onExportProcessed(this.mExportRequest, this.mJobId,
        this.buildShareEventVcsBean(this.mExportRequest.shareType, this.mExportRequest.mPath,
          this.mExportRequest.mIcsPath, events[0], eventText, shareTitle));
    } else if (this.mExportRequest.shareType == ShareType.ONLY_VCS) {
      this.mListener.onExportProcessed(this.mExportRequest, this.mJobId,
        this.buildShareEventVcsBean(this.mExportRequest.shareType, this.mExportRequest.mPath,
          this.mExportRequest.mIcsPath, undefined, undefined, shareTitle));
    } else {
      this.mListener.onExportProcessed(this.mExportRequest, this.mJobId,
        this.buildShareEventVcsBean(this.mExportRequest.shareType,
          this.mExportRequest.mPath, this.mExportRequest.mIcsPath));
    }
  }

  private getFormatDisplayName(account: CalendarContract.Accounts): string {
    if (AccountUtils.isHolidayAccount(account)) {
      const holidayCalendarDisplayName: ResourceStr = getContext().resourceManager.
        getStringSync($r('app.string.country_holiday'), HolidayUtil.getDisplayCountry(account.accountName));
      return holidayCalendarDisplayName;
    }
    return account.calendarDisplayName;
  }

  private buildShareTitle(events: AgendaEventInfo[], account?: CalendarContract.Accounts): string {
    const context = GlobalThis.getInstance().context;
    let rowTitle: string = '';
    if (ExportType.ACCOUNT_EXPORT == this.mExportRequest.exportType && account) {
      rowTitle = this.getFormatDisplayName(account);
    } else {
      rowTitle = events[0].mTitle;
      if (EmptyUtils.isEmptyString(rowTitle)) {
        rowTitle = (GlobalThis.getResourceStr($r('app.string.no_title_label')));
      }
      if (events.length <= 1) {
        return rowTitle;
      }
    }
    if (events.length > 1 && rowTitle.length > maxCharNum) {
      rowTitle = rowTitle.substring(0, maxCharNum) + '...';
    }
    if (context) {
      try {
        const agendaNum: string = GlobalThis.getPluralStr($r('app.plural.share_multiple_agendas'), events.length, I18nUtil.getSystemLanguage())
        return context.resourceManager.getStringSync($r('app.string.share_multiple_agenda').id, rowTitle, agendaNum);
      } catch (err) {
        Log.error(TAG, `buildShareTitle ${err?.message}`);
      }
    }
    return '';
  }

  private async queryEventAndReminds(accountId: number, eventIds: number[],
                                     events: Array<AgendaEventInfo>,
                                     reminderMap: HashMap<number, Array<CalendarContract.Reminders>>, isAccount: boolean) {
    let temEvents: Array<AgendaEventInfo> | undefined = undefined;
    if (isAccount) {
      temEvents = await EventService.INSTANCE.queryEventByAccountId(accountId);
    } else {
      let results : AgendaEventInfo[] = [];
      for (let i = 0; i < eventIds.length; i += maxIdsPerQuery) {
        const segmentIds = eventIds.slice(i, i + maxIdsPerQuery);
        let segmentEvents = await EventService.INSTANCE.queryEventsByEventIds(segmentIds);

        if (segmentEvents) {
          results.push(...segmentEvents);
        }
      }
      temEvents = results; // 将结果赋值给temEvents
    }
    if (EmptyUtils.isEmptyArray(temEvents) && isAccount) {
      Log.info(TAG, `queryEventAndReminds events is Empty`);
      return true;
    }
    if (EmptyUtils.isEmptyArray(temEvents) && !isAccount) {
      Log.warn(TAG, `queryEventAndReminds events is Empty isAccount false eventIds count is ${eventIds.length}`);
      return false;
    }
    events.push(...temEvents)
    let temReminderMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
    const reminderEventIds: Array<number> = new Array();
    for (let eventsElement of events) {
      reminderEventIds.push(eventsElement.mId);
    }
    temReminderMap = await ReminderService.INSTANCE.queryReminderInfoByEventIds(reminderEventIds);
    if (EmptyUtils.isEmptyArray(temReminderMap)) {
      Log.info(TAG, `queryEventAndReminds reminderMap is Empty`);
    } else {
      reminderMap.setAll(temReminderMap);
    }
    return true;
  }

  private buildShareEventVcsBean(shareType: ShareType, filePath: string, icsPath: string,
                                 event?: AgendaEventInfo, eventText?: string, shareTitle?: string): ShareEventVcsBean {
    return new ShareEventVcsBean(shareType, eventText, filePath, icsPath, event, shareTitle);
  }
}

export function buildTextByEventInfo(eventInfo: AgendaEventInfo): string {
  const language: string = i18n.System.getSystemLanguage();
  let text: string = '';
  if (EmptyUtils.isNotEmptyString(eventInfo.mTitle)) {
    text += GlobalThis.getResourceStr($r('app.string.edit_event_title_label'), language) +
      V_SPLIT + eventInfo.mTitle + NEW_LINE;
  }
  // 纪念日或倒数日
  if (eventInfo.mImportantEventType > 0) {
    text += GlobalThis.getResourceStr($r('app.string.important_title_data'), language) +
      V_SPLIT + stampToDate(eventInfo.mBegin, true) + NEW_LINE;
  } else if (eventInfo.mIsAllDay) {
    // 全天
    text += GlobalThis.getResourceStr($r('app.string.all_day'), language) + V_SPLIT +
    stampToDate(eventInfo.mBegin, true) + NEW_LINE;
  } else {
    text += GlobalThis.getResourceStr($r('app.string.start_date'), language) + V_SPLIT +
    stampToDate(eventInfo.mBegin, false, eventInfo.eventTimeZone) + NEW_LINE;
    if (eventInfo.mBegin < eventInfo.mEnd) {
      text += GlobalThis.getResourceStr($r('app.string.end_date'), language) +
        V_SPLIT + stampToDate(eventInfo.mEnd, false, eventInfo.eventTimeZone) + NEW_LINE;
    }
  }
  if (EmptyUtils.isNotEmptyString(eventInfo.mLocation, true)) {
    text += GlobalThis.getResourceStr($r('app.string.hint_where'), language) +
      V_SPLIT + eventInfo.mLocation + NEW_LINE;
  }
  if (EmptyUtils.isNotEmptyString(eventInfo.mDescription, true)) {
    text += GlobalThis.getResourceStr($r('app.string.hint_export_description'), language) +
      V_SPLIT + eventInfo.mDescription + NEW_LINE;
  }
  if (EmptyUtils.isNotEmptyString(text)) {
    const lastNewLineIndex: number = text.lastIndexOf(NEW_LINE);
    if (lastNewLineIndex != -1) {
      text = text.substring(0, lastNewLineIndex);
    }
  }
  return text;
}

/**
 * 这个方法是导出txt String 使用,因为单框架都是UTC,所以这里格式化时不能传入event的timeZone
 * 全天日程 yyyy-MM-dd 非全天 yyyy-MM-dd HH:mm
 * @param millis
 * @param isAllDay
 * @returns
 */
function stampToDate(millis: number, isAllDay: boolean, timeZone?: string): string {
  if (isAllDay) {
    const splitOption: SplitOption = {
      yearSplit: '-',
      monthSplit: '-',
      daySplit: '',
      hourSplit: '',
      minuteSplit: '',
      secondSplit: ''
    };
    const customTime: CustomTime = new CustomTime(UTC);
    customTime.setTime(millis);
    return new FormatTime().setByCustomTime(customTime, false).format(FormatBit.DAY, splitOption);
  } else {
    const splitOption: SplitOption = {
      yearSplit: '-',
      monthSplit: '-',
      daySplit: ' ',
      hourSplit: ':',
      minuteSplit: '',
      secondSplit: ''
    };
    const customTime: CustomTime = new CustomTime(timeZone);
    customTime.setTime(millis);
    return new FormatTime().setByCustomTime(customTime, false).format(FormatBit.MINUTE, splitOption);
  }
}

@Concurrent
async function startExport(timeZone: string, version:string, path: string, icsPath: string,
                           account: CalendarContract.Accounts, events: Array<AgendaEventInfo>,
                           reminderMap: Map<number, Array<CalendarContract.Reminders>>) {
  Log.info('ExportVcsProcessor', `startExport start`);
  const begin = Date.now();
  const calendarInfo: CalendarInfo = new CalendarInfo(timeZone, version);
  const iBuilder: CalendarBuilder = getCalendarBuilder(calendarInfo);
  iBuilder.setOutputFilePath(path);
  let reminderHashMap: HashMap<number, Array<CalendarContract.Reminders>> = new HashMap();
  reminderMap?.forEach((value, key) => {
    reminderHashMap.set(key, value);
  })
  let eventArr = events.map(item => new AgendaEventInfo(item))
  const buildResult: boolean = await iBuilder.buildExportFile(account, eventArr, reminderHashMap);
  if (!buildResult) {
    return [];
  }
  FileUtils.copyFileFromSrcToDes(path, icsPath);
  Log.info('ExportVcsProcessor', `startExport end cost time:${Date.now() - begin} buildResult: ${buildResult}`);
  return eventArr;
}