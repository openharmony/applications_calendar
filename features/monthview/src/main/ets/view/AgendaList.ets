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
  AgendaListItemViewModel,
  AgendaUtil,
  BigFontSize,
  CHINESE_HOLIDAY_STATE_VALUE,
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  DateUtil,
  DeviceConfig,
  EmitterCollector,
  FeatureType,
  GlobalDataKeys,
  Log,
  PreviewFromType,
} from '@app/common';

import { SingleMonthlyViewModel } from '../viewmodel/SingleMonthlyViewModel';
import lazy { MonthAgendaItem } from './MonthAgendaItem';
import { ImportantAgendaItem } from '@app/feature.agenda';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { FrameLayout, MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { emitter } from '@kit.BasicServicesKit';
import { display, LengthMetrics } from '@kit.ArkUI';
import { SlidingStackHelper } from '../utils/SlidingStackHelper';
import { MonthlyModeState, MonthlyViewState, MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import { MonthAgendaListViewModel } from '../viewmodel/MonthAgendaListViewModel';

const TAG: string = '[MonthlyView][AgendaList]';

const LIST_GENERAL_TRANSITION_DURING = 150; // 月视图下日程列表的通用出入场动效时长

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

// 日程列表渐入渐出的通用属性
@Styles
function opacityTransition() {
  .transition(TransitionEffect.OPACITY.animation({
    duration: LIST_GENERAL_TRANSITION_DURING,
    curve: Curve.Sharp
  }))
}

@Component
export struct AgendaList {
  // 月视图绑定的视图模型
  private monthModel?: SingleMonthlyViewModel;

  // 日程列表视图绑定的视图模型
  @ObjectLink viewModel: MonthAgendaListViewModel;

  // 嵌套使用
  @State isTodayAgendaExist: boolean = false;

  @State searchText: string = '';

  // 判断数据是否 Ready
  @State isTodayAgendaReady: boolean = false;

  @Consume isAnimation: boolean;

  @Consume isMaximizeRecovery: boolean;

  @State isTop: boolean = true; // 列表是否滚动到顶

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 月视图绑定的布局参数
  @Consume layout: FrameLayout;

  @Consume monthAgendaViewAnimate: CombineAnimateParam;

  @State selectable: boolean = false;

  @LocalStorageLink('windowHeight') windowHeightInVp: number = 0;

  @StorageLink('tabIndex') tabsIndex: number = 1;

  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private cardSplitRowWidth: number = 600; // 多少宽度分行显示

  private bottomAvoidAreaHeight = DeviceConfig.instance().config.bottomAvoidAreaHeight;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  @State slidingStackHelper: SlidingStackHelper = new SlidingStackHelper();

  @State monthlyViewState: MonthlyViewState = MonthlyViewStateManager.getInstance().state;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State scheduleCardPageLoaded: boolean = false;

  private agendaListTotalMargin: number = DeviceConfig.instance().config.agendaListTotalMargin;

  @State isScrolling: boolean = false; //月视图是否正在滑动

  @Builder
  initItemFunc() {
  };

  aboutToAppear() {
    hiTraceMeter.startTrace(traceEvents.monthAgendaListAppear, 0);
    this.isTodayAgendaReady = this.viewModel.isTodayAgendaReady;
    this.isTodayAgendaExist = this.viewModel.isTodayAgendaExist;
    this.viewModel.onIsTodayAgendasChange = (isTodayAgendaExist: boolean, isTodayAgendaReady: boolean) => {
      this.onTodayAgendasChange(isTodayAgendaExist, isTodayAgendaReady);
    };

    // 初始化滑动叠卡控制器
    this.slidingStackHelper.init(this.viewModel.agendaScroller)
    this.viewModel.slidingStackHelper = this.slidingStackHelper;
    hiTraceMeter.finishTrace(traceEvents.monthAgendaListAppear, 0);
  }

  aboutToDisappear() {
    this.emitterCollector.off();
  }

  onTodayAgendasChange(isTodayAgendaExist: boolean, isTodayAgendaReady: boolean) {
    this.isTodayAgendaReady = isTodayAgendaReady;
    this.isTodayAgendaExist = isTodayAgendaExist;
  }

  @Builder
  normalAgendaDataSources() {
    LazyForEach(this.viewModel?.sigAgendaManager?.normalAgendaDataSources,
      (info: AgendaListItemViewModel, index: number) => {
        ListItem() {
          Column() {
            MonthAgendaItem({
              info,
              isSmall: this.layout.isSmall,
              index: this.viewModel.arrayIndex ?? 0,
              isScrolling: this.isScrolling
            })
            Divider()
              .color($r('sys.color.comp_divider'))
              .strokeWidth('1px')
              .margin({ top: 12, bottom: 12 })
              .opacityTransition()
              .visibility(this.showNormalAgendaBottomDivider(index) ? Visibility.Visible : Visibility.None)
          }
        }
        .id(CompId.NORMAL_AGENDA_LIST_ITEM + info.mId)
        .renderGroup(!this.isMaximizeRecovery)
        .margin({
          bottom: index === this.getNormalAgendaLength() - 1 ? 0 : 12
        })
        .opacityTransition()
      }, (item: AgendaEventInfo, index: number) => item.getEditAblePropStr() + '-' + index + '-' +
        this.showNormalAgendaBottomDivider(index) + '-' + this.checkItemIsLast(index))
  }

  @Builder
  importantAgendaDataSources() {
    LazyForEach(this.viewModel?.sigAgendaManager?.importantAgendaDataSources,
      (info: AgendaListItemViewModel, index: number) => {
        ListItem() {
          Column() {
            ImportantAgendaItem({
              info,
              selectable: $selectable,
              searchText: this.searchText,
              fromType: FromType.MONTH_VIEW,
              previewFromType: PreviewFromType.MONTH_VIEW,
              index: this.viewModel?.arrayIndex ?? 0,
              isScrolling: this.isScrolling,
              isSmall: this.layout.isSmall
            })
            if (this.showImportantAgendaBottomDivider(index)) {
              this.buildDivider($r('sys.float.padding_level6'), $r('sys.float.padding_level6'))
            }
          }
        }
        .id(AgendaUtil.getShareIdByIndexAndInfo(info, (this.viewModel?.arrayIndex ?? 0)))
        .renderGroup(!this.isMaximizeRecovery)
        .margin({
          bottom: index === this.getImportantAgendaLength() - 1 ? 0 : 12
        })
        .opacityTransition()
      }, (item: AgendaEventInfo, index) => item.getEditAblePropStr() + '-' + index + '-' +
        this.showImportantAgendaBottomDivider(index) + '-' + this.checkImportantItemIsLast(index))
  }

  @Builder
  buildDivider(bottom: Resource, top: Resource) {
    Divider()
      .color($r('sys.color.comp_divider'))
      .strokeWidth('1px')
      .margin({ bottom: bottom, top: top })
  }

  computeListWidth() {
    return this.layout.agendaListViewWidth;
  }

  @Builder
  noAgendaImage() {
    Column() {
      Image($r('app.media.ic_no_agenda'))
        .width(96)
        .height(96)
        .margin({ bottom: MonthlyViewStateManager.getInstance().modeState.isSmallFoldDevice ? 0 : 8 })
        .commonProperties()
        .edgeAntialiasing(this.antialiasingNumber)
      Text($r('app.string.agenda_empty_text'))
        .fontSize(14)
        .opacity(0.6)
        .id(CompId.NO_AGENDA)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
    }
    .renderGroup(!this.isMaximizeRecovery)
    .height('100%')
    .width('100%')
    .padding({
      end: LengthMetrics.vp(16),
      bottom: LengthMetrics.vp(this.windowAvoidAreaNavigationRectHeight + MonthStaticLayout.monthPaddingTop)
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .visibility(
      !this.isTodayAgendaReady || this.isTodayAgendaExist ?
        Visibility.None : Visibility.Visible
    )
    .opacityTransition()
  }

  /**
   * 获取底部占位高度。设置为一个卡片item最大高度，保证叠卡回弹时不截断
   */
  getListBottomPlaceholder(): number {
    // 大2档及以下，默认高度均可满足不截断
    if (this.fontSizeScale <= BigFontSize.BIG_FONT_SIZE_TWO) {
      return 90;
    }
    // 大3档，高度最大的item为【包含地点和两行标题的普通日程】
    if (this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE) {
      // 大3
      return 120;
    }
    // 大4档及以后，高度最大的item为【开启农历显示的跨年重要日】
    if (this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE_2X) {
      // 大4
      return 180;
    }
    if (this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE_3X) {
      // 大5
      return 210;
    }
    // 大6字体
    return 360;
  }

  @Builder
  buildListItem() {
    if (this.isTodayAgendaExist && this.isTodayAgendaReady) {
      this.normalAgendaDataSources();
      this.importantAgendaDataSources();
    }
  }

  @Builder
  buildAgendaList() {
    List({ scroller: this.viewModel.agendaScroller }) {
      this.buildListItem();
    }
    .id(CompId.AGENDA_LIST)
    .borderRadius($r('sys.float.corner_radius_level10'))
    .scrollBar(BarState.Off)
    .width('calc(100% - 16vp)')
    .height('100%')
    .nestedScroll({ scrollBackward: NestedScrollMode.SELF_FIRST, scrollForward: NestedScrollMode.PARENT_FIRST })
    .contentEndOffset(this.windowAvoidAreaNavigationRectHeight)
    .enableScrollInteraction(this.viewModel.isWeekShow || !this.layout.isSmall || this.viewModel.canScroll)
    .onDrop((event: DragEvent) => {
    })
    .onScrollStart(() => {
      hiTraceMeter.startTrace(traceEvents.monthAgendaListSwipe, 0)
      this.isAnimation = true;
    })
    // 列表滑动事件
    .onDidScroll((scrollOffset: number, scrollState: ScrollState) => {
      this.slidingStackHelper.onDidScroll(scrollOffset, scrollState);
    })
    // 列表滑动索引回调
    .onScrollIndex((start: number, end: number, center: number) => {
      this.slidingStackHelper.onScrollIndex(start, end, center);
      this.isTop = start === 0;
    })
    .onScrollStart(() => {
      this.slidingStackHelper.onScrollStart();
    })
    .onReachEnd(() => {
      this.slidingStackHelper.onReachEnd();
    })
    .onTouch(event => {
      if (event.type == TouchType.Up) {
        // 手指抬起。(onScrollStop有概率会延迟1~2秒触发，导致叠卡回弹有延迟，这里使用Touch事件根据手指抬起来判断停止滑动)
        Log.info(TAG, `onScrollStop by onTouch up`)
        this.slidingStackHelper.onScrollStop();
      }
    })
    // 底部新增回弹效果 如果是顶部则不支持回弹
    .edgeEffect(this.isScrolling ? EdgeEffect.None : EdgeEffect.Spring,
      {
        alwaysEnabled: true,
       // effectEdge: this.layout.isSmall ? EffectEdge.END : EffectEdge.START | EffectEdge.END,
      })
    // 叠卡顶部偏移量
    .contentStartOffset(SlidingStackHelper.CONTENT_START_OFFSET)
    // 摩擦系数 默认0.75 越大阻力越强
    .friction(SlidingStackHelper.FRICTION)
    // 列表项滚动结束对齐效果
    .scrollSnapAlign(this.slidingStackHelper.scrollSnapAlign)
    .parallelGesture(PanGesture({ direction: PanDirection.Down })
      .onActionStart((event: GestureEvent) => {
        if (!this.layout.isSmall || !this.monthModel) {
          return;
        }
        //月视图上下滑动开启SingleWeekView背景色
        MonthlyViewStateManager.getInstance().weekState.singleWeekBackgroundColorOpen = true;
        this.monthModel.initMonthHeight();
        this.isScrolling = true;
      })
      .onActionUpdate((event: GestureEvent) => {
        if (!event || !this.layout.isSmall || !this.monthModel) {
          return;
        }
        this.monthModel.updateWeekHeightByOffsetY(event.offsetY);
      })
      .onActionEnd((event: GestureEvent) => {
        this.finishAnimation(event);
      })
      .onActionCancel((event: GestureEvent) => {
        this.finishAnimation(event);
      }))
    .onScrollStop(() => {
      this.isAnimation = false;
      hiTraceMeter.finishTrace(traceEvents.monthAgendaListSwipe, 0)
      this.slidingStackHelper.onScrollStop();
    })
    .onGestureJudgeBegin((gestureInfo: GestureInfo, event: BaseGestureEvent) => {
      // 若该手势类型为拖动手势，转换为拖动手势事件
      if (gestureInfo.type == GestureControl.GestureType.PAN_GESTURE) {
        // 小屏状态list没滚到顶部或者当前月视图可滚动则拦截拖动手势事件
        if ((!this.isTop && this.layout.isSmall) || this.viewModel.canScroll) {
          return GestureJudgeResult.REJECT;
        }
      }
      return GestureJudgeResult.CONTINUE;
    })
  }

  private finishAnimation(event: GestureEvent) {
    if (!this.layout.isSmall || !this.monthModel) {
      return;
    }
    this.monthModel?.updateAgendaAreaMinHeight();
    this.monthAgendaViewAnimate.translateOptions = { y: 420 } // 日程列表跟随日期视图上移
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: 300, curve: Curve.Friction
    };
    this.monthModel.finishWeekHeightUpdate(event.offsetY);
    this.isScrolling = false;
  }

  private shouldSetEdgeEffectSpring(): boolean {
    // 仅小屏顶部不设置回弹效果
    return !(this.layout.isSmall && this.isTop);
  }

  build() {
    Row() {
      this.noAgendaImage();
      this.buildAgendaList();
      ScrollBar({
        scroller: this.viewModel.agendaScroller,
        direction: ScrollBarDirection.Vertical,
        state: BarState.Auto
      })
        .margin({ bottom: 28 })
        .width(16)
        .visibility(this.isTodayAgendaExist && !this.viewModel.canScroll ? Visibility.Visible : Visibility.None)
    }
    .height('100%')
    .width('100%')
    .layoutWeight(1)
  }

  private getNormalAgendaLength(): number {
    return this.viewModel?.sigAgendaManager?.normalAgendaDataSources.totalCount() ?? 0;
  }

  private getImportantAgendaLength(): number {
    return this.viewModel?.sigAgendaManager?.importantAgendaDataSources.totalCount() ?? 0;
  }

  /**
   * 普通日程下方是否要展示分割线(分割线放在listitem的内部，是为了做滑动叠卡动效时避免分割线被计算为单独item)
   * 展示条件：index刚好为最后一个 && 下方有重要日或订阅卡片 或 有推荐订阅banner的内容 或 有课表卡片
   * @param index
   * @returns
   */
  private showNormalAgendaBottomDivider(index: number): boolean {
    return index === this.getNormalAgendaLength() - 1 &&
      (this.getImportantAgendaLength() !== 0);
  }

  private checkItemIsLast(index: number): boolean {
    return index === this.getNormalAgendaLength() - 1;
  }

  private checkImportantItemIsLast(index: number): boolean {
    return index === this.getImportantAgendaLength() - 1;
  }

  /**
   * 重要日日程下方是否要展示分割线
   * 展示条件：index刚好为最后一个 && 有课表卡片
   * @param index
   * @returns
   */
  private showImportantAgendaBottomDivider(index: number): boolean {
    return index === this.getImportantAgendaLength() - 1;
  }
}