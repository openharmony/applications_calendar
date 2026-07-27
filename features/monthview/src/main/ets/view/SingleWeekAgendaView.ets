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

import { AgendaBlockInfo, WeekAgendaBlockModel } from '../viewmodel/WeekAgendaBlockModel';
import { ClickEventResultData, ClickPositionType, SingleWeekViewModel } from '../viewmodel/SingleWeekViewModel';
import {
  AgendaEventInfo,
  CommonInnerEvent,
  CompId,
  DAY_PER_WEEK,
  DeviceConfig,
  DialogControllerOptions,
  GlobalDataKeys,
  Log,
  PreviewFromType,
  ThrottleFunction,
  EmitterCollector,
  ServiceManager,
  AgendaDeleteService,
  ServiceEnum,
  GlobalThis,
  DateInfo,
} from '@app/common';
import {
  AgendaEditMenuOpt,
  AgendaMenu,
  AgendaMenuOpt,
  AgendaPopupContent,
  CopyHelper,
  CreateAgendaPageSource,
  generateAgendaEditOption,
  generateAgendaOption,
  PreviewContent
} from '@app/feature.agenda';
import { FrameLayout, WeekAgendaLayout } from '../layoutmodel/FrameLayoutRule';
import { SINGLE_DAY_MENU_OPTS } from './ConstantUtils';
import { componentUtils, LengthMetrics } from '@kit.ArkUI';
import { CreatePopupContent, getPopOffsetY } from '@app/feature.agenda';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { DayViewState, MonthlyViewStateManager, MonthlyWeekState } from '../viewmodel/MonthlyViewState';
import { WeekAgendaState } from '../viewmodel/WeekAgendaState';
import { DayCellLayout, gridDayCellBreakPoints } from '../layoutmodel/DayCellLayoutRule';
import { PaintCache } from '@app/common/src/main/ets/graphic/PaintCache';
import { MonthPaintCache } from '../utils/MonthPaintCache';

const TAG: string = '[MonthlyView][SigWeekAgenda]';
const MAX_CIRCLE_SIZE: number = gridDayCellBreakPoints[gridDayCellBreakPoints.length - 1].value.circleSize;

interface PopupStateEvent { isVisible: boolean };

@Component
@Reusable
export struct SingleWeekAgendaView {
  // 月视图 单周视图 绑定的视图模型
  @ObjectLink viewModel: SingleWeekViewModel;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 是否开启无障碍模式
  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) @Watch('updateAccessibilityVirtualNodeStatus') isOpenAccessibilityScreenReader: boolean = false;

  // 是否全屏月视图显示无障碍模式日程块虚拟节点
  @State isShowAccessibilityVirtualNode: boolean = false;

  @State @Watch('updateAccessibilityVirtualNodeStatus') dateInfo: DateInfo = new DateInfo();

  // 窗口大小
  @LocalStorageProp('windowHeight') windowHeight: number = 0;

  // 当周的日程模型
  @ObjectLink dataModel: WeekAgendaBlockModel;

  // 月视图绑定的布局参数
  @State layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  // 单天视图绑定的布局参数
  @State dayCellLayout: DayCellLayout = MonthViewLayoutModel.getInstance().dayLayout.value;

  @State showPop: boolean = false;

  @Consume selectBlock: AgendaBlockInfo | undefined;

  @Consume rightPop: boolean;
  // 一级菜单选项
  private menuOpts: Array<AgendaMenuOpt> = SINGLE_DAY_MENU_OPTS;
  // 二级编辑菜单选项
  private menuEditOpts: Array<AgendaEditMenuOpt> = [];

  // 当前右键选中时间
  private clickDateTime: number = 0;

  //周下标
  private index: number = 0;

  private totalWeekNum: number = 0;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 关闭新建日程跟手弹窗时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  @State  @Watch('updateAccessibilityVirtualNodeStatus')  weekState: MonthlyWeekState = MonthlyViewStateManager.getInstance().weekState;

  @State weekAgendaState: WeekAgendaState = WeekAgendaState.getInstance();

  @State popOffsetY: number = 0;

  // 新建弹窗内容是否被编辑过
  @State hasBeenEdited: boolean = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private timeoutId: number = 0;

  aboutToAppear() {
    this.updateAccessibilityVirtualNodeStatus();
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FULL_UPDATE_AGENDA_LIST_PAGE },
      this.dataModel.resetMonthAgendaBlockFocusParam);
    this.emitterCollector.on({ eventId: CommonInnerEvent.RESET_MONTH_AGENDA_BLOCK_FOCUS_PARAM },
      this.dataModel.resetMonthAgendaBlockFocusParam);
    this.emitterCollector.on({ eventId: CommonInnerEvent.THEME_FONT_CHANGE }, this.onThemeChange);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  // 主题变更
  private onThemeChange: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    PaintCache.instance().setFontFamilyPath('');
    MonthPaintCache.instance().loadFontSync();
    this.dataModel.invalidate();
  };

  private getSelectInfo(): AgendaEventInfo | undefined {
    if (!this.selectBlock) {
      return undefined;
    }
    return this.selectBlock.getInfo();
  }

  @Builder
  buildAgendaMenu() {
    AgendaMenu({
      info: this.selectBlock?.getInfo(),
      date: this.selectBlock?.getEarliestDate(),
      isSmallWindow: false,
      menuOpts: this.menuOpts,
      menuEditOpts: this.menuEditOpts,
      onShareHandle: () => {
        emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
          data: {
            compId: this.dataModel.getCompId(),
            eventIds: [this.selectBlock?.getInfo().mId],
            // ShareKit 注释 - start
            // popPos: this.dataModel.getSharePopPos(this.selectBlock),
            // comeFormAgendaBlock: true,
            // agendaBlockWidth: this.dataModel.getShareAgendaBlockWidth(this.selectBlock)
            // ShareKit 注释 - end
          }
        })
      },
      onCreateHandle: () => {
        this.viewModel.jumpCreateAgendaPop(this.clickDateTime);
      },
      onEditHandle: (editType: number) => {
        this.viewModel.jumpEditAgendaPop(this.selectBlock, editType);
      },
      onDeleteHandle: async () => {
        const selectInfo = this.getSelectInfo();
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
        const selectInfo = this.getSelectInfo();
        if (!selectInfo) {
          Log.error(TAG, `copy agenda get selectInfo err undefined`);
          return;
        }
        emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': selectInfo.mId } });
      },
      onPasteHandle: () => {
        CopyHelper.instance().pasteEventInfo(this.clickDateTime);
      },
      onViewHandle: () => {
        if (!this.selectBlock) {
          Log.error(TAG, `view agenda get selectInfo err undefined`);
          return;
        }
        this.viewModel.toEventDetail(this.selectBlock);
      },
    })
  }

  @Builder
  buildCreateAgendaPopupContent() {
    CreatePopupContent({
      createPageData: this.viewModel.createPageData,
      discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
      isQuickCreate: this.viewModel.isQuickCreate,
      onCreatePageDismiss: () => {
        this.viewModel.isCreatePopupShow = false;
        this.hasBeenEdited = false;
      },
      changeEditedFlag: () => {
        this.hasBeenEdited = true;
      }
    })
  }

  @Builder
  buildCreateAgendaPop() {
    Rect()
      .width(1)
      .height(1)
      .opacity(0)
      .position(this.viewModel.popupPos)
      .bindPopup(this.viewModel.isCreatePopupShow, {
        builder: this.buildCreateAgendaPopupContent(),
        popupColor: this.viewModel.isQuickCreate ? $r('sys.color.ohos_id_color_list_card_bg') :
        $r('sys.color.ohos_id_color_panel_bg'),
        radius: 16,
        backgroundBlurStyle: BlurStyle.NONE,
        mask: true,
        placement: this.viewModel.isCreatePopupShow && !this.viewModel.isQuickCreate ? Placement.Right :
        Placement.Bottom,
        offset: { y: this.popOffsetY },
        onWillDismiss: (dismiss) => {
          if (this.viewModel.isQuickCreate) {
            // 有编辑-->失焦保存日程，无编辑-->失焦不创建日程
            if (this.hasBeenEdited) {
              emitter.emit({ eventId: CommonInnerEvent.EVENT_CREATE_AGENDA });
            }
            this.viewModel.isQuickCreate = false;
            this.viewModel.isCreatePopupShow = false;
            dismiss.dismiss();
          } else {
            this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
          }
        },
        onStateChange: (ev) => {
          if (!ev.isVisible) {
            this.viewModel.isCreatePopupShow = false;
          }
        },
        shadow: ShadowStyle.OUTER_DEFAULT_SM
      })
  }

  @Builder
  buildAgendaPop(agendaBlockInfo: AgendaBlockInfo | undefined) {
    Rect()
      .width(1)
      .height(1)
      .opacity(0)
      .position(this.viewModel.popupPos)
      .bindPopup((this.weekAgendaState.showPopup), {
        builder: this.buildAgendaPopupContent(agendaBlockInfo),
        popupColor: agendaBlockInfo && agendaBlockInfo.getInfoList().length > 1 ? $r('app.color.pop_background_color') :
          this.needCommerce ? $r('sys.color.ohos_id_color_panel_bg') : $r('sys.color.comp_background_primary'),
        backgroundBlurStyle: BlurStyle.NONE,
        mask: false,
        placement: this.viewModel.popDirection,
        showInSubWindow: this.viewModel.isCreatePopupShow && !this.viewModel.isQuickCreate,
        radius: $r('sys.float.corner_radius_level10'),
        onStateChange: (event: PopupStateEvent) => {
          if (!event.isVisible) {
            this.weekAgendaState.showPopup = false;
            focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //保险用重新聚焦到日期上
          }
        },
        onWillDismiss: (dismiss) => {
          //pop关闭将clickAgendaShow复原
          this.viewModel.recoverResponseHover();
          dismiss.dismiss();
        },
        shadow: ShadowStyle.OUTER_DEFAULT_SM
      })
  }

  @Builder
  buildAgendaClickPop(agendaBlockInfo: AgendaBlockInfo) {
    AgendaPopupContent({
      info: agendaBlockInfo.getInfoList(),
      date: agendaBlockInfo.blockStartStamp,
      isFold: !agendaBlockInfo.isUnfold(),
      isSmallWindow: this.layout.isSmall,
      borderless: true,
      isPreview: false,
      onClickContent: () => {
        this.viewModel.recoverResponseHover();
        this.weekAgendaState.showPopup = false;
        focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //保险用重新聚焦到日期上
      },
      onMenuChosen: (opt: AgendaMenuOpt, id: number) => {
        this.weekAgendaState.showPopup = false;
        focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO); //保险用重新聚焦到日期上
      },
    })
  }

  @Builder
  previewContentBuilder(info: AgendaEventInfo, selectBlock: AgendaBlockInfo) {
    PreviewContent({
      info,
      searchText: '',
      previewFromType: PreviewFromType.MONTH_VIEW,
      displayStartMills: info?.mBegin,
      displayEndMills: info?.mEnd,
      isHoverShow: true,
      onClickHandler: () => {
        this.viewModel.recoverResponseHover(); //点击pop，跳转到日程详情，点击事件标志位复原
        this.viewModel.toEventDetail(selectBlock);
        this.weekAgendaState.showPopup = false;
      },
      onHoverHandler: (isHover: boolean) => {
        if (isHover) {
          // 清除计时器防止pop弹窗被关闭
          this.viewModel.agendaPopHoverClearTimer();
        } else {
          // 添加关闭计时器用于pop弹窗hover移出且没有落在日程区域
          this.viewModel.agendaPopHoverClose();
        }
      }
    }).borderRadius($r('sys.float.corner_radius_level12'))
  }

  @Builder
  buildAgendaPopupContent(agendaBlockInfo: AgendaBlockInfo | undefined) {
    if (agendaBlockInfo && this.weekAgendaState.showPopup) {
      if (this.needCommerce && agendaBlockInfo.getInfoList().length === 1) { //PC
        this.previewContentBuilder(agendaBlockInfo.getInfoList()[0], agendaBlockInfo);
      } else {
        this.buildAgendaClickPop(agendaBlockInfo);
      }
    }
  }

  build() {
    if (this.viewModel?.isExist) {
      Column() {
        if (this.weekAgendaState.showPopup) {
          if (this.dataModel.showAgendaPop()) { //点击日程块 pop
            this.buildAgendaPop(this.selectBlock);
          } else if (this.weekAgendaState.agendaBlockState.hoverFlag && this.dataModel.showHoverPop()) { //hover日程块 pop
            this.buildAgendaPop(this.weekAgendaState.agendaBlockState.hoverBlock);
          }
        }
        if (this.isCreateAgendaPopup && this.viewModel.isCreatePopupShow) {
          //新建、编辑日程块弹窗
          this.buildCreateAgendaPop();
        }
        if (this.isShowAccessibilityVirtualNode) {
          Row()
            .width('100%')
            .height('100%')
            .accessibilityLevel('no')
            .accessibilityVirtualNode(this.canvas2VirtualNode())
        }
      }
      .accessibilityLevel('no')
      .id(this.dataModel.getCompId())
      .drawModifier(this.dataModel)
      .visibility(!this.layout.isSmall || this.weekState.isFullShow ? Visibility.Visible : Visibility.None)
      .layoutWeight(1)
      .width(this.layout.isGrid && !this.layout.isSmall ? '100%' :
        `calc(100% - ${16 + this.dayCellLayout.weekNumPadding}vp)`)
      .margin({
        top: LengthMetrics.vp(this.layout.isGrid ?
          (this.needCommerce ? MonthViewLayoutModel.getInstance().dayLayout.value.circleSize - MAX_CIRCLE_SIZE : 0) :
          WeekAgendaLayout.agendaRowPaddingTop),
        start: LengthMetrics.vp(this.layout.isGrid && !this.layout.isSmall ? 0 :
          (16 + this.dayCellLayout.weekNumPadding))
      })
      .bindContextMenu(this.buildAgendaMenu(), ResponseType.RightClick, {
        onAppear: () => {},
        onDisappear: () => {
          this.rightPop = false;
          this.viewModel.recoverResponseHover();
        }
      })
      .gesture(
        GestureGroup(GestureMode.Parallel,
          TapGesture({ count: 1 })
            .onAction((event) => {
              Log.info(TAG, 'Gesture TapGesture');
              const data: ClickEventResultData = this.viewModel.onClickAgendaArea(this.index, this.totalWeekNum, event);
              if (data.getClickPositionType() === ClickPositionType.CLICK_AGENDA_BLOCK_ONCE) {
                if (data.getSelectBlock()) {
                  this.selectBlock = data.getSelectBlock();
                }
              } else if (data.getClickPositionType() === ClickPositionType.CLICK_BLANK_AREA_ONCE) {
                this.viewModel.clickBlankArea(data.getXIndex());
              }
            }),
          LongPressGesture({ fingers: 1 })
            .onAction((event: GestureEvent) => {
              const data: ClickEventResultData = this.viewModel.onLongPressAgendaArea(this.index, event);
            })
        )
      )
      .onMouse((ev?) => {
        if (!ev) {
          return;
        }
        if (ev.button === MouseButton.Right && ev.action === MouseAction.Press) {
          //关闭弹窗
          this.weekAgendaState.showPopup = false;
          this.viewModel.recoverResponseHover();
          const clickedAgenda = this.viewModel.handleRightClick(ev.x, ev.y, this.index);
          if (clickedAgenda && clickedAgenda.isUnfold()) {
            this.generateAgendaOption(clickedAgenda.getInfo());
            this.selectBlock = clickedAgenda;
          } else {
            //点到非日程区域
            this.menuOpts = [];
            this.menuEditOpts = [];
            this.menuOpts.push(AgendaMenuOpt.CREATE);
            if (CopyHelper.instance().getStashEventInfo()) {
              this.menuOpts.push(AgendaMenuOpt.PASTE);
            }
            this.rightPop = true;
            if (this.selectBlock) {
              this.selectBlock.blockPop = false;
            }
          }
          this.viewModel.setNoResponseHover();
        }
        if (ev.button === MouseButton.Right && ev.action === MouseAction.Release) {
          this.clickDateTime = this.viewModel.getClickDateTime(ev.x);
          if (this.needCommerce) {
            const windowHeight = this.windowHeight ?? 560;
            this.popOffsetY = getPopOffsetY(ev.windowY, windowHeight);
          }
          this.viewModel.popupPos = { x: ev.x, y: ev.y };
        }
        if (ev.button === MouseButton.Left && ev.action === MouseAction.Press) {
          if (this.needCommerce) { // 新建日程pop弹窗偏移,用于规避三键
            const windowHeight = this.windowHeight ?? 560;
            this.popOffsetY = getPopOffsetY(ev.windowY, windowHeight);
          }
        }

        ThrottleFunction.instance().throttle(TAG, (): void => {
          this.viewModel.handleHover(ev.x, ev.y, this.index, this.totalWeekNum);
        }, 20);
        ev.stopPropagation();
      })
    }
  }
  /**
   * 虚拟空节点，用于正常模式下显示
   */
  @Builder
  empty2VirtualNode() {
    Column() {

    }
    .id('empty2VirtualNode')
    .width('100%')
    .height('100%')
  }

  getAccessibilityText(block: AgendaBlockInfo): string {
    const accessibilityTextStr = GlobalThis.getPluralStr($r('app.plural.broadcast_omit_agenda_num'), block.blockAgendas.length);
    return block.isUnfold() ? block.titleString : accessibilityTextStr;
  }

  /**
   * 虚拟触摸节点
   */
  @Builder
  canvas2VirtualNode() {
    Column() {
      ForEach(this.dataModel.blocks, (block: AgendaBlockInfo, index: number) => {
        Column() {
        }
        .accessibilityText(this.getAccessibilityText(block))
        .height(block.blockHeight)
        .width(this.getWidth(block.columnEnd - block.columnStart))
        .position({
          x: this.getPos_X(block.columnStart),
          y: this.getPos_Y(block.rowStart, block.blockHeight)
        })
        .accessibilityLevel('yes')
        .id(`${block.columnStart}-${block.columnEnd}-${block.rowStart}-${block.rowEnd}`)
      }, (block: AgendaBlockInfo, index: number) => block.blockTimeStamp + '-' + block.toString() + '-' + String(index))
    }
    .id('canvas2VirtualNode')
    .width('100%')
    .height('100%')
  }

  private getPos_X(index: number): string {
    const temp = Math.round((index) / 7 * 10000) / 100;
    return `${temp}%`;
  }

  private getPos_Y(index: number, blockHeight: number): number {
    return index * (blockHeight + 2);
  }

  private getWidth(index: number): string {
    const temp = Math.round((index + 1) / 7 * 10000) / 100;
    return 'calc(' + temp + '% - ' + 16 / 100 * temp + 'vp)'; // 注意此处无法使用嵌套的`${}`方式进行输入
  }

  async generateAgendaOption(clickedAgenda: AgendaEventInfo) {
    this.menuOpts = await generateAgendaOption(clickedAgenda);
    this.menuEditOpts = generateAgendaEditOption(clickedAgenda);
  }

  private updateAccessibilityVirtualNodeStatus() {
    this.isShowAccessibilityVirtualNode = false;
    clearTimeout(this.timeoutId);
    this.timeoutId = setTimeout(() => {
      // 此处询问过ArkUI，虚拟节点上树后，无法根据状态变量不同进行重渲染，
      // 设置延时规避打开无障碍后进入日历虚拟子节点挂树问题
      this.isShowAccessibilityVirtualNode = this.isOpenAccessibilityScreenReader && this.weekState.isFullShow;
    }, 100)
  }
}

export interface onStateChangeEvent {
  isVisible: boolean
}