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
import { ErrorCode, Log, Result } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CalendarCacheService } from '@app/common/src/main/ets/dao/service/CalendarCacheService';
import { LockTimeZoneRepository } from '@app/common/src/main/ets/dao/repo/LockTimeZoneRepository';
import { LockTimeZoneInfo } from '@app/common/src/main/ets/dao/model/LockTimeZoneInfo';
import { TestUtil } from '../../utils/TestUtil';

const TAG = 'CalendarCacheServiceTest';

export default function CalendarCacheServiceTest() {
  describe('CalendarCacheServiceTest', () => {
    let service = CalendarCacheService.getInstance();
    let repo: LockTimeZoneRepository;
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
      repo = TestUtil.getPrivateAttribute(service, 'timeZoneRepository');
    })

    it('test_queryLockTimeZoneSwitchInfo', 0, async (done: Function) => {

      let queryByCondition: Function = mocker.mockFunc(repo, repo.queryByCondition);
      when(queryByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', []));
      let result = await service.queryLockTimeZoneSwitchInfo();
      Log.info(TAG, `result is ${result.toString()}`);
      expect(result.message).assertEqual('error');
      when(queryByCondition)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult([]));
      result = await service.queryLockTimeZoneSwitchInfo();
      expect(result.isSuccess()).assertTrue()
      expect(result.data).assertUndefined();
      when(queryByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildSuccessResult([LockTimeZoneInfo.buildLockTimeZoneSwitchInfo(true)]));
      result = await service.queryLockTimeZoneSwitchInfo();
      expect(result.data?.isTimeZoneLocked()).assertTrue();
      done();
    });

    it('test_queryLockedTimeZone', 0, async (done: Function) => {
      let queryByByCondition: Function = mocker.mockFunc(repo, repo.queryByCondition);
      when(queryByByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', []));
      let result = await service.queryLockedTimeZone();
      Log.info(TAG, `result is ${result.toString()}`);
      expect(result.message).assertEqual('error');
      when(queryByByCondition)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult([]));
      result = await service.queryLockedTimeZone();
      expect(result.isSuccess()).assertTrue();
      expect(result.data.length).assertEqual(0);
      when(queryByByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildSuccessResult([LockTimeZoneInfo.buildLockedTimeZoneInfo('shanghai')]));
      result = await service.queryLockedTimeZone();
      expect((result.data)[0].value).assertEqual('shanghai');
      done();
    });

    it('test_insertLockedTimeZone', 0, async (done: Function) => {
      let insertItem: Function = mocker.mockFunc(repo, repo.insertItem);
      when(insertItem)(ArgumentMatchers.any).afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', 0));
      let result = await service.insertLockedTimeZone({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.message).assertEqual('error');
      when(insertItem)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(1));
      result = await service.insertLockedTimeZone({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.isSuccess()).assertTrue();
      expect(result.data).assertEqual(1);
      done();
    });

    it('test_insertLockTimeZoneSwitchInfo', 0, async (done: Function) => {
      let insertItem: Function = mocker.mockFunc(repo, repo.insertItem);
      when(insertItem)(ArgumentMatchers.any).afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', 0));
      let result = await service.insertLockTimeZoneSwitchInfo({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.message).assertEqual('error');
      when(insertItem)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(1));
      result = await service.insertLockTimeZoneSwitchInfo({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.isSuccess()).assertTrue();
      expect(result.data).assertEqual(1);
      done();
    });

    it('test_updateLockedTimeZone', 0, async (done: Function) => {
      let updateByCondition: Function = mocker.mockFunc(repo, repo.updateByCondition);
      when(updateByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', 0));
      let result = await service.updateLockedTimeZone({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.message).assertEqual('error');
      when(updateByCondition)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(1));
      result = await service.updateLockedTimeZone({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.isSuccess()).assertTrue();
      expect(result.data).assertEqual(1);
      done();
    });

    it('test_updateLockTimeZoneSwitchInfo', 0, async (done: Function) => {
      let updateByCondition: Function = mocker.mockFunc(repo, repo.updateByCondition);
      when(updateByCondition)(ArgumentMatchers.any)
        .afterReturn(Result.buildFailResult(ErrorCode.ILLEGAL_CODE, 'error', 0));
      let result = await service.updateLockTimeZoneSwitchInfo({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.message).assertEqual('error');
      when(updateByCondition)(ArgumentMatchers.any).afterReturn(Result.buildSuccessResult(1));
      result = await service.updateLockTimeZoneSwitchInfo({
        id: 1,
        key: 'xx',
        value: 'xx'
      } as LockTimeZoneInfo);
      expect(result.isSuccess()).assertTrue();
      expect(result.data).assertEqual(1);
      done();
    });
  });
}