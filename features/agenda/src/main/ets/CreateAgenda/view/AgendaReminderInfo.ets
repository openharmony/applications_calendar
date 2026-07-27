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
  behaviorEvents,
  BigFontSize,
  CalendarContract,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  EventService,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  HiEventAction,
  HiEventParamsConfirm,
  I18nUtil,
  Log,
  ModeUtil,
  ReminderService,
  ReminderUtil,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  statisticEvents,
  UnusualMode,
  NotificationHelper,
} from '@app/common';
import {
  DEFAULT_ALL_DAY_REMINDER_OPTIONS,
  DEFAULT_REMINDER_OPTIONS,
  RadioListDialogOption
} from '@app/common.components';
import { ValuesBucket } from '@kit.ArkData';
import { DividerLine } from './DividerLine';
import { inputMethod } from '@kit.IMEKit';
import { RepeatRuleRow } from '@app/commons.repeatruleview';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ReminderDialog } from './ReminderDialog';
import { ChangeFlag } from '../../components/DateAndTimePicker';
import { ImportantAlertRow } from '../../AgendaDetail/view/ImportantAlertRow';
import { ReminderRow } from '../../AgendaPreview/view/ReminderRow';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'AgendaReminderInfo';
const NO_REMINDER_VALUE = -1;

@Component
export struct AgendaReminderInfo {
  // 默认提醒时间
  @StorageLink('defaultRemindTime') defaultRemindTime: number = 10;

  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') allDayEventsDefaultRemindTime: number = 0;

  @StorageLink('language') language: string = '';

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 日程信息
  @Prop @Watch('initializeCommon') mIsAllDay: boolean;

  private originalIsAllDay: boolean = false; // 编辑模式下初始值

  @Link eventInfo: AgendaEventInfo;

  // 当前弹框选中的value值
  @State value: number = 0;

  // 选中的value集合
  @Link @Watch('checkValuesArrayChange') checkValuesArray: CalendarContract.Reminders[];

  private originalReminderArray: CalendarContract.Reminders[] = []; // 编辑模式下初始值

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  @StorageProp(GlobalDataKeys.IS_NOTIFICATION_GRANTED) isNotificationGranted: boolean = false;

  // 是否重要日卡片选择页面跳转过来
  @Prop fromImportantSelect: boolean = false;

  // 添加卡片到桌面
  @State addCardToDesk: boolean = false;

  @Prop marginTop: number = 0;

  @State marginBottom: number = 0;

  // 重要提醒开关
  @Link isImportantAlert: boolean;

  @State reminderSeparator: string = '';

  @Prop isAgendaCollapse: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private selectedValues: number[] = [];

  private emitterCollector : EmitterCollector = new EmitterCollector();

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  private cardToMonthHandler: () => void = (): void => {
    this.dialogController?.close();
  };

  private closeDialog: () => void = (): void => {
    this.dialogController?.close();
  };

  private onRepeatChanged: () => void = (): void => {};

  // 弹框控制器
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: ReminderDialog({
      type: this.eventInfo.mImportantEventType,
      mIsAllDay: $mIsAllDay,
      value: $value,
      defaultArray: this.checkValuesArray.map(reminder=>reminder.remindMinutes),
      transferValue: (arr: number[]): void => this.transferValue(arr)
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
  });

  // 最大提醒列数
  private readonly maxColumns: number = 5;

  // 全天事件弹窗所有value值
  private allDayValues: number[] = [];

  // 默认事件弹窗所有label值
  private defaultValues: number[] = [];

  // 提醒列的index值
  private currentLabelIndex: number = 0;

  // 弹窗前的value值
  private oldValue: number = 0;

  // 是否在编辑态
  private isEditMode: boolean = false;

  // 是否在日程详情界面
  private isInDetailPage: boolean = false;

  // 默认 num 值
  private defaultNum: number = -1;

  private optionMap: Map<number, ResourceStr> = new Map();

  private allDayOptionMap: Map<number, ResourceStr> = new Map();

  //是否界面初始化
  private isInitializing: boolean = false;

  //svg模糊度

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  //展开屏断点
  private breakPoints: number = 620;


  onWindowWidthChange() {
    Log.info(TAG, `onWindowWidthChange: ${this.windowWidth}`)
  }

  // 钩子函数，传递给RadioList把选中的值通知过来
  transferValue(value: number[]) {
    this.selectedValues = value;
    Log.info(TAG, `transfered value:` + JSON.stringify(value));
    this.deleteReminderFromSelected().then(()=>{
      // 插入
      this.selectedValues.forEach(async value => {
        await this.tryInsertReminder(value);
      })
    })
  }

  // 根据当前选中的日程删除Reminder
  async deleteReminderFromSelected() {
    let notInPrevArray = this.checkValuesArray.filter(reminder => {
      return this.selectedValues.indexOf(reminder.remindMinutes) < 0;
    })
    notInPrevArray.forEach(async reminder => {
      let index: number | undefined = this.getReminderFromArray(reminder.remindMinutes);
      await this.deleteReminderAndRefreshView(reminder.id, index!);
    })
  }

  /**
   * 提醒时间改变
   *
   */
  async tryInsertReminder(minute: number) {
    Log.info(TAG, JSON.stringify(this.checkValuesArray));
    let index: number | undefined = this.getReminderFromArray(minute);
    if (index != undefined) {
      return;
    } else {
      Log.info(TAG, `insert new reminder for ${minute}`);
      this.insertReminderAndRefreshView(minute);
      this.reportRemindStatistic(minute, HiEventAction.EDIT)
    }
  }

  /**
   * 在日程详情页面时更新提醒类型
   */
  async alertTypeChange() {
    this.eventInfo.alertType = this.isImportantAlert
      ? CalendarContract.AgendaAlertType.IMPORTANT
      : CalendarContract.AgendaAlertType.NORMAL;
    if (this.isInDetailPage) {
      const value = {} as ValuesBucket;
      value[CalendarContract.EventsColumns.HW_EXT_ALERT_TYPE] = this.eventInfo.alertType;
      EventService.INSTANCE.updateByEventId(this.eventInfo.mId, value);

      let params: ReportHiEventParams = {
        IS_ON: this.eventInfo.alertType,
        TYPE: this.eventInfo.mImportantEventType,
        CHANGE_FLAG: ChangeFlag.DETAIL
      };
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaImportantAlert, params);
    }
  }

  // 插入到 checkArray 中，preserve order
  pushReminderByOrder(reminder: CalendarContract.Reminders) {
    for (let i = 0; i < this.checkValuesArray.length; i++) {
      if (reminder.remindMinutes < this.checkValuesArray[i].remindMinutes) {
        this.checkValuesArray.splice(i, 0, reminder);
        return;
      }
    }
    this.checkValuesArray.push(reminder);
    this.originalReminderArray = this.checkValuesArray;
  }

  /**
   * 插入提醒，触发视图刷新
   *
   */
  async insertReminderAndRefreshView(value: number) {
    if (value === NO_REMINDER_VALUE) {
      return;
    }
    let reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
    reminder = this.createReminder(this.eventInfo.mId, value, CalendarContract.RemindersRemindType.TYPE_ALERT);
    this.reportRemindStatistic(reminder.remindMinutes, HiEventAction.CREATE)
    if (this.isInDetailPage) {
      reminder.id = await ReminderService.INSTANCE.insertReminder(reminder) as number;
      if (reminder.id !== this.defaultNum) {
        Log.debug(TAG, `Insert reminder succeed reminder.id = ${reminder.id}`);
        this.pushReminderByOrder(reminder);
      }
    } else {
      let repeat: boolean = false;
      for (let tempReminder of this.checkValuesArray) {
        if (reminder.remindMinutes === tempReminder.remindMinutes) {
          repeat = true;
          break;
        }
      }
      if (repeat === false) {
        this.pushReminderByOrder(reminder);
      }
    }
  }

  /**
   * 删除提醒，触发视图刷新
   * @param reminderId 待删除的提醒 id
   * @param index 待删除提醒在列表中的 index 值
   *
   */
  async deleteReminderAndRefreshView(reminderId: number, index: number) {
    if (this.isInDetailPage) {
      let rowsDeleted: number = await ReminderService.INSTANCE.deleteReminderById(reminderId) as number;
      if (rowsDeleted > this.defaultNum + 1) {
        Log.debug(TAG, `Delete reminder succeed reminder.id = ${reminderId}, deleted rows = ${rowsDeleted}`);
        this.deleteCheck(index);
      }
    } else {
      this.deleteCheck(index);
    }
    this.originalReminderArray = this.checkValuesArray;
  }

  /**
   * 更新提醒，触发视图刷新
   *
   */
  async updateReminderAndRefreshView() {
    if (this.isInDetailPage) {
      let reminder: CalendarContract.Reminders = this.createReminder(
        this.checkValuesArray[this.currentLabelIndex].eventId,
        this.value,
        CalendarContract.RemindersRemindType.TYPE_ALERT
      );
      let rowsUpdated: number = await ReminderService.INSTANCE.updateReminderById(
        this.checkValuesArray[this.currentLabelIndex].id, reminder) as number;
      if (rowsUpdated > this.defaultNum + 1) {
        Log.debug(TAG, `Update reminder succeed reminder.id =
        ${this.checkValuesArray[this.currentLabelIndex].id}, updated rows = ${rowsUpdated}`);
        this.checkValuesArray[this.currentLabelIndex].remindMinutes = this.value;
        // 改变数组中 this.currentLabelIndex 位置元素的地址，触发视图刷新

        let t = {} as CalendarContract.Reminders;
        t.eventId = this.checkValuesArray[this.currentLabelIndex].eventId;
        t.remindMinutes = this.checkValuesArray[this.currentLabelIndex].remindMinutes;
        t.remindType = this.checkValuesArray[this.currentLabelIndex].remindType;
        t.syncId = this.checkValuesArray[this.currentLabelIndex].syncId;
        this.checkValuesArray[this.currentLabelIndex] = t;
      }
    } else {
      this.checkValuesArray[this.currentLabelIndex].remindMinutes = this.value;
      // 改变数组中 this.currentLabelIndex 位置元素的地址，触发视图刷新
      let t = {} as CalendarContract.Reminders;
      t.eventId = this.checkValuesArray[this.currentLabelIndex].eventId;
      t.remindMinutes = this.checkValuesArray[this.currentLabelIndex].remindMinutes;
      t.remindType = this.checkValuesArray[this.currentLabelIndex].remindType;
      t.syncId = this.checkValuesArray[this.currentLabelIndex].syncId;
      this.checkValuesArray[this.currentLabelIndex] = t;
    }
  }

  /**
   * 从提醒列表中获取提醒选项
   *
   */
  getReminderFromArray(targetRemindMinutes: number) {
    Log.info(TAG, `getReminderFromArray ${JSON.stringify(this.checkValuesArray.map(r=>r.remindMinutes))}`);
    for (let i = 0; i < this.checkValuesArray.length; i++ ) {
      Log.info(TAG, `${i}-${this.checkValuesArray[i].remindMinutes}`)
      if (this.checkValuesArray[i].remindMinutes === targetRemindMinutes) {
        return i;
      }
    }
    return undefined;
  }

  getResourceStr(resource: Resource) {
    return GlobalThis.getResourceStr(resource, this.language)
  }

  getPluralStr(resource: Resource, num: number) {
    return GlobalThis.getPluralStr(resource, num, this.language)
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  BuildReminderItem(item: CalendarContract.Reminders, index: number) {
    Row() {
      Text(ReminderUtil.getReminderText(item.remindMinutes, this.mIsAllDay, this.language))
        .accessibilityText(this.getAccessibilityText(item))
        .layoutWeight(1)
        .align(Alignment.Start)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            16
          ))
          .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
          .opacity($r('sys.float.alpha_primary'))
          .alignSelf(ItemAlign.Center)
      }
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.delete_dialog_button')))
      .width(40)
      .constraintSize({ minHeight: 40 })
      .hitTestBehavior(HitTestMode.Block)
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .backgroundColor(Color.Transparent)
      .id(CompId.CANCEL_SINGLE_REMIND)
      .onClick(() => {
        this.deleteReminderAndRefreshView(item.id, index);
      })
      .margin({ end: LengthMetrics.vp(2) })
    }
    .margin( {
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0)
    })
    .constraintSize({ minHeight: 48 })
    .layoutWeight(1)
    .width('100%')
  }

  private getAccessibilityText(item: CalendarContract.Reminders): string {
    return GlobalThis.getResourceStr($r('app.string.reminder_time')) +
        ReminderUtil.getReminderText(item.remindMinutes, this.mIsAllDay, this.language);
  }

  @Builder
  BuildReminderList() {
    ForEach(this.checkValuesArray, (item: CalendarContract.Reminders, index: number) => {
      Row() {
        this.BuildReminderItem(item, index);
      }
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .accessibilityText(this.getAccessibilityText(item))
      .constraintSize({ minHeight: 48 })
      .onClick(() => {
        this.currentLabelIndex = index;
        this.oldValue = this.checkValuesArray[index].remindMinutes === undefined
          ? 10
          : this.checkValuesArray[index].remindMinutes;
        this.value = this.oldValue;
        Log.log(TAG, `value: ${this.value}`);
        inputMethod.getController().hideTextInput();
        if (this.eventInfo?.isImportantCountDown()) {
          focusControl.requestFocus(CompId.NEW_IMPORTANT_EVENT);
        }
        setTimeout(() => {
          this.dialogController?.open();
          Log.log(TAG, `ReminderDialog alignment: ${this.dialogControllerOptions.alignment}, ReminderDialog offset: ${this.dialogControllerOptions.offset}`);
        }, 50)
      })
      .padding({
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        end: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0)
      })

      DividerLine({
        paddingLeft: $r('sys.float.padding_level4'),
        paddingRight: $r('sys.float.padding_level4')
      })
        .visibility((index + 1) === this.maxColumns ? Visibility.None : Visibility.Visible)
    })
  }

  @Builder
  buildColReminderButton() {
    Row() { // 此处的 row 作为 text 的容器，限制text的大小
      Text($r('app.string.preferences_reminder_title'))
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .padding({ start: LengthMetrics.vp(0), end: LengthMetrics.vp(8) })
        .layoutWeight(FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale) &&
          this.checkValuesArray.length > 0 ? 1 : undefined)
        .margin({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          bottom: 0
        })
    }
    this.buildSelectedReminderHints((FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale) ?
    TextAlign.Start : TextAlign.End), 1 )
  }

  @Builder
  buildRowReminderButton() {
    Row() { // 此处的 row 作为 text 的容器，限制text的大小
      Text($r('app.string.preferences_reminder_title'))
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .padding({ start: LengthMetrics.vp(0), end: LengthMetrics.vp(8) })
        .margin({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          bottom: 0
        })
    }
    this.buildSelectedReminderHints(TextAlign.End, undefined)
  }

  @Builder
  BuildAddReminder() {
    Row() {
      if (FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale) &&
        this.checkValuesArray.length > 0 &&
      this.windowWidth < this.breakPoints) {
        Column() {
          this.buildColReminderButton();
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 6, bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0) })
      } else {
        Row() {
          this.buildRowReminderButton();
        }.layoutWeight(1)
      }
    }
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      }
    , normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .onClick(() => {
      this.dialogController?.open();
    })
    .id(CompId.ADD_AGENDA_ADD_REMIND)
    .padding({
      start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
    })
  }

  @Builder
  BuildRepeatRuleAndEffectiveDateRow() {
    if (!this.isInDetailPage || (this.isInDetailPage && this.eventInfo.mRepeatRule !== '')) {
      if (!this.eventInfo.isImportantAnniversaries()) {
        DividerLine({
          paddingLeft: $r('sys.float.padding_level4'),
          paddingRight: $r('sys.float.padding_level4')
        })
      }
      RepeatRuleRow({
        rrule: this.eventInfo.mRepeatRule,
        disabled: this.isInDetailPage,
        routerName: this.routerName,
        onNewRuleSetCallback: (newRrule: string) => {
          this.eventInfo.mRepeatRule = newRrule;
          if (this.onRepeatChanged) {
            this.onRepeatChanged();
          }
        },
        onAgendaCalendarTypeChange: (value: number) => {
          this.eventInfo.mEventCalendar = value;
        },
        mIsAllDay: this.mIsAllDay,
        mEventInfo: this.eventInfo,
      });
    }
  }

  @Builder
  buildSelectedReminderHints(textAlign: TextAlign, layoutWeight?: number) {
    Row () {
      Text() {
        // 若日程本来没有提醒时间时，需要显示“无”
        if (this.checkValuesArray.length === 0) {
          Span($r('app.string.no_calendar_display_name'));
        } else {
          if (this.checkValuesArray.length > 0) {
            Span(ReminderUtil.getReminderText(this.checkValuesArray[0].remindMinutes, this.mIsAllDay, this.language))
          }
          if (this.checkValuesArray.length > 1) {
            Span(this.reminderSeparator)
            Span(ReminderUtil.getReminderText(this.checkValuesArray[1].remindMinutes, this.mIsAllDay, this.language))
          }
          if (this.checkValuesArray.length > 2 && !this.mIsAllDay) { //非全天日程可以显示三项
            Span(this.reminderSeparator)
            Span(ReminderUtil.getReminderText(this.checkValuesArray[2].remindMinutes, this.mIsAllDay, this.language))
          }
          if ((this.checkValuesArray.length > 2 && this.mIsAllDay) ||
            (this.checkValuesArray.length > 3 && !this.mIsAllDay) ||
            (this.checkValuesArray.length > 3 && FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale))) {
            Span('...')
          }
        }
      }
      .flexShrink(1)
      .fontSize($r('sys.float.Body_M'))
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .layoutWeight(layoutWeight)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .heightAdaptivePolicy(TextHeightAdaptivePolicy.LAYOUT_CONSTRAINT_FIRST)
      .textAlign(textAlign )

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
        .flexShrink(1)
    }
    .height(this.checkValuesArray.length == 0 ? '100%' : undefined)
    .constraintSize({ maxHeight: this.fontSizeScale > 3 ? 100 : 50 }) // 3倍以上放大倍数，其他语种低于100无法显示
    .justifyContent(FlexAlign.End)
    .alignItems(this.checkValuesArray.length === 0 && this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ?
      VerticalAlign.Bottom : VerticalAlign.Center)
    .margin({
      start: LengthMetrics.vp(0)
    })
    .padding({ bottom: this.checkValuesArray.length > 0 ||
      this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE_3X ? 0 : 8 })
    .layoutWeight(1)
  }

  build() {
    Column() {
      if (!this.isNotificationGranted && this.canShowReminder()) {
        this.buildNotice();
      }

      Column() {
        if (this.canShowReminder()) {
          if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) && this.checkValuesArray.length > 0) {
            ReminderRow({
              checkValuesArray: this.checkValuesArray,
              mIsAllDay: this.eventInfo.mIsAllDay
            })
          }
          if (!ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
            Row() {
              this.BuildAddReminder();
            }

            DividerLine({ paddingLeft: $r('sys.float.padding_level4'), paddingRight: $r('sys.float.padding_level4') });

          }
          ImportantAlertRow({
            isImportantAlert: this.isImportantAlert,
            importantAlertToggleOnChange: (isOn: boolean) => {
              this.importantAlertToggleOnChange(isOn)
            },
            toggleEnabled: this.getToggleEnabled()
          })
        }

        this.BuildRepeatRuleAndEffectiveDateRow();
      }
      .onAppear(() => {
        Log.info(TAG, `agenda reminder row appear`);
      })
      .id(CompId.AGENDA_REMINDER_INFO)
      .padding({
        left: $r('sys.float.padding_level2'),
        right: $r('sys.float.padding_level2'),
        top: $r('sys.float.padding_level2'),
        bottom: $r('sys.float.padding_level2')
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))

    }
    .visibility(this.isAgendaCollapse ? Visibility.None : Visibility.Visible)
    .margin({ top: this.marginTop, bottom: this.marginBottom })
  }

  getToggleEnabled(): boolean {
    if (this.checkValuesArray.length === 1 && this.checkValuesArray[0].remindMinutes === NO_REMINDER_VALUE) {
      return false;
    }
    return !ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) && this.checkValuesArray.length > 0
  }

  @Builder
  buildNotice() {
    Text($r('app.string.notification_reminder_hints'))
      .align(Alignment.Start)
      .fontSize($r('sys.float.Body_S'))
      .opacity(0.6)
      .margin({ bottom: 8 })
      .width('100%')
      .padding({ left: $r('sys.float.padding_level6') })
  }

  private canShowReminder(): boolean {
    return this.eventInfo.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
      this.eventInfo.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
  }

  /**
   * 删除提醒选项
   *
   * @param index 当前label的索引值
   */
  deleteCheck(index: number) {
    this.reportRemindStatistic(this.checkValuesArray[index].remindMinutes, HiEventAction.DELETE)
    this.checkValuesArray.splice(index, 1);
  }

  reportRemindStatistic(minute: number, action: number) {
    let params: ReportHiEventParams = {
      REMINDER_MINUTE: minute,
      IS_ALLDAY: this.mIsAllDay ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE,
      ACTION: action,
      TYPE: this.eventInfo?.mImportantEventType
    }
    if (this.isInDetailPage) {
      ReportUtil.reportStatisticEvent(statisticEvents.viewAgendaModifyRemind, params);
    } else if (this.isEditMode) {
      ReportUtil.reportStatisticEvent(statisticEvents.editAgendaModifyRemind, params);
    } else {
      params.FROM_TYPE = this.fromImportantSelect ? FromType.IMPORTANT_FA : FromType.MONTH_VIEW;
      ReportUtil.reportStatisticEvent(statisticEvents.createAgendaModifyRemind, params);
    }
  }

  /**
   * 获取需要添加的提醒对象
   *
   * @param values 弹窗value值
   * @param options 弹窗选项
   * @return 需要添加的提醒对象
   */
  addCheck(values: number[], options: RadioListDialogOption[]): CalendarContract.Reminders {
    let reminder: CalendarContract.Reminders;
    if (this.checkValuesArray === null || this.checkValuesArray === undefined || this.checkValuesArray.length === 0) {
      if (this.checkValuesArray.length === 0) {
        this.checkValuesArray.splice(0);
      } else {
        this.checkValuesArray = [];
      }
      // 日程无提醒时，默认提醒时间为准时
      reminder = this.createReminder(this.eventInfo.mId, 0, CalendarContract.RemindersRemindType.TYPE_ALERT);
      return reminder;
    }
    // 获取目前提醒列表的最后一项，从而计算下一个提醒选项
    let index = values.indexOf(this.checkValuesArray[this.checkValuesArray.length - 1].remindMinutes);
    if (index < 0) {
      index = 1;
    }
    const length = values.length;
    while (this.getReminderFromArray(values[index])) {
      index++;
      if (index === length) {
        index = 1;
      }
    }
    reminder = this.createReminder(this.eventInfo.mId, values[index], CalendarContract.RemindersRemindType.TYPE_ALERT);
    return reminder;
  }

  /**
   * 获取所有value值
   *
   * @param options 弹窗选项
   * @param labels value储存数组
   */
  getAllValues(options: RadioListDialogOption[], labels: number[]) {
    options.forEach((item) => {
      labels.push(item.value)
    })
  }

  /**
   * 初始化
   */
  initializeReminder() {
    Log.info(TAG, `initializeReminder checkValuesArray length: ${this.checkValuesArray.length}`);
    if (this.checkValuesArray === null || this.checkValuesArray === undefined || this.checkValuesArray.length === 0) {
      this.isInitializing = true;
      this.initializeCommon();
      return;
    }
  }

  /**
   * 初始化-事件mIsAllDay属性改变或者新建日程
   *
   * @param remindMinutes 设置的默认提醒时间
   * @param options 选项
   */
  initialize(remindMinutes: number, options: RadioListDialogOption[]) {
    let reminder: CalendarContract.Reminders = this.createReminder(this.eventInfo.mId, remindMinutes, 1);
    this.checkValuesArray.push(reminder);

    // 对提醒列表中的提醒时间去重
    this.checkValuesArray = this.checkValuesArray.reduce((reminderList: CalendarContract.Reminders[],
                                                          reminder: CalendarContract.Reminders) => {
      const existing = reminderList.find(item => item.remindMinutes === reminder.remindMinutes);
      if (!existing) {
        reminderList.push(reminder);
      }
      return reminderList;
    }, []);
  }

  /**
   * 创建提醒对象
   *
   */
  createReminder(eventId: number, remindMinutes: number, remindType: number) {
    let reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
    reminder.eventId = eventId;
    reminder.remindMinutes = remindMinutes;
    reminder.remindType = remindType;
    return reminder;
  }

  /**
   * 初始化日程提醒组件-事件mIsAllDay属性改变或者新建日程
   */
  initializeCommon() {
    if (this.isInDetailPage || this.isEditMode) {
      if (this.originalIsAllDay === this.mIsAllDay) {
        this.checkValuesArray = this.originalReminderArray; // 恢复初始值
        return;
      }
    }
    if (!this.checkValuesArray || !this.isInitializing) {
      this.checkValuesArray = [];
      this.isInitializing = false;
    }
    if (this.mIsAllDay && this.allDayEventsDefaultRemindTime !== this.defaultNum) {
      this.initialize(this.allDayEventsDefaultRemindTime, DEFAULT_ALL_DAY_REMINDER_OPTIONS);
    }
    if (!this.mIsAllDay && this.defaultRemindTime !== this.defaultNum) {
      this.initialize(this.defaultRemindTime, DEFAULT_REMINDER_OPTIONS);
    }
  }

  /**
   * 监听提醒数组变化
   */
  checkValuesArrayChange() {
    this.eventInfo.checkValuesArray = this.checkValuesArray
  }

  /**
   * 初始化选项的键值对map //pc全部日程界面不会在日程列表选择日程时触发aboutToAppear,导致初始化失败
   */
  initOptionMap() {
    DEFAULT_REMINDER_OPTIONS.forEach((item: RadioListDialogOption) => {
      this.optionMap.set(item.value, item.label);
    });
    DEFAULT_ALL_DAY_REMINDER_OPTIONS.forEach((item: RadioListDialogOption) => {
      this.allDayOptionMap.set(item.value, item.label);
    });
  }

  subscribeEvents() {
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closeDialog);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_LANGUAGE_CHANGED }, this.systemLanguageChangeHandler);
  }

  aboutToAppear() {
    if (this.isEditMode) { // 编辑模式下保存初始值
      this.originalReminderArray = this.checkValuesArray;
      this.originalIsAllDay = this.mIsAllDay;
    }
    NotificationHelper.getInstance().queryNotificationGranted().then((data) => {
      this.isNotificationGranted = data;
    })
    this.initOptionMap();
    this.initializeReminder();
    this.getAllValues(DEFAULT_REMINDER_OPTIONS, this.defaultValues);
    this.getAllValues(DEFAULT_ALL_DAY_REMINDER_OPTIONS, this.allDayValues);
    this.setReminderSeparator();
    this.subscribeEvents();
    Log.info(TAG, `agenda reminder info abouttoappear over`);
  }

  aboutToDisappear() {
    this.emitterCollector.off()
    this.dialogController = null;
  }

  private importantAlertToggleOnChange(isOn: boolean) {
    if (this.isImportantAlert === isOn) {
      return;
    }
    this.eventInfo.alertType = isOn
      ? CalendarContract.AgendaAlertType.IMPORTANT
      : CalendarContract.AgendaAlertType.NORMAL;
    this.isImportantAlert = isOn;
    this.alertTypeChange();
  }

  private setReminderSeparator() {
    const newLanguage = I18nUtil.getSystemLanguage();
    const isEnglish = I18nUtil.isEnglishLanguage(newLanguage);
    this.reminderSeparator = isEnglish ? ', ' : ','; // 英文逗号之后要有空格
  }

  private systemLanguageChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.setReminderSeparator();
  };
}