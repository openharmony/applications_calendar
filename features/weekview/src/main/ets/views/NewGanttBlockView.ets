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

import { behaviorEvents, ReportHiEventParams, ReportUtil, MILLS_PER_DAY, MILLS_PER_HOUR,
  DeviceConfig,
  CommonInnerEvent,
  Log} from '@app/common';
import { NewGanttBlockViewModel } from '../viewmodel/NewGanttBlockViewModel';
import { SaveTimeType } from '@app/feature.agenda';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'NewGanttBlockView';

@Component
export struct NewGanttBlockView {
  @Consume navPathStack: NavPathStack;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  //主题色
  @StorageProp('bgThemeColor') bgThemeColor: string = '';

  @ObjectLink viewModel: NewGanttBlockViewModel;

  @Consume isAnimation: boolean;

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  private openCreatePop: (data: emitter.EventData, position: Position) => void =
    (data: emitter.EventData, position: Position) => {};

  showAddAgendaPage() {
    const dayTimeStamp = this.viewModel.ganttStartTime + MILLS_PER_DAY * this.viewModel.widthCount;
    let eventData: emitter.EventData = {
      data: {
        needSaveTime: SaveTimeType.SAVE_ALL_TIME,
        agendaDateParam: dayTimeStamp + this.viewModel.heightStart * MILLS_PER_HOUR,
        agendaDateLength: this.viewModel.heightCount * MILLS_PER_HOUR,
      }
    };
    if (this.isCreateAgendaPopup) {
      const position: Position = {
        x: this.viewModel.positionX + this.viewModel.width / 2,
        y: this.viewModel.positionY + this.viewModel.height / 2,
      }
      this.openCreatePop(eventData, position);
    } else {
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    }
    this.viewModel.isAddShow = false;
    // 甘特图点击新建日程打点
    let params: ReportHiEventParams = {
      SOURCE_PAGE: this.viewModel.tabType,
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.ganttCreateAgenda, params);
  }

  // 甘特图移动新建日程打点
  reportMoveBlock() {
    let params: ReportHiEventParams = {
      SOURCE_PAGE: this.viewModel.tabType,
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.moveGanttBlock, params);
  }

  @Builder
  dragBlock() {
    Column() {
      SymbolGlyph($r('sys.symbol.plus'))
        .width('50%')
        .height('50%')
        .fontColor([this.themeColor])
    }
    .border({ width: '1px', color: this.themeColor })
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.bgThemeColor)
    .height(this.viewModel.height)
    .width(this.viewModel.width)
    .opacity(0.5)
  }

  @Builder
  buildUpArea() {
    Column() {
    }
    .width('100%')
    .height('15%')
    .hitTestBehavior(HitTestMode.Block)
    .responseRegion({
      x: 0,
      y: '-100%',
      width: '100%',
      height: '200%'
    })
    .gesture(
      PanGesture()
        .onActionStart((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.isAnimation = true;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.viewModel.updateNewAgendaHeight(event.offsetY, true);
        })
        .onActionEnd((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.viewModel.updateUpHeight();
          this.isAnimation = false;
        })
        .onActionCancel(() => {
          this.viewModel.updateUpHeight();
          this.isAnimation = false;
        })
    )
    .onClick(() => {
      this.showAddAgendaPage();
    })
  }

  @Builder
  buildDownArea() {
    Column() {
    }
    .width('100%')
    .height('15%')
    .hitTestBehavior(HitTestMode.Block)
    .responseRegion({
      x: 0,
      y: 0,
      width: '100%',
      height: '200%'
    })
    .gesture(
      PanGesture()
        .onActionStart((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.isAnimation = true;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          if (event) {
            this.viewModel.updateNewAgendaHeight(-event.offsetY, false);
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.viewModel.updateDownHeight();
          this.isAnimation = false;
        })
        .onActionCancel((event: GestureEvent) => {
          this.viewModel.updateDownHeight();
          this.isAnimation = false;
        })
    )
    .onClick(() => {
      this.showAddAgendaPage();
    })
  }

  @Builder
  buildAddArea() {
    Column() {
      SymbolGlyph($r('sys.symbol.plus'))
        .fontColor([this.themeColor])
        .fontSize('16vp')
    }
    .height('70%')
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .hitTestBehavior(HitTestMode.Block)
    .gesture(
      PanGesture()
        .onActionStart((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.isAnimation = true;
        })
        .onActionUpdate((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          if (event) {
            this.viewModel.positionX = this.viewModel.originalX + event.offsetX
            this.viewModel.positionY = this.viewModel.originalY + event.offsetY
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (!this.processGestureEvent(event)) {
            return;
          }
          this.viewModel.updatePosition();
          this.isAnimation = false;
          this.reportMoveBlock();
        })
        .onActionCancel((event: GestureEvent) => {
          this.viewModel.updatePosition();
          this.isAnimation = false;
          this.reportMoveBlock();
        })
    )
    .onClick(() => {
      this.showAddAgendaPage();
    })
  }

  // 新建日程块屏蔽鼠标滚轮和触摸板双指滑动操作
  private processGestureEvent(event: GestureEvent) {
    if (!event) {
      return false;
    }
    if ((event.sourceTool === SourceTool.MOUSE || event.sourceTool === SourceTool.TOUCHPAD) &&
      (event.axisVertical !== 0 || event.axisHorizontal !== 0)) {
      Log.info(TAG, `event return, source : ${event.source}  sourceTool : ${event.sourceTool} ` +
        ` axisVertical : ${event.axisVertical}  axisHorizontal : ${event.axisHorizontal}`)
      return false;
    }
    return true;
  }

  build() {
    Column() {
      Column() {
        this.buildUpArea()
        this.buildAddArea()
        this.buildDownArea()
      }
      .border({
        width: this.viewModel.BLOCK_BORDER_WIDTH,
        color: this.themeColor,
        radius: this.viewModel.BLOCK_BORDER_RADIUS,
        style: BorderStyle.Dashed
      })
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .backgroundColor(this.bgThemeColor)

      Column()
        .border({ radius: 10, color: this.themeColor, width: 1 })
        .width(10)
        .height(10)
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .position({ x: '50%', y: 0 })
        .markAnchor({ x: 5, y: 5 })
        .hitTestBehavior(HitTestMode.Transparent)
      Column()
        .border({ radius: 10, color: this.themeColor, width: 1 })
        .width(10)
        .height(10)
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .position({ x: '50%', y: '100%' })
        .markAnchor({ x: 5, y: 5 })
        .hitTestBehavior(HitTestMode.Transparent)
    }
    .height(this.viewModel.height)
    .width(this.viewModel.width)
    .position({
      x: this.viewModel.positionX,
      y: this.viewModel.positionY,
    })
    .visibility(this.viewModel.isAddShow ? Visibility.Visible : Visibility.None)
  }
}