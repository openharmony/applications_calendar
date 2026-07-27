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

import intl from '@ohos.intl';
import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';


const TAG: string = 'DateFormatter';

export class DateFormatter {
  private formatCache: Map<string, intl.DateTimeFormat> = new Map();

  static instance(): DateFormatter {
    return SingleInstanceHelper.createOrGet(DateFormatter, 'DateFormatter');
  }

  format(date: Date, opt: intl.DateTimeOptions, systemLanguage?: string): string | undefined {
    const language: string | undefined = systemLanguage ? systemLanguage : AppStorage.get('language');
    const key: string = language + JSON.stringify(opt);

    if (this.formatCache.has(key)) {
      return this.formatCache.get(key)?.format(date);
    }


    const locale: intl.Locale | undefined = language ? new intl.Locale(language) : undefined;
    if (!locale) {
      return undefined;
    }
    const dateFormat: intl.DateTimeFormat = new intl.DateTimeFormat(locale?.toString(), opt);
    this.formatCache.set(key, dateFormat);
    return dateFormat.format(date);
  }
}