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

import { CalendarDate } from '@app/common';
import { Weeks } from '../Constants';

/**
 * 根据Date日期，返回其所在的星期几，返回格式为自定的Weeks枚举
 *
 * @param date 待判断日期
 * @returns 星期几，Weeks枚举
 */
export function getWeekOfDate(date: CalendarDate): Weeks {
  if (date === null || date === undefined) {
    return Weeks.UNDEFINED;
  }
  const weekDay: number = date.getDay();
  switch (weekDay) {
    case 1:
      return Weeks.MON;
    case 2:
      return Weeks.TUE;
    case 3:
      return Weeks.WED;
    case 4:
      return Weeks.THUR;
    case 5:
      return Weeks.FRI;
    case 6:
      return Weeks.SAT;
    case 0:
      return Weeks.SUN;
    default:
      return Weeks.UNDEFINED;
  }
}