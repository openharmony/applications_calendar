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

import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { WeekTitleViewModel } from '../components/WeekTitlesViewModel';
import { jumpToMonthView } from '../../../utils/CardJumpUtils';
import { FormName } from '../../../utils/FormName';
import { SimpleMonthViewModel } from '../components/monthVM/SimpleMonthViewModel';
import { ComplexMonthViewModel } from '../components/monthVM/ComplexMonthViewModel';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

const TAG: string = '[MonthCard][MonthCardViewModel]';

@Observed
export class MonthCardViewModel {
  // 第一次创建卡片，数据处理是否完成
  public isDataProcessedFirstTime: boolean = false;
  // 当天日期
  public todayDate: CalendarDate = new CalendarDate();
  // 一周开始日
  public startOfWeek: number = 0;
  // 周末
  public weekends: number[] = [];
  // 周题的VM
  public weekTitleVM: WeekTitleViewModel;
  // 月视图VM
  public monthViewModel: SimpleMonthViewModel | ComplexMonthViewModel = new SimpleMonthViewModel([]);
  // formID
  private formId: string = '';
  // formName
  private formName: FormName;

  constructor(formName: FormName) {
    this.formName = formName;
    this.weekTitleVM = new WeekTitleViewModel();
  }

  public getFormName(): FormName {
    return this.formName
  }

  public getFormID(): string {
    return this.formId
  }

  /**
   * 用于记录FormID
   * @param formId
   */
  onFormIdChange(formId: string) {
    this.formId = formId;
  }

  /**
   * 用于一周开始日的刷新
   * @param startOfWeek 一周开始日 可能范围 -1~6 对应周日-周六
   */
  onStartOfWeekChange(startOfWeek: number) {
    this.startOfWeek = startOfWeek;
    this.weekTitleVM.onStartOfWeekChange(startOfWeek);
  }

  /**
   * 用于周末设置项的刷新
   * @param weekends 数组可能值为0-6
   */
  onWeekendsChange(weekends: number[]) {
    this.weekends = weekends;
    this.weekTitleVM.onWeekendsChange(weekends);
  }

  /**
   * 跳转到月视图
   * @param obj 卡片跳转绑定的页面
   * @param desDate 跳转的页面参数
   */
  jumpToMonthView(obj: Object, desDate?: CalendarDate) {
    const curDate = desDate ?? new CalendarDate();
    const year = curDate.getFullYear();
    const month = curDate.getMonth();
    const day = curDate.getDate();
    jumpToMonthView(obj, year, month, day, this.formId, this.formName);
  }

  getAccessibilityText(): string {
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long'
    };
    let date = new CalendarDate();
    let now = DateUtil.intlDateFormatChineseStyle(date, dateOption, true);
    return now;
  }
}