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

import { TimeZoneService } from '../interface/TimeZoneService';
import {
  factory,
  ServiceEnum,
  EmptyUtils,
  Log,
  PreferencesFiles,
  PreferencesUtil,
  PreferencesValueType,
  SettingPreferencesKeys,
  Result,
  CalendarCacheService,
  LockTimeZoneInfo,
  CalendarContract,
  TypeUtils,
  CommonInnerEvent,
  I18nUtil,
  GlobalDataKeys,
  EmitterCollector,
  CalendarDate,
  GlobalData,
  MILLS_PER_MINUTE,
  TimeZoneUtil,
  GlobalThis,
  CityTimeZone
} from '@app/common';
import emitter from '@ohos.events.emitter';
import I18n from '@ohos.i18n';
import { reInitGlobalContextInTaskPool, runTaskAsync } from '@app/common/src/main/ets/util/TaskPool';
import { common } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';

const TAG = 'TimeZoneServiceImpl';

enum State {
  NEGATIVE = 0,
  POSITIVE = 1,
}

/*
 * TimeZoneServiceImpl
 */
@factory(ServiceEnum.LOCK_TIME_ZONE_SERVICE)
export class TimeZoneServiceImpl extends TimeZoneService {
  private mLockedTimeZone: string = '';
  private mLockTimeZoneSwitch: boolean = false;
  private emitterCollector: EmitterCollector = new EmitterCollector();
  private timeZoneList: CityTimeZone[] = [];
  private isSupportLockTimeZone: boolean = false;

  constructor() {
    super(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
  }

  protected async doStart(): Promise<void> {
    Log.warn(TAG, `doStart`);
    await this.init();
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED }, this.systemTimeZoneChangeHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.SYSTEM_LANGUAGE_CHANGED }, this.systemLanguageChangeHandler);
  }

  protected async doStop(): Promise<void> {
    Log.warn(TAG, `doStop`);
    this.emitterCollector.off();
  }


  private async init() {
    Log.warn(TAG, `init`);
    await this.queryIsSupportLockTimeZone();
    if (this.isSupportLockTimeZone) {
      await this.loadLockTimeZoneSwitch();
      await this.loadLockedTimeZone();
    }
    await this.queryTimeZoneList();
  }

  private async loadLockedTimeZone() {
    await this.getAndCheckLockedTimeZone();
    Log.info(TAG, `loadLockedTimeZone mLockedTimeZone is ${this.mLockedTimeZone}`);
    this.notifyLockedTimeZoneChange();
  }

  private async getAndCheckLockedTimeZone() {
    let spLockedTimeZone = '';
    let dbLockedTimeZone = '';

    let result = PreferencesUtil.getPreferencesValue(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.LOCKED_TIME_ZONE, '', true, PreferencesValueType.STRING);
    if (result.isSuccess() && EmptyUtils.isStringAndNotEmpty(result.data)) {
      spLockedTimeZone = result.data;
    } else if (result.isSuccess()) {
      Log.warn(TAG, `loadLockedTimeZone Preferences is ${result.data} Empty`);
    } else {
      Log.error(TAG, `loadLockedTimeZone Preferences fail ${result.toString()}`);
    }
    this.mLockedTimeZone = spLockedTimeZone;

    // 检查DB设置项是否一致
    const queryResult = await this.queryLockedTimeZone();
    if (!queryResult.isSuccess()) {
      Log.error(TAG, `loadLockedTimeZone LockedTimeZone in db fail ${queryResult.toString()}`);
      return;
    }
    if (EmptyUtils.isNotEmptyString(queryResult.data)) {
      dbLockedTimeZone = queryResult.data;
    } else {
      Log.warn(TAG, `loadLockedTimeZone LockedTimeZone in db is ${queryResult.data} Empty`);
    }
    this.mLockedTimeZone = dbLockedTimeZone;

    if (dbLockedTimeZone !== spLockedTimeZone) {
      this.saveLockedTimeZoneToPreferences(dbLockedTimeZone);
    }
  }

  private notifyLockedTimeZoneChange(): void {
    AppStorage.setOrCreate(SettingPreferencesKeys.LOCKED_TIME_ZONE, this.mLockedTimeZone);
    emitter.emit({ eventId: CommonInnerEvent.LOCKED_TIME_ZONE_CHANGED });
    this.systemTimeZoneChangeHandler();
  }

  private notifyLockedSwitchChange(): void {
    AppStorage.setOrCreate(SettingPreferencesKeys.IS_TIME_ZONE_LOCKED, this.mLockTimeZoneSwitch);
    emitter.emit({ eventId: CommonInnerEvent.LOCK_TIME_ZONE_SWITCH_CHANGED },
      { data: { 'isTimeZoneLocked': this.mLockTimeZoneSwitch ? 1 : 0 } });
    this.systemTimeZoneChangeHandler();
  }

  private async loadLockTimeZoneSwitch(): Promise<void> {
    await this.getAndCheckLockTimeZoneSwitch();
    Log.info(TAG, `loadLockTimeZoneSwitch mLockTimeZoneSwitch is ${this.mLockTimeZoneSwitch}`);
    this.notifyLockedSwitchChange();
  }

  private async getAndCheckLockTimeZoneSwitch() {
    let spLockTimeZoneSwitch = false;
    let dbLockTimeZoneSwitch = false;

    const lockTimeZoneSwitchResult = PreferencesUtil.getPreferencesValue(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_TIME_ZONE_LOCKED, State.NEGATIVE, true, PreferencesValueType.NUMBER);
    if (lockTimeZoneSwitchResult.isSuccess()) {
      spLockTimeZoneSwitch = this.mapNumberToBoolean(lockTimeZoneSwitchResult.data);
    } else {
      Log.error(TAG, `loadLockTimeZoneSwitch Switch in Preferences fail ${lockTimeZoneSwitchResult.toString()}`);
    }
    this.mLockTimeZoneSwitch = spLockTimeZoneSwitch;

    // 检测DB设置项是否一致
    const queryResult = await this.queryLockTimeZoneSwitch();
    if (!queryResult.isSuccess()) {
      Log.error(TAG, `loadLockTimeZoneSwitch queryLockTimeZoneSwitch error ${queryResult.toString()}`);
      return;
    }
    if (queryResult.data) {
      dbLockTimeZoneSwitch = queryResult.data.isTimeZoneLocked();
    } else {
      Log.info(TAG, `loadLockTimeZoneSwitch queryLockTimeZoneSwitch lockTimeZoneInfo isUndefinedOrNull`);
    }
    this.mLockTimeZoneSwitch = dbLockTimeZoneSwitch;

    if (spLockTimeZoneSwitch !== dbLockTimeZoneSwitch) {
      this.saveLockTimeZoneSwitchToPreferences(dbLockTimeZoneSwitch);
    }
  }

  private async queryLockTimeZoneSwitch(): Promise<Result<LockTimeZoneInfo | undefined>> {
    const result = CalendarCacheService.getInstance().queryLockTimeZoneSwitchInfo();
    return result;
  }

  private async queryLockedTimeZone(): Promise<Result<string>> {
    const result = await CalendarCacheService.getInstance().queryLockedTimeZone();
    if (!result.isSuccess()) {
      Log.error(TAG, `queryLockedTimeZone error ${result.toString()}`);
      return Result.copyResult(result, '');
    }
    const lockTimeZoneInfos = result.data;
    if (lockTimeZoneInfos.length > 1) {
      Log.error(TAG, `queryLockedTimeZone error LockTimeZoneInfo length is ${lockTimeZoneInfos.length} illegal`);
    }
    if (EmptyUtils.isEmptyArray(lockTimeZoneInfos)) {
      Log.info(TAG, `queryLockedTimeZone no LockTimeZoneInfo`);
    }
    return Result.buildSuccessResult(EmptyUtils.isEmptyArray(lockTimeZoneInfos) ? '' : lockTimeZoneInfos[0].value);
  }

  private mapNumberToBoolean(state: State): boolean {
    return state === State.POSITIVE;
  }

  public isTimeZoneLocked(): boolean {
    Log.info(TAG, `isTimeZoneLocked : ${this.mLockTimeZoneSwitch}`);
    return this.mLockTimeZoneSwitch;
  }

  public getLockedTimeZone(): string {
    return this.mLockedTimeZone;
  }

  public getTimeZoneList(): CityTimeZone[] {
    return this.timeZoneList;
  }

  public async updateTimeZoneList(language: string): Promise<boolean> {
    let isUpDateFlag: boolean = await this.queryTimeZoneList(language);
    return isUpDateFlag;
  }

  public getIsSupportLockTimeZone() {
    return this.isSupportLockTimeZone;
  }

  private async queryTimeZoneList(language?: string): Promise<boolean> {
    const currentLanguage = language ? language : I18nUtil.getSystemLanguage();
    const context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `queryTimeZoneList get invalid context`);
      return false;
    }
    let data = await runTaskAsync(queryTimeZoneListTask, context, currentLanguage) as CityTimeZone[];
    Log.info(TAG, `queryTimeZoneList result length is ${data?.length}`);
    if (data.length) {
      this.timeZoneList = data.map(item => new CityTimeZone(item));
      this.timeZoneList.sort((a, b) => a.cityDisplayName.localeCompare(b.cityDisplayName, currentLanguage));
      return true;
    } else {
      return false;
    }
  }

  // 更新锁定时区开关
  public async updateLockTimeZoneSwitch(lockTimeZoneSwitch: boolean): Promise<boolean> {
    Log.info(TAG, `updateLockTimeZoneSwitch lockTimeZoneSwitch is ${lockTimeZoneSwitch}`);
    if (!this.isSupportLockTimeZone) {
      Log.warn(TAG, `not support lock timeZone`);
      return false;
    }
    if (!TypeUtils.isBoolean(lockTimeZoneSwitch)) {
      Log.warn(TAG, `updateLockTimeZoneSwitch lockTimeZoneSwitch ${lockTimeZoneSwitch} not boolean`);
      return false;
    }
    if (this.mLockTimeZoneSwitch === lockTimeZoneSwitch) {
      Log.warn(TAG, `updateLockTimeZoneSwitch lockTimeZoneSwitch ${lockTimeZoneSwitch} no change no need update`);
      return true;
    }
    const saveResult = await this.saveLockTimeZoneSwitch(lockTimeZoneSwitch);
    if (!saveResult) {
      Log.error(TAG, `updateLockTimeZoneSwitch lockTimeZoneSwitch ${lockTimeZoneSwitch} save fail`);
      return false;
    }
    this.mLockTimeZoneSwitch = lockTimeZoneSwitch;
    this.notifyLockedSwitchChange();
    return true;
  }

  public async updateLockedTimeZone(timeZone: string): Promise<boolean> {
    Log.info(TAG, `updateLockedTimeZone timeZone is ${timeZone}`);
    if (!this.isSupportLockTimeZone) {
      Log.warn(TAG, `not support lock timeZone`);
      return false;
    }
    if (EmptyUtils.isNotOrEmptyString(timeZone, true)) {
      Log.warn(TAG, `updateLockedTimeZone timeZone ${timeZone} isNotOrEmptyString`);
      return false;
    }
    if (this.mLockedTimeZone === timeZone) {
      Log.warn(TAG, `updateLockedTimeZone timeZone ${timeZone} no change no need update`);
      return true;
    }
    const saveResult = await this.saveLockedTimeZone(timeZone);
    if (!saveResult) {
      Log.warn(TAG, `updateLockedTimeZone timeZone ${timeZone} save fail`);
      return false;
    }
    this.mLockedTimeZone = timeZone;
    this.notifyLockedTimeZoneChange();
    return true;
  }

  public async refreshSpLockTimeZoneToRemoteDb(): Promise<boolean> {
    //增加克隆时刷新sp到db的容错，重新查询一次isSupportLockTimeZone
    if (!this.isSupportLockTimeZone) {
      await this.queryIsSupportLockTimeZone();
    }
    if (!this.isSupportLockTimeZone) {
      Log.warn(TAG, `not support lock timeZone`);
      return false;
    }
    const mLockTimeZoneSwitch = PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_TIME_ZONE_LOCKED, State.NEGATIVE);
    let mLockTimeZone = PreferencesUtil.getStringValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.LOCKED_TIME_ZONE, '');
    await this.updateLockTimeZoneSwitch(this.mapNumberToBoolean(mLockTimeZoneSwitch));
    if (mLockTimeZone) {
      await this.updateLockedTimeZone(mLockTimeZone);
    }
    return true;
  }

  private async saveLockedTimeZone(lockedTimeZone: string): Promise<boolean> {
    const saveDbResult = await this.saveTimeZoneToRemoteDb(lockedTimeZone);
    if (!saveDbResult.isSuccess()) {
      Log.error(TAG, `saveLockedTimeZone ToRemoteDb fail ${saveDbResult.toString()}`);
      return false;
    }
    const savePreferencesResult = this.saveLockedTimeZoneToPreferences(lockedTimeZone);
    if (!savePreferencesResult) {
      Log.error(TAG, `saveLockedTimeZone ToPreferences fail`);
    }
    return savePreferencesResult;
  }

  private async saveLockTimeZoneSwitch(lockTimeZoneSwitch: boolean): Promise<boolean> {
    const saveDbResult = await this.saveLockTimeZoneSwitchToRemoteDb(lockTimeZoneSwitch);
    if (!saveDbResult.isSuccess()) {
      Log.error(TAG, `saveLockTimeZoneSwitch ToRemoteDb fail ${saveDbResult.toString()}`);
      return false;
    }
    const savePreferencesResult = this.saveLockTimeZoneSwitchToPreferences(lockTimeZoneSwitch);
    if (!savePreferencesResult) {
      Log.error(TAG, `saveLockTimeZoneSwitch ToPreferences fail`);
    }
    return savePreferencesResult;
  }

  private async saveTimeZoneToRemoteDb(lockedTimeZone: string): Promise<Result<boolean>> {
    const queryResult = await CalendarCacheService.getInstance().queryLockedTimeZone();
    if (!queryResult.isSuccess()) {
      Log.error(TAG, `saveTimeZoneToRemoteDb queryLockedTimeZone fail ${queryResult.toString()}`);
      return Result.copyResult(queryResult, false);
    }
    const isNeedInset = EmptyUtils.isEmptyArray(queryResult.data);
    if (isNeedInset) {
      const model = LockTimeZoneInfo.buildLockedTimeZoneInfo(lockedTimeZone);
      const insertResult = await CalendarCacheService.getInstance().insertLockedTimeZone(model);
      Log.info(TAG, `saveTimeZoneToRemoteDb insert ${insertResult.toString()}`);
      return Result.copyResult(insertResult, insertResult.isSuccess());
    } else {
      const model = LockTimeZoneInfo.buildLockedTimeZoneInfo(lockedTimeZone);
      const excludeColumns = [CalendarContract.CalendarCacheColumns.ID];
      const updateResult = await CalendarCacheService.getInstance()
        .updateLockedTimeZone(model, [], excludeColumns);
      Log.info(TAG, `saveTimeZoneToRemoteDb upadte ${updateResult.toString()}`);
      return Result.copyResult(updateResult, updateResult.isSuccess());
    }
  }

  private saveLockedTimeZoneToPreferences(lockedTimeZone: string): boolean {
    return PreferencesUtil.putStringValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.LOCKED_TIME_ZONE, lockedTimeZone);
  }

  private async saveLockTimeZoneSwitchToRemoteDb(lockTimeZoneSwitch: boolean): Promise<Result<boolean>> {
    const queryResult = await CalendarCacheService.getInstance().queryLockTimeZoneSwitchInfo();
    if (!queryResult.isSuccess()) {
      Log.error(TAG, `saveLockTimeZoneSwitchToRemoteDb queryLockedTimeZoneSwitch fail ${queryResult.toString()}`);
      return Result.copyResult(queryResult, false);
    }
    const isNeedInsert = EmptyUtils.isUndefinedOrNull(queryResult.data);
    Log.info(TAG, `saveLockTimeZoneSwitchToRemoteDb isNeedInsert ${isNeedInsert}`);
    try {
      if (isNeedInsert) {
        const model = LockTimeZoneInfo.buildLockTimeZoneSwitchInfo(lockTimeZoneSwitch);
        const insertResult = await CalendarCacheService.getInstance().insertLockTimeZoneSwitchInfo(model);
        Log.info(TAG, `saveLockTimeZoneSwitchToRemoteDb insert ${insertResult.toString()}`);
        return Result.copyResult(insertResult, insertResult.isSuccess());
      } else {
        const model = LockTimeZoneInfo.buildLockTimeZoneSwitchInfo(lockTimeZoneSwitch);
        const excludeColumns = [CalendarContract.CalendarCacheColumns.ID];
        const updateResult = await CalendarCacheService.getInstance()
          .updateLockTimeZoneSwitchInfo(model, [], excludeColumns);
        Log.info(TAG, `saveLockTimeZoneSwitchToRemoteDb update ${updateResult.toString()}`);
        return Result.copyResult(updateResult, updateResult.isSuccess());
      }
    } catch (error) {
      Log.logErrorMsg(TAG, `saveLockTimeZoneSwitchToRemoteDb`, error);
      return Result.buildByErrorWithData(error, false)
    }
  }

  private saveLockTimeZoneSwitchToPreferences(lockTimeZoneSwitch: boolean): boolean {
    const switchState = lockTimeZoneSwitch ? State.POSITIVE : State.NEGATIVE;
    return PreferencesUtil.putNumberValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_TIME_ZONE_LOCKED, switchState);
  }

  // 系统时区变化响应回调
  private systemTimeZoneChangeHandler = (): void => {
    let systemTimeZone = I18nUtil.getSystemTimeZone();
    Log.info(TAG,
      `TimeZone update system:${systemTimeZone}, lock:${this.mLockTimeZoneSwitch}, lockZone:${this.mLockedTimeZone}`);
    const nowTimeZone = this.mLockTimeZoneSwitch ? this.mLockedTimeZone : systemTimeZone;
    this.updateCalendarTimeZone(nowTimeZone);
  }

  // 系统语言变化响应回调
  private systemLanguageChangeHandler = async (): Promise<void> => {
    let systemLanguage = I18nUtil.getSystemLanguage();
    Log.info(TAG,
      `langauge update language:${systemLanguage}`);
    await this.queryTimeZoneList();
  };

  // 更新CalendarDate全局时区，并广播变化
  updateCalendarTimeZone(timeZone: string) {
    if (EmptyUtils.isEmptyString(timeZone)) {
      timeZone = I18nUtil.getSystemTimeZone();
    }
    if (CalendarDate.timeZone === timeZone) {
      return;
    }
    const nowDate: CalendarDate = new CalendarDate(); // 根据当前系统时区获取日期
    Log.info(TAG, `checkDateChange: ${nowDate.toDateString()} ${CalendarDate.timeZone} ${timeZone}`);
    CalendarDate.timeZone = timeZone;
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, nowDate.getTime());
    GlobalData.instance().set(GlobalDataKeys.CURRENT_DATE, nowDate.getTime());
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED });
  }

  async queryIsSupportLockTimeZone(): Promise<void> {
    let isSupport = false;
    try {
      const bundleInfo = await bundleManager.getBundleInfo('com.ohos.calendardata',
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA |
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      let metadataArray = bundleInfo.appInfo.metadataArray.find((array) => {
        return array.moduleName === 'entry';
      });
      if (metadataArray) {
        isSupport = metadataArray.metadata.some((metaItem => {
          return metaItem && metaItem.name === 'hmos.calendardata.lockTimeZone' && metaItem.value === 'true';
        }))
      }
    } catch (error) {
      Log.logErrorMsg(TAG, 'getIsSupportSchedule', error)
      this.isSupportLockTimeZone = false;
    }
    Log.warn(TAG, `calendardata is support lockTimeZone: ${isSupport}`);
    this.isSupportLockTimeZone = isSupport;
  }
}

@Concurrent
async function queryTimeZoneListTask(context: common.UIAbilityContext, language: string): Promise<CityTimeZone[]> {
  // 切线程后GlobalThis失效，是一个全新对象，需要赋予context，否则后续创建dsHelper会失败，导致无法查询数据库
  reInitGlobalContextInTaskPool(context);
  const TAG = 'queryTimeZoneListTask';
  let timeZoneList: CityTimeZone[] = [];
  try {
    let cityIdArray: string[] = I18n.TimeZone.getAvailableZoneCityIDs();
    cityIdArray.forEach((item: string, index: number) => {
      let cityId = cityIdArray[index];
      let timezone = I18n.TimeZone.getTimezoneFromCity(cityId); // 城市Id对应的时区对象
      let cityDisplayName = I18n.TimeZone.getCityDisplayName(cityId, language); // 本地化城市名称
      let timestamp = Date.now();
      let timeZoneOffset = timezone.getOffset(timestamp) / MILLS_PER_MINUTE;
      let offset = TimeZoneUtil.processTimeZoneOffset(timeZoneOffset);
      let city: CityTimeZone = new CityTimeZone();
      city.cityDisplayName = cityDisplayName;
      city.timezoneId = timezone.getID();
      city.offset = offset;
      city.cityId = cityId;
      timeZoneList.push(city);
    })
    return timeZoneList;
  } catch (err) {
    Log.error(TAG, `queryTimeZoneList error is:${err?.code} message is:${err?.message}`)
  }
  return [];
}

