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
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { SubscriptionCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';
import { CardSingleDayViewModel } from '../viewModel/components/CardSingleDayViewModel';

const TAG: string = 'ViewModelUtils';

export class ViewModelUtils {
  /**
   * 更新日期字体透明度
   */
  public static updateDateTextOpacity(viewModel: CardSingleDayViewModel) {
    if (!viewModel.isCurrentMonth) {
      return 0.5; // 非当月
    }

    if (viewModel.isToday) {
      return 1;
    }

    if (viewModel.showRecessData) {
      return 1; // 显示班休时使用强调色
    }

    if (viewModel.isWeekends) {
      return $r('sys.float.alpha_tertiary'); // 周末
    }

    return 1; // 其它场景
  }

  /**
   * 更新日期字体颜色
   */
  public static updateDateTextColor(viewModel: CardSingleDayViewModel) {
    // 当月今天
    if (viewModel.isCurrentMonth && viewModel.isToday) {
      return $r('sys.color.ohos_fa_text_contrary');
    }

    // 显示班休 1：休  2：班
    if (viewModel.showRecessData) {
      return viewModel.mark === 1 ? $r('app.color.blue_common') : $r('app.color.red_common');
    }

    // 默认颜色
    return $r('sys.color.font_primary');
  }

  /**
   * 更新节假日、历法字体颜色
   */
  public static updateCalOrHolTextColor(viewModel: CardSingleDayViewModel, festivalName?: string) {
    // 1.当月今天，字体颜色反转白色
    if (viewModel.isCurrentMonth && viewModel.isToday) {
      return $r('sys.color.ohos_fa_text_contrary');
    }

    // 2.节假日或者今天，为主题色
    if (viewModel.hasFestivals || viewModel.isToday ||
      (festivalName !== '' && festivalName !== undefined)) {
      return $r('app.color.red_common');
    }

    // 3.默认颜色
    return $r('sys.color.font_secondary');
  }

  /**
   * 更新文本
   */
  public static getAccessibilityText(viewModel: CardSingleDayViewModel) {
    // todo 待提翻
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
    };
    let date = new CalendarDate(viewModel.year, viewModel.month - 1, viewModel.day);
    let now = DateUtil.intlDateFormatChineseStyle(date, dateOption, true);
    let toDay = viewModel.isToday ? '今天' : '';
    let isLunar = viewModel.subscriptionCalendar === SubscriptionCalendar.CHINESE_CALENDAR && !viewModel.hasFestivals;
    let subscriptionCalendar = isLunar ? '农历' : '';

    return [
      toDay,
      now,
      `${subscriptionCalendar}${viewModel.tagText}`
    ].filter(Boolean).join(',');
  }
}