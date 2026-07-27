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

import { Log } from '@app/common';
import { Recurrence } from '../Recurrence';
import { FLAG_BY_WEEK_DAY, parseNumber, WEEK_MAP } from '../RecurrenceParser';
import PartParser from './PartParser';
import { Weeks } from '../Constants';

const TAG: string = 'ParseByWeekDay';

const MAX_WEEKS_OF_YEAR: number = 53;

const MAX_WEEKS_OF_LAST_YEAR: number = -53;

// rrule中week表现为：MO/TU/SA等，固定2个字符
const WEEK_STR_LEN: number = 2;

/**
 * 解析按x周星期x循环的配置
 */
export default class ParseByWeekDay implements PartParser {
  parsePart(value: string, recurrence: Recurrence) {
    if (!recurrence) {
      Log.warn(TAG, `parsePart get invalid params`);
      return;
    }
    if (value.indexOf(',') < 0) {
      this.parseWeekDay(value, recurrence.byWeekDay, recurrence.byWeekNum);
    } else {
      const strArray: string[] = value.split(',');
      strArray.forEach((str: string) => {
        this.parseWeekDay(str, recurrence.byWeekDay, recurrence.byWeekNum);
      })
    }
    if (recurrence.byWeekDayCount() > 0) {
      recurrence.parseFlag |= FLAG_BY_WEEK_DAY;
    }
  }

  parseWeekDay(str: string, weekDay: number[], weekDayNum: number[]) {
    // weekDay格式为 2MON 或 MON，分别表示第2个星期一和星期一，需要判断是否MON前面有数字
    let numPart: string = '';
    let weekPart: string = str;
    if (str.length > WEEK_STR_LEN) {
      numPart = str.substring(0, str.length - WEEK_STR_LEN);
      weekPart = str.substring(str.length - WEEK_STR_LEN);
    }

    const week: Weeks = WEEK_MAP[weekPart];
    if (!week) {
      return;
    }

    weekDay.push(week);
    if (numPart === null || numPart === undefined || numPart.length === 0) {
      weekDayNum.push(0);
    } else {
      const num: number | null = parseNumber(numPart, MAX_WEEKS_OF_LAST_YEAR, MAX_WEEKS_OF_YEAR, false);
      if (num === null) {
        weekDayNum.push(0);
      } else {
        weekDayNum.push(num);
      }
    }
  }
}