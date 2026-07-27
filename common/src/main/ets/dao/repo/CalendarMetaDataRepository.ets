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

import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { DBUtils } from '../DBUtils';
import { CalendarContract } from '../../default/calendar/CalendarContract';
import { InnerResultSet } from '../util/InnerResultSet';

const TAG: string = 'CalendarMetaDataRepository';

export class CalendarMetaDataRepository {
  public static readonly INSTANCE: CalendarMetaDataRepository = new CalendarMetaDataRepository();

  private constructor() {
  }

  public async query(columns: Array<string>): Promise<InnerResultSet | undefined> {
    const tag = 'queryCalendarMetaData';
    let predicates = new dataSharePredicates.DataSharePredicates();
    return await DBUtils.INSTANCE.query(CalendarContract.Tables.CALENDAR_META_DATA,
      predicates, columns, tag);
  }
}