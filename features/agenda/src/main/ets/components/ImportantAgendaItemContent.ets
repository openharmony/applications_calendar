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
  AgendaItemLayout,
  AgendaService,
  AgendaTransitionUtil,
  BigFontSize,
  CalendarDate,
  CalendarLayoutManager,
  DateUtil,
  EmptyUtils,
  FontSizeScaleUtils,
  GlobalDataKeys,
  Log,
  LunarDateUtil,
  ServiceEnum,
  ServiceManager,
  I18nUtil,
  ObservedArray
} from '@app/common';

import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { CardDataPanel } from './CardDataPanel';
import { IRichText, AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { AgendaOffsetTitle } from '../service/AgendaServiceImpl';

const TAG = 'ImportantAgendaItem';

/**
 * 重要日日程的背板样式
 */
class ImportantAgendaBoardModifier implements AttributeModifier<ColumnAttribute> {
  private fromType: FromType = FromType.UNKNOWN;
  public isDarkMode: boolean | undefined = undefined;

  constructor(fromType: FromType, isDarkMode: boolean | undefined) {
    this.fromType = fromType;
    this.isDarkMode = isDarkMode;
  }

  applyNormalAttribute(instance: ColumnAttribute): void {
    // comp_background_list_card深色模式时为透明色，在月视图时需为ohos_id_color_list_card_bg
    const importantBackgroundColor = this.fromType === FromType.MONTH_VIEW ?
      $r('sys.color.ohos_id_color_list_card_bg') : $r('sys.color.comp_background_list_card');
    if (!this.isDarkMode) {
      const importantBackgroundImage = $r('app.media.importantBgImg');
      instance.backgroundColor(importantBackgroundColor)
        .backgroundImage(importantBackgroundImage)
        .backgroundImageSize(ImageSize.Auto)
    } else {
      instance.backgroundColor(importantBackgroundColor)
    }
  }
}

/**
 * 搜索日程list重要日的item样式
 */
@Component
export struct ImportantAgendaItemContent {
  @StorageProp('themeColor') themeColor: string = '';

  // 当前展示的日期
  @StorageProp(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayDate: number = 0;

  // 小屏判断
  @Consume inSmallWindow: boolean;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @Link info: AgendaEventInfo;

  @Prop fromType: FromType = FromType.UNKNOWN;

  // 分栏场景是否选中
  @Link isChecked: boolean;

  // 搜索文字
  @Link searchText: string;

  @State titleSpanStrList: Array<IRichText> = [];

  private radius: number = 16;

  @Prop isScrolling: boolean = false;

  @State title: string = '';

  @State showPanel: boolean = true; // 用于周年时倒数日的显示与否

  @State agendaLayout: AgendaItemLayout = CalendarLayoutManager.getInstance().agendaLayout;

  @StorageProp('language') @Watch('onLanguageChange') language: string = 'zh';

  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean | undefined =
    AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 定制化背板样式
  @State modifier: ImportantAgendaBoardModifier =
    new ImportantAgendaBoardModifier(this.fromType, this.isDarkMode);

  onLanguageChange() {
    Log.info(TAG, 'onLanguageChange')
    this.onDisplayDateChange();
  }

  aboutToAppear() {
    this.onDisplayDateChange();
    const currentJulianDay: number = DateUtil.getJulianDay();
    Log.info(TAG, `currentJulianDay = ${currentJulianDay}, instanceId = ${this.info.mId}`);
  }

  onDarkModeChange() {
    Log.info(TAG, 'onDarkModeChange');
    this.processDarkModeChange(this.isDarkMode);
  }

  /**
   * 处理深色模式样式
   * @param isDarkMode
   */
  processDarkModeChange(isDarkMode: boolean | undefined) {
    this.modifier.isDarkMode = isDarkMode;
  }

  onDisplayDateChange() {
    this.title = this.info.mTitle;
    const server = ServiceManager.getInstance().getService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
    if (server) {
      if (EmptyUtils.isEmptyString(this.info.mRepeatRule) && this.displayDate > this.info.mBegin) {
        const utcStartMill = this.displayDate + new CalendarDate().getTimezoneOffset(this.displayDate);
        const titleOffset: AgendaOffsetTitle = server.updateNormalAgendaTitle(this.info, utcStartMill);
        this.title = titleOffset.title;
        this.showPanel = !titleOffset.isFullYear;
      } else {
        this.title = server.updateRepeatAgendaTitle(this.info, this.info.mBegin);
      }
    }
    this.titleSpanStrList = AgendaUtil.transTitleMessage(this.title, this.searchText);
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  onChangeFontSizeForSpace(num: number) {
    return FontSizeScaleUtils.getLimitHeightNum(
      this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SIX,
      num
    );
  }

  // 特大一档字体
  @Builder
  BiggerThanExtraLargeLayout() {
    Column() {
      this.ImportantAgendaTitle()
      Text(this.info.isLunarEvent() ? LunarDateUtil.getLunarDate(new CalendarDate(this.info.mBegin)) :
      DateUtil.getDateText(new CalendarDate(this.info.mBegin)))
        .fontSize(14)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.comp_focused_secondary'))
        .maxLines(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE ? 2 : 3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ top: 5.5, bottom: 5 })
      CardDataPanel({
        info: this.info
      })
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  NormalLayout() {
    Row() {
      Column({ space: this.onChangeFontSizeForSpace(5) }) {
        this.ImportantAgendaTitle()
        Text(this.info.isLunarEvent() ? LunarDateUtil.getLunarDate(new CalendarDate(this.info.mBegin)) :
        DateUtil.getDateText(new CalendarDate(this.info.mBegin)))
          .fontSize(this.agendaLayout.subTextFontSize)
          .fontWeight(FontWeight.Regular)
          .fontColor($r('sys.color.comp_focused_secondary'))
          .maxLines(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE ? 2 : 3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .flexShrink(2)

      Blank().width(12)

      Column() {
        CardDataPanel({
          info: this.info
        })
      }
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Center)
      .visibility(this.showPanel ? Visibility.Visible : Visibility.None)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
  }

  @Builder
  ImportantItemContent() {
    Row() {
      if (this.fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE) {
        this.BiggerThanExtraLargeLayout()
      } else {
        this.NormalLayout()
      }
    }
    .width('100%')
    .padding({
      left: 12,
      right: 12,
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8)
    })
    .backgroundColor(Color.Transparent)
    .stateStyles({
      pressed: {
        .backgroundColor(this.isScrolling ? '' : $r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(this.isChecked && !this.inSmallWindow ? '#33F76045' : Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .borderRadius(12)
    .constraintSize({ minHeight: 72 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  ImportantAgendaTitle() {
    Row() {
      Text() {
        ForEach(this.titleSpanStrList, (item: IRichText) => {
          Span(item.text)
            .fontColor(item.isHighLight ? this.themeColor : $r('sys.color.font_primary'))
            .fontSize(this.agendaLayout.mainTextFontSize)
        }, (item: IRichText, index: number | undefined): string =>
        '' + this.info.mId + this.info.mTitle + index + item.text)
      }
      .fontWeight(FontWeight.Medium)
      .fontSize(this.agendaLayout.mainTextFontSize)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
      .fontColor($r('sys.color.comp_focused_primary'))
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .ellipsisMode(EllipsisMode.CENTER)
      .maxLines(1)
      .constraintSize({ maxWidth: this.info?.mAttachmentCount > 0 ? 'calc(100% - 26vp)' : '100%' })

      if (this.info?.mAttachmentCount > 0) {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize(this.agendaLayout.mainTextFontSize)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
          .fontColor([$r('sys.color.comp_focused_primary')])
          .width(26)
          .draggable(false)
      }
    }
  }

  build() {
    Column() {
      this.ImportantItemContent()
    }
    .padding(4)
    .borderRadius(this.radius)
    .constraintSize({ minHeight: this.agendaLayout.agendaItemHeight })
    .attributeModifier(this.modifier)

  }
}