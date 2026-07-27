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
  AccountColor,
  AgendaAbilityManager,
  AgendaDeleteService,
  AgendaEventInfo,
  AgendaTransitionUtil,
  BigFontSize,
  CalendarContract,
  CalendarService,
  ClickSource,
  CloudUtils,
  CommonEventHubCode,
  CommonInnerEvent,
  CommonService,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  EmitterCollector,
  EventService,
  FromType,
  GlobalThis,
  isSyncAbleAccount,
  Log,
  ServiceEnum,
  ServiceManager,
  ThrottleFunction,
  ViewProxy
} from '@app/common';
import { CommonTextDialog, ImageButton } from '@app/common.components';
import {
  AgendaDetail,
  AgendaDetailSource,
  AgendaOperateHelper,
  CreateAgendaRoot,
  DeleteAgendaRadio,
  DeleteMode,
  EditAgendaMenu
} from '@app/feature.agenda';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { KeyCode } from '@kit.InputKit';
import { common } from '@kit.AbilityKit';

const TAG: string = 'AgendaDetailPage';

let storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct AgendaDetailPage {
  @Provide navPathStack: NavPathStack = new NavPathStack();

  @Provide agendaTransitionUtil: AgendaTransitionUtil = new AgendaTransitionUtil();

  @Provide isAgendaAniShowFinish: boolean = false;

  @State eventId: number = -1;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  // 顶部导航标题
  @State navTitle: Resource = $r('app.string.event_detail');

  // 右上角删除按钮被点击
  @State deleteFlagChanged: boolean = false;

  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  // 日程是否可编辑
  @State canEdit: boolean = true;

  // 日程可分享
  @State canShare: boolean = true;

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  @LocalStorageLink('uiAbilityContext') context: common.UIAbilityContext | undefined = undefined;

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  @State isHoliday: boolean = false;

  @State holidayTitle: string = '';

  // 右上角分享按钮被点击
  @State shareFlagChanged: boolean = false;

  // 右上角编辑按钮被点击
  @State editFlagChanged: boolean = false;

  // 来源入口
  @State fromType: number = FromType.UNKNOWN;

  @State isEditMenuShow: boolean = false;

  @State mEventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State rightButtonShow: boolean = false;

  // 广播携带的日程信息
  @State createPageData: emitter.EventData = {};

  // 显示新建日程的半模态
  @State isShowCreateAgenda: boolean = false;

  // 关闭新建日程半模态时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  @State detailPadding: number = 16;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private emitterCollector: EmitterCollector = new EmitterCollector();

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  //button背景色
  private buttonBackgroundColor: ResourceColor =
    this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private isShowBottom: boolean = DeviceConfig.instance().config.isShowBottom;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private scroller: Scroller = new Scroller();

  private getUpdatedInfo: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.mEventInfo = info;
    this.navTitle = info.isImportantEvent() ? $r('app.string.important_day') : $r('app.string.event_detail');
    const title = info.mTitle ? info.mTitle : GlobalThis.getResourceStr($r('app.string.no_title_label'), this.language);
    this.context?.setMissionLabel(title);
    this.rightButtonShow = this.shouldShowOperateButtons();
  };

  private updatedInfoByNewWant: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.instanceStartMills = info.mBegin;
    this.instanceEndMills = info.mEnd;
    this.holidayTitle = info.mTitle;
  };

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

  private nowSpringAction: SpringBackAction | undefined = undefined;

  private onDialogCancel: () => void = () => {
    if (this.nowSpringAction) {
      // 弹窗直接取消的情况下要回弹新建日程弹窗并将action设为空以防止出错
      this.nowSpringAction.springBack();
      this.nowSpringAction = undefined;
    }
  };

  private deleteAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private editAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private deleteAgenda: AgendaEventInfo | undefined = undefined; // 要删除的agenda

  private deleteTimestamp: number = -1; // 涉及删除的时间

  private deleteAccountType: string = '';

  private agendaDeleteService: AgendaDeleteService | undefined = undefined;

  private instanceKey: string = ''; // 传输的用于获取context的Ability key值

  // 删除重复日程弹框
  deleteRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DeleteAgendaRadio({
      confirm: (checkValue) => {
        if (!this.deleteAgenda) {
          return;
        }
        if (checkValue === DeleteMode.ONLY_THIS_AGENDA) {
          this.agendaDeleteService?.addExclusiveToRepeatRule(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else if (checkValue === DeleteMode.THIS_AND_FUTURE_AGENDA) {
          this.agendaDeleteService?.updateEndTime(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else {
          this.agendaDeleteService?.deleteEvent(this.deleteAgenda.mId);
        }
      },
      showCloudSyncTip: isSyncAbleAccount('', this.deleteAccountType) &&
      CloudUtils.isSupportCloudSync() && CloudUtils.isCloudSyncOpened(),
      title: this.agendaDeleteService?.getDeleteAgendaDialogTitle(this.deleteAgenda?.mTitle || ''),
      isFirstRepeatAgenda: this.deleteAgenda?.mBegin === this.deleteTimestamp,
    }),
    alignment: DialogAlignment.Center,
  });

  // 删除非重复日程弹框
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: this.agendaDeleteService?.getDeleteMessage(this.deleteAgenda, this.deleteAccountType),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        if (!this.deleteAgenda) {
          return;
        }
        this.agendaDeleteService?.deleteEvent(this.deleteAgenda?.mId);
      },
      onCancelClick: () => {
        Log.info(TAG, 'click cancel');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  onLanguageChange(): void {
    if (!this.mEventInfo.mTitle) {
      const title = GlobalThis.getResourceStr($r('app.string.no_title_label'), this.language);
      this.context?.setMissionLabel(title);
    }
  }

  // 是否重复日程第一条
  isFirstRepeatAgenda(): boolean {
    if (!this.mEventInfo.isRepeatEvent()) {
      return false;
    }
    if (this.mEventInfo.mBegin === this.instanceStartMills) {
      return true;
    }
    return false;
  }

  /**
   * 日程详情右上角按钮菜单
   */
  @Builder
  NavigationMenus() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.share'),
        flagChanged: this.shareFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_share'),
        compId: CompId.ID_BT_AGENDA_DETAIL_SHARE
      })
        .margin({ end: LengthMetrics.vp(8) })
        .visibility(this.canShare ? Visibility.Visible : Visibility.None)
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.square_and_pencil'),
        flagChanged: this.editFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_edit'),
        onButtonClick: () => {
          this.goToEditEvent();
        },
        compId: CompId.AGENDA_DETAIL_EDIT
      })
        .bindContextMenu(this.isEditMenuShow, this.buildEditMenu(), {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.isEditMenuShow = false;
          },
        })
        .bindSheet($$this.isShowCreateAgenda, this.buildCreateAgenda(this.createPageData), {
          height: SheetSize.LARGE,
          detents: [SheetSize.LARGE, 0, 0],
          dragBar: false,
          showClose: false,
          preferType: this.isCreateAgendaPopup ? SheetType.POPUP : SheetType.CENTER,
          shadow: ShadowStyle.OUTER_DEFAULT_SM,
          enableOutsideInteractive: false,
          maskColor: Color.Transparent,
        //  keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
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
        .margin({ end: LengthMetrics.vp(8) })
        .visibility(this.canEdit ? Visibility.Visible : Visibility.None)
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.trash'),
        flagChanged: this.deleteFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_delete'),
        compId: CompId.AGENDA_DETAIL_DELETE,
      })
    }
    .height(56)
  }

  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    EditAgendaMenu({
      isFirstRepeatAgenda: this.isFirstRepeatAgenda(),
      editThisAgenda: () => {
        this.mAgendaOperateHelper.editThisAgenda(this.mEventInfo, this.instanceStartMills, this.instanceEndMills, true);
      },
      editThisAgendaAndBeyond: () => {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(
          this.mEventInfo, this.instanceStartMills, this.instanceEndMills, true);
      },
      onClickEdit: () => {
        this.mAgendaOperateHelper.editAgenda(this.mEventInfo, true);
      }
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
        isCreateAgendaPopup: true,
        onDialogCancel: this.onDialogCancel,
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  MainContentBuilder() {
    GridRow({
      // 手机边距16,大屏边距24,宽度大于840则需要以10/12的栅格比例留白
      columns: { xs: 10, sm: 10, md: 12 },
      breakpoints: {
        value: ['600vp', '840vp'],
        reference: BreakpointsReference.WindowSize
      },
      direction: GridRowDirection.Row
    }) {
      GridCol({ span: 10, offset: { xs: 0, sm: 0, md: 1 } }) {
        AgendaDetail({
          canEdit: $canEdit,
          canShare: $canShare,
          shareFlagChanged: this.shareFlagChanged,
          shareAnchorViewId: CompId.ID_BT_AGENDA_DETAIL_SHARE,
          deleteFlagChanged: this.deleteFlagChanged,
          isShowBottom: this.isShowBottom,
          eventId: $eventId,
          isDivide: false,
          isInNewPage: true,
          needLeftPadding: false,
          needRightPadding: false,
          scroller: this.scroller,
          titleHeight: this.windowAvoidAreaTopRectHeight + 64,
          sourceType: AgendaDetailSource.AGENDA_PAGE,
          instanceKey: this.instanceKey,
          holidayInfo: this.holidayInfo,
          displayStartMills: this.instanceStartMills,
          displayEndMills: this.instanceEndMills,
          onDeleteSuccess: () => {
            this.pageBackAfterDelete();
          },
          onAgendaNotFound: () => {
            this.pageBackAfterDelete();
          },
          fromType: this.fromType,
          getUpdatedInfo: this.getUpdatedInfo,
          paddingLeft: this.detailPadding,
          paddingRight: this.detailPadding,
        })
      }
    }
    .onBreakpointChange((bp) => {
      // 小屏需要边距,到直接通过栅格来留白
      if (bp === 'xs') {
        this.detailPadding = 16;
      } else if (bp === 'sm') {
        this.detailPadding = 24;
      } else if (bp === 'md') {
        this.detailPadding = 16;
      }
    })
    .layoutWeight(1)
    .margin({ top: 8 })
  }

  @Builder
  GridColContent() {
    Row() {
      Text(this.navTitle)
        .fontSize(20)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
        .margin({ start: LengthMetrics.vp(16) })
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      if (this.rightButtonShow) {
        this.NavigationMenus()
      }
    }
    .padding({ end: LengthMetrics.vp(16 + this.titleButtonWidth) })
    .height(56)
    .margin({ top: 8 })
  }

  build() {
    Navigation() {
      Column() {
        this.GridColContent()
        this.MainContentBuilder()
      }
    }
    .padding({
      top: this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
      bottom: this.windowAvoidAreaNavigationRectHeight,
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .id(CompId.AGENDA_DETAIL_PAGE_BOX)
    .onTouch((event?: TouchEvent) => {
      if (!event) {
        return;
      }
      if (event.type === TouchType.Down) {
        focusControl.requestFocus(CompId.AGENDA_DETAIL_PAGE_BOX);
      }
    })
    .onKeyEvent((event: KeyEvent) => { // 全局按键触发事件
      if (event.keyCode === KeyCode.KEYCODE_ESCAPE && event.type === KeyType.Down) {
        ThrottleFunction.instance().throttle(TAG, (): void => {
          AgendaAbilityManager.getInstance().exitAgendaContext(this.instanceKey);
          Log.info(TAG, `onKeyEvent ESC close`)
        }, 50);
      }
    })
  }

  onPageShow() {
    this.viewProxy.onShown();
  }

  onPageHide() {
    this.viewProxy.onHidden();
  }

  onBackPress(): boolean {
    this.viewProxy.onBackPressed();
    return false;
  }

  pageBackAfterDelete() {
    AgendaAbilityManager.getInstance().exitAgendaContext(this.instanceKey);
  }

  pageRouterBack() {
    AgendaAbilityManager.getInstance().exitAgendaContext(this.instanceKey);
  }

  private deleteEvent(data: emitter.EventData): void {
    let eventId: number | undefined = data.data?.eventId;
    let deleteTimestamp: number | undefined = data.data?.timestamp;
    let isMainAbility: boolean | undefined = data.data?.isMainAbility ?? true;
    // deleteTimestamp 用于删除重复日程的重复规则,isMainAbility判断是否在mainAbility发起
    if (eventId == undefined || deleteTimestamp == undefined || isMainAbility) {
      return;
    }
    if (eventId !== this.eventId) {
      return;
    }
    EventService.INSTANCE.queryEventById(eventId).then(async (event) => {
      if (event) {
        let accounts = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
        let accountMap = CommonService.INSTANCE.getAccountMap(accounts);
        this.deleteAccountType = accountMap.get(event.mCalendarId).accountType;
        this.deleteAgenda = event;
        this.deleteTimestamp = deleteTimestamp || 0;
        Log.info(TAG, `delete agenda page ${this.deleteAgenda.mId}-${this.deleteTimestamp}-${this.deleteAccountType}`);
        if (event.isRepeatEvent() && !event.isImportantEvent()) {
          this.deleteRepeatAgendaDialogController?.open();
        } else {
          this.deleteDialogController?.open();
        }
      }
    })
  }

  emitterEvent() {
    this.deleteAgendaHandler = (data: emitter.EventData) => this.deleteEvent(data);
    this.emitterCollector.on({ eventId: CommonInnerEvent.DELETE_AGENDA }, this.deleteAgendaHandler)
    this.editAgendaHandler = (eventData: emitter.EventData) => {
      Log.info(TAG, 'onClick to Edit Agenda');
      if (!eventData.data) {
        Log.info(TAG, 'No Valid eventData!');
        return;
      }
      if (!eventData.data.isSubAbility || !eventData.data.eventId) {
        Log.info(TAG, 'Open Not In SubAbility');
        return;
      }
      const eventId = eventData.data.eventId as number;
      if (eventId !== this.eventId) {
        return;
      }
      this.createPageData = eventData;
      this.isShowCreateAgenda = true;
    };

    this.emitterCollector.on({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, this.editAgendaHandler);
    // eventHub注册监听,在context销毁时通过AgendaAbilityManager统一销毁
    const context = AgendaAbilityManager.getInstance().getAgendaContext(this.instanceKey);
    if (context) {
      context.eventHub.on(CommonEventHubCode.EVENT_UPDATE_AGENDA_NEW_PAGE, this.updatedInfoByNewWant);
    }
  }

  async initService() {
    this.agendaDeleteService =
      await ServiceManager.getInstance().getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE);
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.getParameterByStorage();
    this.initService();
    this.emitterEvent();
    Log.info(TAG, `params.id = ${this.eventId}, params.action = new Page`);
  }

  // 初始化及更新从storage中拼装
  getParameterByStorage() {
    let eventId = -1; // 因this.eventId更新会触发回调故放置于最后进行更新
    try {
      eventId = storage.get<number>('editing_eventId') ?? -1;
      this.instanceStartMills = storage.get<number>('editing_instanceStartMills') ?? -1;
      this.instanceEndMills = storage.get<number>('editing_instanceEndMills') ?? -1;
      this.isHoliday = storage.get<boolean>('editing_isHoliday') ?? false;
      this.holidayTitle = storage.get<string>('editing_holidayTitle') ?? '';
      this.instanceKey = storage.get<string>('editing_instanceKey') ?? '';
    } catch (err) {
      Log.logErrorMsg(TAG, 'parse param get Err', err);
    }
    if (this.isHoliday) { // 拼接节假日数据
      this.holidayInfo.mTitle = this.holidayTitle;
      this.holidayInfo.mIsHoliday = true;
      this.holidayInfo.mIsAllDay = true;
      this.holidayInfo.mId = -1; // 用作标识，无实际含义
      this.holidayInfo.mBegin = this.instanceStartMills;
      this.holidayInfo.mImportantEventType = -1; // 用作标识，无实际含义
      this.holidayInfo.mEnd = this.instanceEndMills;
      this.holidayInfo.mDisplayColor = AccountColor.RED;
    }
    this.eventId = eventId;
    this.rightButtonShow = this.shouldShowOperateButtons();
  }

  goToEditEvent() {
    if (this.mEventInfo.isRepeatEvent() && !this.mEventInfo.isImportantEvent()) {
      this.isEditMenuShow = true;
    } else {
      this.mAgendaOperateHelper.editAgenda(this.mEventInfo, true);
    }
  }

  /**
   * pc端是否展示编辑、分享、删除操作按钮
   */
  private shouldShowOperateButtons(): boolean {
    if (this.isShowBottom) {
      return false;
    }

    if (this.holidayInfo?.mIsHoliday) {
      return false;
    }

    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return false;
    }
    return true;
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.emitterCollector.off();
  }
}