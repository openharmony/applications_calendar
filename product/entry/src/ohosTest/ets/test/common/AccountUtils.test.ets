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
import {
  AccountColor,
  AccountUtils,
  AgendaEventInfo,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis
} from '@app/common/';

function buildAccount(accountName: string = '',
                      accountType: string = '',
                      creator: string = ''): CalendarContract.Accounts {
  let account = new CalendarContract.Accounts();
  account.accountName = accountName;
  account.accountType = accountType;
  account.creator = creator;
  return account;
}

const defaultAccount = buildAccount('local', CalendarAccountType.LOCAL_ACCOUNT_TYPE, 'com.openharmony.calendardata');
const birthdayAccount = buildAccount('birthday', CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE);
const customThirdAccount = buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE);
const customCalendarAccount = buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE, 'com.openharmony.calendar');
const customCalendarDataAccount = buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE, 'com.openharmony.calendardata');
const weLinkAccount1 = buildAccount('weLinkAccount1', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'com.openharmony.it.works');
const weLinkAccount2 = buildAccount('weLinkAccount2', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'com.openharmony.it.works');
const exchangeAccount = buildAccount('exchange', CalendarAccountType.OpenHarmony_EXCHANGE_ACCOUNT_TYPE);
const otherAccount1 = buildAccount('otherAccount1', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'aaa');
const otherAccount2 = buildAccount('otherAccount2', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'aaa');

export default function AccountUtilsTest() {
  describe('AccountUtilsTest', () => {
    // 华为账号下的item排序 1.'local' 2.'birthday'  2.'custom' 3.'others'
    it('sortAccountListInAccPage_huaweiSort', 0, () => {
      const sortedAccountList = AccountUtils.sortAccountListInAccPage(
        [otherAccount1, defaultAccount, customCalendarAccount, birthdayAccount, otherAccount2]);
      expect(sortedAccountList[0]).assertDeepEquals(defaultAccount);
      expect(sortedAccountList[1]).assertDeepEquals(birthdayAccount);
      expect(sortedAccountList[2]).assertDeepEquals(customCalendarAccount);
      expect(sortedAccountList[3]).assertDeepEquals(otherAccount1);
      expect(sortedAccountList[4]).assertDeepEquals(otherAccount2);
    });

    it('sortAccountListInAccPage_weLinkAccount', 0, () => {
      const sortedAccountList = AccountUtils.sortAccountListInAccPage(
        [otherAccount1, weLinkAccount1, weLinkAccount2, otherAccount2]);
      expect(sortedAccountList[0]).assertDeepEquals(weLinkAccount1);
      expect(sortedAccountList[1]).assertDeepEquals(weLinkAccount2);
      expect(sortedAccountList[2]).assertDeepEquals(otherAccount1);
      expect(sortedAccountList[3]).assertDeepEquals(otherAccount2);
    });

    it('sortAccountListInAccPage_thirdAppAccount', 0, () => {
      const sortedAccountList = AccountUtils.sortAccountListInAccPage(
        [otherAccount1, exchangeAccount, otherAccount2]);
      expect(sortedAccountList[0]).assertDeepEquals(otherAccount1);
      expect(sortedAccountList[1]).assertDeepEquals(otherAccount2);
      expect(sortedAccountList[2]).assertDeepEquals(exchangeAccount);
    });

    it('sortAccountListInAccPopup_normal', 0, () => {
      const sortedAccountList = AccountUtils.sortAccountListInAccPopup(
        [otherAccount1, defaultAccount, customCalendarAccount, otherAccount2]);

      expect(sortedAccountList[0]).assertDeepEquals(defaultAccount);
      expect(sortedAccountList[1]).assertDeepEquals(customCalendarAccount);
      expect(sortedAccountList[2]).assertDeepEquals(otherAccount1);
      expect(sortedAccountList[3]).assertDeepEquals(otherAccount2);
    });

    it('isThirdAppAccount', 0, () => {
      expect(AccountUtils.isThirdAppAccount(defaultAccount)).assertFalse();
      expect(AccountUtils.isThirdAppAccount(customThirdAccount)).assertTrue();
      expect(AccountUtils.isThirdAppAccount(customCalendarAccount)).assertFalse();
      expect(AccountUtils.isThirdAppAccount(customCalendarDataAccount)).assertFalse();
      expect(AccountUtils.isThirdAppAccount(weLinkAccount1)).assertFalse();
      expect(AccountUtils.isThirdAppAccount(exchangeAccount)).assertFalse();
      let testAccount = buildAccount('local', CalendarAccountType.LOCAL_ACCOUNT_TYPE);
      expect(AccountUtils.isThirdAppAccount(testAccount)).assertTrue();
    })

    it('getAccountColorName', 0, () => {
      expect(AccountUtils.getAccountColorName(AccountColor.RED).id).assertEqual($r('app.string.accessibility_account_color_vermilion').id);
      expect(AccountUtils.getAccountColorName(AccountColor.BLUE).id).assertEqual($r('app.string.accessibility_account_color_indigo').id);
      expect(AccountUtils.getAccountColorName(100).id).assertEqual($r('app.string.accessibility_account_color_other').id);
    })

    it('isNotInCalendarColors', 0, () => {
      expect(AccountUtils.isNotInCalendarColors(AccountColor.RED)).assertFalse()
      expect(AccountUtils.isNotInCalendarColors(AccountColor.BLUE)).assertFalse()
      expect(AccountUtils.isNotInCalendarColors(100)).assertTrue()
    })

    it('HexColor', 0, () => {
      expect(AccountUtils.HexColor(16777215)).assertEqual('ffffff');
      expect(AccountUtils.HexColor(0)).assertEqual('000000');
      expect(AccountUtils.HexColor(-1)).assertEqual('ffffff');
      expect(AccountUtils.HexColor(-6678784)).assertEqual('9a1700');
      expect(AccountUtils.HexColor(-5488128)).assertEqual('ac4200');
      expect(AccountUtils.HexColor(-6258176)).assertEqual('a08200');
      expect(AccountUtils.HexColor(-15100928)).assertEqual('199400');
      expect(AccountUtils.HexColor(-16756331)).assertEqual('005195');
      expect(AccountUtils.HexColor(-15859554)).assertEqual('0e009e');
      expect(AccountUtils.HexColor(-11534181)).assertEqual('50009b');
      expect(AccountUtils.HexColor(-12213274)).assertEqual('45a3e6');
      expect(AccountUtils.HexColor(4563942)).assertEqual('45a3e6');
      expect(AccountUtils.HexColor(4279861720)).assertEqual('1981d8');
      expect(AccountUtils.HexColor(-3756424744)).assertEqual('1981d8');
    })

    it('checkIsSameColor', 0, () => {
      expect(AccountUtils.checkIsSameColor(1939711, -14837505)).assertTrue();
      expect(AccountUtils.checkIsSameColor(1939712, -14837505)).assertFalse();
    })

    it('getOldAccountColorMap', 0, () => {
      expect(AccountUtils.getOldAccountMapNowAccount(-43956)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-1686170)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-565179)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-6678784)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-3059398)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-3059308)).assertEqual(AccountColor.RED);

      expect(AccountUtils.getOldAccountMapNowAccount(-2722504)).assertEqual(AccountColor.DARK_ORANGE);
      expect(AccountUtils.getOldAccountMapNowAccount(-3694080)).assertEqual(AccountColor.LIGHT_ORANGE);
      expect(AccountUtils.getOldAccountMapNowAccount(-9722273)).assertEqual(AccountColor.GREEN);
      expect(AccountUtils.getOldAccountMapNowAccount(-15105576)).assertEqual(AccountColor.TURQUOISE);
      expect(AccountUtils.getOldAccountMapNowAccount(-10002745)).assertEqual(AccountColor.BLUE);
      expect(AccountUtils.getOldAccountMapNowAccount(-7185721)).assertEqual(AccountColor.PURPLE);

      expect(AccountUtils.getOldAccountMapNowAccount(0)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-16777215)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(16777215)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(-8947848)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(8947848)).assertEqual(AccountColor.RED);
      expect(AccountUtils.getOldAccountMapNowAccount(1000000)).assertEqual(AccountColor.RED);

      expect(AccountUtils.getOldAccountMapNowAccount(13717818)).assertEqual(AccountColor.RED & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(14054712)).assertEqual(AccountColor.DARK_ORANGE & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(13083136)).assertEqual(AccountColor.LIGHT_ORANGE & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(7054943)).assertEqual(AccountColor.GREEN & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(1671640)).assertEqual(AccountColor.TURQUOISE & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(6774471)).assertEqual(AccountColor.BLUE & 0xFFFFFF);
      expect(AccountUtils.getOldAccountMapNowAccount(9591495)).assertEqual(AccountColor.PURPLE & 0xFFFFFF);
    })

    it('isBirthDayAccountById_test', 0, async (done: Function) => {
      let mocker = new MockKit();
      let func = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(func)(ArgumentMatchers.any).afterReturn('1,2,4,5');
      if (birthdayAccount) {
        let isBirthday1 = await AccountUtils.isBirthDayAccountById(2);
        expect(isBirthday1).assertTrue();
        let isBirthday2 = await AccountUtils.isBirthDayAccountById(8);
        expect(isBirthday2).assertFalse();
      }
      when(func)(ArgumentMatchers.any).afterReturn('1,2');
      let isBirthday = await AccountUtils.isBirthDayAccountById(-1);
      expect(isBirthday).assertFalse();
      done();
    })

    it('isBirthDayAccountByIdAsync_test', 0, async (done: Function) => {
      let mocker = new MockKit();
      let func = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(func)(ArgumentMatchers.any).afterReturn('1,2,7,8');
      if (birthdayAccount) {
        let isBirthday1 = await AccountUtils.isBirthDayAccountById(2);
        expect(isBirthday1).assertTrue();
        let isBirthday2 = await AccountUtils.isBirthDayAccountById(9);
        expect(isBirthday2).assertFalse();
      }
      when(func)(ArgumentMatchers.any).afterReturn('1,2');
      let isBirthday = await AccountUtils.isBirthDayAccountByIdAsync(-1);
      expect(isBirthday).assertFalse();
      done();
    })

    it('getAccountResourceStr_test', 0, async (done: Function) => {
      let mocker = new MockKit();
      let account: CalendarContract.Accounts = new CalendarContract.Accounts();
      let func = mocker.mockFunc(AccountUtils, AccountUtils.isDefaultAccount);
      when(func)(ArgumentMatchers.any).afterReturn(true);
      account.calendarDisplayName = 'Phone';
      let result: ResourceStr = AccountUtils.getAccountResourceStr(account) as Resource;
      expect(GlobalThis.getResourceStr(result)).assertEqual(GlobalThis.getResourceStr($r('app.string.my_calendar')));
      account.calendarDisplayName = 'Calendar';
      result = AccountUtils.getAccountResourceStr(account);
      expect(result).assertEqual('Calendar');
      done();
    })
  })
}