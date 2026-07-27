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
import { DayCellLayout, ReadOnlyDayCellProp } from '../layoutmodel/DayCellLayoutRule';
import { FrameLayout } from '../layoutmodel/FrameLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';

import { SingleWeekViewModel } from '../viewmodel/SingleWeekViewModel';
import { SingleDayView } from './SingleDayView';
import { SingleWeekAgendaView } from './SingleWeekAgendaView';
import { WeekNumLayout } from '../layoutmodel/WeekNumLayoutRule';
import { CommonInnerEvent, CompId, DAY_PER_WEEK, I18nUtil, NumberFormatManager } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { displaySync } from '@kit.ArkGraphics2D';
import { emitter } from '@kit.BasicServicesKit';
import {
  DayViewState,
  MonthlyModeState,
  MonthlyViewStateManager,
  MonthlyWeekState
} from '../viewmodel/MonthlyViewState';

const TAG: string = '[MonthlyView][SigWeek]';

const FIRST_FRAME = 1;
const SECOND_FRAME = 2;
const THIRD_FRAME = 3;

@Preview
@Component
export struct SingleWeekView {
  // 月视图 单周视图 绑定的视图模型
  @ObjectLink viewModel: SingleWeekViewModel;

  // 月视图绑定的布局参数
  @Consume weekNumLayout: WeekNumLayout;

  @Consume innerShowWeekNumber: boolean;

  // 月视图绑定的布局参数
  @State layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  // 单天视图绑定的布局参数
  @State dayCellLayout: DayCellLayout = MonthViewLayoutModel.getInstance().dayLayout.value;

  @State weekState: MonthlyWeekState = MonthlyViewStateManager.getInstance().weekState;

  @State dayState: DayViewState = MonthlyViewStateManager.getInstance().dayState;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  private isSmall: boolean = false;

  private index: number = 0;

  private totalWeekNum: number = 0;

  //系统语言
  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  myDisplaySync: displaySync.DisplaySync = displaySync.create();

  @State stages: number = THIRD_FRAME;

  onLanguageChange() {
    NumberFormatManager.instance().onLanguageChange(this.language);
  }

  @Builder
  buildWeekNum() {
    Column(){
      Text(NumberFormatManager.instance().numberFormat(this.viewModel.dateInfo.weekNum).toString())
        .textAlign(TextAlign.Center)
        .maxFontSize(this.weekNumLayout.fontSize + 'vp')
        .minFontSize('4vp')
        .fontColor($r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .accessibilityLevel('no')
      if (I18nUtil.isChineseLanguage(this.language)) {
        Text($r('app.string.week_view'))
          .textAlign(TextAlign.Center)
          .maxFontSize(this.weekNumLayout.fontSize + 'vp')
          .minFontSize('4vp')
          .fontColor($r('sys.color.font_tertiary'))
          .fontWeight(FontWeight.Regular)
          .fontFamily('HarmonyHeiTi')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .accessibilityLevel('no')
      }
    }
    .justifyContent(FlexAlign.Center)
    .height(!this.isSmall ? this.dayCellLayout.circleSize : this.layout.weekRowHeight)
    .width(16)
    .flexShrink(1)
    .padding({
      bottom: this.dayCellLayout.isVerticalCell ?
      ReadOnlyDayCellProp.verticalGap : 0
    })
    .position({
      start: LengthMetrics.vp(this.layout.isGrid && !this.layout.isSmall ? 0 : this.dayCellLayout.weekNumPadding),
    })
    .backgroundColor(this.layout.isSmall ?
    $r('sys.color.ohos_id_color_sub_background') : Color.Transparent)
    .visibility(this.viewModel.isShow ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildSmallWeek() {
    Column() {
      if (this.innerShowWeekNumber) {
        this.buildWeekNum();
      }
      Row() {
        ForEach(new Array(DAY_PER_WEEK).fill(''), (item: string, index: number) => {
          SingleDayView({
            viewModel: this.viewModel.dayViewModels[index]
          })
        }, (item: string, index: number) => index.toString())
      }
      .padding({ bottom: ReadOnlyDayCellProp.circleLine })
      .height(this.dayCellLayout.circleSize)
      .backgroundColor((this.dayState.isBackToToday || !this.weekState.singleWeekBackgroundColorOpen) ?
      Color.Transparent :
        this.modeState.isInSmallFold ? $r('sys.color.ohos_id_color_sub_background') :
        Color.Transparent)
      .hitTestBehavior(HitTestMode.None)
      .alignItems(VerticalAlign.Top)
      .margin({
        start: LengthMetrics.vp(16 + (this.layout.isGrid && !this.layout.isSmall ? 0 :
          this.dayCellLayout.weekNumPadding))
      })
      .flexShrink(this.modeState.isInSmallFold ? 0 : 1)

      if (!this.modeState.isInSmallFold) {
        SingleWeekAgendaView({
          viewModel: this.viewModel,
          dataModel: this.viewModel.agendaBlockModel,
          index: this.index,
          totalWeekNum: this.totalWeekNum,
          dateInfo: this.viewModel.dateInfo,
        })
      }
    }
    .id(CompId.SINGLE_WEEK_AGENDA_AREA)
    .visibility(this.viewModel.isShow ? Visibility.Visible : Visibility.None)
    .height(
      (this.modeState.isInSmallFold &&
        (!this.weekState.isWeekShow || this.dayState.isEditPan) ? this.viewModel.smallFoldHeight :
      this.layout.weekRowHeight))
    .layoutWeight(this.modeState.isForceSmall || this.weekState.isFullShow ? 1 : 0)
    .offset({
      y: this.viewModel.isSelect ?
      Math.max(-this.viewModel.nowMonthMoveHeight, -this.viewModel.smallFoldHeight * this.index) :
        -this.viewModel.nowMonthMoveHeight
    })
    .zIndex(this.viewModel.isSelect ? 99 : this.viewModel.showIndex)
    //月视图左右滑动和回到今天的过程中关闭背景色
    .backgroundColor(this.dayState.isBackToToday || !this.weekState.singleWeekBackgroundColorOpen ?
    Color.Transparent : this.layout.isSmall ? $r('sys.color.ohos_id_color_sub_background') : Color.Transparent)
    .hitTestBehavior(HitTestMode.None)
    .width('100%')
  }

  @Builder
  buildLargeWeek() {
    Column() {
      if (this.stages >= FIRST_FRAME && !this.layout.isGrid && this.innerShowWeekNumber) {
        this.buildWeekNum();
      }

      if (this.stages >= SECOND_FRAME) {
        if (this.layout.isGrid) {
          this.gridColumnLine();
        }
        Row() {
          ForEach(new Array(DAY_PER_WEEK).fill(''), (item: string, index: number) => {
            SingleDayView({
              viewModel: this.viewModel.dayViewModels[index]
            })
          }, (item: string, index: number) => index.toString())
        }
        .padding({ bottom: ReadOnlyDayCellProp.circleLine })
        .hitTestBehavior(HitTestMode.None)
        .alignItems(VerticalAlign.Bottom)
        .margin({ start: LengthMetrics.vp(this.layout.isGrid ? 0 : 16) })
      }

      if (this.stages >= THIRD_FRAME) {
        SingleWeekAgendaView({
          viewModel: this.viewModel,
          dataModel: this.viewModel.agendaBlockModel,
          index: this.index,
          totalWeekNum: this.totalWeekNum,
          dateInfo: this.viewModel.dateInfo,
        })
      }
    }
    .id(CompId.SINGLE_WEEK_AGENDA_AREA)
    .layoutWeight(1)
    .hitTestBehavior(HitTestMode.None)
    .width('100%')
    .zIndex(2)
  }

  @Builder
  gridColumnLine() {
    Divider()
      .strokeWidth('1px')
      .opacity(0.7)
      .color($r('sys.color.comp_divider'))
      .vertical(false)
      .width('100%')
  }

  private sizeChangeHandle: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  aboutToAppear() {
    this.updateStage();
    this.sizeChangeHandle = (data: emitter.EventData) => this.sizeChange(data);
    emitter.on({ eventId: CommonInnerEvent.MONTH_VIEW_LAYOUT_CHANGE }, this.sizeChangeHandle);
  }

  aboutToDisappear(): void {
    emitter.off(CommonInnerEvent.MONTH_VIEW_LAYOUT_CHANGE, this.sizeChangeHandle);
  }

  sizeChange(data: emitter.EventData): void {
    this.stages = 0;
    this.updateStage();
  }

  updateStage() {
    if (this.stages === THIRD_FRAME) {
      return;
    }
    if (this.stages == 0) {
      this.myDisplaySync.start();
      this.myDisplaySync.on('frame', (frameInfo: displaySync.IntervalInfo) => {
        this.updateStage();
      });
    }
    this.stages += 1;
    if (this.stages == THIRD_FRAME) {
      this.myDisplaySync.stop();
    }
  }

  build() {
    if (this.viewModel?.isExist) {
      if (this.isSmall || this.modeState.isForceSmall) {
        this.buildSmallWeek();
      } else {
        this.buildLargeWeek();
      }
    }
  }
}