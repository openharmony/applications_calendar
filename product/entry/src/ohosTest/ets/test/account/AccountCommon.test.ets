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
import { describe, expect, it } from '@ohos/hypium/src/main/interface';
import { HashMap } from '@kit.ArkTS';
import { CalendarAccountType, CalendarContract, GlobalThis } from '@app/common';
import { AccountCommon } from '@app/feature.sidebar/src/main/ets/account/AccountCommon';
import { i18n } from '@kit.LocalizationKit';

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
const birthdayAccount2 = buildAccount('birthday', CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE);
const customThirdAccount = buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE);
const customCalendarAccount =
  buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE, 'com.openharmony.calendar');
const customCalendarDataAccount =
  buildAccount('custom', CalendarAccountType.CUSTOM_ACCOUNT_TYPE, 'com.openharmony.calendardata');
const weLinkAccount1 = buildAccount('weLinkAccount1', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'com.openharmony.it.works');
const weLinkAccount2 = buildAccount('weLinkAccount2', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'com.openharmony.it.welink');
const otherAccount1 = buildAccount('otherAccount1', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'aaa');
const otherAccount2 = buildAccount('otherAccount2', CalendarAccountType.EMAIL_ACCOUNT_TYPE, 'aaa');

export default function AccountCommonTest() {
  const accountCommon: AccountCommon = new AccountCommon();

  describe('AccountCommonTest', () => {

    it('AccountCommon_getGroupName_local', 0, () => {
      expect(accountCommon.getGroupName(defaultAccount, new HashMap<string, string>(), 'test')).assertEqual('test');
    })

    it('AccountCommon_getGroupName_birthday', 0, () => {
      expect(accountCommon.getGroupName(birthdayAccount, new HashMap<string, string>(), 'test')).assertEqual('test');
    })

    it('AccountCommon_getGroupName_custom', 0, () => {
      expect(accountCommon.getGroupName(customThirdAccount, new HashMap<string, string>(), 'test'))
        .assertEqual('应用日程');
      expect(accountCommon.getGroupName(customCalendarAccount, new HashMap<string, string>(), 'test'))
        .assertEqual('test');
      expect(accountCommon.getGroupName(customCalendarDataAccount, new HashMap<string, string>(), 'test'))
        .assertEqual('test');
    })

    it('AccountCommon_getGroupName_welink', 0, () => {
      expect(accountCommon.getGroupName(weLinkAccount1, new HashMap<string, string>(), 'test')).assertEqual('Welink');
      expect(accountCommon.getGroupName(weLinkAccount2, new HashMap<string, string>(), 'test')).assertEqual('Welink');
    })

    it('AccountCommon_getGroupName_other', 0, () => {
      const otherGroupName =
        GlobalThis.getResourceStr($r('app.string.third_app_event'), i18n.System.getSystemLanguage());
      expect(accountCommon.getGroupName(otherAccount1, new HashMap<string, string>(), 'test'))
        .assertEqual(otherGroupName);
      expect(accountCommon.getGroupName(otherAccount2, new HashMap<string, string>(), 'test'))
        .assertEqual(otherGroupName);
      expect(accountCommon.getGroupName(birthdayAccount2, new HashMap<string, string>(), 'test'))
        .assertEqual(otherGroupName);
    })
  })
}