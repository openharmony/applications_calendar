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
  CalendarContract,
  CompId,
  DateUtil,
  HiEventParamsConfirm,
  I18nUtil,
  Log,
  ReportHiEventParams,
  ReportUtil,
  BigFontSize,
  FontSizeScaleUtils,
  DeviceConfig,
  VibratorUtils,
  VibrationType,
  ThrottleFunction,
  CalendarDate,
  GlobalThis,
} from '@app/common';
import { HighlightButton, NormalButton } from '@app/common.components';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import lazy { inspector, LengthMetrics } from '@kit.ArkUI';
import lazy { KeyCode } from '@kit.InputKit';
import { addSelectStatusAndButton, broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';

const TAG: string = 'DateAndTimePicker';

export enum TimePoint {

  DATE = 0,

  START,

  END
}

export enum ChangeFlag {

  INSERT = 0,

  EDIT,

  DETAIL
}

const MIN_TIME_HEIGHT = 58; // 时间选择器最小高度
const MAX_TIME_HEIGHT = 200; // 时间选择器最大高度

/**
 * 自定义日期时间选择器
 *
 * @since 2022-10-09
 */
@CustomDialog
export struct DateAndTimePicker {
  controller: CustomDialogController = new CustomDialogController({ builder: null });

  selectedDateTime: Date = new Date();

  @State showLunar: boolean = false;

  @Provide('date_title') dateTitle: number = this.selectedDateTime.getTime();

  @StorageProp('is24HourClock') is24Hour: boolean = I18nUtil.is24HourClock();

  // 是否重要日卡片选择页面跳转过来
  @Prop fromImportantSelect: boolean = false;

  // 是否编辑页
  @Prop isEditMode: boolean;

  @State lunarButtonBC: ResourceColor = Color.Transparent;

  @StorageLink('language') @Watch('onLanguageChanged') language: string = '';

  @State isChinese: boolean = false;

  showTimePicker: boolean = true;

  // 日程
  agendaType: number = 0;

  // 开始/结束时间
  timePoint: number = 0;

  // 新建/修改
  changeFlag: number = 0;

  @Link eventInfo: AgendaEventInfo;

  // 限制起始日期
  startTime: Date = new Date('1900-01-01');

  // 限制结束日期
  endTime: Date = new Date('5000-12-31');

  // 日程类型为农历或阳历
  eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  confirm: (date: Date) => void = (date: Date): void => {
  };

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private scroller: Scroller = new Scroller();

  // 已选择的开始时间，用于判断结束时间是否早于开始时间
  private selectedStartDate: Date = new Date();

  lunarHover(isHover: boolean) {
    // 通过onHover事件动态修改按钮在是否有鼠标悬浮时的背景颜色
    if (isHover) {
      this.lunarButtonBC = $r('sys.color.interactive_hover');
    } else {
      this.lunarButtonBC = Color.Transparent;
    }
  }

  lunarTouch(event?: TouchEvent) {
    if (event) {
      if (event.type === TouchType.Down) {
        this.lunarButtonBC = $r('sys.color.interactive_click');
      }
      if (event.type === TouchType.Up) {
        this.lunarButtonBC = Color.Transparent;
      }
    }
  }

  dateFontChange(def: number) {
    const dateTitleFontSize = FontSizeScaleUtils
      .getLimitFontSizeNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD, def);
    return dateTitleFontSize + 'vp';
  }

  private reportDatePickerEvent(isSave: HiEventParamsConfirm) {
    let params: ReportHiEventParams = {
      CHANGE_FLAG: this.isEditMode ? ChangeFlag.EDIT : ChangeFlag.INSERT,
      TIME_POINT: this.timePoint,
      IS_SAVE: isSave
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDatePicker, params);
  }

  @State rootLoaded: boolean = false;

  private componentObserver: inspector.ComponentObserver = 
    inspector.createComponentObserver(CompId.AGENDA_DATE_AND_TIME_PICKER);

  //日期选择
  @Builder
  buildDatePicker() {
    Row() {
      DatePicker({
        start: this.startTime,
        end: this.endTime,
        selected: this.selectedDateTime,
      })
        .lunar(this.showLunar)
        .onDateChange((date: Date) => {
          date.setHours(this.selectedDateTime.getHours())
          date.setMinutes(this.selectedDateTime.getMinutes())
          this.selectedDateTime = date;
          this.dateTitle = date.getTime();
          if (!this.needCommerce) {
            // 触发震动 PC上不需要触发震动
            VibratorUtils.startPresetVibration(VibrationType.SLIDE);
          }
        })
        .textStyle({ font: { size: this.dateFontChange(14) } })
        .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
        .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
        .layoutWeight(3)
        .backgroundColor($r('app.color.default_background'))

      if (this.showTimePicker) {
        TimePicker({
          selected: this.selectedDateTime,
        })
          .enableCascade(true)
          .useMilitaryTime(this.is24Hour)
          .onChange((date: TimePickerResult) => {
            Log.info(TAG, `select current date is: ${date.hour}:${date.minute}:${date.second}`);
            this.selectedDateTime.setHours(date.hour as number);
            this.selectedDateTime.setMinutes(date.minute as number);
            if (!this.needCommerce) {
              // 触发震动 PC上不需要触发震动
              VibratorUtils.startPresetVibration(VibrationType.SLIDE);
            }
          })
          .textStyle({ font: { size: this.dateFontChange(14) } })
          .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
          .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
          .layoutWeight(2)
          .backgroundColor($r('app.color.default_background'))
      }
    }
    .layoutWeight(1)
    .constraintSize({ maxHeight: MAX_TIME_HEIGHT, minHeight: MIN_TIME_HEIGHT })
    .margin({ top: 16, left: 8, right: 8 })
  }

  //按钮
  @Builder
  buildButton() {
    Row() {
      if (this.needCommerce) {
        HighlightButton({
          label: $r('app.string.cancel_dialog_button'),
          compId: CompId.CANCEL,
          onButtonClick: () => {
            this.controller.close();
            this.reportDatePickerEvent(HiEventParamsConfirm.FALSE);
          }
        })
      } else {
        NormalButton({
          label: $r('app.string.cancel_dialog_button'),
          compId: CompId.CANCEL,
          onButtonClick: () => {
            this.controller.close();
            this.reportDatePickerEvent(HiEventParamsConfirm.FALSE);
          }
        })
      }
      if (this.needCommerce) {
        Blank().width($r('sys.float.padding_level8'));
        HighlightButton({
          label: $r('app.string.button_ok'),
          compId: CompId.CONFIRMS,
          onButtonClick: () => {
            this.onConfirmClick();
          }
        })
      } else {
        Divider()
          .vertical(true)
          .strokeWidth('2px')
          .height(24)
          .color($r('sys.color.comp_divider'))
          .margin({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
        NormalButton({
          label: $r('app.string.button_ok'),
          compId: CompId.CONFIRMS,
          onButtonClick: () => {
            this.onConfirmClick();
          }
        })
      }
    }.margin({ top: 8 }).padding({ bottom: 16, left: 16, right: 16 })
  }

  private onConfirmClick() {
    this.eventInfo.mEventCalendar = this.showLunar ?
    CalendarContract.AgendaCalendarType.LUNAR : CalendarContract.AgendaCalendarType.SOLAR;
    if (this.timePoint === TimePoint.END && this.selectedDateTime.getTime() < this.selectedStartDate.getTime()) {
      showToast($r('app.string.end_time_invalid_toast'));
      return;
    }
    this.controller.close();
    this.confirm(this.selectedDateTime);
    this.reportDatePickerEvent(HiEventParamsConfirm.TRUE);
  }

  @Builder
  lunarSelectCheckBox() {
    Checkbox({ name: 'ck', group: 'ckgroup' })
      .accessibilityText(' ')
      .select(this.showLunar)
      .selectedColor(this.themeColor)
      .width(20)
      .height(20)
      .hoverEffect(HoverEffect.None)
      .margin(2)
      .onChange((checked) => {
        Log.info(TAG, 'changevalis' + checked);
        this.showLunar = !!checked;
        this.eventCalendarType = this.showLunar ?
        CalendarContract.AgendaCalendarType.LUNAR : CalendarContract.AgendaCalendarType.SOLAR;
        const params: ReportHiEventParams = {
          TYPE: this.agendaType,
          IS_ON: this.showLunar ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE,
          TIME_POINT: this.timePoint,
          CHANGE_FLAG: this.changeFlag,
          FROM_TYPE: this.fromImportantSelect ? FromType.IMPORTANT_FA : FromType.MONTH_VIEW
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaSelectLunarDate, params);
      })
      .onHover((isHover: boolean) => {
        this.lunarHover(isHover);
      })
      .onTouch((event?: TouchEvent) => {
        this.lunarTouch(event);
      })
      .id(CompId.SHOW_LUNAR_CALENDAR)
      .width(24)
      .height(24)
      .borderRadius($r('sys.float.corner_radius_level16'))
      .margin({ left: 6, right: 10 })
      .backgroundColor(this.lunarButtonBC)
  }

  @Builder
  LunarCheckBox() {
    if (this.isChinese) {
      Row() {
        this.lunarSelectCheckBox()
        Text('显示农历')
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            14))
      }
      .height(56)
      .margin({
        top: 8,
        start: LengthMetrics.vp(8)
      })
      .alignSelf(ItemAlign.Start)
      .accessibilityGroup(true)
      .accessibilityText(addSelectStatusAndButton('显示农历', this.showLunar))
      .onClick(() => {
        this.showLunar = !this.showLunar;
        broadcastSelectStatus(this.showLunar);
      })
    }
  }

  private rootObserver: () => void = (): void => {
  };

  // 可滑动的组件
  @Builder
  buildScrollContent() {
    Column() {
      DateTitle({ defaultDateTime: this.selectedDateTime.getTime() })
      if (this.rootLoaded) {
        this.buildDatePicker();
        this.LunarCheckBox();
      } else {
        Row()
          .constraintSize({ minHeight: MAX_TIME_HEIGHT }) // 高度占位，避免按压态和标题重叠
      }
    }
  }

  build() {
    Column() {
      Row() {
        Scroll(this.scroller) {
          this.buildScrollContent()
        }
        .layoutWeight(1)
        .padding({ left: 16 })
        .scrollBar(BarState.Off)

        ScrollBar({
          scroller: this.scroller,
          direction: ScrollBarDirection.Vertical,
          state: BarState.Auto
        })
          .margin({ top: this.needCommerce ? 4 : 16 })
          .width(16)
      }
      .constraintSize({
        // 限制总高度,否则scrollBar会将弹窗高度顶到极限 72为标题高度,后续56为农历开关高度
        maxHeight: MAX_TIME_HEIGHT + 72 + (this.isChinese ? 56 : 0)
      })
      .layoutWeight(1)

      this.buildButton();
    }
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .id(CompId.AGENDA_DATE_AND_TIME_PICKER)
    .onKeyEvent((event) => {
      if (event.keyCode === KeyCode.KEYCODE_ENTER) {
        ThrottleFunction.instance().throttle(TAG + 'keyEvent',
          (): void => {
            this.onConfirmClick();
          },
          500);
      }
    })
  }

  aboutToAppear() {
    this.rootObserver = () => {
      this.rootLoaded = true
    };
    this.componentObserver.on('draw', this.rootObserver);
    this.isChinese = I18nUtil.isSystemChineseLanguage();
    this.showLunar = this.eventCalendarType === CalendarContract.AgendaCalendarType.LUNAR;
  }

  aboutToDisappear(): void {
    this.componentObserver.off('draw', this.rootObserver);
  }

  onLanguageChanged(): void {
    this.dateTitle = new Date().getTime();
    this.isChinese = I18nUtil.isSystemChineseLanguage();
  }
}

@Component
struct DateTitle {
  defaultDateTime: number = new Date().getTime();

  @State dateTitle: string = this.getDateTime(this.defaultDateTime);

  @Consume('date_title') @Watch('onDateChange') selectedDateTime: number;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  onDateChange() {
    this.dateTitle = this.getDateTime(this.selectedDateTime);
  }

  getDateTime(time: number): string {
    const dateTime = new Date(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime,
      {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long'
      })
  }

  dateFontChange(def: number) {
    const dateTitleFontSize = FontSizeScaleUtils
      .getLimitFontSizeNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_TWO, def);
    return dateTitleFontSize + 'vp';
  }

  build() {
    Text(this.dateTitle)
      .fontSize(this.dateFontChange(20))
      .height(56)
      .textAlign(TextAlign.Center)
      .fontWeight(FontWeight.Medium)
      .id(CompId.AGENDA_DATE_TITLE)
      .padding({
        top: $r('sys.float.padding_level2')
      })
  }

  aboutToAppear() {
    this.dateTitle = this.getDateTime(this.defaultDateTime);
  }
}