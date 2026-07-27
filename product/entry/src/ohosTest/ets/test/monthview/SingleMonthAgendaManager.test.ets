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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { SingleMonthAgendaManager } from '@app/feature.monthview/src/main/ets/viewmodel/SingleMonthAgendaManager';
import { SingleMonthlyViewModel } from '@app/feature.monthview/src/main/ets/viewmodel/SingleMonthlyViewModel';
import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import {
  AgendaEventInfo,
  CalendarAccountType,
  CalendarContract,
  CalendarDate,
  DateUtil,
  InstanceService,
  MILLS_PER_DAY,
} from '@app/common';
import { HashMap } from '@kit.ArkTS';

class SingleMonthAgendaManagerMock extends SingleMonthAgendaManager {
  constructor(sigMonthVM: SingleMonthlyViewModel) {
    super(sigMonthVM);
  }

  sigWeekNoAgendaChange(weekAccount: number) {
    super.sigWeekNoAgendaChange(weekAccount);
  }

  groupImportantAgendas(importantAgendas: AgendaEventInfo[]) {
    super.groupImportantAgendas(importantAgendas, new Date().getTime());
  }

  isImportantEventCanShow(event: AgendaEventInfo, selectDateBegin: number, selectedDateEnd: number): boolean {
    return super.isImportantEventCanShow(event, selectDateBegin, selectedDateEnd);
  }
}

export default function SingleMonthAgendaManagerTest() {
  describe('SingleMonthAgendaManagerTest', () => {

    it('constructor', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo(1, 1, 1, 1)));
      expect(manager.sigMonthVM).not().assertNull();
    })

    it('getNotificationEndTimes_empty_agendaResult', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      manager.agendaResult = [];
      expect(manager.getNotificationEndTimes().length).assertEqual(0);
    })

    it('getNotificationEndTimes_agendaEndTime_over_currTime', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      let agendaInfo = new AgendaEventInfo();
      agendaInfo.mEnd = new Date().getTime() + 10000;
      manager.agendaResult = [agendaInfo];
      expect(manager.getNotificationEndTimes()).not().assertEqual([]);
    })

    it('getAccountList', 0, async (done: Function)  => {
      let mocker: MockKit = new MockKit();
      const instanceService = InstanceService.INSTANCE;
      let mockFunc: Function = mocker.mockFunc(
        instanceService, instanceService.queryAccountListTask
      );
      const account1 = new CalendarContract.Accounts;
      account1.id = 1;
      account1.accountType = CalendarAccountType.LOCAL_ACCOUNT_TYPE;
      const infos: CalendarContract.Accounts[] = [account1];
      when(mockFunc)(ArgumentMatchers.any).afterReturn(infos);
      SingleMonthAgendaManager.accountList = [];
      const accountMap: HashMap<number, CalendarContract.Accounts> = await SingleMonthAgendaManager.getAccountMap();
      expect(accountMap.get(1)).not().assertNull();
      const accountMap2: HashMap<number, CalendarContract.Accounts> = await SingleMonthAgendaManager.getAccountMap();
      expect(accountMap2.get(1)).not().assertNull();
      done();
    })

    it('analyzeAgendaInDate_null_selectDate', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      manager.agendaResult = [new AgendaEventInfo()];
      expect(manager.analyzeAgendaInDate(undefined)).assertFalse();
    })

    it('onSigWeekAgendaChange_null', 0, () => {
      let hasError: boolean = true;
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      manager.onSigWeekAgendaChange([]);
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('onSigWeekAgendaChange', 0, () => {
      let hasError: boolean = true;
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      manager.onSigWeekAgendaChange([new AgendaEventInfo()]);
      hasError = false;
      expect(hasError).assertFalse();
    });

    it('sigWeekNoAgendaChange_0', 0, () => {
      let hasError: boolean = true;
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      manager.sigWeekNoAgendaChange(4)
      hasError = false;
      expect(hasError).assertFalse();
    });

    // 重要日列表进行排序 倒数日在纪念日前面。倒数日时间戳越小越靠前，纪念日时间戳越大越靠前
    it('groupImportantAgendas', 0, () => {
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      const info1 = new AgendaEventInfo();
      info1.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES
      info1.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      const info2 = new AgendaEventInfo();
      info2.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES
      info2.mBegin = info1.mBegin + 100;
      const info3 = new AgendaEventInfo();
      info3.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN
      info3.mBegin = info1.mBegin;
      const info4 = new AgendaEventInfo();
      info4.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN
      info4.mBegin = info1.mBegin + 100;
      let result = [info1, info2, info3, info4];
      manager.groupImportantAgendas(result);
      expect(result[0]).assertDeepEquals(info3);
      expect(result[1]).assertDeepEquals(info4);
      expect(result[2]).assertDeepEquals(info2);
      expect(result[3]).assertDeepEquals(info1);
    });
    // 跨天的日程靠前
    it('sortAgendaList_cross_day', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      const info1 = new AgendaEventInfo();
      info1.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      info1.mEnd = new CalendarDate(2024, 1, 2, 1).getTime();
      const info2 = new AgendaEventInfo();
      info2.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      info2.mEnd = info2.mBegin + 1;
      const result = manager.sortAgendaList([info2, info1]);
      expect(result[0]).assertDeepEquals(info1);
      expect(result[1]).assertDeepEquals(info2);
    });

    // 开始时间早的排序靠前
    it('sortAgendaList_begin_early', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      const info1 = new AgendaEventInfo();
      info1.mBegin = new CalendarDate(2024, 1, 1, 2).getTime();
      info1.mEnd = info1.mBegin + 1;
      const info2 = new AgendaEventInfo();
      info2.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      info2.mEnd = info2.mBegin + 1;
      const result = manager.sortAgendaList([info1, info2]);
      expect(result[0]).assertDeepEquals(info2);
      expect(result[1]).assertDeepEquals(info1);
    });

    // 标题排序
    it('sortAgendaList_title', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      const info1 = new AgendaEventInfo();
      info1.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      info1.mEnd = info1.mBegin + 100;
      info1.mTitle = 'bcd';
      const info2 = new AgendaEventInfo();
      info2.mBegin = info1.mBegin;
      info2.mEnd = info1.mEnd;
      info2.mTitle = 'abc';
      const info3 = new AgendaEventInfo();
      info3.mBegin = info1.mBegin;
      info3.mEnd = info1.mEnd;
      info3.mTitle = 'abc';
      const result = manager.sortAgendaList([info1, info3, info2]);
      expect(result[0]).assertDeepEquals(info3);
      expect(result[1]).assertDeepEquals(info2);
      expect(result[2]).assertDeepEquals(info1);
    });
    testIsCanShowImportant();
    // 全天日程排序靠前
    it('sortAgendaList_allDay_early', 0, () => {
      let manager = new SingleMonthAgendaManager(new SingleMonthlyViewModel(new DateInfo()));
      const info1 = new AgendaEventInfo();
      info1.mBegin = new CalendarDate(2024, 1, 1, 2).getTime();
      info1.mEnd = info1.mBegin + 1;
      info1.mTitle = '1';
      info1.mIsAllDay = true;
      const info2 = new AgendaEventInfo();
      info2.mBegin = new CalendarDate(2024, 1, 1, 1).getTime();
      info2.mEnd = info2.mBegin + 1;
      const info3 = new AgendaEventInfo();
      info3.mBegin = new CalendarDate(2024, 1, 1, 2).getTime();
      info3.mEnd = info3.mBegin + 1;
      info3.mTitle = '2';
      info3.mIsAllDay = true;
      const result = manager.sortAgendaList([info1, info2, info3]);
      expect(result[0]).assertDeepEquals(info1);
      expect(result[1]).assertDeepEquals(info3);
      expect(result[2]).assertDeepEquals(info2);
    });

    it('logTodayAgendas', 0, () => {
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      expect(manager.logTodayAgendas(new DateInfo())).assertTrue();
    });

    it('getEndRepetitionTime_001', 0, () => {
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      let event: AgendaEventInfo = new AgendaEventInfo();
      event.mBegin = 1735689600000; // 2025-1-1 8:00
      event.mOriginalBegin = 1735689600000;
      event.mRepeatRule = 'FREQ=MONTHLY;COUNT=3;WKST=MO;BYMONTHDAY=1'; //限定三次
      const endRepetitionTime = manager.getEndRepetitionTime(event);
      expect(endRepetitionTime).assertEqual(1740787200000) // 2025-3-1 8:00;
    });

    it('getEndRepetitionTime_002', 0, () => {
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      let event: AgendaEventInfo = new AgendaEventInfo();
      event.mBegin = 1735689600000 // 2025-1-1 8:00
      event.mRepeatRule = 'FREQ=MONTHLY;UNTIL=20250822T155900Z;WKST=MO;BYMONTHDAY=1'; //截止时间为2025-8-22
      const endRepetitionTime = manager.getEndRepetitionTime(event);
      expect(endRepetitionTime).assertEqual(1755878340000)
    });

    it('getEndRepetitionTime_003', 0, () => {
      let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
      let event: AgendaEventInfo = new AgendaEventInfo();
      event.mBegin = 1735689600000 // 2025-1-1 8:00
      event.mRepeatRule = 'FREQ=MONTHLY;WKST=MO;BYMONTHDAY=1'; //无截止时间
      const endRepetitionTime = manager.getEndRepetitionTime(event);
      expect(endRepetitionTime).assertEqual(0)
    });
  })
}

function testIsCanShowImportant() {
  let date = new CalendarDate();
  date.setUTCFullYear(2024, 5, 7);
  date.setUTCHours(0, 0, 0, 0);
  it('testIsCanShowImportant_Anniversaries', 0, () => {
    let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
    const info = new AgendaEventInfo();
    info.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
    info.mBegin = date.getTime();
    info.mEnd = info.mBegin + MILLS_PER_DAY;
    info.mTitle = 'Anniversaries';
    info.mEventTimeStamp = new CalendarDate(2024, 5, 10).getTime();
    let selectDate = new CalendarDate(2024, 5, 1);
    let startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    let endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertFalse();
    selectDate = new CalendarDate(2024, 5, 7);
    startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertTrue();
  });

  it('testIsCanShowImportant_CountDown', 0, () => {
    let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
    const info = new AgendaEventInfo();
    info.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
    info.mBegin = date.getTime();
    info.mEnd = info.mBegin + MILLS_PER_DAY;
    info.mTitle = 'CountDown';
    info.mEventTimeStamp = new CalendarDate(2024, 5, 2).getTime();
    let selectDate = new CalendarDate(2024, 5, 1);
    let startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    let endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertFalse();
    selectDate = new CalendarDate(2024, 5, 2);
    startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertTrue();
    selectDate = new CalendarDate(2024, 5, 8);
    startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertFalse();
    info.mRepeatRule = 'FREQ=MONTHLY;BYMONTHDAY=7';
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertTrue();
  });

  it('testIsCanShowImportant_normal_type', 0, () => {
    let manager = new SingleMonthAgendaManagerMock(new SingleMonthlyViewModel(new DateInfo()));
    const info: AgendaEventInfo = new AgendaEventInfo();
    info.mImportantEventType === CalendarContract.EventImportantType.NORMAL;
    info.mBegin = date.getTime();
    info.mEnd = info.mBegin + MILLS_PER_DAY;
    info.mTitle = 'CountDown';
    info.mEventTimeStamp = new CalendarDate(2024, 5, 2).getTime();
    let selectDate = new CalendarDate(2024, 5, 1);
    let startOfDate = DateUtil.getStartMillsOfDate(selectDate);
    let endOfDate = DateUtil.getEndMillsOfDate(selectDate);
    expect(manager.isImportantEventCanShow(info, startOfDate, endOfDate)).assertFalse();
  });
}