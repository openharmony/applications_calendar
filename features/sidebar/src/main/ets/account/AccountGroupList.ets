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
  CommonInnerEvent,
  EventService,
  Log,
  ReportHiEventParams,
  ReportUtil,
  ShareMemberSourceTypeEnum,
  ShareRole,
  SourceTypeEnum,
  TabType,
  ServiceEnum,
  statisticEvents,
  HiEventParamsConfirm,
  DialogControllerOptions,
  EmptyUtils,
} from '@app/common';
import { AccountGroupItem } from './AccountGroupItem';
import HashMap from '@ohos.util.HashMap';
import emitter from '@ohos.events.emitter';
import { AccountGroup } from '@app/common/src/main/ets/account/AccountGroup';
import { AccountCommon } from './AccountCommon';
import { CommonTextDialog } from '@app/common.components';

const TAG = 'SideBarAccountGroupList';

/**
 * 账户管理界面——所有账户列表
 */
@Component
export struct AccountGroupList {
  // 分组后的帐户数组
  @State @Watch('onAccountGroupListChange') accountGroupList: AccountGroup[] = [];

  // 第一次进入
  @State firstIn: boolean = true;

  // 主题色
  @State themeColor: string = '';

  // 侧边栏是否为悬浮态
  @Prop sideBarOverlay: boolean;

  @StorageLink('tabIndex') tabsIndex: number = TabType.MONTH;

  //账户列表的高度,用于动效,初始设为0
  @State accountHeight: Length = 0;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 帐户数据数组
  private accountList: CalendarContract.Accounts[] = [];

  // 帐户列表自定义帐户数组
  private showAccountList: AccountItemData[] = [];

  // 记录组标题和分组数组的 index 映射关系
  private accountGroupMap: HashMap<string, number> = new HashMap<string, number>();

  // 帐户组标题 map
  private localGroupNameMap: HashMap<string, string> = new HashMap<string, string>();

  private accountCommon: AccountCommon = new AccountCommon();

  private sourceCustomAccountIds: number[] = [];

  private updateAccountInfoHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
  };

  private updateContractInfoHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
  };

  private accountExitHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
  };

  // 待删除用的日历账户数据
  private preDeleteAccountId: number = -1;

  private deleteAccountHandler: (accountId: number, uuid: string) => void = (accountId: number, uuid: string) => {
    this.preDeleteAccountId = accountId;
    this.deleteDialogController?.open();
  };

  /**
   * 删除弹窗
   */
  private deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message:  $r('app.string.custom_account_delete_message'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      onCancelClick: (() => {
        Log.info(TAG, 'click dialog cancel');
        this.deleteDialogController?.close()
      }),
      onConfirmClick: (() => {
        const params: ReportHiEventParams = {
          IS_SAVE: HiEventParamsConfirm.TRUE
        }
        ReportUtil.reportStatisticEvent(statisticEvents.deleteAccountSavePopup, params);
        this.deleteAccount();
      })
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  aboutToAppear() {
    Log.info(TAG, `aboutToAppear init accountInfo`);
    this.accountCommon.initGroupNameMap(this.localGroupNameMap, AccountUtils.DEFAULT_ACCOUNT_GROUP);
    this.accountCommon.initAccounts(
      this.accountList,
      this.accountGroupList,
      this.showAccountList,
      this.accountGroupMap,
      this.localGroupNameMap,
      AccountUtils.DEFAULT_ACCOUNT_GROUP,
      this.sourceCustomAccountIds)
      .then(() => { //加载完成后将高度设为''用于自适应展开动效
        this.accountHeight = '';
      });
    this.emmitOnInit();
  }

  onAccountGroupListChange() {
    if (this.firstIn) {
      this.firstIn = false;
      return;
    }
    let params: ReportHiEventParams = {
      ACCOUNT_COUNTS: this.accountCommon.getAccountGroupListLength(this.accountGroupList)
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.accountGetCounts, params);
  }

  async updateAccountData() {
    let accounts: CalendarContract.Accounts[] = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    Log.info(TAG, `update accounts length : ${accounts.length}`);
    this.accountList = AccountUtils.sortAccountListInAccPage(accounts);
    this.accountList = this.accountList.filter(accounts => {
      return accounts.accountType !== CalendarAccountType.HOLIDAY_ACCOUNT_TYPE;
    });
    await this.updateShowAccountList();
    this.updateAccountGroupList();
  }

  /**
   * 删除帐户
   */
  async deleteAccount() {
    if (this.preDeleteAccountId < 0) {
      Log.error(TAG, `Delete account err, preDeleteAccountId small than 0: ${this.preDeleteAccountId}`);
      return;
    }
    // 先删除该账户下的所有日程，避免外键约束导致删除失败
    const events = await EventService.INSTANCE.queryEventsByAccountIds([this.preDeleteAccountId]);
    if (events.length > 0) {
      const eventIds = new Set(events.map(event => event.mId));
      await EventService.INSTANCE.deleteEvents(eventIds);
    }
    let deleteSum: number = await CalendarService.INSTANCE.deleteCalendarById(this.preDeleteAccountId) as number;
    this.preDeleteAccountId = -1;
    if (deleteSum <= 0) {
      Log.error(TAG, `Delete a new account err, sum = ${deleteSum}`);
      return;
    }
    Log.info(TAG, `Delete a new account succeed, sum = ${deleteSum}`);
  }

  /**
   * 更新帐户界面展示的帐户列表
   */
  async updateShowAccountList() {
    let newShowAccountList: AccountItemData[] = [];
    for (let i = 0; i < this.accountList.length; i++) {
      let showItem: AccountItemData = new AccountItemData();
      showItem.creator = this.accountList[i].creator;
      showItem.id = this.accountList[i].id;
      showItem.accountName = this.accountList[i].accountName;
      showItem.accountType = this.accountList[i].accountType;
      showItem.name = this.accountList[i].name;
      showItem.calendarDisplayName = this.accountList[i].calendarDisplayName;
      if (showItem.calendarDisplayName === '') {
        showItem.calendarDisplayName = this.accountList[i].accountName;
      }
      showItem.calendarColor = this.accountList[i].calendarColor;
      showItem.calendarAccessLevel = this.accountList[i].calendarAccessLevel;
      showItem.visible = this.accountList[i].visible;
      showItem.canReminder = this.accountList[i].canReminder;
      if (showItem.groupName === '') {
        showItem.groupName = this.accountCommon.getGroupName(this.accountList[i],
          this.localGroupNameMap, AccountUtils.DEFAULT_ACCOUNT_GROUP);
      }
      showItem.uuid = this.accountList[i].uuid;
      newShowAccountList.push(showItem);
    }
    this.showAccountList = newShowAccountList;
    Log.info(TAG, `update showAccountList success, length : ${this.showAccountList.length}`);
  }

  /**
   * 更新帐户列表
   */
  private async updateAccountGroupList() {
    let newAccountGroupList: AccountGroup[] = [];
    this.accountGroupMap = new HashMap<string, number>();
    for (let i = 0; i < this.showAccountList.length; i++) {
      const showAccount: AccountItemData = this.showAccountList[i];
      const accGroupName: string = showAccount.groupName;
      if (this.accountGroupMap.hasKey(accGroupName)) {
        const index: number = this.accountGroupMap.get(accGroupName);
        newAccountGroupList[index].items.push(showAccount);
      } else {
        let tempGroup: AccountGroup = new AccountGroup(accGroupName, []);
        tempGroup.items.push(showAccount);
        const arrayLength: number = newAccountGroupList.push(tempGroup);
        this.accountGroupMap.set(accGroupName, arrayLength - 1);
      }
    }
    this.accountGroupList = newAccountGroupList.slice(0);
  }

  aboutToDisappear() {
    Log.info(TAG, `aboutToDisappear uninit accountInfo`);
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.updateAccountInfoHandler);
    emitter.off(CommonInnerEvent.EVENT_ON_ACCOUNT_CONTRACT_COUNT_CHANGED, this.updateContractInfoHandler);
    emitter.off(CommonInnerEvent.EVENT_ON_ACCOUNT_EXIT, this.accountExitHandler);
  }

  build() {
    Column() {
      ForEach(this.accountGroupList, (accountGroup: AccountGroup) => {
        AccountGroupItem({
          groupName: accountGroup.groupName,
          items: accountGroup.items,
          themeColor: this.themeColor,
          sideBarOverlay: this.sideBarOverlay,
          deleteAccountHandler: this.deleteAccountHandler,
        })
      })
    }.height(this.accountHeight)
  }

  private emmitOnInit() {
    this.updateAccountInfoHandler = (data: emitter.EventData): void => {
      if (data?.data?.table === 'Calendars') {
        Log.info(TAG, `aboutToAppear Calendars tab changed`);
        this.updateAccountData();
      }
    };
    this.updateContractInfoHandler = (data: emitter.EventData): void => {
      Log.info(TAG, `aboutToAppear EVENT_ON_ACCOUNT_CONTRACT_COUNT_CHANGED`);
      // 异步插入的联系人关系,延迟两秒再刷新
      setTimeout(() => {
        this.updateAccountData();
      }, 2000)
    };
    this.accountExitHandler = (data: emitter.EventData): void => {
      Log.info(TAG, `aboutToAppear EVENT_ON_ACCOUNT_EXIT`);
      if (data?.data?.calendarId) {
        const newShowAccountList: AccountItemData[] = [];
        this.showAccountList.forEach(account => {
          if (account.id !== data?.data?.calendarId) {
            newShowAccountList.push(account);
          }
        });
        this.showAccountList = newShowAccountList;
        this.updateAccountGroupList();
      }
    };
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.updateAccountInfoHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_ON_ACCOUNT_CONTRACT_COUNT_CHANGED }, this.updateContractInfoHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_ON_ACCOUNT_EXIT }, this.accountExitHandler);
  }
}