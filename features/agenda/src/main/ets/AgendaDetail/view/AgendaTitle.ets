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
  BigFontSize,
  CalendarContract,
  CalendarDate,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  FontSizeScaleUtils,
  getAdaptImportantTime,
  GlobalDataKeys,
  GlobalThis,
  Log,
  LunarDateUtil,
  maskString,
  MeetingInfoService,
  MILLS_PER_HOUR,
  MILLS_PER_MINUTE,
  NotifyHandlerEnum,
  ServiceEnum,
  ServiceManager,
  TabType,
  ThrottleFunction,
  TimeZoneUtil,
} from '@app/common';
import { OneKeyServiceButton, OneKeyServiceButtonType } from '@app/common.components';
import { i18n } from '@kit.LocalizationKit';
import { EventLocationInfo } from './EventLocationInfo';
import { emitter } from '@kit.BasicServicesKit';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { common } from '@kit.AbilityKit';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import intl from '@ohos.intl';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'AgendaTitle';
const ERR_ABILITY_NOT_EXIST = 16000001;

@Component
export struct AgendaTitle {
  @Prop @Watch('infoChanged') info: AgendaEventInfo | undefined;

  @Prop @Watch('displayStartMillsChanged') displayStartMills: number;

  @Prop @Watch('displayEndMillsChanged') displayEndMills: number;

  @Prop searchText: string = '';

  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayDate: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State singleTimeFirstLine: string = '';

  @State singleTimeSecondLine: string = '';

  @State timeZoneOffset: string = '';

  @State displaySingleRow: boolean = true;

  @State mStartTime: string = '';

  @State mEndTime: string = '';

  @State title: string = '';

  @Prop disableCopy: boolean = false;

  @State haveMeeting: boolean = false;

  @State isHoverShow: boolean = false;

  @Prop isLongClickPreview: boolean = false;

  @Prop marginBottom: number = 12;

  @StorageProp('themeColor') themeColor: string = '';

  private meetingLink: string = '';

  private disabled: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private isPreview: boolean = false;

  private hourCycleChangeHandler: () => void = () => {
  };

  private systemDataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
  };

  @StorageProp('bgThemeColor') bgThemeColor: string = '';

  private backgroundColorOverlay: string = '#ffffff';

  // 详情页是否单独页（不与日程列表左右分栏），并且从月视图跳转过来
  private isFromMonthView: boolean = false;

  // 用户接收状态(共享日程当前用户为受邀者时)，0拒绝 1待定 2接受
  @State userHandler: NotifyHandlerEnum = NotifyHandlerEnum.DEFAULT;

  private onClickHandler: () => void = () => {
  };

  private showTimeZoneId: string = '';

  private agendaItemSubFontSize: Resource = DeviceConfig.instance().config.agendaItemSubFontSize;

  onSystemDataChange(data: emitter.EventData): void {
    if (data?.data?.table !== 'MeetingInfo') {
      return;
    }
    Log.info(TAG, 'systemDataChanged');
    this.refreshMeetingInfo();
  }

  onDisplayDateChange() {
    this.initInfo();
  }

  subscribeEvents(): void {
    this.hourCycleChangeHandler = () => {
      this.onHourCycleChange();
    };
    this.systemDataChangeHandler = (data: emitter.EventData) => {
      this.onSystemDataChange(data);
    }
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_HOUR_CYCLE_CHANGED }, this.hourCycleChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.systemDataChangeHandler);
  }

  unsubscribeEvents(): void {
    emitter.off(CommonInnerEvent.SYSTEM_HOUR_CYCLE_CHANGED, this.hourCycleChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.systemDataChangeHandler);
  }

  aboutToAppear(): void {
    this.subscribeEvents();
    this.initInfo();
    this.refreshMeetingInfo();
    Log.info(TAG, `agenda title aboutToAppear over`);
  }

  aboutToDisappear(): void {
    this.unsubscribeEvents();
    this.info = undefined;
  }

  async refreshMeetingInfo() {
    // 去抖，防止数据竞争
    ThrottleFunction.instance().debounce(TAG + this.info?.mId, async () => {
      if (!this.info) {
        Log.info(TAG, 'info is null');
        return;
      }
      // 根据eventId 和会议开始时间找到对应的 会议Link
      let meetingInfo = await MeetingInfoService.INSTANCE.queryMeetingInfo(this.info.mId, this.displayStartMills);
      if (meetingInfo) {
        this.haveMeeting = true;
        this.meetingLink = meetingInfo.link;
      } else {
        this.haveMeeting = false;
        this.meetingLink = '';
      }
      Log.info(TAG, `have meeting minute ${this.haveMeeting}`);
    }, 100)
  }

  @Builder
  buildService() {
    Row() {
      if (this.haveMeeting && this.meetingLink.length > 0) {
        if (this.info?.isOneKeyService()) {
          OneKeyServiceButton({
            info: this.info,
            serviceUri: this.info?.mHwextServiceUri,
            type: OneKeyServiceButtonType.LARGE,
            viewType: TabType.AGENDA_DETAIL,
            buttonPadding: 6,
          })
            .padding({ left: 24 })
        }
      }
    }.width(!this.isPreview ? '100%' : 'calc(100% - 12vp)')
  }

  build() {
    if (this.isPreview) {
      Row() {
        Column() {
          this.buildAgendaTitle();
          this.buildAgendaTimeAndLocation();
          if (!this.disabled) {
            this.buildService()
          }
          if (this.checkServiceButtonPosition(true)) {
            OneKeyServiceButton({
              info: this.info,
              serviceUri: this.info?.mHwextServiceUri,
              type: OneKeyServiceButtonType.LARGE,
              viewType: TabType.AGENDA_DETAIL,
              buttonPadding: 12,
              needCenter: false,
            })
          }
        }

        Blank();
        this.builderRightArrow();
      }
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .alignItems(VerticalAlign.Center)
      .id(CompId.AGENDA_INFO)
      .padding({
        left: 12,
        right: 12,
        top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 12),
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 12)
      })
      .onClick(() => {
        this.onClickHandler();
      })
      .onHover((isHover) => {
        this.isHoverShow = isHover;
      })
      .onAppear(() => {
        Log.info(TAG, `agenda title row appear`);
      })
      .margin({ bottom: this.marginBottom })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(this.isPreview ? $r('sys.float.corner_radius_level6') :
        this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
    } else {
      this.agendaTitle();
    }
  }

  @Builder
  agendaTitle() {
    Column() {
      this.buildAgendaTitle();
      this.buildAgendaTimeAndLocation();
      if (!this.disabled) {
        this.buildService();
      }
      if (this.checkServiceButtonPosition(true)) {
        OneKeyServiceButton({
          info: this.info,
          serviceUri: this.info?.mHwextServiceUri,
          type: OneKeyServiceButtonType.LARGE,
          viewType: TabType.AGENDA_DETAIL,
          buttonPadding: 12,
          needCenter: false,
        })
      }
    }
    .onAppear(() => {
      Log.info(TAG, `agenda title column appear`);
    })
    .id(CompId.AGENDA_INFO)
    .padding({
      left: 12,
      right: 12,
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 12),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 12)
    })
    .focusBox({
      margin: LengthMetrics.px(-5),
    })
    .onClick(() => {
      this.onClickHandler();
    })
    .onHover((isHover) => {
      this.isHoverShow = isHover;
    })
    .accessibilityText(this.title)
    .accessibilityDescription(' ')
    .margin({ bottom: this.marginBottom })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.isPreview ? $r('sys.float.corner_radius_level6') :
      this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
  }

  //右箭头
  @Builder
  builderRightArrow() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
        24
      ))
      .visibility((this.isHoverShow || !this.needCommerce) ? Visibility.Visible : Visibility.Hidden)
      .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
  }

  onHourCycleChange(): void {
    Log.info(TAG, 'On HourCycle change');
    this.updateStartEndTime();
  }

  /**
   * 获取日程时间戳格式化后的时间显示内容
   *
   * @param time 日程时间
   * @returns 上午xx:xx
   */
  getFormatTimeStr(time: number, timeZone?: string) {
    const dateOfTime = new CalendarDate(time);
    let options: Record<string, string | Boolean> = {
      'hour': 'numeric',
      'minute': '2-digit',
      'hour12': !i18n.System.is24HourClock()
    }
    timeZone ? options['timeZone'] = timeZone : '';
    return DateUtil.intlDateFormatChineseStyle(dateOfTime, options);
  }

  /**
   * 获取日程时间戳格式化后的日期显示内容
   *
   * @param time 日程时间
   * @returns xxxx年xx月xx日 星期x
   */
  getFormatDateStr(time: number) {
    const dateOfTime = new CalendarDate(time);
    const yearOfTime = dateOfTime.getFullYear();
    const yearOfNow = new CalendarDate().getFullYear();
    let options: Record<string, string | Boolean> = yearOfTime === yearOfNow ? {
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
    } : {
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
      'year': 'numeric'
    };
    if (this.info?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      return DateUtil.lunarDateString(dateOfTime);
    }
    return DateUtil.intlDateFormatChineseStyle(dateOfTime, options);
  }

  /**
   * 获取日程时间的文字显示内容
   *
   * @param time 日程时间
   */
  getTimeStr(time: number, timeZone?: string): string {
    if (!this.info) {
      Log.info(TAG, 'info is null');
      return '';
    }
    const dateOfTime = new CalendarDate(time);
    const yearOfTime = dateOfTime.getFullYear();
    const yearOfNow = new CalendarDate().getFullYear();
    let mIsAllDay: boolean = this.info?.mIsAllDay
    let options: Record<string, string | Boolean> = this.isImportantDay() ?
      (mIsAllDay ? {
        'month': 'long',
        'day': 'numeric',
      } : {
        'month': 'long',
        'day': 'numeric',
      }) : (mIsAllDay ? {
        'month': 'long',
        'day': 'numeric',
        'weekday': 'long'
      } : {
        'month': 'long',
        'day': 'numeric',
        'weekday': 'long',
      });
    if (yearOfTime !== yearOfNow) {
      // 非本年时增加年份字段
      options = this.isImportantDay() ? (mIsAllDay ? {
        'month': 'long',
        'day': 'numeric',
        'year': 'numeric'
      } : {
        'month': 'long',
        'day': 'numeric',
        'year': 'numeric'
      }) : (mIsAllDay ? {
        'month': 'long',
        'day': 'numeric',
        'weekday': 'long',
        'year': 'numeric'
      } : {
        'month': 'long',
        'day': 'numeric',
        'weekday': 'long',
        'year': 'numeric'
      });
    }
    if (timeZone) {
      options['timeZone'] = timeZone;
    }
    if (this.info?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      if (this.isImportantDay()) {
        return LunarDateUtil.getLunarDate(dateOfTime)
      } else {
        return DateUtil.lunarDateString(dateOfTime);
      }
    }
    return DateUtil.intlDateFormatChineseStyle(dateOfTime, options);
  }

  @Builder
  buildAgendaTitle() {
    Row() {
      Text(this.title)
        .direction(Direction.Ltr)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontFeature('\"ss08\" 1')
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
        .textSelectable(TextSelectableMode.SELECTABLE_FOCUSABLE)
        .constraintSize({ maxWidth: this.userHandler != NotifyHandlerEnum.DEFAULT ||
          (this.info && this.info?.mAttachmentCount > 0 && this.isLongClickPreview) ? '90%' : '100%' })

      if (this.info && (this.info?.mAttachmentCount > 0) && this.isLongClickPreview) {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize($r('sys.float.Subtitle_M'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
          .fontColor([$r('sys.color.font_primary')])
          .width(26)
          .draggable(false)
      }
    }
    .alignItems(VerticalAlign.Center)
    .accessibilityGroup(true)
    .accessibilityText(this.title)
    .accessibilityDescription(' ')
    .width(!this.isPreview ? '100%' : 'calc(100% - 12vp)')
  }

  private getStatusFontColor(status: NotifyHandlerEnum): ResourceColor {
    if (status === NotifyHandlerEnum.ACCEPT) {
      return this.backgroundColorOverlay;
    } else if (status === NotifyHandlerEnum.REFUSE) {
      return $r('sys.color.font_secondary');
    } else {
      return this.themeColor;
    }
  }

  private getStatusBgColor(status: NotifyHandlerEnum): ResourceColor {
    if (status === NotifyHandlerEnum.ACCEPT) {
      return this.themeColor;
    } else if (status === NotifyHandlerEnum.REFUSE) {
      return $r('sys.color.comp_background_tertiary');
    } else {
      return this.bgThemeColor;
    }
  }

  getSecondLineAccessibilityText(): string {
    if (this.info?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      return '农历' + this.singleTimeSecondLine
    } else {
      return this.singleTimeSecondLine
    }
  }

  getStartTimeAccessibilityText(): string {
    if (this.info?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      // 播报：开始 农历六月初五 星期三
      return this.getResourceStr($r('app.string.start_date')) + '农历' +
      this.mStartTime.substring(2, this.mStartTime.length + 1)
    } else {
      return this.mStartTime
    }
  }

  getEndTimeAccessibilityText(): string {
    if (this.info?.mEventCalendar === CalendarContract.AgendaCalendarType.LUNAR) {
      return this.getResourceStr($r('app.string.end_date')) + '农历' +
      this.mEndTime.substring(2, this.mEndTime.length + 1)
    } else {
      return this.mEndTime
    }
  }

  @Builder
  buildDisplaySingleRow() {
    Row() {
      SymbolGlyph($r('sys.symbol.clock'))
        .fontSize(14)
        .margin({ end: LengthMetrics.vp(8) })
        .fontColor([$r('sys.color.icon_secondary')])
        .alignSelf(ItemAlign.Start)
        .flexShrink(1)
      Column() {
        Text(this.singleTimeFirstLine)
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Clip })
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(4)
          .flexShrink(1)
          .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
          .accessibilityDescription(' ')
        Text(this.singleTimeSecondLine)
          .accessibilityText(this.getSecondLineAccessibilityText())
          .accessibilityDescription(' ')
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Clip })
          .fontColor($r('sys.color.font_secondary'))
          .maxLines(4)
          .flexShrink(1)
          .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .alignSelf(ItemAlign.Start)
    .visibility(this.isImportantDay() ? Visibility.None : Visibility.Visible)
  }

  @Builder
  buildDisplayMultipleRow() {
    Row() {
      SymbolGlyph($r('sys.symbol.clock'))
        .fontSize(14)
        .margin({ end: LengthMetrics.vp(8) })
        .fontColor([$r('sys.color.icon_secondary')])
        .alignSelf(ItemAlign.Start)
        .flexShrink(1)
      Text(this.mStartTime)
        .accessibilityText(this.getStartTimeAccessibilityText())
        .accessibilityDescription(' ')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_secondary'))
        .maxLines(4)
        .flexShrink(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
    }
    .width('100%')

    Row() {
      SymbolGlyph($r('sys.symbol.clock'))
        .fontSize(14)
        .margin({ end: LengthMetrics.vp(8) })
        .fontColor([$r('sys.color.icon_secondary')])
        .alignSelf(ItemAlign.Start)
        .flexShrink(1)
      Text(this.mEndTime)
        .accessibilityText(this.getEndTimeAccessibilityText())
        .accessibilityDescription(' ')
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_secondary'))
        .flexShrink(1)
        .copyOption(this.disableCopy ? CopyOptions.None : CopyOptions.LocalDevice)
    }
    .width('100%')
    .visibility(this.isImportantDay() ? Visibility.None : Visibility.Visible)
  }

  getHolidayTimeStr() {
    if (this.info) {
      const DATE_INTL_OPT: intl.DateTimeOptions = { month: 'long', day: 'numeric', weekday: 'long' };
      const stamp: number = this.info.mBegin;
      const dateStr: string = DateUtil.intlDateFormatChineseStyle(new CalendarDate(stamp), DATE_INTL_OPT)
      return `${dateStr}`;
    }
    return '';
  }

  @Builder
  buildAgendaTimeAndLocation() {
    if (this.info?.isHoliday()) {
      Column() {
        Text() {
          Span(this.getHolidayTimeStr());
        }
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')
        .flexShrink(1)

        Text($r('app.string.all_day'))
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
          .flexShrink(1)
      }
      .width(!this.isPreview ? '100%' : 'calc(100% - 12vp)')
    } else {
      Row() {
        Column({ space: 6 }) {
          if (this.displaySingleRow) {
            this.buildDisplaySingleRow();
          } else {
            this.buildDisplayMultipleRow();
          }
          // 地址显示
          if (this.info && this.info.mLocation?.length > 0) {
            EventLocationInfo({
              disableCopy: this.disableCopy,
              isLongClickPreview: this.isLongClickPreview,
              mLocation: this.info?.mLocation,
              mLatitude: this.info?.mLatitude,
              mLongitude: this.info?.mLongitude,
              isPreview: this.isPreview,
              onClickHandler: () => {
                this.onClickHandler();
              }
            })
          }
        }
        .flexShrink(1)
        .margin({
          top: LengthMetrics.vp(12),
          bottom: LengthMetrics.vp(this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? 0 : 4),
          end: LengthMetrics.vp(this.checkServiceButtonPosition(false) ? 8 : 0),
        })
        .layoutWeight(1)

        if (this.checkServiceButtonPosition(false)) {
          OneKeyServiceButton({
            info: this.info,
            serviceUri: this.info?.mHwextServiceUri,
            type: OneKeyServiceButtonType.LARGE,
            viewType: TabType.AGENDA_DETAIL,
            buttonPadding: 12,
          })
        }
      }
      .width(!this.isPreview ? '100%' : 'calc(100% - 12vp)')
    }
  }

  // 是否显示一键入会按钮
  private checkServiceButtonPosition(isBigFont: boolean) {
    return this.info?.isOneKeyService() && !this.disabled && !this.haveMeeting &&
      (isBigFont ? this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL :
        this.fontSizeScale <= BigFontSize.BIG_FONT_SIZE_SPECIAL)
  }

  private infoChanged() {
    this.initInfo();
    this.refreshMeetingInfo();
  }

  private displayStartMillsChanged() {
    Log.info(TAG, 'displayStartMillsChanged');
    // 针对重复的重要日日程，需要将循环倒数日日期适配到目标日期
    if (this.info?.isImportantEvent() && this.info.isRepeatEvent()) {
      this.refreshRepeatImportantDisplayStartMills();
    }
    this.updateStartEndTime();
    this.refreshMeetingInfo();
    this.getAgendaTitle();
  }

  refreshRepeatImportantDisplayStartMills() {
    if (!this.info) {
      Log.warn(TAG, 'repeat important info is null');
      return;
    }
    const selectDate = new CalendarDate(this.displayDate);
    this.displayStartMills = getAdaptImportantTime(this.info.mEventCalendar,
      this.info.mBegin, this.info.mRepeatRule, selectDate);
    this.displayEndMills = this.displayStartMills + (this.info.mEnd - this.info.mBegin);
  }

  private displayEndMillsChanged() {
    this.updateStartEndTime();
  }

  private async initInfo() {
    if (!this.info) {
      Log.info(TAG, 'info is null');
      return;
    }
    this.info.mTitle = AgendaUtil.filterEmLabel(this.info.mTitle);
    this.info.mLocation = AgendaUtil.filterEmLabel(this.info.mLocation);
    await this.initTimeZone();
    this.getAgendaTitle();
    if (this.displayStartMills === 0 || this.displayEndMills === 0) {
      // 两个参数有一个为0 时，走入
      Log.error(TAG, `No Valid Input, begin = ${this.displayStartMills}, end = ${this.displayEndMills}`);
    }
    this.updateStartEndTime();
  }

  // 是否重要日
  private isImportantDay(): boolean {
    return this.info?.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES ||
      this.info?.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
  }

  private onLanguageChange() {
    this.initInfo();
    this.getAgendaTitle()
  }

  private getResourceStr(resource: Resource): string {
    return GlobalThis.getResourceStr(resource, this.language);
  }

  private getAgendaTitle() {
    if (!this.info) {
      Log.info(TAG, 'info is null');
      return;
    }
    let titleStr: string = this.info.mTitle;
    if (this.isImportantDay()) {
      const server = ServiceManager.getInstance().getService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
      if (!server) {
        Log.warn(TAG, `getAgendaTitle get null AgendaService!`);
        return;
      }
      const referenceDate = this.isFromMonthView ? this.displayDate : Date.now();
      titleStr = server.agendaTitleDayOffset(this.info, this.displayStartMills, referenceDate);
    }
    if (titleStr === '') {
      titleStr = this.getResourceStr($r('app.string.no_title_label'));
    }
    this.title = titleStr.trim().replace(/·$/, '').trim();

    //    如果是重要日且非镜像语言就正常显示“日程名”+“•”+“10天后”
    //    如果是重要日且镜像语言（比如阿拉伯语言），处理成“10天后”+“•”+“日程名”的形式
    if (this.isImportantDay() && i18n.isRTL(i18n.getSystemLocale())) {
      const cleanedtitle = this.title.replace(/[\u200F\u200E\u200B]/g, '').trim();
      let titleparts = cleanedtitle.trim().split('•');
      if (titleparts.length > 2 && titleparts[1]) {
        this.title = titleparts[1] + '•' + titleparts[0];
      } else {
        this.title = titleparts[0];
      }
    }
    this.userHandler = NotifyHandlerEnum.DEFAULT;
  }

  /**
   * 判断是否是从卡片进入的日程详情
   * @returns 是从卡片进入的日程详情
   */
  private isRootLauncherByFaCard(): boolean {
    const parameters = GlobalThis.getInstance().abilityWant?.parameters;
    if (!parameters || parameters.params === '') {
      Log.info(TAG, 'Not Root Launcher By FaCard!');
      return false;
    }
    const isCard = parameters.action === 'CLICK_AGENDA_DETAIL';
    return isCard;
  }

  private updateStartEndTime() {
    let hours = Math.ceil((this.displayEndMills - this.displayStartMills) / MILLS_PER_HOUR);
    // 一天内显示一行，跨天显示两行
    let startDay = DateUtil.getJulianDay(this.displayStartMills);
    let endDay = DateUtil.getJulianDay(this.displayEndMills);
    const isNormalAgenda = this.info?.mImportantEventType === 0;
    if (hours <= 24 && isNormalAgenda && !this.info?.mIsAllDay && startDay == endDay) {
      this.displaySingleRow = true;
      this.singleTimeFirstLine =
        `${this.getFormatTimeStr(this.displayStartMills)} - ${this.getFormatTimeStr(this.displayEndMills)}${this.timeZoneOffset}`;
      Log.info(TAG, `this agenda displayStartMills = ${this.displayStartMills}, displayEndMills = ${this.displayEndMills}`)
      this.singleTimeSecondLine = `${this.getFormatDateStr(this.displayStartMills)}`;
      return;
    }
    this.displaySingleRow = false;
    Log.info(TAG,
      `this agenda displayStartMills = ${this.displayStartMills}, displayEndMills = ${this.displayEndMills}`)
    if (this.info?.mIsAllDay) {
      // 当前存储侧全天日程时区默认转为UTC,这边写死偏移 ,重要日在计算偏移时已经对时区做了处理,故不再做偏移处理
      const zoneOffset = isNormalAgenda ? new CalendarDate().getTimezoneOffset(this.displayEndMills) : 0;
      this.mStartTime =
        `${this.getResourceStr($r('app.string.start_date'))}: ${this.getTimeStr(this.displayStartMills -
          zoneOffset)}`;
      // 三方写入日程开始结束时间可能相等,故取其中的最大值
      const endMill = Math.max(this.displayStartMills - zoneOffset, this.displayEndMills - zoneOffset - 1);
      // 全天日程end为UTC时间的24点，会被计算为下一天0点，故处理时减去1ms再进行计算
      this.mEndTime = `${this.getResourceStr($r('app.string.end_date'))}: ${this.getTimeStr(endMill)}`;
    } else {
      this.mStartTime = `${this.getResourceStr($r('app.string.start_date'))}: ` +
        `${this.getTimeStr(this.displayStartMills, this.showTimeZoneId)} ${this.getFormatTimeStr(this.displayStartMills, this.showTimeZoneId)}` +
        `${this.timeZoneOffset}`;
      this.mEndTime = `${this.getResourceStr($r('app.string.end_date'))}: ` +
        `${this.getTimeStr(this.displayEndMills, this.showTimeZoneId)} ${this.getFormatTimeStr(this.displayEndMills, this.showTimeZoneId)}` +
        `${this.timeZoneOffset}`;
    }
  }

  private async initTimeZone() {
    this.timeZoneOffset = '';
    if (!this.info) {
      Log.warn(TAG, `info is null`);
      return;
    }
    this.showTimeZoneId = this.info.eventTimeZone;
    if (this.info.eventTimeZone !== CalendarDate.timeZone) {
      this.showTimeZoneId = CalendarDate.timeZone;
      const timestamp = TimeZoneUtil.getTimeZoneOffset(CalendarDate.timeZone, this.info.mBegin) / MILLS_PER_MINUTE;
      this.timeZoneOffset = `(${TimeZoneUtil.processTimeZoneOffset(timestamp)})`;
    }
    Log.info(TAG, `initTimeZone ${this.timeZoneOffset}`);
  }
}