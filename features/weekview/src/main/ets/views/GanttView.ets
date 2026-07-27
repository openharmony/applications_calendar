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

import { GanttBlockType, GanttBlockViewModel } from '../viewmodel/GanttBlockViewModel';
import { GanttLineViewModel, GanttViewModel } from '../viewmodel/GanttViewModel';
import { RootViewModel } from '../viewmodel/RootViewModel';
import { GlobalData } from '@app/common/src/main/ets/data/GlobalData';
import { GlobalDataKeys } from '@app/common/src/main/ets/data/GlobalDataKeys';
import {
  AgendaEventInfo,
  behaviorEvents,
  BigFontSize,
  CalendarContract,
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  EventService,
  FontSizeScaleUtils,
  GlobalThis,
  HiEventParamsConfirm,
  Log,
  NavPathManager,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  statisticEvents,
  PreviewFromType,
  TabType,
  ThrottleFunction,
  VibratorUtils,
  VibrationType,
  ViewCallInterceptorHolder,
  isSyncAbleAccount,
  CloudUtils,
  CalendarService,
  CommonService,
  AccountUtils,
  MILLS_PER_DAY,
  MILLS_PER_HOUR,
  AgendaAbilityManager,
  CalendarDate,
  ServiceManager,
  ServiceEnum,
  AgendaDeleteService,
} from '@app/common';
import { CommonTextDialog, } from '@app/common.components'
import {
  generateAgendaOption,
  AgendaMenuOpt,
  AgendaPopupContent,
  AgendaOperateHelper,
  AgendaMenu,
  AgendaEditMenuOpt,
  generateAgendaEditOption
} from '@app/feature.agenda'
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import prompt from '@system.prompt';
import emitter from '@ohos.events.emitter';
import { RootModel } from '../model/RootModel';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { buildUDC, verifyDataFromUdmf, parseDataFromUdmf } from '@app/common/src/main/ets/default/util/ShareUtils';
import { NewGanttBlockView } from './NewGanttBlockView';
import {
  CopyHelper,
  DeleteAgendaRadio as ChangeRepeatAgendaRadio,
  DeleteMode as ChangeMode,
  SaveTimeType,
  CreateAgendaPageSource,
  CreatePopupContent,
  PreviewContent,
  getPopOffsetY
} from '@app/feature.agenda';
import { DayModel } from '../model/DayModel';
import {
  BackPressInterceptor,
  OnHidden,
  OnShown
} from '@app/common/src/main/ets/commoncapability/view/ViewCallInterceptorHolder';
import { displaySync } from '@kit.ArkGraphics2D';
import { i18n } from '@kit.LocalizationKit';
import { LengthMetrics } from '@kit.ArkUI';
import { DragEventState } from './WeekView';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'GanttView';
const FIRST_FRAME = 1;
const SECOND_FRAME = 2;
const THIRD_FRAME = 3;
const HOVER_DELAY = 500; // hover显示延迟
const HOVER_LEAVE_DELAY = 200; // hover消失延迟
const GANTT_GENERAL_TRANSITION_DURING = 150; // 甘特视图的通用出入场动效时长


interface PopupStateEvent { isVisible: boolean };

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

export const GANTT_VIEW_MENU_OPTS: AgendaMenuOpt[] = [
  AgendaMenuOpt.VIEW,
  AgendaMenuOpt.COPY,
  AgendaMenuOpt.SHARE,
  AgendaMenuOpt.EDIT,
  AgendaMenuOpt.DELETE,
  AgendaMenuOpt.CREATE
];


@Component
export struct GanttView {
  @Consume navPathStack: NavPathStack;

  @Consume keyCtrlState: boolean; // Ctrl 键的状态

  @Consume rootVM: RootViewModel;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Consume isOnDropAllowed: boolean;

  // 新建弹窗内容是否被编辑过
  @State hasBeenEdited: boolean = false;

  @ObjectLink ganttVM: GanttViewModel;

  @ObjectLink ganttViewAnimate: CombineAnimateParam;

  @Provide isNotInScroll: boolean = true;

  // 当前语言
  @StorageProp('language') systemLanguage: string = '';

  // 当前甘特图在swiper中的index
  @Provide('swipeIndex') swipeIndex: number = -1;

  // 当前甘特图的视图类型：周视图/日视图
  @Prop mTabType: TabType = TabType.WEEK;

  // 当前主页的页签tabIndex
  @StorageProp('tabIndex') curTab: number = TabType.WEEK;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) isOpenAccessibilityScreenReader: boolean = false;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') navigationHeight: number = 0;

  // 窗口宽度
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  // 窗口高度
  @LocalStorageLink('windowHeight') windowHeight: number = 0;

  @State eventIsFirstRepeatAgenda: boolean = false;

  @State deleteEventIsCloudSync: boolean = false;

  @State repeatDialogTitle: string = '';

  @Consume dragEventState: DragEventState;

  private displaySync: displaySync.DisplaySync | undefined = undefined;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private needPreview: boolean = DeviceConfig.instance().config.needPreview;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  @State rightClickChosenBlock: GanttBlockViewModel | undefined = undefined;

  @State searchText: string = '';

  @State popOffsetY: number = 0;

  //删除普通日程弹窗
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      title: this.deleteEventIsCloudSync ? $r('app.string.whether_to_delete', this.repeatDialogTitle) : '',
      message: this.deleteEventIsCloudSync ? $r('app.string.delete_with_cloudDevices') :
      $r('app.string.whether_to_delete', this.repeatDialogTitle),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: async () => {
        if (!this.checkCanDelete()) {
          this.ganttVM.nowDeleteIndex++;
          this.deleteEventLoop();
          return;
        }

        await this.ganttVM.deleteNormalAgenda();
        this.ganttVM.nowDeleteIndex++;
        this.deleteEventLoop();
        this.reportPopupStatistic(
          this.ganttVM.state.selectBlock?.getInfo().mImportantEventType, HiEventParamsConfirm.TRUE)
      },
      onCancelClick: () => {
        this.ganttVM.nowDeleteIndex++;
        this.deleteEventLoop();
        this.reportPopupStatistic(
          this.ganttVM.state.selectBlock?.getInfo().mImportantEventType, HiEventParamsConfirm.FALSE)
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  // 删除重复日程弹框
  deleteRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: ChangeRepeatAgendaRadio({
      showCloudSyncTip: this.deleteEventIsCloudSync,
      confirm: async (checkValue) => {
        if (checkValue === ChangeMode.ONLY_THIS_AGENDA) {
          await this.ganttVM.deleteThisAgenda();
        } else if (checkValue === ChangeMode.THIS_AND_FUTURE_AGENDA) {
          await this.ganttVM.deleteThisAgendaAndBeyond();
        } else {
          await this.ganttVM.deleteNormalAgenda();
          this.ganttVM.allDeletedRepeatEvent.add(this.ganttVM.deleteAgendaBlocks[this.ganttVM.nowDeleteIndex].getInfo()
            .mId)
        }
        this.ganttVM.nowDeleteIndex++;
        this.deleteEventLoop();
      },
      cancel: () => {
        this.ganttVM.nowDeleteIndex++;
        this.deleteEventLoop();
      },
      title: $r('app.string.whether_to_delete', this.repeatDialogTitle),
      isFirstRepeatAgenda: this.eventIsFirstRepeatAgenda
    }),
    alignment: DialogAlignment.Center
  });

  dragRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: ChangeRepeatAgendaRadio({
      showCloudSyncTip: false,
      confirmText: $r('app.string.confirme_information'),
      confirm: (changeType) => {
        this.ganttVM.onGanttBlockDrop(changeType)
      },
      title: getContext().resourceManager.getStringSync($r('app.string.whether_to_move_event'),
        this.repeatDialogTitle),
      isFirstRepeatAgenda: this.eventIsFirstRepeatAgenda
    }),
    alignment: DialogAlignment.Center,
  });

  private readonly ROOT_BORDER_RADIUS: number = 16;

  private readonly POPUP_LIMIT_X: number = 15;

  private readonly POPUP_PHONE_WIDTH: number = 328;

  private readonly POPUP_PC_WIDTH: number = 400;

  private readonly LINE_COLOR: ResourceColor = $r('sys.color.comp_divider');

  private readonly HOUR_COLOR: ResourceColor = $r('sys.color.font_primary');

  private readonly HOUR_OPACITY: number = 0.4;

  private readonly leftClickDelay: number = 300;

  private readonly DEFAULT_MENU_WIDTH: number = 150; //默认右键弹窗宽度150

  private popupTimestamp: number = Date.now();

  // 一级菜单选项
  private menuOpts: AgendaMenuOpt[] = [];
  // 二级编辑菜单选项
  private menuEditOpts: Array<AgendaEditMenuOpt> = [];

  private popupInfo: AgendaEventInfo[] = [];

  private popupPos: Position = { x: 0, y: 0 };

  private popupPlacement: Placement = Placement.Bottom;

  private popupWidth: number = 0;

  private popupOffset: number = 0;

  @State isMenuPopup: boolean = false;

  // 是否显示新建跟手弹窗
  @State isCreatePopupShow: boolean = false;

  // 关闭新建日程跟手弹窗时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  // 是否快速新建
  private isQuickCreate: boolean = false;

  private createPageData: emitter.EventData = {};

  private leftClickCount: number = 0;

  private needSaveTime: number = 0; //是否需要保留传入时分

  private isFold: boolean = false;

  private isAllDay: boolean = false;

  myDisplaySync: displaySync.DisplaySync = displaySync.create();

  private hoverBLock: GanttBlockViewModel | undefined = undefined;

  updateStage() {
    if (this.stages == 0) {
      this.myDisplaySync.start();
      this.myDisplaySync.on('frame', (frameInfo: displaySync.IntervalInfo) => {
        this.updateStage();
      });
    }
    this.stages += 1;
    if (this.stages == THIRD_FRAME) {
      this.myDisplaySync.stop()
    }
  }

  aboutToAppear() {
    ViewCallInterceptorHolder.getInstance().addViewCallBacks(this.backPressInterceptor, this.onHidden, this.onShown);
    hiTraceMeter.startTrace(traceEvents.ganttAppear, 0);
    this.subscribeEvents();
    this.updateStage()
    hiTraceMeter.finishTrace(traceEvents.ganttAppear, 0);
  }

  aboutToDisappear() {
    ViewCallInterceptorHolder.getInstance().removeViewCallBacks(this.backPressInterceptor, this.onHidden, this.onShown);
    this.unsubscribeEvents();
    this.deleteDialogController = null;
    this.deleteRepeatAgendaDialogController = null;
    this.dragRepeatAgendaDialogController = null;
  }

  private readonly backPressInterceptor: BackPressInterceptor = (): boolean => {
    return false;
  }

  private readonly onHidden: OnHidden = () => {
  }

  private readonly onShown: OnShown = () => {
  }

  subscribeEvents(): void {
    this.keyEnterEventHandler = (): void => this.onKeyEventEnter();
    this.keyDelEventHandler = (): void => this.onKeyEventDel();
    this.keyCopyEventHandler = (data: emitter.EventData): Promise<void> => this.onKeyEventCopy(data);
    this.keyPasteEventHandler = (data: emitter.EventData): Promise<void> => this.onKeyEventPaste(data);
    emitter.on({ eventId: CommonInnerEvent.BUTTON_KEY_ENTER }, this.keyEnterEventHandler);
    emitter.on({ eventId: CommonInnerEvent.BUTTON_KEY_DEL }, this.keyDelEventHandler);
    emitter.on({ eventId: CommonInnerEvent.BUTTON_KEY_COPY }, this.keyCopyEventHandler);
    emitter.on({ eventId: CommonInnerEvent.BUTTON_KEY_PASTE }, this.keyPasteEventHandler);
  }

  unsubscribeEvents(): void {
    emitter.off(CommonInnerEvent.BUTTON_KEY_ENTER, this.keyEnterEventHandler);
    emitter.off(CommonInnerEvent.BUTTON_KEY_DEL, this.keyDelEventHandler);
    emitter.off(CommonInnerEvent.BUTTON_KEY_COPY, this.keyCopyEventHandler);
    emitter.off(CommonInnerEvent.BUTTON_KEY_PASTE, this.keyPasteEventHandler);
  }

  @Builder
  buildAllDayText() {
    Text($r('app.string.all_day'))
      .textAlign(TextAlign.Center)
      .size({ width: this.rootVM.weekTitleVM.leftWidth + 'vp', height: this.ganttVM.allDayHeight + 'vp' })
      .maxFontSize(this.rootVM.allDayTitleFontSize + 'vp')
      .minFontSize('4vp')
      .maxLines(2)
      .padding({ left: 2, right: 2 })
  }

  @Builder
  buildAllDay() {
    Row() {
      this.buildAllDayText();
      if (this.ganttVM.isShowButton) {
        SymbolGlyph(this.ganttVM.isArrowDown ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(20))
          .opacity($r('sys.float.alpha_primary'))
          .fontColor([$r('sys.color.font_primary')])
          .position(this.ganttVM.buttonPosition)
          .onClick(() => {
            this.ganttVM.onFlagChange();
          })
          .id(CompId.EXPAND_AND_COLLAPSE_ALL_DAY_AGENDA)
      }
      Row() {
        this.buildAllDayGanttViewAgendaBlock();
      }
      .gesture(
        GestureGroup(GestureMode.Parallel,
          TapGesture({ count: 2 })
            .onAction((ev) => {
              ThrottleFunction.instance()
                .debounce(TAG + this.mTabType + 'clickTwice' + this.swipeIndex,
                  () => this.onClickBlockArea(true, ev), 0);
            }),
          TapGesture({ count: 1 })
            .onAction((ev) => {
              if (this.keyCtrlState) {
                this.onCtrlClickBlockAreaFocus(true, ev)
              } else {
                // 添加防抖以防止周视图双击时唤起pop弹窗
                ThrottleFunction.instance()
                  .throttle(TAG + this.mTabType + 'clickOne' + this.swipeIndex,
                    () => this.onClickBlockAreaFocus(true, ev), 300);
              }
            }),
          LongPressGesture({ fingers: 1 })
            .onAction((ev) => {
              if (!this.keyCtrlState) {
                this.onLongPressAreaFocus(true, ev);
              }
            }),
        )
      )
      .accessibilityLevel('no')
      .onMouse((ev?) => this.onMouseHotspotArea(true, ev))
      .position({
        x: this.rootVM.isRTL ? this.rootVM.weekTitleVM.rootWidth - this.rootVM.weekTitleVM.leftWidth : this.rootVM.weekTitleVM.leftWidth
      })
      .markAnchor({
        x: this.rootVM.isRTL ? '100%' : '0%' // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
      })
      .size({ width: this.rootVM.ganttGridWidth, height: this.ganttVM.allDayHeight })
    }
    .id(CompId.WEEK_ALLDAY_AREA)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .size({ width: this.rootVM.ganttWidth, height: this.ganttVM.allDayHeight })
    .constraintSize({ minHeight: this.ganttVM.allDayHeight })
  }

  @Builder
  buildAllDayGanttViewAgendaBlock() {
    ForEach(this.ganttVM.allDayBlocks, (item: GanttBlockViewModel, index: number) => {
      if (this.ganttVM.allDayBlocks[index]) {
        GanttViewAgendaBlock({
          block: this.ganttVM.allDayBlocks[index],
          ganttVM: this.ganttVM,
          onClickContent: (event): void => {
            this.onClickBlockFocus(true, this.ganttVM.allDayBlocks[index]);
          },
          onHoverContent: this.blockHoverEventHandler,
        });
      }
    })
  }

  /**
   * 处理拖拽事件
   * @param event
   */
  private async processDataFromUdmf(event: DragEvent) {
    if (verifyDataFromUdmf(event)) {
      const eventInfo: AgendaEventInfo = await parseDataFromUdmf(event);
      this.jumpToCreateAgenda(eventInfo);
      return;
    }
  }

  /**
   * 跳转到日程列表
   * @param eventInfo 携带的预置日程信息
   */
  private jumpToCreateAgenda(eventInfo: AgendaEventInfo) {
    let eventData: emitter.EventData = {
      data: {
        'eventInfo': JSON.stringify(eventInfo),
        'intent': CreateAgendaPageSource.NLU_CREATE_AGENDA_PAGE,
        'action': 'CLICK_CREATE_EVENT'
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
  }

  /**
   * 获取传入新建弹窗的页面信息
   */
  private getCreatePageData() {
    this.createPageData = {
      data: {
        agendaDateParam: new CalendarDate(this.popupTimestamp).getTime(),
        needSaveTime: this.needSaveTime,
        isAllDay: this.isAllDay
      }
    }
  }

  /**
   * 获取传入编辑弹窗的页面信息
   * @param event 携带的预置日程信息
   * @param isEdit 是否编辑
   */
  private getEditPageData(event: AgendaEventInfo, editType: number) {
    let intent = CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE;
    if (editType === AgendaEditMenuOpt.ONLY_THIS_AGENDA) {
      intent = CreateAgendaPageSource.EDIT_THIS_AGENDA;
    } else if (editType === AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA) {
      intent = CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND;
    }
    this.createPageData = {
      data: {
        instanceStartMills: event.mBegin,
        instanceEndMills: event.mEnd,
        intent: intent,
        eventInfo: JSON.stringify(event),
      }
    }
  }

  @Builder
  buildGridRowLines() {
    ForEach(RootModel.instance().GRID_ROW_ARRAY, (_: number, index: number) => {
      Column()
        .backgroundColor(this.LINE_COLOR)
        .position({ x: 0, y: this.ganttVM.gridCellHeight * (index + 1) })
        .size({ width: this.rootVM.ganttGridWidth, height: this.ganttVM.LINE_WIDTH })
      // drop热区
      Column()
        .position({ x: 0, y: this.ganttVM.gridCellHeight * index })
        .width(this.rootVM.ganttGridWidth)
        .height(this.ganttVM.gridCellHeight)
        .onDrop(async (event: DragEvent) => {
          // 甘特图内部拖拽
          if (this.isOnDropAllowed) {
            // 外部拖入
            this.processDataFromUdmf(event);
            return;
          }
          event.useCustomDropAnimation = true;
          // 拖拽放置位置
          Log.info(TAG, 'ganttViewX ' + this.ganttVM.ganttViewDropState.ganttViewX);
          this.ganttVM.ganttViewDropState.dropCol = Math.floor((event.getWindowX() -
          this.ganttVM.ganttViewDropState.ganttViewX -
          this.rootVM.weekTitleVM.leftWidth) / this.rootVM.ganttCellWidth)

          this.ganttVM.ganttViewDropState.dropRow = index;

          this.ganttVM.ganttViewDropState.dropEventId = this.dragEventState.dragEventId;
          this.ganttVM.ganttViewDropState.dropEventInstanceStartMill = this.dragEventState.dragEventInstanceStartMill;

          this.ganttVM.ganttViewDropState.dropEventInfo =
            await EventService.INSTANCE.queryEventById(this.ganttVM.ganttViewDropState.dropEventId)

          if (!this.ganttVM.ganttViewDropState.dropEventInfo) {
            Log.info(TAG, 'dropEvent is null');
            return;
          }
          if (!this.checkCanDrop(event)) {
            return;
          }
          // 弹窗文字参数赋值
          this.eventIsFirstRepeatAgenda =
            AgendaEventInfo.isFirstRepeatAgenda(this.ganttVM.ganttViewDropState.dropEventInfo,
              this.ganttVM.ganttViewDropState.dropEventInstanceStartMill)
          this.repeatDialogTitle = this.ganttVM.ganttViewDropState.dropEventInfo.mTitle;

          if (this.ganttVM.ganttViewDropState.dropEventInfo.isRepeatEvent()) {
            this.dragRepeatAgendaDialogController?.open()
          } else {
            this.ganttVM.onGanttBlockDrop();
          }
        })
    })
  }

  checkCanDrop(event: DragEvent): boolean {
    if (this.ganttVM.ganttViewDropState.dropEventInfo.mHwextServiceType) {
      prompt.showToast({
        message: GlobalThis.getResourceStr($r('app.string.service_event_cannot_be_edited'),
          i18n.System.getSystemLanguage())
      })
      event.setResult(DragResult.DRAG_CANCELED)
      return false;
    }

    if (this.dragEventState.dragEventIsMultiDayEvent) {
      prompt.showToast({
        message: GlobalThis.getResourceStr($r('app.string.unable_to_drag_cross_day_event'),
          i18n.System.getSystemLanguage())
      })
      event.setResult(DragResult.DRAG_CANCELED)
      return false;
    }

    if (this.ganttVM.ganttViewDropState.dropEventInfo.mIsAllDay ||
    this.ganttVM.ganttViewDropState.dropEventInfo.isHoliday() ||
      this.ganttVM.ganttViewDropState.dropEventInfo.mId === -1) {
      prompt.showToast({
        message: GlobalThis.getResourceStr($r('app.string.unable_to_drag_all_day_event'),
          i18n.System.getSystemLanguage())
      })
      event.setResult(DragResult.DRAG_CANCELED)
      return false;
    }
    return true;
  }

  @Builder
  buildGridColumnLines() {
    ForEach(RootModel.instance().WEEK_ROW_ARRAY, (_: number, index: number) => {
      Column()
        .backgroundColor(this.LINE_COLOR)
        .position({ x: this.rootVM.ganttCellWidth * index, y: '-6' })
        .size({ width: this.ganttVM.LINE_WIDTH, height: 'calc(100% + 6vp)' })
    })
  }

  @Builder
  buildAccessibilityNode() {
    ForEach(RootModel.instance().GRID_ROW_ARRAY, (_: number, yIndex: number) => {
      if (this.rootVM.isWeekView()) {
        ForEach(RootModel.instance().WEEK_ARRAY, (_: number, xIndex: number) => {
          this.buildAccessibilityNodeForView(xIndex, yIndex)
        })
      } else {
        // 日视图，只构建一天即可
        this.buildAccessibilityNodeForView(0, yIndex)
      }
    })
  }

  @Builder
  buildAccessibilityNodeForView(xIndex: number, yIndex: number) {
    Column()
      .position({ x: this.rootVM.ganttCellWidth * xIndex, y: this.ganttVM.gridCellHeight * (yIndex) })
      .size({ width: this.rootVM.ganttCellWidth, height: this.ganttVM.gridCellHeight })
      .onClick(() => {
        let now: CalendarDate = this.getNodeDay(xIndex, yIndex);
        let eventData: emitter.EventData = {
          data: {
            needSaveTime: SaveTimeType.SAVE_ALL_TIME,
            agendaDateParam: now.getTime(),
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
      })
      .accessibilityLevel('yes')  //单体可被识别
      .accessibilityText(this.getAccessibilityText(xIndex, yIndex))
  }

  private getNodeDay(x: number, y: number) {
    let now: CalendarDate = new CalendarDate();
    if (!this.rootVM.isWeekView()) {
      now.setTime(RootModel.instance().displayDate)
    } else {
      let dateVM = this.rootVM.dateVMs[this.swipeIndex];
      let dayModel: DayModel = dateVM.cellVMs[x].getDayModel();
      now.setFullYear(dayModel.solarYear);
      now.setMonth(dayModel.solarMonth - 1);
      now.setDate(dayModel.solarDay);
    }
    now.setHours(y, 0, 0, 0);
    return now;
  }

  getAccessibilityText(x: number, y: number): string {
    let now: CalendarDate = this.getNodeDay(x, y);
    let option: Record<string, string | boolean> = {
      'month': 'long',
      'day': 'numeric',
      'hour': '2-digit',
      'minute': '2-digit',
      'hour12': true
    };
    let startDate = DateUtil.intlDateFormat(now, option);
    now.setHours(y + 1, 0, 0, 0)
    option = { 'hour': '2-digit', 'minute': '2-digit', 'hour12': true };
    let endDate = DateUtil.intlDateFormat(now, option);
    return GlobalThis.getResourceStr($r('app.string.peek_create_agenda')) + startDate + '至' + endDate;
  }

  // 甘特图缩放打点
  reportGanttScaleChange() {
    let params: ReportHiEventParams = {
      SOURCE_PAGE: this.mTabType
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.changeGanttScale, params);
  }

  @Builder
  buildHours() {
    GanttLineView({
      lineVM: this.ganttVM.ganttLineVM,
      ganttVM: this.ganttVM
    })
  }

  @Builder
  buildTimeLine() {
    GanttViewTimeLine({
      rootVM: this.rootVM,
      ganttVM: this.ganttVM
    })
  }

  @Builder
  buildNewAgendaBlock() {
    NewGanttBlockView({
      viewModel: this.ganttVM.addBlockVM,
      openCreatePop: this.openCreatePop,
    })
  }

  @Builder
  buildGridGantt() {
    Column() {
      if (this.stages > 0) {
        this.buildHours()
        if (this.ganttVM.needShowTimeLine) {
          this.buildTimeLine();
        }
      }

      Column() {
        if (this.stages >= FIRST_FRAME) {
          this.buildGridRowLines()
          if (this.rootVM.isWeekView()) {
            this.buildGridColumnLines();
          }
        }
        if (this.stages >= SECOND_FRAME) {
          if (this.isOpenAccessibilityScreenReader) {
            this.buildAccessibilityNode();
          }
          this.buildGanttViewAgendaBlock();
        }
        if (this.stages >= THIRD_FRAME) {
          this.buildNewAgendaBlock()
        }
      }
      .gesture(
        GestureGroup(GestureMode.Exclusive, // 设置排斥手势组用于区分长按和单击操作
          GestureGroup(GestureMode.Parallel,
            TapGesture({ count: 2 })
              .onAction((ev) => {
                ThrottleFunction.instance()
                  .debounce(TAG + this.mTabType + 'clickTwice' + this.swipeIndex,
                    () => this.onClickBlockArea(false, ev), 0);
              }),
            TapGesture({ count: 1 })
              .onAction((ev) => {
                if (this.keyCtrlState) {
                  this.onCtrlClickBlockAreaFocus(false, ev)
                } else {
                  // 添加防抖以防止周视图双击时唤起pop弹窗
                  ThrottleFunction.instance()
                    .throttle(TAG + this.mTabType + 'clickOne' + this.swipeIndex,
                      () => this.onClickBlockAreaFocus(false, ev), 300);
                }
              })),
          LongPressGesture({ fingers: 1 })
            .onAction((ev) => {
              if (!this.keyCtrlState) {
                this.onLongPressAreaFocus(false, ev);
              }
            }),
        ))
      .accessibilityLevel('no') //整体不可别识别
      .onMouse((ev?) => this.onMouseHotspotArea(false, ev))
      .size({ width: this.rootVM.ganttGridWidth, height: this.ganttVM.gridHeight })
      .position({
        x: this.rootVM.isRTL ? this.rootVM.ganttWidth - this.rootVM.weekTitleVM.leftWidth : this.rootVM.weekTitleVM.leftWidth,
        y: this.ganttVM.GRID_MARGIN_TOP
      })
      .markAnchor({
        x: this.rootVM.isRTL ? '100%' : '0%' // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
      })
    }
    .id(CompId.GRID_GANTT)
    .borderRadius($r('sys.float.corner_radius_level8'))
    .size({
      width: this.rootVM.ganttWidth,
      height: this.ganttVM.gridWrapperHeight + (this.navigationHeight > 0 ? RootModel.instance().GRID_NAVI_MARGIN : 0)
    })
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PinchGesture({ fingers: 2 })
          .onActionStart((event: GestureEvent) => {
            this.isNotInScroll = false;
            this.ganttVM.initOriginalGanttViewScale(true, event?.pinchCenterY);
          })
          .onActionUpdate((event: GestureEvent) => {
            this.ganttVM.updateGanttViewScale(event.scale);
          })
          .onActionEnd(() => {
            this.finishPinch();
          })
          .onActionCancel(() => {
            this.finishPinch();
          })))
    .onAreaChange((ov: Area, nv: Area) => {
      this.ganttVM.ganttViewDropState.ganttViewX = nv.globalPosition.x as number;
    })
  }

  @Builder
  buildGanttViewAgendaBlock() {
    ForEach(this.ganttVM.normalBlocks, (item: GanttBlockViewModel, index: number) => {
      if (this.ganttVM.normalBlocks[index]) {
        GanttViewAgendaBlock({
          block: this.ganttVM.normalBlocks[index],
          ganttVM: this.ganttVM,
          onClickContent: (event): void => {
            this.onClickBlockFocus(false, this.ganttVM.normalBlocks[index]);
          },
          onHoverContent: this.blockHoverEventHandler,
        });
      }
    })
  }

  private finishPinch() {
    // 捏合手势结束时，发送广播通知周日甘特视图变更缩放比例
    this.ganttVM.emitterGanttScale();
    this.isNotInScroll = true;
    this.reportGanttScaleChange();
  }

  // 长按新建
  onLongPressAreaFocus(isAllDay: boolean, ev?: GestureEvent): void {
    if (!ev || !ev.fingerList || !ev.fingerList[0]) {
      return;
    }
    this.ganttVM.hideAddAgendaBlock();
    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const positionX = ev.fingerList[0].localX;
    const positionY = ev.fingerList[0].localY;
    const chosenBlock = allBlocks.filter(block => block.containPoint(positionX, positionY))[0];
    this.popupTimestamp = this.ganttVM.transPositionToStamp(positionX, positionY, isAllDay);
    if (!chosenBlock) {
      VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
      if (this.isCreateAgendaPopup) {
        this.showQuickCreatePop(isAllDay, positionX, positionY)
      } else {
        let eventData: emitter.EventData = {
          data: {
            needSaveTime: isAllDay ? SaveTimeType.DEFAULT : SaveTimeType.SAVE_START_TIME,
            agendaDateParam: this.popupTimestamp,
          }
        };
        emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
      }
    }
  }

  // click once
  onClickBlockAreaFocus(isAllDay: boolean, ev?: GestureEvent): void {
    if (!ev || !ev.fingerList || !ev.fingerList[0]) {
      Log.info(TAG, `no ev return`);
      return;
    }
    this.ganttVM.hideAddAgendaBlock();
    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const positionX = ev.fingerList[0].localX;
    const positionY = ev.fingerList[0].localY;
    const chosenBlock = allBlocks.filter(block => block.containPoint(positionX, positionY))[0];

    if (!chosenBlock) {
      if (!isAllDay) {
        this.ganttVM.showAddAgendaBlock(positionX, positionY);
      } else {
        this.ganttVM.hideAddAgendaBlock();
      }
      Log.info(TAG, `no chosenBlock`);
      return;
    }
    this.ganttVM.hideAddAgendaBlock();
    this.ganttVM.showPopup = false;
    // 非PC，重叠日程块，日视图分栏场景，直接跳转日程详情
    if (!this.needCommerce && (!this.rootVM.isDivide || this.rootVM.isWeekView()) && !chosenBlock.isFold()) {
      this.onClickBlockArea(isAllDay, ev);
      return;
    }
    this.hoverCheck(false, chosenBlock, 0);
    this.setHoverPopupPlacement(chosenBlock);
    this.popupTimestamp = this.ganttVM.transPositionToStamp(positionX, positionY, isAllDay);
    this.popupOffset = this.ganttVM.scrollOffsetY;
    this.setPopupPlacement(positionX, isAllDay);
    this.ganttVM.state.selectBlock = chosenBlock;

    this.onClearFocus(isAllDay ? '' : this.ganttVM.state.selectBlock.key);
    this.ganttVM.state.selectBlock.isFocus = true;

    if (!chosenBlock.isFold()) {
      this.rootVM.selectAgendaInfo = chosenBlock.getInfo();
      focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //尝试重新聚焦到日期标题上
    }


    // 日视图普通日程块，通知AgendaDetail刷新
    if (!this.rootVM.isWeekView() && !chosenBlock.getInfo()?.mIsHoliday) {
      this.ganttVM.eventToRefreshDetail(chosenBlock.getInfo());
    }

    if (this.rootVM.isDivide && !chosenBlock.isFold()) {
      ReportUtil.reportStatisticEvent(statisticEvents.dayViewAgendaDetail);
      return;
    }

    ThrottleFunction.instance()
      .debounce(TAG + this.mTabType + 'clickTwice' + this.swipeIndex,
        () => {
          this.popupInfo = chosenBlock.getInfoList();
          this.isFold = chosenBlock.isFold();
          this.isMenuPopup = false;
          this.setHoverPopupPlacement(chosenBlock);
          this.setPopupWidth();
          this.isCreatePopupShow = false;
          this.ganttVM.showPopup = true;
        }, 300);
  }

  onCtrlClickBlockAreaFocus(isAllDay: boolean, ev?: GestureEvent): void {
    if (!ev || !ev.fingerList || !ev.fingerList[0]) {
      return;
    }
    this.ganttVM.hideAddAgendaBlock();
    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const positionX = ev.fingerList[0].localX;
    const positionY = ev.fingerList[0].localY;
    const chosenBlock = allBlocks.filter(block => block.containPoint(positionX, positionY))[0];
    // 非可选中块，直接返回
    if (!chosenBlock) {
      return;
    }

    //日视图节假日日程块不需要做操作
    if (!this.rootVM.isWeekView() && chosenBlock.getInfo()?.mIsHoliday) {
      return;
    }
    // 折叠块不可多选
    if (chosenBlock.isFold()) {
      return;
    }

    this.ganttVM.state.selectBlock = chosenBlock;

    if (chosenBlock.isFocus) {
      chosenBlock.isFocus = false;

    } else {
      chosenBlock.isFocus = true;
    }
  }

  onClickBlockFocus(isAllDay: boolean, chosenBlock: GanttBlockViewModel): void {
    if (!chosenBlock) {
      Log.warn(TAG, 'onClickBlockFocus chosenBlock is null');
      return;
    }
    this.ganttVM.hideAddAgendaBlock();
    let x = chosenBlock.x + chosenBlock.width / 2;
    let y = chosenBlock.y + chosenBlock.height / 2;
    this.setHoverPopupPlacement(chosenBlock);
    this.popupTimestamp = this.ganttVM.transPositionToStamp(x, y, isAllDay);
    this.setPopupPlacement(chosenBlock.x, isAllDay);
    this.ganttVM.state.selectBlock = chosenBlock;

    this.onClearFocus(isAllDay ? '' : this.ganttVM.state.selectBlock.key);
    this.ganttVM.state.selectBlock.isFocus = true;

    if (!chosenBlock.isFold()) {
      this.rootVM.selectAgendaInfo = chosenBlock.getInfo();
      focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //尝试重新聚焦到日期标题上
    }

    //日视图节假日日程块不需要做操作
    if (!this.rootVM.isWeekView() && chosenBlock.getInfo()?.mIsHoliday) {
      return;
    }

    // 日视图普通日程块，通知AgendaDetail刷新
    if (!this.rootVM.isWeekView() && !chosenBlock.getInfo()?.mIsHoliday) {
      this.ganttVM.eventToRefreshDetail(chosenBlock.getInfo());
    }

    //非分屏状态日视图点击非折叠非节假日的日程块需要跳转日程详情
    if (!this.rootVM.isDivide && !this.rootVM.isWeekView() && !chosenBlock.isFold()) {
      this.toDetailPage(chosenBlock.getInfo());
      return;
    }

    if (this.rootVM.isDivide && !chosenBlock.isFold()) {
      ReportUtil.reportStatisticEvent(statisticEvents.dayViewAgendaDetail);
      return;
    }

    this.popupInfo = chosenBlock.getInfoList();
    this.isFold = chosenBlock.isFold();
    this.isMenuPopup = false;
    this.setPopupWidth();
    this.isCreatePopupShow = false;
    this.ganttVM.showPopup = true;
  }

  onClickBlockArea(isAllDay: boolean, ev?: GestureEvent): void {
    if (!ev || !ev.fingerList || !ev.fingerList[0]) {
      return;
    }

    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const chosenBlock =
      allBlocks.filter(block => block.containPoint(ev.fingerList[0]?.localX, ev.fingerList[0]?.localY))[0];

    if (!chosenBlock) {
      return;
    }
    this.hoverCheck(false, chosenBlock, 0);
    this.setHoverPopupPlacement(chosenBlock);
    this.popupTimestamp = this.ganttVM.transPositionToStamp(ev.fingerList[0].localX, ev.fingerList[0].localY, isAllDay);
    this.setPopupPlacement(ev.fingerList[0].localX, isAllDay);
    this.ganttVM.state.selectBlock = chosenBlock;

    this.onClearFocus(isAllDay ? '' : this.ganttVM.state.selectBlock.key);
    this.ganttVM.state.selectBlock.isFocus = true;

    //折叠日程块不需要做操作
    if (chosenBlock.isFold()) {
      return;
    }
    this.ganttVM.showPopup = false; // 跳转前将pop弹窗关闭
    const blockInfo = chosenBlock.getInfo();

    if (AccountUtils.isBirthDayAccountById(blockInfo.mCalendarId)) {
      Log.info(TAG, 'click to contact detail');
      return;
    }

    if (this.needCommerce) { // 商务化跳转多实例窗口
      AgendaAbilityManager.getInstance()
        .startAbilityByEventId(blockInfo.mId, blockInfo.mBegin, blockInfo.mEnd, blockInfo.mIsHoliday,
          blockInfo.mTitle);
      return;
    }

    const param: Record<string, number | AgendaEventInfo> = {};
    param.id = chosenBlock.getInfo().mId;
    param.holidayInfo = chosenBlock.getInfo();
    param.instanceStartMills = chosenBlock.getInfo()?.mBegin;
    param.instanceEndMills = chosenBlock.getInfo()?.mEnd;
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: param
    });
  }

  setPopupPlacement(x: number, isAllDay: boolean): void {
    const maxBottomX: number = this.rootVM.ganttGridWidth - this.POPUP_LIMIT_X;

    if (x > maxBottomX && !isAllDay) {
      this.popupPlacement = Placement.Left;
    } else {
      this.popupPlacement = Placement.Bottom;
    }
  }

  onMouseHotspotArea(isAllDay: boolean, ev?: MouseEvent): void {
    if (!ev) {
      return;
    }

    if (ev.button === MouseButton.Right && ev.action === MouseAction.Press) {
      const windowHeight = this.windowHeight ?? 560;
      this.popOffsetY = getPopOffsetY(ev.windowY, windowHeight);
      this.onMouseRightClick(isAllDay, ev.x, ev.y);
    } else if (ev.button === MouseButton.Left && ev.action === MouseAction.Press) {
      this.leftClickCount++;
      ThrottleFunction.instance().debounce(TAG + this.mTabType + 'click' + this.swipeIndex, () => {
        this.leftClickCount = 0;
      }, this.leftClickDelay);
      if (this.leftClickCount > 1) {
        this.onMouseLeftClickTwice(isAllDay, ev.x, ev.y);
      }
    }
  }

  // 鼠标右键操作
  async onMouseRightClick(isAllDay: boolean, x: number, y: number) {
    // 用于与月视图保持一致,右键可直接点击打开其他位置的menu弹窗
    let needWait: boolean = this.isMenuPopup;

    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const chosenBlock = allBlocks.filter(block => block.containPoint(x, y))[0];
    this.popupPos = this.ganttVM.transClickPosition(x, y, isAllDay);
    this.ganttVM.hoverWidth = 1;
    this.ganttVM.hoverHeight = 1;
    this.popupTimestamp = this.ganttVM.transPositionToStamp(x, y, isAllDay);
    this.popupPlacement = Placement.Bottom;

    if (!chosenBlock || chosenBlock.isFold()) {
      this.menuOpts = [AgendaMenuOpt.CREATE];
      if (CopyHelper.instance().getStashEventInfo()) {
        this.menuOpts.push(AgendaMenuOpt.PASTE);
      }
      this.popupInfo = [];
      this.isFold = false;
    } else {
      this.popupInfo = chosenBlock.getInfoList();
      this.rightClickChosenBlock = chosenBlock;
      await this.generateAgendaOption();
      this.isFold = false;
    }

    // 右键高亮
    if (chosenBlock) {
      this.ganttVM.state.selectBlock = chosenBlock;
      this.onClearFocus(isAllDay ? '' : this.ganttVM.state.selectBlock.key);
      this.ganttVM.state.selectBlock.isFocus = true;
    }

    this.needSaveTime = isAllDay ? SaveTimeType.DEFAULT : SaveTimeType.SAVE_START_TIME;
    this.setPopupWidth();
    this.isCreatePopupShow = false;
    this.ganttVM.showPopup = false;
    // 此处防抖是为了防止单击弹出事件关闭菜单,延迟是为了在菜单打开状态下右键其他地方会优先关闭菜单导致无法响应此次右击操作所做的处理
    ThrottleFunction.instance().debounce(TAG + this.mTabType + 'clickTwice' + this.swipeIndex, () => {
      if (chosenBlock) {
        this.hoverCheck(false, chosenBlock, 0);
      }
      this.isCreatePopupShow = false;
      this.ganttVM.showPopup = false;
      this.isMenuPopup = true;
    }, needWait ? 200 : 0)
    this.isAllDay = isAllDay;
  }

  async generateAgendaOption(chosenBlock: GanttBlockViewModel | undefined = undefined) {
    if (chosenBlock && chosenBlock.key === this.rightClickChosenBlock?.key && this.menuOpts.length > 0) {
      return;
    } else if (chosenBlock) {
      let event = chosenBlock.getInfo();
      this.menuOpts = await generateAgendaOption(event);
      this.menuEditOpts = generateAgendaEditOption(event);
    } else {
      let event = this.rightClickChosenBlock?.getInfo();
      this.menuOpts = await generateAgendaOption(event);
      this.menuEditOpts = generateAgendaEditOption(event);
    }
  }

  //左键双击后新建日程
  onMouseLeftClickTwice(isAllDay: boolean, x: number, y: number): void {
    const allBlocks = isAllDay ? this.ganttVM.allDayBlocks : this.ganttVM.normalBlocks;
    const chosenBlock = allBlocks.filter(block => block.containPoint(x, y))[0];
    this.popupTimestamp = this.ganttVM.transPositionToStamp(x, y, isAllDay);
    if (!chosenBlock) {
      this.showQuickCreatePop(isAllDay, x, y)
    }
  }

  showQuickCreatePop(isAllDay: boolean, x: number, y: number) {
    let eventData: emitter.EventData = {
      data: {
        needSaveTime: isAllDay ? 0 : 1,
        agendaDateParam: new CalendarDate(this.popupTimestamp).getTime(),
        isAllDay: isAllDay
      }
    };
    //TODO 需要区分小屏
    this.createPageData = eventData;
    this.popupPos = this.ganttVM.transClickPosition(x, y, isAllDay);
    this.ganttVM.hoverWidth = 1;
    this.ganttVM.hoverHeight = 1;
    this.isCreatePopupShow = true;
    this.ganttVM.showPopup = true;
  }

  //enter键触发
  onKeyEventEnter() {
    const selectBlock = this.ganttVM.state.selectBlock;
    if (this.curTab === this.mTabType && this.swipeIndex === this.rootVM.ganttSwiperIndex &&
      selectBlock !== undefined && selectBlock.isFocus) {
      //回车键触发跳转日程详情
      ReportUtil.reportStatisticEvent(statisticEvents.dayViewAgendaDetail);
      if (!selectBlock.isFold()) {

        if (this.needCommerce) { // 商务化跳转多实例窗口
          const blockInfo = selectBlock.getInfo();
          AgendaAbilityManager.getInstance()
            .startAbilityByEventId(blockInfo.mId, blockInfo.mBegin, blockInfo.mEnd, blockInfo.mIsHoliday,
              blockInfo.mTitle);
          return;
        }

        const param: Record<string, number | AgendaEventInfo> = {};
        param.id = selectBlock.getInfo()
          .mId;
        param.holidayInfo = selectBlock.getInfo();
        param.instanceStartMills = selectBlock.getInfo()?.mBegin;
        param.instanceEndMills = selectBlock.getInfo()?.mEnd;
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_DETAIL,
          routerName: RouterName.ENTRY_HAP,
          param: param
        });
        return;
      }
      this.ganttVM.scroller.scrollTo({ xOffset: 0, yOffset: this.popupOffset });
      this.popupInfo = selectBlock.getInfoList();
      this.isFold = selectBlock.isFold();
      this.isMenuPopup = false;
      this.setPopupWidth();
      this.isCreatePopupShow = false;
      this.ganttVM.showPopup = true;
    }
  }

  //动态设置Popup弹窗的宽度
  setPopupWidth() {
    if (this.isMenuPopup) {
      this.popupWidth = this.DEFAULT_MENU_WIDTH;
      return;
    }
    this.popupWidth = this.rootVM.isNeedAdapt() ? this.POPUP_PC_WIDTH : this.POPUP_PHONE_WIDTH;
    const windowWidth = this.windowWidth;
    this.popupWidth = this.popupWidth > windowWidth - this.ganttVM.BLOCK_POP_MARGIN * 2 ?
      windowWidth - this.ganttVM.BLOCK_POP_MARGIN * 2 : this.popupWidth;
  }

  //del键触发删除操作
  onKeyEventDel() {
    if (this.curTab === this.mTabType && this.swipeIndex === this.rootVM.ganttSwiperIndex) {

      Log.info(TAG, `this.ganttVM.normalBlocks.length ${this.ganttVM.normalBlocks.length}`);
      Log.info(TAG, `this.ganttVM.allDayBlocks ${this.ganttVM.allDayBlocks.length}`);

      this.ganttVM.deleteAgendaBlocks = this.ganttVM.normalBlocks.filter(e => e.isFocus)
      this.ganttVM.deleteAgendaBlocks =
        this.ganttVM.deleteAgendaBlocks.concat(this.ganttVM.allDayBlocks.filter(e => e.isFocus))
      Log.info(TAG, 'keyEventDel length' + this.ganttVM.deleteAgendaBlocks.length)
      if (this.ganttVM.deleteAgendaBlocks.length > 0) {
        this.deleteEventLoop();
      }
    }
  }

  // Ctrl+C复制响应
  async onKeyEventCopy(data: emitter.EventData) {
    if (this.curTab !== this.mTabType || this.swipeIndex !== this.rootVM.ganttSwiperIndex) {
      return;
    }
    let focusAgendaBlocks = this.ganttVM.allDayBlocks.filter(e => e.isFocus);
    focusAgendaBlocks = focusAgendaBlocks.concat(this.ganttVM.normalBlocks.filter(e => e.isFocus));
    Log.info(TAG, 'keyEventCopy length' + focusAgendaBlocks.length)
    if (focusAgendaBlocks.length == 0) {
      Log.info(TAG, 'focusAgendaBlocks is empty')
      CopyHelper.instance().clear();
      return;
    }
    let eventId = data?.data?.eventId as number;
    if (!eventId) {
      const selectBlock = focusAgendaBlocks[0];
      eventId = selectBlock.getInfo().mId;
    }
    CopyHelper.instance().copyEventInfo(eventId);
  }

  // 粘贴响应
  async onKeyEventPaste(data: emitter.EventData) {
    if (this.curTab !== this.mTabType || this.swipeIndex !== this.rootVM.ganttSwiperIndex) {
      return;
    }
    // 周日视图粘贴日程，有+块时粘贴到+块，没有时粘贴到高亮日
    if (this.ganttVM.addBlockVM.isAddShow) {
      const pasteTime = this.ganttVM.addBlockVM.ganttStartTime +
        MILLS_PER_DAY * this.ganttVM.addBlockVM.widthCount +
        this.ganttVM.addBlockVM.heightStart * MILLS_PER_HOUR;
      const pasteSuccess: boolean = await CopyHelper.instance().pasteEventInfoWithStartTime(pasteTime);
      // 粘贴成功，则+块不显示
      this.ganttVM.addBlockVM.isAddShow = !pasteSuccess;
    } else {
      CopyHelper.instance().pasteEventInfoHighLight();
    }
  }

  // 循环弹框删除逻辑
  async deleteEventLoop() {
    Log.info(TAG, 'this.ganttVM.nowDeleteIndex' + this.ganttVM.nowDeleteIndex)
    if (this.ganttVM.nowDeleteIndex < this.ganttVM.deleteAgendaBlocks.length) {
      const deleteEventInfoBlock = this.ganttVM.deleteAgendaBlocks[this.ganttVM.nowDeleteIndex];
      const deleteEventInfo = deleteEventInfoBlock.getInfo();
      this.repeatDialogTitle = deleteEventInfo.mTitle;

      if (this.ganttVM.deleteAgendaBlocks.length === 1 && !this.checkCanDelete()) {
        return;
      }

      // 如果某个重复日程已经被全部删除，则跳过该重复日程后续删除逻辑
      if (this.ganttVM.allDeletedRepeatEvent.has(deleteEventInfo.mId)) {
        this.ganttVM.nowDeleteIndex++;
        this.deleteEventLoop();
        return;
      }
      const eventInfo = await EventService.INSTANCE.queryEventById(deleteEventInfo.mId);
      // 获取删除日程账户类型
      let accounts = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
      let accountMap = CommonService.INSTANCE.getAccountMap(accounts);
      const deleteAccountType = accountMap.get(eventInfo.mCalendarId).accountType;
      this.deleteEventIsCloudSync = isSyncAbleAccount('', deleteAccountType) &&
      CloudUtils.isSupportCloudSync() && CloudUtils.isCloudSyncOpened();

      if (deleteEventInfo.isRepeatEvent()) {
        this.eventIsFirstRepeatAgenda =
          AgendaEventInfo.isFirstRepeatAgenda(eventInfo, deleteEventInfo.mBegin)
        this.deleteRepeatAgendaDialogController?.open();
      } else {
        this.deleteDialogController?.open();
      }
    } else {
      this.ganttVM.deleteAgendaBlocks = [];
      this.ganttVM.nowDeleteIndex = 0;
      this.ganttVM.allDeletedRepeatEvent = new Set();
      return;
    }
  }

  checkCanDelete(): boolean {
    const deleteEventInfoBlock = this.ganttVM.deleteAgendaBlocks[this.ganttVM.nowDeleteIndex];
    const deleteEventInfo = deleteEventInfoBlock.getInfo();
    if (deleteEventInfoBlock.type !== GanttBlockType.AGENDA || deleteEventInfo.isImportantEvent() ||
      deleteEventInfo.mImportantEventType !== CalendarContract.EventImportantType.NORMAL) {
      prompt.showToast({
        message: GlobalThis.getResourceStr($r('app.string.agenda_can_not_delete'),
          i18n.System.getSystemLanguage())
      });
      return false;
    }
    return true;
  }

  //清除获焦态
  onClearFocus(key: string) {
    this.ganttVM.allDayBlocks.forEach((item: GanttBlockViewModel) => {
      if (item.key !== key) {
        item.clearFocus();
      }
    });
    this.ganttVM.normalBlocks.forEach((item: GanttBlockViewModel) => {
      if (item.key !== key) {
        item.clearFocus();
      }
    });
  }

  // 用于hover延时弹窗的判断方法
  private hoverCheck(isHover: boolean, block: GanttBlockViewModel, delay: number = HOVER_DELAY) {
    if (isHover) {
      ThrottleFunction.instance().debounce(this.getHoverTag(block), () => {
        if (this.ganttVM.showPopup || (block.isFocus && !this.rootVM.isWeekView() && this.rootVM.isDivide)) {
          return;
        }
        const blockX = block.x + (block.width / 2);
        const blockY = block.y + (block.height / 2);
        this.popupTimestamp = this.ganttVM.transPositionToStamp(blockX, blockY, block.isAllDayAgenda);
        this.setHoverPopupPlacement(block);
        this.popupInfo = block.getInfoList();
        this.isFold = block.isFold();
        this.setPopupWidth();
        this.hoverBLock = block;
        this.isMenuPopup = false;
        this.isCreatePopupShow = false;
        this.ganttVM.isHoverPop = isHover;
      }, delay);
    } else {
      ThrottleFunction.instance().debounce(this.getHoverTag(block), () => {
        this.ganttVM.isHoverPop = isHover;
        this.hoverBLock = undefined;
      }, delay);
    }
  }

  private getHoverTag(block: GanttBlockViewModel) {
    return TAG + this.mTabType + 'clickOne' + this.swipeIndex + block.compId;
  }

  setHoverPopupPlacement(block: GanttBlockViewModel) {
    this.popupPlacement = Placement.Bottom;
    this.ganttVM.scrollOffsetY = this.ganttVM.getScrollOffsetY();
    this.popupOffset = this.ganttVM.scrollOffsetY;
    if (block.isAllDayAgenda) {
      this.popupPos = this.ganttVM.transClickPosition(block.x, block.y, block.isAllDayAgenda);
      this.ganttVM.hoverWidth = block.width;
      this.ganttVM.hoverHeight = block.height;
      return;
    }
    const offsetY = Math.max(block.y + 6, this.ganttVM.scrollOffsetY);
    this.popupPos =
      this.ganttVM.transClickPosition(block.x, offsetY, block.isAllDayAgenda);
    this.ganttVM.hoverWidth = block.width;
    const blockHeight = Math.min(this.ganttVM.scrollHeight, block.height,
      this.ganttVM.scrollHeight - block.y + this.ganttVM.scrollOffsetY,
      block.y + block.height - this.ganttVM.scrollOffsetY);
    this.ganttVM.hoverHeight = blockHeight;
  }

  reportPopupStatistic(type: number = 0, isSave: number) {
    let params: ReportHiEventParams = {
      TYPE: type,
      IS_SAVE: isSave
    }
    ReportUtil.reportStatisticEvent(statisticEvents.deleteAgendaSavePopup, params);
  }

  private openCreatePop: (data: emitter.EventData, position: Position) => void =
    (data: emitter.EventData, position: Position) => {
      this.createPageData = data;
      this.popupPos = this.ganttVM.transClickPosition(position.x as number, position.y as number, false);
      this.ganttVM.hoverWidth = 1;
      this.ganttVM.hoverHeight = 1;
      this.isCreatePopupShow = true;
      this.ganttVM.showPopup = true;
    };

  private async showCreateAgendaPop(isEdit: boolean, editType: number = 0) {
    if (isEdit) {
      if (this.popupInfo.length === 0) {
        return;
      }
      const eventInfo = this.popupInfo[0];
      // 封装提醒
      await AgendaOperateHelper.getCheckValueForEdit(eventInfo);
      this.getEditPageData(eventInfo, editType);
    } else {
      this.getCreatePageData();
    }
    this.popupPlacement = Placement.Right;
    this.isQuickCreate = false;
    this.isMenuPopup = false;
    this.isCreatePopupShow = true;
    this.ganttVM.showPopup = true;
  }

  private getPopAgendaInfo(): AgendaEventInfo | undefined {
    if (!this.popupInfo || this.popupInfo.length !== 1) {
      return undefined;
    }
    return this.popupInfo[0];
  }

  @Builder
  buildPopupContent() {
    if (this.isCreatePopupShow) {
      CreatePopupContent({
        createPageData: this.createPageData,
        isQuickCreate: this.isQuickCreate,
        discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
        onCreatePageDismiss: () => {
          this.isCreatePopupShow = false;
          this.ganttVM.showPopup = false;
          this.hasBeenEdited = false;
        },
        changeEditedFlag: () => {
          this.hasBeenEdited = true;
        }
      })
    } else if (!this.isMenuPopup && (this.ganttVM.isHoverPop || (this.ganttVM.showPopup && this.needPreview))) {
      this.previewContent();
    } else {
      this.buildAgendaPop()
    }
  }

  @Builder
  buildAgendaPop() {
    AgendaPopupContent({
      info: this.popupInfo,
      date: this.popupTimestamp,
      isSmallWindow: !this.rootVM.inDivideWindow,
      isFold: this.isFold,
      isWeekView: true,
      agendaMaxWidth: this.popupWidth,
      needSaveTime: this.needSaveTime,
      borderless: true,
      onClickContent: () => {
        this.ganttVM.showPopup = false;
        focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //尝试重新聚焦到日期标题上
      },
      onHoverHandler: (isHover: boolean) => {
        if (!this.hoverBLock || this.ganttVM.showPopup) {
          return;
        }
        this.hoverCheck(isHover, this.hoverBLock, isHover ? 0 : 100);
      },
    }).id(CompId.GANTT_VIEW_AGENDA_POP)
  }

  @Builder
  previewContentBuilder(info: AgendaEventInfo) {
    PreviewContent({
      info,
      searchText: this.searchText,
      previewFromType: PreviewFromType.MONTH_VIEW,
      displayStartMills: info?.mBegin,
      displayEndMills: info?.mEnd,
      isHoverShow: true,
      onHoverHandler: (isHover: boolean) => {
        if (!this.hoverBLock || this.ganttVM.showPopup) {
          return;
        }
        this.hoverCheck(isHover, this.hoverBLock, isHover ? 0 : 100);
      },
      onClickHandler: () => {
        this.toDetailPage(info);
        this.ganttVM.showPopup = false;
      }
    }).borderRadius($r('sys.float.corner_radius_level12'))
  }

  @Builder
  previewContent() {
    if (this.popupInfo.length > 1) {
      this.buildAgendaPop();
    } else {
      this.previewContentBuilder(this.popupInfo[0]);
    }
  }

  @Builder
  buildAgendaMenu() {
    AgendaMenu({
      info: this.popupInfo[0],
      date: this.popupTimestamp,
      isSmallWindow: false,
      menuOpts: this.menuOpts,
      menuEditOpts: this.menuEditOpts,
      onShareHandle: () => {
        const event = this.rightClickChosenBlock?.getInfo();
        if (event) {
          emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
            data: {
              compId: this.rightClickChosenBlock?.compId,
              eventIds: [event.mId]
            }
          })
        }
      },
      onCreateHandle: () => {
        this.showCreateAgendaPop(false);
      },
      onEditHandle: (editType: number) => {
        this.showCreateAgendaPop(true, editType);
      },
      onDeleteHandle: async () => {
        const selectInfo = this.getPopAgendaInfo();
        if (!selectInfo) {
          Log.error(TAG, `delete agenda get selectInfo err undefined`);
          return;
        }
        ServiceManager.getInstance()
          .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
          service?.notifyDeleteEvent(selectInfo.mId, selectInfo.mBegin, true);
        })
          .catch((err: BusinessError) => {
            Log.logErrorMsg(TAG, `delete event id : ${selectInfo.mId}, err`, err)
          });
      },
      onCopyHandle: () => {
        const selectInfo = this.getPopAgendaInfo();
        if (!selectInfo) {
          Log.error(TAG, `copy agenda get selectInfo err undefined`);
          return;
        }
        emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': selectInfo.mId } });
      },
      onPasteHandle: () => {
        CopyHelper.instance().pasteEventInfo(this.popupTimestamp);
      },
      onViewHandle: () => {
        const selectInfo = this.getPopAgendaInfo();
        if (!selectInfo) {
          Log.error(TAG, `view agenda get selectInfo err undefined`);
          return;
        }
        this.toDetailPage(selectInfo);
      }
    })
  }

  @Builder
  buildVirtualRect() {
    Rect()
      .width(this.ganttVM.hoverWidth)
      .height(this.ganttVM.hoverHeight)
      .opacity(0)
      .hitTestBehavior(HitTestMode.Transparent)
      .position(this.popupPos)
      .bindPopup((this.ganttVM.showPopup || this.ganttVM.isHoverPop) && !this.isMenuPopup, {
        builder: this.buildPopupContent(),
        placement: this.popupPlacement,
        popupColor: this.isQuickCreate ? $r('sys.color.ohos_id_color_list_card_bg') :
          this.popupInfo.length > 1 ? $r('app.color.pop_background_color') :
            this.needCommerce ? $r('sys.color.ohos_id_color_panel_bg') : $r('sys.color.comp_background_primary'),
        radius: 20,
        backgroundBlurStyle: BlurStyle.NONE,
        offset: { y: this.isCreatePopupShow && !this.isQuickCreate ? this.popOffsetY : 0 },
        maskColor: (!this.rootVM.isNeedAdapt()) ? 0x33000000 : undefined,
        mask: false,
        enableArrow: true,
        onWillDismiss: (dismiss) => {
          if (!this.isCreatePopupShow) {
            dismiss.dismiss();
            return;
          }
          if (this.isQuickCreate) {
            // 有编辑-->失焦保存日程，无编辑-->失焦不创建日程
            if (this.hasBeenEdited) {
              emitter.emit({ eventId: CommonInnerEvent.EVENT_CREATE_AGENDA });
            }
            this.isQuickCreate = false;
            dismiss.dismiss();
          } else {
            this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
          }
        },
        onStateChange: (ev: PopupStateEvent) => {
          if (!ev.isVisible) {
            this.ganttVM.showPopup = false;
            focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //尝试重新聚焦到日期标题上
            ReportUtil.reportStatisticEvent(statisticEvents.weekClickPopupNone);
          } else {
            ReportUtil.reportStatisticEvent(statisticEvents.weekClickAgenda);
          }
        },
        shadow: ShadowStyle.OUTER_DEFAULT_SM
      })
      .bindContextMenu(this.isMenuPopup, this.buildAgendaMenu(), {
        placement: Placement.BottomRight,
        onDisappear: () => {
          this.isMenuPopup = false;
        },
      })
  }

  @State stages: number = 0;

  build() {
    Column() {
      GanttViewVirtualGrid();
      this.buildAllDay();

      Column()
        .backgroundColor(this.LINE_COLOR)
        .size({ width: this.rootVM.ganttWidth, height: this.ganttVM.LINE_WIDTH })

      Scroll(this.ganttVM.scroller) {
        Column() {
          Column() {
            this.buildGridGantt();
          }
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius({
            bottomLeft: $r('sys.float.corner_radius_level8'),
            bottomRight: $r('sys.float.corner_radius_level8')
          })

          Blank()
            .height(this.needCommerce ? 16 : this.navigationHeight)
            .backgroundColor($r('sys.color.background_secondary'))
        }
      }
      .initialOffset({ yOffset: this.ganttVM.scrollOffsetY })
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .scrollBar(BarState.Off)
      .nestedScroll({ scrollBackward: NestedScrollMode.SELF_FIRST, scrollForward: NestedScrollMode.PARENT_FIRST })
      .size({ width: this.rootVM.ganttWidth, height: this.ganttVM.scrollHeight })
      .onScroll(() => {
        this.ganttVM.updateMorningAndAfternoon()
      })
      .onScrollStart(() => {
        hiTraceMeter.startTrace(traceEvents.ganttViewSwipe, 0)
        this.isNotInScroll = false;
      })
      .onScrollStop(() => {
        this.isNotInScroll = true;
        this.rootVM.updateScrollOffsetByIndex(this.swipeIndex);
        hiTraceMeter.finishTrace(traceEvents.ganttViewSwipe, 0)
      })

      this.buildVirtualRect()
    }
    .id(CompId.GANTT_VIEW_ROOT)
    .alignItems(HorizontalAlign.Start)
    .size({ width: this.rootVM.ganttWidth, height: this.rootVM.bottomHeight })
    .borderRadius({ topLeft: this.ROOT_BORDER_RADIUS, topRight: this.ROOT_BORDER_RADIUS })
    .visibility(this.ganttViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      // 创建默认透明度转场效果
      TransitionEffect.OPACITY
      // 添加平移转场效果
        .combine(TransitionEffect.translate(this.ganttViewAnimate.translateOptions)
          .animation(this.ganttViewAnimate.translateAnimateParam))
        .combine(TransitionEffect.opacity(this.ganttViewAnimate.opacity)
          .animation(this.ganttViewAnimate.opacityAnimateParam))
        .combine(TransitionEffect.scale(this.ganttViewAnimate.scaleOption)
          .animation(this.ganttViewAnimate.scaleAnimateParam))
    )
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
      if (ov.width === nv.width && ov.height === nv.height) {
        return;
      }
      Log.info(TAG, 'onSizeChange')
      this.stages = 0;
      this.updateStage();
    })

  }

  private keyEnterEventHandler: () => void = (): void => {
  };

  private keyDelEventHandler: () => void = (): void => {
  };

  //处理选中时按下复制键变化
  private keyCopyEventHandler: (data: emitter.EventData) => void = (): void => {
  };

  //处理选中时按下粘贴键变化
  private keyPasteEventHandler: (data: emitter.EventData) => void = (): void => {
  };

  //处理hover事件响应
  private blockHoverEventHandler: (isHover: boolean, block: GanttBlockViewModel) => void =
    (isHover: boolean, block: GanttBlockViewModel): void => {
      if (this.ganttVM.showPopup || this.isMenuPopup) {
        return;
      }
      this.hoverCheck(isHover, block, isHover ? HOVER_DELAY : HOVER_LEAVE_DELAY);
    };

  /**
   * 切换视图清除选中日程块的数据
   */
  private clearSelectBlocks() {
    this.ganttVM.state.selectBlock = undefined;
  }

  private async toDetailPage(info: AgendaEventInfo) {
    const isBirthday = await AccountUtils.isBirthDayAccountByIdAsync(info.mCalendarId);
    if (isBirthday) {
      return;
    }
    if (this.needCommerce) { // 商务化跳转多实例窗口
      AgendaAbilityManager.getInstance()
        .startAbilityByEventId(info.mId, info.mBegin, info.mEnd, info.mIsHoliday,
          info.mTitle);
      return;
    }
    const param: Record<string, number | AgendaEventInfo> = {};
    param.id = info.mId;
    param.holidayInfo = info;
    param.instanceStartMills = info?.mBegin;
    param.instanceEndMills = info?.mEnd;
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: param
    });
  }
}

@Component
@Reusable
export struct GanttViewAgendaBlock {
  @ObjectLink block: GanttBlockViewModel;

  @ObjectLink ganttVM: GanttViewModel;

  @Consume rootVM: RootViewModel;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Consume isOnDropAllowed: boolean;

  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) isOpenAccessibilityScreenReader: boolean = false;

  onClickContent?: (event: ClickEvent) => void;

  private agendaBlockSize = DeviceConfig.instance().config.agendaBlockFontSize;

  @StorageProp('is24HourClock') is24HourClock: boolean = false;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @Consume dragEventState: DragEventState;

  /**
   * 通用日程块修饰
   */
  @Styles
  blockGeneralStyle(){
    .transition(
      TransitionEffect.OPACITY.animation({ duration: GANTT_GENERAL_TRANSITION_DURING, curve: Curve.Sharp })
    )
    .id(this.block?.compId)
  }

  private onHoverContent: (isHover: boolean, block: GanttBlockViewModel) => void =
    (isHover: boolean, block: GanttBlockViewModel): void => {
    };

  aboutToAppear(): void {
    Log.info(TAG, "GanttViewAgendaBlock aboutToAppear")
  }

  @Builder
  buildAgendaBlock() {
    if (this.isOpenAccessibilityScreenReader) {
      this.buildAccessibilityAgendaBlock();
    } else {
      this.buildNormalAgendaBlock();
    }
  }

  @Builder
  buildNormalAgendaBlock() {
    Row() {
      Column()
        .width(this.block?.DIVIDER_WIDTH)
        .height(this.block?.height - this.ganttVM.blockSpace * 2)
        .backgroundColor(this.block?.textColor)
        .borderRadius({
          topStart: LengthMetrics.vp(this.block?.leftBorderRadius),
          bottomStart: LengthMetrics.vp(this.block?.leftBorderRadius),
        })
        .opacity(0.7);
      Column() {
        this.buildAgendaBlockText();
      }
      .padding({ start: LengthMetrics.vp(this.block?.isFold() || this.block?.isAllDayAgenda ? 0 : 2) })
      .alignSelf(ItemAlign.Start)
      .alignItems(HorizontalAlign.Start);
    }
    .justifyContent(FlexAlign.Start)
    .size({ width: this.block?.width, height: this.block?.height - this.ganttVM.blockSpace * 2 })
    .backgroundColor(this.block?.isFocus ?
      (this.isDarkMode ? this.block?.backgroundDarkFocusColor : this.block?.backgroundFocusColor) :
      (this.isDarkMode ? this.block?.backgroundDarkColor : this.block?.backgroundColor))
    .borderRadius(this.block?.rightBorderRadius)
    .clip(true)
    .markAnchor({
      x: this.rootVM.isRTL ? '100%' : '0%' // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
    })
    .position({ x: this.rootVM.isRTL ? this.rootVM.ganttGridWidth - this.block?.x : this.block?.x, y: this.block?.y })
    .hitTestBehavior(HitTestMode.Transparent)
    .onHover((isHover: boolean, event: HoverEvent) => {
      if (!this.block) {
        return;
      }
      this.onHoverContent(isHover, this.block);
    })
    .draggable(!this.block?.isFold())
    .onPreDrag((status: PreDragStatus) => {
      // READY_TO_TRIGGER_DRAG_ACTION：拖拽准备完成，可发起拖拽阶段。(按下500ms时触发)
      if (status == PreDragStatus.READY_TO_TRIGGER_DRAG_ACTION) {
        VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT); // 触发震动
      }
    })
    .onDragStart((event: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.block?.getInfo());
      this.isOnDropAllowed = false;

      const dragEventInfo = this.block?.getInfo();
      if (!dragEventInfo) {
        Log.info(TAG, 'dragEventInfo is null')
        return;
      }
      Log.info(TAG, `dragEventId ${dragEventInfo.mId}`)
      this.dragEventState.dragEventId = dragEventInfo.mId;
      this.dragEventState.dragEventInstanceStartMill = dragEventInfo.mBegin;
      this.dragEventState.dragEventIsMultiDayEvent = dragEventInfo.mIsMultiDayEvent;
    })
    .onDragEnd(() => {
      this.isOnDropAllowed = true;
    })
    .blockGeneralStyle()
  }

  @Builder
  buildAccessibilityAgendaBlock() {
    Row() {
      Column()
        .width(this.block?.DIVIDER_WIDTH)
        .height(this.block?.height - this.ganttVM.blockSpace * 2)
        .backgroundColor(this.block?.textColor)
        .borderRadius({
          topStart: LengthMetrics.vp(this.block?.leftBorderRadius),
          bottomStart: LengthMetrics.vp(this.block?.leftBorderRadius),
        })
        .opacity(0.7);
      Column() {
        this.buildAgendaBlockText();
      }
      .padding({ start: LengthMetrics.vp(this.block?.isFold() || this.block?.isAllDayAgenda ? 0 : 2) })
      .alignItems(HorizontalAlign.Start);

    }
    .accessibilityGroup(true)
    .accessibilityText(this.block?.getAccessibilityText())
    .justifyContent(FlexAlign.Start)
    .size({ width: this.block?.width, height: this.block?.height - this.ganttVM.blockSpace * 2 })
    .backgroundColor(this.block?.isFocus ?
      (this.isDarkMode ? this.block?.backgroundDarkFocusColor : this.block?.backgroundFocusColor) :
      (this.isDarkMode ? this.block?.backgroundDarkColor : this.block?.backgroundColor))
    .borderRadius(this.block?.rightBorderRadius)
    .clip(true)
    .position({ x: this.block?.x, y: this.block?.y })
    .hitTestBehavior(HitTestMode.Transparent)
    .onHover((isHover?: boolean, event?: HoverEvent) => {
    })
    .onDragStart((event: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.block.getInfo());
      this.isOnDropAllowed = false;
    })
    .onDragEnd(() => {
      this.isOnDropAllowed = true;
    })
    .onClick((event) => {
      this.blockClick(event);
    })
    .blockGeneralStyle()
  }

  @Builder
  buildTimeText() {
    if (this.block?.showTimeText) {
      Text(this.block?.getStartTime(this.block?.getInfo().mBegin, this.is24HourClock))
        .fontColor(this.isDarkMode ? GanttBlockViewModel.DARK_BLOCK_TEXT_COLOR : this.block?.textColor)
        .fontWeight(FontWeight.Medium)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.agendaBlockSize)
        )
        .lineHeight(this.ganttVM.lineHeight + 'vp')
        .textOverflow({ overflow: TextOverflow.None })
        .maxLines(1)
        .width('100%')
        .opacity(1)
        .fontFeature('\"ss08\" 1')
        .focusable(true)
        .id(this.block?.key + '-time')
        .textAlign(TextAlign.Start)
    }
  }

  @Builder
  buildAgendaBlockText() {
    this.buildTimeText()
    Text(this.block?.mainText)
      .fontColor(this.isDarkMode ? GanttBlockViewModel.DARK_BLOCK_TEXT_COLOR : this.block?.textColor)
      .fontWeight(FontWeight.Medium)
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        GlobalThis.getInstance().fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD,
        this.agendaBlockSize)
      )
      .lineHeight(this.ganttVM.lineHeight + 'vp')
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(this.block?.mainTextMaxLines)
      .margin({ bottom: this.block?.blockMargin })
      .opacity(1)
      .fontFeature('\"ss08\" 1')
      .focusable(true)
      .id(this.block?.key)
      .textAlign(this.block?.isFold() ? TextAlign.Center : TextAlign.Start)
    Text(this.block?.subText)
      .fontColor(this.isDarkMode ? GanttBlockViewModel.DARK_BLOCK_TEXT_COLOR : this.block?.textColor)
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        GlobalThis.getInstance().fontSizeScale,
        BigFontSize.BIG_FONT_SIZE_STANDARD,
        this.agendaBlockSize)
      )
      .fontWeight(FontWeight.Medium)
      .lineHeight(this.ganttVM.lineHeight + 'vp')
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(this.block?.subTextMaxLines)
      .opacity(0.8)
  }

  @Builder
  buildHolidaysBlock() {
    if (this.isOpenAccessibilityScreenReader) {
      this.buildAccessibilityHolidaysBlock();
    } else {
      this.buildNormalHolidaysBlock();
    }
  }

  @Builder
  buildNormalHolidaysBlock() {
    Column() {
      Text(this.block?.mainText)
        .fontColor(this.isDarkMode ? GanttBlockViewModel.DARK_BLOCK_TEXT_COLOR : this.block?.textColor)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.agendaBlockSize)
        )
        .fontWeight(FontWeight.Medium)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .opacity(1)
        .focusable(true)
        .id(this.block?.key)
    }
    .size({ width: this.block?.width - this.ganttVM.blockPadding, height: this.block?.height })
    .constraintSize({ minHeight: this.block?.height, minWidth: this.block?.width - this.ganttVM.blockPadding })
    .position({ x: this.rootVM.isRTL ? this.rootVM.ganttGridWidth - this.block?.x : this.block?.x, y: this.block?.y })
    .markAnchor({
      x: this.rootVM.isRTL ? '100%' : '0%' // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
    })
    .backgroundColor(this.block?.isFocus ?
      (this.isDarkMode ? this.block?.backgroundDarkFocusColor : this.block?.backgroundFocusColor) :
      (this.isDarkMode ? this.block?.backgroundDarkColor : this.block?.backgroundColor))
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .borderRadius(this.ganttVM.blockBorderRadius)
    .padding({ start: LengthMetrics.vp(this.ganttVM.blockPadding) })
    .hitTestBehavior(HitTestMode.Transparent)
    .onHover((isHover: boolean, event: HoverEvent) => {
      if (!this.block) {
        return;
      }
      this.onHoverContent(isHover, this.block);
    })
    .onDragStart((event: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.block.getInfo());
      this.isOnDropAllowed = false;

      const dragEventInfo = this.block?.getInfo();
      if (!dragEventInfo) {
        Log.info(TAG, 'dragEventInfo is null')
        return;
      }
      Log.info(TAG, `dragEventId ${dragEventInfo.mId}`)
      this.dragEventState.dragEventId = dragEventInfo.mId;
      this.dragEventState.dragEventInstanceStartMill = dragEventInfo.mBegin;
      this.dragEventState.dragEventIsMultiDayEvent = dragEventInfo.mIsMultiDayEvent;
    })
    .onDragEnd(() => {
      this.isOnDropAllowed = true;
    })
    .blockGeneralStyle()
  }

  @Builder
  buildAccessibilityHolidaysBlock() {
    Column() {
      Text(this.block?.mainText)
        .fontColor(this.isDarkMode ? GanttBlockViewModel.DARK_BLOCK_TEXT_COLOR : this.block?.textColor)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale,
          BigFontSize.BIG_FONT_SIZE_STANDARD,
          this.agendaBlockSize)
        )
        .fontWeight(FontWeight.Medium)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .opacity(1)
        .focusable(true)
        .id(this.block?.key)
        .accessibilityLevel('no');
    }
    .accessibilityGroup(true)
    .accessibilityText(this.block?.getAccessibilityText())
    .size({ width: this.block?.width - this.ganttVM.blockPadding, height: this.block?.height })
    .constraintSize({ minHeight: this.block?.height, minWidth: this.block?.width - this.ganttVM.blockPadding })
    .position({ x: this.block?.x, y: this.block?.y })
    .backgroundColor(this.block?.isFocus ?
      (this.isDarkMode ? this.block?.backgroundDarkFocusColor : this.block?.backgroundFocusColor) :
      (this.isDarkMode ? this.block?.backgroundDarkColor : this.block?.backgroundColor))
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .borderRadius(this.ganttVM.blockBorderRadius)
    .padding({ start: LengthMetrics.vp(this.ganttVM.blockPadding) })
    .hitTestBehavior(HitTestMode.Transparent)
    .onDragStart((event: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.block.getInfo());
      this.isOnDropAllowed = false;
    })
    .onDragEnd(() => {
      this.isOnDropAllowed = true;
    })
    .onClick((event) => {
      this.blockClick(event);
    })
    .blockGeneralStyle()
  }

  private blockClick(event: ClickEvent) {
    if (this.onClickContent && this.isOpenAccessibilityScreenReader) {
      this.onClickContent(event);
    }
  }

  build() {
    if (this.block) {
      if (this.block?.isAllDayAgenda) {
        this.buildHolidaysBlock();
      } else {
        this.buildAgendaBlock();
      }
    }
  }
}

@Component
export struct GanttViewTimeLine {
  @ObjectLink ganttVM: GanttViewModel;

  @ObjectLink rootVM: RootViewModel;

  @StorageProp('is24HourClock') is24HourClock: boolean = false;

  private readonly DOT_RADIUS: number = 2;

  private readonly TIME_LINE_COLOR: ResourceColor = GlobalData.instance().get(GlobalDataKeys.THEME_COLOR) as string;

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Text(this.ganttVM.getCurrentTime(this.is24HourClock))
          .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale,
            BigFontSize.BIG_FONT_SIZE_STANDARD,
            this.rootVM.currentTimeFontSize)
          )
          .minFontSize('6vp')
          .maxLines(1)
          .fontColor(this.TIME_LINE_COLOR)
          .textAlign(TextAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
      .width(this.rootVM.weekTitleVM.leftWidth - this.DOT_RADIUS)
      .position({
        x: this.rootVM.isRTL ? this.rootVM.ganttGridWidth + this.DOT_RADIUS : 0,
        y: -this.rootVM.currentTimeFontSize / 2
      })
      Column()
        .width(this.DOT_RADIUS * 2)
        .height(this.DOT_RADIUS * 2)
        .backgroundColor(this.TIME_LINE_COLOR)
        .borderRadius(this.DOT_RADIUS)
        .hitTestBehavior(HitTestMode.None)
        .position({
          x: this.rootVM.isRTL ? this.rootVM.ganttGridWidth - this.DOT_RADIUS :
            this.rootVM.weekTitleVM.leftWidth - this.DOT_RADIUS,
          y: -this.DOT_RADIUS
        })

      Column()
        .width(this.rootVM.ganttGridWidth)
        .height(1)
        .hitTestBehavior(HitTestMode.None)
        .backgroundColor(this.TIME_LINE_COLOR)
        .borderRadius(this.DOT_RADIUS)
        .position({ x: this.rootVM.isRTL ? 0 : this.rootVM.weekTitleVM.leftWidth, y: 0 })
    }
    .hitTestBehavior(HitTestMode.None)
    .size({ width: this.rootVM.ganttWidth, height: 1 })
    .markAnchor({
      x: this.rootVM.isRTL ? '100%' : '0%', // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
      y: 0
    })
    .position({ x: this.rootVM.isRTL ? this.rootVM.ganttWidth: 0, y: this.ganttVM.timeLinePositionY })
  }
}

// 甘特图时间线
@Component
export struct GanttLineView {
  @Consume rootVM: RootViewModel;

  @Consume isNotInScroll: boolean;

  @Consume isMaximizeRecovery: boolean;

  @ObjectLink ganttVM: GanttViewModel;

  @ObjectLink lineVM: GanttLineViewModel;

  @StorageProp('is24HourClock') is24HourClock: boolean = false;

  private readonly LINE_COLOR: ResourceColor = $r('sys.color.comp_divider');

  private readonly LINE_OPACITY: number = 0.15;

  private readonly HOUR_COLOR: ResourceColor = $r('sys.color.font_primary');

  private readonly HOUR_OPACITY: number = 0.4;

  @Builder
  amTextBuilder() {
    if (!this.is24HourClock && !this.lineVM.hiddenMorning) {
      Text($r('app.string.morning'))
        .maxFontSize(this.rootVM.timeFontSize + 'vp')
        .minFontSize('4vp')
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Regular)
        .fontColor(this.HOUR_COLOR)
        .opacity(this.HOUR_OPACITY)
        .id(CompId.MORNING)
    }
  }

  @Builder
  pmTextBuilder() {
    if (!this.is24HourClock && !this.lineVM.hiddenAfternoon) {
      Text($r('app.string.afternoon'))
        .maxFontSize(this.rootVM.timeFontSize + 'vp')
        .minFontSize('4vp')
        .maxLines(1)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Regular)
        .fontColor(this.HOUR_COLOR)
        .opacity(this.HOUR_OPACITY)
        .id(CompId.AFTERNOON)
    }
  }

  build() {
    Column() {
      Column() {
        this.amTextBuilder();
      }
      .width(this.rootVM.weekTitleVM.leftWidth)
      .position({
        x: 0, y:
        this.lineVM.morningLine * this.lineVM.gridCellHeight
      })

      Column() {
        this.pmTextBuilder();
      }
      .width(this.rootVM.weekTitleVM.leftWidth)
      .position({
        x: 0, y: this.lineVM.afternoonLine * this.lineVM.gridCellHeight
      })

      ForEach(RootModel.instance().HOUR_ARRAY, (_: number, index: number) => {
        Column() {
          if (!(this.lineVM.hiddenHourIndex === index && this.ganttVM.needShowTimeLine)) {
            Text(this.rootVM.hoursString[this.is24HourClock ? index : (index % 12)])
              .fontSize(FontSizeScaleUtils.getLimitFontSizeNum(
                GlobalThis.getInstance().fontSizeScale,
                BigFontSize.BIG_FONT_SIZE_STANDARD,
                this.rootVM.timeFontSize) + 'vp'
              )
              .textAlign(TextAlign.Center)
              .fontWeight(FontWeight.Regular)
              .fontColor(this.HOUR_COLOR)
              .opacity(this.HOUR_OPACITY)
          }
        }
        .width(this.rootVM.weekTitleVM.leftWidth)
        .position({
          x: 0, y: (index + 1) * this.lineVM.gridCellHeight
        })
      })
    }
    .width(this.rootVM.weekTitleVM.leftWidth)
    .height(this.ganttVM.gridHeight)
    .position({ x: this.rootVM.isRTL ? this.rootVM.ganttWidth : 0, y: 0 })
    .markAnchor({
      x: this.rootVM.isRTL ? '100%' : '0%' // 由于周视图全部使用绝对定位 镜像语言则锚点从视图块的右上角计算
    })
    .renderGroup(this.isNotInScroll && !this.isMaximizeRecovery)
    .transition(
      TransitionEffect.OPACITY.animation({ duration: GANTT_GENERAL_TRANSITION_DURING, curve: Curve.Sharp })
    )
  }
}

// 虚拟栅格节点
@Component
export struct GanttViewVirtualGrid {
  @Consume rootVM: RootViewModel;

  build() {
    GridRow({
      breakpoints: {
        value: ['740vp'],
        reference: BreakpointsReference.WindowSize
      },
      direction: GridRowDirection.Row
    }) {
    }.width('100%')
    .onBreakpointChange((breakpoint) => {
      this.rootVM.onBreakpointChange(breakpoint);
    })
  }
}
