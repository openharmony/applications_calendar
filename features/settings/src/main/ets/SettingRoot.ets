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
  behaviorEvents,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  GlobalThis,
  NavPageBuilderFactory,
  ReportHiEventParams,
  ReportUtil,
  ViewProxy,
  EmptyUtils,
  RouterName,
  NavPathManager,
  FontSizeScaleUtils,
  BigFontSize,
  Log,
  GlobalDataKeys,
  MIN_WINDOW_WIDTH_VP,
  EmitterCollector,
} from '@app/common';
import { IsSettingData, SettingDataSources } from '../ets/groupConfig/declare';
import lazy { Group } from './group/Group';
import { SettingData } from './groupConfig/index';
import { StartOfWeek } from './dialogs/StartOfWeek';
import { DefaultRemindTime } from './dialogs/DefaultRemindTime';
import { AllDayEventsDefaultRemindTime } from './dialogs/AllDayEventsDefaultRemindTime';
import settingKeys from './settingKeys';
import { NaviTitleBar } from './NavTitleBar';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { Weekends } from './dialogs/Weekends';
import { SubscriptionCalendar } from './dialogs/SubscriptionCalendar';
import emitter from '@ohos.events.emitter';
import { LengthMetrics, window } from '@kit.ArkUI';

const TAG: string = 'SettingRoot';

/**
 * 设置首页
 *
 * @since 2022-06-25
 */

@Builder
function harBuilder(value: object) {
  SettingRoot({ settingRootVM: new SettingRootViewModel(false, true) });
}

const builderName = NavPathName.SETTING_MAIN;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct SettingRoot {
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @Provide navPathStackInPop: NavPathStack = new NavPathStack();

  @Consume isShowSettingPage: boolean;

  // 一周开始日
  @StorageLink('startOfWeek') startOfWeek: number = 0;

  // 周末
  @StorageLink('weekends') weekends: number[] = [];

  // 默认提醒时间
  @StorageLink('defaultRemindTime') defaultRemindTime: number = 10;

  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') allDayEventsDefaultRemindTime: number = 0;

  // 其它历法
  @StorageLink('subscriptionCalendar') subscriptionCalendar: number = -1;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('windowStatusType') windowState: number = window.WindowStatusType.FULL_SCREEN;

  @StorageLink('language') language: string = '';

  // 传入弹框的自定义参数
  @State settingKey: string = '';

  private settingData: IsSettingData[] = [];

  @State settingDataSources: SettingDataSources = new SettingDataSources([]);

  // 本组件的视图模型
  @ObjectLink settingRootVM: SettingRootViewModel;

  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 是否需要滚动条-PC|Pad以弹窗显示，默认带滚动条，不需要再显示滚动条
  private needScrollBar: boolean = DeviceConfig.instance().config.isSettingRootNeedScrollBar;

  private columnColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.ohos_id_color_button_normal');

  // 弹框控制器 —— 目前只能在属性中定义时进行初始化，不能动态初始化
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: SettingDialog({
      settingKey: this.settingKey
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  scroller: Scroller = new Scroller();

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  @State private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  @State isRootLoad: boolean = false;

  private titleHeight: number = 56; // 标题区高度

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
    this.initButtonTopHeight();
  }

  private initButtonTopHeight() {
    // 在大屏且为子窗，上边距设置为8
    if (this.settingRootVM.isInPop && !this.inSmallWindow) {
      this.buttonTopHeight = 8;
    }
  }

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.dialogController?.close();
  }

  private closeDialog: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.dialogController?.close();
  }

  /**
   * 打开弹框
   */
  openDialog(settingKey: string) {
    this.settingKey = settingKey;
    this.dialogController?.open();
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  async aboutToAppear() {
    Log.info(TAG, `windowHeight: ${this.windowHeightInVp}}`);
    this.settingData = await SettingData.getSettingData();
    this.settingData = await SettingData.checkLockTimeZoneSettingSupport(this.settingData);
    this.settingDataSources.setData(this.settingData);
    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closeDialog);
    let weekends: number[] = [];
    this.weekends.forEach(item => weekends.push(item));
    let params: ReportHiEventParams = {
      SETTINGS_SUBSCRIPTION_CALENDAR: this.subscriptionCalendar,
      SETTINGS_START_OF_WEEK: this.startOfWeek,
      SETTINGS_WEEKEND: weekends,
      SETTINGS_DEFAULT_REMINDER_TIME: this.defaultRemindTime,
      SETTINGS_ALL_DAY_REMINDER_TIME: this.allDayEventsDefaultRemindTime
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.SettingStatus, params);
    if (this.settingRootVM.isInPop || this.settingRootVM.isBindSheet) {
      Log.info(TAG, 'SettingRoot try to create Router');
      NavPathManager.getInstance().createRouter(RouterName.SETTING_HAP, this.navPathStackInPop);
    }
    const timeId = setTimeout(() => { // 跳转页面后尝试获焦
      focusControl.requestFocus(CompId.SETTINGS_SCROLL);
      clearTimeout(timeId);
    }, 500);
    this.initButtonTopHeight();
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
    if (this.settingRootVM.isInPop || this.settingRootVM.isBindSheet) {
      Log.info(TAG, 'SettingRoot try to discard Router');
      NavPathManager.getInstance().discard(RouterName.SETTING_HAP);
    }
    this.dialogController = null;
  }

  @Builder
  buildSettingList() {
    Column() {
      List({ scroller: this.scroller }) {
        ListItem().height(this.titleHeight + 8)
        LazyForEach(this.settingDataSources, (data: IsSettingData, index: number) => {
          ListItemGroup() {
            if (!data.hide) {
              ListItem() {
                Group({
                  isInPop: this.settingRootVM.isInPop,
                  isBindSheet: this.settingRootVM.isBindSheet,
                  title: data.groupName,
                  items: data.items,
                  compId: data.compId ? data.compId : '',
                  index: index,
                  openDialog: (settingKey: string) => {
                    this.openDialog(settingKey)
                  }
                })
              }
            }
          }
          .id(data.compId)
        }, (data: IsSettingData, index: number) => `${data.groupName}_${data.compId}_${data.hide}_index`)

        // 底部占位，使滑到底部才有边距
        if (!this.settingRootVM.isInPop || this.windowState === window.WindowStatusType.FLOATING) {
          ListItem() {
            Row().size({
              width: '100%',
              height: this.inSmallWindow && this.windowAvoidAreaNavigationRectHeight !== 0 ?
              this.windowAvoidAreaNavigationRectHeight : 16
            })
          }
        }
      }
      .id(CompId.SETTINGS_SCROLL)
      .scrollBar(this.needScrollBar ? BarState.Auto : BarState.Off) // 需要根据产品形态设置滚动条状态
//      .scrollBarMargin({
//        start: LengthMetrics.vp(this.titleHeight + 8),
//        end: LengthMetrics.vp(this.inSmallWindow && this.windowAvoidAreaNavigationRectHeight !== 0 ?
//          this.windowAvoidAreaNavigationRectHeight - 8 : 8),
//      })
      .flexGrow(1)
      .backgroundColor(Color.Transparent)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .constraintSize({
        minHeight: '100%'
      })
      .padding({
        left: this.needScrollBar ? $r('sys.float.padding_level8') : 0,
        right: this.needScrollBar ? $r('sys.float.padding_level8') : 0
      })
      .align(Alignment.Top)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
  }

  @Builder
  buildTitleBar() {
    NaviTitleBar({
      title: $r('app.string.menu_preferences'),
      navPath: NavPathName.SETTING_MAIN,
      onClosePage: () => {
        this.isShowSettingPage = false;
      }
    })
      .width('100%')
      .height(this.titleHeight)
      .margin({ top: 8 })
  }

  @Builder
  buildSubWinBar() {
    Row() {
      Text($r('app.string.menu_preferences'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD,
          20
        ))
        .minFontSize(10)
        .fontWeight(FontWeight.Bold)
        .padding({ right: 16 })
      Row() {
        Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize('18vp')
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
        }
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.cancel_dialog_button')))
        .width(40)
        .height(40)
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor(this.columnColor)
        .onClick(() => {
          Log.info(TAG, 'Settings Pag Try To Close Popup Bind By More Button!');
          emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
        })
      }
      .margin({ left: 16 })
      .height(56)
    }
    .height(56)
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildScrollBar() {
    Row() {
      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
    }
    .padding({ top: this.titleHeight + 12, bottom: $r('sys.float.padding_level2') })
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  buildContent() {
    GridRow({
      columns: {
        xs: 12,
        sm: 48,
        md: 48,
        lg: this.settingRootVM.isInPop ? 48 : 12
      },
    }) {
      GridCol({
        span: {
          xs: 10,
          sm: 44,
          md: 44,
          lg: this.settingRootVM.isInPop ? 44 : 8
        },
        offset: {
          xs: 0,
          sm: 2,
          md: 2,
          lg: 2
        }
      }) {
        this.buildSettingList()
      }

      GridCol({
        span: {
          xs: 2,
          sm: 2,
          md: 2,
          lg: 2
        }
      }) {
        this.buildScrollBar();
      }
    }
    .margin({ top: this.settingRootVM.isInPop ? 0 : $r('sys.float.padding_level4') })
    .layoutWeight(1)
  }

  @Builder
  buildSubWinRoot() {
    Navigation(this.navPathStackInPop) {
      Column() {
        if (this.isRootLoad) {
          this.buildSubWinBar()
          this.buildContent()
        }
      }
      .onAppear(() => {
        this.isRootLoad = true;
      })
      .margin({ bottom: 16 })
    }
    .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') : $r('app.color.color_privacy_background'))
    .hideTitleBar(true)
    .navDestination(this.navRoute)
    .height(this.windowHeightInVp < 660 ? this.windowHeightInVp - 100 : '560vp')
    .padding({ top: 8 })
  }

  @Builder
  buildHalfContent() {
    Column() {
      Row() {
        this.buildSettingList()
      }
      .layoutWeight(1)
      .padding({
        left: this.needScrollBar ? 0 : $r('sys.float.padding_level8'),
        right: this.needScrollBar ? 0 : $r('sys.float.padding_level8'),
      })
    }
    .padding({ top: 8 })
    .backgroundColor(Color.Transparent)
  }

  @Builder
  buildNormalRoot() {
    Navigation(this.navPathStackInPop) {
      if (this.isRootLoad) {
        Column() {
          this.buildTitleBar()
          this.buildHalfContent()
        }
      }
    }
    .onAppear(() => {
      this.isRootLoad = true;
    })
    .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') : $r('app.color.color_privacy_background'))
    .hideTitleBar(true)
    .navDestination(this.navRoute)
    .padding({ top: this.buttonTopHeight })
  }

  build() {
    if (this.settingRootVM.isInPop) {
      this.buildSubWinRoot()
    } else {
      this.buildNormalRoot()
    }
  }

}

@CustomDialog
struct SettingDialog {
  private settingKey: string = '';

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  controller: CustomDialogController = new CustomDialogController({
    builder: SettingDialog({
      settingKey: this.settingKey
    })
  });

  // 弹窗高度规格Map
  private heightOptionsMap: Map<string, number> = new Map<string, number>([
    [settingKeys.startOfWeek, 520],
    [settingKeys.defaultRemindTime, 664],
    [settingKeys.allDayEventsDefaultRemindTime, 424],
    [settingKeys.subscriptionCalendar, 280],
    [settingKeys.weekends, 520]
  ]);

  build() {
    Column() {
      if (this.settingKey === settingKeys.startOfWeek) {
        StartOfWeek({
          cancel: () => {
            this.controller.close();
          }
        })
      } else if (this.settingKey === settingKeys.defaultRemindTime) {
        DefaultRemindTime({
          cancel: () => {
            this.controller.close();
          }
        })
      } else if (this.settingKey === settingKeys.allDayEventsDefaultRemindTime) {
        AllDayEventsDefaultRemindTime({
          cancel: () => {
            this.controller.close();
          }
        })
      } else if (this.settingKey === settingKeys.subscriptionCalendar) {
        SubscriptionCalendar({
          cancel: () => {
            this.controller.close();
          }
        })
      } else if (this.settingKey === settingKeys.weekends) {
        Weekends({
          cancel: () => {
            this.controller.close();
          }
        })
      }
    }
    .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .backgroundBlurStyle(this.settingKey === settingKeys.weekends ? BlurStyle.COMPONENT_ULTRA_THICK : undefined)
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16'))
    .height('90%')
    .constraintSize({
      minWidth: 300,
      maxWidth: 400,
      maxHeight: this.heightOptionsMap.get(this.settingKey)
    });
  }
}

@Observed
export class SettingRootViewModel {
  // 本组件是否存在与弹窗内
  public isInPop: boolean = false;
  public isBindSheet: boolean = false;

  reset() {
    this.isInPop = false;
    this.isBindSheet = false;
  }

  constructor(isInPop?: boolean, isBindSheet?: boolean) {
    if (!EmptyUtils.isUndefinedOrNull(isInPop) || !EmptyUtils.isUndefinedOrNull(isBindSheet)) {
      this.isInPop = isInPop as boolean;
      this.isBindSheet = isBindSheet as boolean;
    }
  }
}

// 子窗跳转参数
export interface PopPageParam {
  isInPop: boolean;
  isBindSheet: boolean;
}