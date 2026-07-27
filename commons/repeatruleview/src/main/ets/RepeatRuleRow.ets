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
  BigFontSize,
  CalendarContract,
  CalendarDate,
  CommonInnerEvent,
  CompId,
  DAY_PER_WEEK,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  FontSizeScaleUtils,
  Log,
  NavPathManager,
  NavPathName,
  RouterName
} from '@app/common';
import { customPageNavParam, CustomRepeatSetPage } from './CustomRepeatSetPage';
import { Frequency, RepeatType, Weeks } from '@app/feature.repeatrule/src/main/ets/Constants';
import { SelectRepeatTypeDialog } from './SelectRepeatTypeDialog';
import { Recurrence } from '@app/feature.repeatrule/src/main/ets/Recurrence';
import { Callback } from '@ohos.base';
import { getWeekOfDate } from '@app/feature.repeatrule/src/main/ets/utils/TimeUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { EffectiveDate } from './EffectiveDate';
import { EffectiveDateViewModel } from './EffectiveDateViewModel';

const TAG: string = 'RepeatRuleRow';

@Component
export struct RepeatRuleRow {
  @State @Watch('initByRrule') rrule: string = '';

  @State effectiveDateVM: EffectiveDateViewModel = new EffectiveDateViewModel();

  // 是否全天日程
  @Prop mIsAllDay: boolean;

  @Prop @Watch('onCalendarTypeChange') mEventInfo: AgendaEventInfo;

  private onCalendarTypeChange() {
    if (this.rrule !== this.mEventInfo?.mRepeatRule) {
      this.rrule = this.mEventInfo?.mRepeatRule;
      return;
    }
    if (this.mEventInfo?.isLunarEvent()) {
      this.recurrence.setLunarEvent();
    } else {
      this.recurrence.setSolarEvent();
    }
    if (this.recurrence.freq !== Frequency.YEARLY && this.mEventInfo?.isLunarEvent()) {
      this.recurrence.resetAll();
    }
    this.onRepeatSetDone();
  }

  @StorageLink('initSelectedStartDate') @Watch('onInitSelectedStartDateChange') initSelectedStartDate: CalendarDate = new CalendarDate();

  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  @State recurrence: Recurrence = new Recurrence();

  @State repeatShowStr: ResourceStr = '';

  @Prop themeColor: ResourceColor;

  @State showCustomRepeatDialog: boolean = false;

  // 预览框点击不需要有选中反馈
  @Prop toggleEnabled: boolean = true;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State showRepeatMenu: boolean = false;

  // 是否禁用编辑
  private disabled: boolean = false;

  //svg模糊度
  private globalAntialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  private sheetOptions: SheetOptions | null = {
    height: SheetSize.LARGE,
    detents: [SheetSize.LARGE, 0, 0],
    dragBar: false,
    showClose: false,
    preferType: SheetType.CENTER,
    backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
    maskColor: $r('sys.color.ohos_id_color_mask_thin'),
    blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
    onAppear: () => {
      Log.info(TAG, 'CustomRepeat BindSheet onAppear.');
    },
    onDisappear: () => {
      Log.info(TAG, 'CustomRepeat BindSheet onDisappear.');
      this.showCustomRepeatDialog = false;
    }
  };

  onNewRuleSetCallback: Callback<string> = () => {
  };

  onAgendaCalendarTypeChange: Callback<number> = () => {
  };


  private onClickHandler: () => void = () => {
  };

  private cardToMonthHandler: () => void = (): void => {
    this.showCustomRepeatDialog = false;
  };

  private closeDialog: () => void = (): void => {
    this.showCustomRepeatDialog = false;
  };

  private recurrenceSetHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    Log.info(TAG, `recurrenceSetHandler: ${JSON.stringify(data)}`);
    this.recurrence = Recurrence.parse(data.data?.recurrence);
    this.onRepeatSetDone();
  };

  aboutToAppear(): void {
    this.initByRrule();
    this.emitEvent();
  }

  // 监听弹窗和半模态展示变化
  emitEvent() {
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closeDialog);
    this.emitterCollector.on({ eventId: CommonInnerEvent.RECURRENCE_SET }, this.recurrenceSetHandler);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
    this.sheetOptions = null;
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  onLanguageChange(): void {
    this.repeatShowStr = this.recurrence.toString(this.language);
  }

  @Builder
  RepeatContainerText() {
    Text($r('app.string.event_add_repeat'))
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

  @Builder
  RepeatDisableText() {
    Text(this.repeatShowStr)
      .fontSize($r('sys.float.Body_M'))
      .fontWeight(FontWeight.Regular)
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .textAlign(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? TextAlign.End : TextAlign.Start)
      .layoutWeight(1)
      .padding({ end: LengthMetrics.vp(8) })
  }

  @Builder
  CaringModeContent() {
    this.RepeatContainerText();

    Row() {
      if (this.disabled) {
        this.RepeatDisableText();
      } else {
        Text(this.repeatShowStr)
          .fontSize($r('sys.float.Body_M'))
          .fontWeight(FontWeight.Regular)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_secondary'))
          .layoutWeight(1)
          .textAlign(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? TextAlign.End : TextAlign.Start)
          .margin({
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
          .id('arrow_right')
          .align(Alignment.Center)
      }
    }
    .margin({ start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(0) })
    .layoutWeight(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 1 : undefined)
  }

  @Builder
  CaringModeContentVerticalLayout() {
    Column() {
      this.CaringModeContent();
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
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
    .bindMenu(this.showRepeatMenu, this.disabled ? undefined : this.buildRepeatMenu, {
      placement: Placement.BottomRight,
      onDisappear: () => {
        this.showRepeatMenu = false;
      }
    })
    .bindSheet($$this.showCustomRepeatDialog, this.buildCustomRepeatPage(), this.sheetOptions)
    .onClick(() => {
      this.onClickHandler?.();
      this.showRepeatMenu = true;
    })
  }

  @Builder
  buildRepeatMenu() {
    SelectRepeatTypeDialog({
      supportTypes: this.getSupportTypes(),
      selectValue: this.getRepeatTypeByRecurrence(),
      callback: (repeatType: RepeatType) => {
        this.onRepeatDialogCallback(repeatType);
        this.showRepeatMenu = false;
      }
    }).width(224)
  }

  private getSupportTypes(): RepeatType[] {
    if (this.mEventInfo.isImportantEvent()) {
      return [RepeatType.NONE, RepeatType.MONTHLY, RepeatType.YEARLY, RepeatType.LUNAR_YEARLY];
    } else {
      return [RepeatType.NONE, RepeatType.DAILY, RepeatType.WEEKLY, RepeatType.MONTHLY, RepeatType.YEARLY,
        RepeatType.LUNAR_YEARLY, RepeatType.CUSTOM];
    }
  }

  build() {
    Column() {
      if (this.isChangeLayout()) {
        this.CaringModeContentVerticalLayout();
      } else {
        Row() {
          this.CaringModeContent();
        }
        .bindMenu(this.showRepeatMenu, this.disabled ? undefined : this.buildRepeatMenu, {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.showRepeatMenu = false;
          }
        })
        .bindSheet($$this.showCustomRepeatDialog, this.buildCustomRepeatPage(), this.sheetOptions)
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible)
        .constraintSize({ minHeight: 48 })
        .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
        .hoverEffect(this.disabled ? HoverEffect.None : HoverEffect.Highlight)
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.interactive_click'))
          }
        , normal: {
            .backgroundColor(Color.Transparent)
          }
        })
        .onClick(() => {
          this.onClickHandler?.();
          this.showRepeatMenu = !this.showRepeatMenu;
        })
      }
      if (this.rrule !== '') {
        DividerLine();
        this.BuildEffectiveDateRow();
      }
    }
    .enabled(this.toggleEnabled)
  }

  @Builder
  BuildEffectiveDateRow() {
    EffectiveDate({
      vm: this.effectiveDateVM,
      tempRecurrence: $recurrence,
      ruleChange: (newRrule: string) => {
        this.onNewRuleSetCallback(newRrule);
      },
      onClickHandler: () => {
        this.onClickHandler?.();
      }
    })
      .id(CompId.EFFECTIVE_DATE)
  }

  /*自定义重复半模态页面*/
  @Builder
  buildCustomRepeatPage() {
    CustomRepeatSetPage({})
  }

  private initByRrule() {
    if (this.recurrence === null || this.recurrence === undefined) {
      this.recurrence = new Recurrence();
    } else {
      this.recurrence.resetAll();
    }
    if (this.rrule !== null && this.rrule !== undefined && this.rrule.length > 0) {
      if (this.mEventInfo?.isLunarEvent()) {
        this.recurrence.setLunarEvent();
      } else {
        this.recurrence.setSolarEvent();
      }
      this.recurrence.parse(this.rrule);
    }
    this.effectiveDateVM.init(this.recurrence, this.disabled, this.mEventInfo.eventTimeZone);
    this.repeatShowStr = this.recurrence.toString(this.language);
  }

  private getRepeatTypeByRecurrence(): RepeatType {
    if (this.recurrence.isCustomFreq()) {
      return RepeatType.CUSTOM;
    }
    if (this.mEventInfo.isLunarEvent()) {
      this.recurrence.setLunarEvent();
      this.repeatShowStr = this.recurrence.toString(this.language);
      switch (this.recurrence.freq) {
        case Frequency.YEARLY:
          return RepeatType.LUNAR_YEARLY;
        default:
          return RepeatType.NONE;
      }
    } else {
      this.recurrence.setSolarEvent();
      this.repeatShowStr = this.recurrence.toString(this.language);
      switch (this.recurrence.freq) {
        case Frequency.DAILY:
          return RepeatType.DAILY;
        case Frequency.WEEKLY:
          return RepeatType.WEEKLY;
        case Frequency.MONTHLY:
          return RepeatType.MONTHLY;
        case Frequency.YEARLY:
          return RepeatType.YEARLY;
        default:
          return RepeatType.NONE;
      }
    }
  }

  private getWeekNumOfDate(date: number): number {
    // 参考双框架，周数为：(日期+6)/7
    let weekNum: number = Math.floor((date + DAY_PER_WEEK - 1) / DAY_PER_WEEK);
    if (weekNum === 5) {
      weekNum = -1;
    }
    return weekNum;
  }

  private onInitSelectedStartDateChange() {
    if (this.disabled) {
      return;
    }
    const byWeekDay: Weeks = getWeekOfDate(this.initSelectedStartDate);
    const byMonthDay: number = this.initSelectedStartDate.getDate();
    const byWeekNum: number = this.getWeekNumOfDate(byMonthDay);
    if (this.recurrence.isCustomFreq()) {
      switch (this.recurrence.freq) {
        case Frequency.MONTHLY:
          if (this.recurrence.byWeekDay.length > 0 &&
            this.recurrence.byWeekDay.length === this.recurrence.byWeekNum.length) {
            this.recurrence.byWeekDay = [byWeekDay];
            this.recurrence.byWeekNum = [byWeekNum];
          } else {
            this.recurrence.byMonthDay = [byMonthDay];
          }
          break;
        case Frequency.YEARLY:
          if (this.mEventInfo.isLunarEvent()) {
            this.recurrence.setToLunarYearly(this.initSelectedStartDate);
          } else {
            this.recurrence.setToYearly(this.initSelectedStartDate.getMonth(), byMonthDay);
          }
          break;
        default:
          break;
      }
    } else {
      switch (this.recurrence.freq) {
        case Frequency.WEEKLY:
          this.recurrence.setToWeekly([byWeekDay]);
          break;
        case Frequency.MONTHLY:
          this.recurrence.setToMonthlyByDay(byMonthDay);
          break;
        case Frequency.YEARLY:
          if (this.mEventInfo.isLunarEvent()) {
            this.recurrence.setToLunarYearly(this.initSelectedStartDate);
          } else {
            this.recurrence.setToYearly(this.initSelectedStartDate.getMonth(), byMonthDay);
          }
          break;
        default:
          break;
      }
    }
    this.onRepeatSetDone();
  }

  private onRepeatDialogCallback(value: RepeatType): void {
    if (value === RepeatType.CUSTOM) {
      this.jumpToCustomRepeatPage();
      return;
    }
    if (value === RepeatType.LUNAR_YEARLY) {
      this.recurrence.setLunarEvent();
    } else {
      this.recurrence.setSolarEvent();
    }
    switch (value) {
      case RepeatType.DAILY:
        this.recurrence.setToDaily();
        break;
      case RepeatType.WEEKLY:
        const week: Weeks = getWeekOfDate(this.initSelectedStartDate);
        this.recurrence.setToWeekly([week]);
        break;
      case RepeatType.MONTHLY:
        this.recurrence.setToMonthlyByDay(this.initSelectedStartDate.getDate());
        break;
      case RepeatType.YEARLY:
        this.recurrence.setToYearly(this.initSelectedStartDate.getMonth(), this.initSelectedStartDate.getDate());
        break;
      case RepeatType.LUNAR_YEARLY:
        this.recurrence.setToLunarYearly(this.initSelectedStartDate);
        break;
      default:
        this.recurrence.setToNoneRepeat();
        break;
    }
    this.onRepeatSetDone();
  }

  private onRepeatSetDone() {
    this.repeatShowStr = this.recurrence.toString(this.language);
    if (this.recurrence.isLunarEvent()) {
      this.onAgendaCalendarTypeChange(CalendarContract.AgendaCalendarType.LUNAR);
    } else {
      this.onAgendaCalendarTypeChange(CalendarContract.AgendaCalendarType.SOLAR);
    }
    this.onNewRuleSetCallback(this.recurrence.format());
    Log.info(TAG, `onRepeatSetDone recurrence untilMills:` +
      `${this.recurrence.getUntilMills(this.mEventInfo.eventTimeZone)}`);
  }

  private jumpToCustomRepeatPage(): void {
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.CUSTOM_REPEAT,
      routerName: this.routerName,
      param: {
        inPopUp: true,
        recurrenceString: this.recurrence.format(),
        routerName: this.routerName
      } as customPageNavParam
    });
  }
}

@Component
export struct DividerLine {
  private paddingLeft: Length = $r('sys.float.padding_level4');

  private paddingRight: Length = $r('sys.float.padding_level4');

  build() {
    Divider()
      .height('1px')
      .strokeWidth('1px')
      .color($r('sys.color.comp_divider'))
      .width('100%')
      .padding({ left: this.paddingLeft, right: this.paddingRight })
  }
}