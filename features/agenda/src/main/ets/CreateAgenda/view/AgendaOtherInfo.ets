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

import { AgendaEventInfo, BigFontSize, CompId, DeviceConfig, FontSizeScaleUtils,
  Log,
  NavPathManager,
  NavPathName,
  RouterName,
  TimeZoneUtil} from '@app/common';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { LengthMetrics } from '@kit.ArkUI';
import measure from '@ohos.measure';
import { AgendaType } from '../Constants';

const TAG = 'AgendaOtherInfo';
const MAX_DESCRIPTION_LEN = 10000;

@Component
export struct AgendaOtherInfo {
  @Link eventInfo: AgendaEventInfo;

  @Prop currentIndex: number;

  @Prop @Watch('agendaTimeZoneChange') agendaTimeZone: string;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  scrollerForList: Scroller | null = null;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @State mDescription: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 是否编辑态
  private isEditMode: boolean = false;

  @State rowLinesBeyondOne: boolean = false;

  @State @Watch('onRowWidthChanged') rowWidth: number = 0;

  @State timeZoneLabel: string = '';

  // 是否存在于弹窗中
  @State isShowTimeZonePage: boolean = false;

  aboutToAppear(): void {
    this.initTimeZone();
  }

  initTimeZone() {
    if (!this.agendaTimeZone) {
      return;
    }
    this.timeZoneLabel = TimeZoneUtil.localizedNameOfTheTimeZone(this.agendaTimeZone, this.language);
  }

  onLanguageChange() {
    this.initTimeZone();
  }

  agendaTimeZoneChange() {
    this.initTimeZone();
  }

  onRowWidthChanged() {
    const renderTextWidthPx: number = measure.measureText(
      { textContent: this.timeZoneLabel, fontSize: 14, fontWeight: FontWeight.Regular }
    );
    const renderTextWidth = px2vp(renderTextWidthPx);
    this.rowLinesBeyondOne = renderTextWidth > 50 ? true : false;
    Log.info(TAG,
      `onRowWidthChanged, rowWidth:${this.rowWidth},rowLinesBeyondOne:${this.rowLinesBeyondOne}`);
  }

  @Builder
  BuildDescTextArea() {
    TextArea({ placeholder: $r('app.string.hint_description'), text: $$this.mDescription })
      .maxLength(MAX_DESCRIPTION_LEN + 1)
      .backgroundColor(Color.Transparent)
      .fontWeight(FontWeight.Medium)
      .selectedBackgroundColor(this.themeColor)
      .caretColor(this.themeColor)
      .fontWeight(FontWeight.Medium)
      .onChange((value) => {
        if (value.length > MAX_DESCRIPTION_LEN) {
          value = value.substring(0, MAX_DESCRIPTION_LEN);
          showToast($r('app.string.content_length_exceeds_the_maximum'));
        }
        this.mDescription = value;
        this.eventInfo.mDescription = value;
      })
      .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
        if (newValue.height && oldValue.height && newValue.height > oldValue.height && this.scrollerForList) {
          this.scrollerForList.scrollEdge(Edge.Bottom)
        }
      })
      .padding({
        top: 0,
        bottom: 0,
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6')
      })
      .margin({
        top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
        left: 0,
        right: 0
      })// textArea自带圆角，影响光标
      .borderRadius(0)
      .id(CompId.AGENDA_REMARK)
      .layoutWeight(1)
  }

  @Builder
  BuildTimeZoneText() {
    Text($r('app.string.edit_event_timezone_label'))
      .fontColor($r('sys.color.font_primary'))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .margin({ start: LengthMetrics.vp(12), end: LengthMetrics.vp(8) })
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  BuildTimeZoneLabel() {
    Row() {
      Row() {
        Text(this.timeZoneLabel)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .opacity(0.6)
          .fontColor($r('sys.color.font_primary'))
          .layoutWeight(this.rowLinesBeyondOne ? 1 : 0)
          .margin({ start: LengthMetrics.vp(12), end: LengthMetrics.vp(this.isEditMode ? 12 : 0) })
          .id(CompId.ADD_AGENDA_SELECTED_ACCOUNT_TEXT)
          .textAlign(this.isChangeLayout() ? TextAlign.Start : TextAlign.End)
      }
      .layoutWeight(1)
      .justifyContent(this.isChangeLayout() ? FlexAlign.Start : FlexAlign.End)

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ start: LengthMetrics.vp(4), end: LengthMetrics.vp(12) })
        .visibility(this.isEditMode ? Visibility.None : Visibility.Visible)
        .align(Alignment.Center)
    }
    .layoutWeight(this.isChangeLayout() ? 0 : 1)
    .width(this.isChangeLayout() ? '100%' : '')
    .justifyContent(this.isChangeLayout() ? FlexAlign.SpaceBetween : FlexAlign.End)
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
      if (ov.width === nv.width) {
        return;
      }
      this.rowWidth = nv.width as number;
    })
  }

  @Builder
  BuildTimeZone() {
    if (this.isChangeLayout()) {
      this.BuildColumnTimeZone();
    } else {
      this.BuildRowTimeZone();
    }
  }

  @Builder
  BuildRowTimeZone() {
    Row() {
      Row() {
        this.BuildTimeZoneText();

        this.BuildTimeZoneLabel();
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .constraintSize({ minHeight: 48 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'));
        },
        normal: {
          .backgroundColor(Color.Transparent);
        }
      })
      .hoverEffect(this.isEditMode ? HoverEffect.None : HoverEffect.Highlight)
      .id(CompId.ADD_AGENDA_SELECTED_TIMEZONE);
    }
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding({
      left: 4,
      right: 4,
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
    .margin({
      top: 12,
      bottom: this.windowAvoidAreaNavigationRectHeight > 0 ? this.windowAvoidAreaNavigationRectHeight : 16
    })
    .onClick(() => {
      const params: Record<string, number | boolean | string> = {};
      params.isInPop = false;
      params.isFormAgenda = true;
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.SETTINGS_TIME_ZONE,
        routerName: RouterName.CREATE_AGENDA_MAIN,
        param: params
      });
    })
    .focusBox({
      margin: LengthMetrics.px(-4),
    })
  }

  @Builder
  BuildColumnTimeZone() {
    Column() {
      Column() {
        Row() {
          this.BuildTimeZoneText();
        }.margin({ top: $r('sys.float.padding_level6')})

        Row() {
          this.BuildTimeZoneLabel();
        }.margin({ bottom: $r('sys.float.padding_level4')})
      }
      .focusable(true)
      .focusBox({
        margin: LengthMetrics.px(-8),
      })
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .constraintSize({ minHeight: 56 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'));
        },
        normal: {
          .backgroundColor(Color.Transparent);
        }
      })
      .hoverEffect(this.isEditMode ? HoverEffect.None : HoverEffect.Highlight)
      .id(CompId.ADD_AGENDA_SELECTED_TIMEZONE);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .constraintSize({ minHeight: 56 })
    .padding($r('sys.float.padding_level2'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
    .margin({
      top: 12,
      bottom: this.windowAvoidAreaNavigationRectHeight
    })
    .onClick(() => {
      const params: Record<string, number | boolean | string> = {};
      params.isInPop = false;
      params.isFormAgenda = true;
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.SETTINGS_TIME_ZONE,
        routerName: RouterName.CREATE_AGENDA_MAIN,
        param: params
      });
    })
  }

  build() {
    Column() {
      Row() {
        this.BuildDescTextArea();
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .id(CompId.AGENDA_OTHER_INFO)
      .padding({
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
      .margin({
        top: 12
      });

      if (this.currentIndex === AgendaType.DEFAULT) {
        this.BuildTimeZone()
      }
    };
  }
}