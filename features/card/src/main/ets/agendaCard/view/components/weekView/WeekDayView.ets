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
import { CardSingleDayViewModel } from '../../../../monthCard/viewModel/components/CardSingleDayViewModel';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { WeekSingleDayView } from './WeekSingleDayView';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { date2julianDay } from '../../../../utils/TimeUtils';

const TAG: string = 'WeekDayView1x4';

@Component
export struct WeekDayView {
  @Prop @Watch('onMonthVMChange') curMonthVM: CardSingleDayViewModel[] = [];

  @Prop isAgreeStatement: boolean = true;

  // 一周开始日
  @LocalStorageProp('startOfWeek') startOfWeek: number = -1;

  // 设备规格
  @LocalStorageProp('deviceLayout') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  // 周末
  @LocalStorageProp('weekends') weekends: number[] = [];

  // formId
  @LocalStorageProp('formId') formId: string = '';

  // 当前选中日
  @Link activeDay: number

  // @state
  // 当天日期
  @State displayDate: CalendarDate = new CalendarDate();

  // 今天是第几周
  @State weekIndex: number = 1;

  // 周标题
  private weekTitle: Map<number, Resource> = new Map();

  // @computed
  getAccessibilityText(): string {
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long'
    };
    let date = new CalendarDate()
    let now = DateUtil.intlDateFormatChineseStyle(date, dateOption, true);
    return now;
  }

  // @watch
  onMonthVMChange() {
    let todayIndex = this.curMonthVM.findIndex(day => day.isToday) || 0
    this.weekIndex = Math.floor((todayIndex) / 7);
    this.displayDate = new CalendarDate();
    Log.info(TAG, `onMonthVMChange,this.curMonthVM.length:${this.curMonthVM.length},this.weekIndex:${this.weekIndex},todayIndex:${todayIndex}`);
  }

  // @mounted
  aboutToAppear(): void {
    Log.log(TAG, `date: ${new Date()} is created`);
    this.weekTitle
      .set(0, $r('app.string.Card_Sun'))
      .set(1, $r('app.string.Card_Mon'))
      .set(2, $r('app.string.Card_Tue'))
      .set(3, $r('app.string.Card_Wed'))
      .set(4, $r('app.string.Card_Thu'))
      .set(5, $r('app.string.Card_Fri'))
      .set(6, $r('app.string.Card_Sat'));
    this.onMonthVMChange()
  }

  // @destroyed
  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`)
  }

  // component
  @Builder
  buildWeekTitles() {
    Flex({
      direction: FlexDirection.Row,
      wrap: FlexWrap.NoWrap,
      justifyContent: FlexAlign.SpaceBetween,
    }) {
      ForEach(new Array(7).fill(''), (item: string, index: number) => {
        Text(this.weekTitle.get((this.startOfWeek + index) % 7))
          .fontSize($r('sys.float.Caption_M'))
          .maxFontScale(1)
          .fontColor($r('sys.color.font_primary'))
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Medium)
          .opacity(this.weekends?.includes((this.startOfWeek + index) % 7)
            ? $r('sys.float.alpha_tertiary')
            : $r('sys.float.alpha_primary'))
        .width('14%')
        .height(14)
      }, (item: string, index: number) => index.toString())
    }
    .accessibilityLevel('no')
    .margin({
      top: 4,
      bottom: 4,
      left: 2,
      right: 2
    })
  }

  isActiveDay(dayInfo: CardSingleDayViewModel) {
    return this.activeDay == date2julianDay(dayInfo.year, dayInfo.month, dayInfo.day);
  }

  @Builder
  buildWeekDay() {
    Row() {
      ForEach(new Array(7).fill(''), (item: string, dayIndex: number) => {
        if (this.curMonthVM.length > 0 && this.curMonthVM[this.weekIndex * 7 + dayIndex]) {
          WeekSingleDayView({
            viewModel: this.curMonthVM[this.weekIndex * 7 + dayIndex],
            displayDate: this.displayDate,
            deviceLayout: this.deviceLayout,
            formId: this.formId,
            activeDay: this.activeDay,
            isActiveDay: this.isActiveDay(this.curMonthVM[this.weekIndex * 7 + dayIndex]),
            isAgreeStatement: this.isAgreeStatement,
          })
        }
      }, (item: string, dayIndex: number) => dayIndex.toString())
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 2, right: 2 })
  }

  // @template
  build() {
    Column() {
      this.buildWeekTitles();
      this.buildWeekDay();
    }
    .accessibilityText(this.getAccessibilityText())
  }
}



