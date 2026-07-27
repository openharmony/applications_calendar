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
  behaviorEvents,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  FeatureType,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPathName,
  PreferencesFiles,
  PreferencesUtil,
  RouterModel,
  RouterName,
  ThrottleFunction,
  TIPS_HOVER_DELAY
} from '@app/common';
import { LongPressConfig, LongPressTipsDialog, TipsPopup } from '@app/common.components';
import { KeyboardType, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import emitter from '@ohos.events.emitter';
import lazy { accessibility } from '@kit.AccessibilityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { SideBar } from '@app/feature.sidebar/src/main/ets/SideBar';

const TAG: string = 'CalendarSideBarContainer';

export enum CommonWidth {
  WIN_WIDTH = 1143,
  SIDEBAR_HIDDEN_DATE_LEFT = 48, //侧边栏隐藏时日期标题偏移量
  SIDEBAR_BOTTOM_HEIGHT = 40, //侧边栏按钮高宽
  SIDEBAR_BOTTOM_HEIGHT_BORDER = 8, //侧边栏按钮边框
  SIDEBAR_BOTTOM_HEIGHT_INAGE = 24, //侧边栏按钮内高宽
  DEFAULT_BLANK_HEIGHT_PHONE = 48, //默认侧边栏上方留空高度
}

export const SIDEBAR_VISIBLE_TAG = 'sidebar_visible'; // 用于侧边栏节点下树防抖操作TAG

export const SIDE_BAR_SHOW_USER = 'side_bar_show_user'; // 用户记录用户手动展开收缩侧边栏的SPkey

@Component
export struct CalendarSideBarContainer {
  @Consume isShowLeftBar: boolean; // 动态判断是否要显示侧边栏

  @Consume sidebarVisible: boolean;

  @Consume maskPosX: number;

  @Link showSearch: boolean;

  @Prop displayDate: number;

  //继承用
  @Prop statusBarHeight: number = 0; //上方需要留空的高度

  @Prop hideMenu: boolean = false;

  @Consume @Watch('onSidebarOverlayStateChange') sideBarOverlay: boolean;

  @BuilderParam closer: () => void; // 内容物

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  private readonly KEY_ENTER_DELAY: number = 100; //键盘操作间隔

  private readonly DELAY: number = 300;

  private curShowState: boolean = true; // 按钮控制,用来记录触发按钮的状态变更,窗口拉伸不会改变此状态

  @StorageProp(GlobalDataKeys.SIDEBAR_WIDTH) sidebarWidth: number = DeviceConfig.instance().config.deviceLayout.sidebarWidth;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @Consume keyCtrlState: boolean; // Ctrl 键的状态

  @State sidebarBtTips: boolean = false;

  @StorageLink('windowFocused') windowFocused: boolean = true;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink(GlobalDataKeys.LAST_OPEN_SIDEBAR) lastOpenSidebar: boolean = true;
  
  @State showGuidePopup: boolean = false;
  private emitterCollector : EmitterCollector = new EmitterCollector();
  
  private openTipsDialogController: CustomDialogController = new CustomDialogController({    builder: LongPressTipsDialog({ tipsText: $r('app.string.sidebar'), tipsImage: $r('sys.symbol.open_sidebar') }),
    customStyle: true,
    isModal: false,
  });

  private closeTipsDialogController: CustomDialogController = new CustomDialogController({
    builder: LongPressTipsDialog({ tipsText: $r('app.string.sidebar'), tipsImage: $r('sys.symbol.close_sidebar') }),
    customStyle: true,
    isModal: false,
  });

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    if (this.sideBarOverlay) {
      this.isShowLeftBar = false;
    }
  };

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  @Builder
  buildButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph(this.isShowLeftBar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
        .fontSize(FontSizeScaleUtils.fontSizeNumToVp(CommonWidth.SIDEBAR_BOTTOM_HEIGHT_INAGE))
        .fontColor([$r('sys.color.icon_primary')])
        .opacity(0.9)
        .focusable(true)
    }
    .accessibilityText(this.getBarAccessibilityText())
    .accessibilityDescription(this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE ?
      '' : GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
    .onClick(() => {
      ThrottleFunction.instance().throttle(TAG, (): void => {
        this.showGuidePopup = false;
        this.onSideBarChange();
        this.lastOpenSidebar = this.isShowLeftBar;
        PreferencesUtil.putBooleanValue(PreferencesFiles.DEFAULT,
          GlobalDataKeys.LAST_OPEN_SIDEBAR, this.isShowLeftBar);
      }, this.DELAY);
    })
    .position({
      start: this.needCommerce ?
      LengthMetrics.vp((this.isShowLeftBar ? this.sidebarWidth - CommonWidth.SIDEBAR_BOTTOM_HEIGHT - 16 : 16)) :
      LengthMetrics.resource($r('sys.float.padding_level8')),
      top: LengthMetrics.vp(this.buttonTopHeight + this.statusBarHeight)
    })
    .visibility(this.hideMenu ? Visibility.None : Visibility.Visible)
    .zIndex(2)
    .focusable(true)
    .backgroundColor(this.needCommerce ? Color.Transparent :
    $r('sys.color.ohos_id_color_button_normal'))
    .width(CommonWidth.SIDEBAR_BOTTOM_HEIGHT)
    .height(CommonWidth.SIDEBAR_BOTTOM_HEIGHT)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .hitTestBehavior(HitTestMode.Block)
    .renderGroup(true)
    .id(CompId.EXPAND_AND_COLLECTION_SIDEBAR_BUTTON)
    .onHover((isHover: boolean) => {
      if (this.showGuidePopup) {
        return;
      }
      ThrottleFunction.instance().debounce(TAG + 'sidebarBtTips', () => {
        this.sidebarBtTips = isHover;
      }, isHover ? TIPS_HOVER_DELAY : 0);
    })
    .bindPopup(this.sidebarBtTips || this.showGuidePopup, {
      builder: this.PopupComp(this.getPopupCompText(this.isShowLeftBar)),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: this.showGuidePopup,
      onStateChange: (e) => {
        if (!e.isVisible) {
          this.showGuidePopup = false;
        }
      }
    })
    .gesture(
      LongPressGesture({ duration: LongPressConfig.TIPS_DIALOG_PRESS_TIME })
        .onAction((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.isShowLeftBar ? this.closeTipsDialogController.open() : this.openTipsDialogController.open();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.isShowLeftBar ? this.closeTipsDialogController.close() : this.openTipsDialogController.close();
          }else {
            this.onSideBarChange();
          }
        })
    )
    .opacity(!this.windowFocused && this.needCommerce ? 0.4 : 1)
  }

  private getBarAccessibilityText(): string {
    return this.isShowLeftBar ? GlobalThis.getResourceStr($r('app.string.accessibility_close_sidebar')) : GlobalThis.getResourceStr($r('app.string.accessibility_open_sidebar'));
  }

  build() {
    Column() {
      this.buildButton();

      SideBarContainer(this.sideBarOverlay ? SideBarContainerType.Overlay : SideBarContainerType.Embed) {
        SideBar({
          displayDate: this.displayDate,
          blankHeight: this.buttonTopHeight + CommonWidth.DEFAULT_BLANK_HEIGHT_PHONE + this.statusBarHeight,
        })

        this.closer();
      }
      .id(CompId.CALENDAR_SIDEBAR_CONTAINER)
      .showControlButton(false)
      .sideBarWidth(this.sidebarWidth)
      .minSideBarWidth(this.sidebarWidth)
      .maxSideBarWidth(this.sidebarWidth)
      .minContentWidth(0)
      .focusable(true)
      .focusOnTouch(this.needCommerce)
      .onTouch((event?: TouchEvent) => {
        if (!event) {
          return;
        }
        if (event.type === TouchType.Down) {
          focusControl.requestFocus(CompId.SLIDE_TAB_BAR);
        }
      })
      .showSideBar(this.isShowLeftBar)
      .onChange((isSidebarOpened: boolean) => {
        this.isShowLeftBar = isSidebarOpened;
        Log.info(TAG, `isShowLeftBar change ${this.isShowLeftBar}`);
        let eventInfo: accessibility.EventInfo = ({
          type: 'requestFocusForAccessibility',
          bundleName: 'com.openharmony.calendar',
          triggerAction: 'common',
          customId: CompId.EXPAND_AND_COLLECTION_SIDEBAR_BUTTON
        });
        accessibility.sendAccessibilityEvent(eventInfo);
      })
      .divider({
        strokeWidth: 0,
      })
      .zIndex(1)
      .onBlur(() => {
        Log.info(TAG, 'SideBar on blur');
        this.keyCtrlState = false;
      })
      .onKeyEvent((event: KeyEvent) => { // 全局按键触发事件
        this.onKeyEventEmitter(event);
      })
    }
    .scale({ x: this.agendaTransitionUtil.scalePage, y: this.agendaTransitionUtil.scalePage })
    .accessibilityLevel(this.showSearch ? 'no-hide-descendants' : 'no')
  }

  onSidebarOverlayStateChange() {
    if (this.sideBarOverlay) { //嵌入式转为悬浮态,默认关闭侧边栏
      ThrottleFunction.instance().debounce(SIDEBAR_VISIBLE_TAG, () => {
        this.sidebarVisible = false;
      }, 400);
      this.isShowLeftBar = false;
    } else if (!this.sideBarOverlay && (this.curShowState || this.lastOpenSidebar)) {
      //由嵌入态转为悬浮态时如果侧边栏展开,且悬浮态未操作侧边栏,则再次转为嵌入态时需要自动展开,补充未操作侧边栏按钮时默认始终打开
      ThrottleFunction.instance().debounce(SIDEBAR_VISIBLE_TAG, () => {
        this.sidebarVisible = true;
      }, 0);
      this.isShowLeftBar = true;
    }
    Log.info(TAG, `isShowLeftBar areaChange ${this.isShowLeftBar}`);
  }

  aboutToAppear() {
    //初始化参数
    this.curShowState = !this.sideBarOverlay;

    // 侧边栏是悬浮态说明设备是手机，手机上点击卡片进入月视图关闭账户侧边栏
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
  }

  getPopupCompText(isShowLeftBar: boolean): ResourceStr {
    if (this.showGuidePopup && !isShowLeftBar) {
      return $r('app.string.popup_text_schedule_online');
    }
    return isShowLeftBar ? $r('app.string.accessibility_close_sidebar') : $r('app.string.accessibility_open_sidebar');
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  changeShowLeftButtonByAnimate(isShow: boolean): void {
    ThrottleFunction.instance().debounce(SIDEBAR_VISIBLE_TAG, () => {
      this.sidebarVisible = true;
    }, 0);
    animateToImmediately({
      duration: 300,
      curve: Curve.Smooth,
      onFinish: () => {
        this.curShowState = isShow;
        ThrottleFunction.instance().debounce(SIDEBAR_VISIBLE_TAG, () => {
          this.sidebarVisible = isShow;
        }, 400);
      }
    }, () => {
      this.isShowLeftBar = isShow;
      this.maskPosX = isShow ? this.sidebarWidth : 0;
      PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT, SIDE_BAR_SHOW_USER, isShow);
      Log.info(TAG, `isShowLeftBar button click ${this.isShowLeftBar}`);
    })
  }

  // 限流创建按键事件
  broadcastKeyEvent(eventId: number) {
    ThrottleFunction.instance().throttle(TAG + 'keyEvent',
      (): void => {
        emitter.emit({ eventId: eventId });
        Log.info(TAG, `send emitter ` + eventId);
      },
      this.KEY_ENTER_DELAY);
  }

  // 处理 Enter 健
  handleEnterKey(event: KeyEvent) {
    let params: ReportHiEventParams = {}
    if (event.type === KeyType.Down) {
      params.TYPE = KeyboardType.ENTER;
      this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_ENTER);
      ReportUtil.reportBehaviorEvent(behaviorEvents.keyboardEvents, params);
    }
  }

  // 处理方向键
  handleDPadKey(event: KeyEvent) {
    if (event.type !== KeyType.Down) {
      return;
    }
    let params: ReportHiEventParams = {}
    if (event.keyCode === KeyCode.KEYCODE_DPAD_UP || event.keyCode === KeyCode.KEYCODE_DPAD_LEFT) {
      params.TYPE = KeyboardType.UP_AND_LEFT;
      this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_UP_OR_LEFT);
    } else if (event.keyCode === KeyCode.KEYCODE_DPAD_DOWN || event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
      params.TYPE = KeyboardType.DOWN_AND_RIGHT;
      this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_DOWN_OR_RIGHT);
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.keyboardEvents, params);
  }

  // 处理删除键
  handleDeleteKey(event: KeyEvent) {
    if (event.type !== KeyType.Down) {
      return;
    }
    let params: ReportHiEventParams = {}
    params.TYPE = KeyboardType.DELETE;
    this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_DEL);
    ReportUtil.reportBehaviorEvent(behaviorEvents.keyboardEvents, params);
  }

  // 处理复制键
  handleCopyKey(event: KeyEvent) {
    if (event.type !== KeyType.Down) {
      return;
    }
    let params: ReportHiEventParams = {}
    params.TYPE = KeyboardType.COPY;
    this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_COPY);
    ReportUtil.reportBehaviorEvent(behaviorEvents.keyboardEvents, params);
  }

  // 处理粘贴键
  handlePasteKey(event: KeyEvent) {
    if (event.type !== KeyType.Down) {
      return;
    }
    let params: ReportHiEventParams = {};
    params.TYPE = KeyboardType.PASTE;
    this.broadcastKeyEvent(CommonInnerEvent.BUTTON_KEY_PASTE);
    ReportUtil.reportBehaviorEvent(behaviorEvents.keyboardEvents, params);
  }

  // 处理 Ctrl 键
  handleCtrlKey(event: KeyEvent) {
    if (event.type === KeyType.Down) {
      this.keyCtrlState = true;
    } else if (event.type === KeyType.Up) {
      this.keyCtrlState = false;
    }
  }

  // 处理F键
  handleSearchKey(event: KeyEvent) {
    if (event.type === KeyType.Down) {
      const param: Record<string, number> = {};
      const routerData: RouterModel = {
        builderName: NavPathName.FLEX_SEARCH_AGENDA,
        routerName: RouterName.ENTRY_HAP,
        param: param
      }
      if (DeviceConfig.instance().config.showMorePagePopUp) {
        const eventData: emitter.EventData = {
          data: routerData
        };
        emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_TO_POPUP }, eventData);
        return;
      }
      this.showSearch = true;
    }
  }

  onKeyEventEmitter(event: KeyEvent) {
    switch (event.keyCode) {
      case KeyCode.KEYCODE_ENTER: {
        this.handleEnterKey(event);
        break;
      }
      case KeyCode.KEYCODE_FORWARD_DEL: {
        this.handleDeleteKey(event);
        break;
      }
      case KeyCode.KEYCODE_DPAD_DOWN: // DPAD 一并处理
      case KeyCode.KEYCODE_DPAD_RIGHT:
      case KeyCode.KEYCODE_DPAD_LEFT:
      case KeyCode.KEYCODE_DPAD_UP: {
        this.handleDPadKey(event);
        break; // 方向键在这里一起break
      }
      case KeyCode.KEYCODE_CTRL_LEFT: {
        this.handleCtrlKey(event);
        break;
      }
      case KeyCode.KEYCODE_D: {
        if (this.keyCtrlState) {
          this.handleDeleteKey(event);
        }
        break;
      }

      case KeyCode.KEYCODE_C: {
        if (this.keyCtrlState) {
          this.handleCopyKey(event);
        }
        break;
      }

      case KeyCode.KEYCODE_V: {
        if (this.keyCtrlState) {
          this.handlePasteKey(event);
        }
        break;
      }

      case KeyCode.KEYCODE_F: {
        if (this.keyCtrlState) {
          this.handleSearchKey(event);
        }
        break;
      }
      default:
        break;
    }
  }

  private onSideBarChange = () => { //侧边栏显隐动画及按钮控制
    this.changeShowLeftButtonByAnimate(!this.isShowLeftBar);
    let params: ReportHiEventParams = {
      IS_SHOW: this.isShowLeftBar ? 1 : 0
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.clickLeftDrawer, params);
  };
}
