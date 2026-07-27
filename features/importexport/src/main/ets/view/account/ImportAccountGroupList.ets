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
  GlobalThis,
  Log,
  ReportUtil,
} from '@app/common/index';
import { AccountGroupItem } from './ImportAccountGroupItem';
import HashMap from '@ohos.util.HashMap';
import emitter from '@ohos.events.emitter';
import { AccountGroup } from '@app/common/src/main/ets/account/AccountGroup';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { ImportAccountDetail } from './ImportAccountDetail';
import { i18n } from '@kit.LocalizationKit';

const TAG = 'AccountGroupList';

interface PageParam {
  checkedAccId: number
}

/**
 * 账户管理界面——所有账户列表
 */
@Component
export struct ImportAccountGroupList {
  @Consume navPathStack: NavPathStack;

  @StorageProp('themeColor') themeColor: string = '';

  // 分组后的帐户数组
  @State accountGroupList: AccountGroup[] = [];

  // 是否显示账户详情页面
  @State isShowAccountDetailPage: boolean = false;

  // 模态窗动画结束标识
  @Provide isAccountAniShowFinish: boolean = false;

  // 帐户数据数组
  private accountList: CalendarContract.Accounts[] = [];

  // 帐户列表自定义帐户数组
  private showAccountList: AccountItemData[] = [];

  // 滚动器
  private scroller: Scroller = new Scroller();

  // 记录组标题和分组数组的 index 映射关系
  private accountGroupMap: HashMap<string, number> = new HashMap<string, number>();

  // 默认选中的帐户
  @State private checkedAccId: number = 0;

  private localGroupNameMap: HashMap<string, string> = new HashMap<string, string>();

  private systemDataChangedHandler: (data?: emitter.EventData) => void = (data?: emitter.EventData): void => {
    if (data?.data?.table === 'Calendars') {
      this.updateAccountData();
    }
  };

  aboutToAppear() {
    const paramsArray: PageParam[] = this.navPathStack.getParamByName(NavPathName.IMPORT_ACCOUNT) as PageParam[];
    if (!paramsArray[0]) {
      return;
    }
    const params: PageParam = paramsArray[0];
    this.checkedAccId = params?.checkedAccId;

    if (this.showAccountList.length === 0) {
      this.initGroupNameMap(this.localGroupNameMap, AccountUtils.DEFAULT_ACCOUNT_GROUP);
    }
    this.updateAccountData();
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.systemDataChangedHandler);
  }

  /**
   * 初始化帐户组标题 map
   */
  initGroupNameMap(localGroupNameMap: HashMap<string, string>, defaultAccountStr: string) {
    localGroupNameMap.set(CalendarAccountType.LOCAL_ACCOUNT_TYPE, defaultAccountStr);
    localGroupNameMap.set(CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE, defaultAccountStr);
    localGroupNameMap.set(CalendarAccountType.CUSTOM_ACCOUNT_TYPE, defaultAccountStr);
  }

  getGroupName(calendarAccounts: CalendarContract.Accounts, defaultAccountStr: string): string {
    if (AccountUtils.isDefaultAccount(calendarAccounts) || AccountUtils.isDefaultBirthDayAccount(calendarAccounts)) {
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
    if (AccountUtils.isCustomAccount(calendarAccounts)) {
      return GlobalThis.getResourceStr($r('app.string.account_custom'), i18n.System.getSystemLanguage());
    }
    return calendarAccounts.accountType;
  }

  async updateAccountData() {
    let accounts: CalendarContract.Accounts[] = await CalendarService
      .INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    this.accountList = AccountUtils.sortAccountListInAccPage(accounts);
    this.updateShowAccountList();
    this.updateAccountGroupList();
  }

  /**
   * 更新帐户界面展示的帐户列表
   */
  updateShowAccountList() {
    let newShowAccountList: AccountItemData[] = [];
    for (let i = 0; i < this.accountList.length; i++) {
      let showItem: AccountItemData = new AccountItemData();
      showItem.accountType = this.accountList[i].accountType;
      if (showItem.accountType !== CalendarAccountType.LOCAL_ACCOUNT_TYPE &&
        showItem.accountType !== CalendarAccountType.CUSTOM_ACCOUNT_TYPE) {
        break;
      }
      showItem.creator = this.accountList[i].creator;
      showItem.id = this.accountList[i].id;
      showItem.accountName = this.accountList[i].accountName;
      showItem.name = this.accountList[i].name;
      showItem.calendarDisplayName = this.accountList[i].calendarDisplayName;
      showItem.calendarColor = this.accountList[i].calendarColor;
      showItem.calendarAccessLevel = this.accountList[i].calendarAccessLevel;
      showItem.visible = this.accountList[i].visible;
      showItem.canReminder = this.accountList[i].canReminder;
      showItem.groupName = this.getGroupName(this.accountList[i], AccountUtils.DEFAULT_ACCOUNT_GROUP);
      newShowAccountList.push(showItem);
    }
    this.showAccountList = newShowAccountList;
  }

  /**
   * 更新帐户列表
   */
  async updateAccountGroupList() {
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
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.systemDataChangedHandler);
  }

  @Builder
  buildAccountDetailPage() {
    Column() {
      ImportAccountDetail({
        isShowAccountDetailPage: $isShowAccountDetailPage
      })
    }
    .height('100%')
  }

  @Builder
  addPersonAccount() {
    Row() {
      Row() {
        Text($r('app.string.custom_account_create'))
          .fontSize($r('sys.float.Body_L'))
          .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
          .fontColor(this.themeColor)
      }
      .width('100%')
      .height(56)
      .borderRadius(12)
      .padding({ top: 4, bottom: 4, left: 12 })
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
    }
    .margin({ top: 12 })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(16)
    .padding({
      top: 4,
      bottom: 4,
      left: 4,
      right: 4
    })
    .onClick((event => {
      this.isShowAccountDetailPage = true;
      ReportUtil.reportBehaviorEvent(behaviorEvents.accountClickGoToCreate);
    }))
    .bindSheet($$this.isShowAccountDetailPage, this.buildAccountDetailPage(), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.CENTER,
      backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
      maskColor: $r('sys.color.ohos_id_color_mask_thin'),
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
      onAppear: () => {
        Log.debug(TAG, 'AccountDetail BindSheet onAppear.');
      },
      onDisappear: () => {
        Log.debug(TAG, 'AccountDetail BindSheet onDisappear.');
      }
    })
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        ForEach(this.accountGroupList, (accountGroup: AccountGroup) => {
          AccountGroupItem({
            groupName: accountGroup.groupName,
            items: accountGroup.items,
            checkedAccId: this.checkedAccId
          })
        })
        this.addPersonAccount()
      }
    }
    .width('100%')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .flexGrow(1)
    .backgroundColor($r('app.color.default_background'))
    .padding({ left: 12, right: 12, bottom: 24 })
    .constraintSize({
      minHeight: '100%'
    })
    .align(Alignment.Top)
  }
}