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
import { Configuration } from '@ohos.app.ability.Configuration';
import { EmptyUtils } from './EmptyUtils';
import { Log } from '../default/common/Log';
import { emitter } from '@kit.BasicServicesKit';
import { CommonInnerEvent } from '../event/CommonInnerEvent';

const TAG = 'I18nUtil';

/**
 * i18n工具类
 *
 * @since 2022-11-11
 */
export class I18nUtil {
  // 系统区域
  private static systemLocale: string = '';
  // 系统地区
  private static systemRegion: string = '';
  // 系统语言
  private static systemLanguage: string = '';

  /**
   * 设置系统语言
   */
  public static initSelfOnce(): void {
    I18nUtil.setSystemLanguage(i18n.System.getSystemLanguage());
    I18nUtil.setSystemLocale();
    I18nUtil.setSystemRegion();
  }

  /**
   * 返回系统语言
   * 多线程下每个static都是线程独享,并不会内存共用,所有的static都需要先判空
   *
   * @return 系统语言
   */
  static getSystemLanguage(): string {
    if (!I18nUtil.systemLanguage) {
      I18nUtil.setSystemLanguage(i18n.System.getSystemLanguage());
    }
    return I18nUtil.systemLanguage;
  }

  /**
   * 获取系统当前语言下的国家名称
   *
   * @param code 国家码，例如CN
   * @returns 系统当前语言下的国家名称
   */
  static getDisplayCountry(code: string): string {
    let displayCountry: string = '';
    try {
      displayCountry = i18n.System.getDisplayCountry(code, i18n.System.getSystemLanguage());
    } catch (error) {
      Log.logErrorMsg(TAG, 'getDisplayCountry', error);
    }
    return displayCountry;
  }

  /**
   * 设置系统区域
   */
  static setSystemRegion(): void {
    I18nUtil.systemRegion = i18n.System.getSystemRegion();
  }

  /**
   * 返回系统区域
   *
   * @return 系统区域
   */
  static getSystemRegion(): string {
    if (!I18nUtil.systemRegion) {
      I18nUtil.setSystemRegion();
    }
    return I18nUtil.systemRegion;
  }

  static isChineseRegion(): boolean {
    let region = I18nUtil.getSystemRegion();
    return region === 'CN' || region === 'MO' || region === 'HK' || region === 'TW';
  }

  /**
   * 设置系统地区
   */
  static setSystemLocale(): void {
    I18nUtil.systemLocale = i18n.System.getSystemLocale();
  }

  /**
   * 返回系统地区
   *
   * @return 系统地区
   */
  static getSystemLocale(): string {
    if (!I18nUtil.systemLocale) {
      I18nUtil.setSystemLocale();
    }
    return I18nUtil.systemLocale;
  }

  /**
   * 获取日历对象
   *
   * @param locale 地区
   * @param type 日历类型
   */
  static getCalendar(locale: string): i18n.Calendar {
    return i18n.getCalendar(locale);
  }

  /**
   * 判断是否是24小时制
   *
   */
  static is24HourClock(): boolean {
    return i18n.System.is24HourClock();
  }

  /**
   * 获取当前时区
   * @returns
   */
  static getSystemTimeZone(): string {
    return i18n.getTimeZone().getID();
  }

  /**
   * 获取当前时区相对于指定时区的偏移量
   * @timeZoneId 指定时区
   * @returns
   */
  static getTimeZoneOffsetById(timeZoneId: string): number {
    let offset: number = i18n.getTimeZone().getRawOffset(); //当前时区对应的偏移量
    try {
      const oldTimeZone = i18n.getTimeZone(timeZoneId); //获取id对应时区,未获取到时区时会获取到空值
      if (oldTimeZone !== undefined) {
        offset -= oldTimeZone.getRawOffset();
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'getTimeZoneOffsetById', err);
    }
    return offset;
  }

  /**
   * 当配置变化时更新自己的属性
   * @param newConfig
   */
  static updatePropertyOnConfigurationUpdated(newConfig: Configuration): void {
    Log.info(TAG, `updatePropertyOnConfigurationUpdated newConfig.language is ${newConfig.language}`);
    if (EmptyUtils.isEmptyString(newConfig.language)) {
      Log.warn(TAG, `updatePropertyOnConfigurationUpdated newConfig.language is empty`);
      return;
    }
    if (newConfig.language !== I18nUtil.systemLanguage) {
      I18nUtil.setSystemLanguage(newConfig.language as string);
      AppStorage.setOrCreate('language', newConfig.language);
      // 触发语言变更事件
      emitter.emit({ eventId: CommonInnerEvent.SYSTEM_LANGUAGE_CHANGED }, {
        data: {
          language: newConfig.language
        }
      });
    }
  }

  /**
   * 判断某个语言是否为中文语言
   * @param systemLanguage
   * @returns
   */
  static isChineseLanguage(systemLanguage: string): boolean {
    if (!systemLanguage.split('-') || systemLanguage.split('-').length <= 0) {
      return false;
    }
    return systemLanguage.split('-')[0].toLocaleLowerCase() === 'zh';
  }

  /**
   * 判断某个语言是否为英文语言
   * @param systemLanguage
   * @returns
   */
  static isEnglishLanguage(systemLanguage: string): boolean {
    if (!systemLanguage.split('-') || systemLanguage.split('-').length <= 0) {
      return false;
    }
    return systemLanguage.split('-')[0].toLocaleLowerCase() === 'en';
  }

  /**
   * 判断某个语言是否为维语语言
   * @param systemLanguage
   * @returns
   */
  static isUyghurLanguage(systemLanguage: string): boolean {
    if (!systemLanguage.split('-') || systemLanguage.split('-').length <= 0) {
      return false;
    }
    return systemLanguage.split('-')[0].toLocaleLowerCase() === 'ug';
  }

  /**
   * 当前系统是否为中文语言
   * @return
   */
  static isSystemChineseLanguage(): boolean {
    // 设置当前系统语言
    I18nUtil.setSystemLanguage(i18n.System.getSystemLanguage());
    const systemLanguage: string = I18nUtil.getSystemLanguage();
    return I18nUtil.isChineseLanguage(systemLanguage);
  }

  /**
   * 设置系统语言
   */
  private static setSystemLanguage(language: string): void {
    Log.info(TAG, `setSystemLanguage preLanguage is ${I18nUtil.systemLanguage} language is ${language}`);
    I18nUtil.systemLanguage = language;
  }
}
