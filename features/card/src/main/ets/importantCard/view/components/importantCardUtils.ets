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
  BackgroundPanelId,
  EventMode,
  ImportantCardConfig,
  LayoutId,
  TextureId
} from '@app/common/src/main/ets/card/ImportantCardConfig';
import { ImportantEntity } from '../../model/ImportantEntity';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import {
  AccountUtils,
  AgendaEventInfo,
  behaviorEvents,
  BigFontSize,
  CalendarAccountType,
  CalendarContract,
  CalendarDate,
  CalendarService,
  DateUtil,
  DeviceConfig,
  FontSizeScaleUtils,
  getAdaptImportantTime,
  Log,
  ReportUtil,
  TimeZoneUtil
} from '@app/common';
import { addImageText } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { LengthMetrics } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';
import { SUPPORT_CHINESE_HOLIDAYS } from '../../model/ImportantCardModel';
import { CardUiUtils } from '../../util/CardUiUtils';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';

const TAG: string = 'ImportantCardUtils';
const IN_DAYS: string = 'in_days';
const DAYS_LATER: string = 'days_later';

//图片的通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

export function convertToImportantEntity(array: Array<AgendaEventInfo>, isBirthday: boolean): ImportantEntity[] {
  const result: ImportantEntity[] = [];
  array.forEach((item: AgendaEventInfo) => {
    const important: ImportantEntity = new ImportantEntity();
    important.title = item.mTitle;
    important.eventId = item.mId;
    important.begin = item.mBegin;
    important.originalBegin = item.mOriginalBegin;
    important.end = item.mEnd;
    important.eventTimeStamp = item.mEventTimeStamp;
    important.rrule = item.mRepeatRule;
    important.duration = item.duration;
    important.importantEventType = item.mImportantEventType;
    important.eventCalendarType = item.mEventCalendar;
    if (isBirthday) {
      important.accountType = CalendarContract.CalendarType.BIRTHDAY;
    }
    important.mAttachmentCount = item.mAttachmentCount;
    result.push(important);
  });
  return result;
}

/**
 * get important agenda precedence by type
 * @param { string } type - important agenda type, acquired from DateUtil.getDayOffset
 * @returns { number } - precedence of provided type
 */
export function importantTypePrecedence(type: string) {
  switch (type) {
    case IN_DAYS:
      return 2;
    case DAYS_LATER:
      return 1;
    default:
      return 0;
  }
}

/**
 * compare function between two agendas, countdown events have higher precedence
 * events that is more close to today have higher precedence
 * @param { AgendaEventInfo } agenda1 - agenda to be compared
 * @param { AgendaEventInfo } agenda2 - agenda to be compared
 * @returns { number } - relative precedence over the other
 */
export function sortImportantAgenda(agenda1: AgendaEventInfo, agenda2: AgendaEventInfo) {
  const instanceTime1 = agenda1.isRepeatEvent() ? getAdaptImportantTime(agenda1.mEventCalendar, agenda1.mBegin,
    agenda1.mRepeatRule, new CalendarDate()) : agenda1.mBegin;
  const instanceTime2 = agenda2.isRepeatEvent() ? getAdaptImportantTime(agenda2.mEventCalendar, agenda2.mBegin,
    agenda2.mRepeatRule, new CalendarDate()) : agenda2.mBegin;
  const agenda1Info = DateUtil.getDayOffset(instanceTime1, agenda1.mImportantEventType);
  const agenda2Info = DateUtil.getDayOffset(instanceTime2, agenda2.mImportantEventType);
  if (agenda1Info.type === agenda2Info.type) {
    return agenda1Info.dayOffset - agenda2Info.dayOffset;
  } else {
    return importantTypePrecedence(agenda1Info.type) - importantTypePrecedence(agenda2Info.type);
  }
}

export function getValidImportantList(list: AgendaEventInfo[], valid: boolean = true): AgendaEventInfo[] {
  let validList: AgendaEventInfo[] = [];
  // 删除无效重要日
  for (let index = 0; index < list.length; index++) {
    const element: AgendaEventInfo = list[index];

    // 非循环重要日，检查日期是否过期
    if (Boolean(valid) === Boolean(isValid(element))) {
      validList.push(element);
    }
  }
  return validList.sort(sortImportantAgenda);
}

export function isValid(element: AgendaEventInfo) {
  if (element.mId <= 0) {
    return false;
  }
  if (element.mImportantEventType === 0 && !AccountUtils.isBirthDayAccountById(element.mCalendarId)) {
    return false;
  }
  // 未过期则有效，过期则无效
  return !isExpired(element);
}

export function isExpired(element: AgendaEventInfo, fixedEventId?: number): boolean {
  if (element.mImportantEventType === CalendarContract.EventImportantType.ANNIVERSARIES) {
    // 1.纪念日，不存在过期
    return false;
  }
  // 2.倒数日、节假日、生日，按是否周期日程做不同处理
  if (element.mRepeatRule) {
    // 周期性，不会过期
    return false;
  }
  // 3.固定节假日，不做过期处理，需寻找下一年度的节假日
  if (fixedEventId && element.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
    return false;
  }

  const eventDate: CalendarDate = new CalendarDate(element.mEnd);
  const nowTime = Date.now();
  // 获取系统时区的偏移量
  const timeStampOffset = TimeZoneUtil.getTimeZoneOffset(TimeZoneUtil.getCurrentTimeZone(), nowTime);
  const nowDate: CalendarDate = new CalendarDate(nowTime + timeStampOffset);
  // 非周期性日程，检查日期是否过期
  return eventDate.getTime() < nowDate.getTime();
}

// 获取联系人生日账户id
export async function loadBirthDayAccountId(): Promise<number> {
  const accounts: CalendarContract.Accounts[] =
    await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];

  let birthdayCalendarId = -1;
  for (let index = 0; index < accounts?.length; index++) {
    if (AccountUtils.isBirthDayAccount(accounts[index])) {
      birthdayCalendarId = accounts[index].id;
      break;
    }
  }
  return birthdayCalendarId;
}

// 获取中国节假日账户id
export async function loadChineseHolidayAccountId(): Promise<number> {
  const accounts: CalendarContract.Accounts[] =
    await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
  const commonHolidayAccountName = 'CN';
  const chineseHolidayAccountName = 'CN_CUSTOM';
  let chineseHolidayCalendarId = -1;
  for (let index = 0; index < accounts?.length; index++) {
    if ((chineseHolidayAccountName === accounts[index].accountName ||
      commonHolidayAccountName === accounts[index].accountName) &&
      CalendarAccountType.HOLIDAY_ACCOUNT_TYPE === accounts[index].accountType) {
      chineseHolidayCalendarId = accounts[index].id;
      break;
    }
  }
  return chineseHolidayCalendarId;
}

@Component
export struct CardSetLayout {
  @StorageProp('editing_formId') @Watch('onFormIdChange') formId: string = '';

  @Consume navPathStack: NavPathStack;

  // 主题色
  @StorageProp('themeColor') themeColor: string = '';

  @Link formConfig: ImportantCardConfig;

  @Prop title: Resource | string = '';

  @Prop isCard2x2: boolean = true;

  @Prop formWidth: number;

  @Prop formHeight: number;

  @Prop importantEventInfo: ImportantEntity | undefined = undefined;

  @Prop content: string = '';

  /** 是否隐藏操作栏 */
  @Prop hideSettingBar: boolean = false;

  @State diffHeight: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp('windowHeight') @Watch('onWindowHeightChange') windowHeight: number = 0;

  onSelectChange?: (config: ImportantCardConfig) => void;

  private DIFF_COUNT = 4;

  //系统导航栏规避区,在pc上可能为0，pc底部会贴边，所以下边加了三元表达式
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 容器最大高度
  private containerMaxHeight: number = 400;

  // verd横屏高度：440vp
  private verdLandscapeScreenHeight: number = 440;

  @State containerHeight: number = this.containerMaxHeight;

  /** 用于隐藏重要日0天时的天数字体和颜色选择栏 */
  @Prop dayOffset: number = -1;

  scroller: Scroller = new Scroller();

  onConfirm: () => void = () => {
  };

  onWindowHeightChange() {
    Log.info(TAG, `onWindowHeightChange, ${this.windowHeight}`)
    if (this.windowHeight <= this.verdLandscapeScreenHeight) {
      // 最小高度220，可容纳一行文字，为后续小设备兜底处理
      const minHeight = 220;

      // 默认高度对应容器高度400，verd高度对应容器高度280，默认差120, 刚好接壤
      const defaultDiff = 120;

      // 屏幕高度越小，差异越大
      const diff = this.verdLandscapeScreenHeight - this.windowHeight;

      const containerHeight = this.containerMaxHeight - defaultDiff - diff;
      this.containerHeight = Math.max(containerHeight, minHeight);
    } else {
      this.containerHeight = this.containerMaxHeight;
    }
  }

  onFormIdChange() {
    this.scroller.scrollEdge(Edge.Start);
  }

  @Builder
  selectDateContent() {
    Text(this.formConfig.eventMode === EventMode.RECENT_HOLIDAY ? $r('app.string.recent_holiday') : this.title)
      .fontColor($r('sys.color.font_primary'))
      .fontSize(16)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(2)
      .width(this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? '100%' : undefined)
      .layoutWeight(this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? undefined : 1)
      .padding({ end: LengthMetrics.vp(16) })
    Row() {

      Text(this.content)
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .textAlign(this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? TextAlign.Start : TextAlign.End)
        .layoutWeight(this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? 1 : undefined)
        .opacity($r('sys.float.alpha_secondary'))
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(20)
        .margin({ left: 4 })
        .fontColor([$r('sys.color.icon_primary')])
        .opacity(0.3)
    }
  }

  build() {
    Stack() {
      Scroll(this.scroller) {
        Column() {
          // 日期选择
          this.selectDate()
          if (!this.hideSettingBar) {
            // 操作栏，含背景字体等选择
            this.settingBar()
          }
        }
        .borderRadius($r('sys.float.corner_radius_level6'))
      }
      .align(Alignment.Top)
      .width('100%')
      .scrollable(ScrollDirection.Vertical)
      .height(this.containerHeight)
      .scrollBar(BarState.Auto)
      // 底部按钮字体16，根据fontSizeScale放大，高度随之变大
      // 底部避让增加16，外边距需同步增加16，由140 ->156
      .margin({ bottom: 156 + 16 * (this.fontSizeScale - 1) })
      .borderRadius($r('sys.float.corner_radius_level6'))

      Column() {
        Stack() {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text($r('app.string.event_apply'))
              .fontColor($r('sys.color.white'))
              .fontSize(16)
          }
          .width('100%')
          .onClick(() => {
            this.onConfirm();
          })
          .constraintSize({
            minHeight: 40,
          })
          .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level10'))
          .backgroundColor($r('app.color.red_common'))
        }.width('100%')
      }
      .backgroundColor($r('sys.color.background_secondary'))
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .padding({
        top: $r('sys.float.padding_level8'),
        bottom: this.windowAvoidAreaNavigationRectHeight === 0
          ? $r('sys.float.padding_level16')
          // 底部按钮避让新规范，避让区域外加16vp
          : this.windowAvoidAreaNavigationRectHeight + 16
      })
      .margin({ bottom: 56 })
    }
    .height(this.containerHeight)
    .width('100%')
    .alignContent(Alignment.Bottom)
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({
      top: $r('sys.float.padding_level12'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .margin({
      left: -16,
      right: -16
    })
    .borderRadius({
      topLeft: $r('sys.float.corner_radius_level16'),
      topRight: $r('sys.float.corner_radius_level16')
    })
  }

  /** 日期选择框 */
  @Builder
  selectDate() {
    if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE) {
      Text($r('app.string.select_date'))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ bottom: 9 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .opacity($r('sys.float.alpha_secondary'))
        .padding({
          left: $r('sys.float.padding_level6'),
        })

      Column() {
        this.selectDateContent()
      }
      .constraintSize({
        minHeight: 56
      })
      .borderRadius($r('sys.float.corner_radius_level8'))
      .width('100%')
      .padding({
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6'),
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale),
        top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale)
      })
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor($r('sys.color.comp_background_list_card'))
        }
      })
      .onClick(() => {
        this.launchEventSelectPage();
      })
    } else {
      Text($r('app.string.select_date'))
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_primary'))
        .margin({ bottom: 9 })
        .textAlign(TextAlign.Start)
        .width('100%')
        .opacity($r('sys.float.alpha_secondary'))
        .padding({
          left: $r('sys.float.padding_level6'),
        })

      Row() {
        this.selectDateContent()
      }
      .constraintSize({
        minHeight: 56
      })
      .borderRadius(16)
      .width('100%')
      .padding({
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .justifyContent(FlexAlign.SpaceBetween)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      , normal: {
          .backgroundColor($r('sys.color.comp_background_list_card'))
        }
      })
      .onClick(() => {
        this.launchEventSelectPage();
      })
    }
  }

  // 操作栏，含背景字体等选择
  isVisible(formConfig: ImportantCardConfig) {
    // 正常背景
    if (formConfig.backgroundId === BackgroundId.TEXTURES) {
      return true;
    }

    // 自定义背景
    if (formConfig.backgroundId === BackgroundId.CUSTOMIZE && formConfig.panelId === BackgroundId.TEXTURES) {
      return true;
    }

    return false;
  }
  @Builder
  settingBar() {
    Column() {
      Text($r('app.string.select_texture'))
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 20, bottom: 9 })
        .opacity($r('sys.float.alpha_secondary'))
        .padding({
          left: $r('sys.float.padding_level6'),
        })
        .textAlign(TextAlign.Start);
      TextureSelect({
        formConfig: this.formConfig,
        themeColor: this.themeColor
      })
        .width('100%');
    }
    .alignItems(HorizontalAlign.Start)
    .visibility(this.isVisible(this.formConfig) ? Visibility.Visible : Visibility.None)

    Column() {
      Text($r('app.string.select_layout'))
        .fontSize(14)
        .fontColor($r('sys.color.font_primary'))
        .margin({ top: 20, bottom: 9 })
        .opacity($r('sys.float.alpha_secondary'))
        .padding({
          left: $r('sys.float.padding_level6'),
        })
        .textAlign(TextAlign.Start)
        .onSizeChange(size => {
          const height = size.height as number;
          this.diffHeight = Math.max(0, Math.ceil(height));
        });
      LayoutSelect({
        formConfig: this.formConfig,
        isCard2x2: this.isCard2x2,
        themeColor: this.themeColor
      }).width('100%');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }

  private launchEventSelectPage() {
    const param: Record<string, number | ImportantCardConfig | undefined> = {};
    param.mId = this.importantEventInfo?.eventId;
    param.config = this.formConfig;
    ReportUtil.reportBehaviorEvent(behaviorEvents.importantFaClickSelectDate);
    this.navPathStack.pushPathByName(NavPathName.IMPORTANT_CARD_SELECT, param, (popInfo: PopInfo) => {
      const result = popInfo?.result as ImportantCardConfig;
      if (this.onSelectChange && result) {
        this.onSelectChange(result);
      } else {
        Log.warn(TAG, 'pop from select page do nothing');
      }
    });
  }
}

// 底纹
@Component
export struct TextureSelect {
  @StorageProp('editing_formId') @Watch('onFormIdChange') formId: string = '';
  @Link formConfig: ImportantCardConfig;

  // 主题色
  @Prop themeColor: string = '';

  scroller: Scroller = new Scroller();

  onFormIdChange() {
    this.scroller.scrollEdge(Edge.Start);
  }

  build() {
    Row() {
      Scroll(this.scroller) {
        Row({ space: 8 }) {
          ForEach(this.formConfig.supportTextureIds, (textureId: TextureId, index: number) => {
            Column() {
              Image(CardUiUtils.getTextureById(textureId))
                .objectFit(ImageFit.None)
                .opacity(0.5)
                .borderRadius($r('sys.float.corner_radius_level6'))
            }
            .accessibilityText(CardUiUtils.getTextureAccessibilityTextById(textureId))
            .width(82)
            .height(82)
            .border(
              this.formConfig.texturesId === textureId ? {
                width: 1,
                color: this.themeColor
              } : {
                width: 0.5,
                color: 'rgba(0, 0, 0, 0.05)'
              }
            )
            .borderRadius($r('sys.float.corner_radius_level6'))
            .onClick(() => {
              if (this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
                showToast($r('app.string.reselect_contact_or_important_date'));
              } else {
                this.formConfig.texturesId = textureId;
              }
            })
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          })
        }
      }
      .width('100%')
      .align(Alignment.Start)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .padding({
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6'),
        top: $r('sys.float.padding_level12'),
        bottom: $r('sys.float.padding_level12'),
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
    }
  }
}

// 版式
@Component
export struct LayoutSelect {
  @Link formConfig: ImportantCardConfig;

  @Prop isCard2x2: boolean = true;

  // 主题色
  @Prop themeColor: string = '';

  build() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.formConfig.supportLayoutIds, (item: LayoutId) => {
          Column() {
            Image(CardUiUtils.getLayoutById(item, this.isCard2x2))
              .objectFit(ImageFit.Cover)
              .borderRadius($r('sys.float.corner_radius_level6'))
              .fillColor($r('sys.color.icon_primary'))
          }
          .accessibilityText(CardUiUtils.getLayoutTextById(item, this.isCard2x2))
          .width(this.isCard2x2 ? 60 : 120)
          .height(60)
          .border(
            this.formConfig.layoutId === item ? {
              width: 1,
              color: this.themeColor
            } : {
              width: 0
            }
          )
          .borderRadius($r('sys.float.corner_radius_level6'))
          .onClick(() => {
            if (this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
              showToast($r('app.string.reselect_contact_or_important_date'));
            } else {
              this.formConfig.layoutId = item;
            }
          })
        })
      }
    }
    .width('100%')
    .align(Alignment.Start)
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      top: $r('sys.float.padding_level12'),
      bottom: $r('sys.float.padding_level12'),
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }
}