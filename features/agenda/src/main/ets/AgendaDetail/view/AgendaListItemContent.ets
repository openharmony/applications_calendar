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
  AgendaEventInfo,
  AgendaItemLayout,
  AgendaListItemViewModel,
  AgendaService,
  BigFontSize,
  CalendarContract,
  CalendarDate,
  CalendarLayoutManager,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  EmitterCollector,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  I18nUtil,
  Log,
  ServiceEnum,
  ServiceManager,
} from '@app/common';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { OneKeyServiceButton, OneKeyServicePlaceholder } from '@app/common.components/src/main/ets/OneKeyServiceComponents';
import { Callback } from '@ohos.base';
import { LengthMetrics } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import intl from '@ohos.intl';
import { image } from '@kit.ImageKit';

interface IRichText {
  isHighLight: boolean;
  text: string | Resource;
};

interface TimeMessage {
  text: ResourceStr;
};

const TAG: string = 'AgendaListItemContent';

const BTN_MARGIN_LEFT: number = 6;
const TIME_WIDTH_24_HOUR: number = 34;
const TIME_WIDTH_12_HOUR: number = 60;

/**
 * 单个日程组件
 */
@Component
export struct AgendaListItemContent {
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('bgThemeColor') bgThemeColor: string = '';

  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean | undefined =
    AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageProp('is24HourClock') @Watch('on24HourClockChange') is24HourClock: boolean = false;

  @StorageLink('language') @Watch('onLanguageChanges') language: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是分栏场景
  @Prop isSmallWindow: boolean = true;

  //日程时间文本
  @State timeTextStrTop: ResourceStr = '';

  @State timeTextStrBottom: ResourceStr = '';

  @State titleSpanStrList: Array<IRichText> = [];

  @State timeWidth: number = TIME_WIDTH_24_HOUR;

  @State status: string = '0';

  @State agendaModifier: AgendaItemModifier = new AgendaItemModifier();

  @Prop searchText: string = '';

  // 日程实例
  @ObjectLink info: AgendaListItemViewModel;

  @Prop viewType: number = -1;

  @State isExpired: boolean = false;

  @State canShowOneKeyService: boolean = false;

  @Prop showEventId: number = -1;

  @Prop isChecked: boolean = false;

  @Prop selectable: boolean = false;

  @Prop isPopup: boolean = false;

  @Prop singleAgendaMargin: Margin = {};

  @State isConflictingAgenda: boolean = false;

  @State xMirror: boolean = false; // x镜像

  private isChinese: boolean = I18nUtil.isSystemChineseLanguage();

  private emitterCollector: EmitterCollector = new EmitterCollector();

  @State agendaImg: ResourceStr | image.PixelMap | undefined = undefined;

  private needShowConflict: boolean = true; // 是否需要显示冲突角标

  //卡片弹窗是否有边框 true:无边框
  private borderless: boolean = false;

  @Prop isScrolling: boolean = false;

  // 是否位于月视图
  @Prop inMonthView: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @State agendaLayout: AgendaItemLayout = CalendarLayoutManager.getInstance().agendaLayout;

  private agendaTitleToLocationHeight: number = DeviceConfig.instance().config.agendaTitleToLocationHeight;

  private isSameAllDay: boolean = false; // 是否为非跨天的全天日程

  private timeZoneChangeHandler: Callback<emitter.EventData> = () => {
    this.transTimeMessage();
  };

  // 滚动器
  private scroller: Scroller = new Scroller();

  /**
   * 监听深色模式变化
   */
  private onDarkModeChange(): void {
    this.getImageForAgenda();
  }

  aboutToAppear() {
    this.isExpired = this.info.mEnd < Date.now();
    this.timeWidth = this.is24HourClock ? TIME_WIDTH_24_HOUR : TIME_WIDTH_12_HOUR;
    this.isSameAllDay = this.info.mIsAllDay && this.info.mStartDay === this.info.mEndDay;
    this.canShowOneKeyService = this.info.canShowOneKeyService();
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    //深色模式下滑动会导致背景底板消失
    this.agendaModifier.isShowItemShadow = this.isConflictingAgenda && !this.isDarkMode; // 冲突日程的状态下需要展示阴影
    let title = this.info.mTitle;
    if (this.info.isImportantEvent()) {
      const server = ServiceManager.getInstance().getService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
      if (server) {
        title = server.updateRepeatAgendaTitle(this.info, this.info.mBegin);
      }
    }
    this.titleSpanStrList = AgendaUtil.transTitleMessage(title, this.searchText);
    this.info.mLocation = AgendaUtil.filterEmLabel(this.info.mLocation);
    this.info.mLocation = AgendaUtil.getLocation(this.info.mLocation);
    this.transTimeMessage();
    this.emitterEvents();
    this.getImageForAgenda();
  }

  on24HourClockChange() {
    this.timeWidth = this.is24HourClock ? TIME_WIDTH_24_HOUR : TIME_WIDTH_12_HOUR;
    this.transTimeMessage();
  }

  onLanguageChanges() {
    this.transTimeMessage();
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    this.isChinese = I18nUtil.isSystemChineseLanguage();
    this.getImageForAgenda();
  }

  aboutToDisappear() {
    this.unEmitterEvents();
    if (this.agendaImg && typeof this.agendaImg !== 'string') {
      try {
        (this.agendaImg as image.PixelMap).release();
      } catch (e) {
        Log.logErrorMsg(TAG, 'release agendaImg ', e)
      }
    }
  }

  emitterEvents(): void {
    this.minuteChangeHandler = () => this.onMinuteChange();
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_TICK }, this.minuteChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED }, this.minuteChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.timeZoneChangeHandler);
  }

  unEmitterEvents(): void {
    this.emitterCollector.off();
  }

  onMinuteChange(): void {
    Log.debug(TAG, 'On HourCycle change');
    if (this.isExpired) {
      return;
    }
    const nowTime = Date.now();
    this.isExpired = this.info.mEnd < nowTime;
    this.canShowOneKeyService = this.info.canShowOneKeyService();
  }

  /**
   * 获取显示的时间信息
   */
  transTimeMessage() {
    if (this.info.mIsAllDay || (this.info.mIsMultiDayEvent && this.info.mFlag === AgendaEventInfo.FLAG_MID)) {
      this.timeTextStrTop = $r('app.string.all_day');
      return;
    }
    if (this.info.mIsMultiDayEvent && this.info.mFlag === AgendaEventInfo.FLAG_START) {
      this.timeTextStrTop = this.getTimeStr(this.info.mBegin);
      this.timeTextStrBottom = $r('app.string.start_date');
    } else if (this.info.mIsMultiDayEvent && this.info.mFlag === AgendaEventInfo.FLAG_END) {
      this.timeTextStrTop = this.getTimeStr(this.info.mEnd);
      this.timeTextStrBottom = $r('app.string.end_date');
    } else {
      this.timeTextStrTop = this.getTimeStr(this.info.mBegin);
      this.timeTextStrBottom = this.getTimeStr(this.info.mEnd);
    }
  }

  private getResourceStr(resource: Resource): string {
    return GlobalThis.getResourceStr(resource, this.language);
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
   * 时间戳转化为 24 小时或 12 小时制时间 ——> 小时:分钟
   * @param time 时间戳
   * @returns 转化后的时间字符串
   */
  getTimeStr(time: number): string {
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !this.is24HourClock
    });
  }

  async getImageForAgenda() {
    this.agendaImg = '';
  }

  /**
   * 日程时间组件：深色
   * @param timeMessage 显示的开始时间内容
   */
  @Builder
  timeMessageDark(timeMessage: TimeMessage) {
    Text(timeMessage.text)
      .opacity(0.9)
      .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
      .minFontSize('4vp')
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignSelf(ItemAlign.Center)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
  }

  /**
   * 日程时间组件：浅色
   * @param timeMessage 显示的时间内容
   */
  @Builder
  timeMessageLight(timeMessage: TimeMessage) {
    Text(timeMessage.text)
      .opacity(0.7)
      .fontColor($r('sys.color.font_primary'))
      .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
      .minFontSize('4vp')
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignSelf(ItemAlign.Center)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
  }

  @Builder
  dividerTop() {
    Column()
      .width(1)
      .height(8)
      .backgroundColor($r('sys.color.comp_divider'))
      .opacity(0.9)
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 1, bottom: 3 })
  }

  @Builder
  dividerBottom() {
    Column()
      .width(1)
      .height(8)
      .backgroundColor($r('sys.color.comp_divider'))
      .opacity(0.9)
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 3, bottom: 1 })
  }

  @Builder
  accountCircle() {
    Circle()
      .width(7)
      .height(7)
      .fillOpacity(0)
      .alignSelf(ItemAlign.Center)
      .stroke(this.info.mDisplayColor)
      .strokeWidth(1.8)
  }

  getFontColor(item: IRichText) {
    if (item.isHighLight) {
      return this.themeColor;
    } else if (this.isExpired) {
      return $r('sys.color.font_tertiary');
    } else if (this.selectable && (this.info.isHoliday() || this.info.isContactBirthday())) { // 节假日或者联系人生日多选置灰
      return $r('sys.color.font_tertiary');
    } else {
      return $r('sys.color.font_primary');
    }
  }

  /**
   * 日程标题组件
   */
  @Builder
  agendaTitle(layoutWeight = 1, width = 'auto', textAlign = 'Start') {
    Row() {
      Text() {
        ForEach(this.titleSpanStrList, (item: IRichText) => {
          Span(item.text)
            .fontColor(this.getFontColor(item))
            .fontSize(this.agendaLayout.mainTextFontSize)
        }, (item: IRichText, index: number | undefined): string => '' + this.info.mId + index)
      }
      .fontFeature('\"ss08\" 1')
      .fontSize(this.agendaLayout.mainTextFontSize)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .maxLines(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE ? 2 : 3)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .textAlign(TextAlign[textAlign])
      .lineHeight(18)
      .constraintSize({ maxWidth: this.info?.mAttachmentCount > 0 ? 'calc(100% - 26vp)' : width })
      .margin({end: LengthMetrics.vp(2)})

      if (this.info?.mAttachmentCount > 0) {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize(this.agendaLayout.mainTextFontSize)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
          .fontColor(this.isExpired ? [$r('sys.color.font_tertiary')] : [$r('sys.color.font_primary')])
          .width(26)
          .draggable(false)
      }
    }
    .width(width)
    .layoutWeight(layoutWeight)
  }

  /**
   * 日程地点组件
   */
  @Builder
  agendaLocation() {
    Text(this.info.mLocation)
      .opacity(this.isExpired ? 0.4 : 0.6)
      .fontSize(this.agendaLayout.subTextFontSize)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
      .fontWeight(FontWeight.Normal)
      .fontFeature('\"ss08\" 1')
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .margin({ top: this.isChangeLayout() ? 5 * this.fontSizeScale : 2 })
      .direction(i18n.isRTL(i18n.getSystemLocale()) ? Direction.Rtl : Direction.Ltr)
  }

  @Builder
  agendaTimeBuilder() {
    Column() {
      if (this.info.mIsAllDay) {
        this.accountCircle();
        Blank().height(4);
        this.timeMessageDark({ text: this.timeTextStrTop });
      } else if (this.info.mIsMultiDayEvent && this.info.mFlag === AgendaEventInfo.FLAG_MID) {
        this.dividerTop();
        Blank().height(2);
        this.accountCircle();
        Blank().height(8);
        this.timeMessageDark({ text: this.timeTextStrTop });
        Blank().height(5);
        this.dividerBottom();
      } else if (this.info.mIsMultiDayEvent) {
        if (this.info.mFlag === AgendaEventInfo.FLAG_START) {
          this.timeMessageDark({ text: this.timeTextStrTop });
          Blank().height(2);
          this.timeMessageDark({ text: this.timeTextStrBottom });
          Blank().height(10);
          this.accountCircle();
          Blank().height(2);
          this.dividerBottom();
        } else if (this.info.mFlag === AgendaEventInfo.FLAG_END) {
          this.dividerTop();
          Blank().height(2);
          this.accountCircle();
          Blank().height(10);
          this.timeMessageDark({ text: this.timeTextStrTop });
          Blank().height(2);
          this.timeMessageDark({ text: this.timeTextStrBottom });
        }
      } else {
        this.timeMessageDark({ text: this.timeTextStrTop });
        // 线加圆圈
        this.dividerTop();
        Blank().height(1);
        this.accountCircle();
        Blank().height(2);
        this.dividerBottom();
        Blank().height(1);
        this.timeMessageLight({ text: this.timeTextStrBottom });
      }
    }
    .id(CompId.AGENDA_TIME_LINE)
    .constraintSize({ minHeight: 58 })
    .width(this.timeWidth)
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .opacity(this.isExpired || (this.selectable && (this.info.isHoliday() || this.info.isContactBirthday())) ? 0.4 : 1)
  }

  @Builder
  buildAgendaHasLocationInfo() {
    // 有地址，一键服务按钮和地址在同一行显示,大3档以上2行显示
    Column() {
      Row() {
        this.agendaLocation();

        if (this.fontSizeScale <= BigFontSize.BIG_FONT_SIZE_SPECIAL && this.canShowOneKeyService) {
          OneKeyServiceButton({ info: this.info, serviceUri: this.info.mHwextServiceUri, viewType: this.viewType })
            .margin({ left: BTN_MARGIN_LEFT, top: 2 })
        }
      }

      if (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL && this.canShowOneKeyService) {
        Row() {
          OneKeyServiceButton({ info: this.info, serviceUri: this.info.mHwextServiceUri, viewType: this.viewType })
        }
        .width('100%')
        .margin({ top: 2 })
      }
    }
    .margin({ top: this.agendaTitleToLocationHeight })
  }

  @Builder
  buildAgendaNoLocationInfo() {
    // 没有地址，线上会议的地址部分展示默认文字，非线上会议只展示文字按钮,大3档以上2行显示
    Column() {
      Row() {
        if (AgendaUtil.isMeetingService(this.info)) {
          OneKeyServicePlaceholder({
            info: this.info,
            isExpired: this.isExpired
          }).layoutWeight(1)
            .margin({ top: 2 })
            .padding({ top: this.agendaTitleToLocationHeight })
        } else {
          Blank().layoutWeight(1)
        }

        if (this.fontSizeScale <= BigFontSize.BIG_FONT_SIZE_SPECIAL && this.canShowOneKeyService) {
          OneKeyServiceButton({ info: this.info, serviceUri: this.info.mHwextServiceUri, viewType: this.viewType })
            .margin({ left: BTN_MARGIN_LEFT, top: 2 })
            .padding({ top: this.agendaTitleToLocationHeight })
        }
      }

      if (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL && this.canShowOneKeyService) {
        Row() {
          OneKeyServiceButton({ info: this.info, serviceUri: this.info.mHwextServiceUri, viewType: this.viewType })
        }
        .width('100%')
        .margin({ top: 2 })
        .padding({ top: this.agendaTitleToLocationHeight })
      }
    }
  }

  @Builder
  buildAgendaLocationInfo() {
    if (this.info?.mLocation && this.info.mLocation.trim().length > 0) {
      this.buildAgendaHasLocationInfo();
    } else {
      this.buildAgendaNoLocationInfo();
    }
  }

  // 多选框
  @Builder
  buildCheckBox() {
    Column() {
      Checkbox()
        .width(20)
        .height(20)
        .select(this.info.isSelected)
        .selectedColor(this.themeColor)
        .shape(this.needCommerce ? CheckBoxShape.ROUNDED_SQUARE : CheckBoxShape.CIRCLE)
        .onChange((value) => {
          this.info.isSelected = value;
        })
        .onClick(() => {
          if (this.info.isHoliday()) {
            return;
          }
          emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED });
        })
    }
    .padding({ right: 4 })
    .alignItems(HorizontalAlign.Center)
  }

  // 冲突角标
  @Builder
  buildConflict() {
    Column() {
      Text($r('app.string.collision_text'))
        .textAlign(TextAlign.Center)
        .padding({ top: 4 })
        .fontColor(this.isExpired ? $r('sys.color.ohos_id_color_text_secondary') : this.themeColor)
        .fontSize($r('sys.float.ohos_fa_text_size_caption'))
    }
    .offset({ x: this.xMirror ? 4 : -4, y: 4 })
    .height(20)
    .width(40)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.isExpired ? $r('sys.color.ohos_id_color_component_normal') : this.bgThemeColor)
    .borderRadius({ bottomLeft: this.xMirror ? 2 : 15, bottomRight: this.xMirror ? 15 : 2,
                    topRight: this.xMirror ? 2 : 15, topLeft: this.xMirror ? 15 : 2 }) // 适配左右镜像的情况
  }

  onChangeFontSizeForSpace(num: number) {
    return FontSizeScaleUtils.getLimitHeightNum(
      this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SIX,
      num
    );
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }


  /**
   * 获取开始/结束时间字符串
   * @param type
   * @param isAllDay
   * @returns
   */
  getDateTimeStr(type: string, isAllDay: boolean): string {
    if (!type) {
      return '';
    }

    if (this.info.mStartDay === this.info.mEndDay && isAllDay) { //当日全天日程
      const resource = this.getResourceStr($r('app.string.start_date'));
      const date = this.getFormatDateStr(this.info.mBegin);
      return `${resource}: ${date}`;
    } else if (isAllDay) { //跨天全天日程
      const zoneOffset = isAllDay ? new CalendarDate().getTimezoneOffset(this.info.mBegin) : 0;
      if (type === 'start') {
        return this.getFormattedDateStr(this.info.mBegin - zoneOffset, $r('app.string.start_date'), isAllDay);
      } else if (type === 'end') {
        return this.getFormattedDateStr(this.info.mEnd - zoneOffset - 1, $r('app.string.end_date'), isAllDay);
      } else {
        return '';
      }
    } else { //跨天日程和普通日程
      if (type === 'start') {
        return this.getFormattedDateStr(this.info.mBegin, $r('app.string.start_date'), isAllDay);
      } else if (type === 'end') {
        return this.getFormattedDateStr(this.info.mEnd, $r('app.string.end_date'), isAllDay);
      } else {
        return '';
      }
    }
  }

  /**
   * 获取格式化字符串：开始/结束：年月日：小时分钟
   * @param timestamp
   * @param res
   * @param isAllDay 是否全天日程
   * @returns
   */
  getFormattedDateStr(timestamp: number, res: Resource, isAllDay: boolean) {
    const resource = this.getResourceStr(res);
    if (isAllDay) { // 全天日程减去偏移量
      const date = this.getFormatDateStr(timestamp);
      return `${resource}: ${date}`;
    } else {
      const date = this.getFormatDateStr(timestamp);
      const time = this.getTimeStr(timestamp);
      return `${resource}: ${date} ${time}`;
    }
  }

  /**
   * 获取节日时间字符串
   * @returns
   */
  getHolidayTimeStr() {
    if (this.info) {
      const DATE_INTL_OPT: intl.DateTimeOptions = { month: 'long', day: 'numeric', weekday: 'long' };
      const holidayDate = new Date(this.info?.mBegin);
      const date = new CalendarDate(holidayDate.getUTCFullYear(), holidayDate.getUTCMonth(), holidayDate.getUTCDate());
      const dateStr: string = DateUtil.intlDateFormatChineseStyle(date, DATE_INTL_OPT);
      Log.info(TAG, ` AgendaListItem : getHolidayTimeStr date = ${date.getTime()}, dateStr = ${dateStr}`);
      return `${dateStr}`;
    }
    return '';
  }

  @Builder
  InterDayTimeAndLocationBuilder() {
    Column({ space: 3 }) {
      if (this.info?.isHoliday() || this.isSameAllDay) {
        Column() {
          Text(this.getHolidayTimeStr())
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
      } else {
        ForEach(['start', 'end'], (item: string) => {
          Row() {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(14)
              .margin({ end: LengthMetrics.vp(8) })
              .fontColor([$r('sys.color.icon_secondary')])
              .alignSelf(ItemAlign.Start)
              .flexShrink(1)

            Text(this.getDateTimeStr(item, this.info.mIsAllDay))
              .fontWeight(FontWeight.Regular)
              .wordBreak(WordBreak.BREAK_WORD)
              .lineBreakStrategy(LineBreakStrategy.GREEDY)
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontColor($r('sys.color.font_secondary'))
              .alignSelf(ItemAlign.Start)
              .layoutWeight(1)
          }
        }, (item: string, index: number) => index.toString())
      }

      if (this.info?.mLocation) {
        Blank().height(2);
        this.InterDayLocationBuilder();
      }
    }
    .opacity(this.isExpired ? 0.4 : 1)
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  InterDayLocationBuilder() {
    Row() {
      SymbolGlyph($r('sys.symbol.local'))
        .fontSize(14)
        .margin({ end: LengthMetrics.vp(8) })
        .fontColor([$r('sys.color.icon_secondary')])
        .alignSelf(ItemAlign.Start)
        .flexShrink(1)

      Text(this.info.mLocation)
        .fontSize(this.agendaLayout.subTextFontSize)
        .fontWeight(FontWeight.Regular)
        .fontFeature('\"ss08\" 1')
        .wordBreak(WordBreak.BREAK_WORD)
        .lineBreakStrategy(LineBreakStrategy.GREEDY)
        .layoutWeight(1)
        .textAlign(i18n.isRTL(i18n.getSystemLocale()) ? TextAlign.End : TextAlign.Start)
    }
    .opacity(this.isExpired ? 0.4 : 1)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  InterDayBuilder() {
    Column() {
      Row() {
        this.agendaTitle(0, '100%', i18n.isRTL(i18n.getSystemLocale()) ? 'End' : 'Start');
      }
      Row() {
        this.InterDayTimeAndLocationBuilder();

        if (this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SIX && this.canShowOneKeyService) {
          OneKeyServiceButton({
            info: this.info,
            serviceUri: this.info.mHwextServiceUri,
            viewType: this.viewType
          });
        }
      }.margin({
        top:10
      })

      // 6倍大字体,竖排展示
      if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SIX && this.canShowOneKeyService) {
        Row() {
          OneKeyServiceButton({
            info: this.info,
            serviceUri: this.info.mHwextServiceUri,
            viewType: this.viewType
          });
        }.justifyContent(FlexAlign.Start)
      }
    }
    .accessibilityGroup(true)
    .accessibilityText(this.info?.getAccessibilityText())
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  // 是否需要显示时间
  showAgendaTime(): boolean {
    if (this.info?.isHoliday() && this.isChinese && this.agendaImg && this.agendaImg !== '') {
      return false;
    }
    return true;
  }

  build() {
    Row() {
      Row() {
        if (this.borderless) {
          this.InterDayBuilder();
        } else {
          if (this.showAgendaTime()) {
            this.agendaTimeBuilder();
          }
          Column() {
            //  日程头
            Row() {
              this.agendaTitle();
            }

            this.buildAgendaLocationInfo();
          }
          .borderRadius(16)
          .id(CompId.AGENDA_CONTEND)
          .margin({ start: LengthMetrics.vp(12), end: LengthMetrics.vp(8) })
          .borderRadius($r('sys.float.corner_radius_level8'))
          .layoutWeight(1)

          if (this.selectable && !this.info.isHoliday() && !this.info.isContactBirthday()) {
            this.buildCheckBox();
          }
        }
      }
      .accessibilityGroup(true)
      .accessibilityText(this.info?.getAccessibilityText())
      .padding({
        top: this.info?.mLocation ? LengthMetrics.vp(10) : LengthMetrics.vp(8),
        bottom: this.info?.mLocation ? LengthMetrics.vp(10) : LengthMetrics.vp(8),
        start: LengthMetrics.vp(8),
        end: this.info.isConflict && !this.selectable ? LengthMetrics.vp(30) : LengthMetrics.vp(0)
      })
      .alignItems(VerticalAlign.Center)
      .borderRadius(16)
      .constraintSize({ minHeight: this.agendaLayout.agendaItemHeight })
      .hoverEffect(this.isConflictingAgenda || this.isScrolling ? HoverEffect.None : HoverEffect.Highlight)
      .stateStyles({
        pressed: {
          .backgroundColor(this.isConflictingAgenda || this.isScrolling || this.needCommerce ?
            '' : $r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(this.isChecked && !this.isSmallWindow ? $r('app.color.agenda_list_item_select') : '')
        }
      })
    }
    .zIndex(2)
    .overlay(!this.selectable && this.info.isConflict && this.needShowConflict ?
    this.buildConflict() : undefined,
      { align: this.xMirror ? Alignment.TopStart : Alignment.TopEnd }
    )
    .clip(true)
    .attributeModifier(this.agendaModifier)
    .margin(this.borderless ? 0 : this.singleAgendaMargin)
    .padding({
      top: 4,
      bottom: 4,
      left: 4,
      right: 4
    })
    .borderRadius($r('sys.float.corner_radius_level10'))
    // comp_background_list_card深色模式时为透明色，与滑动叠卡冲突，在月视图时需为ohos_id_color_list_card_bg
    .backgroundColor(this.inMonthView ? $r('sys.color.ohos_id_color_list_card_bg') :
      this.borderless ? $r('sys.color.comp_background_primary') : $r('sys.color.comp_background_list_card'))
    .backgroundImage(this.agendaImg, !this.agendaImg ? ImageRepeat.X : ImageRepeat.NoRepeat)
    .backgroundImageSize(ImageSize.FILL)
  }

  private minuteChangeHandler: Callback<emitter.EventData> = () => {
  };
}

/**
 * 用于区分不同场景下的日程
 */
class AgendaItemModifier implements AttributeModifier<RowAttribute> {
  // 是否显示阴影
  public isShowItemShadow: boolean = false;

  applyNormalAttribute(instance: RowAttribute): void {
    if (this.isShowItemShadow) {
      instance
        .backgroundBlurStyle(BlurStyle.COMPONENT_REGULAR)
        .shadow({
          radius: 8,
          color: '#0d000000'
        })
    }
  }
}

