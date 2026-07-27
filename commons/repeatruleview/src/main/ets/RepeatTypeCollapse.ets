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
  BigFontSize,
  CompId,
  DAY_PER_WEEK,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalThis,
  Log,
} from '@app/common';
import { CheckboxList, CheckboxListOption, RadioList, RadioListDialogOption } from '@app/common.components';
import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';
import {
  Frequency,
  Weeks,
  WEEK_OF_MONTH_TOMAP
} from '@app/feature.repeatrule/src/main/ets/Constants';
import { CustomTime } from '@app/feature.repeatrule';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'RepeatTypeCollapse';

const MODE_DAY_OF_MONTH: number = 0;

const MODE_WEEK_OF_MONTH: number = 1;

const REPEAT_MAX_NUMBER: number = 100; // 重复周期最大数字

/**
 * 重复类型折叠面板组件
 */
@Component
export struct RepeatTypeCollapse {
  // 是否收起折叠面板
  @State isArrowDown: boolean = false;

  // 重复周期之每周几列表
  @State weekCheckboxValue: number[] = [];

  build() {
    Column() {
      Header({
        isArrowDown: this.isArrowDown,
      })
      CollapseAndExpand({
        isArrowDown: this.isArrowDown
      })
        .margin({
          left: $r('sys.float.padding_level2'),
          right: $r('sys.float.padding_level2')
        })
    }
  }
}

@Component
struct Header {
  @Consume tempRecurrence: Recurrence;

  @Link isArrowDown: boolean;

  @State isHoverShow: boolean = false;

  @StorageLink('language') language: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Builder
  HeaderContainerText() {
    Text($r('app.string.custom_repeat_type'))
      .align(Alignment.Start)
      .fontSize($r('sys.float.Subtitle_M'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .margin({ end: LengthMetrics.vp(16) })
  }

  @Builder
  HeaderLabelText() {
    Text(this.formatRepeatTypeLabel())
      .fontSize($r('sys.float.Body_M'))
      .fontWeight(FontWeight.Regular)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .layoutWeight(1)
      .textAlign(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? TextAlign.End : TextAlign.Start)
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
        24
      ))
      .fontColor([$r('sys.color.icon_fourth')])
      .margin({ start: LengthMetrics.vp(6) })
      .align(Alignment.Center)
      .rotate({ angle: this.isArrowDown ? 90 : -90 })
  }

  @Builder
  CaringModeContent() {
    Row() {
      this.HeaderContainerText();
    }
    .width(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? undefined : '100%')
    .justifyContent(FlexAlign.Start)

    Row() {
      this.HeaderLabelText()
    }
    .layoutWeight(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 1 : undefined)
  }

  build() {
    Row() {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        if (this.fontSizeScale < BigFontSize.BIG_FONT_SIZE) {
          Row() {
            this.CaringModeContent()
          }
        } else {
          Column() {
            this.CaringModeContent()
          }
        }
      }
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius($r('sys.float.corner_radius_level7'))
      .backgroundColor(Color.Transparent)
      .constraintSize({ minHeight: 56 })
      .padding({ left: $r('sys.float.padding_level4'), right: 20 })
    }
    .padding({
      left: $r('sys.float.padding_level2'),
      right: $r('sys.float.padding_level2'),
      top: $r('sys.float.padding_level2'),
      bottom: $r('sys.float.padding_level2')
    })
    .onClick(() => {
      this.isArrowDown = !this.isArrowDown;
    })
    .onHover((isHover) => {
      this.isHoverShow = !isHover;
    })
  }

  private formatRepeatTypeLabel = () => {
    let recurrenceString: ResourceStr = '';
    if (this.tempRecurrence.freq === Frequency.DAILY) {
      recurrenceString = this.tempRecurrence.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_day'), this.tempRecurrence.interval, this.language)
        .toString()
        : $r('app.string.every_day_repeat')
    } else if (this.tempRecurrence.freq === Frequency.WEEKLY) {
      recurrenceString = this.tempRecurrence.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_week'), this.tempRecurrence.interval, this.language)
        .toString()
        : $r('app.string.every_week_repeat')
    } else if (this.tempRecurrence.freq === Frequency.MONTHLY) {
      recurrenceString = this.tempRecurrence.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_month'), this.tempRecurrence.interval, this.language)
        .toString()
        : $r('app.string.every_month_repeat')
    } else if (this.tempRecurrence.freq === Frequency.YEARLY) {
      recurrenceString = this.tempRecurrence.interval > 1
        ? GlobalThis.getPluralStr($r('app.plural.every_repeat_year'), this.tempRecurrence.interval, this.language)
        .toString()
        : $r('app.string.every_year_repeat')
    }
    return recurrenceString;
  }
}

/**
 * 重复类型折叠面板
 */
@Component
struct CollapseAndExpand {
  @Consume tempRecurrence: Recurrence;

  @Link isArrowDown: boolean;

  build() {
    Column() {
      Row() {
        NumberTextPicker();
        TypeTextPicker();
      }

      Row() {
        if (this.tempRecurrence.freq === Frequency.WEEKLY) {
          WeekCheckboxList();
        }
        if (this.tempRecurrence.freq === Frequency.MONTHLY) {
          MonthRadioList();
        }
      }
      .margin({ top: $r('sys.float.padding_level8') })
    }
    .padding({
      top: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      bottom: $r('sys.float.padding_level2')
    })
    .width('100%')
    .clip(true)
    .visibility(this.isArrowDown ? Visibility.None : Visibility.Visible)
  }
}

/**
 * 重复周期数字选择器
 */
@Component
struct NumberTextPicker {
  @Consume tempRecurrence: Recurrence;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private numbers: string[] = [];

  aboutToAppear(): void {
    for (let i = 1; i < REPEAT_MAX_NUMBER; i++) {
      this.numbers.push(i + '')
    }
  }

  build() {
    Column() {
      TextPicker({ range: this.numbers, selected: this.tempRecurrence.interval - 1 })
        .onChange((value: string | string[], index: number | number[]) => {
          Log.info(TAG, `Picker item changed, value: ${value}, index: ${index}`)
          this.tempRecurrence.setInterval(index as number + 1);
        })
        .selectedTextStyle({
          color: $r('app.color.red_common'), font: {
            size: FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
              20)
          }
        })
        .textStyle({
          font: {
            size: FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_TWO,
              14)
          }
        })
        .divider({
          strokeWidth: '1px',
          color: $r('sys.color.comp_divider'),
          startMargin: 0,
          endMargin: 0
        } as DividerOptions)
    }
  }
}

/**
 * 重复周期单位选择器
 */
@Component
struct TypeTextPicker {
  @Consume tempRecurrence: Recurrence;

  @Consume initCustomTime: CustomTime;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private types: TextCascadePickerRangeContent[] = [
    { text: $r('app.string.day_view') },
    { text: $r('app.string.week_view') },
    { text: $r('app.string.month') },
    { text: $r('app.string.year') }
  ];

  build() {
    Column() {
      TextPicker({ range: this.types, selected: this.freqToIndex(this.tempRecurrence.freq) })
        .canLoop(false)
        .onChange((value: string | string[], index: number | number[]) => {
          this.tempRecurrence.freq = this.indexToFreq(index as number);
          this.correctTempRecurrence();
        })
        .selectedTextStyle({
          color: $r('app.color.red_common'), font: {
            size: FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
              20)
          }
        })
        .textStyle({
          font: {
            size: FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
              14)
          }
        })
        .divider({
          strokeWidth: '1px',
          color: $r('sys.color.comp_divider'),
          startMargin: 0,
          endMargin: 0
        } as DividerOptions)
    }
  }

  // 从周切到月时，不满足按月重复条件时修正数据
  private correctTempRecurrence() {
    if (this.tempRecurrence.freq !== Frequency.MONTHLY) {
      return;
    }
    if (!this.tempRecurrence.isValidRecurrence()) {
      this.tempRecurrence.byMonthDay = [this.initCustomTime.getDate()];
      this.tempRecurrence.byWeekDay = [];
    }
  }

  private freqToIndex(freq: Frequency): number {
    return freq - Frequency.DAILY;
  }

  private indexToFreq(index: number): Frequency {
    return index + Frequency.DAILY;
  }
}

/**
 * 周多选列表
 */
@Component
struct WeekCheckboxList {
  @Consume tempRecurrence: Recurrence;

  @Consume initCustomTime: CustomTime;

  // list选项配置
  @State weekCheckboxListOptions: CheckboxListOption[] = [
    { label: $r('app.string.Sunday'), value: Weeks.SUN, compId: CompId.SUNDAY },
    { label: $r('app.string.Monday'), value: Weeks.MON, compId: CompId.MONDAY },
    { label: $r('app.string.Tuesday'), value: Weeks.TUE, compId: CompId.TUESDAY },
    { label: $r('app.string.Wednesday'), value: Weeks.WED, compId: CompId.WEDNESDAY },
    { label: $r('app.string.Thursday'), value: Weeks.THUR, compId: CompId.THURSDAY },
    { label: $r('app.string.Friday'), value: Weeks.FRI, compId: CompId.FRIDAY },
    { label: $r('app.string.Saturday'), value: Weeks.SAT, compId: CompId.SATURDAY },
  ];

  @State isCustomWeekList: boolean = true;

  aboutToAppear(): void {
    this.weekCheckboxListOptions.forEach((option: CheckboxListOption) => {
      let needCheck: boolean = false;
      this.tempRecurrence.byWeekDay.forEach((week: Weeks) => {
        if (week === option.value) {
          needCheck = true;
        }
      });

      if (this.initCustomTime.getDayOfWeek() === option.value && this.tempRecurrence.byWeekDay.length === 0) {
        needCheck = true;
        this.tempRecurrence.byWeekDay.push(option.value as Weeks);
      }

      option.checked = needCheck;
    });
  }

  build() {
    CheckboxList({
      options: this.weekCheckboxListOptions,
      onChange: (options: CheckboxListOption[]) => {
        const checkedWeeks: Weeks[] = [];
        options?.forEach((option: CheckboxListOption) => {
          if (option.checked) {
            checkedWeeks.push(option.value as Weeks);
          }
        });
        this.tempRecurrence.byWeekDay = checkedWeeks;
      },
      isCustomWeekList: this.isCustomWeekList
    }).layoutWeight(1)
  }
}

/**
 * 月单选列表
 */
@Component
struct MonthRadioList {
  @Consume tempRecurrence: Recurrence;

  @Consume initCustomTime: CustomTime;

  @StorageLink('language') language: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State checkedValue: number = MODE_DAY_OF_MONTH;

  @State isBackToPage: boolean = false;

  // 当前日期在第几周
  @State weekNum: number = 0;

  // 当前日期是周几
  @State weekDay: number = 0;

  // list选项配置
  private weekRadioOptions: RadioListDialogOption[] = [];

  private dividerLength: number = 18;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 初始化单选列表选项
  initMonthRadioListLabel() {
    this.weekNum = this.getWeekNumOfDate(this.initCustomTime.getDate());
    this.weekDay = this.initCustomTime.getDayOfWeek();

    Log.info(TAG, `initMonthRadioListLabel: weekNum:${this.weekNum},weekDay:${this.weekDay}`);
    const weekOfMonthMap: ReadonlyMap<Weeks, Resource> | undefined = WEEK_OF_MONTH_TOMAP.get(this.weekNum);
    if (!weekOfMonthMap) {
      Log.info(TAG, `no weekOfMonthMap`);
      return;
    }
    const dayOfWeekToResource: ResourceStr | undefined = weekOfMonthMap.get(this.weekDay);
    if (!dayOfWeekToResource) {
      Log.info(TAG, `no dayOfWeekToResource`);
      return;
    }
    this.weekRadioOptions = [
      {
        label: $r('app.string.same_day_of_every_month'),
        value: MODE_DAY_OF_MONTH,
        compId: CompId.SAME_DAY_OF_EVERY_MONTH
      },
      { label: dayOfWeekToResource, value: MODE_WEEK_OF_MONTH, compId: CompId.SPECIFIC_DATES },
    ];
  }

  aboutToAppear(): void {
    this.checkedValue = this.tempRecurrence.byMonthDay.length > 0 ? MODE_DAY_OF_MONTH : MODE_WEEK_OF_MONTH;
    this.initMonthRadioListLabel();
  }

  build() {
    RadioList({
      groupName: 'MonthRadioList',
      options: this.weekRadioOptions,
      isBackToPage: this.isBackToPage,
      dividerLength: this.dividerLength,
      checkValue: this.checkedValue,
      onChange: (value: number) => {
        this.checkedValue = value;
        if (value === MODE_DAY_OF_MONTH) {
          this.setToDayOfMonth();
        } else if (value === MODE_WEEK_OF_MONTH) {
          this.setToWeekOfMonth();
        }
      }
    })
      .height(FontSizeScaleUtils.getLimitHeightNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD,
        this.weekRadioOptions.length * (this.needCommerce ? 40 : 48)))
      .layoutWeight(1)
  }

  private getWeekNumOfDate(date: number): number {
    // 参考双框架，周数为：(日期+6)/7
    let weekNum: number = Math.floor((date + DAY_PER_WEEK - 1) / DAY_PER_WEEK);
    if (weekNum === 5) {
      weekNum = -1;
    }
    return weekNum;
  }

  private setToDayOfMonth() {
    if (this.tempRecurrence.freq !== Frequency.MONTHLY) {
      return;
    }
    this.tempRecurrence.byMonthDay = [this.initCustomTime.getDate()];

    this.tempRecurrence.byWeekDay = [];
    this.tempRecurrence.byWeekNum = [];
  }

  private setToWeekOfMonth() {
    if (this.tempRecurrence.freq !== Frequency.MONTHLY) {
      return;
    }
    this.tempRecurrence.byWeekDay = [this.weekDay];
    this.tempRecurrence.byWeekNum = [this.weekNum];

    this.tempRecurrence.byMonthDay = [];
  }
}