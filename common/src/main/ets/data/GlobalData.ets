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


import { DateUtil } from '../util/DateUtil';
import { PermissionState } from '../default/common/declare';
import { DateManager } from '../date/DateManager';
import { DayData } from '../date/Date';
import { CalendarDate } from '../date/CalendarDate';
import {
  CalendarContract,
  CommonInnerEvent,
  GlobalThis,
  I18nUtil,
  Log,
  SettingPreferencesKeys,
  PreferencesUtil,
  PreferencesFiles,
  CHINESE_HOLIDAY_STATE,
  GlobalDataKeys,
  maskString
} from '../../../../index';
import i18n from '@ohos.i18n';
import { AccountUtils } from '../account/AccountUtils';
import { BigFontSize } from '../constants/BigFontSize';
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'GlobalData';

export type GlobalDataValueType = number | string | Object;

export class GlobalData {
  private static _instance: GlobalData = new GlobalData();
  private bInitialized: boolean = false;

  static instance(): GlobalData {
    if (!GlobalData._instance) {
      GlobalData._instance = new GlobalData();
    }
    return GlobalData._instance;
  }

  init(supportLockTimeZone : boolean = true): void {
    this.initLanguageAndDate(supportLockTimeZone);
    if (this.bInitialized) {
      Log.info(TAG, `GlobalData is initialized`);
      return;
    }
    AppStorage.setOrCreate(GlobalDataKeys.TAB_INDEX, 0);
    const is24HourClock: boolean = i18n.System.is24HourClock();
    AppStorage.setOrCreate(GlobalDataKeys.IS_24_HOUR_CLOCK, is24HourClock);

    AppStorage.setOrCreate(GlobalDataKeys.IS_RECESS_TOGGLE_ON, false);
    AppStorage.setOrCreate(GlobalDataKeys.IS_RECESS_DATA_LOADED, false);
    AppStorage.setOrCreate(GlobalDataKeys.START_OF_WEEK, 0);
    AppStorage.setOrCreate(GlobalDataKeys.WEEKENDS, []);
    AppStorage.setOrCreate(GlobalDataKeys.DEFAULT_REMIND_TIME, 10);
    AppStorage.setOrCreate(GlobalDataKeys.ALL_DAY_EVENTS_DEFAULT_REMIND_TIME, 0);
    AppStorage.setOrCreate(GlobalDataKeys.SETTINGS_HIDDEN_ITEMS, []);
    AppStorage.setOrCreate(GlobalDataKeys.SUBSCRIPTION_CALENDAR, 0);
    AppStorage.setOrCreate(GlobalDataKeys.SHOW_MULTI_DELETE, false);
    AppStorage.setOrCreate(GlobalDataKeys.SYSTEM_REGION, 'CN');
    AppStorage.setOrCreate(GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON, false);
    AppStorage.setOrCreate(GlobalDataKeys.IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW, true);
    AppStorage.setOrCreate(GlobalDataKeys.IS_SHOW_RECOMMENDED_SUBSCRIPTION, true);
    AppStorage.setOrCreate(GlobalDataKeys.CHECK_EVENT_ID, -1);
    AppStorage.setOrCreate(GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR, false);
    AppStorage.setOrCreate(GlobalDataKeys.THEME_COLOR, '#F76045');
    AppStorage.setOrCreate(GlobalDataKeys.LIGHT_THEME_COLOR, '#33F76045');
    AppStorage.setOrCreate(GlobalDataKeys.Dark_THEME_COLOR, '#CCF76045');
    AppStorage.setOrCreate(GlobalDataKeys.BESIDE_THEME_COLOR, '#C0C0C0');
    AppStorage.setOrCreate(GlobalDataKeys.BG_THEME_COLOR, '#1AF76045');
    AppStorage.setOrCreate(GlobalDataKeys.BG_COLOR, '#FFFFFF');
    AppStorage.setOrCreate(GlobalDataKeys.IS_DARKMODE, false);
    AppStorage.setOrCreate(
      GlobalDataKeys.FONT_SIZE_SCALE,
      GlobalThis.getInstance().abilityStageContext?.config.fontSizeScale ?? BigFontSize.BIG_FONT_SIZE_STANDARD
    );
    AppStorage.setOrCreate(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER, false);
    AppStorage.setOrCreate(GlobalDataKeys.IS_NOTIFICATION_GRANTED, false);
    AppStorage.setOrCreate(GlobalDataKeys.IS_NETWORK_AVAILABLE, false);
    AppStorage.setOrCreate(GlobalDataKeys.IS_SLIDE_SLIP_BACK, false);
    // for debug
    Log.debug(TAG, 'Init AppStorage success!');
    this.dataPreferencesInit();
    this.bInitialized = true;
  }

  initLanguageAndDate(needInitDisplayDate: boolean = true, supportLockTimeZone : boolean = true) {
    // i18n初始化
    const language: string = i18n.System.getSystemLanguage();
    AppStorage.setOrCreate(GlobalDataKeys.LANGUAGE, language);
    // 根据时区初始化选中日期以及当前日期
    const initTimeStamp: number = DateUtil.getStartOfDayTimeStamp(undefined, supportLockTimeZone);
    this.set(GlobalDataKeys.CURRENT_DATE, initTimeStamp);
    if (needInitDisplayDate) {
      this.set(GlobalDataKeys.DISPLAY_DATE, initTimeStamp);
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    }
  }

  /**
   * 获取持久化存储初始化值
   * @returns
   */
  async dataPreferencesInit(): Promise<void> {
    this.checkAndSetDefaultValue('IS_CHOOSE_SUBSCRIPTION_CALENDAR', GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR);
    this.checkAndSetDefaultValue('IS_RECESS_TOGGLE_ON', GlobalDataKeys.IS_RECESS_TOGGLE_ON);
    this.checkAndSetDefaultValue('SHOW_WEEK_NUMBER', GlobalDataKeys.IS_SHOW_WEEK_NUM_TOGGLE_ON);
    this.checkAndSetDefaultValue('SHOW_IMPORTANT_DAY', GlobalDataKeys.IS_SHOW_IMPORTANT_DAY_IN_MONTH_VIEW);
    this.checkAndSetDefaultValue('START_OF_WEEK', GlobalDataKeys.START_OF_WEEK);
    this.checkAndSetDefaultValue('DEFAULT_REMIND_TIME', GlobalDataKeys.DEFAULT_REMIND_TIME);
    this.checkAndSetDefaultValue('ALL_DAY_EVENTS_DEFAULT_REMIND_TIME', GlobalDataKeys.ALL_DAY_EVENTS_DEFAULT_REMIND_TIME);
    this.checkAndSetDefaultValue(SettingPreferencesKeys.SHARE_SCHEDULE_POPUPS, GlobalDataKeys.SHARE_SCHEDULE_POPUPS);
    this.checkAndSetDefaultValue(SettingPreferencesKeys.ACCOUNT_SHARE_POPUPS, GlobalDataKeys.ACCOUNT_SHARE_POPUPS);
    this.checkAndSetDefaultValue(CHINESE_HOLIDAY_STATE, GlobalDataKeys.CHINESE_HOLIDAY_STATE);



    if (this.get(GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR)) {
      this.checkAndSetDefaultValue('SUBSCRIPTION_CALENDAR', GlobalDataKeys.SUBSCRIPTION_CALENDAR);
    } else {
      this.set(GlobalDataKeys.SUBSCRIPTION_CALENDAR, I18nUtil.isChineseRegion() ? 0 : -1);
    }

    // 是否第一次打开且未操作过三分栏
    this.checkAndSetPreference(GlobalDataKeys.LAST_OPEN_SIDEBAR)

    if (PreferencesUtil.queryHasSyncBySync(PreferencesFiles.SETTINGS, 'WEEKENDS')) {
      let weekends: object = JSON.parse(PreferencesUtil.getStringValueSync(
        PreferencesFiles.SETTINGS, 'WEEKENDS', '[-1, 0, 6]')) as object;
      AppStorage.setOrCreate(GlobalDataKeys.WEEKENDS, weekends);
      Log.debug(TAG, `get data preferences name: WEEKENDS `);
    }

    // 详情子窗默认配置
    if (PreferencesUtil.queryHasSyncBySync(PreferencesFiles.DEFAULT, GlobalDataKeys.IS_SUB_WINDOW_DETAIL)) {
      AppStorage.setOrCreate(GlobalDataKeys.IS_SUB_WINDOW_DETAIL,
        PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT, GlobalDataKeys.IS_SUB_WINDOW_DETAIL, false));
    }
  }


  // 辅助方法：检查并设置偏好设置
  private checkAndSetPreference(key: string): void {
    if (PreferencesUtil.queryHasSyncBySync(PreferencesFiles.DEFAULT, key)) {
      const value: boolean = PreferencesUtil.getBooleanValueSync(PreferencesFiles.DEFAULT, key, true);
      AppStorage.setOrCreate(key, value);
    }
  }

  /**
   * 判断持久化存储是否存在,有的话覆盖默认初始化值
   * @param storage
   * @param settingKey
   */
  checkAndSetDefaultValue(settingKey: string, globalDataKeys: GlobalDataKeys): void {
    if (PreferencesUtil.queryHasSyncBySync(PreferencesFiles.SETTINGS, settingKey)) {
      const value = PreferencesUtil.getStringValueSync(PreferencesFiles.SETTINGS, settingKey, '');
      AppStorage.setOrCreate(globalDataKeys, value);
      Log.info(TAG, `get data preferences name: ${settingKey}  ${maskString(value?.toString())}`);
    }
  }


  set(key: GlobalDataKeys, value: GlobalDataValueType): void {
    if (!CalendarDate.timeZone) {
      CalendarDate.timeZone = I18nUtil.getSystemTimeZone();
    }
    Log.warn(TAG, `Calendar timeZone : ${CalendarDate.timeZone}`);
    if (key === GlobalDataKeys.DISPLAY_DATE) {
      const dateTime: number = DateUtil.get24HoursStartTime(value as number);
      DateManager.getInstance().selectedDay = DayData.buildByDate(new CalendarDate(dateTime));
      Log.info(TAG,
        `set selectedDay : ${DayData.buildByDate(new CalendarDate(dateTime))
          .toString()}, dateTime: ${dateTime}, value : ${value}`);
      Log.info(TAG,
        `Calendar timeZone : ${CalendarDate.timeZone}, SystemTimeZone : ${I18nUtil.getSystemTimeZone()}`);
      AppStorage.set(key, dateTime);
    } else if (key === GlobalDataKeys.CURRENT_DATE) {
      let dateTime: number = value as number;
      AppStorage.setOrCreate(key, DateUtil.getStartOfDayTimeStamp(dateTime));
    } else {
      Log.info(TAG, `GlobalDataKeys: ${key}, GlobalDataValueType: ${value}`)
      AppStorage.setOrCreate(key, value);
    }
  }

  get(key: GlobalDataKeys): GlobalDataValueType | undefined {
    return AppStorage.get(key);
  }

  // 获取生日账户id，保存到本地
  async setBirthDayAccountId(accounts: CalendarContract.Accounts[]): Promise<void> {
    Log.info(TAG, `setBirthDayAccountId ${accounts?.length}`);
    // 云同步后会有多个联系人账户
    let birthdayCalendarIds: number[] = [];
    for (let index = 0; index < accounts?.length; index++) {
      if (AccountUtils.isBirthDayAccount(accounts[index])) {
        birthdayCalendarIds.push(accounts[index].id);
      }
    }
    let birthdayCalendarId = birthdayCalendarIds.join(',');
    AppStorage.setOrCreate(GlobalDataKeys.BIRTHDAY_ACCOUNT_ID, birthdayCalendarId);
  }

  addHiddenItem(settingKey: string): void {
    let settingsHiddenItems: string[] = this.get(GlobalDataKeys.SETTINGS_HIDDEN_ITEMS) as string[];
    if (!settingsHiddenItems.includes(settingKey)) {
      settingsHiddenItems.push(settingKey);
      this.set(GlobalDataKeys.SETTINGS_HIDDEN_ITEMS, settingsHiddenItems);
      Log.debug(TAG, `add hidden item ${settingKey}`);
    }
  }

  removeHiddenItem(settingKey: string): void {
    let settingsHiddenItems: string[] = this.get(GlobalDataKeys.SETTINGS_HIDDEN_ITEMS) as string[];
    if (settingsHiddenItems.includes(settingKey)) {
      const index = settingsHiddenItems.findIndex((item: string) => (item === settingKey));
      settingsHiddenItems.splice(index, 1);
      this.set(GlobalDataKeys.SETTINGS_HIDDEN_ITEMS, settingsHiddenItems);
      Log.debug(TAG, `remove hidden item ${settingKey}`);
    }
  }

  destroy(): void {
    this.bInitialized = false;
  }
}