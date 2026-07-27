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
  CalendarDate,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalThis,
  Log,
  LunarDateUtil
} from '@app/common';
import { RadioListDialog, RadioListDialogOption, RadioListStyle } from '@app/common.components';
import { CustomTime } from '@app/feature.repeatrule';
import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';
import { LengthMetrics } from '@kit.ArkUI';
import { EffectiveDateMode, EffectiveDateViewModel } from './EffectiveDateViewModel';
import { DividerLine } from './RepeatRuleRow';

// 限定次数最大值
const MAX_LIMIT_TIMES = 730;

const MAX_HOUR: number = 23;

const MAX_MINUTES: number = 59;

const TAG = 'EffectiveDate';

@Component
export struct EffectiveDate {
  @ObjectLink vm: EffectiveDateViewModel;

  // 仅用于子组件RadioListDialog中@Link checkValue的初始值传入
  @State effectiveDateMode: EffectiveDateMode = EffectiveDateMode.FOREVER;

  @StorageLink('initSelectedStartDate') initSelectedStartDate: CalendarDate = new CalendarDate();

  // list选项配置
  private effectiveDateRadioOptions: RadioListDialogOption[] = [
    { label: $r('app.string.all_the_time'), value: EffectiveDateMode.FOREVER, compId: CompId.ALL_THE_TIME },
    { label: $r('app.string.up_to_label'), value: EffectiveDateMode.UNTIL, compId: CompId.UP_TO_LABEL },
    { label: $r('app.string.limited_times'), value: EffectiveDateMode.COUNT, compId: CompId.LIMITED_TIMES },
  ];

  // 临时的重复规则
  @Link tempRecurrence: Recurrence;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //系统语言
  @StorageLink('language') language: string = '';

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  ruleChange: Callback<string> = () => {
  };

  onClickHandler: () => void = () => {
  };

  @Styles
  Styles(){
    .width('100%')
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .hoverEffect(this.vm.disabled ? HoverEffect.None : HoverEffect.Highlight)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      }
    , normal: {
        .backgroundColor(Color.Transparent)
      }
    })
  }

  aboutToAppear(): void {
    this.effectiveDateMode = this.vm.effectiveDateMode;
  }

  getEffectiveModeText(): string {
    if (this.vm.effectiveDateMode === EffectiveDateMode.UNTIL) {
      return GlobalThis.getResourceStr($r('app.string.up_to_label'), this.language)
    } else if (this.vm.effectiveDateMode === EffectiveDateMode.COUNT) {
      return GlobalThis.getResourceStr($r('app.string.limited_times'), this.language)
    } else {
      return GlobalThis.getResourceStr($r('app.string.all_the_time'), this.language)
    }
  }

  getLimitTimeText(): string {
    const newLimitedTimes = this.tempRecurrence.count;
    return GlobalThis.getPluralStr($r('app.plural.repetition_times'), newLimitedTimes, this.language);
  }

  getUpToDateText(): string {
    const newUpToDate = new Date(this.tempRecurrence.getUntilMills(this.vm.timeZone));
    const upToText = GlobalThis.getResourceStr($r('app.string.up_to'), this.language);
    let option: Record<string, string> = { 'year': 'numeric', 'month': 'numeric', 'day': 'numeric' }
    if (newUpToDate.getFullYear() === new CalendarDate().getFullYear()) {
      option = { 'month': 'numeric', 'day': 'numeric' };
    }
    let upToString: string = '';
    if (this.tempRecurrence.isLunarEvent()) {
      upToString = LunarDateUtil.getLunarDate(newUpToDate);
    } else {
      upToString = newUpToDate.toLocaleDateString(this.language, option);
    }
    return upToText.replace('%s', upToString);
  }

  aboutToDisappear(): void {
  }

  updateTempRecurrenceByEffectiveDateMode() {
    if (this.vm.effectiveDateMode === EffectiveDateMode.UNTIL) {
      this.tempRecurrence.count = 0;
      const customTime: CustomTime = new CustomTime();
      customTime.setTime(this.initSelectedStartDate.getTime());
      customTime.addMonth(1);
      this.vm.upToDate.setTime(customTime.getTimeInMills());
      this.tempRecurrence.setUntil(this.vm.upToDate.getTime());
    } else if (this.vm.effectiveDateMode === EffectiveDateMode.COUNT) {
      this.tempRecurrence.until = '';
      this.tempRecurrence.setCount(this.vm.limitedTimes);
    } else if (this.vm.effectiveDateMode === EffectiveDateMode.FOREVER) {
      this.tempRecurrence.count = 0;
      this.tempRecurrence.until = '';
    }
    this.ruleChange(this.tempRecurrence.format());
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  EffectiveDateContainerText() {
    Text($r('app.string.effective_date'))
      .align(Alignment.Start)
      .fontSize($r('sys.float.Subtitle_M'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .id(CompId.REPEAT)
      .width(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? undefined : '100%')
      .margin({
        end: LengthMetrics.vp(16),
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        top: this.isChangeLayout() ?
        LengthMetrics.vp(FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
      })
  }

  /*有效日期按钮*/
  @Builder
  buildEffectiveDateContent() {
    this.EffectiveDateContainerText();

    Row() {
      Text(this.getEffectiveModeText())
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_secondary'))
        .layoutWeight(1)
        .textAlign(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? TextAlign.End : TextAlign.Start)
        .margin({
          bottom: this.vm.disabled ? LengthMetrics.vp(0) : this.isChangeLayout() ? LengthMetrics.vp(
            FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
          top: this.vm.disabled ? LengthMetrics.vp(0) : this.isChangeLayout() ? LengthMetrics.vp(4)
            : LengthMetrics.vp(0)
        })
        .padding({ end: this.vm.disabled ? LengthMetrics.vp(8) : LengthMetrics.vp(0) })
      if (!this.vm.disabled) {
        this.BuildRightArrow();
      }
    }
    .margin({ start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0) })
    .layoutWeight(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 1 : undefined)
  }

  build() {
    Column() {
      if (this.isChangeLayout()) {
        Column() {
          this.buildEffectiveDateContent();
        }
        .alignItems(HorizontalAlign.Start)
        .Styles()
      } else {
        Row() {
          this.buildEffectiveDateContent();
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .Styles()
      }
      if (this.vm.effectiveDateMode === EffectiveDateMode.UNTIL) {
        DividerLine();
        this.buildUpToDateRow();
      }
      if (this.vm.effectiveDateMode === EffectiveDateMode.COUNT) {
        DividerLine();
        this.buildLimitedTimesRow();
      }
    }
    .bindMenu(this.vm.showEffectiveDateMenu, this.vm.disabled ? undefined : this.buildEffectiveDateMenu, {
      placement: Placement.BottomRight,
      onDisappear: () => {
        this.vm.showEffectiveDateMenu = false;
      }
    })
    .onClick(() => {
      this.onClickHandler?.();
      this.vm.showEffectiveDateMenu = !this.vm.showEffectiveDateMenu;
    })
  }

  @Builder
  buildUpToDateRow() {
    Column() {
      if (this.isChangeLayout()) {
        Column() {
          this.buildContent();
        }
        .alignItems(HorizontalAlign.Start)
        .Styles()
      } else {
        Row() {
          this.buildContent();
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .Styles()
      }
      // 非编辑界面不展示pick，并且可以实现点击隐藏和展示
      if (!this.vm.disabled && this.vm.isShowTimePick) {
        UpToDatePicker({
          vm: this.vm,
          tempRecurrence: $tempRecurrence,
          onChange: () => {
            this.ruleChange(this.tempRecurrence.format());
          }
        })
      }
    }
    .onClick(() => {
      this.vm.isShowTimePick = !this.vm.isShowTimePick;
      this.onClickHandler?.();
    })
  }

  @Builder
  buildLimitedTimesRow() {
    Column() {
      if (this.isChangeLayout()) {
        Column() {
          this.buildContent();
        }
        .alignItems(HorizontalAlign.Start)
        .Styles()
      } else {
        Row() {
          this.buildContent();
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .Styles()
      }
      // 非编辑界面不展示pick，并且可以实现点击隐藏和展示
      if (!this.vm.disabled && this.vm.isShowLimitsTimePick) {
        LimitedTimesPicker({
          vm: this.vm,
          tempRecurrence: $tempRecurrence,
          onChange: () => {
            this.ruleChange(this.tempRecurrence.format());
          }
        })
      }
    }
    .onClick(() => {
      this.vm.isShowLimitsTimePick = !this.vm.isShowLimitsTimePick;
      this.onClickHandler?.();
    })
  }

  @Builder
  BuildRightArrow() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
        24
      ))
      .fontColor([$r('sys.color.icon_fourth')])
      .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
      .id('arrow_right')
      .align(Alignment.Center)
  }

  @Builder
  buildContent() {
    Text(this.getEffectiveModeText())
      .align(Alignment.Start)
      .fontSize($r('sys.float.Subtitle_M'))
      .fontWeight(FontWeight.Medium)
      .fontColor($r('sys.color.font_primary'))
      .id(CompId.REPEAT)
      .width(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? undefined : '100%')
      .margin({
        end: LengthMetrics.vp(16),
        start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8),
        top: this.isChangeLayout() ?
        LengthMetrics.vp(FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0)
      })

    Row() {
      Text(this.tempRecurrence.hasUntil() ? this.getUpToDateText() : this.getLimitTimeText())
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_secondary'))
        .layoutWeight(1)
        .textAlign(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? TextAlign.End : TextAlign.Start)
        .margin({
          bottom: this.vm.disabled ? LengthMetrics.vp(0) : this.isChangeLayout() ? LengthMetrics.vp(
            FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)) : LengthMetrics.vp(0),
          top: this.vm.disabled ? LengthMetrics.vp(0) : this.isChangeLayout() ? LengthMetrics.vp(4)
            : LengthMetrics.vp(0)
        })
        .padding({ end: this.vm.disabled ? LengthMetrics.vp(8) : LengthMetrics.vp(0) })
      if (!this.vm.disabled) {
        this.BuildRightArrow();
      }
    }
    .margin({ start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0) })
    .layoutWeight(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 1 : undefined)
  }

  @Builder
  buildEffectiveDateMenu() {
    RadioListDialog({
      title: $r('app.string.effective_date'),
      options: this.effectiveDateRadioOptions,
      compId: CompId.EFFECTIVE_DATE,
      checkValue: this.effectiveDateMode,
      style: RadioListStyle.Menu,
      onChange: (value: number) => {
        this.effectiveDateMode = value;
        this.vm.onEffectiveDateModeChanged(value);
        this.updateTempRecurrenceByEffectiveDateMode();
      },
    }).width(224)
  }
}

/**
 * 截止日期选择器组件
 */
@Component
struct UpToDatePicker {
  @Link @Watch('recurrenceChange') tempRecurrence: Recurrence;

  @StorageLink('initSelectedStartDate') initSelectedStartDate: CalendarDate = new CalendarDate();

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @ObjectLink vm: EffectiveDateViewModel;

  @State isLunar: boolean = false;

  onChange: Callback<void> = () => {
  };

  aboutToAppear(): void {
    Log.info(TAG, `UpToDatePicker aboutToAppear, initSelectedStartDate = ${this.initSelectedStartDate}`);
    this.isLunar = this.tempRecurrence.isLunarEvent();
    if (this.tempRecurrence.hasUntil()) {
      this.vm.upToDate.setTime(this.tempRecurrence.getUntilMills(this.vm.timeZone));
    } else {
      const customTime: CustomTime = new CustomTime();
      customTime.setTime(this.initSelectedStartDate.getTime());
      customTime.addMonth(1);
      this.vm.upToDate.setTime(customTime.getTimeInMills());
      this.tempRecurrence.setUntil(this.vm.upToDate.getTime());
    }
    // 初始化的时候也需要把初值传递给上层，避免未改变值无法向上层传递
    this.onChange();
  }

  build() {
    Column() {
      DatePicker({
        start: new Date(),
        selected: this.vm.upToDate
      }).onDateChange((value: Date) => {
        this.vm.upToDate = value;
        this.vm.upToDate.setHours(MAX_HOUR);
        this.vm.upToDate.setMinutes(MAX_MINUTES);
        this.tempRecurrence.setUntil(this.vm.upToDate.getTime());
        this.onChange();
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
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE,
              14)
          }
        })
        .lunar(this.isLunar)
    }
    .width('100%')
    .padding({
      top: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
  }

  recurrenceChange() {
    this.isLunar = this.tempRecurrence.isLunarEvent();
  }
}

/**
 * 限定次数选择器组件
 */
@Component
struct LimitedTimesPicker {
  @Link tempRecurrence: Recurrence;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @ObjectLink vm: EffectiveDateViewModel;

  private limitedTimesList: string[] = [];

  aboutToAppear(): void {
    for (let i = 1; i <= MAX_LIMIT_TIMES; i++) {
      this.limitedTimesList.push(i + '');
    }
    if (this.tempRecurrence.count > 0) {
      this.vm.limitedTimes = this.tempRecurrence.count;
    } else {
      this.tempRecurrence.setCount(this.vm.limitedTimes);
    }
    // 初始化的时候也需要把初值传递给上层，避免未改变值无法向上层传递
    this.onChange();
  }

  onChange: Callback<void> = () => {
  };

  build() {
    Column() {
      TextPicker({ range: this.limitedTimesList, selected: this.vm.limitedTimes - 1 })
        .onChange((value: string | string[], index: number | number[]) => {
          console.info('Picker item changed, value: ' + value + ', index: ' + index)
          this.vm.limitedTimes = index as number + 1;
          this.tempRecurrence.setCount(this.vm.limitedTimes);
          this.onChange();
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
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE,
              14)
          }
        })
    }
    .padding({
      top: $r('sys.float.padding_level8'),
      bottom: $r('sys.float.padding_level8'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
  }
}