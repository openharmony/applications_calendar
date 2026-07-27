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

import { CalendarBuilder } from './export/builder/CalendarBuilder';
import { CalendarBuilderV20 } from './export/builder/CalendarBuilderV20';
import { CalendarBuilderV10 } from './export/builder/CalendarBuilderV10';
import { CalendarInfo } from './CalendarInfo';
import { VERSION_10 } from './VCalendarConstants';
import { Log } from '@app/common';
import { CalendarParserV10 } from './import/parser/CalendarParserV10';
import { CalendarParserV20 } from './import/parser/CalendarParserV20';
import { CalendarParser } from './import/parser/CalendarParser';

/**
 * CalendarFactory 创建1.0 和 2.0 两个vcs文件协议
 *
 */
const TAG = 'CalendarFactory'

export function getCalendarBuilder(calendarInfo: CalendarInfo): CalendarBuilder {
  const version: string = calendarInfo ? calendarInfo.getVersion() : '';
  Log.info(TAG, `getCalendarBuilder version is ${version}`);
  if (VERSION_10 == version) {
    return new CalendarBuilderV10(calendarInfo);
  } else {
    return new CalendarBuilderV20(calendarInfo);
  }
}

export function getCalendarParser(calendarInfo: CalendarInfo, countryCode: string = ''): CalendarParser {
  const version: string = calendarInfo ? calendarInfo.getVersion() : '';
  Log.info(TAG, `getCalendarParser version is ${version}`);
  if (VERSION_10 == version) {
    return new CalendarParserV10(calendarInfo);
  } else {
    return new CalendarParserV20(calendarInfo, countryCode);
  }
}