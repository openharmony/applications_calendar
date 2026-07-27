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

import { TimeFormatType } from '@app/feature.repeatrule/src/main/ets/time/FormatTime';

/**
 * 日期格式化的参数封装
 */
export class DateFormatPara {
  // timeZoneID
  readonly tzId: string = '';
  // 时间格式化 如UTC, ISO8601,YYYY_MM_DD
  readonly timeFormat: TimeFormatType;

  constructor(tzId: string, timeFormat: TimeFormatType) {
    this.tzId = tzId;
    this.timeFormat = timeFormat;
  }
}