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
  AgendaTransitionUtil,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  EmptyUtils,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPathManager,
  PreferencesFiles,
  PreferencesUtil,
  ReportUtil,
  RouterModel,
  RouterName,
  SafeUtil,
  statisticEvents,
  TabType,
  ThrottleFunction,
  TIPS_HOVER_DELAY
} from '@app/common';
import { BackToTodayToolbarButton, LongPressConfig, LongPressTipsDialog, TipsPopup } from '@app/common.components';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import emitter from '@ohos.events.emitter';
import { Callback } from '@ohos.base';
import lazy { CreateAgendaRoot } from '@app/feature.agenda/src/main/ets/CreateAgenda/view/CreateAgendaRoot';
import lazy { SettingRoot, SettingRootViewModel } from '@app/feature.settings/src/main/ets/SettingRoot';
import lazy { FlexSearchAgendaRoot, FlexSearchAgendaRootViewModel } from '@app/feature.agenda/src/main/ets/components/FlexSearchAgendaRoot';
import { LengthMetrics } from '@kit.ArkUI';
import { ConfigMenu } from './ConfigMenu';
import { AgendaDetailPopup } from '@app/feature.agenda';

const TAG = 'ButtonInMainPage'

/**
 * 主页右上角操作按钮图标公共样式属性
 *
 * @param ctx this
 * @param borderColor 获焦时边框颜色变量名
 */
@Extend(Image)
function operationIcon() {
  .width($r('sys.float.ohos_id_navigation_bar_menu_icon_size'))
  .height($r('sys.float.ohos_id_navigation_bar_menu_icon_size'))
  .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(8) })
  .focusable(true)
  .draggable(false)
}

/**
 * 主界面按钮组
 *
 * @since 2022-11-29
 */
@Component
export struct ButtonInMainPage {
  @Consume navPathStack: NavPathStack;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @Provide popNavPathStack: NavPathStack = new NavPathStack();

  @Prop themeColor: string = '';

  @State moreButtonVM: MoreButtonViewModel = new MoreButtonViewModel();

  private multiSelectBackgroundColor: string = '#00000000';

  //显示搜索日程页面
  @Prop showSearch: boolean = false;

  @Prop needHideAgendaFolding: boolean = false;

  @State needShowBack: boolean = false;

  @Provide isShowSettingPage: boolean = false;
  
  // 显示新建日程的半模态
  @State isShowCreateAgenda: boolean = false;

  // 广播携带的日程信息
  @State createPageData: emitter.EventData = {};

  //显示多选日程按钮
  @StorageProp('showMultiDelete') showMultiDelete: boolean = false;

  // tab页签索引，无缓存情况下首次进入日历应用显示月视图
  @StorageLink('tabIndex') tabsIndex: number = TabType.YEAR;

  // 背景主题色
  @StorageLink('bgThemeColor') bgThemeColor: string = '';

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 右侧日程列表宽度，用于约束弹出子窗宽度不超过日程列表区域
  @StorageLink(GlobalDataKeys.AGENDA_LIST_WIDTH) agendaListWidth: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('windowFocused') windowFocused: boolean = true;

  @Provide isAgendaAniShowFinish: boolean = false;

  @Consume hideAgendaWindowMonth: boolean;

  @Consume hideAgendaWindowDay: boolean;

  @Consume needShowHideButton: boolean; // 是否需要显示详情开合按钮

  // 关闭新建日程半模态时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private showFloatButton: boolean = DeviceConfig.instance().config.showFloatButton;

  private columnColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.ohos_id_color_button_normal');

  private emitterCollector : EmitterCollector = new EmitterCollector();

  private popRadius: Resource =
    this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16');

  private readonly CAN_SHOW_BACK_WIDTH: number = 740;

  private initCreateAgenda: boolean = false;

  // 是否支持一句话创建日程
  private oneSentenceCreate: boolean = true;

  // 用于tips的参数
  @State addTips: boolean = false;
  @State moreTips: boolean = false;
  @State hideAgendaTips: boolean = false;

  // 是否展示更多菜单
  @State showMenu: boolean = false;

  private addTipsDialogController: CustomDialogController = new CustomDialogController({
    builder: LongPressTipsDialog({ tipsText: $r('app.string.peek_create_agenda'), tipsImage: $r('sys.symbol.plus') }),
    customStyle: true,
    isModal: false,
  });

  private moreTipsDialogController: CustomDialogController = new CustomDialogController({
    builder: LongPressTipsDialog({
      tipsText: $r('app.string.main_page_option_button'),
      tipsImage: $r('sys.symbol.dot_grid_2x2')
    }),
    customStyle: true,
    isModal: false,
  });

  onChanged: (showSearch: boolean) => void = () => {
  };

  showJumpToSomedayDialog: () => void = () => {
  }

  private nowSpringAction: SpringBackAction | undefined = undefined;

  private onDialogCancel: () => void = () => {
    if (this.nowSpringAction) {
      // 弹窗直接取消的情况下要回弹新建日程弹窗并将action设为空以防止出错
      this.nowSpringAction.springBack();
      this.nowSpringAction = undefined;
    }
  };

  @Styles
  focusStyles(){
    .focusable(true)
    .focusBox({
      margin: LengthMetrics.vp(6)
    })
  }

  onWindowWidthChange() {
    this.needShowBack = this.windowWidth > this.CAN_SHOW_BACK_WIDTH;
  }

  /**
   * 获取弹出子窗宽度，不超过右侧日程列表区域
   */
  getPopupWidth(): number {
    const defaultWidth = this.windowWidth > this.CAN_SHOW_BACK_WIDTH ? 400 : 350;
    if (this.agendaListWidth > 0 && this.agendaListWidth < defaultWidth) {
      return this.agendaListWidth;
    }
    return defaultWidth;
  }

  /**
   * 其他页面拉起设置半模态
   */
  onClickSettingPage() {
    this.isShowSettingPage = true;
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  // 右上角“更多”配置菜单
  @Builder
  MoreMenu() {
    ConfigMenu({
      showSearch: this.showSearch,
      onChanged: this.onChanged,
      showJumpToSomedayDialog: this.showJumpToSomedayDialog
    })
  }

  onClickAddButton() {
    Log.info(TAG, 'ButtonInMainPage onclick to CreateEvent');
    let eventData: emitter.EventData = {
      data: {
        'tabIndex': this.tabsIndex,
        'oneSentenceCreate': this.oneSentenceCreate
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    switch (this.tabsIndex) {
      case TabType.YEAR: {
        ReportUtil.reportStatisticEvent(statisticEvents.yearGoToCreateAgenda);
        break;
      }
      case TabType.MONTH: {
        ReportUtil.reportStatisticEvent(statisticEvents.monthGoToCreateAgenda);
        break;
      }
      case TabType.WEEK: {
        ReportUtil.reportStatisticEvent(statisticEvents.weekGoToCreateAgenda);
        break;
      }
      case TabType.DAY: {
        ReportUtil.reportStatisticEvent(statisticEvents.dayGoToCreateAgenda);
        break;
      }
      default:
        break;
    }
  }

  // 添加日程的按钮
  @Builder
  buildAddButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.plus'))
        .focusStyles()
        .fontColor([$r('sys.color.icon_primary')])
        .fontSize('24vp')
    }
    .id(CompId.ADD_AGENDA)
    .onClick(() => this.onClickAddButton())
    .focusable(true)
    .backgroundColor(this.columnColor)
    .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(4) })
    .width(40)
    .height(40)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .bindSheet($$this.isShowCreateAgenda, this.buildCreateAgenda(this.createPageData), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: this.isCreateAgendaPopup ? SheetType.POPUP : SheetType.CENTER,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      enableOutsideInteractive: false,
      //keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
      maskColor: this.isCreateAgendaPopup ? Color.Transparent : $r('sys.color.ohos_id_color_mask_thin'),
      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
        this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
      }),
      onWillSpringBackWhenDismiss: ((springBackAction: SpringBackAction) => {
        this.nowSpringAction = springBackAction;
        // 没有注册SpringBackAction.springBack(), 下拉半模态页面无回弹行为,将action存储以用于弹窗取消场景回弹
      }),
      onAppear: () => {
        this.isAgendaAniShowFinish = true;
        Log.info('CREATE_AGENDA_PAGE', 'isShowCreateAgenda BindSheet onAppear.');
      },
      onDisappear: () => {
        Log.info('CREATE_AGENDA_PAGE', 'isShowCreateAgenda BindSheet onDisappear.');
      }
    })
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.peek_create_agenda')))
    .accessibilityDescription(GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
    .onHover((isHover: boolean) => {
      ThrottleFunction.instance().debounce(TAG + 'addTips', () => {
        this.addTips = isHover;
      }, isHover ? TIPS_HOVER_DELAY : 0);
    })
    .bindPopup(this.addTips, {
      builder: this.PopupComp($r('app.string.peek_create_agenda')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: this.getShadow('#ccffffff'),
      mask: false,
      enableArrow: false
    })
    .gesture(
      LongPressGesture({ duration: LongPressConfig.TIPS_DIALOG_PRESS_TIME })
        .onAction((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.addTipsDialogController.open();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.addTipsDialogController.close();
          }else {
            this.onClickAddButton();
          }
        })
    )
    .onAppear(() => {
      if (this.initCreateAgenda) {
        this.isShowCreateAgenda = true;
      }
      this.initCreateAgenda = false;
    })
  }

  // 新建页面半模态
  @Builder
  buildCreateAgenda(createPageData: emitter.EventData) {
    Column() {
      CreateAgendaRoot({
        createPageData: createPageData,
        isShowCreateAgenda: $isShowCreateAgenda,
        discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
        isCreateAgendaPopup: this.isCreateAgendaPopup,
        onDialogCancel: this.onDialogCancel,
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 拉起弹窗页面
   */
  onPopupPageShow(routerData: RouterModel) {
    this.moreButtonVM.popBuilder = routerData.builderName;
    this.moreButtonVM.animated = routerData.animated ?? true;
    if (this.moreButtonVM.popBuilder === NavPathName.AGENDA_DETAIL) {
      this.moreButtonVM.param = routerData.param;
      if (this.agendaTransitionUtil.isEditPageShow) {
        this.agendaTransitionUtil.clearAniEnd();
        this.agendaTransitionUtil.onBackClicked(false, false, false);
      }
    }
    this.moreButtonVM.showPopup = true;
    this.moreTips = false;
  }

  /**
   * 关闭弹窗页面
   */
  onPopupPageClose() {
    Log.info(TAG, `Popup Page close`);
    this.moreButtonVM.showPopup = false;
    this.moreButtonVM.popBuilder = ''; // 注销页面资源
  }

  getShadow(color: string) {
    return this.isDarkMode ?
      { radius: 2, color: color, offsetX: 0, offsetY: 0, fill: true } as ShadowOptions :
      ShadowStyle.OUTER_DEFAULT_SM
  };

  @Builder
  buildPopupContent() {
    if (this.moreTips && !this.moreButtonVM.showPopup) {
      this.PopupComp($r('app.string.main_page_option_button'))
    } else {
      Column() {
        if (this.moreButtonVM.popBuilder === NavPathName.SETTING_MAIN) {
          SettingRoot({
            settingRootVM: new SettingRootViewModel(true)
          });
        } else if (this.moreButtonVM.popBuilder === NavPathName.FLEX_SEARCH_AGENDA) {
          FlexSearchAgendaRoot({
            searchAgendaRootVM: new FlexSearchAgendaRootViewModel(true)
          })
        } else if (this.moreButtonVM.popBuilder === NavPathName.AGENDA_DETAIL) {
          AgendaDetailPopup({
            eventId: this.moreButtonVM.param.id as number,
            instanceStartMills: Number(this.moreButtonVM.param?.instanceStartMills),
            instanceEndMills: Number(this.moreButtonVM.param?.instanceEndMills),
            fromType: this.moreButtonVM.param.fromType as number,
            isMessageResource: this.moreButtonVM.param.isMessageResource as boolean,
            isPopShrink: this.moreButtonVM.param.isPopShrink as boolean,
            isHoliday: this.moreButtonVM.param.isHoliday as boolean,
            holidayTitle: this.moreButtonVM.param.holidayTitle as string
          })
        }
      }
      .constraintSize({
        minHeight: 320,
        maxHeight: '90%'
      })
      .transition(TransitionEffect.asymmetric(
        TransitionEffect.opacity(1),
        TransitionEffect.opacity(0.99),
      ))
      .width(this.getPopupWidth())
    }
  }

  // 设置页面半模态
  @Builder
  buildSettingPage() {
    Column() {
      SettingRoot({ settingRootVM: new SettingRootViewModel(false, true) });
    }
    .backgroundColor(Color.Transparent)
    .height('100%')
    .width('100%')
  }

  // 更多菜单的按钮
  @Builder
  buildMoreManu() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
        .fontSize('24vp')
        .focusStyles()
        .fontColor([$r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_primary'))
    }
    .width(40)
    .height(40)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor(this.columnColor)
    .onClick(() => {
      this.showMenu = true;
      this.moreTips = false; // 关闭hover弹窗
    })
    .bindMenu(this.showMenu, this.MoreMenu(), {
      placement: Placement.BottomRight,
      showInSubWindow: false,
      aboutToDisappear: () => {
        this.showMenu = false;
      }
    })
    .bindPopup(this.moreButtonVM.showPopup || this.moreTips, {
      builder: this.buildPopupContent(),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: this.getShadow('#ffaaaaaa'),
      radius: this.moreButtonVM.showPopup ?
      this.popRadius : $r('sys.float.corner_radius_level4'),
      mask: this.moreButtonVM.popBuilder === NavPathName.AGENDA_DETAIL ? { color: Color.Transparent } : false,
      enableArrow: false,
      onStateChange: (ev) => {
        if (!ev.isVisible) {
          Log.info(TAG, `popup state change ${ev.isVisible}  ${this.moreButtonVM.showPopup}`)
          this.moreButtonVM.reset();
        }
      },
      transition: TransitionEffect.opacity(1).animation({ duration: 0 }),
      onWillDismiss: (dismiss) => {
        if (this.moreButtonVM.popBuilder !== NavPathName.AGENDA_DETAIL) {
          dismiss.dismiss();
          return true;
        }
        Log.info(TAG, ` onClick to close popup`);
        emitter.emit({ eventId: CommonInnerEvent.DETAIL_PAGE_POPUP_CLOSE });
        return false;
      }
    })
    .bindSheet($$this.isShowSettingPage, this.buildSettingPage(), {
      height: SheetSize.LARGE,
      dragBar: false,
      showClose: false,
      preferType: SheetType.CENTER,
      onAppear: () => {
        Log.debug(TAG, 'SettingsPage BindSheet onAppear.');
      },
      onDisappear: () => {
        Log.debug(TAG, 'SettingsPage BindSheet onDisappear.');
      },
      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
        this.isShowSettingPage = !this.isShowSettingPage;
      }),
      onWillSpringBackWhenDismiss: ((springBackAction: SpringBackAction) => {
        // 不主动注册springBackAction.springBack()来屏蔽下拉半模态页面的回弹行为。避免shouldDismiss中主动隐藏和回弹相互导致的闪跳
      })
    })
    .margin({ start: LengthMetrics.vp(4) })
    .id(CompId.MORE_MENU)
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.main_page_option_button')))
    .accessibilityDescription(this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE ?
      '' : GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
    .onHover((isHover: boolean) => {
      ThrottleFunction.instance().debounce(TAG + 'moreTips', () => {
        this.moreTips = !this.moreButtonVM.showPopup && isHover;
    }, isHover ? TIPS_HOVER_DELAY : 0);
    })
    .gesture(
      LongPressGesture({ duration: LongPressConfig.TIPS_DIALOG_PRESS_TIME })
        .onAction((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.moreTipsDialogController.open();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.moreTipsDialogController.close();
          } else {
            this.showMenu = true;
          }
        })
    )
  }

  // 显隐周月视图日程详情的按钮
  @Builder
  buildHideAgenda() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.thumbnails'))
        .fontSize('24vp')
        .focusStyles()
        .fontColor([(this.tabsIndex === TabType.MONTH ? this.hideAgendaWindowMonth : this.hideAgendaWindowDay) ?
          this.themeColor : $r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_primary'))
    }
    .width(40)
    .height(40)
    .margin({ start: LengthMetrics.vp(8) })
    .borderRadius($r('sys.float.corner_radius_level4'))
    .backgroundColor((this.tabsIndex === TabType.MONTH ? this.hideAgendaWindowMonth : this.hideAgendaWindowDay) ?
      this.bgThemeColor : this.columnColor)
    .hoverEffect(HoverEffect.Highlight)
    .onClick(() => {
      ThrottleFunction.instance().throttle(TAG + 'hideAgenda', () => {
        if (this.tabsIndex === TabType.MONTH) {
          this.hideAgendaWindowMonth = !this.hideAgendaWindowMonth;
          PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT,
            TabType.MONTH + GlobalDataKeys.TAB_INDEX, this.hideAgendaWindowMonth);
        } else if (this.tabsIndex === TabType.DAY) {
          this.hideAgendaWindowDay = !this.hideAgendaWindowDay;
          PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT,
            TabType.DAY + GlobalDataKeys.TAB_INDEX, this.hideAgendaWindowDay);
        }
        Log.info(TAG, `onClick hideAgenda, ${this.hideAgendaWindowMonth} ${this.hideAgendaWindowDay}`);
      })
    })
    .id(CompId.HIDE_AGENDA)
    .visibility(this.tabsIndex === TabType.MONTH || this.tabsIndex === TabType.DAY ?
    Visibility.Visible : Visibility.None)
    .accessibilityText($r('app.string.view_switching'))
    .onHover((isHover: boolean) => {
      ThrottleFunction.instance().debounce(TAG + 'hideAgendaTips', () => {
        this.hideAgendaTips = isHover;
      }, isHover ? TIPS_HOVER_DELAY : 0);
    })
    .bindPopup(this.hideAgendaTips, {
      builder: this.PopupComp($r('app.string.view_switching')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: this.getShadow('#ccffffff'),
      mask: false,
      enableArrow: false
    })
  }

  aboutToAppear(): void {
    this.onClickSettingHandler = () => {
      this.onClickSettingPage();
    }
    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_SETTING_PAGE }, this.onClickSettingHandler);

    this.onShowPopUpHandler = (eventData: emitter.EventData) => {
      if (EmptyUtils.isUndefinedOrNull(eventData?.data)) {
        Log.error(TAG, 'No Valid Show Popup ')
        return;
      }
      const routerData: RouterModel = eventData?.data as RouterModel;
      this.onPopupPageShow(routerData);
    }
    this.emitterCollector.on({ eventId: CommonInnerEvent.MORE_PAGE_TO_POPUP }, this.onShowPopUpHandler);


    this.onClosePopUpHandler = () => {
      this.onPopupPageClose();
    }
    this.emitterCollector.on({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE }, this.onClosePopUpHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.onCloseShowSettingPage);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.onCloseShowSettingPage);

    this.registerCreateAgendaEmitter();
    this.needShowBack = this.windowWidth > this.CAN_SHOW_BACK_WIDTH;
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  build() {
    Row() {
      if (this.tabsIndex === TabType.AGENDA && this.showMultiDelete) {
        Button({ type: ButtonType.Normal }) {
          SymbolGlyph($r('sys.symbol.checkmark_square'))
            .fontSize($r('sys.float.ohos_id_navigation_bar_menu_icon_size'))
            .margin({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(8) })
            .focusable(true)
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
        }
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.multiple_choice_agenda_button')))
        .width(48)
        .height(48)
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor(this.multiSelectBackgroundColor)
        .onClick(() => {
          Log.info(TAG, " multi select  icon onclick");
          const param: Record<string, number> = {};
          ReportUtil.reportStatisticEvent(statisticEvents.search);
          this.navPathStack.pushPathByName(NavPathName.MULTI_DELETE, param);
        })
      }

      if (this.showFloatButton) {
        BackToTodayToolbarButton();
      }

      if (!this.needHideAgendaFolding && this.needShowHideButton) {
        this.buildHideAgenda();
      }

      this.buildAddButton();
      
      this.buildMoreManu();
      }    .renderGroup(true)
    .opacity(!this.windowFocused && this.needCommerce ? 0.4 : 1)
    .id(CompId.BUTTON_IN_MAIN_PAGE)
  }

  // 点击新建日程按钮
  private onClickCreateAgenda = (eventData: emitter.EventData) => {
  };

  // 退出新建日程模态的响应事件
  private onExitCreateAgendaPage = (eventData: emitter.EventData) => {
    this.isShowCreateAgenda = false;
  };

  private onClickSettingHandler: Callback<emitter.EventData> = () => {
  };

  private onShowPopUpHandler: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
  };

  private onClosePopUpHandler: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
  };

  //卡片进入详情界面，需要关闭设置半模态
  private onCloseShowSettingPage: Callback<emitter.EventData> = (eventData: emitter.EventData) => {
    this.isShowSettingPage = false;
  };

  /**
   * 注册内部广播监听新建页面半模态开关
   */
  private registerCreateAgendaEmitter() {
    this.registerCreateAgendaOn();
    this.registerCreateAgendaOff();
  }

  /**
   * 注册内部广播监听新建页面半模态打开动作
   */
  private registerCreateAgendaOn() {
    // 处理点击新建日程的事件
    let onClickCreateAgenda = (eventData: emitter.EventData) => {
      Log.info(TAG, 'onClick to Create Agenda');
      if (!eventData.data) {
        Log.info(TAG, 'No Valid eventData!');
      }
      if (eventData.data?.isSubAbility) {
        Log.info(TAG, 'Open In SubAbility');
        return;
      }
      this.createPageData = eventData;
      this.isShowCreateAgenda = true;
    };

    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, onClickCreateAgenda);
  }

  /**
   * 注册内部广播监听新建页面半模态关闭动作
   */
  private registerCreateAgendaOff() {
    // 点击新建日程页面的确认或取消按钮，退出新建日程
    this.onExitCreateAgendaPage = (eventData: emitter.EventData) => {
      Log.info(TAG, 'emitter to close Create Agenda Sheet');
      this.isShowCreateAgenda = false;
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_DISMISS_CREATE_AGENDA }, this.onExitCreateAgendaPage);
  }
}

@Observed
export class MoreButtonViewModel {
  // 显示子页面弹窗标志
  public showPopup: boolean = false;
  // 显示子页面弹窗
  public popBuilder: string = '';
  public param: Record<string, string | number | boolean> = {};
  public animated: boolean = true;


  // 清空所有的morePop相关的根路由
  reset() {
    Log.info(TAG, `popup state reset ${this.showPopup}`)
    this.showPopup = false;
    this.popBuilder = '';
    this.param = {};
    this.animated = true;
    NavPathManager.getInstance().discard(RouterName.SETTING_HAP);
  }
}