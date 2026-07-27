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
import { DBUtils, EventRepository } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { DataShareResultSetMock } from '../DataShareHelperMock';
import { ValuesBucket } from '@kit.ArkData';


export default function EventRepositoryTest() {
  describe('EventRepositoryTest', () => {

    let db = DBUtils.INSTANCE;
    let repo: EventRepository;
    let mocker: MockKit;
    let query: Function;
    let deleteFunc: Function;
    let insert: Function;
    let update: Function;

    beforeEach(() => {
      repo = new EventRepository;
      mocker = new MockKit();
      query = mocker.mockFunc(db, db.query);
      insert = mocker.mockFunc(db, db.insert);
      update = mocker.mockFunc(db, db.update);
      deleteFunc = mocker.mockFunc(db, db.delete);
    });

    it('queryEvents_no_db', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await repo.queryEvents()).assertUndefined();
      done();
    });

    it('queryEvents_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      let result = await repo.queryEvents();
      expect(result).assertUndefined();
      done();
    });

    it('queryEvents_normal', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock())
      let result = await repo.queryEvents();
      expect(result).not().assertUndefined();
      done();
    });

    it('queryEventById_no_db', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await repo.queryEventById(1, [])).assertUndefined();
      done();
    });

    it('queryEventById_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryEventById(1, [])).assertUndefined();
      done();
    });

    it('queryEventById_normal', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      expect(await repo.queryEventById(1, [])).not().assertUndefined();
      expect(await repo.queryEventById(1)).not().assertUndefined();
      done();
    });

    it('queryEventByTitle_normal', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      expect(await repo.queryHolidayEventByTitle('春节', 1, [])).not().assertUndefined();
      done();
    });

    it('queryEventByTitle_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryHolidayEventByTitle('春节', 1, [])).assertUndefined();
      done();
    });

    it('queryEventsByIds_no_db', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await repo.queryEventsByIds([1], [])).assertUndefined();
      done();
    });

    it('queryEventsByIds_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryEventsByIds([1], [])).assertUndefined();
      done();
    });

    it('queryEventsByIds_normal', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      expect(await repo.queryEventsByIds([], [])).assertUndefined();
      expect(await repo.queryEventsByIds([1], [])).not().assertUndefined();
      expect(await repo.queryEventsByIds([1])).not().assertUndefined();
      done();
    });

    it('queryEventsByAccountId_no_db', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await repo.queryEventsByAccountId([1], [])).assertUndefined();
      done();
    });

    it('queryEventsByAccountId_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryEventsByAccountId([1], [])).assertUndefined();
      done();
    });

    it('queryEventsByAccountId_normal', 0, async (done: Function) => {
      const resultSet = new DataShareResultSetMock();
      when(query)(ArgumentMatchers.any).afterReturn(resultSet);
      expect(await repo.queryEventsByAccountId([], [])).assertEqual(undefined);
      expect(await repo.queryEventsByAccountId([-1], [])).assertEqual(resultSet);
      expect(await repo.queryEventsByAccountId([1], [])).not().assertUndefined();
      expect(await repo.queryEventsByAccountId([1])).not().assertUndefined();
      done();
    });

    it('queryImportantEvents_no_db', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      const result = await repo.queryImportantEvents([])
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0)
      done();
    });

    it('queryImportantEvents_throw_err', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      const result = await repo.queryImportantEvents([])
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0)
      done();
    });

    it('queryImportantEvents_query_empty', 0, async (done: Function) => {
      let resultSet = new DataShareResultSetMock();
      resultSet.rowCount = 0;
      when(query)(ArgumentMatchers.any).afterReturn(resultSet);
      let result = await repo.queryImportantEvents([]);
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0);
      result = await repo.queryImportantEvents(['test'], 1);
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0);
      done();
    });

    it('queryImportantEvents_query_undefined', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      let result = await repo.queryImportantEvents([]);
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0);
      result = await repo.queryImportantEvents(['test'], 1);
      expect(result).not().assertUndefined();
      expect(result.length).assertEqual(0);
      done();
    });

    it('queryImportantEvents_normal', 0, async (done: Function) => {
      let resultSet = new DataShareResultSetMock();
      when(mocker.mockFunc(resultSet, resultSet.goToFirstRow))(ArgumentMatchers.any).afterReturn(true);
      resultSet.rowCount = 1;
      when(query)(ArgumentMatchers.any).afterReturn(resultSet);
      let result = await repo.queryImportantEvents([]);
      expect(result).not().assertUndefined();
      expect(result.length).not().assertEqual(0);
      result = await repo.queryImportantEvents(['test'], 1);
      expect(result).not().assertUndefined();
      expect(result.length).not().assertEqual(0);
      done();
    });

    it('insert', 0, async (done: Function) => {
      when(insert)(ArgumentMatchers.any).afterReturn(3);
      expect(await repo.insert({})).assertEqual(3);
      done();
    });

    it('updateById', 0, async (done: Function) => {
      when(update)(ArgumentMatchers.any).afterReturn(3);
      const value: ValuesBucket = {}
      expect(await repo.updateById(1, value)).assertEqual(3);
      done();
    });

    it('deleteByIds_less_10000', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteByIds([1])).assertEqual(1);
      done();
    });

    it('deleteByIds_over_10000', 0, async (done: Function) => {
      let ids = new Array<number>();
      for (let i = 0; i < 10001; i++) {
        ids.push(i);
      }
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteByIds(ids)).assertEqual(2); // call 2 times
      done();
    });
  });
}