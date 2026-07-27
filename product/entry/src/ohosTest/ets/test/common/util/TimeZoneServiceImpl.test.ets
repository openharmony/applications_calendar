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
import { CalendarDate, EmptyUtils, ErrorCode, I18nUtil, Result, ServiceEnum, ServiceManager } from '@app/common/index';
import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { TestUtil } from '../../utils/TestUtil';
import { TimeZoneServiceImpl } from '@app/service.timezone/src/main/ets/impl/TimeZoneServiceImpl';
import { TimeZoneService } from '@app/service.timezone';


export default function TimeZoneServiceImplTest() {
  describe('TimeZoneServiceImplTest', () => {
    let mocker: MockKit;

    beforeEach(() => {
      mocker = new MockKit();
    })

    it('test_saveLockedTimeZone', 0, async () => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      const tSaveLockedTimeZone = TestUtil.getPrivateFunction(service!, 'saveLockedTimeZone');
      if (EmptyUtils.isUndefinedOrNull(tSaveLockedTimeZone)) {
        expect(tSaveLockedTimeZone).assertNull();
      } else {
        const saveLockedTimeZone = tSaveLockedTimeZone!
        let saveToDb: Function = TestUtil.getPrivateFunction(service!, 'saveTimeZoneToRemoteDb')!;
        TestUtil.setPrivateAttribute(service!, 'saveTimeZoneToRemoteDb', async (xx: string) => {
          return Result.buildFailResult(-1, 'error');
        })
        expect((await saveLockedTimeZone(''))).assertFalse();
        let saveToPre: Function = TestUtil.getPrivateFunction(service!, 'saveLockedTimeZoneToPreferences')!;
        TestUtil.setPrivateAttribute(service!, 'saveTimeZoneToRemoteDb', async (xx: string) => {
          return Result.buildSuccessResult()
        })
        TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZoneToPreferences', (xx: string) => {
          return false;
        })
        expect((await saveLockedTimeZone(''))).assertFalse();
        TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZoneToPreferences', (xx: string) => {
          return true;
        })
        expect((await saveLockedTimeZone(''))).assertTrue();
        TestUtil.setPrivateAttribute(service!, 'saveTimeZoneToRemoteDb', saveToDb);
        TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZoneToPreferences', saveToPre);
      }
    });

    it('test_saveLockTimeZoneSwitch', 0, async () => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      const tSaveLockTimeZoneSwitch = TestUtil.getPrivateFunction(service!, 'saveLockTimeZoneSwitch');
      if (EmptyUtils.isUndefinedOrNull(tSaveLockTimeZoneSwitch)) {
        expect(tSaveLockTimeZoneSwitch).assertNull();
      } else {
        const saveLockTimeZoneSwitch = tSaveLockTimeZoneSwitch!
        let saveToDb: Function = TestUtil.getPrivateFunction(service!, 'saveLockTimeZoneSwitchToRemoteDb')!;
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToRemoteDb', async (xx: boolean) => {
          return Result.buildFailResult(-1, 'error');
        })
        expect((await saveLockTimeZoneSwitch(false))).assertFalse();
        let saveToPre: Function = TestUtil.getPrivateFunction(service!, 'saveLockTimeZoneSwitchToPreferences')!;
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToRemoteDb', async (xx: boolean) => {
          return Result.buildSuccessResult(1);
        })
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToPreferences', (xx: boolean) => {
          return false;
        })
        expect((await saveLockTimeZoneSwitch(false))).assertFalse();
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToPreferences', (xx: boolean) => {
          return true;
        })
        expect((await saveLockTimeZoneSwitch(false))).assertTrue();
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToRemoteDb', saveToDb);
        TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitchToPreferences', saveToPre);
      }
    });

    it('test_updateLockTimeZoneSwitch', 0, async () => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      let updateResult = await service!.updateLockTimeZoneSwitch(service!.isTimeZoneLocked());
      expect(updateResult).assertTrue();
      updateResult = await service!.updateLockTimeZoneSwitch(new Object() as boolean);
      expect(updateResult).assertFalse();
      let saveValue: Function = TestUtil.getPrivateFunction(service!, 'saveLockTimeZoneSwitch')!;
      TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitch', async (xx: boolean) => {
        return false;
      })
      updateResult = await service!.updateLockTimeZoneSwitch(!service!.isTimeZoneLocked());
      expect(updateResult).assertFalse();
      TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitch', async (xx: boolean) => {
        return true;
      })
      updateResult = await service!.updateLockTimeZoneSwitch(!service!.isTimeZoneLocked());
      expect(updateResult).assertTrue();
      TestUtil.setPrivateAttribute(service!, 'saveLockTimeZoneSwitch', saveValue);
    });

    it('test_updateLockedTimeZone', 0, async () => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      let updateResult = await service!.updateLockedTimeZone(service!.getLockedTimeZone());
      expect(updateResult).assertTrue();
      updateResult = await service!.updateLockedTimeZone(new Object() as string);
      expect(updateResult).assertFalse();
      let saveValue: Function = TestUtil.getPrivateFunction(service!, 'saveLockedTimeZone')!;
      TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZone', async (xx: boolean) => {
        return false;
      })
      updateResult = await service!.updateLockedTimeZone((service!.getLockedTimeZone() + 'aaa'));
      expect(updateResult).assertFalse();
      TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZone', async (xx: boolean) => {
        return true;
      })
      updateResult = await service!.updateLockedTimeZone('Asia/Shanghai');
      expect(updateResult).assertTrue();
      TestUtil.setPrivateAttribute(service!, 'saveLockedTimeZone', saveValue);
    });

    it('should_set_timeZoneOffset_to_0_when_mLockTimeZoneSwitch_is_false', 0, async() => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      TestUtil.setPrivateAttribute(service!, 'mLockTimeZoneSwitch', false);
      TestUtil.setPrivateAttribute(service!, 'mLockedTimeZone', 'Asia/Tokyo');
      const updateTimeZoneFunction = TestUtil.getPrivateFunction(service!, 'systemTimeZoneChangeHandler')!;
      updateTimeZoneFunction();
      expect(CalendarDate.timeZone).assertEqual('Asia/Shanghai');
    });

    it('should_set_timeZoneOffset_to_the_result_of_getTimeZoneOffsetById_when_mLockTimeZoneSwitch_is_true', 0, async() => {
      const service = await ServiceManager.getInstance()
        .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
      TestUtil.setPrivateAttribute(service!, 'mLockTimeZoneSwitch', true);
      TestUtil.setPrivateAttribute(service!, 'mLockedTimeZone', 'Asia/Tokyo');
      const updateTimeZoneFunction = TestUtil.getPrivateFunction(service!, 'systemTimeZoneChangeHandler')!;
      updateTimeZoneFunction();
      expect(CalendarDate.timeZone).assertEqual('Asia/Tokyo');
    });
  });
}