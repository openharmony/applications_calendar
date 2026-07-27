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
import { SingleMonthlyViewModel } from '../viewmodel/SingleMonthlyViewModel';
import { SingleWeekView } from './SingleWeekView';
import { WeekTitle } from './WeekTitle';
import { WeekTitleViewModel } from '../viewmodel/WeekTitleViewModel';

import { DateBanner } from './DateBanner';
import { AgendaList } from './AgendaList';
import { SingleWeekViewModel } from '../viewmodel/SingleWeekViewModel';
import {
  CombineAnimateParam,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
} from '@app/common';
import { MonthlyModeState, MonthlyViewStateManager, MonthlyWeekState } from '../viewmodel/MonthlyViewState';
import { FrameLayout, MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { WeekTitleLayout } from '../layoutmodel/WeekTitleLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { DayCellLayout, ReadOnlyDayCellProp } from '../layoutmodel/DayCellLayoutRule';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { WeekNumView } from './WeekNumView';
import lazy { pointer } from '@kit.InputKit';

const TAG: string = '[MonthlyView][SigMonth]';
const MOD_FACTOR = 1.2; // 放大上滑动作的比例，是上滑动作更快
const BAR_H = 4; // 控制柄的高度
const BAR_W = 18; // 控制柄的宽度

/**
 * 基于月视图基础组件封装的业务组件，包含了Swiper无限下拉获取数据并基于月视图基础组件进行展示的逻辑
 *
 * @since 2023-08-16
 */
@Component
export struct SingleMonthlyView {
  // 月视图绑定的视图模型
  @ObjectLink viewModel: SingleMonthlyViewModel;

  // 周题
  @ObjectLink weekTitlesVM: WeekTitleViewModel;

  // 月视图绑定的布局参数
  @State layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  // 单天视图绑定的布局参数
  @State dayCellLayout: DayCellLayout = MonthViewLayoutModel.getInstance().dayLayout.value;

  @State showDivider: boolean = false;

  @Consume innerShowWeekNumber: boolean;

  @Consume monthDateViewAnimate: CombineAnimateParam;

  @Consume monthAgendaViewAnimate: CombineAnimateParam;

  @Consume isMaximizeRecovery: boolean;


  // 显示隐藏日程列表
  @Consume hideAgendaWindowMonth: boolean;

  // 是否需要显示开合按钮
  @Consume needShowHideButton: boolean;

  @StorageProp('windowAvoidAreaNavigationRectHeight') navigationHeight: number = 0;

  // 深色模式
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageProp(GlobalDataKeys.BG_THEME_COLOR) bgThemeColor: string = '#1AF76045';

  //冷启动不分帧
  @State stages: number = 5;

  private needPanDivide: boolean = DeviceConfig.instance().config.needPanDivide; // 是否需要隐形拖动

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //是否显示宫格底纹日期
  private showGridDate: boolean = DeviceConfig.instance().config.showGridBackgroundDate;

  // 滑动 scroller
  private scroller: Scroller = new Scroller();

  private themeColor: string = GlobalData.instance().get(GlobalDataKeys.THEME_COLOR) as string;

  @State weekState: MonthlyWeekState = MonthlyViewStateManager.getInstance().weekState;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  @LocalStorageProp('isFullScreen') isFullScreen: boolean = false;

  @Builder
  buildLarge() {
    Row() {
      this.buildGridWeekNum();
      Column() {
        //周标题
        WeekTitle({ viewModel: this.weekTitlesVM, index: this.viewModel.arrayIndex ?? 1 });

        Column() {
          if (this.innerShowWeekNumber && !this.layout.isGrid) {
            this.buildWeekNumLine();
          }
          if (this.layout.isGrid) {
            this.buildBackgroundDate();
            this.gridRowLine();
          }

          ForEach(new Array(6).fill(''), (item: string, index: number) => {
            SingleWeekView({
              viewModel: this.viewModel.weekViewModels[index] as SingleWeekViewModel,
              isSmall: this.layout.isSmall,
              index: index,
              totalWeekNum: this.viewModel.weekNumViewModel.weekNumbers.length
            })
          }, (item: string, index: number) => index.toString())

          this.buildBackToTodayCircle();
        }
        .id(`sigMonth_${this.viewModel.arrayIndex}`)
        .hitTestBehavior(HitTestMode.None)
        .margin({
          top: LengthMetrics.vp(WeekTitleLayout.marginDownGap),
          bottom: LengthMetrics.vp(WeekTitleLayout.marginDownGap),
          end: LengthMetrics.vp(this.layout.isGrid ? 0 : 16)
        })
        .width(this.layout.isGrid ? `100%` : `Calc(100% - 16vp)`)
        .accessibilityLevel('no')
      }
      .renderGroup(this.needCommerce) // pc添加renderGroup
      .id(CompId.BUILD_LARGE_DATE_AREA)
      .accessibilityLevel('no')
      .layoutWeight(1)
      .margin({ right: $r('sys.float.padding_level0') })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(this.layout.isGrid ? 8 : 16)
      .padding({
        top: this.navigationHeight > 0 ? MonthStaticLayout.monthAvoidPadding :
          (this.layout.isGrid ? 8 : MonthStaticLayout.singleMonthPadding),
        bottom: MonthStaticLayout.singleMonthPadding,
      })
      .visibility(this.monthDateViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY
            .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
              .animation(this.monthDateViewAnimate.scaleAnimateParam))
            .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
              .animation(this.monthDateViewAnimate.opacityAnimateParam))
            .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
              .animation(this.monthDateViewAnimate.translateAnimateParam)),
          TransitionEffect.OPACITY
            .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
              .animation(this.monthDateViewAnimate.scaleAnimateParam))
            .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
              .animation(this.monthDateViewAnimate.opacityAnimateParam))
            .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
              .animation(this.monthDateViewAnimate.translateAnimateParam)),
        )
      )
      .clip(true)

      this.buildDivideLine();
      this.buildAgendaArea();
    }
    .id(CompId.LARGE_SINGLE_MONTHLY_VIEW)
    .accessibilityLevel('no')
    .margin({ bottom: this.navigationHeight > 0 ? 12 : 0 })
    .size({
      width: '100%',
      height: `Calc(100% - ${this.navigationHeight > 0 ? MonthStaticLayout.monthAvoidPadding : 0}vp)`
    })
  }

  @Builder
  buildBackgroundDate() {
    Text('' + this.viewModel.curMonthlyInfo.solarMonth)
      .width('100%')
      .height('100%')
      .maxFontSize(this.getBackgroundDateSize(this.hideAgendaWindowMonth, this.isFullScreen))
      .minFontSize('200vp') // 此处使用最大最小字体自适应防止窗口过小显示不下
      .fontWeight(FontWeight.Medium)
      .textAlign(TextAlign.Center)
      .align(Alignment.Center)
      .position({ x: 0, y: 0 })
      .fontColor(this.bgThemeColor)
      .visibility(this.showGridDate ? Visibility.Visible : Visibility.None)
  }

  getBackgroundDateSize(hideAgendaWindow: boolean, isFullScreen: boolean): string {
    if (isFullScreen && this.needCommerce) { // 只有PC的最大化需要大字体
      return hideAgendaWindow ? '660vp' : '600vp';
    } else {
      return hideAgendaWindow ? '400vp' : '360vp';
    }
  }

  @Builder
  buildGridWeekNum() {
    if (this.layout.isGrid) {
      WeekNumView({
        viewModel: this.viewModel.weekNumViewModel
      })
    }
  }

  @Builder
  buildDivideLine() {
    Column() {
      Image($r('app.media.calendar_divider_bar'))
        .width($r('sys.float.padding_level4'))
        .height(48)
        .draggable(false)
        .borderRadius($r('sys.float.corner_radius_level4'))
        .visibility(this.showDivider ? Visibility.Visible : Visibility.Hidden)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width($r('sys.float.padding_level8'))
    .height('100%')
    .borderRadius($r('sys.float.corner_radius_level6'))
    .backgroundColor(Color.Transparent)
    .focusable(false)
    .onHover((isHover) => {
      if (isHover) {
        cursorControl.setCursor(pointer.PointerStyle.RESIZE_LEFT_RIGHT)
      } else {
        cursorControl.restoreDefault();
      }
    })
    .onBlur(() => {
      this.divideAction(false);
    })
    .gesture(GestureGroup(this.needPanDivide ? GestureMode.Parallel : GestureMode.Sequence,
      LongPressGesture({ repeat: false, fingers: this.needPanDivide ? 1 : 10 })// 先触发长按
        .onAction((event?: GestureEvent) => {
          this.divideAction(true);
        })
        .onActionCancel(() => {
          this.divideAction(false);
        }),
      PanGesture({ direction: PanDirection.Horizontal })// 再触发拖动
        .onActionStart((event: GestureEvent) => {
          const language = AppStorage.get<string>('language') ?? '';
          MonthViewLayoutModel.getInstance().onDivideInit(this.hideAgendaWindowMonth, language);
          if (event.source !== SourceType.Mouse) {
            this.divideAction(true);
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          this.longGestureUpdate(event);
        })
        .onActionCancel(() => {
          this.divideAction(false);
        })
        .onActionEnd((event: GestureEvent) => {
          this.divideAction(false);
          MonthViewLayoutModel.getInstance().onDivideEnd(event.offsetX);
        }))
      .onCancel(() => {
        this.divideAction(false);
      })
    )
  }

  // 长按拖动更新日期和日程区域比例
  private longGestureUpdate(event: GestureEvent): void {
    if (!event) {
      return;
    }
    const hideFlag = MonthViewLayoutModel.getInstance().onDivideChange(event.offsetX);
    this.hideAgendaWindowMonth = hideFlag;
  }

  // 改变隐形拖动按钮显隐以及renderGroup缓存的开关
  private divideAction(status: boolean): void {
    this.showDivider = status;
  }

  @Builder
  gridRowLine() {
    Row() {
      ForEach(new Array(6).fill(''), (item: string, index: number) => {
        Divider()
          .vertical(true)
          .strokeWidth('1px')
          .opacity(0.7)
          .color($r('sys.color.comp_divider'))
          .height('101%')
          .position({ x: `${(index + 1) * 14.2857}%` })
      })
    }
    .width(`100%`)
    .height('100%')
    .position({ x: 0, y: 0 })
    .visibility(this.viewModel.showDivider ? Visibility.Visible : Visibility.None)
  }

  monthPanMoveEnd(offsetY: number) {
    if (this.modeState.isForceSmall) {
      return;
    }
    this.monthAgendaViewAnimate.translateOptions = { y: 420 }; // 日程列表跟随日期视图上移
    this.monthAgendaViewAnimate.translateAnimateParam = {
      duration: 300, curve: Curve.Friction
    };
    this.viewModel.finishWeekHeightUpdate(offsetY);
  }

  @Builder
  buildSmall() {
    Scroll(this.scroller) {
      Column() {
        this.buildSmallDateArea();
        if (!this.modeState.isForceSmall) {
          this.weekShowButton();
          this.buildAgendaArea();
        }
      }
      .accessibilityLevel('no')
      .constraintSize(this.modeState.isInSmallFold || this.modeState.isForceSmall ? {} : {
        minHeight: (this.weekState.isWeekShow ? 1 : this.viewModel.weekAccount) *
        this.layout.weekRowHeight + this.viewModel.MIN_AGENDA_HEIGHT
      })
      .size({ width: '100%', height: '100%' })
    }
    .id(CompId.SMALL_SINGLE_MONTHLY_VIEW)
    .scrollable(this.viewModel.isWeekShow && !this.modeState.isInSmallFold
      ? ScrollDirection.Vertical : ScrollDirection.None)
    .edgeEffect(EdgeEffect.None, { alwaysEnabled: false })
    .gesture(
      PanGesture({ direction: PanDirection.Vertical })
        .onActionStart((event: GestureEvent) => {
          if (this.modeState.isForceSmall) {
            return;
          }
          this.weekState.singleWeekBackgroundColorOpen = true; //月视图上下滑动开启SingleWeekView背景色
          this.viewModel.initMonthHeight();
        })
        .onActionUpdate((event: GestureEvent) => {
          if (!event || this.modeState.isForceSmall) {
            return;
          }
            this.viewModel.updateWeekHeightByOffsetY(MOD_FACTOR * event.offsetY);
        })
        .onActionEnd((event: GestureEvent) => {
          this.monthPanMoveEnd(event.offsetY);
        })
        .onActionCancel((event: GestureEvent) => {
          this.monthPanMoveEnd(event.offsetY);
        })
    )
    .scrollBar(BarState.Auto)
    .accessibilityLevel('no')
  }

  @Builder
  buildSmallDateArea() {
    Column() {
      if (this.innerShowWeekNumber && !this.layout.isGrid) {
        this.buildWeekNumLine();
      }
      this.SigSmallMonthView();
      this.buildBackToTodayCircle();
    }
    .flexShrink(1)
    .id(`sigMonth_${this.viewModel.arrayIndex}`)
    .hitTestBehavior(HitTestMode.None)
    .width('Calc(100% - 16vp)')
    .padding({
      bottom: LengthMetrics.vp(WeekTitleLayout.marginDownGap),
    })
    .margin({
      end: LengthMetrics.vp(16)
    })
    .height(
      this.getMonthHeight(this.viewModel.isPanEdit, this.viewModel.editHeight, this.viewModel.isFullShow,
        this.navigationHeight, this.modeState.isInSmallFold, this.viewModel.isWeekShow, this.layout.weekRowHeight,
        this.viewModel.weekAccount)
    )
    .layoutWeight(this.modeState.isForceSmall ? 1 : 0)
    .backgroundColor(Color.Transparent)
    .borderRadius(16)
    .align(this.modeState.isForceSmall ? Alignment.Center : null)
    .padding({
      top: 0,
      bottom: ReadOnlyDayCellProp.circleLine * 2,
    })
    .visibility(this.monthDateViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.IDENTITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
      )
    )
    .clip(this.viewModel.isPanEdit)
  }

  /**
   * 月视图日期区域,在不同状态下的的高度
   * @param isPanEdit 是否处于跟手滑动过程中
   * @param editHeight 跟手滑动时跟手变更的高度
   * @param isFullShow 是否为全屏月视图状态
   * @param navigationHeight 当前的底部导航栏规避距离
   * @param isInSmallFold 是否为折叠机外屏
   * @param isWeekShow 是否为月视图单周展示状态
   * @param weekRowHeight 当前单周的高度
   * @param weekAccount 当前月份的周数
   * @returns 当前月视图的高度
   */
  getMonthHeight(isPanEdit: boolean, editHeight: number, isFullShow: boolean, navigationHeight: number,
    isInSmallFold: boolean, isWeekShow: boolean, weekRowHeight: number, weekAccount: number): Length {
    // 单月视图的边距,默认的下外边距加上防止选中圈截断的上下内边距
    const singleMonthMargin = ReadOnlyDayCellProp.circleLine * 2 + WeekTitleLayout.marginDownGap;
    if (isPanEdit) { // 处于跟手滑动状态,此时需要根据手滑动的距离动态改变当前月视图的高度
      return editHeight + singleMonthMargin;
    }

    if (isInSmallFold) { // 折叠外屏只有两种状态,全屏态和周状态,全屏态为正常月视图状态
      if (isWeekShow) { // 周状态,只有一周的高度
        return weekRowHeight + singleMonthMargin;
      } else { // 全屏态,填满屏幕并减去拽托按钮和下外边距
        return `calc(100% - 20vp + ${WeekTitleLayout.marginDownGap}vp)`;
      }
    }

    if (isFullShow) { // 当前处于全屏展示状态,需要填满屏幕,减去拽托按钮,下外边距以及对导航栏进行规避
      return `calc(100% - 24vp - ${navigationHeight}vp - ${WeekTitleLayout.marginDownGap}vp)`;
    }

    if (isWeekShow) { // 当前处于周状态,只需要展示一周的高度
      return weekRowHeight + singleMonthMargin;
    }
    // 正常态 周数乘以每周高度
    return weekAccount * weekRowHeight + singleMonthMargin;
  }

  @Builder
  buildWeekNumLine() {
    Divider()
      .vertical(true)
      .color($r('sys.color.comp_divider'))
      .height('100%')
      .width('1px')
      .position({
        start: LengthMetrics.vp(15.5 +
          (this.layout.isGrid && !this.layout.isSmall ? 0 : this.dayCellLayout.weekNumPadding))
      })
      .zIndex(101)
  }

  // 月视图日期区域
  @Builder
  SigSmallMonthView() {
    ForEach(new Array(6).fill(''), (item: string, index: number) => {
      SingleWeekView({
        viewModel: this.viewModel.weekViewModels[index] as SingleWeekViewModel,
        isSmall: this.layout.isSmall,
        index: index,
        totalWeekNum: this.viewModel.weekNumViewModel.weekNumbers.length
      })
    }, (item: string, index: number) => index.toString())
  }

  @Styles
  viewControlBarStyle(){
    .height(BAR_H)
    .width(BAR_W)
    .borderRadius(BAR_H / 2)
    .backgroundColor(this.isDarkMode ? '#333333' : '#C1C2C4')
    .position({
      x: '50%',
      y: '50%'
    })
  }

  /**
   * 视图控制柄
   */
  @Builder
  ViewControlBar() {
    Column() {
      Column()
        .viewControlBarStyle()
        .markAnchor({ x: BAR_W - BAR_H / 2, y: BAR_H / 2 })
        .rotate({
          angle: -30 * (this.weekState.currentVolume - 50) / 100,
          centerX: BAR_W - BAR_H / 2,
          centerY: BAR_H / 2
        })
      Column()
        .viewControlBarStyle()
        .markAnchor({ x: BAR_H / 2, y: BAR_H / 2 })
        .rotate({
          angle: 30 * (this.weekState.currentVolume - 50) / 100,
          centerX: BAR_H / 2,
          centerY: BAR_H / 2
        })
    }
    .width(64)
    .height(this.modeState.isInSmallFold ? 12 : 24)
    .focusable(true)
    .draggable(false)
  }

  @Builder
  weekShowButton() {
    Column() {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        this.ViewControlBar();
      }
      .padding({ bottom: this.modeState.isInSmallFold ? 8 : 0 })
      .accessibilityText(this.getAccessibilityText())
      .accessibilityDescription($r('app.string.broadcast_swipe_view_mode'))
      .width(64)
      .height(this.modeState.isInSmallFold ? 20 : 24)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .id(CompId.MONTH_VIEW_SLIDE_UP)
      .onClick(() => {
        this.weekState.singleWeekBackgroundColorOpen = true; //月视图上下滑动开启SingleWeekView背景色
        this.viewModel.finishWeekUpdateByButton();
      })
      .alignSelf(ItemAlign.Center)
      .backgroundColor(Color.Transparent)
    }
    .width('100%')
    .visibility(this.monthDateViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden)
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.IDENTITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
        TransitionEffect.OPACITY
          .combine(TransitionEffect.scale(this.monthDateViewAnimate.scaleOption)
            .animation(this.monthDateViewAnimate.scaleAnimateParam))
          .combine(TransitionEffect.opacity(this.monthDateViewAnimate.opacity)
            .animation(this.monthDateViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthDateViewAnimate.translateOptions)
            .animation(this.monthDateViewAnimate.translateAnimateParam)),
      )
    )
  }

  @Builder
  buildAgendaArea() {
    Column() {
      if (!this.modeState.isInSmallFold) {
        DateBanner({
          viewModel: this.viewModel.dateBannerVM
        })
      }
      AgendaList({
        monthModel: this.viewModel,
        viewModel: this.viewModel.agendaListModel
      })
    }
    .onSizeChange((_, newSize) => {
      this.viewModel.agendaListViewHeight = newSize?.height as number;
    })
    .id(CompId.SMALL_SINGLE_MONTHLY_VIEW_AGENDA_AREA)
    .width(this.layout.isSmall ? '100%' : '')
    .constraintSize({ minHeight: this.viewModel.agendaListViewMinHeight })
    .height('100%')
    .layoutWeight(this.layout.isSmall ? 1 : this.layout.agendaListRatio)
    .padding({
      start: this.layout.isSmall ? LengthMetrics.vp(16) : LengthMetrics.vp(0),
      end: LengthMetrics.vp(0),
    })
    // 详情开合按钮,正常状态月视图全屏,小折叠外屏非周状态
    .visibility((this.viewModel.hideAgendaWindow && this.needShowHideButton) ||
      (this.viewModel.isFullShow && !this.viewModel.isPanEdit) ||
      (!this.viewModel.isWeekShow && !this.viewModel.isPanEdit &&
      this.modeState.isInSmallFold) ?
    Visibility.None :
      (this.monthAgendaViewAnimate.visibility ? Visibility.Visible : Visibility.Hidden))
    .focusable(true)
    .focusOnTouch(true)
    .accessibilityLevel('no')
    .onClick(() => {
      focusControl.requestFocus(CompId.SLIDE_TAB_BAR);
    })
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.IDENTITY
          .combine(TransitionEffect.opacity(this.monthAgendaViewAnimate.opacity)
            .animation(this.monthAgendaViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthAgendaViewAnimate.translateOptions)
            .animation(this.monthAgendaViewAnimate.translateAnimateParam)),
        TransitionEffect.OPACITY
          .combine(TransitionEffect.opacity(this.monthAgendaViewAnimate.opacity)
            .animation(this.monthAgendaViewAnimate.opacityAnimateParam))
          .combine(TransitionEffect.translate(this.monthAgendaViewAnimate.translateOptions)
            .animation(this.monthAgendaViewAnimate.translateAnimateParam))
      )
    )
  }

  @Builder
  buildBackToTodayCircle() {
    // 空心圆
    Circle({
      width: this.viewModel.circleRadius,
      height: this.viewModel.circleRadius
    })
      .width(this.viewModel.circleRadius)
      .height(this.viewModel.circleRadius)
      .strokeWidth(ReadOnlyDayCellProp.circleLine)
      .stroke(this.themeColor)
      .fill(this.themeColor)
      .fillOpacity(0)
      .visibility(this.viewModel.isCircleVisible ? Visibility.Visible : Visibility.None)
      .markAnchor({
        start: LengthMetrics.vp(this.viewModel.circleRadius / 2),
        top: LengthMetrics.vp(this.viewModel.circleRadius / 2)
      })
      .position({ start: LengthMetrics.vp(this.viewModel.circleX), top: LengthMetrics.vp(this.viewModel.circleY) })

    // 实心圆
    Circle({
      width: this.viewModel.circleRadius,
      height: this.viewModel.circleRadius
    })
      .width(this.viewModel.circleRadius)
      .height(this.viewModel.circleRadius)
      .strokeWidth(ReadOnlyDayCellProp.circleLine)
      .stroke(this.themeColor)
      .fill(this.themeColor)
      .fillOpacity(1)
      .opacity(this.viewModel.fillCircleOpacity)
      .visibility(this.viewModel.isCircleVisible2 ? Visibility.Visible : Visibility.None)
      .markAnchor({
        start: LengthMetrics.vp(this.viewModel.circleRadius / 2),
        top: LengthMetrics.vp(this.viewModel.circleRadius / 2)
      })
      .position({ start: LengthMetrics.vp(this.viewModel.circleX), top: LengthMetrics.vp(this.viewModel.circleY) })
      .scale({
        x: this.viewModel.circleScale,
        y: this.viewModel.circleScale,
        centerX: '50%',
        centerY: '50%',
      })
  }

  private freshWeekAgendaArea: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const index: number = data?.data?.weekIndex;
    if (index >= 0) {
      this.viewModel.weekViewModels[index].freshSingleWeekAgendaBlockArea();
    }
  }

  aboutToAppear(): void {
    this.emitterCollector.on({ eventId: CommonInnerEvent.FRESH_MONTH_AGENDA_BLOCK_AREA }, this.freshWeekAgendaArea);
    this.viewModel.initViewEditHeight(); // 月视图出现时，校准基础高度，用于初始化控制柄状态
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  build() {
    if (this.layout.isSmall || this.modeState.isForceSmall) {
      this.buildSmall();
    } else {
      this.buildLarge();
    }
  }

  private getAccessibilityText() {
    const month = GlobalThis.getResourceStr($r('app.string.description_Month_Card'));
    const fullScreen = GlobalThis.getResourceStr($r('app.string.full_screen_mode'));
    const normalMode = GlobalThis.getResourceStr($r('app.string.normal_mode'));
    const singleWeek = GlobalThis.getResourceStr($r('app.string.single_week_mode'));
    const viewDrag = GlobalThis.getResourceStr($r('app.string.view_drag'));

    if (this.weekState.isWeekShow) {
      return `${month}${singleWeek}${viewDrag}`;
    }
    if (this.weekState.isFullShow) {
      return `${month}${fullScreen}${viewDrag}`;
    }
    return `${month}${normalMode}${viewDrag}`;
  }

}