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

import { EmptyUtils, Log, MILLS_PER_HOUR, TimeZoneUtil } from '@app/common';

import { Duration } from './import/model/Duration';
import i18n from '@ohos.i18n';


/**
 * hap vcalendar utils
 *
 */

/**
 * 默认的提醒分钟数
 */
const DEFAULT_REMINDER = '10';

/**
 * 全天事件的默认提醒
 */
const DEFAULT_DAY_REMINDER = '0';

/**
 * int默认初始值
 */
const INT_DEFAULT_VALUE = -1;

/**
 * 计算小时的十进制
 */
const DECIMAL_VALUE = 10;

const DAYS_IN_YEAR_PRECEDING_MONTH = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

const TAG = "VCalUtils";

export class VCalUtils {
  /**
   * Method to get dtend using dtstart and duration
   *
   * @param dtstart dtstart
   * @param duration duration
   * @return long
   */
  public static getDtEndFromDuration(dtStart: number, duration: string): number {
    let dTend: number = dtStart;
    const durationParser: Duration = new Duration();
    if (!durationParser.parse(duration)) {
      return -1;
    }
    dTend = durationParser.addTo(dtStart);
    return dTend;
  }


  public static isLocalTime(time: string): boolean {
    let isLocalTime: boolean = false;
    if (EmptyUtils.isEmptyString(time, true)) {
      Log.warn(TAG, `isLocalTime time is ${time}`);
      return false;
    }
    isLocalTime = !(time.trim().endsWith("Z"));
    return isLocalTime;
  }

  public static getTimezoneLabel(timeZoneId: string): string {
    let timeZone: i18n.TimeZone | undefined = TimeZoneUtil.getTimeZoneById(timeZoneId);
    let offset: number = timeZone.getOffset();
    let timeZoneLabel: string = '';
    if (offset < 0) {
      timeZoneLabel += "-";
      offset = (-offset);
    } else {
      timeZoneLabel += "+";
    }
    // 小时取整，去掉分钟：+09.5
    const hour: number = Math.floor(offset / (MILLS_PER_HOUR));
    const minutes: number = (offset % (MILLS_PER_HOUR)) / 60000;
    if (hour < DECIMAL_VALUE) {
      timeZoneLabel += "0" + hour + ":";
    } else {
      timeZoneLabel += hour + ":";
    }
    if (minutes < DECIMAL_VALUE) {
      timeZoneLabel += "0" + minutes;
    } else {
      timeZoneLabel += minutes;
    }
    return timeZoneLabel;
  }

  // todo 通过偏移量获取时区
  public static getSenderTimezone(tzOffset: string): string {
    Log.info(TAG, `getSenderTimezone tzOffset is ${tzOffset}`);
    const offsetMills: number = VCalUtils.getOffsetMillsFromTzValue(tzOffset);
    return TimeZoneUtil.getTimeZoneIdByOffSet(offsetMills);
  }

  /**
   * Method to get the offset time in millis.The time passed as parameter
   * can be GMT[+/-]hh[:]mm format.  例如 TZOFFSETTO:+08:00
   *
   * @param aTzValue - time zone difference between UTC and Sender's local time.
   * @return - returns the offset from UTC in milliseconds
   */
  public static getOffsetMillsFromTzValue(tzOffset: string): number {
    let lLen = tzOffset.length;
    let lCh = '-1';
    let lHrsIndex = 0;
    let lMinIndex = 0;
    let lHour = 0;
    let lMin = 0;
    let lHrMSD = 0;
    let lHrLSD = -1; // Set least significant digit to some invalid value
    let lMinMSD = 0;
    let lMinLSD = -1; // Set least significant digit to some invalid value
    let lSign = '+';
    let lOffsetInMillis = 0;
    for (let lIndex = 0; lIndex < lLen; lIndex++) {
      lCh = tzOffset.charAt(lIndex);
      if ('G' == lCh || 'M' == lCh || 'T' == lCh) {
        continue;
      } else if ('0' <= lCh && '9' >= lCh) {
        if (lHrsIndex < 2) {
          if (lHrsIndex == 0) {
            lHrMSD = Number.parseInt(lCh);
          } else {
            lHrLSD = Number.parseInt(lCh);
          }
          lHrsIndex++;
        } else if (lMinIndex < 2) {
          if (lMinIndex == 0) {
            lMinMSD = Number.parseInt(lCh);
          } else {
            lMinLSD = Number.parseInt(lCh);
          }
          lMinIndex++;
        } else {
          Log.info(TAG, 'no else case lMinIndex:' + lMinIndex);
        }
      } else if (':' == lCh) {
        lHrsIndex = 2; // Setting lHrsIndex to 2 marks the end of hours digit parsing
        continue;
      } else if ('-' == lCh || '+' == lCh) {
        lSign = lCh;
      } else {
        Log.error(TAG, 'Invalid char in tz');
        return lOffsetInMillis;
      }
    }

    if (lHrLSD != -1) {
      lHour = (lHrMSD * 10) + lHrLSD;
    } else {
      lHour = lHrMSD;
    }
    if (lMinLSD != -1) {
      lMin = (lMinMSD * 10) + lMinLSD;
    } else {
      lMin = lMinMSD;
    }

    if ('+' == lSign) {
      lOffsetInMillis = (lHour * 60 * 60 * 1000) + (lMin * 60 * 1000);
    } else {
      lOffsetInMillis = (-1) * ((lHour * 60 * 60 * 1000) + (lMin * 60 * 1000));
    }
    return lOffsetInMillis;
  }


  /**
   * Method to append time parameter "ThhmmssZ" to the time object passed as parameter to this method.
   * CustTime object can come without time field("ThhmmssZ").Trying to prase such an object will throw
   * IllegalArgumentException.To avoid this  "ThhmmssZ" will be appended after "yyyyMMDD".
   *
   * @author S72938
   * @param time - time object in YYYYMMDD format
   * @return - time object in YYYYMMDDTHHMMSSZ where hhmmss value will be 000000.
   */
  public static appendTimeParameter(time: string): string {
    Log.info(TAG, `appendTimeParameter Enter time is ${time}`);
    time = time + "T000000Z";
    Log.info(TAG, `appendTimeParameter Exit time is ${time}`);
    return time;
  }

  /**
   * Method to check whether time parameter is present for the DTSTART, DTEND, COMPLETED fields.
   * Only date can be passed for DTSTART, DTEND,
   * COMPLETED in case of all day event.switchFromUTCToDeviceCurrentTimezone()
   * method will fail due to missing "Thhmmss" fileds.Hence this method will be called
   * before converting DTSTART, DTEND, COMPLETED to UTC.
   *
   * @author S72938
   * @DATE - 11-1-2012
   * @param time - a time object in string format which needs to be checked for time parameter.
   * @return - true if time parameter is present otherwise false.
   */
  public static isTimeParamMissing(time: string): boolean {
    Log.info(TAG, `isTimeParamMissing Enter time is ${time}`);
    /*
     * We assume that aTime will be sent in ISO 8601 which is recommended by vcal 1.0 standard.
     * As per ISO8601 combined date and time should be in the form <date>T<time> where T indicates
     * start of time component.
     */
    return EmptyUtils.isNotEmptyString(time) && time.indexOf('T') == -1;
  }
}
