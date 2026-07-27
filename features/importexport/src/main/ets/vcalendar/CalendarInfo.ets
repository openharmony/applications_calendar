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
import HashMap from '@ohos.util.HashMap';

import { CalendarDate, EmptyUtils, Log, TimeZoneUtil, UTC } from '@app/common';
import { VcsComponent, VTIMEZONE } from './import/model/VcsComponent';
import { Property } from './import/model/Property';
import { TIMEZONE, TIMEZONE_ID, TIMEZONE_TZ_DAYLIGHT, TIMEZONE_TZ_OFFSET_TO, TIMEZONE_TZ_STANDARD, VERSION } from './VCalendarConstants';
import LinkedList from '@ohos.util.LinkedList';
import { CustomTime } from '@app/feature.repeatrule';
import { VCalUtils } from './VCalUtils';
import { convertWindowsToIana } from '../util/WindowsToIanaUtils';


/**
 * 文件解析后的日程对象,主要存储了时区和时区偏移量
 *
 */

const TIME_FOMARTE = "yyyyMMdd'T'HHmmssZ";
const TARGET_TIME_FOMARTE = "yyyyMMdd'T'HHmmss";
const TIME_ZONE_UTC = "UTC";
const TIME_OFFSET_UTC = "+0000";

const VCS_VERSION_1_0 = "1.0";

const VCS_TIME_YEAR_STAT = 0;

const VCS_TIME_YEAR_END = 4;

const VCS_TIME_MM_END = 6;

const VCS_TIME_DD_END = 8;

const VCS_TIME_HH_START = 9;

const VCS_TIME_HH_END = 11;

const VCS_TIME_MIN_END = 13;

const VCS_TIME_SS_END = 15;

const NUM_2 = 2;

const TAG = "CalendarInfo";

/**
 * 文件解析后的日程对象,主要存储了时区和时区偏移量
 *
 */
export class CalendarInfo {
  private mTimezone: string = '';
  private mVersion: string = '';
  private mTz: string = '';
  private mTzId: string = '';
  private mTzOffSetTo: string = '';
  private mOffsetValues: Map<string, string> = new Map();
  /**
   * 存放夏令时开始和结束规则
   */
  private mRRules: string[] = ['', ''];

  /**
   * 导出时使用这个方法对timezone和version赋值
   * @param timezone
   * @param version
   */
  constructor(timezone?: string, version?: string) {
    if (EmptyUtils.isNotEmptyString(timezone)) {
      this.mTimezone = timezone as string;
    }
    if (EmptyUtils.isNotEmptyString(version)) {
      this.mVersion = version as string;
    }
  }

  copyInfo(info: CalendarInfo) {
    this.mTimezone = info.mTimezone;
    this.mVersion = info.mVersion;
    this.mTz = info.mTz;
    this.mTzOffSetTo = info.mTzOffSetTo;
    this.mOffsetValues = info.mOffsetValues;
  }

  /**
   * 导入时使用这个方法对timezone和version赋值
   * @param component
   */
  initCalendarInfoByComponent(component: VcsComponent) {
    const property: Property | undefined = component.getFirstProperty(VERSION);
    if (property) {
      this.mVersion = property.getValue();
    }

    // 版本1
    const tzProperty: Property | undefined = component.getFirstProperty(TIMEZONE);
    if (tzProperty) {
      this.mTz = tzProperty.getValue();
    }
    const childComponent = component.getComponents();
    if (EmptyUtils.isNotEmptyArray(childComponent)) {
      for (let i = 0; i < childComponent.length; i++) {
        const subComponent: VcsComponent = childComponent[i];
        if (subComponent && VTIMEZONE == subComponent.getName()) {
          this.setTimezoneFromFiles(subComponent);
          break
        }
      }
    }
    if (EmptyUtils.isEmptyString(this.mTimezone) && EmptyUtils.isEmptyString(this.mTzOffSetTo)) {
      Log.warn(TAG, `initCalendarInfoByComponent mTimezone and mTzOffSetTo both empty`);
      this.mTimezone = TimeZoneUtil.getCurrentTimeZone();
    }

    //todo 获取当前时区例如默认的东八区
    if (VCS_VERSION_1_0 == this.mVersion && !EmptyUtils.isEmptyString(this.mTz)) {
      const currentTimeZone = TimeZoneUtil.getTimeZoneById(TimeZoneUtil.getCurrentTimeZone());
      const utcTimeZone = TimeZoneUtil.getTimeZoneById(UTC);
      // 获取当前时区例如默认的东八区
      const defaultLabel: string = VCalUtils.getTimezoneLabel(currentTimeZone.getID());
      const utcLabel: string = VCalUtils.getTimezoneLabel(utcTimeZone.getID());
      Log.info(TAG, `initCalendarInfoByComponent defaultLabel is ${defaultLabel} utcLabel is ${utcLabel} mTz is ${this.mTz}`);
      if (utcLabel == this.mTz) {
        this.mTimezone = UTC;
      } else if (defaultLabel == this.mTz) {
        this.mTimezone = TimeZoneUtil.getCurrentTimeZone();
      } else {
        this.mTimezone = VCalUtils.getSenderTimezone(this.mTz);
      }
    } else if (EmptyUtils.isEmptyString(this.mTz) && EmptyUtils.isEmptyString(this.mTzId) &&
      !EmptyUtils.isEmptyString(this.mTzOffSetTo)) {
      // 没有TZ，使用VTIMEZONE中的时区偏移量获取时区
      const parseTz = VCalUtils.getSenderTimezone(this.mTzOffSetTo);
      if (TimeZoneUtil.isValidTimezone(parseTz)) {
        this.mTimezone = parseTz;
      } else {
        Log.warn(TAG, `isTimezoneValid parseTz is ${parseTz}`);
      }
    }
    Log.info(TAG, `initCalendarInfoByComponent after init is mTimezone:${this.mTimezone} mVersion:${this.mVersion}}`);
  }

  /**
   * 获取当前日程的时区,如果TZID是无效的则为“”
   *
   * @return 时区 默认值""
   */
  public getTimezone(): string {
    return this.mTimezone;
  }

  /**
   * 获取Timezone的offset
   *
   * @return 时区偏移量 +0800
   */
  public getOffSet(): string {
    return this.mTzOffSetTo;
  }

  /**
   * 获取Tz的标签 +08：00，将：号去掉，获取+0800，因为格式化的需要
   *
   * @return 获取时区偏移的时间缩写 +0800
   */
  public getTz(): string {
    if (this.mTz) {
      return this.mTz.replace(":", "");
    }
    return "";
  }

  /**
   * 当前VCS和ICS的版本号
   *
   * @return 版本号
   */
  public getVersion(): string {
    return this.mVersion;
  }

  /**
   * 解析节点获取时区和偏移量例如东八区 +0800,文件中的TZID有可能是不被识别的需要时区偏移进行计算
   *
   * BEGIN:VTIMEZONE
   * TZID:China Standard Time
   * BEGIN:STANDARD
   * DTSTART:16010101T000000
   * TZOFFSETFROM:+0800
   * TZOFFSETTO:+0800
   * END:STANDARD
   * END:VTIMEZONE
   *
   * @param subComponent vcs components
   */
  private setTimezoneFromFiles(component: VcsComponent) {
    const property: Property | undefined = component.getFirstProperty(TIMEZONE_ID);
    let isTimezoneValid: boolean = true;
    if (property && TIMEZONE_ID == property.getName()) {
      const tz: string = property.getValue();
      isTimezoneValid = TimeZoneUtil.isValidTimezone(tz);
      if (isTimezoneValid) {
        this.mTimezone = tz;
        this.mTzId = tz;
      } else {
        const ianaTz = convertWindowsToIana(tz);
        if (ianaTz) {
          isTimezoneValid = TimeZoneUtil.isValidTimezone(ianaTz);
          if (isTimezoneValid) {
            this.mTimezone = ianaTz;
            this.mTzId = ianaTz;
          }
        }
        Log.warn(TAG, `setTimezoneFromFiles  tz is ${tz} ianaTz is ${ianaTz}`);
      }
    }
    const subComponents = component.getComponents();
    if (EmptyUtils.isEmptyArray(subComponents)) {
      Log.warn(TAG, `setTimezoneFromFiles subComponents is Empty`);
      return;
    }
    for (let component of subComponents) {
      const name: string = component.getName();
      let offset: string = '';
      if (TIMEZONE_TZ_STANDARD == name && !this.mOffsetValues.has(TIMEZONE_TZ_STANDARD)) {
        const names: Set<string> = component.getPropertyNames();
        offset = this.getOffsetValue(component, names);
        this.mOffsetValues.set(TIMEZONE_TZ_STANDARD, offset);
        continue;
      }
      if (TIMEZONE_TZ_DAYLIGHT == name && !this.mOffsetValues.has(TIMEZONE_TZ_DAYLIGHT) && !isTimezoneValid) {
        const names: Set<string> = component.getPropertyNames();
        offset = this.getOffsetValue(component, names);
        this.mOffsetValues.set(TIMEZONE_TZ_DAYLIGHT, offset);
      }
    }
  }

  private getOffsetValue(component: VcsComponent, names: Set<string>): string {
    for (let propertyName of names) {
      const properties = component.getProperties(propertyName);
      if (!properties || EmptyUtils.isEmptyArray(properties)) {
        continue
      }
      for (let property of properties) {
        if (TIMEZONE_TZ_OFFSET_TO == property.getName()) {
          this.mTzOffSetTo = property.getValue();
        }
      }
    }
    return this.mTzOffSetTo;
  }

  /**
   * 比较传入时间是否在夏令时范围内，如果在使用夏令时offset，如果不在使用标准offset
   *
   * @param date 需要计算的时间
   * @param time CustTime
   */
  private setOffSetWithDayLight(date: CalendarDate, time: CustomTime) {

  }
}
