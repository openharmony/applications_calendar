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
  BackgroundId,
  LayoutId,
  LayoutIdType,
  TextureId,
  FontId,
  Color,
  EventMode
} from '@app/common/src/main/ets/card/ImportantCardConfig';
import { ImportantEntity } from '../../model/ImportantEntity';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { getDateText } from '../../../utils/TimeUtils';
import { CARD_IMPORTANT, DIMENSION_2_2, jumpToAgendaDetail } from '../../../utils/CardJumpUtils';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { AgendaEventInfo } from '../../model/AgendaEventInfo';
import { InitImportantCard2x2 } from '../../../view/InitCardView';
import { BigFontSize } from '@app/common/src/main/ets/constants/BigFontSize';
import { ImportantCardModel } from '../../model/ImportantCardModel';
import { CardYearDayOffset } from '../components/CardYearDayOffset'
import { CardAction } from '../../../common/CardAction';
import { CardUiUtils } from '../../util/CardUiUtils'
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { i18n } from '@kit.LocalizationKit';
import { ImportantCardComponentId } from '../../model/ImportantCardComponentId';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { MILLS_PER_DAY } from '@app/common/src/main/ets/util/DateUtil';
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';

const TAG: string = 'ImportantCardView2x2';

@Component
struct ImportantCardView {
  @Prop imageFit: ImageFit | undefined = undefined;

  @State title: Resource | string = '';

  @State attachmentCount: number = 0;

  @State content: string = '';

  @State unit: Resource = $r('app.plural.in_days');

  @State type: string = 'in_days';

  @State rrule: string = '';

  @State yearOffset: number = 0;

  @State remainingDays: number = 0;

  @State dayOffset: number = 0;

  @State date: CalendarDate = new CalendarDate();

  @State eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR;

  // 节假日信息
  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  // 第一次创建卡片，数据处理是否完成
  @LocalStorageProp('isDataProcessedFirstTime') isDataProcessedFirstTime: boolean = false;

  @LocalStorageProp('importantConfig') importantConfig: ImportantConfig = new ImportantConfig();

  @LocalStorageProp('eventMode') @Watch('onEventModeChanged') eventMode: EventMode = EventMode.DEFAULT;

  // 是否进入日历隐私授权
  @LocalStorageProp('isAgreeStatement') @Watch('isAgreeStatementChange') isAgreeStatement: boolean = true;

  // 双升单隐私是否授权
  @LocalStorageProp('isDoubleUpSingleAgreeStatement') isDoubleUpSingleAgreeStatement: boolean = false;

  // 卡片数据代理返回的 固定重要日 JSON 数组
  @LocalStorageProp('fixedImportantList') @Watch('onFixedImportantChanged') fixedImportantList: Array<object> = [];

  // 卡片数据代理返回的 固定生日 JSON 数组
  @LocalStorageProp('fixedBirthdayList') @Watch('onFixedBirthdayChanged') fixedBirthdayList: Array<object> = [];

  // 卡片数据代理返回的 近期重要日 JSON 数组
  @LocalStorageProp('recentHolidayList') @Watch('onRecentHolidayChanged') recentHolidayList: Array<object> = [];

  // 卡片数据代理返回的 固定重要日 JSON 数组
  @LocalStorageProp('fixedHolidayList') @Watch('onFixedHolidayChanged') fixedHolidayList: Array<object> = [];

  @LocalStorageProp('needCommerce') needCommerce: boolean = false;

  @LocalStorageProp('formId') formId: string = '';
  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  @LocalStorageProp('imageName') @Watch('onImageChange') customizeImage: ResourceStr = '';

  @LocalStorageProp('language') language: string = i18n.System.getSystemLocale();

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();

  private dataModel: ImportantCardModel = new ImportantCardModel();

  private showImportantEntity: ImportantEntity | null = null;

  private isShowDefaultCard: boolean = true;

  isAgreeStatementChange() {
    Log.info(TAG, `isAgreeStatement = ${this.isAgreeStatement}`);
    this.tryCalculateEventMode();
  }

  aboutToAppear(): void {
    this.dataModel.bindFormId(this.formId);
    this.dataModel.bindMode(this.eventMode);
    Log.log(TAG, `aboutToAppear formId=${this.formId}, eventMode=${this.eventMode}`);
    if (!this.eventMode || this.eventMode === EventMode.DEFAULT) {
      this.tryCalculateEventMode();
    } else {
      this.onDataChange();
    }
  }

  build() {
    if (!this.isAgreeStatement && !this.isDoubleUpSingleAgreeStatement) {
      this.NoAuthView()
    } else if (this.isDataProcessedFirstTime) {
      this.importantCardView()
    } else {
      InitImportantCard2x2()
    }
  }

  getDefaultImageFit() {
    return this.importantConfig.backgroundId === BackgroundId.TEXTURES ? ImageFit.None : ImageFit.Cover;
  }

  /** 未授权时重要日卡片显示一年最后一天(跨年夜) */
  @Builder
  NoAuthView() {
    Stack() {
      Image(this.getBackgroundImage())
        .objectFit(this.imageFit ?? this.getDefaultImageFit())
        .scale({ x: 1.01, y: 1.01 }) // harden设备背景图片不足以覆盖底图圆角，暗色背景四角出现细微的黑色边框

      Column() {
        layout2x2({
          title: $r('app.string.default_important_agenda'),
          date: new CalendarDate(Date.UTC(new CalendarDate().getFullYear(), 11, 31, 0, 0, 0)).getTime(),
          type: 'days_later',
          rrule: this.rrule,
          yearOffset: 0,
          remainingDays: Math.ceil((new CalendarDate(Date.UTC(new CalendarDate().getFullYear(), 11, 31, 0, 0, 0))
            .getTime() - Date.now()) / MILLS_PER_DAY),
          dayOffset: Math.ceil((new CalendarDate(Date.UTC(new CalendarDate().getFullYear(), 11, 31, 0, 0, 0))
            .getTime() - Date.now()) / MILLS_PER_DAY),
          layout: this.importantConfig.layoutId,
          backgroundId: this.importantConfig.backgroundId,
          fontId: this.importantConfig.fontId,
          color: this.importantConfig.color,
          _opacity: this.importantConfig.opacity,
          topBright: this.importantConfig.topBright,
          bottomBright: this.importantConfig.bottomBright,
          language: this.language,
          eventCalendarType: CalendarContract.AgendaCalendarType.SOLAR,
        });
      }
      .borderRadius($r('sys.float.corner_radius_level8'))
      .padding($r('sys.float.padding_level6'))
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .width('100%')
    .height('100%')
    .onClick(() => {
      this.handleClick();
    });
  }

  /** 重要日卡片视图 */
@Builder
  importantCardView(){
    // 展示通用重要日样式
    this.normalImportantCardView();
  }

  /** 通用重要日卡片视图 */
  @Builder
  normalImportantCardView() {
    Stack() {
      Image(this.getBackgroundImage())
        .objectFit(this.imageFit ?? this.getDefaultImageFit())
        .scale({ x: 1.01, y: 1.01 }) // harden设备背景图片不足以覆盖底图圆角，暗色背景四角出现细微的黑色边框

      Column() {
        if (this.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
          unknownImportantCard2x2();
        } else {
          layout2x2({
            title: this.title,
            date: this.date.getTime(),
            type: this.type,
            rrule: this.rrule,
            yearOffset: this.yearOffset,
            remainingDays: this.remainingDays,
            dayOffset: this.dayOffset,
            layout: this.importantConfig.layoutId,
            backgroundId: this.importantConfig.backgroundId,
            fontId: this.importantConfig.fontId,
            color: this.importantConfig.color,
            _opacity: this.importantConfig.opacity,
            topBright: this.importantConfig.topBright,
            bottomBright: this.importantConfig.bottomBright,
            language: this.language,
            eventCalendarType: this.eventCalendarType,
            attachmentCount: this.attachmentCount
          });
        }
      }
      .borderRadius($r('sys.float.corner_radius_level8'))
      .padding($r('sys.float.padding_level6'))
    }
    .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    .width('100%')
    .height('100%')
    .onClick(() => {
      Log.info(TAG, `normalImportantCardView is clicked. formId: ${this.formId}, title: ${maskString(this.title.toString())}, ` +
        `date: ${this.date.getTime()}, dayOffset: ${this.dayOffset}`);
      this.handleClick();
    });
  }

  private handleClick() {
    if (this.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
      this.jumpToCardEditAbility(); //点击直接跳转到卡片编辑界面
    } else {
      this.isShowDefaultCard
        ? jumpToMonthView(this, new CalendarDate().getFullYear(), 11, 31, this.formId)
        : this.jumpEventInfoPage();
    }
  }

  private jumpToCardEditAbility() {
    postCardAction(this, {
      action: 'router',
      bundleName: 'com.ohos.calendar',
      abilityName: 'CardEditAbility',
      params: {
        'formId': this.formId,
      }
    });
  }

  onEventModeChanged() {
    Log.info(TAG, `onEventModeChanged: ${this.eventMode}, ${this.dataModel.getShowImportantEntity()}`);
    if (!this.eventMode || this.eventMode === EventMode.DEFAULT) {
      this.tryCalculateEventMode();
      return;
    }
    this.dataModel.bindMode(this.eventMode);
  }

  onFixedImportantChanged() {
    Log.info(TAG, `formId: ${this.formId} onFixedImportant callback, size = ${this.fixedImportantList?.length}`);
    this.dataModel.updateFixedImportant(this.fixedImportantList);
    this.onDataChange();
  }

  onFixedBirthdayChanged() {
    Log.info(TAG, `formId: ${this.formId} onFixedBirthday callback, size = ${this.fixedBirthdayList?.length}`);
    this.dataModel.updateFixedBirthday(this.fixedBirthdayList);
    this.onDataChange();
  }

  onRecentHolidayChanged() {
    Log.info(TAG, `formId: ${this.formId} onRecentHoliday callback, size = ${this.recentHolidayList?.length}`);
    this.dataModel.updateRecentHoliday(this.recentHolidayList);
    this.onDataChange();
  }

  onFixedHolidayChanged() {
    Log.info(TAG, `formId: ${this.formId} onFixedHoliday callback, size = ${this.fixedHolidayList?.length}`);
    this.dataModel.updateFixedHoliday(this.fixedHolidayList);
    this.onDataChange();
  }

  onImageChange() {
    Log.info(TAG, `onImageChange: ${this.customizeImage}`);
  }

  private onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange: ${this.timeZone}`);
    CalendarDate.timeZone = this.timeZone;
    this.onDataChange();
  }

  /**
   * 数据变化，刷新卡片
   */
  onDataChange() {
    this.isShowDefaultCard = false;
    if (!this.isDataProcessedFirstTime) {
      this.isDataProcessedFirstTime = true;
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.FINISH_FIRST_DATA_PROCESSING,
        }
      });
    }
    // 未知联系人生日直接返回，展示信息变更样式
    if (this.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
      Log.info(TAG, `formId: ${this.formId}, eventMode is UNKNOWN_BIRTHDAY`);
      return;
    }

    const entity: ImportantEntity | null = this.dataModel.getShowImportantEntity();
    if (entity) {
      Log.info(TAG, `formId: ${this.formId} bindData eventId: ${entity.eventId}, type: ${entity.importantEventType}`);
      this.bindImportantEntityToView(entity);
      return;
    }

    Log.info(TAG, `formId: ${this.formId} show default card`);
    this.isShowDefaultCard = true;
    this.showDefaultCard();
    this.tryCalculateEventMode();
  }

  private tryCalculateEventMode() {
    Log.warn(TAG, `tryCalculateEventMode, formId: ${this.formId}, eventMode: ${this.eventMode}`);
    postCardAction(this, {
      action: 'message',
      params: {
        'message': CardAction.CALCULATE_IMPORTANT_CARD_MODE,
        'formName': 'ImportantCardView2x2',
      }
    });
  }

  getBackgroundImage(): ResourceStr {
    if (this.importantConfig.backgroundId === BackgroundId.CUSTOMIZE && this.customizeImage) {
      return `memory://${this.customizeImage}`;
    }
    if (this.importantConfig.backgroundId === BackgroundId.TEXTURES) {
      return CardUiUtils.getTextureById(this.importantConfig.texturesId);
    } else {
      return CardUiUtils.getBackgroundById(this.importantConfig.backgroundId, this.importantConfig.texturesId, true);
    }
  }

  private bindImportantEntityToView(important: ImportantEntity): void {
    this.showImportantEntity = important;
    this.title = important.title;
    if (important.isBirthday()) {
      this.title = $r('app.string.somebody_birthday', important.title);
    }
    this.attachmentCount = important.mAttachmentCount;

    const yearDayOffsetInfo = CardUiUtils.getYearDayOffset(important);
    this.yearOffset = yearDayOffsetInfo.yearOffset;
    this.remainingDays = yearDayOffsetInfo.remainingDays;
    this.dayOffset = yearDayOffsetInfo.dayOffset;
    this.type = yearDayOffsetInfo.type;

    this.date = new CalendarDate(important.begin);
    this.eventCalendarType = important.eventCalendarType;
    this.rrule = important.rrule;
    this.holidayInfo.mTitle = this.title;
    this.holidayInfo.mBegin = important.begin;
    Log.info(TAG, `formId: ${this.formId}, title: ${maskString(this.title.toString())}, date: ${this.date}, dayOffset: ${this.dayOffset}`);
  }

  /**
   * 展示默认当年的最后一天
   */
  showDefaultCard() {
    this.title = $r('app.string.default_important_agenda');
    this.showImportantEntity = null;
    const currentDate = new CalendarDate();
    const targetDate = new CalendarDate(Date.UTC(currentDate.getFullYear(), 11, 31, 0, 0, 0)).getTime();
    this.date = new CalendarDate(targetDate);
    this.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;

    this.yearOffset = 0;
    const dayOffset = Math.ceil((targetDate - Date.now()) / MILLS_PER_DAY);
    this.remainingDays = dayOffset;
    this.dayOffset = dayOffset;
    this.type = 'days_later';

    this.holidayInfo.mTitle = this.title;
    this.holidayInfo.mBegin = targetDate;
  }

  private jumpEventInfoPage() {
    if (this.showImportantEntity && this.showImportantEntity.eventId > 0) {
      Log.info(TAG, `jumpEventInfoPage formId = ${this.formId}, onclick backgroundId = ${this.importantConfig.backgroundId}`);
      jumpToAgendaDetail(this, this.showImportantEntity, CARD_IMPORTANT, DIMENSION_2_2, this.needCommerce);
    } else {
      Log.info(TAG, `jumpEventInfoPage formId = ${this.formId}, onclick backgroundId = ${this.importantConfig.backgroundId}`);
      postCardAction(this, {
        action: 'router',
        bundleName: 'com.ohos.calendar',
        abilityName: 'MainAbility',
        params: {
          'action': 'CLICK_AGENDA_DETAIL',
          'id': 0,
          'dimension': '2x2',
          'faType': 'important_fa',
          'holidayInfo': JSON.stringify(this.holidayInfo)
        }
      });
    }
  }
}

@Component
export struct unknownImportantCard2x2 {
  build() {
    Flex({ direction: FlexDirection.Column }) {
      Row() {
        Text($r('app.string.important_day'))
          .fontSize($r('sys.float.Subtitle_L'))
          .fontWeight(FontWeight.Bolder)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      }

      Row() {
        Image($r('app.media.contact'))
          .width($r('sys.float.padding_level12'))
          .height($r('sys.float.padding_level12'))
          .fillColor($r('sys.color.ohos_id_color_primary'))
      }
      .margin({
        top: $r('sys.float.padding_level10'),
        bottom: $r('sys.float.padding_level3'),
        left: $r('sys.float.padding_level24')
      })

      Row() {
        Text($r('app.string.contact_info_changed'))
          .maxLines(2)
          .fontSize($r('sys.float.Subtitle_S'))
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      }
      .width(133)
      .height(36)
    }
    .height('100%')
    .width('100%')
  }
}

@Component
export struct layout2x2 {
  @Prop title: Resource | string;

  @Prop attachmentCount: number = 0;

  @Prop date: number;

  @Prop unit: Resource;

  @Prop rrule: string;

  @Prop yearOffset: number;

  @Prop remainingDays: number;

  @Prop dayOffset: number;

  @Prop type: string;

  @Prop isEdit?: boolean;

  @Prop layout?: LayoutId;

  @Prop backgroundId: string;

  @Prop fontId: FontId;

  @Prop color: string;

  @Prop _opacity: number;

  @Prop topBright: number;

  @Prop bottomBright: number;

  @Prop eventCalendarType: number;

  @Prop language: string;

  @State sizeRate: number = 1;

  async aboutToAppear() {
    this.sizeRate = await CardUiUtils.getSizeRateFromDisplay();
  }

  getLayout() {
    switch (this.layout) {
      case LayoutId.LEFT:
      case LayoutId.LEFT_1:
        return HorizontalAlign.Start;
      case LayoutId.RIGHT:
      case LayoutId.RIGHT_1:
        return HorizontalAlign.End;
      default:
        return HorizontalAlign.Center;
    }
  }

  getLayoutType() {
    switch (this.layout) {
      case LayoutId.LEFT:
      case LayoutId.RIGHT:
      case LayoutId.CENTER:
        return LayoutIdType.TEXT_IMG_TEXT;
      case LayoutId.LEFT_1:
      case LayoutId.RIGHT_1:
      case LayoutId.CENTER_1:
        return LayoutIdType.TEXT_IMG;
      default:
        return LayoutIdType.DEFAULT;
    }
  }

  isTextImg() {
    return this.getLayoutType() === LayoutIdType.TEXT_IMG;
  }

  build() {
    Column() {
      // 标题
      Row() {
        if (CardUiUtils.isNoOffsetStyle(this.yearOffset, this.dayOffset)) {
          Text(this.title)
            .fontWeight(FontWeight.Bold)
            .fontColor(CardUiUtils.getPrimaryColor(this.backgroundId, this.topBright, true))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
            .maxFontSize(30)
            .minFontSize(16)
            .constraintSize({ maxWidth: this.attachmentCount > 0 ? 'calc(100% - 16vp)' : '100%' })
            .id(ImportantCardComponentId.IMPORTANT_CARD_VIEW_TITLE)

          if (this.attachmentCount > 0) {
            SymbolGlyph($r('sys.symbol.paperclip'))
              .fontSize(23)
              .fontColor([CardUiUtils.getPrimaryColor(this.backgroundId, this.topBright, true)])
              .width(16)
              .draggable(false)
          }
        } else {
          Text(this.title)
            .fontWeight(FontWeight.Bold)
            .fontSize(17)
            .fontColor(CardUiUtils.getPrimaryColor(this.backgroundId, this.topBright))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
            .constraintSize({ maxWidth: this.attachmentCount > 0 ? 'calc(100% - 16vp)' : '100%' })
            .id(ImportantCardComponentId.IMPORTANT_CARD_VIEW_TITLE)

          if (this.attachmentCount > 0) {
            SymbolGlyph($r('sys.symbol.paperclip'))
              .fontSize(17)
              .fontColor([CardUiUtils.getPrimaryColor(this.backgroundId, this.topBright)])
              .width(16)
              .draggable(false)
          }
        }
      }

      if (this.isTextImg()) {
        // 创建时间
        Text(getLocalDateText(this.date, this.eventCalendarType))
          .fontWeight(FontWeight.Regular)
          .lineHeight(16)
          .fontColor(CardUiUtils.getSecondaryColor(this.backgroundId, this.bottomBright))
          .margin({
            top: CardUiUtils.isNoOffsetStyle(this.yearOffset, this.dayOffset) ? $r('sys.float.padding_level4') : 0
          })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
          .minFontSize(10)
          .maxFontSize(14)
          .maxLines(1)
          .id(ImportantCardComponentId.IMPORTANT_CARD_VIEW_LOCAL)

        // 倒数日或纪念日天数
        Column() {
          CardYearDayOffset({
            title: this.title,
            rrule: this.rrule,
            yearOffset: this.yearOffset,
            remainingDays: this.remainingDays,
            dayOffset: this.dayOffset,
            type: this.type,
            fontId: this.fontId,
            color: CardUiUtils.rgb2argb(this.color, this._opacity),
            isEdit: this.isEdit,
            horizontalAlign: this.getLayout(),
            cardName: 'card2x2',
            language: this.language,
            layoutType: this.getLayoutType(),
            sizeRate: this.sizeRate
          })
        }
        .layoutWeight(CardUiUtils.isNoOffsetStyle(this.yearOffset, this.dayOffset) ? 0 : 1)
        .justifyContent(FlexAlign.End)
      } else {
        // 倒数日或纪念日天数
        Column() {
          CardYearDayOffset({
            title: this.title,
            rrule: this.rrule,
            yearOffset: this.yearOffset,
            remainingDays: this.remainingDays,
            dayOffset: this.dayOffset,
            type: this.type,
            fontId: this.fontId,
            color: CardUiUtils.rgb2argb(this.color, this._opacity),
            isEdit: this.isEdit,
            horizontalAlign: this.getLayout(),
            cardName: 'card2x2',
            language: this.language,
            layoutType: this.getLayoutType(),
            sizeRate: this.sizeRate
          })
        }
        .layoutWeight(CardUiUtils.isNoOffsetStyle(this.yearOffset, this.dayOffset) ? 0 : 1)
        .justifyContent(FlexAlign.Center)

        // 创建时间
        Text(getLocalDateText(this.date, this.eventCalendarType))
          .fontWeight(FontWeight.Regular)
          .lineHeight(16)
          .fontColor(CardUiUtils.getSecondaryColor(this.backgroundId, this.bottomBright))
          .margin({
            top: CardUiUtils.isNoOffsetStyle(this.yearOffset, this.dayOffset) ? $r('sys.float.padding_level4') : 0
          })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
          .minFontSize(10)
          .maxFontSize(14)
          .maxLines(1)
          .id(ImportantCardComponentId.IMPORTANT_CARD_VIEW_LOCAL)
      }
    }
    .height('100%')
    .width('100%')
    .justifyContent(this.isTextImg() ? FlexAlign.Start : FlexAlign.Center)
    .alignItems(this.getLayout())
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      const newHeight = (newValue.height ?? 0) as number;
      this.sizeRate = CardUiUtils.getSizeRateFromSize(newHeight);
      Log.info(TAG, `onSizeChange, newHeight: ${newHeight}`);
    })
  }
}

/**
 * 重要日卡片UI数据
 */
class ImportantConfig {
  public backgroundId: BackgroundId = BackgroundId.TEXTURES;

  public texturesId: TextureId = TextureId.MOIRE;

  public layoutId: LayoutId = LayoutId.CENTER;

  public fontId: FontId = FontId.DEFAULT;

  public color: string = Color.DEFAULT;

  public opacity: number = 1;

  public topBright: number = 1;

  public bottomBright: number = 1;
}

export {
  ImportantCardView, ImportantConfig
}

/**
 * 跳转到月视图
 */
function jumpToMonthView(obj: FormUtils, year: number, month: number, day: number, formId: string) {
  Log.info(TAG, `formId: ${formId} Jump to month view, year: ${year}, month: ${month + 1}, day: ${day}`);
  postCardAction(obj, {
    'action': 'router',
    'bundleName': 'com.ohos.calendar',
    'abilityName': 'MainAbility',
    'params': {
      'action': 'CLICK_MONTH_FORM_HEADER',
      'tabIndex': '1',
      'year': year,
      'month': month,
      'day': day,
      'faType': 'importantCard2x2'
    }
  });
}

function getLocalDateText(timeStamp: number, eventCalendarType: number): string {
  return getDateText(new CalendarDate(timeStamp), eventCalendarType, true);
}
