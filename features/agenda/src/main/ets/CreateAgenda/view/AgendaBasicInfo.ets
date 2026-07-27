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
  AgendaEventInfo,
  AgendaService,
  AgendaUtil,
  BigFontSize,
  CalendarContract,
  CalendarDate,
  CalendarUtils,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  EmptyUtils,
  FontSizeScaleUtils,
  getAdaptImportantTime,
  GlobalDataKeys,
  GlobalThis,
  I18nUtil,
  InstanceService,
  Log,
  LunarDateUtil,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  QueryInfo,
  SafeUtil,
  ServiceEnum,
  ServiceManager,
  ThrottleFunction,
  TimeZoneUtil
} from '@app/common';

import { ChangeFlag, DateAndTimePicker, TimePoint } from '../../components/DateAndTimePicker';
import { DividerLine } from './DividerLine';
import { ConflictingAgenda } from './ConflictingAgenda';
import { LengthMetrics } from '@kit.ArkUI';
import { Recurrence } from '@app/feature.repeatrule';
import { AllDayContent } from './AllDayContent';
import lazy { LocationSetupAbility } from './LocationSetupAbility';
import { i18n } from '@kit.LocalizationKit';
import { emitter } from '@kit.BasicServicesKit';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import accessibility from '@ohos.accessibility';

const DELAY = 200; // 防抖
const TAG = 'AgendaBasicInfo';

@Component
export struct AgendaBasicInfo {
  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageLink('language') @Watch('on24HourClockOrLanguageChanged') language: string = '';

  //标题地点输入光标颜色
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('is24HourClock') @Watch('on24HourClockOrLanguageChanged') is24Hour: boolean = I18nUtil.is24HourClock();

  @Link @Watch('onEventInfoChanged') eventInfo: AgendaEventInfo;

  // 是否重要日卡片选择页面跳转过来
  @Prop fromImportantSelect: boolean = false;

  // 是否快速创建
  @Prop isQuickCreate: boolean = false;

  @Prop agendaTimeZoneOffset: string;

  // 改变弹窗内容是否编辑过的状态
  private changeEditedFlag: () => void = () => {
  };

  @State mTitle: string = '';

  @State mLocation: string = '';

  @State mFormatLocation: string = '';

  @State isLocationAbility: boolean = false;

  @State mLatitude: number = -1;

  @State mLongitude: number = -1;

  @State isToggleOn: boolean = false;

  @State xMirror: boolean = false; // x镜像

  titlePlaceholder: ResourceStr = '';

  // 外部传入起始日期时间戳
  @Prop startTimeStamp: number = -1;

  // 外部传入结束日期时间戳
  @Prop endTimeStamp: number = -1;

  // 外部传入重要日日期时间戳
  @Prop importantTimeStamp: number = -1;

  eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR;

  // 开始时间日期
  private startDate: CalendarDate = new CalendarDate();

  // 结束时间日期
  private endDate: CalendarDate = new CalendarDate();

  // 重要日日期
  private importantDate: CalendarDate = new CalendarDate()

  // 开始和结束时间的差值
  private timeRange : number = MILLS_PER_HOUR;

  // 是否是编辑页面
  @Prop isEditMode: boolean = false;

  @State isDefaultFocus: boolean = true;

  @StorageLink('initSelectedStartDate') initSelectedStartDate: CalendarDate = new CalendarDate();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private recurrence: Recurrence = new Recurrence();

  public onImportantDateChanged: () => void = (): void => {};

  private timeStampKey: number = Date.now(); // 用于拉起键盘防止id重复的key

  startDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DateAndTimePicker({
      confirm: (date) => {
        this.updateStartDate(date);
        this.initSelectedStartDate = new CalendarDate(date);
        this.getConflictingAgenda();
        this.changeEditedFlag();
      },
      selectedDateTime: this.getSelectedStartDateTime(),
      showTimePicker: !this.isToggleOn,
      agendaType: this.eventInfo.mImportantEventType,
      timePoint: TimePoint.START,
      changeFlag: this.eventInfo.mId ? ChangeFlag.EDIT : ChangeFlag.INSERT,
      eventCalendarType: this.eventInfo.mEventCalendar,
      eventInfo: this.eventInfo,
      fromImportantSelect: this.fromImportantSelect,
      isEditMode: this.isEditMode
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
  });

  endDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DateAndTimePicker({
      confirm: (date) => {
        this.updateEndDate(date);
        this.getConflictingAgenda();
        this.changeEditedFlag();
      },
      selectedStartDate: this.getSelectedStartDateTime(),
      selectedDateTime: this.getSelectedEndDateTime(),
      showTimePicker: !this.isToggleOn,
      agendaType: this.eventInfo.mImportantEventType,
      timePoint: TimePoint.END,
      changeFlag: this.eventInfo.mId ? ChangeFlag.EDIT : ChangeFlag.INSERT,
      eventInfo: this.eventInfo,
      eventCalendarType: this.eventInfo.mEventCalendar,
      fromImportantSelect: this.fromImportantSelect,
      isEditMode: this.isEditMode
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
  });

  singleDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DateAndTimePicker({
      confirm: (date) => {
        this.getImportantDate(date);
        this.initSelectedStartDate = new CalendarDate(date);
        this.agendaTitleDayOffset();
      },
      selectedDateTime: this.importantDate.getDateInfoByCalendar(),
      showTimePicker: false,
      agendaType: this.eventInfo.mImportantEventType,
      timePoint: TimePoint.DATE,
      changeFlag: this.eventInfo.mId ? ChangeFlag.EDIT : ChangeFlag.INSERT,
      eventInfo: this.eventInfo,
      eventCalendarType: this.eventInfo.mEventCalendar,
      fromImportantSelect: this.fromImportantSelect,
      isEditMode: this.isEditMode
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
  });

  @Prop @Watch('refreshTimeText') agendaTimeZone: string;

  @Prop secondTimeZone: string;

  @State startTimeText: string = this.getTimeText(this.startDate, this.secondTimeZone);

  @State endTimeText: string = this.getTimeText(this.endDate, this.secondTimeZone);

  @State startTimezoneText: string = '';

  @State endTimezoneText: string = '';

  @State importantTimeText: string = this.getTimeText(this.importantDate);

  @State isDefaultAgenda: boolean = true;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 全局统一的展示日期时间戳
  @StorageProp(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  // 冲突日程列表
  @Consume conflictingAgendaList: AgendaEventInfo[];

  private needAutoFocus: boolean = DeviceConfig.instance().config.needAutoFocus;

  // displayDate 的前一天
  private yesterdayOfDisplayDate: CalendarDate = new CalendarDate(this.displayDate - MILLS_PER_DAY);

  // 日程列表查询起始日期
  private rangeBegin: CalendarDate =
    new CalendarDate(this.yesterdayOfDisplayDate.getFullYear() - 1, this.yesterdayOfDisplayDate.getMonth(),
      this.yesterdayOfDisplayDate.getDate());

  // 日程列表查询终止日期
  private rangeEnd: CalendarDate = new CalendarDate(this.yesterdayOfDisplayDate.getFullYear() + 2,
    this.yesterdayOfDisplayDate.getMonth(),
    this.yesterdayOfDisplayDate.getDate());

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.closeDialogController();
  }

  aboutToAppear() {
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    this.startDate.setTime(this.startTimeStamp);
    this.endDate.setTime(this.endTimeStamp);
    this.importantDate.setTime(this.importantTimeStamp);

    this.timeRange = this.endDate.getTime() - this.startDate.getTime();
    this.importantTimeText = this.getDateText(this.importantDate, false);

    Log.info(TAG, `aboutToAppear startTimeText:${this.startTimeText} endTimeText:${this.endTimeText}`);
    this.isDefaultAgenda = this.eventInfo.mImportantEventType === CalendarContract.EventImportantType.NORMAL;
    if (!this.isEditMode) {
      this.agendaTitleDayOffset();
    }
    this.getConflictingAgenda();
    this.registerIntelligentCreate();
    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);

    Log.info(TAG, `aboutToAppear ${this.agendaTimeZone}-${this.secondTimeZone}`)

    this.refreshTimeText()

  }

  aboutToDisappear() {
    this.emitterCollector.off();
    this.closeDialogController();
    this.changeEditedFlag = () => {};
  }

  closeDialogController() {
    this.startDialogController?.close();
    this.endDialogController?.close();
    this.singleDialogController?.close();
    this.startDialogController = null;
    this.endDialogController = null;
    this.singleDialogController = null;
  }

  private onEventInfoChanged() {
    this.refreshTimeText();
    if (this.eventInfo.isImportantEvent()) {
      this.agendaTitleDayOffset();
    }
  }

  private getSelectedStartDateTime() {
    // DateAndTimePicker不支持时区，日程时间以日程时区为准，选择时间时，需要以年/月/日/时/分/秒转换
    const date = new CalendarDate(this.startDate.getTime());
    date.setTimeZone(this.agendaTimeZone);
    return date.getDateInfoByCalendar();
  }

  private getSelectedEndDateTime() {
    // DateAndTimePicker不支持时区，日程时间以日程时区为准，选择时间时，需要以年/月/日/时/分/秒转换
    let time = this.isToggleOn && this.isEditMode ? this.endDate.getTime() - MILLS_PER_DAY : this.endDate.getTime();
    const date = new CalendarDate(time);
    date.setTimeZone(this.agendaTimeZone);
    return date.getDateInfoByCalendar();
  }

  private registerIntelligentCreate() {
    let refreshBasicInfo = (eventData: emitter.EventData) => {
      Log.info(TAG, `start refreshBasicInfo.`);
      if (!eventData.data) {
        Log.info(TAG, 'No Valid eventData!');
      } else {
        this.mTitle = eventData.data.refreshTitle;
        this.mLocation = eventData.data.refreshLocation;
        this.isToggleOn = eventData.data.refreshIsAllDay;
        this.startTimeStamp = eventData.data.refreshBegin ? eventData.data.refreshBegin : this.startTimeStamp;
        this.startDate = eventData.data.refreshBegin ? new CalendarDate(eventData.data.refreshBegin) : this.startDate;
        this.endTimeStamp = this.startTimeStamp + MILLS_PER_HOUR;
        this.endDate = eventData.data.refreshEnd ? new CalendarDate(eventData.data.refreshEnd)
          : new CalendarDate(this.startDate.getTime() + MILLS_PER_HOUR);
        this.eventInfo.mEnd = this.eventInfo.mBegin + MILLS_PER_HOUR;
        if (this.isToggleOn) {
          this.startTimeText = this.getDateText(this.startDate, false);
          this.endTimeText = this.getDateText(this.endDate, true);
        } else {
          this.refreshTimeText();
        }
        this.initSelectedStartDate = this.startDate;
        this.getConflictingAgenda();
      }
    }
    this.emitterCollector.on({ eventId: CommonInnerEvent.INTELLIGENT_REFRESH }, refreshBasicInfo);
  }

  /**
   * 获取当前时间段内冲突日程列表
   */
  async getConflictingAgenda() {
    // 快速切换table栏时，冲突日程提示框会闪烁
    // 此处限制只触发一次数据加载
    if (!this.isDefaultAgenda) {
      return;
    }
    const queryInfo: QueryInfo = {
      startTime: this.rangeBegin.getTime(),
      endTime: this.rangeEnd.getTime(),
      useCalendarUuid: true
    };
    const result = await InstanceService.INSTANCE.queryInstanceAsync(queryInfo);
    if (result.length === 0) {
      return;
    }
    const tempList: AgendaEventInfo[] = [];
    const startDateTime = this.startDate.getTime();
    const endDateTime = this.endDate.getTime();
    result.forEach(item => {
      if (!((item.mBegin <= startDateTime && item.mEnd <= startDateTime) ||
        (item.mBegin >= endDateTime && item.mEnd >= endDateTime)) &&
        !item.mIsAllDay && this.eventInfo.mId !== item.mId) {
        item.setFlag(DateUtil.getJulianDay(startDateTime));
        item.isConflict = true;
        tempList.push(item);
      }
    })
    this.conflictingAgendaList = tempList;
    Log.info(TAG, `conflictingAgendaList.length = ${this.conflictingAgendaList.length}`);
  }

  getStartTimeText(startDate: CalendarDate, timeZone?: string): string {
    let startTimeText: string = ''
    if (this.isToggleOn) {
      startTimeText = this.getDateText(startDate, false);
      return startTimeText;
    }
    startTimeText = this.getDateText(startDate, false, timeZone) + ' ' + this.getTimeText(startDate, timeZone);
    return startTimeText;
  }

  getEndTimeText(endDate: CalendarDate, timeZone?: string): string {
    if (this.isToggleOn) {
      return this.getDateText(endDate, true);
    }
    let endTimeText = this.getTimeText(endDate, timeZone);
    if (!CalendarUtils.isSameDay(endDate.getTime(), this.startDate.getTime())) {
      endTimeText = this.getDateText(endDate, true) + ' ' + endTimeText;
    }
    return endTimeText;
  }

  getImportantTimeText(importantDate: CalendarDate): string {
    return this.getDateText(importantDate, false);
  }

  getDateText(date: CalendarDate, isEndTime: boolean, timezone?: string): string {
    let now = new CalendarDate();
    let option: Record<string, string> = { 'month': 'long', 'day': 'numeric', }
    if (timezone) {
      option['timeZone'] = timezone
    }
    if (date.getFullYear() !== now.getFullYear()) {
      option = { 'year': 'numeric', 'month': 'long', 'day': 'numeric' }
      if (timezone) {
        option['timeZone'] = timezone
      }
    }
    const isSameDay = CalendarUtils.isSameDay(this.endDate.getTime(), this.startDate.getTime());
    const isNeedRewrite = this.isToggleOn && isEndTime && this.isEditMode && !isSameDay;
    if (this.eventInfo.mEventCalendar == CalendarContract.AgendaCalendarType.LUNAR) {
      return LunarDateUtil.getLunarDate(isNeedRewrite ?
        new CalendarDate(date.getTime() - MILLS_PER_DAY) : date);
    }
    return DateUtil.intlDateFormatChineseStyle(isNeedRewrite ?
      new CalendarDate(date.getTime() - MILLS_PER_DAY) : date, option);
  }

  getTimezoneDateText(date: CalendarDate, isEndTime: boolean, timezone?: string, weekday?: boolean): string {
    let now = new CalendarDate();
    let option: Record<string, string> = {
      'month': 'long',
      'day': 'numeric',
    }
    if (date.getFullYear() !== now.getFullYear()) {
      option = {
        'year': 'numeric',
        'month': 'long',
        'day': 'numeric',
      }
    }
    if(timezone){
      option['timeZone'] = timezone
    }
    if (weekday) {
      option['weekday'] = 'short'
    }
    const isSameDay = CalendarUtils.isSameDay(this.endDate.getTime(), this.startDate.getTime());
    const isNeedRewrite = this.isToggleOn && isEndTime && this.isEditMode && !isSameDay;
    if (this.eventInfo.mEventCalendar == CalendarContract.AgendaCalendarType.LUNAR) {
      return LunarDateUtil.getLunarDate(isNeedRewrite ?
        new CalendarDate(date.getTime() - MILLS_PER_DAY) : date);
    }
    return DateUtil.intlDateFormatChineseStyle(isNeedRewrite ?
      new CalendarDate(date.getTime() - MILLS_PER_DAY) : date, option);
  }

  getTimeText(date: CalendarDate, timezone?: string): string {
    const option: DateTimeOptions = {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !this.is24Hour,
    }
    timezone ? option.timeZone = timezone : '';
    const text = DateUtil.intlDateFormatChineseStyle(date, option);
    return text;
  }

  /**
   * 获取开始时间，并根据界面的时间差值，计算结束时间
   *
   * @param date 开始时间
   */
  updateStartDate(date: Date) {
    // DateAndTimePicker不支持时区，日程时间以日程时区为准，选择时间时，需要以年/月/日/时/分/秒转换
    const resultDate = new CalendarDate();
    resultDate.setTimeZone(this.agendaTimeZone)
    resultDate.set(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(),
      date.getSeconds(), date.getMilliseconds());

    this.startDate = new CalendarDate(resultDate.getTime());
    this.endDate = new CalendarDate(resultDate.getTime() + this.timeRange);
    this.eventInfo.mBegin = Math.trunc(
      this.startDate.getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    this.eventInfo.mEnd = Math.trunc(
      this.endDate.getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    this.refreshTimeText();
  }

  /**
   * 获取结束时间，重新计算界面的时间差值
   *
   * @param date 开始时间
   */
  updateEndDate(date: Date) {
    // DateAndTimePicker不支持时区，日程时间以日程时区为准，选择时间时，需要以年/月/日/时/分/秒转换
    const resultDate = new CalendarDate();
    resultDate.setTimeZone(this.agendaTimeZone)
    resultDate.set(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours(), date.getMinutes(),
      date.getSeconds(), date.getMilliseconds());

    const allDayTime = this.isToggleOn && this.isEditMode ? MILLS_PER_DAY : 0;
    if (resultDate.getTime() <= this.startDate.getTime()) { // 结束时间小于开始时间的情况
      if (this.isToggleOn) { // 全天日程
        if (resultDate.getMonth() !== this.startDate.getMonth() || resultDate.getFullYear() !== this.startDate.getFullYear()) {
          // 月份或者年份不同，直接设置成当前天数
          this.endDate = new CalendarDate(this.startDate.getDateInfoByCalendar());
        } else if (this.startDate.getDate() === resultDate.getDate()) {
          // 同一天，直接设置成相同的时间
          this.endDate = new CalendarDate(this.startDate.getTime());
        } else {
          // 不是同一天，原时间 +5 分钟
          this.endDate = new CalendarDate(this.startDate.getTime() + MILLS_PER_MINUTE * 5);
        }
      } else {
        // 新规格，只需要保证结束时间不小于开始时间即可
        this.endDate = new CalendarDate(this.startDate.getTime());
      }
    } else {
      this.endDate = new CalendarDate(resultDate.getTime() + allDayTime);
    }
    this.timeRange = this.endDate.getTime() - this.startDate.getTime();
    Log.info(TAG, `The range of Time is ${this.timeRange}`);
    this.eventInfo.mEnd = Math.trunc(
      this.endDate.getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    this.refreshTimeText();
  }

  /**
   * 获取日期，重新计算界面的时间差值
   *
   * @param date 重要日时间
   */
  getImportantDate(date: Date) {
    this.importantDate = new CalendarDate(date.getTime());
    this.importantTimeText = this.getImportantTimeText(this.importantDate);
    this.eventInfo.mBegin = this.importantDate.getTime();
    this.eventInfo.mEnd = this.eventInfo.mBegin + MILLS_PER_DAY;
    if (this.onImportantDateChanged) {
      this.onImportantDateChanged();
    }
  }

  on24HourClockOrLanguageChanged(): void {
    this.refreshTimeText();
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
  }

  @Builder
  BuildAgendaTitle() {
    Row() {
      TextArea({ placeholder: this.titlePlaceholder, text: $$this.mTitle })
        .maxLength(1001)
        .placeholderFont({ size: 16 })
        .backgroundColor(Color.Transparent)
        .selectedBackgroundColor(this.themeColor)
        .fontWeight(FontWeight.Medium)
        .caretColor(this.themeColor)
        .constraintSize({ maxHeight: '48fp' })
        .id(CompId.ADD_AGENDA_TITLE)
        .key(CompId.ADD_AGENDA_TITLE + '-' + this.timeStampKey)
        .lineHeight(25)// 藏语维语大字体下出现截断 增加行高和最大高度
        .constraintSize({ maxHeight: this.isChangeLayout() ? 56 * (this.fontSizeScale + 1) : 48 * this.fontSizeScale })
        .onAppear(() => {
          SafeUtil.setTimeout(() => {
            this.requestFocusIfNeed();
          }, 1000)
          // 无障碍模式下 默认本组件会将焦点抢占
          let eventInfo: accessibility.EventInfo = ({
            type: 'requestFocusForAccessibility',
            bundleName: 'com.openharmony.calendar',
            triggerAction: 'common',
            customId: CompId.ADD_AGENDA_TITLE + '-' + this.timeStampKey
          });
          accessibility.sendAccessibilityEvent(eventInfo).then(() => {
            Log.info(TAG, `sendAccessibilityEvent Success`);
            // 无障碍完全聚焦标题后，取消默认焦点，使左滑走焦正常
            SafeUtil.setTimeout(() => {
              this.isDefaultFocus = false;
            }, 300)
          });
        })
        .accessibilityDefaultFocus(this.isDefaultFocus)
        .onClick(() => {
          this.mTitle = this.eventInfo.mTitle;
        })
        .onEditChange((isEditing: boolean) => {
          Log.info(TAG, `agenda title editing=${isEditing}`);
          if (isEditing) {
            this.mTitle = this.eventInfo.mTitle;
          } else {
            this.agendaTitleDayOffset();
          }
        })
        .onChange((value) => {
          if (value.length === 1001) {
            this.mTitle = this.mTitle.substring(0, 1000)
            showToast($r('app.string.content_length_exceeds_the_maximum'));
            return;
          }
          ThrottleFunction.instance().debounceInstant(TAG, () => {
            let str = value.trim();
            if (this.fromImportantSelect || this.eventInfo.isImportantEvent()) {
              str = str.split('·')[0].trim();
            }
            if (str === this.eventInfo.mTitle) {
              return;
            }
            const changeValue = str;
            this.eventInfo.mTitle = changeValue;
            this.mTitle = changeValue;
            this.changeEditedFlag();
          }, DELAY);
        })
        .padding({
          top: 0,
          bottom: 0,
          left: this.isChangeLayout() ? 12 : 8,
          right: this.isChangeLayout() ? 12 : 8
        })
        .margin({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          left: 0,
          right: 0
        })// textArea自带圆角，影响光标
        .borderRadius(0)
        .layoutWeight(1)
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  /**
   * 创建重要日时标题联想距离当前时间还剩多少天
   */
  agendaTitleDayOffset() {
    const server = ServiceManager.getInstance().getService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
    if (!server) {
      Log.warn(TAG, `agendaTitleDayOffset get null AgendaService!`);
      return;
    }
    this.eventInfo.mOriginalBegin = this.eventInfo.mBegin;
    let instanceTime: number = getAdaptImportantTime(this.eventInfo.mEventCalendar, this.eventInfo.mBegin,
      this.eventInfo.mRepeatRule, new CalendarDate());
    this.mTitle = server.agendaTitleDayOffset(this.eventInfo, instanceTime, Date.now());
  }

  // 新建页面半模态
  @Builder
  buildLocationSetupAbility() {
    Column() {
      LocationSetupAbility({
        isLocationAbility: this.isLocationAbility,
        mLocation: this.mLocation,
        mLatitude: this.mLatitude,
        mLongitude: this.mLongitude
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  BuildAgendaLocation() {
    Row() {
      TextArea({
        placeholder: this.isQuickCreate ? $r('app.string.add_location') : $r('app.string.hint_where'),
        text: AgendaUtil.getLocation(this.mLocation)
      })
        .placeholderFont({ size: 16 })
        .backgroundColor(Color.Transparent)
        .caretColor(this.themeColor)
        .selectedBackgroundColor(this.themeColor)
        .constraintSize({ maxHeight: 56 * this.fontSizeScale })
        .fontWeight(FontWeight.Medium)
        .decoration(!AgendaUtil.isLocationValid(this.mLatitude, this.mLongitude) ?
          { type: TextDecorationType.None, color: $r('sys.color.font_secondary') } :
          { type: TextDecorationType.Underline, color: $r('sys.color.font_secondary') })
        .onClick(() => {
          if (this.isQuickCreate) {
            return;
          }
          this.isLocationAbility = true;
        })
        .accessibilityText(EmptyUtils.isEmptyString(AgendaUtil.getLocation(this.mLocation))
          ? GlobalThis.getResourceStr($r('app.string.hint_where')) : AgendaUtil.getLocation(this.mLocation))
        .accessibilityDescription(GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
        .bindSheet($$this.isLocationAbility, this.buildLocationSetupAbility(), {
          height: SheetSize.LARGE,
          detents: [SheetSize.LARGE, 0, 0],
          dragBar: false,
          showClose: false,
          preferType: SheetType.CENTER
        })
        .onChange((value) => {
          this.eventInfo.mLocation = value;
          this.eventInfo.mLatitude = this.mLatitude;
          this.eventInfo.mLongitude = this.mLongitude;
          this.changeEditedFlag();
          ThrottleFunction.instance().throttle(TAG, (): void => {
            this.throttleToReportAgendaLocation();
          }, 2000);
        })
        .padding({
          top: 0,
          bottom: 0,
          left: this.isChangeLayout() ? 12 : 8,
          right: this.isChangeLayout() ? 12 : 8
        })
        .margin({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          left: 0,
          right: 0
        })// textArea自带圆角，影响光标
        .borderRadius(0)
        .id(CompId.ADD_AGENDA_LOCATION)
        .enableKeyboardOnFocus(false)
        .width('90%')
      this.buildClearLocationButton();
    }
    .width('100%')
    .constraintSize({ minHeight: 48 })
  }

  @Builder
  buildClearLocationButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .flexShrink(1)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          18
        ))
        .fontColor([$r('sys.color.icon_fourth')])
    }
    .backgroundColor(Color.Transparent)
    .align(Alignment.End)
    .margin({ left: this.xMirror ? 0 : 4, right: this.xMirror ? 4 : 8 })
    .visibility(this.mLocation === '' ? Visibility.None : Visibility.Visible)
    .onClick(() => {
      this.mLocation = '';
      this.mLatitude = -1;
      this.mLongitude = -1;
    })
    .accessibilityText($r('app.string.delete_label'))
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  startDateBuilder() {
    Text($r('app.string.start_date'))
      .align(Alignment.Start)
      .fontSize(16)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .margin({
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        top: this.isChangeLayout() ? LengthMetrics.vp(
          FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
      })
    Row() {
      Column() {
        Text(this.startTimeText)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .opacity(0.6)
          .constraintSize({ maxWidth: '90%' })
          .fontColor($r('sys.color.font_primary'))
          .id(CompId.ADD_AGENDA_START_TIME_TEXT)
          .margin({
            start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0),
            bottom: this.isChangeLayout() ? LengthMetrics.vp(
              FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
            top: this.isChangeLayout() ? LengthMetrics.vp(
              FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
          })
        if((this.secondTimeZone !== this.agendaTimeZone) && !this.isToggleOn){
          Text(this.startTimezoneText)
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .opacity(0.6)
            .constraintSize({ maxWidth: '90%' })
            .fontColor($r('sys.color.font_primary'))
            .id(CompId.ADD_AGENDA_END_TIME_TEXT)
            .margin({
              start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0),
              bottom: this.isChangeLayout() ? LengthMetrics.vp(
                FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
              top: this.isChangeLayout() ? LengthMetrics.vp(
                FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
            })
        }
      }
      .alignItems(HorizontalAlign.End)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
    }
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
    .margin({ top: LengthMetrics.vp(2) ,bottom: LengthMetrics.vp(2)})
  }

  @Builder
  StartDateVerticalLayout() {
    Column() {
      this.startDateBuilder();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .hoverEffect(HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      }
    , normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .onClick(() => {
      this.startDialogController?.open();
    })
    .id(CompId.ADD_AGENDA_START_TIME);
  }

  @Builder
  BuildStartDate() {
    if (this.isChangeLayout()) {
      this.StartDateVerticalLayout();
    } else {
      Row() {
        this.startDateBuilder();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
      .constraintSize({ minHeight: 48 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .onClick(() => {
        this.startDialogController?.open();
      })
      .id(CompId.ADD_AGENDA_START_TIME);
    }
  }

  @Builder
  endDateBuilder() {
    Text($r('app.string.end_date'))
      .align(Alignment.Start)
      .fontSize(16)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .margin({
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        top: this.isChangeLayout() ? LengthMetrics.vp(
          FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
      })

    Row() {
      Column(){
        Text(this.endTimeText)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .opacity(0.6)
          .constraintSize({ maxWidth: '90%' })
          .fontColor($r('sys.color.font_primary'))
          .id(CompId.ADD_AGENDA_END_TIME_TEXT)
          .margin({
            start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0),
            bottom: this.isChangeLayout() ? LengthMetrics.vp(
              FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
            top: this.isChangeLayout() ? LengthMetrics.vp(
              FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
          })
        if((this.secondTimeZone !== this.agendaTimeZone) && !this.isToggleOn){
          Text(this.endTimezoneText)
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .opacity(0.6)
            .constraintSize({ maxWidth: '90%' })
            .fontColor($r('sys.color.font_primary'))
            .id(CompId.ADD_AGENDA_END_TIME_TEXT)
            .margin({
              start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0),
              bottom: this.isChangeLayout() ? LengthMetrics.vp(
                FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
              top: this.isChangeLayout() ? LengthMetrics.vp(
                FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
            })
        }
      }
      .alignItems(HorizontalAlign.End)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
    }
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
    .margin({ top: LengthMetrics.vp(2) ,bottom: LengthMetrics.vp(2)})
  }

  @Builder
  EndDateVerticalLayout() {
    Column() {
      this.endDateBuilder();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .hoverEffect(HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      }
    , normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .onClick(() => {
      this.endDialogController?.open();
    })
    .id(CompId.ADD_AGENDA_END_TIME)
  }

  @Builder
  BuilderEndDate() {
    if (this.isChangeLayout()) {
      this.EndDateVerticalLayout();
    } else {
      Row() {
        this.endDateBuilder();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
      .constraintSize({ minHeight: 48 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'));
        }
      , normal: {
          .backgroundColor(Color.Transparent);
        }
      })
      .onClick(() => {
        this.endDialogController?.open();
      })
      .id(CompId.ADD_AGENDA_END_TIME)
    }
  }

  @Builder
  singleDateBuilder() {
    Text($r('app.string.date'))
      .align(Alignment.Start)
      .fontSize(16)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .margin({
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        top: this.isChangeLayout() ? LengthMetrics.vp(
          FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
      })

    Row() {
      Text(this.importantTimeText)
        .fontSize(14)
        .fontWeight(FontWeight.Regular)
        .opacity(0.6)
        .constraintSize({ maxWidth: '90%' })
        .fontColor($r('sys.color.font_primary'))
        .id(CompId.ADD_AGENDA_END_TIME_TEXT)
        .margin({
          start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0),
          bottom: this.isChangeLayout() ? LengthMetrics.vp(
            FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
          top: this.isChangeLayout() ? LengthMetrics.vp(4) : LengthMetrics.vp(0)
        })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
    }
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  singleDateVerticalLayout() {
    Column() {
      this.singleDateBuilder();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .hoverEffect(HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      }
    , normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .onClick(() => {
      this.singleDialogController?.open();
      focusControl.requestFocus(CompId.ADD_AGENDA_IMPORTANT_TIME);
    })
    .id(CompId.ADD_AGENDA_IMPORTANT_TIME);
  }

  @Builder
  BuildSingleDate() {
    if (this.isChangeLayout()) {
      this.singleDateVerticalLayout();
    } else {
      Row() {
        this.singleDateBuilder();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
      .constraintSize({ minHeight: 48 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .onClick(() => {
        this.singleDialogController?.open();
        focusControl.requestFocus(CompId.ADD_AGENDA_IMPORTANT_TIME);
      })
      .id(CompId.ADD_AGENDA_IMPORTANT_TIME)
    }
  }

  @Builder
  BuildConflictingAgendaRow() {
    Row() {
      ConflictingAgenda({
        agendaList: $conflictingAgendaList,
      })
    }
    .padding({
      top: $r('sys.float.padding_level4'),
      bottom: $r('sys.float.padding_level4')
    })
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      this.BuildAgendaTitle();
      DividerLine({ paddingLeft: $r('sys.float.padding_level4'), paddingRight: $r('sys.float.padding_level4') });
      if (this.isDefaultAgenda) {
        this.BuildAgendaLocation();
        DividerLine({ paddingLeft: $r('sys.float.padding_level4'), paddingRight: $r('sys.float.padding_level4') });
        AllDayContent({
          eventInfo: this.eventInfo,
          isToggleOn: this.isToggleOn,
          toggleOnChange: () => {
            this.setAllDayTime();
            this.changeEditedFlag();
          }
        });
        DividerLine({ paddingLeft: $r('sys.float.padding_level4'), paddingRight: $r('sys.float.padding_level4') });
        this.BuildStartDate();
        DividerLine({ paddingLeft: $r('sys.float.padding_level4'), paddingRight: $r('sys.float.padding_level4') });
        this.BuilderEndDate();
      } else {
        this.BuildSingleDate();
      }
      if (this.conflictingAgendaList.length > 0 && this.isDefaultAgenda) {
        this.BuildConflictingAgendaRow();
      }
    }
    .id(CompId.AGENDA_BASIC_INFO)
    .padding({
      left: this.isQuickCreate ? 6 : 4,
      right: this.isQuickCreate ? 6 : 4,
      top: this.isQuickCreate? 0 : 4,
      bottom: this.isQuickCreate ? 7 : 4
    })
    .backgroundColor(this.isQuickCreate ? $r('sys.color.ohos_id_color_list_card_bg') :
    $r('sys.color.comp_background_list_card'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
  }

  /**
   * 输入地址时，对打点操作进行限流
   */
  private throttleToReportAgendaLocation: () => void = () => {
    if (!this.isEditMode) {
    }
  };

  /**
   * 大屏切换tab时默认获焦
   */
  private requestFocusIfNeed() {
    if (!this.needAutoFocus) {
      return;
    }
    const result = focusControl.requestFocus(CompId.ADD_AGENDA_TITLE + '-' + this.timeStampKey);
    Log.info(TAG, `agenda title input requestFocus result = ${result}`);
  }

  refreshTimeText() {
    Log.info(TAG, `agendaTimeZoneChange: ${this.agendaTimeZone}-${this.secondTimeZone}`)

    this.startTimeText = this.getStartTimeText(this.startDate, this.agendaTimeZone);
    this.endTimeText = this.getEndTimeText(this.endDate, this.agendaTimeZone);
    this.importantTimeText = this.getImportantTimeText(this.importantDate);

    const timezoneOffset = TimeZoneUtil.getTimeZoneOffset(this.secondTimeZone, this.startDate.getTime()) / MILLS_PER_MINUTE;
    const timezoneText = TimeZoneUtil.processTimeZoneOffset(timezoneOffset);
    const startTimezoneText = this.getTimezoneDateText(this.startDate, false, this.secondTimeZone, true)
      + ' ' + this.getTimeText(this.startDate, this.secondTimeZone);
    this.startTimezoneText = `${startTimezoneText} ${timezoneText}`

    const endTimezoneText = this.getTimezoneDateText(this.endDate, false, this.secondTimeZone, true)
      + ' ' + this.getTimeText(this.endDate, this.secondTimeZone)
    this.endTimezoneText = `${endTimezoneText} ${timezoneText}`
  }

  /**
   * 设置全天时间
   * @description
   * 1. 该方法用于根据当前状态设置日程的全天时间
   * 2. 主要逻辑包括：
   *    - 设置日程的全天状态 (`mIsAllDay`)
   *    - 计算日程的日期范围（天数）
   *    - 根据当前状态 (`isToggleOn`) 处理不同的逻辑：
   *      - 如果为 `true`，设置开始和结束时间的文本显示
   *      - 如果为 `false` 且处于编辑模式：
   *        - 更新时区信息
   *        - 计算并设置新的开始时间和结束时间
   *        - 更新日程的开始和结束时间戳
   *    - 刷新时间文本显示
   */
  private setAllDayTime() {
    this.eventInfo.mIsAllDay = this.isToggleOn;
    let dayRange: number = Math.ceil((this.endDate.getTime() - this.startDate.getTime()) / MILLS_PER_DAY);
    if (this.isToggleOn) {
      this.startTimeText = this.getDateText(this.startDate, false);
      this.endTimeText = this.getDateText(this.endDate, true);
    } else {
      if (this.isEditMode) {
        this.agendaTimeZone = CalendarDate.timeZone;
        let eventData: emitter.EventData = {
          data: {
            'timezoneId': this.agendaTimeZone,
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.AGENDA_TIME_ZONE_CHANGED }, eventData);
        const startTimeStamp = this.getStartDateByCombine(this.startDate.getTime());
        this.startDate = new CalendarDate(startTimeStamp);
        const endTimeStamp = startTimeStamp + MILLS_PER_HOUR + MILLS_PER_DAY * (dayRange - 1);
        this.endDate = new CalendarDate(endTimeStamp);
        this.eventInfo.mBegin = Math.trunc(
          this.startDate.getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
        this.eventInfo.mEnd = Math.trunc(
          this.endDate.getTime() / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
      }
      this.refreshTimeText();
    }
  }

  /**
   * 根据传入的时间戳参数计算开始时间
   * @param dateTimestampParam 传入的时间戳参数
   * @returns 计算后的开始时间戳
   * @description
   * 1. 该方法用于根据传入的时间戳参数计算一个特定的开始时间
   * 2. 主要逻辑包括：
   *    - 获取当前时间的毫秒数
   *    - 计算当前时间在当天的时间偏移量（小时、分钟、秒部分）
   *    - 将传入时间的日期部分与当前时间的时间部分合并
   *    - 根据当前时间是否接近整点或半点，决定返回当前整点/半点或下一个整点/半点的时间戳
   * 3. 特殊情况处理：
   *    - 如果当前时间为整点或半点刚过一分钟内，默认返回当前整点或半点的时间戳
   *    - 如果超过一分钟，默认返回下一个整点或半点的时间戳
   */
  public getStartDateByCombine(dateTimestampParam: number): number {
    Log.info(TAG, `getStartDateByCombine, dateTimestampdateTimestampParam = ${dateTimestampParam}`);
    let nowTimeMills = dateTimestampParam;
    const halfHourMills = MILLS_PER_HOUR / 2;
    const now = new CalendarDate();
    const nowBeyondZeroTimeMills = now.getTime() - DateUtil.getStartOfDayTimeStamp();
    const beginOfDateParam = DateUtil.getStartOfDayTimeStamp(dateTimestampParam);
    const nowOfDateParam = new CalendarDate(beginOfDateParam + nowBeyondZeroTimeMills);
    nowTimeMills = nowOfDateParam.getTime();
    if (nowTimeMills % halfHourMills < MILLS_PER_MINUTE) {
      return Math.trunc(nowTimeMills / MILLS_PER_MINUTE) * MILLS_PER_MINUTE;
    }
    return Math.trunc(nowTimeMills / halfHourMills) * halfHourMills + halfHourMills;
  }
}