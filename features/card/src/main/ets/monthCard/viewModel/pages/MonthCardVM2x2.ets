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
import { FormName } from '../../../utils/FormName';
import { MonthCardViewModel } from './MonthCardViewModel';
import { SimpleMonthViewModel } from '../components/monthVM/SimpleMonthViewModel';
import MonthlyDataArray from '../../common/MonthlyDataArray';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { CompressedDayData } from '../components/CardSingleDayViewModel';
import { decompressData } from '../../../utils/CardUtils';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

const TAG: string = '[MonthCard][MonthCardVM2x2]';
const LOG_MONTH_DATA_INDEX = 10; // 当月的日期数据索引

@Observed
export class MonthCardVM2x2 extends MonthCardViewModel {
  // 当天日期
  public displayDate: CalendarDate = new CalendarDate();
  // 月视图VM
  public monthViewModel: SimpleMonthViewModel;

  constructor(formName: FormName) {
    super(formName);
    this.monthViewModel = new SimpleMonthViewModel([]);
  }

  /**
   * 跳转到应用的月视图
   * @param obj 需要绑定对应视图
   */
  jumpToMonthView(obj: Object) {
    Log.info(TAG, 'Jump To Calendar Month View, Date = ' + this.displayDate.toDateString());
    super.jumpToMonthView(obj, this.displayDate);
  }

  /**
   * 显示时间发生改变
   * @param displayDate 新赋值的显示日期
   */
  onDisplayDateChange(displayDate: CalendarDate) {
    this.displayDate = displayDate;
  }

  /**
   * 用于更新当前显示的全量数据
   * @param curMonthVM 从 FormAbility 拿到的显示数据
   * @returns 是否完整走完流程
   */
  onCurMonthVM(curMonthVM: string):boolean {
    Log.debug(TAG, `onCurMonthVM ：` + curMonthVM + ',end here!');
    if (EmptyUtils.isNotOrEmptyString(curMonthVM)) {
      Log.error(TAG, `curMonthVM is null!`);
      return false;
    }
    try {
      const monthData: CompressedDayData[] = JSON.parse(curMonthVM);
      if (!Array.isArray(monthData) || monthData.length === 0) {
        Log.error(TAG, `curMonthVM parsed is not a valid array!`);
        return false;
      }
      this.buildMonthVM(monthData.map(dayData => decompressData(dayData)));

      const curMonthLen: number = this.monthViewModel.curMonthData.length;
      if (curMonthLen < 35) {
        Log.error(TAG, `curMonthVM is illegal! curMonthLen = ${curMonthLen}`);
        return false;
      }
      const logDate = this.monthViewModel.curMonthData[LOG_MONTH_DATA_INDEX];
      Log.warn(TAG, `formId: ${this.getFormID()} display year = ${logDate.year}, month = ${logDate.month}`);
      this.onDisplayDateChange(new CalendarDate());
      if (!this.isDataProcessedFirstTime) {
        this.isDataProcessedFirstTime = true;
      }
      return true;
    } catch (error) {
      Log.logErrorMsg(TAG, `onCurMonthVM JSON.parse error`, error);
      return false;
    }
  }

  /**
   * 用于构建单天的宫格
   * @param monthlyData 单天的日期数据
   */
  private buildMonthVM(monthlyData: MonthlyDataArray) {
    this.monthViewModel = new SimpleMonthViewModel(monthlyData); // 对象数组无法嵌套赋值 需要对VM进行
  }
}

