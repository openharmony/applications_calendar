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

import { CalendarContract } from '../default/calendar/CalendarContract';
import { CalendarAccountType } from './AccountConst';
import { AccountColor, ALL_ACCOUNT_COLOR, EmuiAccountColor, oldAccountColorList } from './AccountColor';
import { Log } from '../default/common/Log';
import LightWeightMap from '@ohos.util.LightWeightMap';
import { Pair } from '../default/util/preferences_util/PreferencesUtil';
import { GlobalData } from '../data/GlobalData';
import { CalendarService } from '../dao/service/CalendarService';
import { GlobalDataKeys } from '../data/GlobalDataKeys';
import { ValuesBucket } from '@kit.ArkData';

/**
 * 帐户列表使用到的一些工具方法
 *
 */
const TAG = 'AccountUtils';

const keys: string[] = [
  CalendarAccountType.LOCAL_ACCOUNT_TYPE,
  CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE,
  CalendarAccountType.CUSTOM_ACCOUNT_TYPE
];

const CONTACT_BIRTHDAY_BUNDLE_NAME = 'com.ohos.contactsdataability';
const CONTACT_BIRTHDAY_BUNDLE_NAME_2 = 'com.ohos.contacts';

export class AccountUtils {
  public static DEFAULT_ACCOUNT_GROUP: string = 'defaultAccountGroup';
  public static WELINK_ACCOUNT_CREATOR_OLD: string = 'com.openharmony.it.works';
  public static WELINK_ACCOUNT_CREATOR: string = 'com.openharmony.it.welink';
  public static CALENDAR_DATA_ACCOUNT_CREATOR: string = 'com.ohos.calendardata';
  public static CALENDAR_ACCOUNT_CREATOR: string = 'com.ohos.calendar';
  private static sColorResMap: LightWeightMap<Resource, number[]> | null;
  private static sColorValueMap: LightWeightMap<number, number[]> | null;
  private static accountColorMap: LightWeightMap<number, number> | null;
  private static accountStringMap: Map<string, Resource> = new Map<string, Resource>([
    [AccountUtils.DEFAULT_ACCOUNT_GROUP, $r('app.string.local_calendar')],
    ['Phone', $r('app.string.my_calendar')]
  ]);

  /**
   * exchange 邮箱有多个，每个按照邮箱分类 群组名就是这个账号的accountName，分类下的item取名把邮箱后缀去掉
   * 其他不能识别三方账户（包括华为视屏） 都归类到 应用日程 分类下的item取名 取数据库displayName
   * 分组排序规则： 华为账号,welink,caldav,应用日程,exchange类型的账号
   * 华为账号下的item排序 1.'local' 'com.openharmony.birthday'  2.'com.openharmony.custom' 3.'others'
   * 按照帐户 type，对帐户数组进行排序，顺序如下
   *
   * @param 帐户数组
   * @return 排序后的帐户数组
   */
  static sortAccountListInAccPage(accountList: CalendarContract.Accounts[]): CalendarContract.Accounts[] {
    return accountList.sort((a: CalendarContract.Accounts, b: CalendarContract.Accounts) => {
      const openharmonySortResult: Pair<number, boolean> = AccountUtils.openharmonySort(a, b);
      if (openharmonySortResult.getSecond()) {
        return openharmonySortResult.getFirst();
      }
      const weLinkSortResult: Pair<number, boolean> = AccountUtils.weLinkSort(a, b);
      if (weLinkSortResult.getSecond()) {
        return weLinkSortResult.getFirst();
      }

      const thirdAppSortResult: Pair<number, boolean> = AccountUtils.thirdAppSort(a, b);
      if (thirdAppSortResult.getSecond()) {
        return thirdAppSortResult.getFirst();
      }
      return 0;
    });
  }

  /**
   * 按照帐户 type，对帐户数组进行排序，顺序如下
   * 1.'local'
   * 2.'com.openharmony.custom'
   * 3.'others'
   *
   * @param 帐户数组
   * @return 排序后的帐户数组
   */
  static sortAccountListInAccPopup(accountList: CalendarContract.Accounts[]): CalendarContract.Accounts[] {
    const keys: string[] = [
      CalendarAccountType.LOCAL_ACCOUNT_TYPE,
      CalendarAccountType.CUSTOM_ACCOUNT_TYPE
    ];
    return accountList.sort((a: CalendarContract.Accounts, b: CalendarContract.Accounts) => {
      const aIndex: number = keys.indexOf(a.accountType);
      const bIndex: number = keys.indexOf(b.accountType);

      if (aIndex === -1 && bIndex !== -1) {
        return 1;
      }

      if (aIndex !== -1 && bIndex === -1) {
        return -1;
      }

      if (aIndex === -1 && bIndex === -1) {
        return 0;
      }

      return aIndex - bIndex;
    });
  }

  static isDefaultAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.LOCAL_ACCOUNT_TYPE === calendarAccount.accountType &&
      AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR === calendarAccount.creator;
  }

  static isCustomAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.CUSTOM_ACCOUNT_TYPE === calendarAccount.accountType &&
      (AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR === calendarAccount.creator ||
        AccountUtils.CALENDAR_ACCOUNT_CREATOR === calendarAccount.creator);
  }

  static isWeLinkAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return calendarAccount.accountType === CalendarAccountType.EMAIL_ACCOUNT_TYPE &&
      (calendarAccount.creator === AccountUtils.WELINK_ACCOUNT_CREATOR_OLD ||
        calendarAccount.creator === AccountUtils.WELINK_ACCOUNT_CREATOR);
  }

  static isExchangeAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.OpenHarmony_EXCHANGE_ACCOUNT_TYPE === calendarAccount.accountType;
  }

  static isHolidayAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.HOLIDAY_ACCOUNT_TYPE === calendarAccount.accountType;
  }

  static isDefaultBirthDayAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.BIRTHDAY_ACCOUNT_TYPE === calendarAccount.accountType;
  }

  static isThirdAppAccount(calendarAccount: CalendarContract.Accounts) {
    if (AccountUtils.isDefaultAccount(calendarAccount)) {
      return false;
    }
    if (AccountUtils.isCustomAccount(calendarAccount)) {
      return false;
    }
    if (AccountUtils.isWeLinkAccount(calendarAccount)) {
      return false;
    }
    if (AccountUtils.isExchangeAccount(calendarAccount)) {
      return false;
    }
    return true;
  }

  /**
   * 通过Accounts获取是否为联系人账户
   * @return isConcat 是否为联系人账户
   */
  static isConcatAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return (calendarAccount.accountName === CONTACT_BIRTHDAY_BUNDLE_NAME ||
      calendarAccount.accountName === CONTACT_BIRTHDAY_BUNDLE_NAME_2) &&
      calendarAccount.accountType === CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE;
  }

  /**
   * 通过Accounts获取是否为生日日程
   * @return isBirthDay 需要兼容双框架同步过来的生日日程
   */
  static isBirthDayAccount(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE === calendarAccount.accountType ||
      CalendarAccountType.DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE === calendarAccount.accountType;
  }

  /**
   * 通过Accounts获取是否为生日日程
   * @return isBirthDay 判断双同步的生日日程
   */
  static isBirthDayAccountDouble(calendarAccount: CalendarContract.Accounts) {
    if (!calendarAccount) {
      Log.error(TAG, `account is null`);
      return false;
    }
    return CalendarAccountType.DOUBLE_SIDE_BIRTHDAY_ACCOUNT_TYPE === calendarAccount.accountType;
  }

  /**
   * 通过calendarId获取是否为生日日程
   * @return isBirthDay
   */
  static isBirthDayAccountById(calendarId: number): boolean {
    const account = GlobalData.instance().get(GlobalDataKeys.BIRTHDAY_ACCOUNT_ID);
    let isBirthDay: boolean = false;
    if (typeof account === 'string') {
      let accounts: string[] = account.split(',');
      isBirthDay = accounts.some((item) => item === calendarId.toString());
    }
    return isBirthDay;
  }

  // 检查是否是联系人生日账户，同时检查globalData中是否设置了联系人生日账户
  // 确保不会因为联系人生日账户刚创建，还没有导入到globalData中，导致返回错误
  static async isBirthDayAccountByIdAsync(calendarId: number) {
    Log.info(TAG, `isBirthDayAccountByIdAsync`);
    let account = GlobalData.instance().get(GlobalDataKeys.BIRTHDAY_ACCOUNT_ID);
    if (account == undefined) {
      // 全局还未设置生日账户，重新设置一次
      Log.info(TAG, `isBirthDayAccountByIdAsync account not set`);
      let accounts = await CalendarService.INSTANCE.queryCalendarList();
      await GlobalData.instance().setBirthDayAccountId(accounts);
      account = GlobalData.instance().get(GlobalDataKeys.BIRTHDAY_ACCOUNT_ID);
    }
    let isBirthDay: boolean = false;
    if (typeof account === 'string') {
      let accounts: string[] = account.split(',');
      isBirthDay = accounts.some((item) => item === calendarId.toString());
    }
    return isBirthDay;
  }

  /**
   * 更新帐户显隐
   */
  static async updateAccountVisible(accountId: number, visible: boolean) {
    let accountUpdate: ValuesBucket = {};
    accountUpdate[CalendarContract.AccountColumns.VISIBLE] = visible;
    await CalendarService.INSTANCE.updateCalendarById(accountId, accountUpdate);
  }

  /**
   * 获取账户颜色值,双框架的
   * @return 颜色与名称的对照 map
   */
  static getAccountColorName(calendarColor: number): Resource {
    const colorMap: LightWeightMap<Resource, number[]> = AccountUtils.getColorResMap();
    for (let i = 0; i < colorMap.length; i++) {
      const key: Resource = colorMap.getKeyAt(i);
      const colors: number[] = colorMap.get(key);
      for (let colorsElement of colors) {
        if (AccountUtils.checkIsSameColor(colorsElement, calendarColor)) {
          return key;
        }
      }
    }
    Log.warn(TAG, `getAccountColorName calendarColor is ${calendarColor} no any match`);
    return $r('app.string.accessibility_account_color_other');
  }

  /**
   * 获取账户颜色值
   * @return 颜色与名称的对照 map
   */
  static getAdaptedAccountColorValue(calendarColor: number): number {
    const colorMap: LightWeightMap<number, number[]> = AccountUtils.getColorValueMap();
    for (let i = 0; i < colorMap.length; i++) {
      const key: number = colorMap.getKeyAt(i);
      const colors: number[] = colorMap.get(key);
      for (let colorsElement of colors) {
        if (AccountUtils.checkIsSameColor(colorsElement, calendarColor)) {
          return key;
        }
      }
    }
    Log.warn(TAG, `getAdaptedAccountColorValue calendarColor is ${calendarColor} no any match`);
    return calendarColor;
  }

  /**
   * 账户颜色值是否在配置里
   * @return 账户颜色值是否在配置里
   */
  static isNotInCalendarColors(calendarColor: number): boolean {
    for (let accountColor of ALL_ACCOUNT_COLOR) {
      if (AccountUtils.checkIsSameColor(accountColor, calendarColor)) {
        return false;
      }
    }
    return true;
  }

  static getAccountResourceMap() {
    return AccountUtils.accountStringMap;
  }

  /**
   * 判断如果是默认账户且名称为‘Phone’则替换
   * @param account
   * @returns
   */
  static getAccountResourceStr(account: CalendarContract.Accounts): ResourceStr {
    if (AccountUtils.isDefaultAccount(account) && account.calendarDisplayName === 'Phone') {
      return AccountUtils.getAccountResourceMap().get(account.calendarDisplayName) as Resource;
    } else {
      return account.calendarDisplayName;
    }
  }

  /**
   * 将负数十进制颜色转化为十六进制颜色
   *
   * @param sourceColor 负数十进制颜色
   */
  static HexColor(sourceColor: number): string {
    const colorString = (sourceColor & 0xFFFFFF).toString(16);
    return colorString.padStart(6, '0');
  }

  /**
   * 校验是否为同色,无论值为正负
   * @param color1
   * @param color2
   */
  static checkIsSameColor(color1: number, color2: number): boolean {
    const hexColor1 = AccountUtils.HexColor(color1);
    const hexColor2 = AccountUtils.HexColor(color2);
    return hexColor1 === hexColor2;
  }

  private static openharmonySort(a: CalendarContract.Accounts, b: CalendarContract.Accounts): Pair<number, boolean> {
    const aIndex: number = keys.indexOf(a.accountType);
    const bIndex: number = keys.indexOf(b.accountType);

    if (aIndex === -1 && bIndex !== -1) {
      return new Pair(1, true);
    }
    if (aIndex !== -1 && bIndex === -1) {
      return new Pair(-1, true);
    }
    if (aIndex === -1 && bIndex === -1) {
      return new Pair(0, false);
    }
    return new Pair(aIndex - bIndex, true)
  }

  private static weLinkSort(a: CalendarContract.Accounts, b: CalendarContract.Accounts): Pair<number, boolean> {

    if (AccountUtils.isWeLinkAccount(a) && !AccountUtils.isWeLinkAccount(b)) {
      return new Pair(-1, true);
    }
    if (!AccountUtils.isWeLinkAccount(a) && AccountUtils.isWeLinkAccount(b)) {
      return new Pair(1, true);
    }
    if (AccountUtils.isWeLinkAccount(a) && AccountUtils.isWeLinkAccount(b)) {
      return new Pair(0, true);
    }
    return new Pair(0, false)
  }

  private static thirdAppSort(a: CalendarContract.Accounts, b: CalendarContract.Accounts): Pair<number, boolean> {

    if (AccountUtils.isThirdAppAccount(a) && !AccountUtils.isThirdAppAccount(b)) {
      return new Pair(-1, true);
    }
    if (!AccountUtils.isThirdAppAccount(a) && AccountUtils.isThirdAppAccount(b)) {
      return new Pair(1, true);
    }
    if (AccountUtils.isThirdAppAccount(a) && AccountUtils.isThirdAppAccount(b)) {
      return new Pair(0, true);
    }
    return new Pair(0, false)
  }

  /**
   * 获取颜色名称 map
   * @return 颜色与名称的对照 map
   */
  private static getColorResMap(): LightWeightMap<Resource, number[]> {
    if (AccountUtils.sColorResMap) {
      return AccountUtils.sColorResMap;
    }
    AccountUtils.sColorResMap = new LightWeightMap<Resource, number[]>();
    let colorMap: LightWeightMap<Resource, number[]> = AccountUtils.sColorResMap;
    colorMap.set($r('app.string.accessibility_account_color_vermilion'), [AccountColor.RED, EmuiAccountColor.RED])
    colorMap.set($r('app.string.accessibility_account_color_tangerine'), [AccountColor.DARK_ORANGE, EmuiAccountColor.DARK_ORANGE])
    colorMap.set($r('app.string.accessibility_account_color_aubergine'), [AccountColor.LIGHT_ORANGE, EmuiAccountColor.LIGHT_ORANGE])
    colorMap.set($r('app.string.accessibility_account_color_verdure'), [AccountColor.GREEN, EmuiAccountColor.GREEN])
    colorMap.set($r('app.string.accessibility_account_color_verdant'), [AccountColor.TURQUOISE, EmuiAccountColor.TURQUOISE])
    colorMap.set($r('app.string.accessibility_account_color_purplish'), [AccountColor.PURPLE, EmuiAccountColor.PURPLE])
    colorMap.set($r('app.string.accessibility_account_color_indigo'), [AccountColor.BLUE, EmuiAccountColor.BLUE])
    return colorMap;
  }

  /**
   * 获取颜色名称 map
   * @return 颜色与名称的对照 map
   */
  private static getColorValueMap(): LightWeightMap<number, number[]> {
    if (AccountUtils.sColorValueMap) {
      return AccountUtils.sColorValueMap;
    }
    AccountUtils.sColorValueMap = new LightWeightMap<number, number[]>();
    let colorMap: LightWeightMap<number, number[]> = AccountUtils.sColorValueMap;
    colorMap.set(AccountColor.RED, [AccountColor.RED, EmuiAccountColor.RED])
    colorMap.set(AccountColor.DARK_ORANGE, [AccountColor.DARK_ORANGE, EmuiAccountColor.DARK_ORANGE])
    colorMap.set(AccountColor.LIGHT_ORANGE, [AccountColor.LIGHT_ORANGE, EmuiAccountColor.LIGHT_ORANGE])
    colorMap.set(AccountColor.GREEN, [AccountColor.GREEN, EmuiAccountColor.GREEN])
    colorMap.set(AccountColor.TURQUOISE, [AccountColor.TURQUOISE, EmuiAccountColor.TURQUOISE])
    colorMap.set(AccountColor.PURPLE, [AccountColor.PURPLE, EmuiAccountColor.PURPLE])
    colorMap.set(AccountColor.BLUE, [AccountColor.BLUE, EmuiAccountColor.BLUE])
    return colorMap;
  }

  /**
   * 获取旧账户对应的颜色值
   * @return 颜色与名称的对照 map
   */
  static getOldAccountMapNowAccount(calendarColor: number): number {
    const oldColorMap: LightWeightMap<number, number> = AccountUtils.getOldColorMap();
    const defaultColor = AccountColor.RED;
    // 兼容负数颜色值和正数颜色值
    const allColor = ALL_ACCOUNT_COLOR.reduce((a: number[], c: number) => a.concat([c, c & 0xFFFFFF]), []);
    const newColor = allColor.includes(calendarColor) ? calendarColor : defaultColor;
    Log.info(TAG, `getOldAccountMapNowAccount,` +
      `${calendarColor}/${oldColorMap.get(calendarColor)}/${allColor.includes(calendarColor)}`);

    return oldColorMap.hasKey(calendarColor) ? oldColorMap.get(calendarColor) : newColor;
  }

  /**
   * 获取旧颜色映射 map
   * @return 旧颜色与现颜色的映射 map
   */
  private static getOldColorMap(): LightWeightMap<number, number> {
    if (AccountUtils.accountColorMap) {
      return AccountUtils.accountColorMap;
    }
    AccountUtils.accountColorMap = new LightWeightMap<number, number>();
    const oldColorMap: LightWeightMap<number, number> = AccountUtils.accountColorMap;
    for (const colorMap of oldAccountColorList) {
      oldColorMap.set(colorMap.oldAccountColor, colorMap.nowAccountColor);
      oldColorMap.set(colorMap.oldAccountColor & 0xFFFFFF, colorMap.nowAccountColor); // 进行正数转换
    }
    return oldColorMap;
  }
}