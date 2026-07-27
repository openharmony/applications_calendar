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

import { SingleMonthViewModel } from '../viewmodel/SingleMonthViewModel';
import {
  CalendarDate,
  CommonInnerEvent,
  DateUtil,
  GlobalData,
  GlobalDataKeys,
  Log,
  ReportUtil,
  statisticEvents,
  TabType,
  GlobalThis
} from '@app/common';
import emitter from '@ohos.events.emitter';
import { YearViewLayoutModel } from '../layoutmodel/YearViewLayoutModel';
import { componentUtils } from '@kit.ArkUI';
import { GridProp } from '../layoutmodel/YearViewLayoutProp'

const TAG = '[YearView][SingleMonthView]';

@Component
export struct SingleMonthView {
  @Prop displayMonth: number = 0; // only init by OneYearView

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  // 深色模式
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  private viewModel: SingleMonthViewModel | null = null; // 用于组件数据的传递

  @State @Watch('reLayout') layout: YearViewLayoutModel = YearViewLayoutModel.instance();

  @State gridProp: GridProp = YearViewLayoutModel.instance().gridProp.value;

  @State monthAccessibilityText: string | undefined = '';

  @State public swipeIndex: number = 0;

  public monthIndex: number = 0;

  private compId: string = '';

  @Prop @Watch('yearChange') public year: number = 0;

  @Consume isMaximizeRecovery: boolean;

  aboutToAppear(): void {
    this.compId = `SingleMonthView_swipeItem_${this.swipeIndex}_month_${this.monthIndex}`;
    this.monthAccessibilityText = this.viewModel?.getYearMonth();
    const doubleClickMonthStr = GlobalThis.getResourceStr($r('app.string.broadcast_double_tap_view_calendar'));
    const swipeYearStr = GlobalThis.getResourceStr($r('app.string.broadcast_swipe_year'));
    if (this.monthIndex === 0) {
      this.monthAccessibilityText += `, ${doubleClickMonthStr}, ${swipeYearStr}`;
    } else {
      this.monthAccessibilityText += `, ${doubleClickMonthStr}`;
    }
    this.currentMonth();
  }

  onLanguageChange(): void {
    Log.info(TAG, `onLanguageChange: ${this.language}`);
    this.currentMonth();
  }

  currentMonth(): void {
    const doubleClickMonthStr = GlobalThis.getResourceStr($r('app.string.broadcast_double_tap_view_calendar'));
    if (this.viewModel && this.viewModel.year === new CalendarDate().getFullYear() &&
      this.viewModel.month === new CalendarDate().getMonth() + 1) {
      this.monthAccessibilityText = GlobalThis.getResourceStr($r('app.string.current_month')) +
        this.viewModel?.getYearMonth() + `, ${doubleClickMonthStr}`;
    }
  }

  reLayout(): void {
    this.viewModel?.monthPaint.invalidate();
  }

  yearChange(): void {
    this.monthAccessibilityText = this.viewModel?.getYearMonth();
    const doubleClickMonthStr = GlobalThis.getResourceStr($r('app.string.broadcast_double_tap_view_calendar'));
    const swipeYearStr = GlobalThis.getResourceStr($r('app.string.broadcast_swipe_year'));
    if (this.monthIndex === 0) {
      this.monthAccessibilityText += `, ${doubleClickMonthStr}, ${swipeYearStr}`;
    }
  }

  onDarkModeChange(): void {
    this.viewModel?.onDarkModeChange(this.isDarkMode as boolean);
  }

  // 年视图点击单月响应
  // selectMonth 自然月
  dateSelected: Function = (selectMonth: number) => {
    // notify displayDate change
    const year = this.viewModel?.year!;
    const displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE);
    // 1、跳转年份与系统当前时间年份一样：当前选中天为当月,跳转该月份不需要再变更选中日期
    // 2、跳转年份与系统当前时间年份不一样：变更选中日期
    if (!displayDate || (new CalendarDate(displayDate as number).getMonth() + 1) !== selectMonth ||
      ((new CalendarDate(Date.now()).getFullYear()) !== this.viewModel?.year)) {
      const toDisplayDate = DateUtil.dateToStamp(year, selectMonth - 1, 1);
      Log.log(TAG, 'dateSelected set displayDate:' + toDisplayDate);
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, toDisplayDate);
      //额外进行广播通知当前日期改变
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    }
    const info = componentUtils.getRectangleById(this.compId);
    // 根据被点击月份的行数和列数分别计算缩放中心点
    const width = px2vp(info.size.width);
    const height = px2vp(info.size.height);
    const x = px2vp(info.localOffset.x);
    const y = px2vp(info.localOffset.y);
    let centerX = 0;
    let centerY = 0;
    let columnIndex = this.displayMonth % 3;
    if (columnIndex === 1) {
      // 涉及年份切换时，globalPosition不准确，改用position
      centerX = Math.round(x);
    } else if (columnIndex === 2) {
      centerX = Math.round(x + width / 2);
    } else {
      centerX = Math.round(x + width);
    }

    let rowIndex = Math.ceil(this.displayMonth / 3);
    if (rowIndex === 1) {
      centerY = height / 3;
    } else if (rowIndex === 2) {
      centerY = y - height / 2;
    } else {
      centerY = y;
    }

    let eventData: emitter.EventData = {
      data: {
        'tabIndex': TabType.MONTH,
        'centerX': centerX,
        'centerY': centerY
      }
    };
    Log.log(TAG, `'dateSelected emit ${centerX} ${centerY}`);
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB, priority: emitter.EventPriority.HIGH }, eventData)
    ReportUtil.reportStatisticEvent(statisticEvents.yearClickDate);
  };

  build() {
    GridItem() {
    }
    .drawModifier(this.viewModel?.monthPaint)
    .id(this.compId)
    .renderGroup(!this.isMaximizeRecovery)
    .height(this.gridProp.rowsHeight)
    .constraintSize({ minHeight: this.gridProp.minHeight })
    .borderRadius(16)
    .borderColor('#00000000') // GridItem组件走焦态会凹一点，用边框做规避
    .width('100%')
    .onClick(event => {
      this.dateSelected(this.displayMonth);
    })
    .accessibilityLevel('yes')
    .accessibilityText(this.monthAccessibilityText)
    .accessibilityDescription(' ')
  }
}