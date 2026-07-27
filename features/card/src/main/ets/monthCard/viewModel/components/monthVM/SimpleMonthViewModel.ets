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
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DAY_PER_WEEK } from '@app/common/src/main/ets/util/DateUtil';
import MonthlyDataArray from '../../../common/MonthlyDataArray';

const TAG: string = 'WeekTitleViewModel';

/**
 * 简易月视图的VM
 */
@Observed
export class SimpleMonthViewModel {
  // formID
  public formId: string = '';
  // 单月行数
  public rowNum: number = 6;
  // 单天宫格的VM
  public curMonthData: MonthlyDataArray = [];
  // 当前卡片选中的日期
  public displayDate: CalendarDate = new CalendarDate();

  constructor(monthlyData: MonthlyDataArray) {
    this.curMonthData = monthlyData;
    this.rowNum = monthlyData.length / DAY_PER_WEEK;
  }
}