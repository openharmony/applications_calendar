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
  AgendaListDataSource,
  AgendaTransitionUtil,
  AgendaListItemViewModel,
  AgendaUtil,
  DateUtil,
  DialogControllerOptions,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  PreviewFromType,
  TabType,
  ThrottleFunction,
  ReportHiEventParams,
  HiEventParamsConfirm,
  ReportUtil,
  behaviorEvents,
  CompId,
  ServiceEnum,
  AgendaDeleteService,
  ServiceManager,
  CommonInnerEvent,
  BigFontSize,
  FontSizeScaleUtils,
  DeviceConfig,
  SlideActionType,
  I18nUtil,
  AgendaAbilityManager
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { AgendaListLocation } from '@app/common/src/main/ets/default/util/ReportUtil';
import SearchAgendaViewModel from '../viewmodel/SearchAgendaViewModel';
import { AgendaItem } from '../../components/AgendaItem';
import { ImportantAgendaItem } from '../../components/ImportantAgendaItem';
import { LoadingView } from '../../components/LoadingView';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { FocusPage } from '../../components/FlexAgendaList';
import { MultiBottomTab } from '../../AgendaDetail/view/MultiBottomTab';
import { KeyCode } from '@kit.InputKit';
import { CalendarContract } from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { AgendaMenuOpt } from '../../AgendaDetail/view/AgendaPopupContent';
import { AgendaMenu } from '../../AgendaDetail/view/AgendaMenu';
import { AgendaDetailSource } from '../../common/AgendaEnum';
import { showDataParams } from '../viewmodel/SearchAgendaViewModel'

const TAG: string = 'SearchAgendaView';
const SCROLL_BAR_OFFSET = 16; // 滚动条右侧偏移量
const DELAY: number = 300;

@Component
export struct SearchAgendaView {
  @Consume calendarUuid: string;

  // 全局统一的展示日期时间戳
  @StorageProp(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  //键盘规避
  @StorageProp('keyBoardHeight') keyBoardHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 系统时间当天的时间戳
  @StorageProp(GlobalDataKeys.CURRENT_DATE) @Watch('onCurrentDateChange') currentDate: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('language') language: string = '';

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 用于判断是否需要动态变换边距
  private emptyAgendaListAvoid: boolean = DeviceConfig.instance().config.emptyAgendaListAvoid;

  // 选中日程id值
  @StorageLink('checkEventId') checkEventId: number = -1;

  @StorageLink('themeColor') themeColor: string = '';

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @Link showResult: boolean;

  // 选中的日程ID
  @Link showEventId: number;

  // 是否显示回到今日按钮
  @Link isShowBackToToday: boolean;

  @Link @Watch('keyEventFromSearchBoxOnChange') keyEventFromSearchBox: KeyEvent | undefined;

  @Prop @Watch('backToTodayMethod') onBackToday: boolean;

  // 外部传入的日程开始时间，用于处理重复日程
  @Consume currentDisplayStartMills: number;

  // 外部传入的日程结束时间，用于处理重复日程
  @Consume currentDisplayEndMills: number;

  // 窗口类型
  @Consume @Watch('onInSmallWindowChange') inSmallWindow: boolean;

  // 全模态打开日程详情
  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  // 处理焦点变化
  @Consume actionFocus: string

  @Link @Watch('onChangeValueChange') changeValue: string;

  @Link @Watch('onSelectableChange') selectable: boolean; // 是否可以选中

  @Consume keyCtrlState: boolean;

  @State shareableEventCount: number = 0;

  @State selectedEventCount: number = 0;

  // 当前list宽度,用于热区的位置判断
  private listWidth: number = 0;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private onFirstIdChange: (firstEventId: number, isContainCheckId: boolean) => void =
    (firstEventId: number, isContainCheckId: boolean): void => {
    };

  // 删除日程回调函数
  private onDeleteSuccess: () => void = (): void => {
  };

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  private onAniStart: () => void = () => {
  }

  private onAniEnd: () => void = () => {
  }

  private mScroller = new Scroller();

  // 分享的viewId
  private shareAnchorViewId: string = 'multi_bottom_tab_share_btn';

  @State vm: SearchAgendaViewModel = new SearchAgendaViewModel(
    this.displayDate,
    this.checkEventId,
    this.currentDate,
    this.changeValue,
    this.showResult,
    this.calendarUuid,
    this.onFirstIdChange,
    this.onDeleteSuccess,
    this.showEventId,
    this.currentDisplayStartMills,
    this.currentDisplayEndMills,
    (data: showDataParams) => {
      this.vmShowDataChange(data.showEventId, data.currentDisplayStartMills, data.currentDisplayEndMills,
        data.shareableEventCount, data.selectedEventCount, data.selectable);
    },
    this.isInPop,
    this.mScroller
  );

  // 多选删除弹框
  multiDeleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.plural.delete_multiple_selected_count_msg',
        this.vm.selectedAgendaCount, this.vm.selectedAgendaCount),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.SearchAgendaView,
          ACTION: HiEventParamsConfirm.TRUE
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        this.vm.deleteMultiEventsConfirm();
        this.selectable = false;
      },
      onCancelClick: () => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.SearchAgendaView,
          ACTION: HiEventParamsConfirm.FALSE
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        Log.info(TAG, `click cancel`);
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  // VM的状态变量改变需要同步回父组件
  vmShowDataChange(showEventId: number, currentDisplayStartMills: number, currentDisplayEndMills: number,
                   shareableEventCount: number, selectedEventCount: number, selectable?: boolean) {
    this.showEventId = showEventId;
    this.currentDisplayStartMills = currentDisplayStartMills;
    this.currentDisplayEndMills = currentDisplayEndMills;
    this.selectedEventCount = selectedEventCount;
    this.shareableEventCount = shareableEventCount;
    if (selectable !== undefined) {
      this.selectable = selectable;
    }
  };

  onInSmallWindowChange() {
    Log.info(TAG, `SearchAgendaView this.inSmallWindow: ${this.inSmallWindow}, this.actionFocus: ${this.actionFocus}`);
    if (this.inSmallWindow && this.actionFocus === FocusPage.AGENDA_DETAIL) {
      this.changeCheckEventId(this.showEventId);
      const info: AgendaEventInfo | undefined = this.vm.datas.find(item => item.mId === this.showEventId)
      if (info === undefined) {
        Log.error(TAG, `Info Is Not Found, This Show Event ID is Wrong, showEventId = ${this.showEventId}`);
      } else {
        // 跳转到详情页面
        this.agendaTransitionUtil.buildEventDetail(info);
        this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), true, this.onAniStart, this.onAniEnd);
        this.vm.onActionFocusChange(FocusPage.AGENDA_DETAIL)
        Log.info(TAG, `Go To Agenda Detail Cover, ${this.inSmallWindow}, this.actionFocus: ${this.actionFocus}`);
      }
    }
    if (!this.inSmallWindow) {
      // 跳转到全部日程页面，全部日程页面获焦
      this.agendaTransitionUtil.isEditPageShow = false;
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

  @Builder
  existMenu(id: number, isHoliday: boolean = false, info?: AgendaListItemViewModel) {
    AgendaMenu({
      isSmallWindow: false,
      menuOpts: isHoliday ? [AgendaMenuOpt.VIEW] : [AgendaMenuOpt.COPY, AgendaMenuOpt.DELETE],
      onCopyHandle: () => {
        emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': id } });
      },
      onDeleteHandle: () => {
        ServiceManager.getInstance()
          .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
          service?.notifyDeleteEvent(id, 0, true);
        });
      },
      onViewHandle: () => {
        if (info) {
          this.jumpToDetail(info);
        }
      }
    })
  }

  jumpToDetail(info: AgendaListItemViewModel) {
    AgendaAbilityManager.getInstance().startAbilityByEventId(info.mId, info.mBegin, info.mEnd, info.mIsHoliday,
        info.mTitle);
  }

  @Builder
  AgendaDataSources() {
    LazyForEach(this.vm.dataSources, (item: AgendaListItemViewModel) => {
      // 开启多选时，重要日程变成普通日程，显示CheckBox, 节日显示为非重要日程
      if (item.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
        item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY || this.selectable) {
        ListItem() {
          AgendaItem({
            info: item,
            selectable: $selectable,
            viewType: TabType.SEARCH,
            searchText: $changeValue,
            sourceType: AgendaDetailSource.SEARCH_LIST,
            isChecked: this.vm.checkedIdentity === this.vm.getCheckedIdentity(item),
            onItemClick: () => {
              if (this.selectable) {
                item.isSelected = !item.isSelected;
              } else {
                this.vm.onItemClick(item);
                if (this.keyCtrlState) {
                  this.selectable = true;
                  item.isSelected = !item.isSelected;
                  return;
                }
              }
            },
            onDeleteSuccess: () => {
              this.onDeleteSuccess();
            },
            previewFromType: PreviewFromType.SEARCH_AGENDA_VIEW,
            isInPop: this.isInPop
          })
            .width('100%')
            .bindContextMenu(this.existMenu(item.mId, item.isHoliday(), item), ResponseType.RightClick)
        }
        .id(`${item.getEditAblePropStr()}-${this.changeValue}-${this.selectable}`)
      } else {
        ListItem() {
          ImportantAgendaItem({
            info: item,
            selectable: $selectable,
            searchText: $changeValue,
            isChecked: this.vm.checkedIdentity === this.vm.getCheckedIdentity(item),
            sourceType: AgendaDetailSource.SEARCH_LIST,
            onItemClick: () => {
              this.vm.onItemClick(item);
            },
            onDeleteSuccess: () => {
              this.onDeleteSuccess();
            },
            previewFromType: PreviewFromType.SEARCH_AGENDA_VIEW,
            isInPop: this.isInPop
          })
            .width('100%')
            .bindContextMenu(this.existMenu(item.mId), ResponseType.RightClick)
        }
        .id(AgendaUtil.getShareIdByIndexAndInfo(item))
      }
    }, (item: AgendaListItemViewModel) => `${item.getEditAblePropStr()}-${this.changeValue}`)
  }

  @Builder
  EmptyLayout() {
    Column() {
      Image($r('app.media.ic_no_result'))
        .width(120)
        .height(120)
        .margin({
          bottom: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level8'),
        })
        .draggable(false)
        .edgeAntialiasing(this.vm.antialiasingNumber)
      Text($r('app.string.search_no_content_text'))
        .fontSize($r('sys.float.Body_M'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          20
        ))
        .fontColor($r('sys.color.font_secondary'))
        .margin({ right: $r('sys.float.padding_level8') })
    }
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .margin({ bottom: this.getAvoidMargin()})
  }

  @Builder
  buildList() {
    Row() {
      List({
        space: 12,
        initialIndex: this.vm.displayEventsIndexArr[0],
        scroller: this.mScroller
      }) {
        ListItem() {
          this.buildHeadItemContent()
        }
        .visibility(this.vm.headViewText ? Visibility.Visible : Visibility.Hidden)

        this.AgendaDataSources()

        ListItem() {
          this.buildTailItemContent();
        }
        .margin({ bottom: $r('sys.float.padding_level12') })
        .visibility(this.vm.tailViewText ? Visibility.Visible : Visibility.Hidden)
      }
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .contentEndOffset(this.selectable ? 0 : this.isInPop ? 16 : this.windowAvoidAreaNavigationRectHeight)
      .key(CompId.SEARCH_AGENDA_LIST)
      .focusable(true)
      .focusOnTouch(true)
      .onKeyEvent((event: KeyEvent) => {
        this.keyEventHandler(event)
      })
      .scrollBar(BarState.Off)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .height('100%')
      .width(`calc(100% - ${SCROLL_BAR_OFFSET}vp)`)
      .alignListItem(ListItemAlign.Center)
      .onScrollStart(() => {
        this.vm.onActionFocusChange(FocusPage.FLEX_SEARCH_AGENDA);
      })
      .onScrollIndex((start: number, end: number) => {
        this.onScrollIndexHandler(start, end);
      })
      .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
        this.listWidth = Number(newValue.width);
        this.vm.updateListHeight(Number(newValue.height));
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
    }.layoutWeight(this.selectable ? 1 : this.isInPop ? 0.3 : 0.2)
  }

  @Builder
  ListLayout() {
    this.buildList();
  }

  @Builder
  buildHeadItemContent() {
    Column() {
      if (!this.vm.headLoading) {
        Button({ type: ButtonType.Normal, stateEffect: true }) {
          Text(this.vm.headViewText)
            .fontSize(this.vm.viewTextSize)
            .maxFontScale(BigFontSize.BIG_FONT_SIZE)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColor)
            .id(CompId.LOAD_PRE_AGENDA_TEXT)
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
    .width('100%')
  }

  @Builder
  buildTailItemContent() {
    Column() {
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
    .width('100%')
  }

  build() {
    Column() {
      if (this.vm.isDataReady) {
        this.ListLayout();
        if (this.vm.datas.length === 0) {
          this.EmptyLayout()
        }
        if (this.selectable) {
          MultiBottomTab({
            canShare: this.shareableEventCount > 0,
            showSelectAll: true,
            selectedCount: this.selectedEventCount,
            selectable: this.selectable,
            selectAllButtonAvailable: this.vm.selectAllButtonAvailable,
            onClickDelete: (): void => this.onMultiDeleteClick(),
            onClickShare: (): void => this.onMultiShareClick(),
            confirmMutiDel: (): void => this.confirmMultiDelete(),
          })
            .padding({ bottom: this.isInPop ? 16 : this.windowAvoidAreaNavigationRectHeight })
        }
      } else {
        LoadingView();
      }
    }
    .padding({ left: $r('sys.float.padding_level8') })
  }

  confirmMultiDelete(): void {
    this.vm.deleteMultiEventsConfirm();
    this.selectable = false;
  }

  aboutToAppear() {
    this.vm.dataSources = new AgendaListDataSource(this.vm.datas);
    GlobalThis.getResourceStr($r('app.string.search_for_events'));
    this.vm.subscribeEvents();
    this.vm.onFirstSearch();
    // 视图逻辑封装到vm层
    this.vm.onActionFocusChange = (actionFocus: string) => {
      this.actionFocus = actionFocus;
    }
    if (this.agendaTransitionUtil.formerId === this.getGeometryId()) {
      this.onAniStart();
    }
  }

  aboutToDisappear() {
    this.vm.unsubscribeEvents();
    this.multiDeleteDialogController = null;
  }

  getGeometryId(): string {
    return '' + this.showEventId + '-searchAgenda';
  }

  getAvoidMargin(): number {
    if (!this.emptyAgendaListAvoid || this.keyBoardHeight === 0) {
      return this.windowAvoidAreaNavigationRectHeight;
    }
    return this.keyBoardHeight;
  }

  onMultiDeleteClick() {
    if (this.selectedEventCount <= 0) {
      return;
    }
    this.multiDeleteDialogController?.open();
  }

  onMultiShareClick() {
    let params: ReportHiEventParams = {
      FROM_TYPE: AgendaListLocation.SearchAgendaView
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiShare, params);
    this.mAgendaOperateHelper.shareMultipleAgenda(
      this.vm.shareableEventIds, this.shareAnchorViewId
    );
  }

  private onCurrentDateChange() {
    this.vm.onCurrentDateChange(this.currentDate);
  }

  private onChangeValueChange() {
    ThrottleFunction.instance().debounce(TAG, (): void => {
      this.vm.onChangeValueChange(this.changeValue);
    });
  }

  private keyEventHandler(event: KeyEvent) {
    if ((event.keyCode === KeyCode.KEYCODE_DPAD_UP ||
      event.keyCode == KeyCode.KEYCODE_DPAD_DOWN) && event.type === KeyType.Down) {
      Log.info(TAG, 'press key_up or key_down');
      this.vm.onKeyPress(event.keyCode)
    }
  }

  private keyEventFromSearchBoxOnChange() {
    if (!this.keyEventFromSearchBox) {
      return;
    }
    focusControl.requestFocus(CompId.SEARCH_AGENDA_LIST);
    this.keyEventHandler(this.keyEventFromSearchBox);
    this.keyEventFromSearchBox = undefined;
  }

  onScrollIndexHandler(start: number, end: number) {
    this.vm.updateScrollStartIndex(start, end);
    ThrottleFunction.instance().debounceInstant(TAG, (): void => {
      this.vm.changeBackTodayStatus(start, end);
      this.isShowBackToToday = this.vm.isShowBackToday;
    }, DELAY)
  }

  /**
   * 回到今天
   */
  backToTodayMethod() {
    this.vm.onBackTodayClick();
  }

  onSelectableChange() {
    if (this.selectable) {
      this.vm.enableMultiSelect();
    }
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
      return;
    }
    if (type === SlideActionType.START) {
      this.vm.nowSelectCount = this.selectedEventCount;
    }
    this.vm.panGestureAction(type, event.fingerList[0]);
    this.selectedEventCount = this.vm.nowSelectCount;
  }
}