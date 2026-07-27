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

import i18n from '@ohos.i18n';
import { Log } from '../default/common/Log';
import { EmptyUtils } from './EmptyUtils';
import systemDateTime from '@ohos.systemDateTime';
import { BusinessError } from '@ohos.base';
import { MILLS_PER_MINUTE, MINUTES_PER_HOUR } from './DateUtil';

const TAG = 'TimeZoneUtil';

export const UTC = 'UTC';

export const CHINA_SHANG_HAI = 'Asia/Shanghai';

export const CST = 'CST';

/**
 * 时区工具类
 */

export class TimeZoneUtil {
  /**
   * 通过偏移获取对应的时区id
   * @param offset
   * @returns
   */
  static getTimeZoneIdByOffSet(offset: number): string {
    const availableIDs: string[] = i18n.TimeZone.getAvailableIDs();
    if (EmptyUtils.isEmptyArray(availableIDs)) {
      Log.warn(TAG, `getTimeZoneIdByOffSet availableIDs is Empty`);
      return i18n.getTimeZone().getID();
    }
    for (let timezoneId of availableIDs) {
      const timeZone: i18n.TimeZone = i18n.getTimeZone(timezoneId);
      if (timeZone.getOffset() == offset) {
        Log.info(TAG, `getTimeZoneIdByOffSet hit timezoneId is ${timezoneId}`);
        return timezoneId;
      }
    }
    Log.warn(TAG, `getTimeZoneIdByOffSet availableIDs is Empty`);
    return i18n.getTimeZone().getID();
  }


  /**
   * 当前VCS文件中的TID字段的值是否可有效范围内,不建议根据字符串判断例如"China Standard Time",一个时区
   * 也可能有不同的偏移量特别是夏令时
   */
  static isValidTimezone(timeZoneId: string): boolean {
    const availableIDs: string[] = i18n.TimeZone.getAvailableIDs();
    if (EmptyUtils.isEmptyArray(availableIDs)) {
      Log.warn(TAG, `isVaildTimezone availableIDs is Empty`);
      return false;
    }
    const isValid: boolean = availableIDs.includes(timeZoneId);
    Log.info(TAG, `isValidTimezone timeZoneId ${timeZoneId} isValid is ${isValid}`);
    return isValid;
  }

  /**
   * 获取当前地区的默认时区
   * 不要使用 const currentCalendar: i18n.Calendar = i18n.getCalendar(i18n.System.getSystemLocale())
   * currentCalendar.getTimeZone() 的方式获取,这样获取的是 CST TZ:-06:00
   *
   */
  static getCurrentTimeZone(defaultTimeZone?: string): string {
    let timezone: string = '';
    try {
      timezone = systemDateTime.getTimezoneSync();
    } catch (err) {
      let error = err as BusinessError;
      Log.error(TAG, `Failed to get timezone. message: ${error?.message}, code: ${error?.code}`);
    }
    if (EmptyUtils.isEmptyString(timezone)) {
      timezone = EmptyUtils.isNotEmptyString(defaultTimeZone) ? defaultTimeZone as string : UTC;
    }
    Log.info(TAG, `getCurrentTimeZone timezone is ${timezone}`);
    return timezone;
  }


  static getTimeZoneById(timeZoneId: string): i18n.TimeZone {
    return i18n.getTimeZone(timeZoneId);
  }

  static timeParse(timeFormatStr: string, isIso8601Format?: boolean): number {
    const resultDate: Date = new Date();
    const year: number = Number.parseInt(timeFormatStr.substring(0, 4));
    const month: number = (Number.parseInt(timeFormatStr.substring(4, 6)) + 11) % 12;
    const date: number = Number.parseInt(timeFormatStr.substring(6, 8));
    resultDate.setUTCFullYear(year, month, date);
    if (isIso8601Format || timeFormatStr.indexOf('T') > 0) {
      const hour: number = Number.parseInt(timeFormatStr.substring(9, 11));
      const minute: number = Number.parseInt(timeFormatStr.substring(11, 13));
      const second: number = Number.parseInt(timeFormatStr.substring(13, 15));
      resultDate.setUTCHours(hour, minute, second, 0);
    } else {
      resultDate.setUTCHours(0, 0, 0, 0);
    }
    return resultDate.getTime();
  }

  /**
   * 获取时区偏移量,
   * needRawOffset: 时区的固定偏移量
   * @returns
   */
  static getTimeZoneOffset(timezoneId: string, timeStamp: number, needRawOffset: boolean = false): number {
    const timezone = i18n.getTimeZone(timezoneId);
    return needRawOffset ? timezone.getRawOffset() : timezone.getOffset(timeStamp);
  }

  /**
   * 获取时区的本地化名称
   */
  static getDefaultTimeZoneName(): string {
    return i18n.getTimeZone(TimeZoneUtil.getCurrentTimeZone()).getDisplayName('zh-CN', true);
  }

  /**
   * 获取时区的本地化名称
   */
  static getDefaultTimeZoneOffset(): number {
    const timezoneId = i18n.getTimeZone().getID();
    return TimeZoneUtil.getTimeZoneOffset(timezoneId, Date.now());
  }

  static processTimeZoneOffset(timeZoneOffset: number): string {
    const symbol = timeZoneOffset >= 0 ? '+' : '-';
    const mTimeZoneOffset = Math.abs(timeZoneOffset);
    let hour = Math.floor(mTimeZoneOffset / MINUTES_PER_HOUR);
    let minuteStr = (mTimeZoneOffset % MINUTES_PER_HOUR).toString().padStart(2, '0');
    let timeStr = `${hour.toString()}:${minuteStr}`;
    let offset = `GMT${symbol}${timeStr}`;
    return offset;
  }

  static localizedNameOfTheTimeZone(timeZone: string, language: string) {
    let localizedName: string = '';
    try {
      let timezone = i18n.getTimeZone(timeZone);
      let timeZoneName = timezone.getDisplayName(language, true); // 时区的本地化名称
      let timestamp = Date.now();
      let timeZoneOffset = timezone.getOffset(timestamp) / MILLS_PER_MINUTE;
      let offset = TimeZoneUtil.processTimeZoneOffset(timeZoneOffset);
      localizedName = `${offset} ${timeZoneName}`;
    } catch (err) {
      localizedName = '';
      Log.error(TAG, `localizedNameOfTheTimeZone error is:${err?.code} message is:${err?.message}`);
    }
    return localizedName;
  }
}
