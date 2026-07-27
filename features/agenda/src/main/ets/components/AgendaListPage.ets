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
  behaviorEvents,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  CreateAgendaSheetFromPage,
  DeviceConfig,
  GlobalDataKeys,
  Log,
  ModeUtil,
  NavPageBuilderFactory,
  NavPathName,
  ReportHiEventParams,
  ReportUtil,
  UnusualMode,
  ViewProxy,
  isNewSyncAbleAccount,
  ObjectUtils,
  ButtonImageType,
  ButtonLayoutParam,
  CalendarLayoutManager,
  ThrottleFunction,
  MIN_WINDOW_WIDTH_VP,
  MIDDLE_WINDOW_WIDTH_VP,
  TIPS_HOVER_DELAY,
  CalendarAccountType,
  EmptyUtils,
  FontSizeScaleUtils,
  PreferencesUtil,
  PreferencesFiles,
  AgendaListKey,
} from '@app/common';
import { TipsPopup, BackToTodayToolbarButton } from '@app/common.components';
import { FlexAgendaList } from './FlexAgendaList';
import emitter from '@ohos.events.emitter';
import { FlexSearchAgenda } from './FlexSearchAgenda';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';
import { ImageButton } from '@app/common.components';
import { EditAgendaMenu } from './EditAgendaMenu';
import { AgendaOperateHelper } from '../helpers/AgendaOperateHelper';
import { EditAgendaType } from '../AgendaDetail/view/BottomTab';
import { CreatePopupContent } from '../CreateAgenda/view/CreatePopupContent';
import { CreateAgendaPageSource } from '../CreateAgenda/Constants';
import { focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { SearchFromPage } from '../common/AgendaEnum';
import { DividerLine } from '../CreateAgenda/view/DividerLine';

const TAG: string = 'AgendaListPage';

interface RouterParam {
  id: number;
  instanceStartMills: number;
  instanceEndMills: number;
  calendarUuid: string;
  calendarName: ResourceStr;
  accountType: string;
  routerType: string;
}

@Builder
function harBuilder(navParams: object) {
  AgendaListPage({
    navParams: navParams
  });
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}

const builderName = NavPathName.AGENDA_LIST;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct AgendaListPage {
  @Consume navPathStack: NavPathStack;

  // 主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 是否显示回到今日按钮
  @Provide isShowBackToToday: boolean = false;

  @Provide keyCtrlState: boolean = false;

  //全部日程回到今天按钮
  @State onBackToday: boolean = false;

  //显示搜索日程页面
  @State showSearch: boolean = false;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Provide isOnDropAllowed: boolean = true;

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') @Watch('onModeChange') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  @StorageProp('isFloatingWindow') isFloatingWindow: boolean = false;

  // 折叠屏展开态单独布局
  @State isMiddleWindow: boolean = (this.windowWidth > MIN_WINDOW_WIDTH_VP) &&
    (this.windowWidth < MIDDLE_WINDOW_WIDTH_VP);

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;


  private showFloatButton: boolean = DeviceConfig.instance().config.showFloatButton;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private deviceShowBottomTab: boolean = DeviceConfig.instance().config.agendaDetailShowBottomTab;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private readonly ANIMATION_DURATION: number = 200;

  @State deleteSelected: boolean = false;

  @State shareSelected: boolean = false;

  @State editSelected: boolean = false;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @State event: AgendaEventInfo | undefined = new AgendaEventInfo();

  @State buttonLayout: ButtonLayoutParam = CalendarLayoutManager.getInstance().buttonLayout;

  @State canEdit: boolean = true;

  // 全部日程列表是否展示节日
  @State isShowHoliday: boolean = true;

  // 是否展示更多菜单
  @State showMenu: boolean = false;

  @State canShare: boolean = true;

  @State isShowDetail: boolean = false; //当前是否显示日程详情

  @State showEventId: number = -1;

  private navParams: object = JSON.parse('{}');

  @State showEditMenu: boolean = false;

  // 路由携带的 全部日程列表初始化查询时间戳
  private paramsDisplayStartMills: number = 0;
  private paramsDisplayEndMills: number = 0;

  // 路由携带的默认选中日程id
  private paramsEventId: number = 0;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private calendarUuid: string = '';

  private routerType: string = ''; // 跳转的类型,当前仅用于右键进入账户下全部日程场景

  private arrowIconModifier: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.checkmark')).fontColor([$r('sys.color.font_primary')]);

  // 账户下日程列表，当前的账户名称
  @State calendarName: ResourceStr = '';

  // 账户类型
  private accountType: string = CalendarAccountType.ALL_ACCOUNT_TYPE;

  @StorageLink('windowFocused') windowFocused: boolean = true;

  // 显示新建日程的半模态
  @State isCreatePopupShow: boolean = false;

  // 显示编辑日程跟手弹窗
  @State isEditPopupShow: boolean = false;

  // 关闭新建日程跟手弹窗时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  @State isRootLoad: boolean = false;

  private createPageData: emitter.EventData = {
    data: {
      fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
    }
  };

  // 内外屏接续
  private onModeChange() {
    if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
      this.selectable = false;
      this.showSearch = false;
    }
  }

  // 显示搜索框的方法
  private showSearchHandler = () => {
    Log.info(TAG, 'AgendaList Search Start');
    ThrottleFunction.instance().throttle(TAG, (): void => {
      animateTo({
        duration: this.ANIMATION_DURATION,
        curve: Curve.FastOutSlowIn
      }, () => {
        this.showSearch = true;
      })
    }, 200);
  }

  aboutToAppear(): void {
    const paramInter: RouterParam = this.navParams as RouterParam;
    if (!paramInter) {
      return;
    }
    try {
      this.paramsEventId = Number(paramInter.id);
      this.paramsDisplayStartMills = Number(paramInter.instanceStartMills);
      this.paramsDisplayEndMills = Number(paramInter.instanceEndMills);
      this.calendarUuid = paramInter.calendarUuid ?? '';
      this.routerType = paramInter.routerType ?? '';
      this.calendarName = paramInter.calendarName ?? '';
      this.accountType = paramInter.accountType ?? CalendarAccountType.ALL_ACCOUNT_TYPE;
    } catch (err) {
      Log.logErrorMsg(TAG, 'parse param failed', err);
    }
    // 初始化时需要读取sp内容用于记忆之前的变更
    this.isShowHoliday = PreferencesUtil.getBooleanValueSync(
      PreferencesFiles.AGENDA_LIST_IS_SHOW_HOLIDAY, AgendaListKey.IS_SHOW_HOLIDAY, true);
  }

  aboutToDisappear(): void {
  }

  private prevSelectCount: number = 0; // 上次多选条目

  @State @Watch('onSelectedCountChanged') selectedAgendaCount: number = 0; // 多选的数目

  @State selectable: boolean = false; // 是否可以选择

  @State selectAll: boolean = false; // 全选开关

  @State backIconModifier: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.chevron_backward'));

  @State xMarkIconModifier: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.xmark'));

  @State dummyFlag: boolean = false; // 无用flag

  @State showPopup: boolean = false; // 是否展示hover

  @State @Watch('hideListChange') hideList: boolean = false; // 是否隐藏list

  @State hideListButton: boolean = false; // 是否隐藏列表按钮,此处为区分动效故单独添加变量用于控制

  onSelectedCountChanged() {
    if (this.selectedAgendaCount < this.prevSelectCount) {
      this.selectAll = false; //选中的条目减少了，关闭全选
    }
    this.prevSelectCount = this.selectedAgendaCount;
  }

  hideListChange() {
    this.hideListButton = this.hideList;
  }

  /**
   * 左上角返回按钮
   */
  @Builder
  builderFork() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: this.selectable ? $r('sys.symbol.xmark') : $r('sys.symbol.chevron_backward'),
        flagChanged: $dummyFlag,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.navigate_up'),
        onButtonClick:() => {
          if (this.selectable) {
            this.selectable = false;
            focusControl.requestFocus(CompId.AGENDA_LIST_KEY);
          } else {
            this.openAccountDetail();
            this.navPathStack.pop();
          }
        }
      })
    }
    .backgroundColor(Color.Transparent)
    .id(CompId.BACK_MAIN)
    .focusable(true)
    .height(this.buttonLayout.menuHeight)
    .padding({ start: LengthMetrics.vp(16) })
  }

  @Builder
  buildCreatePopup() {
    Column() {
      CreatePopupContent({
        createPageData: this.createPageData,
        discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
        onCreatePageDismiss: () => {
          this.isCreatePopupShow = false;
          this.isEditPopupShow = false;
          this.createPageData = {
            data: {
              fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
            }
          }
        },
        setFullWidth: true
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 右上角按钮
   */
  @Builder
  builderRightButton() {
    if (!this.showFloatButton && this.isShowBackToToday && !this.hideListButton) {
      ImageButton({
        buttonType: ButtonType.Normal,
        image: $r('app.string.go_back_today'),
        flagChanged: $dummyFlag,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.back_to_today'),
        buttonImageType: ButtonImageType.TEXT,
        onButtonClick:() => {
          this.onBackToday = !this.onBackToday;
        }
      })
        .visibility(this.selectable ? Visibility.None : Visibility.Visible)
        .id(CompId.BUTTON_BACK_TO_TODAY)
        .padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level4') })
        .borderRadius($r('sys.float.corner_radius_level4'))
        .margin({ start: LengthMetrics.resource($r('sys.float.padding_level4')) })
    }
    this.zoomRightButton()
    if (this.showFloatButton && this.isShowBackToToday && !this.hideListButton && !this.selectable) {
      BackToTodayToolbarButton({
        isForMainPage: false,
        onButtonClick: () => {
          this.onBackToday = !this.onBackToday;
        }
      })
    }
    if (!this.showFloatButton && !this.hideListButton) {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.plus'),
        flagChanged: $dummyFlag,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.peek_create_agenda'),
        onButtonClick:() => {
          Log.info(TAG, 'to CreateEvent');
          this.isCreatePopupShow = true;
        }
      })
        .visibility(this.selectable || this.calendarName ? Visibility.None : Visibility.Visible)
        .margin({ start: LengthMetrics.vp(8) })
        .id(CompId.ADD_AGENDA)
        .width(40)
        .bindSheet($$this.isCreatePopupShow, this.buildCreatePopup(), {
          height: SheetSize.LARGE,
          detents: [SheetSize.LARGE, 0, 0],
          dragBar: false,
          showClose: false,
          preferType: SheetType.POPUP,
          shadow: ShadowStyle.OUTER_DEFAULT_SM,
          enableOutsideInteractive: false,
          maskColor: Color.Transparent,
          shouldDismiss: ((sheetDismiss: SheetDismiss) => {
            this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
          })
        })
    }
    if (!ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
      this.searchButton();
      // 共享日程不展示编辑删除等按钮
      if (!this.deviceShowBottomTab && !this.isSmallWindowChecked() && !this.isFloatingWindow) {
        this.detailOperationButtons();
      }
      // 联系人生日不显示多选按钮
      if (this.accountType !== CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE) {
        this.multiButton();
      }
    }
  }

  @Builder
  searchButton() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      image: $r('sys.symbol.magnifyingglass'),
      flagChanged: $dummyFlag,
      buttonBackgroundColor: this.buttonBackgroundColor,
      promptText: $r('app.string.search_for_events'),
      onButtonClick: () => {
        this.showSearchHandler();
      },
      compId: CompId.SEARCH_AGENDA
    })
    .visibility(this.selectable || this.hideListButton ? Visibility.None : Visibility.Visible)
    .margin({ start: LengthMetrics.vp(8) })
    .width(40)
  }

  @Builder
  multiButton() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      image: $r('sys.symbol.dot_grid_2x2'),
      flagChanged: $dummyFlag,
      buttonBackgroundColor: this.buttonBackgroundColor,
      promptText: $r('app.string.main_page_option_button'),
      onButtonClick: () => {
        this.showMenu = !this.showMenu;
      },
      compId: CompId.AGENDA_LIST_MORE
    })
      .bindMenu(this.showMenu, this.MoreMenu(), {
        placement: Placement.BottomRight,
        showInSubWindow: false,
        aboutToDisappear: () => {
          this.showMenu = false;
        }
      })
      .visibility(this.selectable || this.hideListButton ? Visibility.None : Visibility.Visible)
      .margin({ start: LengthMetrics.vp(8) })
      .width(40)
  }

  @Builder
  MoreMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.multiple_agenda') })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          this.onSelectAllClick();
        })
      DividerLine()
        .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
      MenuItem({
        content: $r('app.string.festival_holiday_Display'),
        builder: (): void => this.SubMenu(),
      })
    }
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Medium })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
    .radius(this.needCommerce ? 8 : undefined)
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
  }

  @Builder
  SubMenu() {
    Menu() {
      DividerLine();
      MenuItem({
        content: $r('app.string.show_festive_holiday'),
        symbolEndIcon: !this.isShowHoliday ? new SymbolGlyphModifier() : this.arrowIconModifier
      })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          this.isShowHolidayChange(true);
        })
      DividerLine();
      MenuItem({
        content: $r('app.string.hidden_festive_holiday'),
        symbolEndIcon: this.isShowHoliday ? new SymbolGlyphModifier() : this.arrowIconModifier
      })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          this.isShowHolidayChange(false);
        })
    }
    .width(224)
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
  }

  private isShowHolidayChange(isShowHoliday: boolean) {
    this.isShowHoliday = isShowHoliday;
    PreferencesUtil.putBooleanValueSync(PreferencesFiles.AGENDA_LIST_IS_SHOW_HOLIDAY,
      AgendaListKey.IS_SHOW_HOLIDAY, this.isShowHoliday);
  }

  @Builder
  detailOperationButtons() {
    // 分享
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      image: $r('sys.symbol.share'),
      flagChanged: $shareSelected,
      buttonBackgroundColor: this.buttonBackgroundColor,
      promptText: $r('app.string.agenda_menu_item_share'),
      compId: CompId.ID_BT_AGENDA_DETAIL_SHARE,
      buttonEnabled: !this.event?.isHoliday() && this.canShare && this.showEventId !== -1
    })
    .visibility(this.selectable ? Visibility.None : Visibility.Visible)
    .margin({ start: LengthMetrics.vp(8) })
    .width(40)

    // 编辑按钮
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.square_and_pencil'))
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
        .opacity(this.canEdit && this.showEventId !== -1 ? $r('sys.float.alpha_primary') :
        $r('sys.float.alpha_disable'))
    }
    .accessibilityText($r('app.string.agenda_menu_item_edit'))
    .visibility(this.selectable ? Visibility.None : Visibility.Visible)
    .bindMenu(this.showEditMenu, this.buildEditMenu(), {
      onDisappear: () => { this.showEditMenu = false; }
    })
    .stateEffect(this.canEdit && this.showEventId !== -1)
    .hoverEffect(this.canEdit && this.showEventId !== -1 ? HoverEffect.Auto : HoverEffect.None)
    .height(40)
    .width(40)
    .margin({ start: LengthMetrics.vp(8) })
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick(() => {
      this.onEditClick();
    })
    .onHover((isHover) => {
      ThrottleFunction.instance().debounce(TAG + 'editTips', () => {
        this.showPopup = !this.showEditMenu && isHover;
      }, isHover ? TIPS_HOVER_DELAY : 0);
    })
    .backgroundColor(this.buttonBackgroundColor)
    .bindPopup(this.showPopup, {
      builder: this.PopupComp($r('app.string.event_edit')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: false
    })
    .bindSheet($$this.isEditPopupShow, this.buildCreatePopup(), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.POPUP,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      enableOutsideInteractive: false,
      maskColor: Color.Transparent,
      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
        this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
      })
    })
    .id(CompId.EDIT_EVENT)

    // 删除
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      image: $r('sys.symbol.trash'),
      flagChanged: $deleteSelected,
      buttonBackgroundColor: this.buttonBackgroundColor,
      promptText: $r('app.string.agenda_menu_item_delete'),
      buttonEnabled: (!this.event?.isHoliday() && this.showEventId !== -1),
      compId: CompId.DELETE
    })
    .visibility(this.selectable ? Visibility.None : Visibility.Visible)
    .margin({ start: LengthMetrics.vp(8) })
    .width(40)
  }

  private onSelectAllClick() {
    if (!this.selectable) { // 如果没有开启全选，则默认打开全选
      this.selectable = true;
      focusComponentById(CompId.CUSTOM_TITLE_TEXT, 0);
    } else { // 开启了全选，则处理全选，反选效果
      this.selectAll = !this.selectAll;
      if (this.selectAll) {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED },
          { data: { 'selectAll': true } }) // 全选
      } else {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED },
          { data: { 'selectAll': false } }) // 反全选
      }
    }
  }

  private onEditClick() {
    if (!this.canEdit || this.showEventId === -1) {
      Log.info(TAG, `event cannot edit.`);
      return;
    }
    if (!this.event) {
      Log.info(TAG, `this.event undefined`);
      return;
    }
    AgendaOperateHelper.getCheckValueForEdit(this.event);
    if (this.event?.isRepeatEvent() && !this.event.isImportantEvent()) {
      this.showEditMenu = true;
    } else {
      this.createPageData = {
        data: {
          eventInfo: JSON.stringify(this.event),
          intent: CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE,
          fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
        }
      }
      this.isEditPopupShow = true;
    }
    this.showPopup = false;
  }

  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    if (this.event?.isRepeatEvent()) {
      EditAgendaMenu({
        isFirstRepeatAgenda: this.event?.isFirstRepeatAgenda(),
        editThisAgenda: () => {
          this.createPageData = {
            data: {
              eventInfo: JSON.stringify(this.event),
              intent: CreateAgendaPageSource.EDIT_THIS_AGENDA,
              fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE,
              instanceStartMills: this.event?.mBegin,
              instanceEndMills: this.event?.mEnd,
            }
          }
          this.isEditPopupShow = true;
          let param: ReportHiEventParams = {
            TYPE: EditAgendaType.ONLY_THIS
          };
          ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
        },
        editThisAgendaAndBeyond: () => {
          this.createPageData = {
            data: {
              eventInfo: JSON.stringify(this.event),
              intent: CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND,
              fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE,
              instanceStartMills: this.event?.mBegin,
              instanceEndMills: this.event?.mEnd,
            }
          }
          this.isEditPopupShow = true;
          let param: ReportHiEventParams = {
            TYPE: EditAgendaType.THIS_AND_FOLLOWING
          };
          ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
        },
        onClickEdit: () => {
          this.createPageData = {
            data: {
              eventInfo: JSON.stringify(this.event),
              intent: CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE,
              fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE,
            }
          }
          this.isEditPopupShow = true;
          let param: ReportHiEventParams = {
            TYPE: EditAgendaType.ALL
          };
          ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
        }
      })
    }
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  @Builder
  buildSearch() {
    if (this.showSearch) {
      Column() {
        FlexSearchAgenda({
          themeColor: this.themeColor,
          onDismiss: () => {
            this.showSearch = false;
          },
          calendarUuid: this.calendarUuid,
          showSearch: this.showSearch,
          fromPage: SearchFromPage.AGENDA_LIST_PAGE,
        })
      }
      .zIndex(4)
      .transition(TransitionEffect.OPACITY.animation({
        duration: 50,
        curve: Curve.FastOutSlowIn
        }))
      .backgroundColor(this.agendaTransitionUtil.showTitle ?
      $r('sys.color.background_secondary') : Color.Transparent)
      .position({ x: 0, y: 0 })
      .height('100%')
    }
  }

  @Builder
  zoomRightButton() {
    Row() {
      this.zoomImageButton()
    }
    .alignItems(VerticalAlign.Center)
    .margin({ start: LengthMetrics.vp(8) })
    .width(40)
    .height(56)
    .visibility(this.hideListButton || !this.isShowDetail ? Visibility.None : Visibility.Visible)
    .position(this.needCommerce ? undefined : // 非折叠机2:3的比例减去56的返回键宽度减去4vp的限制
      { start: LengthMetrics.vp(this.windowWidth * (this.isMiddleWindow ? 0.5 : 2 / 5) - 60) })
  }

  @Builder
  zoomImageButton() {
    ImageButton({
      buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
      image: this.hideListButton ? $r('sys.symbol.arrow_down_right_and_arrow_up_left') :
      $r('sys.symbol.arrow_up_left_and_arrow_down_right'),
      flagChanged: $dummyFlag,
      buttonBackgroundColor: this.buttonBackgroundColor,
      promptText: $r('app.string.view_switching'),
      onButtonClick: () => {
        Log.info(TAG, `AgendaList HideList ${!this.hideList}`);
        this.hideListButton = !this.hideListButton;
        animateTo({
          duration: 300,
          curve: Curve.Smooth,
        }, () => {
          this.hideList = this.hideListButton;
        });
      },
      compId: CompId.AGENDA_HIDE_LIST
    })
  }

  // 用于规避navDestination标题返回按钮无法屏蔽以及改变
  @Builder
  buildDetailTitle() {
    if (this.hideListButton) {
      Row() {
        this.zoomImageButton()
        this.pageTitle()
        if (!this.deviceShowBottomTab && !this.isFloatingWindow) {
          this.detailOperationButtons();
        }
      }
      .padding({ start: LengthMetrics.vp(16), end: LengthMetrics.vp(16 + this.titleButtonWidth) })
      .margin({ bottom: 8 })
      .constraintSize({ minHeight: this.buttonLayout.menuHeight })
      .width('100%')
      .opacity(this.windowFocused ? 1 : 0.4)
    }
  }

  /**
   * 查看日程标题
   */
  @Builder
  customTitle() {
    Row() {
      this.pageTitle()
      this.builderRightButton()
    }
    .id(CompId.CUSTOM_TITLE)
    .padding({ end: LengthMetrics.vp(16 + this.titleButtonWidth) })
    .constraintSize({ minHeight: 56 })
    .layoutWeight(1)
    .width('calc(100% - 56vp)')
    .opacity(this.windowFocused ? 1 : 0.4)
  }

  /**
   * 缩放用标题栏
   */
  @Builder
  scaleTitle() {
    Row() {
      this.builderFork()
      this.pageTitle()
      this.builderRightButton()
    }
    .padding({ end: LengthMetrics.vp(16 + this.titleButtonWidth) })
    .margin({ bottom: 8 })
    .constraintSize({ minHeight: this.buttonLayout.menuHeight })
    .width('100%')
    .opacity(this.windowFocused ? 1 : 0.4)
  }

  @Builder
  pageTitle() {
    Row() {
      Text(this.selectable ?
      $r('app.plural.events_selected_item', this.selectedAgendaCount, this.selectedAgendaCount)
        : this.calendarName ? this.calendarName :
          this.hideListButton ? $r('app.string.event_detail') : $r('app.string.all_agenda'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          20
        ))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
        .fontWeight(FontWeight.Bold)
        .margin({ start: LengthMetrics.vp(8) })
        .maxLines(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE ? 2 : 1)
        .minFontSize(14)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .wordBreak(WordBreak.BREAK_ALL)
        .id(CompId.CUSTOM_TITLE_TEXT)
        .width(this.calendarName ? this.getCalendarTitleWidth() : '100%')
    }
    .layoutWeight(1)
  }

  getCalendarTitleWidth(): string {
    // 默认数值，折叠屏折叠态，普通手机
    let calendarTitleWidth = '95%';
    if (this.needCommerce) {
      // PC不涉及最大化按钮偏移
      return '100%';
    }
    if(this.hideList) {
      // 最大化状态
      return calendarTitleWidth;
    }
    if (this.isMiddleWindow) {
      if (!this.deviceShowBottomTab) {
        // 平板竖屏, 设备按钮占位
        calendarTitleWidth = '70%';
      } else {
        // 折叠屏竖屏/横屏展开态，分栏1:1
        calendarTitleWidth = '50%';
      }
    } else {
      if (!this.deviceShowBottomTab) {
        // 平板横屏,分栏2:3
        calendarTitleWidth = '45%';
      }
    }
    return calendarTitleWidth;
  }

  @Builder
  buildMask() {
    // 新增全屏的黑色蒙板
    if (this.agendaTransitionUtil.isMaskEnabled) {
      Column()
        .width('100%')
        .height(`calc(100% + ${this.windowAvoidAreaTopRectHeight}vp)`)
        .backgroundColor('#000000')
        .opacity(this.agendaTransitionUtil.maskAlpha)
        .enabled(false)
        .focusable(false)
        .zIndex(999)
        .position({ x: 0, y: -this.windowAvoidAreaTopRectHeight })
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (!this.hideListButton && this.isHideNavBar(this.agendaTransitionUtil.showTitle, this.unusualMode)) {
          this.scaleTitle();
        }
        if (this.hideListButton) {
          this.buildDetailTitle()
        }
        if (this.isRootLoad) {
          FlexAgendaList({
            onSelectedAgendaChanged: this.onSelectedAgendaChange,
            showEventId: $showEventId,
            canEdit: $canEdit,
            canShare: $canShare,
            isShowSyncTip: isNewSyncAbleAccount(this.accountType),
            onBackToday: this.onBackToday,
            selectedAgendaCount: this.selectedAgendaCount,
            selectable: this.selectable,
            deleteSelected: this.deleteSelected,
            shareSelected: this.shareSelected,
            editSelected: this.editSelected,
            hideList: this.hideList,
            isShowDetail: this.isShowDetail,
            isMiddleWindow: this.isMiddleWindow,
            paramsDisplayStartMills: this.paramsDisplayStartMills,
            paramsDisplayEndMills: this.paramsDisplayEndMills,
            paramsEventId: this.paramsEventId,
            calendarUuid: this.calendarUuid,
            showSearchHandler: this.showSearchHandler,
            isShowHoliday: this.isShowHoliday,
          })
        }
      }
      .scale(ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) ? {} : {
        x: this.agendaTransitionUtil.scalePage,
        y: this.agendaTransitionUtil.scalePage
      })
      .padding({
        top: this.getMainPaddingTop(this.showSearch, this.agendaTransitionUtil.showTitle, this.hideListButton,
          this.unusualMode)
      })
      .accessibilityLevel(this.showSearch ? 'no-hide-descendants' : 'no')
      .width('100%')
      .height('100%')
      .onAppear(() => {
        this.isRootLoad = true;
      })
      this.buildSearch();
      this.buildMask();
    }
    .onKeyEvent((event) => {
      this.emitterKeyEvent(event);
    })
    .padding({
      top: ModeUtil.isSmallUpDownFoldMode(this.unusualMode)
        ? Math.max(this.windowAvoidAreaTopRectHeight - 8, 8)
        : this.windowAvoidAreaTopRectHeight + this.buttonTopHeight
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => {
      this.viewProxy.onHidden();
      this.emitMainPageUpdate();
    })
    .backButtonIcon(this.selectable ? this.xMarkIconModifier : this.backIconModifier)
    .onBackPressed(() => {
      if (this.selectable) {
        this.selectable = false;
        return true;
      }
      if (this.showSearch) {
        animateTo({
          duration: this.ANIMATION_DURATION,
          curve: Curve.FastOutSlowIn
        }, () => {
          this.showSearch = false;
        })
        return true;
      }
      if (this.hideList) {
        this.hideList = false;
        this.hideListButton = false;
        return true;
      }
      this.openAccountDetail();
      this.navPathStack.pop();
      return false;
    })
    .hideTitleBar(this.showSearch || this.hideListButton ||
    this.isHideNavBar(this.agendaTransitionUtil.showTitle, this.unusualMode))
    .title(this.needCommerce ? '' : this.customTitle(), { paddingStart: LengthMetrics.vp(16) })
  }

  getMainPaddingTop(showSearch: boolean, showTitle: boolean, hideListButton: boolean,
    unusualMode: UnusualMode | undefined): Length {
    // 当前逻辑,非PC因需要父子转场动效故使用nav的title栏,在搜索打开时需要隐藏title并添加上边距以使搜索栏置于原title位置
    if (!this.needCommerce && showSearch) {
      return 64;
    }
    // PC,hicar以及一镜到底动效标题不需要上边距
    if (this.needCommerce || showTitle || hideListButton || ModeUtil.isHiCarOrSmallUpDownFoldMode(unusualMode)) {
      return 0;
    }

    return 8;
  }

  emitterKeyEvent(event: KeyEvent) {
    if (event.keyCode === KeyCode.KEYCODE_CTRL_LEFT) {
      this.handleCtrlKey(event)
    } else if (event.keyCode === KeyCode.KEYCODE_F) {
      this.handleSearchKey(event)
    }
  }

  /**
   * 是否需要隐藏navBar
   * @param showTitle 是否处于一镜到底动效的展示标题,一镜到底时需要隐藏navBar并展示自定义标题用于一镜到底缩放
   * @param unusualMode 当前mode
   * @returns
   */
  isHideNavBar(showTitle: boolean, unusualMode: UnusualMode | undefined): boolean {
    return this.needCommerce || showTitle || ModeUtil.isSmallUpDownFoldMode(unusualMode);
  }

  // 处理 Ctrl 键
  handleCtrlKey(event: KeyEvent) {
    if (event.type === KeyType.Down) {
      this.keyCtrlState = true;
    } else if (event.type === KeyType.Up) {
      this.keyCtrlState = false;
    }
  }

  handleSearchKey(event: KeyEvent) {
    if (event.type === KeyType.Down) {
      this.showSearch = true;
    }
  }

  // 发送广播唤起日历账户编辑界面
  openAccountDetail() {
    if (EmptyUtils.isEmptyString(this.calendarUuid, true)) {
      return;
    }
    if (this.routerType === 'rightClick') {
      return;
    }
    const eventData: emitter.EventData = {
      data: {
        calendarUuid: this.calendarUuid,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.EVENT_ACCOUNT_DETAIL_PAGE_OPEN }, eventData);
  }

  private onSelectedAgendaChange: (event: AgendaEventInfo | undefined) =>
    void = (event: AgendaEventInfo | undefined): void => {
    let tempEvent: AgendaEventInfo | undefined = new AgendaEventInfo();
    ObjectUtils.copyEvent(event, tempEvent);
    this.event = tempEvent;
    if (event == undefined) {
      return;
    }
  };

  // 发送更新主界面事件
  private emitMainPageUpdate(): void {
    const currentNavPath: string[] = this.navPathStack.getAllPathName();
    if (EmptyUtils.isEmptyArray(currentNavPath)) {
      // 通知主界面更新数据
      let eventData: emitter.EventData = {
        data: {
          'updateData': true,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.EVENT_MAIN_PAGE_UPDATE_DATA }, eventData);
    }
  }

  isSmallWindowChecked(){
    return this.windowWidth < MIN_WINDOW_WIDTH_VP || ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode);
  }
}
