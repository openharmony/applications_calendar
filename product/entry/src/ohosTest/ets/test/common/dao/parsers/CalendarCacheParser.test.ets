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

import { describe, expect, it } from '@ohos/hypium';
import { CalendarCache } from '@app/common/src/main/ets/dao/model/CalendarCache';
import { LockTimeZoneInfo } from '@app/common/src/main/ets/dao/model/LockTimeZoneInfo';
import { ColumnConfig } from '@app/common/src/main/ets/dao/ColumnConfig';
import { DbValueType } from '@app/common/src/main/ets/dao/DbValueType';
import { DataShareResultSetMock } from '../DataShareHelperMock';
import { BaseModelConverter, CalendarContract, EmptyUtils, InnerResultSet, Log, ReflectUtils } from '@app/common';
import { TestUtil } from '../../../utils/TestUtil';
import { DataShareResultSet } from '@kit.ArkData';

const TAG = 'CalendarCacheParserTest';

class MockInnerResultSet extends InnerResultSet {
  constructor(data: DataShareResultSet, creator: string) {
    super(data, creator);
  }

  getColumnIndex(columnName: string): number {
    return 1;
  }

  getString(columnIndex: number): string {
    return '100';
  }

  getLong(columnIndex: number): number {
    return 10;
  }

  get columnNames(): string[] {
    return [CalendarContract.CalendarCacheColumns.ID, CalendarContract.CalendarCacheColumns.KEY, CalendarContract.CalendarCacheColumns.VALUE];
  }
}

export default function CalendarCacheParserTest() {
  const parser = new BaseModelConverter(CalendarContract.Tables.CALENDAR_CACHE,
    ReflectUtils.getPrototypeOf(CalendarCache), 'CalendarCacheParser', CalendarCache);
  describe('CalendarCacheParserTest', () => {

    it('test_parseToModel', 0, () => {
      const resultSet = new DataShareResultSetMock();
      const innerResultSet = new MockInnerResultSet(resultSet, TAG);
      let model = parser.parseToModel(innerResultSet, [CalendarContract.CalendarCacheColumns.ID]);
      Log.info(TAG,`model is ${JSON.stringify(model)}`);
      expect(model.id).assertEqual(10);
      expect(model.key).assertEqual('');
      expect(model.value).assertEqual('');
      model = parser.parseToModel(innerResultSet, []);
      expect(model.id).assertEqual(10);
      expect(model.key).assertEqual('100');
      expect(model.value).assertEqual('100');
      model = parser.parseToModel(innerResultSet, ['key']);
      expect(model.id).assertEqual(0);
      expect(model.key).assertEqual('100');
      expect(model.value).assertEqual('');
    });

    it('test_buildValuesBucket', 0, () => {
      let bucket = parser.buildValuesBucket({
        id: 1,
        key: 'a',
        value: 'b'
      });
      expect(bucket[CalendarContract.CalendarCacheColumns.ID]).assertEqual(undefined);
      expect(bucket['key']).assertEqual('a');
      expect(bucket['value']).assertEqual('b');
      bucket = parser.buildValuesBucket({
        id: 1,
        key: 'a',
        value: 'b'
      }, [CalendarContract.CalendarCacheColumns.ID]);
      Log.info(TAG,`bucket is ${JSON.stringify(bucket)}`);
      expect(bucket[CalendarContract.CalendarCacheColumns.ID]).assertEqual(undefined);
      expect(bucket['key']).assertEqual(undefined);
      expect(bucket['value']).assertEqual(undefined);
      bucket = parser.buildValuesBucket({
        id: 1,
        key: 'a',
        value: 'b'
      }, [], [CalendarContract.CalendarCacheColumns.ID]);
      expect(bucket[CalendarContract.CalendarCacheColumns.ID]).assertEqual(undefined);
      expect(bucket['key']).assertEqual('a');
      expect(bucket['value']).assertEqual('b');
    });
  });
}