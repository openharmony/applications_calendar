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
  AgendaListItemViewModel,
  BigFontSize,
  CompId,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  GlobalDataKeys,
  FontSizeScaleUtils,
  GlobalData,
  Log,
  PreviewFromType,
  TabType,
  ThrottleFunction,
  ReportUtil,
  behaviorEvents,
  ReportHiEventParams,
  HiEventParamsConfirm,
  CommonInnerEvent,
  ModeUtil,
  UnusualMode,
  AgendaDeleteService,
  ServiceManager,
  ServiceEnum,
  CloudUtils,
  EventService,
  SlideActionType,
  I18nUtil,
  CalendarContract,
  CommonService,
  CalendarService,
  CalendarAccountType,
  FromType,
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { AgendaListLocation } from '@app/common/src/main/ets/default/util/ReportUtil';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { AgendaListViewModel } from '../viewmodel/AgendaListViewModel';
import { LoadingView } from '../../components/LoadingView';
import { AgendaItem } from '../../components/AgendaItem';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { KeyCode } from '@kit.InputKit';
import { FocusPage } from '../../components/FlexAgendaList';
import { MultiBottomTab } from '../../AgendaDetail/view/MultiBottomTab';
import { emitter } from '@kit.BasicServicesKit';
import { LengthMetrics } from '@kit.ArkUI';
import { AgendaMenuOpt } from '../../AgendaDetail/view/AgendaPopupContent';
import { AgendaEditMenuOpt, AgendaMenu, generateAgendaEditOption } from '../../AgendaDetail/view/AgendaMenu';
import { AgendaDetailSource } from '../../common/AgendaEnum';
import { HashMap } from '@kit.ArkTS';

/* instrument ignore file */

const TAG: string = 'AgendaListView'; // 使用本TAG做该页面的唯一标记 请勿变更，否则会影响折叠屏的开合一致性
const DELAY: number = 300;
// 滚动条右侧偏移量
const SCROLL_BAR_OFFSET = 16;

@Component
export struct AgendaListView {
  @Consume navPathStack: NavPathStack;

  @Consume calendarUuid: string;

  @Consume currentDisplayStartMills: number;

  @Consume currentDisplayEndMills: number;

  // 窗口类型
  @Consume @Watch('onInSmallWindowChange') inSmallWindow: boolean;

  // 全模态打开日程详情
  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  // 处理焦点变化
  @Consume actionFocus: string

  // 全局统一的展示日期时间戳
  @StorageProp(GlobalDataKeys.DISPLAY_DATE) globalDisplayMills: number = 0;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  @StorageProp('is24HourClock') is24HourClock: boolean = false;

  // 系统时间当天的时间戳
  @StorageProp(GlobalDataKeys.CURRENT_DATE) @Watch('onCurrentDateChange') currentDate: number = 0;

  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  @State searchText: string = '';

  // 是否显示回到今日按钮
  @Consume isShowBackToToday: boolean;

  // 分栏状态下右侧显示的日程的id
  @Link showEventId: number;

  @Link hideList: boolean;

  // 全部日程列表是否展示节日
  @Link @Watch('isShowHolidayChange') isShowHoliday: boolean;

  @Link @Watch('backToTodayMethod') onBackToday: boolean;

  // 是否支持日程卡右键删除
  private isRightClickToDeleteAllowed: boolean = DeviceConfig.instance().config.isRightClickToDeleteAllowed;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private mScroller = new Scroller();

  @Link selectedAgendaCount: number; // 多选选中的数量

  @Link @Watch('onSelectEnableChanged') selectable: boolean; // 是否可以选中

  @Consume keyCtrlState: boolean;

  @State shareableEventCount: number = 0;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  // 路由携带的日期时间戳
  private paramsDisplayStartMills: number = 0;

  private paramsDisplayEndMills: number = 0;

  // 路由携带的日程id
  private paramsEventId: number = 0;

  // 日程列表初始化查询时间戳：默认用全局展示的时间，有传入则用传入值
  private displayMills: number = this.globalDisplayMills;

  // 分享的viewId
  private shareAnchorViewId: string = 'multi_bottom_tab_share_btn';

  // 当前list宽度,用于热区的位置判断
  private listWidth: number = 0;

  @State vm: AgendaListViewModel = new AgendaListViewModel(
    this.displayMills,
    this.calendarUuid,
    this.language,
    this.mScroller,
    this.paramsEventId,
    this.paramsDisplayStartMills,
    (showEventId: number, currentDisplayStartMills: number,
     currentDisplayEndMills: number, shareableEventCount: number, selectedAgendaCount: number,
     event: AgendaEventInfo | undefined) => {
      Log.info(TAG, `AgendaListView shareableCount ${shareableEventCount}`);
      this.shareableEventCount = shareableEventCount;
      this.vmShowDataChange(showEventId, currentDisplayStartMills,
        currentDisplayEndMills, selectedAgendaCount, event);
    });

  @State geometry: string = '';

  @State transitionOption: GeometryTransitionOptions = {};

  private accountMap: HashMap<number, CalendarContract.Accounts> = new HashMap();

  private onAniStart: () => void = () => {
    this.geometry = this.getGeometryId();
    this.transitionOption = AgendaTransitionUtil.option;
  }

  private onAniEnd: () => void = () => {
    this.geometry = '';
    this.transitionOption = {};
  }

  private onSelectedAgendaChange: (event: AgendaEventInfo | undefined) =>
    void = (event: AgendaEventInfo | undefined): void => {
  };

  // VM的状态变量改变需要同步回父组件
  vmShowDataChange(showEventId: number, currentDisplayStartMills:
    number, currentDisplayEndMills: number, selectedAgendaCount: number, event: AgendaEventInfo | undefined) {
    this.showEventId = showEventId;
    this.currentDisplayStartMills = currentDisplayStartMills;
    this.currentDisplayEndMills = currentDisplayEndMills;
    this.selectedAgendaCount = selectedAgendaCount;
    this.onSelectedAgendaChange(event);
  };

  onSelectEnableChanged() {
    if (this.selectable) {
      if (this.keyCtrlState && this.vm.selectedAgenda && !this.vm.selectedAgenda.isHoliday()) {
        this.vm.enableMultiSelect(this.vm.selectedAgenda);
      } else {
        this.vm.enableMultiSelect();
      }
    } else {
      this.disableSelect();
    }
  }

  isShowHolidayChange() {
    this.vm.reInitAgenda(this.isShowHoliday);
  }

  disableSelect() {
    this.selectable = false;
    this.selectedAgendaCount = 0;
    this.vm.disableMultiSelect();
  }

  onCurrentDateChange() {
    this.vm.onCurrentDateChange(this.currentDate);
  }

  onLanguageChange() {
    this.vm.onLanguageChange(this.language);
  }

  onMultiDeleteClick() {
    this.multiDeleteDialogController?.open();
  }

  async onMultiShareClick() {
    let params: ReportHiEventParams = {
      FROM_TYPE: AgendaListLocation.AgendaListView
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiShare, params);
    if (this.selectedAgendaCount !== this.vm.shareableEventIds.length) {
      const eventIds = await EventService.INSTANCE.queryNormalEvents(this.calendarUuid);
      if (!eventIds) {
        Log.error(TAG, `eventIds is null`);
        return;
      }
      // 已查询出的 agendas
      const hasAgendas = this.vm.agendaResult
        .filter(agenda => !agenda.isHoliday() && !agenda.isContactBirthday())
        .map(agenda => agenda.mId);
      const noViewAgendas = eventIds.filter(eventId => !hasAgendas.includes(eventId));// 未查出的 agendas
      let eventResult = this.vm.shareableEventIds.concat(noViewAgendas);// 全部需要分享的 agendas
      this.mAgendaOperateHelper.shareMultipleAgenda(
        eventResult, this.shareAnchorViewId
      );
    } else {
      this.mAgendaOperateHelper.shareMultipleAgenda(
        this.vm.shareableEventIds, this.shareAnchorViewId
      );
    }
  }

  onInSmallWindowChange() {
    Log.info(TAG, `AgendaListView this.inSmallWindow: ${this.inSmallWindow}, this.actionFocus: ${this.actionFocus}`);
    if (this.inSmallWindow && this.hideList) {
      this.changeCheckEventId(this.showEventId);
      const info: AgendaEventInfo | undefined = this.vm.agendaResult.find(item => item.mId === this.showEventId)
      if (info === undefined) {
        Log.error(TAG, `Info Is Not Found, This Show Event ID is Wrong, showEventId: ${this.showEventId}`);
      } else {
        // 跳转到详情页面
        this.agendaTransitionUtil.buildEventDetail(info);
        this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), false, this.onAniStart, this.onAniEnd);
        this.vm.onActionFocusChange(FocusPage.AGENDA_DETAIL);
        Log.info(TAG, `Go To Agenda Detail Cover this.inSmallWindow: ${this.inSmallWindow}, this.actionFocus: ${this.actionFocus}`);
      }
    }
    if (!this.inSmallWindow && this.agendaTransitionUtil.isEditPageShow) {
      // 跳转到全部日程页面，全部日程页面获焦
      this.agendaTransitionUtil.clearAniEnd();
      this.agendaTransitionUtil.isEditPageShow = false;
      this.hideList = true;
    }
  }

  /**
   * 改变选中日程
   *
   * @param checkEventId 选中日程id值
   */
  private changeCheckEventId(checkEventId: number): void {
    GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, checkEventId);
  }

  aboutToAppear() {
    if (this.paramsEventId > 0) {
      this.showEventId = this.paramsEventId;
    }
    if (this.paramsDisplayStartMills > 0 && this.paramsDisplayEndMills > 0) {
      this.displayMills = this.paramsDisplayStartMills;
      this.currentDisplayStartMills = this.paramsDisplayStartMills;
      this.currentDisplayEndMills = this.paramsDisplayEndMills;
    }
    this.initDataSources();
    this.InitAccountMap()
    this.vm.subscribeEvents();
    if (this.agendaTransitionUtil.formerId === this.getGeometryId()) {
      this.onAniStart();
    }
  }

  aboutToDisappear() {
    this.vm.unsubscribeEvents();
    this.deleteDialogController = null;
    this.multiDeleteDialogController = null;
  }

  getGeometryId(): string {
    return '' + this.showEventId + '-agendaList';
  }

  // 建立数据源
  initDataSources() {
    hiTraceMeter.startTrace(traceEvents.agendaListAppear, 0);
    this.vm = new AgendaListViewModel(
      this.displayMills,
      this.calendarUuid,
      this.language,
      this.mScroller,
      this.paramsEventId,
      this.paramsDisplayStartMills,
      (showEventId: number, currentDisplayStartMills: number,
       currentDisplayEndMills: number, shareableEventCount: number, selectedAgendaCount: number,
       event: AgendaEventInfo | undefined) => {
        Log.info(TAG, `AgendaListView shareableCount ${shareableEventCount}`);
        this.shareableEventCount = shareableEventCount;
        this.vmShowDataChange(showEventId, currentDisplayStartMills,
          currentDisplayEndMills, selectedAgendaCount, event)
      });
    this.vm.init();
    hiTraceMeter.finishTrace(traceEvents.agendaListAppear, 0);
    // 视图逻辑封装到vm层
    this.vm.onActionFocusChange = (actionFocus: string) => {
      this.actionFocus = actionFocus;
    }
  }

  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.delete_this_event_title'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => this.vm.rightClickToDeleteConfirm(),
      onCancelClick: () => {
        Log.info(TAG, 'click cancel');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  // 多选删除弹框
  multiDeleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      title: CloudUtils.isCloudSyncOpened() ? $r('app.plural.delete_multiple_selected_count_msg',
        this.selectedAgendaCount, this.selectedAgendaCount) : '',
      message: CloudUtils.isCloudSyncOpened() ? $r('app.string.delete_with_cloudDevices') :
        $r('app.plural.delete_multiple_selected_count_msg', this.selectedAgendaCount, this.selectedAgendaCount),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: (): void => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.AgendaListView,
          ACTION: HiEventParamsConfirm.TRUE
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        this.confirmMultiDelete();
      },
      onCancelClick: () => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.AgendaListView,
          ACTION: HiEventParamsConfirm.FALSE
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        Log.info(TAG, 'click cancel');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  confirmMultiDelete() {
    this.vm.deleteMultiEventsConfirm();
    this.disableSelect();
  }

  /**
   * 回到今天
   */
  backToTodayMethod() {
    this.vm.onBackTodayClick();
    this.mScroller.scrollToIndex(this.vm.scrollIndex);
  }

  @Builder
  buildHeadItemContent() {
    if (!this.vm.headLoading) {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text(this.vm.headViewText)
          .fontSize(this.vm.viewTextSize)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColor)
          .id(CompId.LOAD_PRE_AGENDA_TEXT)
          .focusable(true)
          .focusBox({
            margin: LengthMetrics.px(12),
          })
      }
      .onClick(() => {
        this.vm.onHeadTextClick();
      })
      .backgroundColor($r('sys.color.background_secondary'))
      .padding({
        top: FontSizeScaleUtils.buttonInterval(12, this.fontSizeScale),
        bottom: FontSizeScaleUtils.buttonInterval(12, this.fontSizeScale),
        left: 16,
        right: 16
      })
      .borderRadius(this.needCommerce ?
      $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level10'))
    } else {
      LoadingView();
    }
  }

  @Builder
  buildTailItemContent() {
    if (!this.vm.tailLoading) {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text(this.vm.tailViewText)
          .fontSize(this.vm.viewTextSize)
          .maxFontScale(BigFontSize.BIG_FONT_SIZE)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColor)
          .id(CompId.LOAD_PRE_AGENDA_TEXT)
      }
      .onClick(() => {
        this.vm.onTailTextClick();
      })
      .backgroundColor($r('sys.color.background_secondary'))
      .padding({
        top: 12,
        bottom: 12,
        left: 16,
        right: 16
      })
      .borderRadius(this.needCommerce ?
      $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level10'))
    } else {
      LoadingView();
    }
  }

  @Builder
  existMenu(item: AgendaListItemViewModel) {
    if (this.isRightClickToDeleteAllowed && !item.isHoliday()) {
      AgendaMenu({
        isSmallWindow: false,
        info: item,
        menuOpts: this.getAgendaMenuOpts(item),
        menuEditOpts: generateAgendaEditOption(item),
        onCopyHandle: () => {
          emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': item?.mId } });
        },
        onDeleteHandle: () => {
          ServiceManager.getInstance()
            .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
            service?.notifyDeleteEvent(item.mId, item.mBegin, true);
          });
        },
        onShareHandle: () => {
          this.mAgendaOperateHelper.shareAgenda(item, FromType.UNKNOWN, item.getEditAblePropStr());
        },
        onEditHandle: (editType: number) => {
          this.onEditHandle(editType, item);
        },
        onMultiselectHandle: () => {
          item.isSelected = true;
          this.selectable = true;
        },
      })
    }
  }

  private onEditHandle(opt: AgendaEditMenuOpt, item: AgendaListItemViewModel) {
    const instanceStartMills = item.mBegin;
    const instanceEndMills = item.mEnd;
    switch (opt) {
      case AgendaEditMenuOpt.ALL_AGENDA: {
        this.mAgendaOperateHelper.editAgenda(item);
        break;
      }
      case AgendaEditMenuOpt.ONLY_THIS_AGENDA: {
        this.mAgendaOperateHelper.editThisAgenda(item, instanceStartMills, instanceEndMills);
        break;
      }
      case AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA: {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(item, instanceStartMills, instanceEndMills);
        break;
      }
    }
  }

  private async InitAccountMap() {
    let accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    this.accountMap = CommonService.INSTANCE.getAccountMap(accounts);
  }

  private getAgendaMenuOpts(item: AgendaListItemViewModel) {
    let menuOpt: AgendaMenuOpt[] = [];
    menuOpt.push(AgendaMenuOpt.COPY);

    const accountType = this.accountMap.get(item.mCalendarId)?.accountType;
    if (!item.mHwextServiceType && accountType && accountType !== CalendarAccountType.EMAIL_ACCOUNT_TYPE) {
      menuOpt.push(AgendaMenuOpt.SHARE);
    }
    if (item.mHwextServiceType === 'Meeting') {
      menuOpt.push(AgendaMenuOpt.SHARE);
    }
    menuOpt.push((AgendaMenuOpt.MULTISELECT));

    if (!item.mHwextServiceType && accountType && accountType !== CalendarAccountType.EMAIL_ACCOUNT_TYPE) {
      menuOpt.push(AgendaMenuOpt.EDIT);
    }
    menuOpt.push(AgendaMenuOpt.DELETE);
    return menuOpt;
  }

  @Builder
  buildAgendaList() {
    LazyForEach(this.vm.dataSources, (item: AgendaListItemViewModel, index: number) => {
      ListItem() {
        AgendaItem({
          info: item,
          selectable: this.selectable,
          showEventId: this.showEventId,
          viewType: TabType.AGENDA,
          searchText: $searchText,
          sourceType: AgendaDetailSource.AGENDA_LIST,
          isChecked: this.isItemChecked(item) && !ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode),
          onItemClick: () => {
            this.vm.onItemClick(item);
            if (this.keyCtrlState && !item.isHoliday()) {
              this.selectable = true;
              item.isSelected = true;
            }
          },
          onDeleteSuccess: () => {
          },
          previewFromType: PreviewFromType.AGENDA_LIST
        })
      }
      .bindContextMenu(this.existMenu(item), ResponseType.RightClick)
      .width('100%')
      .focusOnTouch(true)
      .focusable(true)
      .keyboardShortcut('d', [ModifierKey.CTRL], () => {
        Log.info(TAG, 'press d + ctrl');
        if (this.vm.selectedAgenda !== undefined) {
          this.onKeyEventDel();
        }
      })
    }, (item: AgendaListItemViewModel) => `${item.getEditAblePropStr()}-${this.selectable}`)
  }

  isItemChecked(item: AgendaEventInfo) {
    return this.vm.selectedAgenda?.mId === item.mId && this.vm.selectedAgenda?.mBegin === item.mBegin;
  }

  @Builder
  BuildLoadingView() {
    Column() {
      LoadingView();
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  buildAgendaArea() {
    List({ initialIndex: this.vm.scrollIndex, scroller: this.mScroller, space: 12 }) {
      ListItem() {
        this.buildHeadItemContent()
      }
      .width('100%')
      .visibility(this.vm.headViewText ? Visibility.Visible : Visibility.Hidden)

      this.buildAgendaList();
      ListItem() {
        this.buildTailItemContent();
      }
      .width('100%')
      .margin({ bottom: $r('sys.float.padding_level12') })
      .visibility(this.vm.tailViewText ? Visibility.Visible : Visibility.Hidden)
    }
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .focusOnTouch(true)
    .focusable(true)
    .onKeyEvent(this.keyEventHandler)
    .id(CompId.AGENDA_LIST_KEY)
    .height('100%')
    .width(`calc(100% - ${SCROLL_BAR_OFFSET}vp)`)
    .alignListItem(ListItemAlign.Center)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .scrollBar(BarState.Off)
    .onScrollStart(() => {
      Log.info(TAG, 'onScrollIndex In AGENDA LIST VIEW.');
      hiTraceMeter.startTrace(traceEvents.agendaListSwipe, 0)
      this.vm.onActionFocusChange(FocusPage.AGENDA_LIST_VIEW);
    })
    .onScrollStop(() => {
      hiTraceMeter.finishTrace(traceEvents.agendaListSwipe, 0)
    })
    .onScrollIndex((start: number, end: number) => {
      this.onScrollIndexHandler(start, end);
    })
    .onAppear(() => {
      focusControl.requestFocus(CompId.AGENDA_LIST_KEY)
    })
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      this.listWidth = Number(newValue.width);
      this.vm.updateListHeight(Number(newValue.height));
    })
    .onReachEnd(() => {
      if (this.vm.isUpSlideQuerying) {
        return;
      }
      this.vm.handleUpSlide();
    })
    .gesture(
      // 手势滑动
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent | undefined) => {
          this.panGestureAction(SlideActionType.START, event);
        })
        .onActionUpdate((event: GestureEvent | undefined) => {
          this.panGestureAction(SlideActionType.UPDATE, event);
        })
        .onActionEnd((event?: GestureEvent) => {
          this.panGestureAction(SlideActionType.END, event);
        }),
      GestureMask.Normal
    )
    .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer,
      recognizers: Array<GestureRecognizer>) => {
      if (current.isBuiltIn() &&
        current.getType() == GestureControl.GestureType.PAN_GESTURE) { // 系统内置手势且手势为滑动
        if (!this.selectable) { // 非多选状态
          return GestureJudgeResult.CONTINUE;
        }
        if (!event || !event.fingerList || event.fingerList.length === 0) { // 不存在手指信息
          return GestureJudgeResult.CONTINUE;
        }
        const nowFinger = event.fingerList[0];
        if (!nowFinger) {
          Log.error(TAG, 'fingerList index 0 get finger is undefined');
          return GestureJudgeResult.CONTINUE;
        }
        const isInHotArea =
          I18nUtil.isUyghurLanguage(this.language) ? nowFinger.localX < this.vm.CHECK_BOX_WIDTH :
            nowFinger.localX > this.listWidth - this.vm.CHECK_BOX_WIDTH;
        if (!isInHotArea) { // 未处于右侧热区内(维语为左侧)
          return GestureJudgeResult.CONTINUE;
        }
        return GestureJudgeResult.REJECT; // 禁用list滑动
      }
      return GestureJudgeResult.CONTINUE;
    })

    ScrollBar({ scroller: this.mScroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
      .width(SCROLL_BAR_OFFSET)
      .margin({ bottom: 28 })
  }

  build() {
    if (this.vm.isDataReady) {
      Stack() {
        Column() {
          Row() {
            this.buildAgendaArea();
          }
          .layoutWeight(this.selectable ? 0.84 : 1)
          .padding({ start: LengthMetrics.vp(16) })

          if (this.selectable) {
            MultiBottomTab({
              canShare: this.shareableEventCount > 0,
              allAgendaCount: this.vm.allAgendaCount,
              showSelectAll: true,
              selectAllButtonAvailable: this.vm.selectAllButtonAvailable,
              selectable: this.selectable,
              selectedCount: this.selectedAgendaCount,
              isNeedMargin: true,
              onClickDelete: (): void => this.onMultiDeleteClick(),
              onClickShare: (): Promise<void> => this.onMultiShareClick(),
              confirmMutiDel: (): void => this.confirmMultiDelete(),
            })
          }
        }

        Column() {
          Image($r('app.media.ic_no_agenda'))
            .width(96)
            .height(96)
            .margin({
              top: 80,
              bottom: 8
            })
            .draggable(false)
            .edgeAntialiasing(this.antialiasingNumber)
          Text($r('app.string.agenda_empty_text'))
            .fontSize(14)
            .opacity(0.6)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
        }
        .visibility(this.vm.agendaResult.length === 0 && this.showEventId == -1 ? Visibility.Visible : Visibility.None)
      }
      .id(CompId.AGENDA_LIST_STACK)
      .layoutWeight(2)
      .width('100%')
      .onSizeChange((oldValue, newValue) => {
        if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
          return;
        }
        this.handleSizeChange(oldValue, newValue);
      })
    } else {
      this.BuildLoadingView();
    }
  }

  //del键触发删除操作
  onKeyEventDel() {
    Log.info(TAG, 'press key del');
    if (!this.vm.selectedAgenda) {
      return;
    }
    if (this.vm.selectedAgenda.isHoliday()) {
      return;
    }
    ServiceManager.getInstance()
      .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
      service?.notifyDeleteEvent(this.vm.selectedAgenda?.mId || 0, this.vm.selectedAgenda?.mBegin || 0, true);
    });
  }

  private keyEventHandler: (event: KeyEvent) => boolean = (event: KeyEvent) => {
    if (event.keyCode === KeyCode.KEYCODE_FORWARD_DEL && event.type === KeyType.Down) {
      this.onKeyEventDel();
    } else if ((event.keyCode === KeyCode.KEYCODE_DPAD_UP ||
      event.keyCode == KeyCode.KEYCODE_DPAD_DOWN) && event.type === KeyType.Down) {
      this.vm.onKeyPress(event.keyCode)
    } else if (event.keyCode === KeyCode.KEYCODE_ESCAPE && event.type === KeyType.Down) {
      if (this.selectable) {
        this.selectable = false;
        //将焦点放在日程列表，防止无法响应键盘事件
        focusControl.requestFocus(CompId.AGENDA_LIST_KEY);
      } else {
        this.navPathStack.pop();
      }
      return true;
    }
    return false;
  }

  onScrollIndexHandler(start: number, end: number) {
    this.vm.updateScrollStartIndex(start, end);
    if (start === 0 && this.vm.agendaResult.length > 10) {
      this.vm.handlePullDown();
    }
    ThrottleFunction.instance().debounceInstant(TAG, (): void => {
      if (!this.selectable) {
        this.vm.changeBackTodayStatus(start, end);
        this.isShowBackToToday = this.vm.isShowBackToday;
      }
      if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
        this.vm.changeDisplayDate(start);
      }
    }, DELAY)
  }

  handleSizeChange(oldValue: SizeOptions, newValue: SizeOptions): void {
    if (oldValue.width === newValue.width && oldValue.height === newValue.height) {
      return;
    }
    emitter.emit({ eventId: CommonInnerEvent.MONTH_VIEW_LAYOUT_CHANGE });
  }

  /**
   * 滑动多选操作
   * @param type 0：start,1:update,2:end
   * @param event
   */
  panGestureAction(type: SlideActionType, event: GestureEvent | undefined): void {
    // 非多选情况下不操作
    if (!this.selectable) {
      return;
    }
    // 不存在手指输入则不操作
    if (!event || !event.fingerList || event.fingerList.length === 0) {
      Log.error(TAG, 'event or fingerList is empty');
      return;
    }
    const nowFinger = event.fingerList[0];
    if (!nowFinger) { // 额外判断,可能存在fingerList的第一个参数为空的情况
      Log.error(TAG, 'fingerList index 0 get finger is undefined');
      return;
    }
    if (type === SlideActionType.START) { // 初始化当前已选择日程数量
      this.vm.nowSelectCount = this.selectedAgendaCount;
    }
    this.vm.panGestureAction(type, nowFinger);
    this.selectedAgendaCount = this.vm.nowSelectCount; // 日程数量回填
  }
}