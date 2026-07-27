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
import { CalendarDate, DBUtils } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { InstanceRepository } from '@app/common/src/main/ets/dao/repo/InstanceRepository';


export default function InstanceRepositoryTest() {
  describe('InstanceRepositoryTest', () => {
    let db = DBUtils.INSTANCE;
    let repo: InstanceRepository;
    let mocker: MockKit;
    let query: Function;

    beforeEach(() => {
      repo = new InstanceRepository;
      mocker = new MockKit();
      query = mocker.mockFunc(db, db.queryWithExtraUrl);
    });

    it('queryCondition', 0, async (done: Function) => {
      let begin = new CalendarDate().getTime();
      let end = new CalendarDate().getTime();
      expect(await repo.queryCondition(begin, end)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow("");
      expect(await repo.queryCondition(begin, end)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterThrow(undefined);
      expect(await repo.queryCondition(begin, end)).assertEqual(undefined);
      when(query)(ArgumentMatchers.any).afterReturn("");
      expect(await repo.queryCondition(begin, end)).assertEqual("");
      when(query)(ArgumentMatchers.any).afterReturn("");
      expect(await repo.queryCondition(begin, end)).assertEqual("");
      done();
    });
  });
}