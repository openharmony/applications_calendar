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
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { ImportData } from './ImportData';
import { SimpleAccount } from './SimpleAccount';
import { ValuesBucket } from '@kit.ArkData';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { CalendarAccountType } from '@app/common/src/main/ets/account/AccountConst';
import { AccountColor } from '@app/common/src/main/ets/account/AccountColor';
import { CalendarService } from '@app/common/src/main/ets/dao/service/CalendarService';
import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { ImportCallBack } from './ImportCallBack';
import { HolidayUtil } from '@app/common/src/main/ets/date/HolidayUtil';
import { CHINA_COUNTRY_CODE } from '@app/common';

/**
 * 导入回调
 *
 */
const TAG = `ImportHolidayCallBack`

export class ImportHolidayCallBack implements ImportCallBack {
  private countryCode: string = 'CN';
  private countryRegion: string = '';
  private callback: Function | undefined;

  public constructor(countryCode: string, countryRegion: string,
                     callback?: Function) {
    this.countryCode = countryCode;
    this.countryRegion = countryRegion;
    this.callback = callback;
  }

  public readonly defaultSaveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void =
    (isSave: boolean, simpleAccount?: SimpleAccount) => {
    };

  save(isSave: boolean, simpleAccount?: SimpleAccount) {
    this.saveAction(isSave, simpleAccount);
    Log.info(TAG, `save isSave ${isSave}`)
  }

  // todo isSave: boolean, simpleAccount?: SimpleAccoun 需要修改
  async onImportParsed(importData: ImportData, saveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void) {

    let accountId = await this.queryHolidayAccount();
    if (accountId === -1) {
      accountId = await this.insertHolidayAccount();
    }
    // todo
    this.saveAction = saveAction;
    const simpleAccount: SimpleAccount = new SimpleAccount(accountId);
    // countryCode 所属国家 判断是否对应的节假日账户存在，不存在就先新建
    this.saveAction(true, simpleAccount);
  }

  async insertHolidayAccount(): Promise<number> {
    const accountCreated: ValuesBucket = {};
    accountCreated[CalendarContract.SyncColumns.ACCOUNT_NAME] = this.countryCode;
    accountCreated[CalendarContract.SyncColumns.ACCOUNT_TYPE] = CalendarAccountType.HOLIDAY_ACCOUNT_TYPE;
    accountCreated[CalendarContract.AccountColumns.CALENDAR_DISPLAY_NAME] = this.getHolidayAccountDisplayName();
    accountCreated[CalendarContract.AccountColumns.CALENDAR_COLOR] = AccountColor.RED;
    accountCreated[CalendarContract.AccountColumns.VISIBLE] = 1;
    accountCreated[CalendarContract.AccountColumns.CAN_REMINDER] = 0;
    const accountId: number = await CalendarService.INSTANCE.insertCalendar(accountCreated) as number;
    return accountId;
  }

  getHolidayAccountDisplayName(): string {
    if (this.countryCode === CHINA_COUNTRY_CODE) {
      return HolidayUtil.getDisplayCountry(this.countryCode);
    }
    return getContext().resourceManager.getStringSync(
      $r('app.string.country_holiday'), HolidayUtil.getDisplayCountry(this.countryCode));
  }

  async queryHolidayAccount(): Promise<number> {
    let accounts: CalendarContract.Accounts[] = await CalendarService
      .INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    for (let count = 0; count < accounts.length; count++) {
      if (this.countryCode === accounts[count].accountName) {
        return accounts[count].id;
      }
    }
    return -1;
  }

  onSaveStart(): void {
    Log.info(TAG, 'On Save Start');
  }

  async onSaveFailed(errorCode: number): Promise<void> {
    this.saveAction = this.defaultSaveAction;
    Log.info(TAG, 'On Save Failed');
    this.updateHolidayState(false);
  }

  onSaveSuccess(): void {
    this.saveAction = this.defaultSaveAction;
    Log.info(TAG, 'On Save Success');
    this.updateHolidayState(true);
  }

  onImportTaskBuild(jobId: number): void {

  }

  onImportStarted(): void {

  }

  onImportFinished(): void {

  }

  async updateHolidayState(state: boolean) {
    PreferencesUtil.putBooleanValueSync('holiday', this.countryCode, state);
    if (this.callback) {
      this.callback(this.countryCode, state);
    }
  }

  async onImportFailed(errorCode: number): Promise<void> {
    this.saveAction = this.defaultSaveAction;
    Log.info(TAG, 'On Import Failed');
    this.updateHolidayState(false);
  }

  onSomeEventsParseFailed(): boolean {
    return false;
  }

  private saveAction: (isSave: boolean, simpleAccount?: SimpleAccount) => void =
    (isSave: boolean, simpleAccount?: SimpleAccount) => {
      Log.info(TAG, `saveAction isSave ${isSave}`)
    }
}