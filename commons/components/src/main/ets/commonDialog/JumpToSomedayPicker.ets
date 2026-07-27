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
  behaviorEvents,
  BigFontSize,
  CalendarContract,
  CalendarDate,
  CompId,
  DateUtil,
  DeviceConfig,
  FontSizeScaleUtils,
  HiEventParamsConfirm,
  I18nUtil,
  Log,
  ReportHiEventParams,
  ReportUtil,
  ThrottleFunction
} from '@app/common';
import { HighlightButton } from '../button/HighlightButton';
import { NormalButton } from '../button/NormalButton';
import lazy { KeyCode } from '@kit.InputKit';
import { addSelectStatusAndButton, broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';


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

/**
 * 跳转日期选择器
 *
 */

const TAG: string = 'JumpToSomedayPicker';

@CustomDialog
export struct JumpToSomedayPicker {
  controller: CustomDialogController = new CustomDialogController({ builder: null });

  @State selectedDateTime: Date = new Date();

  @State showLunar: boolean = false;

  @Provide('date_title') dateTitle: number = this.selectedDateTime.getTime();

  @State lunarButtonBC: ResourceColor = Color.Transparent;

  @StorageLink('language') @Watch('onLanguageChanged') language: string = '';

  @State isChinese: boolean = false;

  showTimePicker: boolean = true;

  // 开始/结束时间
  timePoint: number = 0;

  // 新建/修改
  changeFlag: number = 0;

  // 限制起始日期
  startTime: Date = new Date('1900-01-01');

  // 限制结束日期
  endTime: Date = new Date('5000-12-31');

  // 日程类型为农历或阳历
  eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;
  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  confirm: (date: Date) => void = (date: Date): void => {
  };

  /**
   * 跳转到指定日期打点
   * @param action 确认/取消
   */
  reportBehaviorEvent(action: number) {
    Log.info(TAG, `reportBehaviorEvent selectedDateTime = ${this.selectedDateTime}, action = ${action}, showLunar = ${this.showLunar}`)
    let params: ReportHiEventParams = {
      TIME_POINT: this.selectedDateTime.getTime(),
      IS_ON: this.showLunar ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE,
      ACTION: action
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.jumpToSomeday, params);
  }

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
      .getLimitFontSizeNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_TWO, def);
    return dateTitleFontSize + 'vp';
  }

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
          date.setHours(this.selectedDateTime.getHours());
          date.setMinutes(this.selectedDateTime.getMinutes());
          this.selectedDateTime = date;
          this.dateTitle = date.getTime();
        })
        .textStyle({ font: { size: this.dateFontChange(14) } })
        .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
        .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
        .layoutWeight(3)
        .backgroundColor($r('app.color.default_background'))
    }
    .height(200)
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
            this.reportBehaviorEvent(HiEventParamsConfirm.FALSE);
          }
        })
      } else {
        NormalButton({
          label: $r('app.string.cancel_dialog_button'),
          compId: CompId.CANCEL,
          onButtonClick: () => {
            this.controller.close();
            this.reportBehaviorEvent(HiEventParamsConfirm.FALSE);
          }
        })
      }
      if (this.needCommerce) {
        Blank().width($r('sys.float.padding_level8'));
        HighlightButton({
          label: $r('app.string.button_ok'),
          compId: CompId.CONFIRMS,
          onButtonClick: () => {
            this.controller.close();
            this.confirm(this.selectedDateTime);
            this.reportBehaviorEvent(HiEventParamsConfirm.TRUE);
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
            this.controller.close();
            this.confirm(this.selectedDateTime);
            this.reportBehaviorEvent(HiEventParamsConfirm.TRUE);
          }
        })
      }
    }.margin({ top: 8 }).padding({ bottom: 16 })
  }

  @Builder
  lunarSelectCheckBox() {
    Column() {
      Checkbox({ name: 'ck', group: 'ckgroup' })
        .accessibilityText(' ')
        .select(this.showLunar)
        .selectedColor(this.themeColor)
        .width(20)
        .height(20)
        .hoverEffect(HoverEffect.None)
        .margin(2)
        .onChange((checked) => {
          this.showLunar = !!checked;
        })
        .onHover((isHover: boolean) => {
          this.lunarHover(isHover);
        })
        .onTouch((event?: TouchEvent) => {
          this.lunarTouch(event);
        })
        .id(CompId.SHOW_LUNAR_CALENDAR)
    }
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
          .fontSize(14)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
      }
      .height(56)
      .margin({ top: 8 })
      .alignSelf(ItemAlign.Start)
      .accessibilityGroup(true)
      .accessibilityText(addSelectStatusAndButton('显示农历', this.showLunar))
      .onClick(() => {
        this.showLunar = !this.showLunar;
        broadcastSelectStatus(this.showLunar);
      })
    }
  }

  build() {
    Scroll() {
      Column() {
        DateTitle({ defaultDateTime: this.selectedDateTime.getTime(), isChinese: this.isChinese })

        this.buildDatePicker()
        this.LunarCheckBox()
        this.buildButton()
      }
      .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
      .padding({ left: 16, right: 16 })
    }
    .onKeyEvent((event) => {
      if (event.keyCode === KeyCode.KEYCODE_ENTER) {
        ThrottleFunction.instance().throttle(TAG + 'keyEvent',
          (): void => {
            this.controller.close();
            this.confirm(this.selectedDateTime);
            this.reportBehaviorEvent(HiEventParamsConfirm.TRUE);
          },
          500);
      }
    })
  }

  aboutToAppear() {
    this.isChinese = I18nUtil.isSystemChineseLanguage();
    this.showLunar = this.eventCalendarType === CalendarContract.AgendaCalendarType.LUNAR;
  }

  onLanguageChanged(): void {
    this.dateTitle = new Date().getTime();
    this.isChinese = I18nUtil.isChineseLanguage(this.language);
  }
}

@Component
struct DateTitle {
  defaultDateTime: number = new Date().getTime();

  @State dateTitle: string = this.getDateTime(this.defaultDateTime);

  @Consume('date_title') @Watch('onDateChange') selectedDateTime: number;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Prop isChinese: boolean;

  onDateChange() {
    this.dateTitle = this.getDateTime(this.selectedDateTime);
  }

  getDateTime(time: number): string {
    const dateTime = new CalendarDate(time);
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
      .fontSize(this.isChinese ? this.dateFontChange(20) : 20)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      .height(56)
      .textAlign(TextAlign.Center)
      .fontWeight(FontWeight.Medium)
      .id(CompId.AGENDA_DATE_TITLE)
  }

  aboutToAppear() {
    this.dateTitle = this.getDateTime(this.defaultDateTime);
  }
}