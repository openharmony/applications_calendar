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
import { DBUtils } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ReminderRepository } from '@app/common/src/main/ets/dao/repo/ReminderRepository';
import { DataShareResultSetMock } from '../DataShareHelperMock';


export default function ReminderRepositoryTest() {
  describe('ReminderRepositoryTest', () => {
    let db = DBUtils.INSTANCE;
    let repo: ReminderRepository;
    let mocker: MockKit;
    let query: Function;
    let deleteFunc: Function;
    let insert: Function;
    let update: Function;

    beforeEach(() => {
      repo = new ReminderRepository;
      mocker = new MockKit();
      query = mocker.mockFunc(db, db.query);
      insert = mocker.mockFunc(db, db.insert);
      update = mocker.mockFunc(db, db.update);
      deleteFunc = mocker.mockFunc(db, db.delete);
    });

    it('insertReminder', 0, async (done: Function) => {
      when(insert)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.insertReminder({})).assertEqual(1);
      done();
    });

    it('deleteReminderById', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteReminderById(1)).assertEqual(1);
      done();
    });

    it('deleteReminderByEventId', 0, async (done: Function) => {
      when(deleteFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.deleteReminderByEventId(1)).assertEqual(1);
      done();
    });

    it('updateReminderById', 0, async (done: Function) => {
      when(update)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.updateReminderById(1, {})).assertEqual(1);
      done();
    });

    it('queryReminderByEventId', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryReminderByEventId(1, [])).assertUndefined();

      when(query)(ArgumentMatchers.any).afterReturn(1);
      expect(await repo.queryReminderByEventId(1, [])).not().assertUndefined();
      done();
    });

    it('queryReminderByEventIds', 0, async (done: Function) => {
      when(query)(ArgumentMatchers.any).afterReturn(undefined);
      expect(await repo.queryReminderByEventIds([], [])).assertUndefined();

      when(query)(ArgumentMatchers.any).afterThrow('');
      expect(await repo.queryReminderByEventIds([1, 2], [])).assertUndefined();

      when(query)(ArgumentMatchers.any).afterReturn(new DataShareResultSetMock());
      expect(await repo.queryReminderByEventIds([], [])).assertUndefined();
      expect(await repo.queryReminderByEventIds([1, 2], [])).not().assertUndefined();
      done();
    });
  });
}