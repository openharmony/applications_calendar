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
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { OneLinkService } from '@app/common/src/main/ets/dao/service/OneLinkService';
import { OneLinkRepository } from '@app/common/src/main/ets/dao/repo/OneLinkRepository';

const TAG = 'OneLinkServiceTest'

export default function OneLinkServiceTest() {
  describe('OneLinkServiceTest', () => {
    let service = OneLinkService.INSTANCE;
    let repo: OneLinkRepository = new OneLinkRepository;
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
      service.repo = repo;
    });

    it('insertOneLinkDataArray', 0, async (done: Function) => {
      expect(await service.insertOneLinkDataArray(undefined)).assertFalse();
      expect(await service.insertOneLinkDataArray([])).assertFalse();
      let mockFunc: Function = mocker.mockFunc(repo, repo.batchInsertOneLink);
      when(mockFunc)(ArgumentMatchers.any).afterReturn(1);
      expect(await service.insertOneLinkDataArray([])).assertTrue();
      when(mockFunc)(ArgumentMatchers.any).afterThrow(undefined);
      expect(await service.insertOneLinkDataArray([])).assertFalse();
      when(mockFunc)(ArgumentMatchers.any).afterThrow("这是一个主动抛出的错误");
      expect(await service.insertOneLinkDataArray([])).assertFalse();
      done();
    });
  });
}