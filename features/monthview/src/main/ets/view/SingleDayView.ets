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
  CommonInnerEvent,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MILLS_PER_HOUR,
  statisticEvents,
  ThrottleFunction,
} from '@app/common';
import {
  AgendaMenuOpt,
  AgendaPopupContent,
  getPopOffsetY
} from '@app/feature.agenda';
import { SingleDayViewModel } from '../viewmodel/SingleDayViewModel';
import { ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import emitter from '@ohos.events.emitter';
import { DayViewState, MonthlyViewState, MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import { DayCellLayout, gridDayCellBreakPoints } from '../layoutmodel/DayCellLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import lazy { KeyCode } from '@kit.InputKit';
import { DAY_PER_WEEK, HOURS_PER_DAY } from '@app/common';
import { CopyHelper, CreatePopupContent } from '@app/feature.agenda';
import { SINGLE_DAY_MENU_OPTS, SINGLE_DAY_MENU_OPTS_WITH_PASTE } from './ConstantUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { WeekAgendaState } from '../viewmodel/WeekAgendaState';
import { FrameLayout } from '../layoutmodel/FrameLayoutRule';

const TAG: string = '[MonthlyView][SigDay]';
const MAX_CIRCLE_SIZE: number = gridDayCellBreakPoints[gridDayCellBreakPoints.length - 1].value.circleSize;

@Preview
@Component
export struct SingleDayView {
  // 月视图 单天视图 绑定的视图模型
  private viewModel: SingleDayViewModel | undefined = undefined;

  // 单天视图绑定的布局参数
  @State dayCellLayout: DayCellLayout = MonthViewLayoutModel.getInstance().dayLayout.value;

  @State dayState: DayViewState = MonthlyViewStateManager.getInstance().dayState;

  @State @Watch('currentDateChange') currentDate: number = MonthlyViewStateManager.getInstance().state.currentDate;

  @LocalStorageLink('windowHeight') windowHeight: number = 0;

  @State dayAccessibilityText: string | undefined = '';

  @StorageProp(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER) @Watch('updateDayAccessibilityText') isOpenAccessibilityScreenReader: boolean = false;

  // 点击条目的具体显示时间
  @State clickDate: number = 0;

  // 点击条目的弹窗显示标志位
  @State showPopup: boolean = false;

  // 是否显示新建日程跟手弹窗
  @State isCreatePopupShow: boolean = false;

  // 关闭新建日程跟手弹窗时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  private createPageData: emitter.EventData = {};

  @Consume keyCtrlState: boolean;

  // 菜单选项
  private menuOpts: Array<AgendaMenuOpt> = SINGLE_DAY_MENU_OPTS;

  @State compId: string | undefined = '';

  @State popOffsetY: number = 0;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 月视图绑定的布局参数
  @State @Watch('layoutChangeHandler') layout: FrameLayout = MonthViewLayoutModel.getInstance().frameProp.value;

  @State isGrid: boolean = this.layout.isGrid;

  layoutChangeHandler() {
    this.isGrid = this.layout.isGrid;
  }

  @Builder
  buildMenuContent() {
    AgendaPopupContent({
      info: [],
      date: this.viewModel?.dayData.getTimeStamp(),
      isSmallWindow: false,
      isMenu: true,
      menuOpts: CopyHelper.instance().getStashEventInfo() ? SINGLE_DAY_MENU_OPTS_WITH_PASTE : SINGLE_DAY_MENU_OPTS,
      onClickContent: () => this.showPopup = false,
      onMenuChosen: (opt: AgendaMenuOpt, id: number) => {
        if (opt === AgendaMenuOpt.CREATE) {
          this.createPageData = {
            data: {
              agendaDateParam: this.viewModel?.dayData.getTimeStamp(),
            }
          };
          this.isCreatePopupShow = true;
        } else {
          this.isCreatePopupShow = false;
        }
        this.showPopup = false
      },
      onPasteHandle: () => {
        if (this.viewModel) {
          CopyHelper.instance().pasteEventInfo(this.viewModel.dayData.getTimeStamp());
        }
      }
    })
  }

  @Builder
  buildPopupContent() {
    CreatePopupContent({
      createPageData: this.createPageData,
      discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
      onCreatePageDismiss: () => {
        this.isCreatePopupShow = false;
      }
    })
  }

  build() {
    Stack()
      .width('14.2857%')
      .drawModifier(this.viewModel)
      .height(this.needCommerce && this.isGrid ? MAX_CIRCLE_SIZE : this.dayCellLayout.circleSize)
      .onClick(this.onClickSingleDay)
      .bindContextMenu(this.buildMenuContent(), ResponseType.RightClick)
      .bindPopup(this.isCreatePopupShow, {
        builder: this.buildPopupContent(),
        popupColor: $r('sys.color.ohos_id_color_panel_bg'),
        radius: 16,
        backgroundBlurStyle: BlurStyle.NONE,
        mask: false,
        placement: Placement.Right,
        offset: { y: this.popOffsetY },
        onWillDismiss: (dismiss) => {
          this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
        },
        onStateChange: (ev) => {
          if (!ev.isVisible) {
            this.isCreatePopupShow = false;
          }
        },
        shadow: ShadowStyle.OUTER_DEFAULT_SM
      })
      .id(this.compId)
      .accessibilityText(this.dayAccessibilityText)
      .accessibilityDescription(' ')
      .accessibilitySelected(this.viewModel?.isSelect)
      .focusable(true)
      .focusBox({
        margin: LengthMetrics.vp(-1)
      })
      .focusOnTouch(true)
      .onKeyEvent((event: KeyEvent) => {
        Log.info(TAG, 'Press direction key and switch highlight date');

        let newDisplayDate: number = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
        if (event.keyCode === KeyCode.KEYCODE_DPAD_UP && event.type === KeyType.Down) {
          newDisplayDate = newDisplayDate - DAY_PER_WEEK * HOURS_PER_DAY * MILLS_PER_HOUR;
          event.stopPropagation();
        } else if (event.keyCode === KeyCode.KEYCODE_DPAD_DOWN && event.type === KeyType.Down) {
          newDisplayDate = newDisplayDate + DAY_PER_WEEK * HOURS_PER_DAY * MILLS_PER_HOUR;
          event.stopPropagation();
        } else if (event.keyCode === KeyCode.KEYCODE_DPAD_LEFT && event.type === KeyType.Down) {
          newDisplayDate = newDisplayDate - HOURS_PER_DAY * MILLS_PER_HOUR;
          event.stopPropagation();
        } else if (event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT && event.type === KeyType.Down) {
          newDisplayDate = newDisplayDate + HOURS_PER_DAY * MILLS_PER_HOUR;
          event.stopPropagation();
        }
        GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, newDisplayDate);
        emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
        ReportUtil.reportStatisticEvent(statisticEvents.monthClickDate);
        return false;
      })
      .onMouse((ev) => {
        if (ev.button === MouseButton.Right && ev.action === MouseAction.Release) {
          const windowHeight = this.windowHeight ?? 560;
          this.popOffsetY = getPopOffsetY(ev.windowY, windowHeight);
        }
        //移动到日期区域，将hover pop关掉
        WeekAgendaState.getInstance().agendaBlockState.resetAgendaHoverFlag();
      })
  }

  onClickSingleDay: (event?: ClickEvent) => void = () => {
    if (this.viewModel) {
      ThrottleFunction.instance().throttle(TAG, (): void => this.viewModel?.onClickChangeDisplayDate(
              this.dayState.isBackToToday, this.dayAccessibilityText, true), 50);
    }
    //点击日期区域，将pop关掉
    WeekAgendaState.getInstance().showPopup = false;
  }

  aboutToAppear(): void {
    if (!this.viewModel) {
      Log.error(TAG, 'this.viewModel is error');
      return;
    }

    this.compId = this.viewModel?.getCompId();
    this.updateDayAccessibilityText();
    this.viewModel.vmSelectChange = () => {
      this.compId = this.viewModel?.getCompId();
      this.updateDayAccessibilityText();

      // 回到今天按钮，失焦，主动聚焦
      if (this.dayState.isBackToToday && this.viewModel && this.viewModel.isSelect && this.viewModel.isToday) {
        focusComponentById(this.viewModel.getCompId(), 500);
      }
    }
  }

  aboutToDisappear(): void {
    if (!this.viewModel) {
      Log.error(TAG, 'this.viewModel is error');
      return;
    }
    this.viewModel.vmSelectChange = () => {};
  }

  currentDateChange() {
    this.updateDayAccessibilityText();
    this.compId = this.viewModel?.getCompId();
  }

  updateDayAccessibilityText() {
    const doubleClickAgendaStr = GlobalThis.getResourceStr($r('app.string.broadcast_double_tap_view_agenda'));
    const swipeMonthStr = GlobalThis.getResourceStr($r('app.string.broadcast_swipe_month'));
    const doubleClickStr = GlobalThis.getResourceStr($r('app.string.double_click_finger_execute'));
    if (this.isOpenAccessibilityScreenReader) {
      this.dayAccessibilityText = this.viewModel?.getAccessibilityText();
      if (this.viewModel?.isSelect && this.viewModel?.isToday) {
        this.dayAccessibilityText += `, ${doubleClickAgendaStr}, ${swipeMonthStr}`;
      } else if (this.viewModel?.isFirstDayOfMonth) {
        this.dayAccessibilityText += `, ${doubleClickStr}, ${swipeMonthStr}`;
      } else {
        this.dayAccessibilityText += `, ${doubleClickStr}`;
      }
      Log.info(TAG, `updateDayAccessibilityText dayAccessibilityText: ${this.dayAccessibilityText}`);
    }
  }
}

