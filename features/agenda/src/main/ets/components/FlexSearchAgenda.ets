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
  AgendaTransitionUtil,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MIN_WINDOW_WIDTH_VP,
  traceEvents
} from '@app/common';
import { BackToTodayToolbarButton } from '@app/common.components';
import { AgendaDetail } from '../AgendaDetail/view/AgendaDetail';
import lazy { SearchAgendaView } from '../SearchAgenda/view/SearchAgendaView';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { emitter } from '@kit.BasicServicesKit';
import { addButtonTypeText, focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { FocusPage } from './FlexAgendaList';
import lazy { KeyCode } from '@kit.InputKit';
import { i18n } from '@kit.LocalizationKit';
import { AgendaDetailSource, SearchFromPage } from '../common/AgendaEnum';
import { LengthMetrics } from '@kit.ArkUI';
import { PaintCache } from '@app/common/src/main/ets/graphic/PaintCache';

const TAG: string = "FlexSearchAgenda";

/**
 * 搜索日程列表适应分栏的父组件
 *
 * @since 2023-03-15
 */
@Component
export struct FlexSearchAgenda {
  // 是否存在于弹窗中, 请勿晚于 inSmallWindow 初始化
  private isInPop: boolean = false;

  @Link showSearch: boolean;

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @Provide inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  @Provide currentDisplayStartMills: number = 0;

  @Provide currentDisplayEndMills: number = 0;

  // 选中日程id值
  @StorageLink('checkEventId') @Watch('onCheckIdChange') checkEventId: number = -1;

  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  // 搜索日程结果是否包含checkEventId
  @State isContainCheckId: boolean = false;

  // 搜索内容
  @State changeValue: string = '';

  // 是否显示日程列表界面
  @State @Watch('onShowResultChange') showResult: boolean = false;

  // 分栏显示日程的id
  @State showEventId: number = -1;

  @State holidayInfo: AgendaEventInfo | undefined = undefined;

  @State themeColor: string = '';

  @State canEdit: boolean = true;

  @State canShare: boolean = true;

  @State barBgOpacity: number = 0;

  @Provide calendarUuid: string = '';

  @State selectable: boolean = false; // 是否可以多选

  //回到今天按钮
  @State onBackToday: boolean = false;

  // 是否显示回到今日按钮
  @State isShowBackToToday: boolean = false;

  // 当焦点在搜索输入框时，按下键盘上下键，将键盘事件传入SearchAgendaView
  @State keyEventFromSearchBox: KeyEvent | undefined = undefined;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('fontSizeScale') @Watch('onFontSizeScaleChanges') fontSizeScale: number =
    BigFontSize.BIG_FONT_SIZE_STANDARD;

  private readonly ANIMATION_DURATION: number = 200;

  // 搜索控制器
  private controller: SearchController = new SearchController();

  private submitValue: string = '';

  @State private buttonTopHeight: number = this.inSmallWindow ? 0 : 8;

  private showResultChange: (showResult: boolean) => void = () => {
  }

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @Provide actionFocus: string = FocusPage.FLEX_SEARCH_AGENDA;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private columnColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  // 搜索框高度
  @State searchBarHeight: Length = 48 + this.buttonTopHeight + (this.isInPop && this.inSmallWindow ? 0 : 8);

  @StorageLink('language') @Watch('onLanguageChanges') language: string = i18n.System.getSystemLanguage();

  // 定制化搜索框字体样式
  @State modifier: searchModifier = new searchModifier(this.fontSizeScale, this.language);

  @State xMirror: boolean = false; // x镜像

  private fromPage: number = SearchFromPage.MAIN_PAGE;

  private emitterCollector : EmitterCollector = new EmitterCollector();

  onActionFocusChange(actionFocus: string) {
    this.actionFocus = actionFocus
  }


  onDismiss: Function = () => {
  };

  onShowResultChange() {
    this.showResultChange(this.showResult);
  }

  getPopupWindowHeight() {
     return this.windowHeightInVp < 660 ? this.windowHeightInVp - 100 : '560vp';
  }

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.searchAgenda, 0);
    this.enterAnimation();
    focusComponentById(CompId.AGENDA_SEARCH_INPUT, 150);
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    this.emitterCollector.on({
      eventId: CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER
    }, this.setSearchBoxFocus);
    this.emitterCollector.on({
      eventId: CommonInnerEvent.DELETE_DIALOG_DELETE_AGENDA_SUCCESS
    }, this.setSearchBoxFocus);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  onFirstIdChange(firstEventId: number, isContainCheckId: boolean) {
    this.showEventId = isContainCheckId ? this.checkEventId : firstEventId;
  }

  onCheckIdChange() {
    if (this.checkEventId !== -1) {
      this.showEventId = this.checkEventId;
    }
  }
  onLanguageChanges() {
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    this.modifier.language = this.language;
  }

  onFontSizeScaleChanges() {
    this.modifier.fontSizeScale = this.fontSizeScale;
  }

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
    this.buttonTopHeight = this.inSmallWindow ? 0 : 8;
    this.searchBarHeight = 48 + this.buttonTopHeight + (this.isInPop && this.inSmallWindow ? 0 : 8);
  }

  forkDismissAnimation(): void {
    this.showSearch = false;
    this.controller.stopEditing();
    if (this.isInPop) {
      Log.info(TAG, 'forkDismissAnimation Search Agenda Page Try To Close Popup Bind By More Button!');
      emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
    } else {
      this.onDismiss();
    }
  }

  backDismissAnimation(): void {
    animateTo({ duration: this.ANIMATION_DURATION, curve: Curve.FastOutSlowIn }, () => {
      this.showSearch = false;
      this.barBgOpacity = 0;
      this.controller.stopEditing();
    });
    const timeoutId = setTimeout(() => {
      if (this.isInPop) {
        Log.info(TAG, 'backDismissAnimation Search Agenda Page Try To Close Popup Bind By More Button!');
        emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
      } else {
        this.onDismiss();
      }
      clearTimeout(timeoutId);
    }, this.ANIMATION_DURATION);
  }

  enterAnimation(): void {
    animateTo({
      duration: this.ANIMATION_DURATION, onFinish: () => {
        hiTraceMeter.finishTrace(traceEvents.searchAgenda, 0);
      }
    }, () => {
      this.barBgOpacity = 1;
    });
  }

  // 日程搜索页左侧返回按钮
  @Builder
  buildBackButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph(this.selectable ? $r('sys.symbol.xmark') : $r('sys.symbol.chevron_backward'))
        .focusable(true)
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
    }
    .focusable(true)
    .height(40)
    .width(40)
    .backgroundColor(this.columnColor)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick(() => {
      if (this.selectable) {
        this.selectable = false;
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, { data: { 'selectAll': false } });
        return;
      }
      focusControl.requestFocus(CompId.AGENDA_LIST_KEY);
      this.backDismissAnimation();
    })
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
    .id(CompId.AGENDA_SEARCH_BACK)
  }

  // 日程搜索页在子窗内 右侧返回按钮
  @Builder
  buildForkButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .focusable(true)
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
    }
    .focusable(true)
    .height(40)
    .width(40)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor(this.columnColor)
    .onClick(() => {
      if (this.selectable) {
        this.selectable = false;
        emitter.emit({eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED}, {data: {'selectAll': false}});
        focusControl.requestFocus(CompId.AGENDA_LIST_KEY);
        return;
      }
      this.forkDismissAnimation();
    })
    .margin({
      left: $r('sys.float.padding_level4')
    })
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
    .id(CompId.AGENDA_SEARCH_BACK)
  }

  // 日程搜索页搜索框
  @Builder
  buildSearchBox() {
    Search({
      value: this.changeValue,
      placeholder: $r('app.string.search_for_events'),
      controller: this.controller
    })
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .placeholderColor($r('sys.color.font_secondary'))
      .selectedBackgroundColor(this.themeColor)
      .textFont({ size: $r('sys.float.Body_L') })
      .placeholderFont({
        size: FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, this.xMirror ? 
          BigFontSize.BIG_FONT_SIZE_SPECIAL : BigFontSize.BIG_FONT_SIZE_SCALE,
          16),
        family: PaintCache.instance().getFontFamilyPath(),
        style: FontStyle.Normal
      })
      .maxFontSize(16)
      .attributeModifier(this.modifier)
      .minFontSize('16vp')
      .enableKeyboardOnFocus(true)
      .onSubmit((value: string) => {
        this.submitValue = value;
        Log.hilogInfo(TAG, 'submitValue is %{private}s', this.submitValue);
      })
      .caretStyle({
        color: this.themeColor
      })
      .onChange((value: string) => {
        this.changeValue = value;
        this.showResult = this.changeValue !== '';
        if (value === '') {
          this.showEventId = -1;
          this.isShowBackToToday = false;
        }
      })
      .onKeyEvent((event: KeyEvent) => {
        if ((event.keyCode === KeyCode.KEYCODE_DPAD_UP ||
          event.keyCode == KeyCode.KEYCODE_DPAD_DOWN) && event.type === KeyType.Down) {
          Log.info(TAG, 'press key_up or key_down when focus on SearchBox');
          this.keyEventFromSearchBox = event;
        }
      })
      .onAppear(()=>{
        focusControl.requestFocus(CompId.FLEX_SEARCH_AGENDA_SEARCH_INPUT);
      })
      .id(CompId.FLEX_SEARCH_AGENDA_SEARCH_INPUT)
  }

  // 分栏场景下右侧日程详情
  @Builder
  DetailBuilder() {
    Row() {
      Divider()
        .vertical(true)
        .width(1)
        .strokeWidth(1)
        .color($r('sys.color.comp_divider'))
      if (this.showEventId !== -1) {
        AgendaDetail({
          canEdit: $canEdit,
          canShare: $canShare,
          eventId: this.showEventId,
          isDivide: !this.isInPop,
          needLeftPadding: true,
          needRightPadding: true,
          holidayInfo: this.holidayInfo || undefined,
          isShowBottom: !this.selectable,
          sourceType: AgendaDetailSource.SEARCH_LIST,
          onDeleteSuccess: () => {
            this.pageRouterBack();
          },
          displayStartMills: this.currentDisplayStartMills,
          displayEndMills: this.currentDisplayEndMills,
          onActionFocusChange: (actionFocus: string): void => this.onActionFocusChange(actionFocus),
          paddingLeft: 16,
          paddingRight: 16,
        }).height('100%')
          .padding({
            bottom: this.windowAvoidAreaNavigationRectHeight,
          })
          .id(CompId.FLEX_SEARCH_AGENDA_AGENDA_DETAIL)
      } else {
        Column() {
        }
        .backgroundColor($r('sys.color.background_secondary'))
        .width('100%')
        .height('100%')
        .padding({ bottom: this.windowAvoidAreaNavigationRectHeight })
      }
    }
    .layoutWeight(1)
  }

  @Builder
  buildSearchBar() {
    Row() {
      if (!this.isInPop) {
        this.buildBackButton()
      }

      Stack({ alignContent: Alignment.End }) {
        this.buildSearchBox()
      }
      .padding({
        start: this.isInPop ? LengthMetrics.vp(0) : LengthMetrics.vp(8),
        end: this.isInPop ? LengthMetrics.vp(0) : LengthMetrics.vp(this.titleButtonWidth)
      })
      .layoutWeight(1)

      if (this.isInPop && this.isShowBackToToday) {
        BackToTodayToolbarButton({
          isForMainPage: false,
          onButtonClick: () => {
            this.onBackToday = !this.onBackToday;
          }
        })
      }

      if (this.isInPop) {
        this.buildForkButton()
      }
    }
    .padding({
      top: this.isInPop && !this.inSmallWindow ? 12 : 0,
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8'),
      bottom: this.isInPop ? 0 : 8,
    })
    .height(this.searchBarHeight)
    .alignItems(VerticalAlign.Center)
    .opacity(this.barBgOpacity)
    .backgroundColor($r('sys.color.background_secondary'))
  }

  // 展示搜索结果
  @Builder
  buildSearchResult() {
    if (!this.showResult) {
      Column() {
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        Log.info(TAG, 'click to dismiss search')
        this.backDismissAnimation();
      })
      .accessibilityLevel('no')
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityText($r('app.string.accessibility_exit_search'))

      .layoutWeight(1)
    } else {
      Row() {
        Column() {
          SearchAgendaView({
            changeValue: $changeValue,
            selectable: $selectable,
            showResult: $showResult,
            showEventId: $showEventId,
            onFirstIdChange: (firstEventId: number, isContainCheckId: boolean) => {
              this.onFirstIdChange(firstEventId, isContainCheckId);
            },
            onDeleteSuccess: () => {
              this.pageRouterBack();
            },
            isInPop: this.isInPop,
            onBackToday: this.onBackToday,
            isShowBackToToday: $isShowBackToToday,
            keyEventFromSearchBox: this.keyEventFromSearchBox
          })
        }
        .layoutWeight(1)

        if (!this.inSmallWindow && !this.isInPop) {
          this.DetailBuilder();
        }
      }
      .height(488)
      .layoutWeight(1)
      .backgroundColor($r('sys.color.background_secondary'))
    }
  }

  @Styles
  backgroundStyle(){
    .backgroundColor(DeviceConfig.instance().config.deviceLayout.searchBackgroundColor)
    .backgroundBlurStyle(DeviceConfig.instance().config.deviceLayout.searchBackgroundBlur)
  }

  build() {
    Column() {
      this.buildSearchBar()
      this.buildSearchResult()
    }
    .height(this.isInPop ? this.getPopupWindowHeight() : '100%')
    .margin({ left: this.inSmallWindow ? 0 : 1 })
    .id('FlexSearchAgenda')
    .scale({ x: this.agendaTransitionUtil.scalePage, y: this.agendaTransitionUtil.scalePage })
    .onTouch((event) => {
      if (this.changeValue === '' && !this.isInPop) {
        animateTo({
          duration: this.ANIMATION_DURATION,
          curve: Curve.FastOutSlowIn
        }, () => {
          this.showSearch = false;
        })
      }
    })
    .responseRegion([
      { x: 0, y: this.searchBarHeight, width: '100%', height: '100%' }, // 热区向下偏移搜索框高度
    ])
  }

  pageRouterBack() {
    GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
    if (this.inSmallWindow) {
      this.enterAnimation();
    }
  }

  // 日程详情返回或搜索页删除日程成功后需要设置焦点在搜索组件上
  private setSearchBoxFocus: () => void = (): void => {
    focusControl.requestFocus(CompId.FLEX_SEARCH_AGENDA_SEARCH_INPUT);
  };
}

/**
 * 搜索框行高样式 ，适配大字体下日语显示截断问题 ，加lineHeight会影响整体显示偏下，只在大字体日文格式下添加
 */
class searchModifier implements AttributeModifier<SearchAttribute> {
  public fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;
  public language: string = '';

  constructor(fontSizeScale: number, language: string) {
    this.fontSizeScale = fontSizeScale;
    this.language = language;
  }

  applyNormalAttribute(instance: SearchAttribute): void {
    if (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL && this.language?.includes('ja')) {
      // 组件原因，直接设置行高会导致大字体场景下文字无法居中显示
      instance.lineHeight(19);
    }
  }
}