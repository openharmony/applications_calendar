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

import emitter from '@ohos.events.emitter';

import {
  AccountUtils,
  AgendaEventInfo,
  AgendaUtil,
  behaviorEvents,
  CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  CalendarDate,
  CalendarService,
  CommonInnerEvent,
  CompId,
  CreateAgendaSheetFromPage,
  DateUtil,
  DialogControllerOptions,
  EmitterCollector,
  EventService,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  NotificationTriggerHelper,
  PreferencesUtil,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceEnum,
  ServiceManager,
  SourceTypeEnum,
  statisticEvents,
  ThrottleFunction,
  traceEvents,
  TriggerSource
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { ChangeFlag } from '../../components/DateAndTimePicker';
import lazy { DefaultAgenda } from './DefaultAgenda';
import { addExDateToDb, CustomTime, Frequency, Recurrence, updateUntilToDb } from '@app/feature.repeatrule';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { TabController } from './TabController';
import { AgendaType, CreateAgendaPageSource, DEFAULT_NUM, SaveTimeType } from '../Constants';
import { EffectiveDateMode } from '@app/commons.repeatruleview/src/main/ets/EffectiveDateViewModel';
import lazy { ImportantAgenda } from './ImportantAgenda';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import lazy { LocationInfo, RECENT_LOCATION } from './LocationSetupAbility';
import { CreateAgendaViewModel } from '../viewmodel/CreateAgendaViewModel';
import { GcmUtil } from '@app/common/src/main/ets/util/GcmUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { AttachmentViewModel } from '../../AgendaAttachment/viewmodel/AttachmentViewModel';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { AgendaAttachmentService } from '@app/service.attachment';
import { broadcastContentNotInterrupt } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'CreateAgenda';

/**
 * 日程创建组件
 *
 * @since 2022-09-27
 */
@Component
export struct CreateAgenda {
  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  // 选择的日程开始时间，用于计算重复周期相关初始值
  @StorageLink('initSelectedStartDate') initSelectedStartDate: CalendarDate = new CalendarDate(this.displayDate);

  @Consume intent: string;

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  // 默认提醒时间
  @StorageLink('defaultRemindTime') presetReminderTime: number = 10;

  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') allDayPresetReminderTime: number = 0;

  @State firstEnter: boolean = true;

  // 日程附件相关信息
  @State @Watch('onAttachmentListChange') agendaAttachmentViewModel: AttachmentViewModel = new AttachmentViewModel();

  // 重要日附件相关信息
  @State @Watch('onAttachmentListChange') importantAttachmentViewModel: AttachmentViewModel = new AttachmentViewModel();

  // 日程界面附件是否改变
  @State hasChangeDefaultAttachmentList: boolean | undefined = false;

  // 重要日界面附件是否改变
  @State hasChangeImportantAttachmentList: boolean | undefined = false;

  // 日程数据
  @Prop eventInfo: AgendaEventInfo = new AgendaEventInfo();

  // 普通日程数据
  @State @Watch('defaultEventInfoChange') defaultEventInfo: AgendaEventInfo = new AgendaEventInfo();

  // 重要日日程数据
  @State @Watch('importantEventInfoChange') importantEventInfo: AgendaEventInfo = new AgendaEventInfo();

  // 提醒列表数据
  @State @Watch('checkValuesArrayChange') checkValuesArray: CalendarContract.Reminders[] = this.eventInfo.checkValuesArray || [];

  // 选中的帐户 id
  @State @Watch('checkAccountIdChange') accountId: number = DEFAULT_NUM;

  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  // 是否初始化完成
  @State isReady: boolean = false;

  // 选中的帐户 id
  @State oldAccountId: number = DEFAULT_NUM;

  // 切换之前的页数
  @State lastIndex: number = 0;

  // 当前页
  @Consume currentIndex: number;

  @State isImportantAlert: boolean = false;

  @State isLunar: boolean = false;

  @State agendaTimeZone: string = '';

  @State secondTimeZone: string = '';

  // 外部传入的创建日程的开始时间，若存在，则使用该时间，否则使用 displayDate
  @Prop agendaDateParam: number = 0;

  // 外部传入的创建日程的时长，若存在，则使用该时间，否则使用 一小时
  @Prop agendaDateLength: number = MILLS_PER_HOUR;

  // 外部传入的保留时间标志,若存在,则不对传入时间作截取操作
  @Prop needSaveTime: SaveTimeType = SaveTimeType.DEFAULT;

  // 指定默认显示的日程页面类型
  @Prop paramEventType: number = CalendarContract.EventImportantType.NORMAL;

  // 冲突日程列表
  @Provide conflictingAgendaList: AgendaEventInfo[] = [];

  // 标题以及规避区高度
  @Prop titleHeight: number = 0;

  @Prop @Watch('eventTypeChange') importantEventType: number = CalendarContract.EventImportantType.NORMAL;

  // 弹窗控制选择器选项，新建日程页面统一配置
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: true,
    customStyle: true,
  };

  // 新建半模态拉起入口
  @Prop fromPage: CreateAgendaSheetFromPage = CreateAgendaSheetFromPage.MAIN_PAGE;

  // 日程的默认开始时间
  defaultStartDate: number = -1;

  // 日程的默认结束时间
  defaultEndDate: number = -1;

  // 初始普通日程数据
  private rawDefaultInfo: AgendaEventInfo = new AgendaEventInfo();

  // 初始重要日日程数据
  private rawImportantInfo: AgendaEventInfo = new AgendaEventInfo();

  // 初始的提醒列表数据，保存刚进入组件生命周期时的提醒列表数据
  private rawCheckValuesArray: CalendarContract.Reminders[] = AgendaEventInfo.deepCloneReminders(this.checkValuesArray);

  // 提醒数据是否改变
  private valuesArrayChange: boolean = false;

  // 是否编辑态
  private isEditMode: boolean = false;

  // 气泡开关
  @StorageLink(GlobalDataKeys.SHARE_SCHEDULE_POPUPS) shareSchedulePopups: boolean = true;

  // 编辑前是全天日程
  private isAllDayBeforeEdit: boolean = false;

  // 是否快速新建
  private isQuickCreate: boolean = false;

  // 编辑态旧ID
  private oldEventId: number = -1;

  private scroller: Scroller = new Scroller();

  // 改变弹窗内容是否编辑过的状态
  private changeEditedFlag: () => void = () => {
  };

  // 是否支持一句话智能创建
  private oneSentenceCreate: boolean = false;

  // 初始日程的提醒时间数量
  private initReminders: number = 0;

  // 防止视图短时间内多次刷新，本延时不宜过长，页面新建时便会触发第一次限流，导致编辑功能无法触发视图刷新
  private readonly DELAY: number = 300;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private viewModel: CreateAgendaViewModel = new CreateAgendaViewModel();

  private timeStampKey: number = Date.now(); // 用于拉起键盘防止id重复的key

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  /**
   * 开启账户日程显示提示框
   */
  private accountVisibleHintDialog: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      title: $r('app.string.calendar_enable_account_title'),
      message: $r('app.string.calendar_enable_account_content'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.calendar_to_enable_account'),
      isFocusLeftButton: true,
      onCancelClick: (() => {
        showToast($r('app.string.calendar_cancel_enable_account_toast'));
        this.saveEvent();
      }),
      onConfirmClick: (() => {
        AccountUtils.updateAccountVisible(this.accountId, true);
        this.saveEvent();
      })
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle,
  });

  // 保存跨天重複日程提示
  saveAcrossDayRecurringAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.save_across_day_recurring_agenda_tips'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.save_dialog_button'),
      isFocusLeftButton: true,
      onCancelClick: () => {
        this.saveAcrossDayRecurringAgendaDialogController?.close();
      },
      onConfirmClick: () => {
        this.saveEvent();
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
    customStyle: this.dialogControllerOptions.customStyle,
  });

  /**
   * 判断是否可勾选
   *
   */
  onSaveStatusChange: (enable: boolean) => void = (enable: boolean): void => {
  };

  /**
   * 点击勾选的回调
   *
   */
  onConfirmComplete: () => void = (): void => {
  };

  onTabTypeChange: (type: number) => void = (type: number): void => {
  };

  /**
   * 获取创建日程的默认开始时间
   *
   */
  getDefaultStartDate(): number {
    Log.info(TAG, `displayDate = ${this.displayDate}, agendaDateParam = ${this.agendaDateParam}`);
    // 有日期参数时
    if (this.agendaDateParam && this.agendaDateParam !== -1) {
      return this.viewModel.getStartDateByCombine(this.agendaDateParam, this.needSaveTime);
    } else {
      return this.viewModel.getStartDateByCombine(this.displayDate, this.needSaveTime);
    }
  }

  /**
   * 计算默认的结束时间戳。
   *
   * 根据默认的开始时间戳和预设的时间长度，计算出一个默认的结束时间戳。
   * 如果默认的开始日期时间戳接近当天的结束时间（即当天的23:30之后），则返回当天的结束时间戳加1，即第二天的0:00；
   * 否则，返回默认的开始时间戳加上预设的时间长度。
   *
   * @returns {number} - 默认的结束时间戳
   */
  getDefaultEndDate(): number {
    const startDateBeyondZeroTimeMills = this.defaultStartDate - DateUtil.getStartOfDayTimeStamp(this.defaultStartDate);
    if (startDateBeyondZeroTimeMills >= (MILLS_PER_DAY - (MILLS_PER_HOUR / 2))) {
      return DateUtil.getEndMillsOfDate(new CalendarDate(this.defaultStartDate)) + 1;
    } else {
      return this.defaultStartDate + this.agendaDateLength;
    }
  }

  eventTypeChange() {
    const type = this.importantEventType;
    this.eventInfoChange(type);
  }

  /**
   * 监听日程数据变化的回调
   *
   */
  eventInfoChange(type: AgendaType) {
    if (!this.isReady) {
      return;
    }
    ThrottleFunction.instance().debounceInstant(TAG, (): void => {
      let newEventInfo: AgendaEventInfo;
      let rawEventInfo: AgendaEventInfo;
      switch (type) {
        case AgendaType.DEFAULT:
          newEventInfo = this.defaultEventInfo;
          rawEventInfo = this.rawDefaultInfo;
          break;
        case AgendaType.IMPORTANT:
          newEventInfo = this.importantEventInfo;
          rawEventInfo = this.rawImportantInfo;
          break;
        default:
          newEventInfo = this.defaultEventInfo;
          rawEventInfo = this.rawDefaultInfo;
          break;
      }
      let infoChange: boolean = this.compareToNotSame(rawEventInfo, newEventInfo);
      this.valuesArrayChange = !this.checkFlagsIsSame(this.checkValuesArray, this.rawCheckValuesArray);
      if (newEventInfo.mId) {
        this.onSaveStatusChange(infoChange || this.valuesArrayChange);
      } else {
        this.onSaveStatusChange(infoChange);
      }
    }, this.DELAY);
  }

  defaultEventInfoChange() {
    Log.info(TAG, 'defaultEventInfoChange');
    this.eventInfoChange(AgendaType.DEFAULT);
  }

  importantEventInfoChange() {
    Log.info(TAG, 'importantEventInfoChange');
    this.eventInfoChange(AgendaType.IMPORTANT);
  }

  checkValuesArrayChange() {
    Log.info(TAG, 'checkValuesArrayChange');
    this.eventInfoChange(AgendaType.DEFAULT);
  }

  checkAccountIdChange() {
    Log.info(TAG, 'checkAccountIdChange');
    this.eventInfoChange(AgendaType.DEFAULT)
  }

  onAttachmentListChange() {
    Log.info(TAG, `onAttachmentListChange updateAttachmentList`);
    this.updateAttachmentList(false);
    this.eventInfoChange(this.currentIndex);
  }

  updateAttachmentList(send: boolean) {
    const server = ServiceManager.getInstance().getService<AgendaAttachmentService>(ServiceEnum.ATTACHMENT_SERVICE);
    if (this.currentIndex === AgendaType.DEFAULT) {
      this.defaultEventInfo.mAttachmentCount = this.agendaAttachmentViewModel.dataSource.totalCount();
      this.hasChangeDefaultAttachmentList =
        server?.isAttachmentListChange(
          this.agendaAttachmentViewModel.dataSource.getDataList(),
          this.agendaAttachmentViewModel.originalAttachmentList,
          send,
          this.getConfirmEventInfo().uuid);
    } else {
      this.importantEventInfo.mAttachmentCount = this.importantAttachmentViewModel.dataSource.totalCount();
      this.hasChangeImportantAttachmentList =
        server?.isAttachmentListChange(
          this.importantAttachmentViewModel.dataSource.getDataList(),
          this.importantAttachmentViewModel.originalAttachmentList,
          send,
          this.getConfirmEventInfo().uuid);
    }
  }

  /**
   * 比较用函数
   * @returns 如果不同返回true
   */
  compareToNotSame(oldEventInfo: AgendaEventInfo, eventInfo: AgendaEventInfo): boolean {
    // 无标题不能保存
    if (!eventInfo.mTitle && (this.currentIndex !== 0)) {
      return false;
    }
    if ((eventInfo === undefined) || (oldEventInfo === undefined)) {
      return true;
    }
    if (this.checkArrLegal(oldEventInfo, eventInfo)) {
      return true;
    }
    if (oldEventInfo.checkValuesArray.length !== eventInfo.checkValuesArray.length) {
      return true;
    }
    if (this.checkAttendeeListLegal(oldEventInfo, eventInfo)) {
      return true;
    }
    if (oldEventInfo.mAttendeeList?.length !== eventInfo.mAttendeeList?.length) {
      return true;
    }

    if (this.compareEventInfoData(oldEventInfo, eventInfo)) {
      return true;
    }
    if (oldEventInfo.checkValuesArray !== undefined) {
      for (let i = 0; i < oldEventInfo.checkValuesArray.length; i++) {
        if (this.compareEventInfoCheckArr(oldEventInfo, i, eventInfo)) {
          return true;
        }
      }
    }

    if (oldEventInfo.mAttendeeList !== undefined) {
      for (let i = 0; i < oldEventInfo.mAttendeeList.length; i++) {
        if (this.compareEventInfoAttendList(oldEventInfo, i, eventInfo)) {
          return true;
        }
      }
    }

    if (this.hasChangeDefaultAttachmentList && this.isEditMode) {
      return true;
    }

    if (this.hasChangeImportantAttachmentList && this.isEditMode) {
      return true;
    }

    if (this.accountId !== this.oldAccountId) {
      return true;
    }
    return false;
  }

  /**
   * 用于校验提醒列表
   * @param oldInstancesFlags
   * @param newInstancesFlags
   * @returns
   */
  checkFlagsIsSame(
    oldCheckValuesArray: CalendarContract.Reminders[],
    newCheckValuesArray: CalendarContract.Reminders[]
  ): boolean {
    if (oldCheckValuesArray?.length !== newCheckValuesArray?.length) {
      return false;
    }

    if (oldCheckValuesArray !== undefined) {
      for (let i = 0; i < oldCheckValuesArray.length; i++) {
        if ((oldCheckValuesArray[i].eventId !== newCheckValuesArray[i].eventId) ||
          (oldCheckValuesArray[i].remindMinutes !== newCheckValuesArray[i].remindMinutes) ||
          (oldCheckValuesArray[i].remindType !== newCheckValuesArray[i].remindType) ||
          (oldCheckValuesArray[i].syncId !== newCheckValuesArray[i].syncId)) {
          return false;
        }
      }
    }

    return true;
  }

  // 编辑态获取数据
  setEditInfo() {
    this.oldEventId = this.eventInfo.mId;
    if (this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA ||
      this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND
    ) {
      this.eventInfo.mBegin = this.instanceStartMills;
      this.eventInfo.mEnd = this.instanceEndMills;
    }

    if (this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA) {
      this.eventInfo.mRepeatRule = '';
    }

    if (this.eventInfo?.checkValuesArray) {
      this.rawCheckValuesArray = AgendaEventInfo.deepCloneReminders(this.eventInfo.checkValuesArray);
      this.checkValuesArray = this.eventInfo.checkValuesArray;
      this.initReminders = this.checkValuesArray.length;
      this.isImportantAlert = this.eventInfo.alertType === CalendarContract.AgendaAlertType.IMPORTANT ? true : false;
    }

    this.currentIndex = this.paramEventType === CalendarContract.EventImportantType.NORMAL ? 0 : 1;
    switch (this.currentIndex) {
      case 0:
        this.rawDefaultInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
        this.defaultEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
        break;
      case 1:
        this.rawImportantInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
        this.importantEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
        break;
      default:
        break;
    }
  }

  // 编辑当前重复日程点击勾选按钮
  async editThisAgendaConfirm() {
    const isDeleted = await addExDateToDb(this.eventInfo.mId, this.instanceStartMills);
    this.defaultEventInfo.mId = 0;
    this.importantEventInfo.mId = 0;
    if (isDeleted) {
      this.confirmEvent();
    } else {
      Log.warn(TAG, 'delete in editThisAgendaConfirm failed');
    }
  }

  // 编辑当前重复日程及以后日程点击勾选按钮
  async editThisAgendaAndBeyondConfirm() {
    const isDeleted = await updateUntilToDb(this.eventInfo.mId, this.instanceStartMills);
    this.defaultEventInfo.mId = 0;
    this.importantEventInfo.mId = 0;
    if (isDeleted) {
      this.confirmEvent();
    } else {
      Log.warn(TAG, 'delete in editThisAgendaAndBeyondConfirm failed');
    }
  }

  saveEvent() {
    // 编辑重复日程，先删除再新建
    if (this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA) {
      this.editThisAgendaConfirm();
    } else if (this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND) {
      this.editThisAgendaAndBeyondConfirm();
    } else {
      this.confirmEvent();
    }
  }

  checkEvent() {
    const nowAgendaInfo = this.getConfirmEventInfo();
    const beginTime = new CalendarDate(nowAgendaInfo.mBegin);
    const endTime = new CalendarDate(nowAgendaInfo.mEnd);
    if (!nowAgendaInfo.isImportantEvent() && nowAgendaInfo.isRepeatEvent() && beginTime.getDate() != endTime.getDate()) {
      return false;
    }
    return true;
  }

  async aboutToAppear() {
    try {
      if (this.isEditMode) {
        this.setEditInfo();
      } else {
        this.initCreateInfo();
      }
      if (this.intent === CreateAgendaPageSource.NLU_CREATE_AGENDA_PAGE) {
        this.rawDefaultInfo = new AgendaEventInfo();
      }

      this.saveHandler = async () => {
        let account = await CalendarService.INSTANCE.queryCalendarById(this.accountId);
        if (account?.visible === 0) {
          this.accountVisibleHintDialog?.open();
          return;
        }
        if (!this.checkEvent()) {
          this.saveAcrossDayRecurringAgendaDialogController?.open();
          return;
        }
        this.saveEvent();
      };

      this.defaultStartDate = this.getDefaultStartDate();
      this.defaultEndDate = this.getDefaultEndDate();
      this.isReady = true;
      this.isLunar = this.eventInfo.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR ? true : false;
      if (this.isEditMode) {
        this.initSelectedStartDate = new CalendarDate(this.eventInfo.mBegin);
        this.isAllDayBeforeEdit = this.eventInfo.mIsAllDay;
      } else {
        this.initSelectedStartDate = new CalendarDate(this.displayDate);
      }
      await this.initTimeZone();
      this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_CREATE_AGENDA }, this.saveHandler)
      this.emitterCollector.on({ eventId: CommonInnerEvent.AGENDA_TIME_ZONE_CHANGED }, this.timeZoneChangeHandler)
    } catch (error) {
      Log.info(TAG, `aboutToAppear catch error = ${error?.message}`);
    }
  }

  async initTimeZone() {
    this.agendaTimeZone = this.eventInfo.eventTimeZone ? this.eventInfo.eventTimeZone : CalendarDate.timeZone;
    this.secondTimeZone = CalendarDate.timeZone;
  }

  aboutToDisappear() {
    this.emitterCollector.off();
    this.saveAcrossDayRecurringAgendaDialogController = null;
  }

  // 新建时初始化提醒时间
  presetReminders(info: AgendaEventInfo) {
    // 根据是否全天日程，获取默认的提醒时间
    let reminderMinutes: number = 0;
    if (info.mIsAllDay && this.allDayPresetReminderTime != CalendarContract.REMIND_MINUTES_NO_REMINDER) {
      reminderMinutes = this.allDayPresetReminderTime;
    } else if (!info.mIsAllDay && this.presetReminderTime != CalendarContract.REMIND_MINUTES_NO_REMINDER) {
      reminderMinutes = this.presetReminderTime;
    } else {
      Log.info(TAG, `user set no reminder default`);
      return;
    }

    // 创建reminder对象
    let reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
    reminder.eventId = this.eventInfo.mId;
    reminder.remindMinutes = reminderMinutes;
    reminder.remindType = CalendarContract.RemindersRemindType.TYPE_ALERT;

    info.checkValuesArray.push(reminder);
  }

  build() {
    Column() {
      if (this.currentIndex === AgendaType.DEFAULT) {
        DefaultAgenda({
          defaultEventInfo: $defaultEventInfo,
          defaultStartTime: this.defaultStartDate,
          defaultEndTime: this.defaultEndDate,
          isEditMode: this.isEditMode,
          accountId: this.accountId,
          oldAccountId: this.oldAccountId,
          scrollerForList: this.scroller,
          checkValuesArray: this.checkValuesArray,
          fromImportantSelect: this.fromPage === CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT,
          isImportantAlert: this.isImportantAlert,
          isQuickCreate: this.isQuickCreate,
          oneSentenceCreate: this.oneSentenceCreate,
          changeEditedFlag: this.changeEditedFlag,
          currentIndex: this.currentIndex,
          timeStampKey: this.timeStampKey,
          routerName: this.routerName,
          titleHeight: this.titleHeight,
          agendaTimeZone: this.agendaTimeZone,
          secondTimeZone: this.secondTimeZone,
          attachmentViewModel: this.agendaAttachmentViewModel,
        })
      } else {
        ImportantAgenda({
          importantEventInfo: this.importantEventInfo,
          defaultStartTimeStamp: this.displayDate,
          defaultEndTimeStamp: this.defaultEndDate,
          isEditMode: this.isEditMode,
          checkValuesArray: this.checkValuesArray,
          timeStampKey: this.timeStampKey,
          routerName: this.routerName,
          titleHeight: this.titleHeight,
          scrollerForList: this.scroller,
          fromImportantSelect: this.fromPage === CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT,
          isImportantAlert: this.isImportantAlert,
          attachmentViewModel: this.importantAttachmentViewModel,
        })
      }
    }
    .id(CompId.CREATE_AGENDA)
    .height(this.isQuickCreate ? undefined : '100%')
    .onAppear(() => {
      if (this.shareSchedulePopups) {
        const timer = setTimeout(() => {
          this.requestNotificationThenRequestFocus();
          clearTimeout(timer);
        }, 1000)
      } else {
        this.requestNotificationThenRequestFocus();
      }
    })
    .layoutWeight(this.isQuickCreate ? 0 : 1)
  }

  async getPostValue(eventInfo: AgendaEventInfo) {
    // 重要日/普通日程时间处理
    let dtStart: number = 0;
    let dtEnd: number = 0;
    let startTime: number = this.defaultStartDate;
    let endTime: number = this.defaultEndDate;
    if (this.currentIndex !== 0) {
      // 重要日开始日期是当天UTC 0点 结束日期获取当天UTC24:00
      let current = eventInfo.mBegin === 0 ?
        new CalendarDate(this.defaultStartDate) : new CalendarDate(eventInfo.mBegin);
      current.setHours(0, 0, 0);
      startTime = current.getTime() + current.getTimezoneOffset(current.getTime());
      Log.info(TAG, `getPostValue importantDaycurrent timeMillIs ${current.getTime()}, startTime ${startTime}`);
      endTime = startTime + MILLS_PER_DAY;
      dtStart = startTime;
      dtEnd = endTime;
    } else {
      if (eventInfo.mIsAllDay) {
        // 全天日程开始日期是当天UTC 0点 结束日期获取结束日期当天UTC24:00
        let current = eventInfo.mBegin === 0 ?
          new CalendarDate(this.defaultStartDate) : new CalendarDate(eventInfo.mBegin);
        current.setHours(0, 0, 0);
        startTime = current.getTime() + current.getTimezoneOffset(current.getTime());
        Log.info(TAG, `getPostValue allDay current timeMillIs ${current.getTime()}, startTime ${startTime}`);
        dtStart = startTime;
        let endCurrent = new CalendarDate(eventInfo.mEnd);
        endCurrent.setHours(0, 0, 0);
        endTime = endCurrent.getTime() + endCurrent.getTimezoneOffset(endCurrent.getTime());
        // 全天日程编辑全天日程且非开始结束时间不同的情况下,不需要+1。普通日程编辑全天日程，或开始结束时间一样时需要+1
        if (this.isAllDayBeforeEdit && eventInfo.mBegin != eventInfo.mEnd) {
          dtEnd = eventInfo.mEnd;
        } else {
          dtEnd = eventInfo.mEnd === 0 ? (startTime + MILLS_PER_DAY) : (endTime + MILLS_PER_DAY);
        }
      } else {
        dtStart = eventInfo.mBegin === 0 ? startTime : eventInfo.mBegin;
        dtEnd = eventInfo.mEnd === 0 ? endTime : eventInfo.mEnd;
      }
    }

    if (eventInfo.isImportantAnniversaries()) {
      this.checkValuesArray = [];
    } else {
      this.checkValuesArray = eventInfo.checkValuesArray;
    }

    const value: Record<string, string | Number> = {
      'title': eventInfo.mTitle,
      'dtstart': DateUtil.changeToUTCTime(dtStart),
      'dtend': DateUtil.changeToUTCTime(dtEnd),
      'eventTimezone': eventInfo.mIsAllDay ? 'UTC' : (this.agendaTimeZone ?
        this.agendaTimeZone : eventInfo.eventTimeZone),
      'description': eventInfo.mDescription.length === 0 ? '' : eventInfo.mDescription,
      'allDay': eventInfo.mIsAllDay ? 1 : 0,
      'event_time_stamp': Date.now(),
      'rrule': eventInfo.mRepeatRule,
      'event_calendar_type': eventInfo.mEventCalendar,
      'hwext_alert_type': eventInfo.alertType
    };
    value[CalendarContract.EventsColumns.CALENDAR_ID] = (this.accountId === DEFAULT_NUM ||
      eventInfo.isImportantEvent()) ? 1 : this.accountId;
    value[CalendarContract.EventsColumns.CALENDAR_UUID] = (this.accountId === DEFAULT_NUM ||
      eventInfo.isImportantEvent()) ? '1' : eventInfo.mCalendarUuid;
    value[CalendarContract.EventsColumns.IMPORTANT_EVENT_TYPE] = eventInfo.mImportantEventType;
    await this.fillEncryptedLocationValue(value, eventInfo);
    if (await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT)) {
      value[CalendarContract.EventsColumns.ATTACHMENT_COUNT] = eventInfo.mAttachmentCount;
    }

    // todo 共享成员列表处理  share_members:Array<ShareMemberInfo> = []

    return value;
  }

  private async fillEncryptedLocationValue(value: Record<string, string | Number>, eventInfo: AgendaEventInfo) {
    value[CalendarContract.EventsColumns.EVENT_LOCATION] = eventInfo.mLocation.length === 0 ? '' : eventInfo.mLocation.trim();
    if (!AgendaUtil.isLocationValid(eventInfo.mLatitude, eventInfo.mLongitude)) {
      return;
    }
    try {
      let latitudeStr = `${eventInfo.mLatitude}`;
      let longitudeStr = `${eventInfo.mLongitude}`;
      value[CalendarContract.EventsColumns.LOCATION_LATITUDE] = latitudeStr;
      value[CalendarContract.EventsColumns.LOCATION_LONGITUDE] = longitudeStr;
    } catch (err) {
      Log.logErrorMsg(TAG, 'fillEncryptedLocationValue', err);
    }
  }

  getConfirmEventInfo(): AgendaEventInfo {
    switch (this.currentIndex) {
      case 0:
        return this.defaultEventInfo;
      case 1:
        return this.importantEventInfo;
      default:
        break;
    }
    return this.eventInfo;
  }

  /**
   * 点击勾选按钮，插入/更新日程信息
   *
   */
  async confirmEvent() {
    const nowAgendaInfo = this.getConfirmEventInfo();

    const value: Record<string, string | Number> = await this.getPostValue(nowAgendaInfo);
    this.onConfirmComplete();
    if (AgendaUtil.isLocationValid(nowAgendaInfo.mLatitude, nowAgendaInfo.mLongitude)) {
      const locationInfo: LocationInfo = {
        location: nowAgendaInfo.mLocation,
        latitudeStr: `${nowAgendaInfo.mLatitude}`,
        longitudeStr: `${nowAgendaInfo.mLongitude}`,
      }
      PreferencesUtil.putStringValueSync(RECENT_LOCATION, nowAgendaInfo.mLocation, JSON.stringify(locationInfo));
    }

    // 更新场景
    if (!await this.updateEventScene(this.getConfirmEventInfo(), value)) {
      return;
    }
    await this.insertEventScene(value);
    this.reportStatisticEvent(this.eventInfo.mId);
  }

  reportStatisticEvent(agendaId: number) {
    const isEdit: boolean = !!agendaId;
    const reminderMinutes: number[] = [];
    this.checkValuesArray.forEach(item => reminderMinutes.push(item.remindMinutes));

    const value: ReportHiEventParams = {
      IS_ON: this.eventInfo.alertType,
      TYPE: this.currentIndex
    };

    const recurrence = Recurrence.parse(this.eventInfo.mRepeatRule);
    if (this.eventInfo.isLunarEvent()) {
      recurrence.setLunarEvent();
    }
    const params: ReportHiEventParams = {
      HAS_LOCATION: this.eventInfo.mLocation.length === 0 ? 0 : 1,
      REMINDER_MINUTES: reminderMinutes,
      IS_ALLDAY: this.currentIndex !== 0 ? 1 : (this.eventInfo.mIsAllDay ? 1 : 0),
      CHANGE_ACCOUNT: this.accountId === this.oldAccountId ? 0 : 1,
      HAS_DESCRIPTION: this.eventInfo.mDescription.length === 0 ? 0 : 1,
      TYPE: this.currentIndex,
    };

    params.REPEAT_TYPE = Frequency.CUSTOMIZE;
    if (recurrence.until !== '') {
      params.EFFECTIVE_DATE = EffectiveDateMode.UNTIL;
    } else if (recurrence.count !== 0) {
      params.EFFECTIVE_DATE = EffectiveDateMode.COUNT;
    } else if (recurrence.interval !== 0) {
      params.EFFECTIVE_DATE = EffectiveDateMode.FOREVER;
    } else {
      params.REPEAT_TYPE = recurrence.freq;
    }

    if (isEdit) {
      value.CHANGE_FLAG = ChangeFlag.EDIT;
      ReportUtil.reportStatisticEvent(statisticEvents.editAgenda, params);
    } else {
      value.CHANGE_FLAG = ChangeFlag.INSERT;
      params.FROM_TYPE =
        this.fromPage === CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT ? FromType.IMPORTANT_FA : FromType.MONTH_VIEW;
      ReportUtil.reportStatisticEvent(statisticEvents.createAgenda, params);
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaImportantAlert, value);
  }

  private saveHandler: () => void = (): void => {
  };

  private timeZoneChangeHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    if (!eventData?.data) {
      return;
    }
    Log.info(TAG, `timeZoneChangeHandler agendaTimeZone ${eventData.data.timezoneId}`);
    this.agendaTimeZone = eventData.data.timezoneId;
    this.defaultEventInfo.eventTimeZone = this.agendaTimeZone;
  };

  private checkAttendeeListLegal(oldEventInfo: AgendaEventInfo, eventInfo: AgendaEventInfo): boolean {
    return (oldEventInfo.mAttendeeList === undefined && eventInfo.mAttendeeList !== undefined) ||
      (oldEventInfo.mAttendeeList !== undefined && eventInfo.mAttendeeList === undefined);
  }

  private checkArrLegal(oldEventInfo: AgendaEventInfo, eventInfo: AgendaEventInfo): boolean {
    return (oldEventInfo.checkValuesArray === undefined && eventInfo.checkValuesArray !== undefined) ||
      (oldEventInfo.checkValuesArray !== undefined && eventInfo.checkValuesArray === undefined);
  }

  private compareEventInfoAttendList(oldEventInfo: AgendaEventInfo, i: number, eventInfo: AgendaEventInfo): boolean {
    return (oldEventInfo.mAttendeeList[i]?.eventId !== eventInfo.mAttendeeList[i]?.eventId) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeName !== eventInfo.mAttendeeList[i]?.attendeeName) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeEmail !== eventInfo.mAttendeeList[i]?.attendeeEmail) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeStatus !== eventInfo.mAttendeeList[i]?.attendeeStatus) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeRelationship !== eventInfo.mAttendeeList[i]?.attendeeRelationship) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeType !== eventInfo.mAttendeeList[i]?.attendeeType) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeIdentity !== eventInfo.mAttendeeList[i]?.attendeeIdentity) ||
      (oldEventInfo.mAttendeeList[i]?.attendeeIdNamespace !== eventInfo.mAttendeeList[i]?.attendeeIdNamespace);
  }

  private compareEventInfoCheckArr(oldEventInfo: AgendaEventInfo, i: number, eventInfo: AgendaEventInfo): boolean {
    return (oldEventInfo.checkValuesArray[i]?.eventId !== eventInfo.checkValuesArray[i]?.eventId) ||
      (oldEventInfo.checkValuesArray[i]?.remindMinutes !== eventInfo.checkValuesArray[i]?.remindMinutes) ||
      (oldEventInfo.checkValuesArray[i]?.remindType !== eventInfo.checkValuesArray[i]?.remindType) ||
      (oldEventInfo.checkValuesArray[i]?.syncId !== eventInfo.checkValuesArray[i]?.syncId);
  }

  private compareEventInfoData(oldEventInfo: AgendaEventInfo, eventInfo: AgendaEventInfo): boolean {
    return (oldEventInfo.mId !== eventInfo.mId) ||
      (oldEventInfo.mCalendarId !== eventInfo.mCalendarId) ||
      (oldEventInfo.mTitle !== eventInfo.mTitle) ||
      (oldEventInfo.mLocation !== eventInfo.mLocation) ||
      (oldEventInfo.mDescription !== eventInfo.mDescription) ||
      (oldEventInfo.mStartDay !== eventInfo.mStartDay) ||
      (oldEventInfo.mEndDay !== eventInfo.mEndDay) ||
      (oldEventInfo.mFlag !== eventInfo.mFlag) ||
      (oldEventInfo.mDisplayColor !== eventInfo.mDisplayColor) ||
      (oldEventInfo.mDay !== eventInfo.mDay) ||
      (oldEventInfo.mEventType !== eventInfo.mEventType) ||
      (oldEventInfo.mBegin !== eventInfo.mBegin) ||
      (oldEventInfo.mEnd !== eventInfo.mEnd) ||
      (oldEventInfo.mIsAllDay !== eventInfo.mIsAllDay) ||
      (oldEventInfo.mIsMultiDayEvent !== eventInfo.mIsMultiDayEvent) ||
      (oldEventInfo.mIsSetDayHead !== eventInfo.mIsSetDayHead) ||
      (oldEventInfo.mEventCalendar !== eventInfo.mEventCalendar) ||
      (oldEventInfo.mEventImageType !== eventInfo.mEventImageType) ||
      (oldEventInfo.mIsCanceled !== eventInfo.mIsCanceled) ||
      (oldEventInfo.mSelfAttendeeStatus !== eventInfo.mSelfAttendeeStatus) ||
      (oldEventInfo.mIsMeetingEvent !== eventInfo.mIsMeetingEvent) ||
      (oldEventInfo.mPosition !== eventInfo.mPosition) ||
      (oldEventInfo.mRepeatRule !== eventInfo.mRepeatRule) ||
      (oldEventInfo.mHwextServiceType !== eventInfo.mHwextServiceType) ||
      (oldEventInfo.mHwextServiceVerified !== eventInfo.mHwextServiceVerified) ||
      (oldEventInfo.mHwextServiceUri !== eventInfo.mHwextServiceUri) ||
      (oldEventInfo.mHwextServicePkgName !== eventInfo.mHwextServicePkgName) ||
      (oldEventInfo.mHwextServiceMinVersion !== eventInfo.mHwextServiceMinVersion) ||
      (oldEventInfo.mHwextServiceDescription !== eventInfo.mHwextServiceDescription) ||
      (oldEventInfo.mCornerType !== eventInfo.mCornerType) ||
      (oldEventInfo.mIsHoliday !== eventInfo.mIsHoliday) ||
      (oldEventInfo.alertType !== eventInfo.alertType) ||
      (oldEventInfo.eventTimeZone !== eventInfo.eventTimeZone);
  }

  // 新建时初始化数据
  private initCreateInfo() {
    if (this.paramEventType !== CalendarContract.EventImportantType.NORMAL) {
      this.currentIndex = this.paramEventType
    } else {
      this.currentIndex = this.eventInfo.mImportantEventType
    }
    this.rawDefaultInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
    this.presetReminders(this.rawDefaultInfo);
    this.defaultEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.rawDefaultInfo);

    this.rawImportantInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
    this.rawImportantInfo.mIsAllDay = true;
    // 重要日不需要获取设置中默认提醒时间，后续会添加
    this.importantEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.rawImportantInfo);
    if (!this.importantEventInfo.isImportantEvent()) {
      this.importantEventInfo.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
    }
  }

  private requestNotificationThenRequestFocus(): void {
    NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS, () => {
      const result = focusControl.requestFocus(CompId.ADD_AGENDA_TITLE + '-' + this.timeStampKey);
      Log.info(TAG, `agenda title requestFocus ${result}`);
    });
  }

  /**
   * 更新场景
   */
  private async updateEventScene(
    eventInfo: AgendaEventInfo,
    value: Record<string, string | Number>
  ): Promise<boolean> {
    if (!eventInfo.mId) {
      return true;
    }

    const isSucceed: boolean = await EventService.INSTANCE.updateEventAndReminder(
      eventInfo.mId, this.checkValuesArray, this.valuesArrayChange, value, this.initReminders) as boolean;
    if (!isSucceed) {
      Log.error(TAG, 'update event error');
      return false;
    }
    this.updateAttachmentList(true);
    this.reportStatisticEvent(this.eventInfo.mId);
    return false;
  }

  /**
   * 新增场景
   */
  private async insertEventScene(value: Record<string, string | Number>): Promise<boolean> {
    const eventId: number = await EventService.INSTANCE.insertEvent(value) as number;
    let isSucceed: boolean = false;
    if (eventId > 0) {
      const nowAgendaInfo = this.getConfirmEventInfo();
      const instanceStartMills = nowAgendaInfo.mBegin ? nowAgendaInfo.mBegin : this.defaultStartDate;
      const instanceEndMills = nowAgendaInfo.mEnd ? nowAgendaInfo.mEnd : this.defaultEndDate;
      if (this.fromPage === CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT) {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_FORM_GET_AGENDA_ID }, { data: { 'mId': eventId } });
      }
      if (this.fromPage === CreateAgendaSheetFromPage.AGENDA_LIST_PAGE) {
        const eventData: emitter.EventData = {
          data: {
            eventId,
            instanceStartMills
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE }, eventData);
      }
      if (this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA ||
        this.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND) {
        let eventData: emitter.EventData = {
          data: {
            'eventId': eventId,
            'alwaysRefreshDetail': true,
            'oldEventId': this.oldEventId,
            'displayStartMills': instanceStartMills,
            'displayEndMills': instanceEndMills,
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
      }
      isSucceed = true;

      await this.insertAttachments(eventId);

      if (this.checkValuesArray?.length > 0) {
        isSucceed = await EventService.INSTANCE.insertReminder(eventId, this.checkValuesArray) as boolean;
      }
    }
    // todo 待提翻
    broadcastContentNotInterrupt(isSucceed ? '保存成功' : '保存失败');
    if (!isSucceed) {
      Log.error(TAG, 'create event error');
      return false;
    }
    return true;
  }

  private async insertAttachments(eventId: number) {
    if (this.getAttachmentViewModelListSize() > 0) {
      const info = await EventService.INSTANCE.queryEventById(eventId);
      const server = ServiceManager.getInstance().getService<AgendaAttachmentService>(ServiceEnum.ATTACHMENT_SERVICE);
      await server?.batchInsertAttachments(this.getAttachmentViewModelList(), info.uuid);
    }
  }

  getAttachmentViewModelList(): AttachmentInfo[] {
    if (this.currentIndex === AgendaType.DEFAULT) {
      return this.agendaAttachmentViewModel.dataSource.getDataList();
    } else {
      return this.importantAttachmentViewModel.dataSource.getDataList();
    }
  }

  getAttachmentViewModelListSize(): number {
    if (this.currentIndex === AgendaType.DEFAULT) {
      return this.agendaAttachmentViewModel.dataSource.totalCount();
    } else {
      return this.importantAttachmentViewModel.dataSource.totalCount();
    }
  }
}