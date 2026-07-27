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
import {
  AccountItemData,
  AccountUtils,
  behaviorEvents,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  GlobalData,
  GlobalThis,
  Log,
  ReportHiEventParams,
  ReportUtil,
  ShareMemberSourceTypeEnum,
  ShareRole,
  SourceTypeEnum,
  EmptyUtils,
} from '@app/common';
import { AccountGroup } from '@app/common/src/main/ets/account/AccountGroup';
import HashMap from '@ohos.util.HashMap';
import { i18n } from '@kit.LocalizationKit';
const TAG = 'AccountCommon';

export class AccountCommon {
  /**
   * 初始化帐户列表
   */
async initAccounts(accountList: CalendarContract.Accounts[],
                      accountGroupList: AccountGroup[],
                      showAccountList: AccountItemData[],
                      accountGroupMap: HashMap<string, number>,
                      localGroupNameMap: HashMap<string, string>,
                      defaultAccountStr: string,
                      sourceCustomAccountIds: number[]) {
    const accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    accountList.push(...AccountUtils.sortAccountListInAccPage(accounts));
    accountList = accountList.filter(accounts => {
      return accounts.accountType !== CalendarAccountType.HOLIDAY_ACCOUNT_TYPE;
    });
    accountList.forEach(item => {
      if (item.accountType === CalendarAccountType.CUSTOM_ACCOUNT_TYPE) {
        sourceCustomAccountIds.push(item.id);
      }
    });
    Log.info(TAG, `update accounts length : ${accounts.length}`);
    await this.getShowAccountList(
      accountList, showAccountList, localGroupNameMap, defaultAccountStr);
    this.getAccountGroupList(showAccountList, accountGroupMap, accountGroupList);
  }

  /**
   * 初始化帐户组标题 map
   */
  initGroupNameMap(localGroupNameMap: HashMap<string, string>, defaultAccountStr: string) {
    localGroupNameMap.set(CalendarAccountType.LOCAL_ACCOUNT_TYPE, defaultAccountStr);
    localGroupNameMap.set(CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE, defaultAccountStr);
    localGroupNameMap.set(CalendarAccountType.CUSTOM_ACCOUNT_TYPE, defaultAccountStr);
  }

  /**
   * 获取帐户组对象数组
   */
  getAccountGroupList(showAccountList: AccountItemData[],
                      accountGroupMap: HashMap<string, number>,
                      accountGroupList: AccountGroup[]) {
    for (let i = 0; i < showAccountList.length; i++) {
      const showAccount: AccountItemData = showAccountList[i];
      const accGroupName: string = showAccount.groupName;
      if (accountGroupMap.hasKey(accGroupName)) {
        const index: number = accountGroupMap.get(accGroupName);
        accountGroupList[index].items.push(showAccount);
      } else {
        let tempGroup: AccountGroup = new AccountGroup(accGroupName, []);
        tempGroup.items.push(showAccount);
        const arrayLength: number = accountGroupList.push(tempGroup);
        accountGroupMap.set(accGroupName, arrayLength - 1);
      }
    }
    let params: ReportHiEventParams = {
      ACCOUNT_COUNTS: this.getAccountGroupListLength(accountGroupList)
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.accountGetCounts, params);
  }

  /**
   * 获取帐户界面展示的帐户列表
   */
  async getShowAccountList(accountList: CalendarContract.Accounts[], showAccountList: AccountItemData[],
    localGroupNameMap: HashMap<string, string>, defaultAccountStr: string) {
    for (let i = 0; i < accountList.length; i++) {
      const showItem: AccountItemData = new AccountItemData();
      const calendarAccounts: CalendarContract.Accounts = accountList[i];
      showItem.creator = calendarAccounts.creator;
      showItem.id = calendarAccounts.id;
      showItem.accountName = calendarAccounts.accountName;
      showItem.accountType = calendarAccounts.accountType;
      showItem.name = calendarAccounts.name;
      showItem.calendarDisplayName = calendarAccounts.calendarDisplayName;
      if (showItem.calendarDisplayName === '') {
        showItem.calendarDisplayName = calendarAccounts.accountName;
      }
      showItem.calendarColor = AccountUtils.getAdaptedAccountColorValue(calendarAccounts.calendarColor);
      showItem.calendarAccessLevel = calendarAccounts.calendarAccessLevel;
      showItem.visible = calendarAccounts.visible;
      showItem.canReminder = calendarAccounts.canReminder;
      if (showItem.groupName === '') {
        showItem.groupName = this.getGroupName(calendarAccounts, localGroupNameMap, defaultAccountStr);
      }
      showItem.uuid = calendarAccounts.uuid;
      showAccountList.push(showItem);
    }
  }

  getGroupName(calendarAccounts: CalendarContract.Accounts, localGroupNameMap: HashMap<string, string>, defaultAccountStr: string): string {
    if (AccountUtils.isDefaultAccount(calendarAccounts) || AccountUtils.isCustomAccount(calendarAccounts) ||
    AccountUtils.isDefaultBirthDayAccount(calendarAccounts)) {
      return defaultAccountStr;
    }
    if (AccountUtils.isWeLinkAccount(calendarAccounts)) {
      return 'Welink';
    }
    if (CalendarAccountType.OpenHarmony_EXCHANGE_ACCOUNT_TYPE == calendarAccounts.accountType) {
      return calendarAccounts.calendarDisplayName;
    }
    if (AccountUtils.isThirdAppAccount(calendarAccounts)) {
      return GlobalThis.getResourceStr($r('app.string.third_app_event'), i18n.System.getSystemLanguage());
    }
    return calendarAccounts.accountType;
  }

  getAccountGroupListLength(accountGroupList: AccountGroup[]): number {
    if (!accountGroupList || accountGroupList.length === 0) {
      return 0;
    } else {
      let len = 0;
      accountGroupList.forEach((item: AccountGroup) => {
        len += item.items.length;
      })
      return len;
    }
  }
}