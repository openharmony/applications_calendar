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

import { AgendaEventInfo, AgendaEventInfoWrap,
  CommonInnerEvent,
  EmptyUtils,
  HolidayUtil,
  Log,
  PreferencesFiles,
  PreferencesUtil,
  traceEvents } from '@app/common';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { CalendarInfo } from '../vcalendar/CalendarInfo';
import { CalendarParser } from '../vcalendar/import/parser/CalendarParser';
import { ImportRequest } from './ImportRequest';
import { BaseProcessor, ShareIntentType, TaskState } from '../core/BaseProcessor';
import { VCalParser, VcsParseStatus } from '../vcalendar/VCalParser';
import { getCalendarParser } from '../vcalendar/CalendarFactory';
import { ImportListener } from '../ImportListener';
import { VcsComponent, VTIMEZONE } from '../vcalendar/import/model/VcsComponent';
import { InnerImportData } from './ImportHelper';
import { VACCOUNT_COLOR, VACCOUNT_DISPLAYNAME, VEVENT_COUNT } from '../vcalendar/VCalendarConstants';
import { SimpleAccount } from '../interface/SimpleAccount';
import { InsertProcessor } from './InsertProcessor';
import { InsertListener } from './InsertListener';
import { ImportData } from '../interface/ImportData';
import { Property } from '../vcalendar/import/model/Property';
import common from '@ohos.app.ability.common';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { ImportExportErrorCode, ImportType } from '../interface/BusinessConstant';
import { collections, taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';
import { data } from '@kit.TelephonyKit';

// 与导入导入系统接口调用强耦合
/* instrument ignore file */

const TAG = 'ImportProcessor'

/**
 * 导入处理
 */
export class ImportProcessor extends BaseProcessor {
  private mImportRequest: ImportRequest;
  private mParser: CalendarParser | undefined = undefined;
  private calendarInfo: CalendarInfo = new CalendarInfo();
  private countryCode: string = '';
  private mImportListener: ImportListener<ImportData>;
  private insertListener: InsertListener;
  private mImportData: InnerImportData = new InnerImportData();
  private insertProcessor: InsertProcessor | undefined = undefined;
  private task: taskpool.Task | undefined = undefined;
  private eventComponents: Array<VcsComponent> = [];

  private onVcsParseListenerCallback: (status: VcsParseStatus, component: VcsComponent) =>
    void = (status:VcsParseStatus, component: VcsComponent) => {
    switch (status) {
      case VcsParseStatus.CALENDAR_PARSED:
        this.onCalendarParsed(component);
        break;
      case VcsParseStatus.EACH_EVENT_PARSED:
        this.onEachEventParsed(component);
        break;
      default:
        this.onParseFinished();
        break;
    }
  };

  public constructor(importRequest: ImportRequest, context: common.UIAbilityContext | null, listener: ImportListener<ImportData>, insertListener: InsertListener,
                     jobId: number, countryCode: string = '') {
    super();
    this.mImportRequest = importRequest;
    this.mContext = context;
    this.mImportListener = listener;
    this.insertListener = insertListener;
    this.mJobId = jobId;
    this.countryCode = countryCode;
  }

  readonly mSaveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void = (isSave: boolean, simpleAccount?: SimpleAccount) => {
    Log.info(TAG, `onSave called isSave ${isSave}`);
    if (isSave) {
      if (!simpleAccount) {
        this.insertListener.onSaveFailed(this.mImportRequest, this.mJobId,
          ImportExportErrorCode.IMPORT_ACCOUNT_IS_NULL);
        return;
      }
      this.saveEventOrAccount(simpleAccount as SimpleAccount);
    } else {
      this.insertListener.onSaveFailed(this.mImportRequest, this.mJobId, ImportExportErrorCode.IMPORT_USER_CANCEL);
      this.cancelByUser();
    }
  }

  /**
   * 解析到日历账户信息后,使用账户构建时区信息
   * @param calendarComponent
   */
  async onCalendarParsed(calendarComponent: VcsComponent, isCalendarParse: boolean = false) {
    Log.info(TAG, `onCalendarParsed calendarComponent`);
    this.calendarInfo = new CalendarInfo();
    this.calendarInfo.initCalendarInfoByComponent(calendarComponent);
    this.mParser = getCalendarParser(this.calendarInfo, this.countryCode);
    this.updatePRule(calendarComponent);
    this.mImportData = new InnerImportData();
    const propertyNames = calendarComponent.getPropertyNames();
    if (propertyNames.has(VACCOUNT_DISPLAYNAME) && propertyNames.has(VACCOUNT_COLOR)) {
      this.mImportData.mAccountDisplayName = (calendarComponent.getFirstProperty(VACCOUNT_DISPLAYNAME) as Property).getValue();
      const colorString: string = (calendarComponent.getFirstProperty(VACCOUNT_COLOR) as Property).getValue();
      const color = Number(colorString);
      if (Number.isNaN(color)) {
        Log.warn(TAG, `onCalendarParsed color is ${colorString} illeagl`);
      } else {
        this.mImportData.mAccountColor = color.valueOf();
      }
      this.fillEventCount(calendarComponent);
      this.mImportData.importType = ImportType.ACCOUNT_IMPORT;
    } else if (propertyNames.has(VEVENT_COUNT)) {
      this.mImportData.importType = ImportType.EVENTS_IMPORT;
      this.fillEventCount(calendarComponent);
    } else {
      this.mImportData.importType = ImportType.EVENT_IMPORT;
    }
  }

  async onEachEventParsed(eventComponent: VcsComponent) {
    this.eventComponents.push(eventComponent);
  }

  async onParseFinished(): Promise<void> {
    this.mImportRequest.setStatus(TaskState.STATE_RUNNING);
    Log.info(TAG, 'onParseFinished');
    if (!this.mParser) {
      Log.error('ImportProcessor', `onEachEventParsed mParser is null ${!this.mParser} `);
      this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
        ImportExportErrorCode.IMPORT_PARSING_FAILED);
      return;
    }
    try {
      const begin = Date.now();
      const task = new taskpool.Task(startConvertEvent, this.calendarInfo, this.eventComponents, this.countryCode);
      const events = await taskpool.execute(task, taskpool.Priority.MEDIUM) as Array<AgendaEventInfo>;
      Log.info(TAG, `startConvertEvent end cost time:${Date.now() - begin} events length:${events.length}`);
      events.forEach(item => {
        const event = new AgendaEventInfoWrap(item);
        event.reminders = event.checkValuesArray;
        this.mImportData.addEvent(event);
      });
      this.mImportListener?.onImportFinished(this.mImportRequest, this.mJobId, this.buildOutImportData());
      this.mImportRequest.setStatus(TaskState.STATE_SUCCESS);
    } catch (err) {
      Log.logErrorMsg(TAG, 'onParseFinished error:', err);
      this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
        ImportExportErrorCode.IMPORT_PARSING_FAILED);
    }
  }

  public getType(): number {
    return ShareIntentType.IMPORT_TYPE;
  }

  public isImportType(): boolean {
    return true;
  }

  public async run(): Promise<boolean> {
    if (this.isCancelled()) {
      Log.info(TAG, 'run task canceled');
      return false;
    }
    hiTraceMeter.startTrace(traceEvents.importVcs, 0);
    let vcsFileStringContent: string = '';
    try {
      // readStringFromFile 调用 getStringByReadSync 方法里的try catch 走了,但是这里还要再catch一次,
      vcsFileStringContent = this.readStringFromFile();
    } catch (error) {
      Log.logErrorMsg(TAG, 'vcsFileStringContent', error);
      this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
        ImportExportErrorCode.IMPORT_FILE_CONTENT_EMPTY);
      return false;
    }
    if (EmptyUtils.isEmptyString(vcsFileStringContent, true)) {
      Log.warn(TAG, `run vcsFileStringContent is empty`);
      this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
        ImportExportErrorCode.IMPORT_FILE_CONTENT_EMPTY);
      hiTraceMeter.finishTrace(traceEvents.importVcs, 0);
      return false;
    }
    try {
      const begin = Date.now();
      this.task = new taskpool.Task(startVscParse, vcsFileStringContent, this.countryCode);
      this.task.onReceiveData(this.onVcsParseListenerCallback);
      const component = await taskpool.execute(this.task, taskpool.Priority.MEDIUM) as VcsComponent;
      Log.info(TAG, `startVscParse end cost time:${Date.now() - begin}`);
      if (!component || this.mImportRequest.getStatus() === TaskState.STATE_WAITING) {
        this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
          ImportExportErrorCode.IMPORT_PARSING_FAILED);
        hiTraceMeter.finishTrace(traceEvents.importVcs, 0);
        return false;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'startVscParse error', err);
      this.mImportListener.onImportFailed(this.mImportRequest, this.mJobId,
        ImportExportErrorCode.IMPORT_PARSING_FAILED);
      hiTraceMeter.finishTrace(traceEvents.importVcs, 0);
      return false;
    }
    return true;
  }

  public cancel(isMayInterruptIfRunning: boolean): boolean {
    if (!super.cancel(isMayInterruptIfRunning)) {
      return false;
    }
    if (this.insertProcessor) {
      return this.insertProcessor?.cancel(isMayInterruptIfRunning);
    }
    return true;
  }

  public isCanDoOtherTask(): boolean {
    if (!this.insertProcessor) {
      return this.isAfterState(TaskState.STATE_RUNNING);
    }
    return this.isAfterState(TaskState.STATE_RUNNING) && this.insertProcessor.isAfterState(TaskState.STATE_RUNNING);
  }

  public isCancelled(): boolean {
    return this.mImportRequest.isCanceled();
  }

  public isWaitingState(): boolean {
    return this.mImportRequest.isWaiting();
  }

  public setRequestStatus(status: TaskState): void {
    this.mImportRequest.setStatus(status);
  }

  private fillEventCount(calendarComponent: VcsComponent) {
    if (!calendarComponent.getPropertyNames().has(VEVENT_COUNT)) {
      Log.warn(TAG, `fillEventCount VEVENT_COUNT Property is null`);
      return;
    }
    const countString: string = (calendarComponent.getFirstProperty(VEVENT_COUNT) as Property).getValue();
    const count = Number(countString);
    if (Number.isNaN(count)) {
      Log.warn(TAG, `onCalendarParsed eventCount is ${countString} illeagl`);
    } else {
      this.mImportData.mEventsCount = count.valueOf();
    }
  }

  private updatePRule(calendarComponent: VcsComponent) {
    if (!calendarComponent) {
      Log.warn(TAG, "updatePRule component is null");
      return;
    }
    const componentsList: collections.Array<VcsComponent> = calendarComponent.getComponents();
    if (EmptyUtils.isEmptyArray(componentsList)) {
      Log.warn(TAG, "updatePRule componentsList is empty");
      return;
    }
    for (let component of componentsList) {
      if (component && VTIMEZONE) {
        Log.info(TAG, ` updatePRule parseDayLight`);
        this.mParser?.parseDayLight(component, this.calendarInfo);
        break;
      }
    }
  }

  /**
   * 用户取消
   */
  private cancelByUser() {
    this.setRequestStatus(TaskState.STATE_CANCELLED)
  }

  /**
   * 保存日程或账户到数据库中
   * @param simpleAccount
   */
  private saveEventOrAccount(simpleAccount: SimpleAccount) {
    this.insertProcessor = new InsertProcessor(this.mImportData, simpleAccount, this.mImportData.importType, this.insertListener, this.mImportRequest);
    this.insertProcessor.run();
    this.insertProcessor.setRequestStatus(TaskState.STATE_RUNNING);
  }

  private buildOutImportData(): ImportData {
    const simpleAccount: SimpleAccount = new SimpleAccount(0, this.mImportData.mAccountDisplayName, this.mImportData.mAccountColor, this.mImportData.mAlarmEnable);
    const importData: ImportData = new ImportData(simpleAccount, this.mImportData.importType,
      this.mImportData.mEventsCount, this.mImportData.getHeadEvents(), this.mImportData.getAllEvents());
    return importData;
  }

  private readStringFromFile(): string {
    return FileUtils.getStringByReadSync(this.mImportRequest.getFileUri());
  }
}

@Concurrent
async function startVscParse(text: string, countryCode = '') {
  const tag = 'ImportProcessor';
  Log.info(tag, `startVscParse start`);
  try {
    return await new VCalParser().parseCalendar(text, countryCode);
  } catch (error) {
    Log.logErrorMsg(tag, 'parseCalendar error', error);
  }
  return undefined;
}

@Concurrent
async function startConvertEvent(calendarInfo: CalendarInfo,
                                 eventComponents: Array<VcsComponent>, countryCode: string) {
  const tag = 'ImportProcessor';
  Log.info(tag, `startConvertEvent start`);
  const mCalendarInfo = new CalendarInfo();
  mCalendarInfo.copyInfo(calendarInfo);
  const events: AgendaEventInfo[] = [];
  const mParser = getCalendarParser(mCalendarInfo, countryCode);

  let holidayAbbreviationArray: string[] = [];
  for (const eventComponent of eventComponents) {
    const event: AgendaEventInfo = new AgendaEventInfo();
    let parseEventResult: boolean = false;
    try {
      parseEventResult = await mParser.parseEvent(eventComponent, event, holidayAbbreviationArray);
    } catch (error) {
      Log.logErrorMsg(tag, 'parseEvent error', error);
    }
    if (countryCode && countryCode === 'CN_CUSTOM') {
      if (HolidayUtil.needRemoveHoliday(event.mTitle) === '') {
        continue;
      }
    }
    if (parseEventResult) {
      event.mLanguageResources = JSON.stringify(event.mLanguageRecord);
      events.push(event);
    }
  }

  if (countryCode === 'CN' || countryCode === 'CN_CUSTOM') {
    PreferencesUtil.putStringArrayValueSync(PreferencesFiles.HOLIDAY, 'holidayAbbreviationInfo', holidayAbbreviationArray);
  }
  return events;
}