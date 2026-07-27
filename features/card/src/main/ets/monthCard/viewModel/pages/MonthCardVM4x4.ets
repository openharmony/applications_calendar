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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { DateUtil, IMonthInfo } from '@app/common/src/main/ets/util/DateUtil';
import { FormName } from '../../../utils/FormName';
import { MonthCardViewModel } from './MonthCardViewModel';
import { MonthSwitchViewModel } from '../components/CarouselPanelViewModel';
import { Direction } from '../../common/MonthCardEnum';
import { DeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { ComplexMonthViewModel } from '../components/monthVM/ComplexMonthViewModel';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

const TAG: string = '[MonthCard][MonthCardVM4x4]';

@Observed
export class MonthCardVM4x4 extends MonthCardViewModel {
  // 当前卡片选中的日期
  public displayDate: CalendarDate = new CalendarDate();
  // 轮播面板的VM
  public monthSwitchVM: MonthSwitchViewModel;
  // 月视图VM
  public monthViewModel: ComplexMonthViewModel;

  constructor(formName: FormName) {
    super(formName);
    this.monthSwitchVM = new MonthSwitchViewModel();
    if (formName !== FormName.MONTH_CARD_4X4) {
      Log.error(TAG, 'NO Valid form Name!');
    }
    this.monthViewModel = new ComplexMonthViewModel((isButtonBanned: boolean) => {
      this.onIsButtonBannedChange(isButtonBanned);
    });
  }

  jumpToMonthView(obj: Object) {
    Log.info(TAG, 'Jump To Calendar Month View, Date = ' + this.displayDate.toDateString());
    super.jumpToMonthView(obj, this.displayDate);
  }

  /**
   * 设备定制化配置变更
   * @param deviceLayout 设备参数
   */
  onDeviceLayoutChange(deviceLayout: DeviceLayout) {
    this.monthViewModel.onDeviceLayoutChange(deviceLayout);
  }

  /**
   * 显示时间发生改变
   * @param displayDate 新赋值的显示日期
   */
  onDisplayDateChange(displayDate: CalendarDate) {
    this.displayDate = displayDate;
    this.monthViewModel.onDisplayDateChange(displayDate);
    this.monthSwitchVM.onDisplayDateChange(displayDate);
  }

  /**
   * 按钮禁用状态变更
   * @param isButtonBanned 按钮是否禁用
   */
  onIsButtonBannedChange(isButtonBanned: boolean) {
    this.monthSwitchVM.onIsButtonBannedChange(isButtonBanned);
  }

  /**
   * 卡片的全量数据变更
   * @param cardSingleMonthVMJSONStr
   */
  onMonthVMChange(cardSingleMonthVMJSONStr: string): boolean {
    this.onDisplayDateChange(new CalendarDate());
    const isFreshDone: boolean = this.monthViewModel.onMonthVMChange(cardSingleMonthVMJSONStr);
    Log.warn(TAG, `onMonthVMChange formId: ${this.getFormID()} full data changes, displayDate = ${this.displayDate}`);
    if (isFreshDone) {
      this.checkIsDataProcessedFirstTime();
    }
    return isFreshDone;
  }

  /**
   * 前一个月数据变更
   * @param preMonthVMJSONStr
   */
  onPreVMChange(preMonthVMJSONStr: string) {
    Log.info(TAG, `formId: ${this.getFormID()} last month viewmodel change`);
    const isFreshDone: boolean = this.monthViewModel.onPreVMChange(preMonthVMJSONStr);
    if (isFreshDone) {
      this.freshDisplayDate(Direction.PRE_MONTH);
      this.checkIsDataProcessedFirstTime();
    }
    return isFreshDone;
  }

  /**
   * 后一个月数据变更
   * @param nextMonthVMJSONStr
   */
  onNextVMChange(nextMonthVMJSONStr: string) {
    Log.info(TAG, `formId: ${this.getFormID()} next month viewmodel change`);
    const isFreshDone: boolean = this.monthViewModel.onNextVMChange(nextMonthVMJSONStr);
    if (isFreshDone) {
      this.freshDisplayDate(Direction.NEXT_MONTH);
      this.checkIsDataProcessedFirstTime();
    }
    return isFreshDone;
  }

  // 更新当前时间
  private freshDisplayDate(directionState: number) {
    const result: IMonthInfo = DateUtil.getOffsetMonthInfo({
      year: this.displayDate.getFullYear(),
      month: this.displayDate.getMonth()
    }, directionState);

    if (result.year === new CalendarDate().getFullYear() && result.month === new CalendarDate().getMonth()) {
      this.onDisplayDateChange(new CalendarDate());
    } else {
      const date = new CalendarDate();
      // 重置到1号，防止1月31 ->2月31出现异常
      date.setFullYear(result.year, result.month, 1);
      this.onDisplayDateChange(date);
    }
    Log.info(TAG, `formId: ${this.getFormID()} monthly card display current date = ${this.displayDate}`)
  }

  private checkIsDataProcessedFirstTime() {
    if (!this.isDataProcessedFirstTime) {
      this.isDataProcessedFirstTime = true;
    }
  }
}

