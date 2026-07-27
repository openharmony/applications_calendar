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


import { TabType } from '../default/common/declare';
import { DateUtil } from './DateUtil';
import intl from '@ohos.intl';
import { CalendarDate } from '../date/CalendarDate';

export class DateTitleUtil {
  /**
   * 格式化时间信息  --language用于页面刷新,无实际用处
   */
  static formatTitle(displayDate: number, type: TabType, language?: string): string {
    const date = new CalendarDate(displayDate);
    const nowTime = new CalendarDate();
    let dateTimeOptions: intl.DateTimeOptions = {};
    if (nowTime.getFullYear() !== date.getFullYear()) {
      dateTimeOptions.year = 'numeric';
    }
    DateTitleUtil.getDateTimeOptionByTabType(dateTimeOptions, type);
    return DateUtil.intlDateFormatChineseStyle(date, dateTimeOptions);
  }

  /**
   * 格式化时间信息
   */
  static formatTitleOri(displayDate: number, type: TabType): string {
    const date = new Date(displayDate);
    const nowTime = new Date();
    let dateTimeOptions: intl.DateTimeOptions = {};
    if (nowTime.getFullYear() !== date.getFullYear()) {
      dateTimeOptions.year = 'numeric';
    }
    DateTitleUtil.getDateTimeOptionByTabType(dateTimeOptions, type);
    return DateUtil.intlDateFormatChineseStyle(date, dateTimeOptions);
  }

  static getDateTimeOptionByTabType(dateTimeOptions: intl.DateTimeOptions, type: TabType) : void {
    switch (type) {
      case TabType.YEAR:
        dateTimeOptions.year = 'numeric';
        break;
      case TabType.MONTH:
        dateTimeOptions.month = 'short';
        break;
      case TabType.WEEK:
        dateTimeOptions.month = 'short';
        break;
      case TabType.DAY:
        dateTimeOptions.month = 'short';
        break;
      case TabType.MINI_MONTH:
        dateTimeOptions.year = 'numeric';
        dateTimeOptions.month = 'short';
        break;
      default:
        return;
    }
  }
}