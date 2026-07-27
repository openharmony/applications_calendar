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
  AGENDA_SUB_DETAIL_WIDTH,
  CalendarContract,
  CommonInnerEvent,
  CreateAgendaSheetFromPage,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  GlobalDataKeys,
  Log,
  MILLS_PER_HOUR,
  NavPageBuilderFactory,
  NavPathManager,
  NavPathName,
  RouterName,
  statisticEvents,
  ViewProxy,
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import lazy { CreateAgenda } from './CreateAgenda';
import {
  HiEventParamsConfirm,
  ReportHiEventParams,
  ReportUtil
} from '@app/common/src/main/ets/default/util/ReportUtil';
import { SaveTimeType } from '../Constants';
import { RouterParam, NaviMenus, NaviTitleBar } from './CreateAgendaRoot';


@Builder
function harBuilder(navParams: object) {
  CreateAgendaSubRoot({
    navParams: navParams
  });
}

const builderName = NavPathName.CREATE_AGENDA_SUB;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

const TAG: string = 'CreateAgendaSubRoot';

@Component
export struct CreateAgendaSubRoot {
  // 当前页
  @Provide currentIndex: number = 0;

  eventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State confirmEnable: boolean = false;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // router跳转可选参数：创建日程的开始时间
  @State agendaDateParam: number = -1;

  // router跳转可选参数：创建日程的时长
  @State agendaDateLength: number = MILLS_PER_HOUR;

  @State mImportantEventType: number = CalendarContract.EventImportantType.NORMAL;

  // router跳转可选参数：创建日程的开始类型
  @State paramEventType: number = CalendarContract.EventImportantType.NORMAL;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // 新建半模态拉起入口
  private fromPage: CreateAgendaSheetFromPage = CreateAgendaSheetFromPage.MAIN_PAGE;

  @Provide intent: string = '';

  @State rootLoaded: boolean = false;

  @State canFocus: boolean = true;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private scroller: Scroller = new Scroller();

  private onDialogCancel: () => void = () => {
  };

  // 页面销毁时执行
  private onCreatePageDismiss: () => void = () => {
  };

  // 改变弹窗内容是否编辑过的状态
  private changeEditedFlag: () => void = () => {
  };

  // 是否支持一句话智能创建
  private oneSentenceCreate: boolean = false;

  private routerName: string = RouterName.AGENDA_DETAIL_HAP;

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
        this.closeToDetailPop();
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

  private navParams: object = JSON.parse('{}') as object;

  private instanceStartMills: number = 0;

  private instanceEndMills: number = 0;

  private tabPage: number = 0;

  private oldEventInfo: AgendaEventInfo = new AgendaEventInfo();

  private bindSheetWindowHeight: number | string = DeviceConfig.instance().config.bindSheetWindowHeight;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  // 外部传入的保留时间标志,若存在且为1,则不对传入时间作截取操作
  private needSaveTime: SaveTimeType = SaveTimeType.DEFAULT;

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
  }

  private closePage: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_POPUP_CLOSE });
  }

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = true;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onWindowWidthChange() {
    if (this.windowWidth < AGENDA_SUB_DETAIL_WIDTH) {
      // 小于子窗展示宽度则直接回退到详情页,然后由详情页处理子窗到全屏的切换
      this.closeToDetailPop(false);
    }
  }

  // 关闭弹窗跳转详情pop页面
  closeToDetailPop(animated: boolean = true) {
    NavPathManager.getInstance().getRouter(RouterName.AGENDA_DETAIL_HAP)?.pop(this.navParams, animated);
  }

  getPopupWindowHeight() {
    return this.isCreateAgendaPopup && this.windowHeightInVp < 660 ? this.windowHeightInVp - 84 :
    this.bindSheetWindowHeight;
  }

  @Builder
  navRoute(name: string, param: object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  @Builder
  buildCreateAgenda() {
    CreateAgenda({
      eventInfo: this.oldEventInfo,
      isEditMode: true,
      agendaDateParam: this.agendaDateParam,
      instanceStartMills: this.instanceStartMills,
      instanceEndMills: this.instanceEndMills,
      agendaDateLength: this.agendaDateLength,
      paramEventType: this.paramEventType,
      needSaveTime: this.needSaveTime,
      fromPage: this.fromPage,
      scroller: this.scroller,
      routerName: this.routerName,
      titleHeight: 72,
      onConfirmComplete: () => {
        this.finishPage();
      },
      onTabTypeChange: (type) => {
        this.mImportantEventType = type;
      },
      onSaveStatusChange: (enable) => {
        Log.info(TAG, `onSaveStatusChange enable ${enable}`);
        this.confirmEnable = enable;
      },
      oneSentenceCreate: this.oneSentenceCreate,
      changeEditedFlag: this.changeEditedFlag
    })
  }

  @Builder
  buildTitle() {
    Row() {
      this.NaviTitle()
      Blank()
      this.NavigationMenus();
    }
    .margin({ top: 8 })
    .height(56)
    .width('100%')
  }

  @Builder
  buildNormalCreateAgenda() {
    NavDestination() {
      Column() {
        if (this.rootLoaded) {
          this.buildCreateAgenda()
        }
      }
      .focusable(this.canFocus)
      .onAppear(() => this.rootLoaded = true)
      .height(this.getPopupWindowHeight())
      .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') :
      $r('app.color.color_privacy_background'))
      .padding({
        top: $r('sys.float.padding_level4'),
        bottom: this.needCommerce ? 16 : this.inSmallWindow ? 0 : 16
      })
    }
    .hideBackButton(true)
    .hideToolBar(true)
    .expandSafeArea([SafeAreaType.CUTOUT])
    .title(this.buildTitle)
  }

  build() {
    this.buildNormalCreateAgenda()
  }

  handleOnShown() {
    this.viewProxy.onShown();
  }

  reportPopupStatistic(isSave: number) {
    let mImportantEventType = this.oldEventInfo?.mImportantEventType || CalendarContract.EventImportantType.NORMAL;

    let params: ReportHiEventParams = {
      TYPE: mImportantEventType,
      IS_SAVE: isSave
    }
    ReportUtil.reportStatisticEvent(statisticEvents.editAgendaSavePopup, params);
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

  private clickToClosePopup: () => void = () => {
    Log.info(TAG, `click close agenda edit popup`);
    if (this.confirmEnable) {
      this.discardDialogController?.open();
    } else {
      this.finishPage();
    }
  };

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.confirmEnable = false;
    this.processCreatePageData();

    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closePage);
    this.emitterCollector.on({ eventId: CommonInnerEvent.DETAIL_PAGE_POPUP_CLOSE }, this.clickToClosePopup);
  }

  /**
   * 处理新建页面传入的默认数据
   */
  processCreatePageData(): boolean {
    const paramsInter: RouterParam = this.navParams as RouterParam;
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
    this.oneSentenceCreate = paramsInter.oneSentenceCreate ?? false;
    if (paramsInter.eventInfo) {
      try {
        this.eventInfo = JSON.parse(paramsInter.eventInfo);
      } catch (err) {
        Log.logErrorMsg(TAG, 'json parse eventInfo err', err);
        return false;
      }
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
    Log.info(TAG, `tabPage: ${this.tabPage}, agendaDateParam: ${this.agendaDateParam}`);
    return true;
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.emitterCollector.off();
    this.discardDialogController = null;
  }

  /**
   * 点击取消按钮
   */
  dismissEvent() {
    this.closeToDetailPop();
    Log.info(TAG, 'click Dismiss Create Agenda');
  }

  @Builder
  NaviTitle() {
    NaviTitleBar({
      editMode: true,
      mImportantEventType: this.oldEventInfo?.mImportantEventType,
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