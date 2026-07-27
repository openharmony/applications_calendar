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
  BigFontSize,
  CalendarContract,
  CommonInnerEvent,
  CompId,
  CreateAgendaSheetFromPage,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  FontSizeScaleUtils,
  GlobalDataKeys,
  Log,
  MILLS_PER_HOUR,
  MIN_WINDOW_WIDTH_VP,
  NavPageBuilderFactory,
  NavPathManager,
  RouterName,
  SafeUtil,
  statisticEvents,
  ThrottleFunction,
  ViewProxy,
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import lazy { CreateAgenda } from './CreateAgenda';
import { FromType, HiEventParamsConfirm, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { CreateAgendaPageSource, SaveTimeType } from '../Constants';
import { LengthMetrics } from '@kit.ArkUI';
import { ImageButton } from '@app/common.components';
import { TabController } from './TabController';

const TAG: string = 'CreateAgendaRoot';

/**
 * 日历创建页面
 *
 * @since 2022-09-29
 */
export interface RouterParam {
  intent: string;
  page: number;
  agendaDateParam: number;
  eventInfo: string;
  instanceStartMills: number;
  instanceEndMills: number;
  eventType?: number;
  fromPage?: CreateAgendaSheetFromPage;
  needSaveTime?: number;
  agendaDateLength?: number;
  oneSentenceCreate?: boolean;
  isAllDay?: boolean;
}

@Component
export struct CreateAgendaRoot {
  @Consume navPathStack: NavPathStack;

  @Link isShowCreateAgenda: boolean;

  editMode: boolean = false;

  eventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State confirmEnable: boolean = false;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @Provide navPathStackInPop: NavPathStack = new NavPathStack();

  // 当前页
  @Provide currentIndex: number = 0;

  // router跳转可选参数：创建日程的开始时间
  @State agendaDateParam: number = -1;

  // router跳转可选参数：创建日程的时长
  @State agendaDateLength: number = MILLS_PER_HOUR;

  @State mImportantEventType: number = CalendarContract.EventImportantType.NORMAL;

  // router跳转可选参数：创建日程的开始类型
  @State paramEventType: number = CalendarContract.EventImportantType.NORMAL;

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  @State hasShown: boolean = false;

  // 新建半模态拉起入口
  private fromPage: CreateAgendaSheetFromPage = CreateAgendaSheetFromPage.MAIN_PAGE;

  @Provide intent: string = '';

  @State rootLoaded: boolean = false;

  @State canFocus: boolean = true;

  tabHeight: number = 64;

  private emitterCollector : EmitterCollector = new EmitterCollector();

  private onDialogCancel: () => void = () => {
  };

  // 页面销毁时执行
  private onCreatePageDismiss: () => void = () => {
  };

  // 改变弹窗内容是否编辑过的状态
  private changeEditedFlag: () => void = () => {
  };

  // 是否快速新建
  private isQuickCreate: boolean = false;

  // 是否支持一句话智能创建
  private oneSentenceCreate: boolean = false;

  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;

  discardDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.eu3_calendar_title_issaveevent'),
      cancelText: $r('app.string.discard_dialog_button'),
      confirmText: $r('app.string.save_dialog_button'),
      isFocusLeftButton: true,
      onCancelClick: () => {
        this.finishPage();
        this.reportPopupStatistic(HiEventParamsConfirm.FALSE);
      },
      onConfirmClick: () => {
        if (!this.editMode && this.fromPage !== CreateAgendaSheetFromPage.AGENDA_LIST_PAGE) {
          this.navPathStack.pop();
        }
        this.createEvent();
        this.reportPopupStatistic(HiEventParamsConfirm.TRUE);
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: true,
    customStyle: this.dialogControllerOptions.customStyle,
    cancel: () => {
      this.onDialogCancel();
    }
  });

  @Prop @Watch('showDiscardDialog') discardDialogInCreateAgendaPageFlag: boolean;

  private createPageData: emitter.EventData = {};

  private instanceStartMills: number = 0;

  private instanceEndMills: number = 0;

  private tabPage: number = 0;

  private oldEventInfo: AgendaEventInfo = new AgendaEventInfo();

  private scroller: Scroller = new Scroller();

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private bindSheetWindowHeight: number | string = DeviceConfig.instance().config.bindSheetWindowHeight;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  // 外部传入的保留时间标志,若存在且为1,则不对传入时间作截取操作
  private needSaveTime: SaveTimeType = SaveTimeType.DEFAULT;

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowCreateAgenda = false;
  }

  private closePage: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowCreateAgenda = false;
  }

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  getPopupWindowHeight() {
    return this.isCreateAgendaPopup && this.windowHeightInVp < 660 ? this.windowHeightInVp - 84 : this.bindSheetWindowHeight;
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  onTabTypeChange: (type: number) => void = (type: number): void => {
    this.currentIndex = type;
    this.mImportantEventType = type;
    SafeUtil.setTimeout(() => {
      this.scroller.scrollBy(0, -1);
    }, 100);
  };

  @Builder
  buildCreateAgenda() {
    CreateAgenda({
      eventInfo: this.oldEventInfo,
      isEditMode: this.editMode,
      agendaDateParam: this.agendaDateParam,
      instanceStartMills: this.instanceStartMills,
      instanceEndMills: this.instanceEndMills,
      agendaDateLength: this.agendaDateLength,
      paramEventType: this.paramEventType,
      needSaveTime: this.needSaveTime,
      fromPage: this.fromPage,
      scroller: this.scroller,
      titleHeight: 0,
      onConfirmComplete: () => {
        this.finishPage();
      },
      onTabTypeChange: this.onTabTypeChange,
      importantEventType: this.mImportantEventType,
      onSaveStatusChange: (enable) => {
        Log.info(TAG, `onSaveStatusChange enable ${enable}`);
        this.confirmEnable = enable;
      },
      isQuickCreate: this.isQuickCreate,
      oneSentenceCreate: this.oneSentenceCreate,
      changeEditedFlag: this.changeEditedFlag
    })
  }

  @Builder
  buildQuickCreateAgenda() {
    Column() {
      if (this.rootLoaded) {
        this.buildCreateAgenda()
      }
    }
    .focusable(this.canFocus)
    .onAppear(() => this.rootLoaded = true)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  buildTitle() {
    Row() {
      this.NaviTitle()
      Blank()
      this.NavigationMenus();
    }
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .padding({ top: 8 })
    .height(64)
    .width('100%')
  }

  @Builder
  buildTabController() {
    if (!this.editMode && !this.isQuickCreate) {
      TabController({
        onTabChange: (type) => {
          this.onTabTypeChange(type);
        },
      })
    }
  }

  @Builder
  buildNormalCreateAgenda() {
    Navigation(this.navPathStackInPop) {
      Column() {
        this.buildTitle()
        
        if (this.rootLoaded) {
          this.buildTabController();
          this.buildCreateAgenda();
        }
      }
      .focusable(this.canFocus)
      .onAppear(() => this.rootLoaded = true)
      .height(this.getPopupWindowHeight())
      .backgroundColor(Color.Transparent)
      .padding({
        top: $r('sys.float.padding_level4'),
        bottom: this.needCommerce ? 16 : this.inSmallWindow ? 0 : 16
      })
    }
    .expandSafeArea([SafeAreaType.CUTOUT])
    .hideTitleBar(true)
    .navDestination(this.navRoute)
  }

  build() {
    if (this.isQuickCreate) {
      this.buildQuickCreateAgenda()
    }else{
      this.buildNormalCreateAgenda()
    }
  }

  handleOnShown() {
    this.hasShown = true;
    this.viewProxy.onShown();
  }

  reportPopupStatistic(isSave: number) {
    let mImportantEventType = this.mImportantEventType
    if (this.editMode) {
      mImportantEventType = this.oldEventInfo?.mImportantEventType || CalendarContract.EventImportantType.NORMAL
    }
    let params: ReportHiEventParams = {
      TYPE: mImportantEventType,
      IS_SAVE: isSave
    }
    if (this.editMode) {
      ReportUtil.reportStatisticEvent(statisticEvents.editAgendaSavePopup, params);
    } else {
      params.FROM_TYPE =
        this.fromPage === CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT ? FromType.IMPORTANT_FA : FromType.UNKNOWN;
      ReportUtil.reportStatisticEvent(statisticEvents.createAgendaSavePopup, params);
    }
  }

  /**
   * 键盘弹出时,侧滑也不会回调,优先隐藏键盘
   * this.navPathStack.pop() 不会回调 onBackPress
   * @returns
   */
  onBackPress(): boolean {
    Log.info(TAG, 'onBackPress Callback in Creat Agenda View.');
    this.viewProxy.onBackPressed();
    if (this.confirmEnable) {
      this.discardDialogController?.open();
    } else {
      this.finishPage();
    }
    return true;
  }

  finishPage() {
    // 弹窗确认后将页面设置为不可获焦
    this.canFocus = false;
    this.dismissEvent();
    this.onCreatePageDismiss();
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.confirmEnable = false;
    this.processCreatePageData();
    NavPathManager.getInstance().createRouter(RouterName.CREATE_AGENDA_MAIN, this.navPathStackInPop);

    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closePage);
  }

  /**
   * 处理新建页面传入的默认数据
   */
  processCreatePageData(): boolean {
    const paramsInter: RouterParam = this.createPageData.data as RouterParam;
    if (!paramsInter) {
      return false;
    }
    Log.info(TAG, `processCreatePageData {instanceStartMills, instanceEndMills, intent, fromPage} in paramsInter:
    ${paramsInter.instanceStartMills}, ${paramsInter.instanceEndMills}, ${paramsInter.intent}, ${paramsInter.fromPage},`);
    this.instanceStartMills = paramsInter.instanceStartMills;
    this.instanceEndMills = paramsInter.instanceEndMills;
    this.tabPage = paramsInter.page;
    this.agendaDateParam = paramsInter.agendaDateParam;
    this.agendaDateLength = paramsInter.agendaDateLength || MILLS_PER_HOUR;
    this.needSaveTime = paramsInter.needSaveTime || SaveTimeType.DEFAULT;
    this.intent = paramsInter.intent;
    this.editMode = paramsInter.intent === CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE ||
      paramsInter.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA ||
      paramsInter.intent === CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND;
    this.oneSentenceCreate = paramsInter.oneSentenceCreate ?? false;
    if (paramsInter.eventInfo) {
      this.eventInfo = JSON.parse(paramsInter.eventInfo);
    }
    if (this.eventInfo) {
      this.oldEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.eventInfo);
    }
    const isAllDay = paramsInter.isAllDay;
    if (isAllDay === true) {
      this.oldEventInfo.mIsAllDay = isAllDay;
    }
    if (paramsInter?.eventType) {
      this.paramEventType = paramsInter.eventType;
      this.mImportantEventType = paramsInter.eventType;
    } else if (this.eventInfo) {
      this.paramEventType = this.eventInfo.mImportantEventType;
      this.mImportantEventType = this.eventInfo.mImportantEventType;
    }
    if (paramsInter?.fromPage) {
      this.fromPage = paramsInter?.fromPage;
    }
    Log.info(TAG, `editMode: ${this.editMode}, tabPage: ${this.tabPage}, agendaDateParam: ${this.agendaDateParam}`);
    return true;
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.emitterCollector.off();
    this.discardDialogController = null;
    NavPathManager.getInstance().discard(RouterName.CREATE_AGENDA_MAIN);
  }

  /**
   * 点击取消按钮
   */
  dismissEvent() {
    this.isShowCreateAgenda = false;
    emitter.emit({ eventId: CommonInnerEvent.EVENT_DISMISS_CREATE_AGENDA, priority: emitter.EventPriority.HIGH });
    Log.info(TAG, 'Emitter Dismiss Create Agenda');
  }

  @Builder
  NaviTitle() {
    NaviTitleBar({
      editMode: this.editMode,
      mImportantEventType: this.editMode ? this.oldEventInfo?.mImportantEventType : this.mImportantEventType,
      onClickDiscard: () => {
        if (this.confirmEnable) {
          this.discardDialogController?.open();
        } else {
          this.finishPage();
        }
      }
    })
  }

  @Builder
  NavigationMenus() {
    NaviMenus({
      confirmEnable: this.confirmEnable
    })
  }

  createEvent() {
    emitter.emit({ eventId: CommonInnerEvent.EVENT_CREATE_AGENDA })
  }

  private showDiscardDialog() {
    this.onBackPress();
  }
}

@Component
export struct NaviMenus {
  @Prop confirmEnable: boolean = false;

  //image fillColor
  @State imgFillColor: string = '#000000';

  @State dummyFlag: boolean = false; // 无用flag

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  //新建日程保存按钮节流：600ms
  private readonly DELAY: number = 600;

  build() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        buttonBackgroundColor: this.buttonBackgroundColor,
        image: $r('sys.symbol.checkmark'),
        flagChanged: $dummyFlag,
        promptText: $r('app.string.account_details_complete_button'),
        buttonEnabled: this.confirmEnable,
        onButtonClick:() => {
          this.onConfirmButtonClick();
        }
      })
      .id(CompId.ADD_AGENDA_COMFRIM)
      .width(40)
      .height(40)
    }
    .margin({ end: LengthMetrics.vp(16) })
    .height(56)
  }

  createEvent() {
    emitter.emit({ eventId: CommonInnerEvent.EVENT_CREATE_AGENDA });
  }

  private onConfirmButtonClick() {
    ThrottleFunction.instance().throttle(TAG, (): void => {
      if (this.confirmEnable) {
        Log.info(TAG, 'onConfirmButtonClick to save schedule');
        this.createEvent();
      }
    }, this.DELAY);
  }
}

@Component
export struct NaviTitleBar {
  editMode: boolean = false;

  @Prop mImportantEventType: number = CalendarContract.EventImportantType.NORMAL;

  //image fillColor
  @State imgFillColor: string = '#000000';

  @State dummyFlag: boolean = false; // 无用flag

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  @StorageLink('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  onClickDiscard: () => void = () => {
  };

  getTitle() {
    switch (this.mImportantEventType) {
      case CalendarContract.EventImportantType.ANNIVERSARIES:
      case CalendarContract.EventImportantType.COUNTDOWN:
        return this.editMode ? $r('app.string.edit_important_event') : $r('app.string.new_important_event')
      default:
        return this.editMode ? $r('app.string.event_edit') : $r('app.string.peek_create_agenda')
    }
  }

  getTitleCompId(): string {
    switch (this.mImportantEventType) {
      case CalendarContract.EventImportantType.ANNIVERSARIES:
      case CalendarContract.EventImportantType.COUNTDOWN:
        return this.editMode ? CompId.EDIT_IMPORTANT_EVENT : CompId.NEW_IMPORTANT_EVENT;
      default:
        return this.editMode ? CompId.EDIT_EVENT : CompId.NEW_EVENT;
    }
  }

  build() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        buttonBackgroundColor: this.buttonBackgroundColor,
        image: $r('sys.symbol.xmark'),
        flagChanged: $dummyFlag,
        promptText: $r('app.string.cancel_dialog_button'),
        onButtonClick:() => {
          this.onClickDiscard();
        }
      })
      .width(40)
      .height(40)
      .id(CompId.ADD_AGENDA_CANCEL)


      Text(this.getTitle())
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE,
          20
        ))
        .minFontSize(8)
        .fontWeight(FontWeight.Bold)
        .margin({ start: LengthMetrics.vp(8) })
        .id(this.getTitleCompId())
        .focusable(true)
        .accessibilityLevel('yes')
        .layoutWeight(1)
    }
    .height(56)
    .layoutWeight(1)
    .margin({ start: LengthMetrics.vp(16) })
  }
}