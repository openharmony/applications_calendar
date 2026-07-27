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
import { intl } from '@kit.LocalizationKit';
import { I18nUtil } from '../I18nUtil';
import { HashMap } from '@kit.ArkTS';
import { Log } from '../../default/common/Log';

const TAG: string = `NumberFormatManager`;

/**
 * NumberFormatManager
 * 用于特殊语言下的数字转译
 */
export class NumberFormatManager {
  private static _instance: NumberFormatManager = new NumberFormatManager();
  public static instance(): NumberFormatManager {
    return NumberFormatManager._instance;
  }
  public _numberFormat: intl.NumberFormat;

  private _language : string = ''
  constructor() {
    this._language = I18nUtil.getSystemLanguage();
    this._numberFormat = this.getNumberFormat(this._language);
  }

  public onLanguageChange(language : string) {
    if (this._language === language) {
      return;
    }
    this._language = language;
    this._numberFormat = this.getNumberFormat(language);
    this._numberFormatCache.clear();
  }

  private getNumberFormat(language : string) : intl.NumberFormat {
    let numberOptions: intl.NumberOptions = {};
    numberOptions.style = 'decimal'
    if (language.includes('ar')) {
      numberOptions.numberingSystem = 'arab'
    }
    return new intl.NumberFormat('zh-Hans-AE', numberOptions);
  }

  private _numberFormatCache : HashMap<number, string> = new HashMap<number, string>()

  public numberFormat(number :number) {
    if (this._numberFormatCache.hasKey(number)) {
      return this._numberFormatCache.get(number);
    }
    const formatNumber = this._numberFormat.format(number);
    this._numberFormatCache.set(number, formatNumber);
    Log.debug(TAG, `_numberFormatCache length:${this._numberFormatCache.length}`);
    return formatNumber;
  }
}


