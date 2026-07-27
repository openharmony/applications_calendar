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

import { beforeAll, describe, expect, it } from '@ohos/hypium'
import { GlobalThis, I18nUtil, Log } from '@app/common/index'
import { TestUtil } from '../../utils/TestUtil'

const TAG = 'I18nUtilTest'

export default function I18nUtilTest() {
  describe('I18nUtilTest', () => {

    beforeAll(() => {
      I18nUtil.initSelfOnce();
    })

    it('I18nUtils_getMessage', 0, (done: Function) => {
      Log.info(TAG, `${TAG} I18nUtils_getMessage begin`);
      expect(I18nUtil.getSystemLanguage()).assertEqual('zh-Hans');
      expect(I18nUtil.getSystemRegion()).assertEqual('CN');
      expect(I18nUtil.getSystemLocale()).assertEqual('zh-Hans-CN');
      expect(I18nUtil.getSystemTimeZone()).assertEqual('Asia/Shanghai');
      expect(I18nUtil.getCalendar('zh-Hans-CN').getTimeZone()).assertEqual('CST');
      expect(I18nUtil.getDisplayCountry('CN')).assertEqual('中国');
      expect(I18nUtil.getDisplayCountry('US')).assertEqual('美国');
      expect(I18nUtil.getDisplayCountry('TEST')).assertEqual('');
      done();
    })

    it('I18nUtils_checkMessage', 0, (done: Function) => {
      Log.info(TAG, `${TAG} I18nUtils_checkMessage begin`);

      TestUtil.setPrivateAttribute(I18nUtil, 'systemRegion', 'HK');
      expect(I18nUtil.isChineseRegion()).assertTrue();
      TestUtil.setPrivateAttribute(I18nUtil, 'systemRegion', 'US');
      expect(I18nUtil.isChineseRegion()).assertFalse();
      TestUtil.setPrivateAttribute(I18nUtil, 'systemRegion', 'CN');
      expect(I18nUtil.isChineseRegion()).assertTrue();
      expect(I18nUtil.is24HourClock()).assertFalse();
      expect(I18nUtil.isSystemChineseLanguage()).assertTrue();
      expect(I18nUtil.isChineseLanguage('zh-Hans-CN')).assertTrue();
      expect(I18nUtil.isChineseLanguage('en-Latn-CN')).assertFalse();
      expect(I18nUtil.isEnglishLanguage('en-Latn-CN')).assertTrue();
      expect(I18nUtil.isEnglishLanguage('zh-Hans-CN')).assertFalse();
      expect(I18nUtil.isUyghurLanguage('ug-CN')).assertTrue();
      expect(I18nUtil.isUyghurLanguage('zh-Hans-CN')).assertFalse();

      done();
    })

    it('I18nUtils_updateConfiguration', 0, (done: Function) => {
      Log.info(TAG, `${TAG} I18nUtils_updateConfiguration begin`);
      const newConfig = GlobalThis.getInstance().context!.config;
      newConfig.language = 'en-US';
      I18nUtil.updatePropertyOnConfigurationUpdated(newConfig);
      expect(I18nUtil.getSystemLanguage()).assertEqual('en-US');

      newConfig.language = '';
      I18nUtil.updatePropertyOnConfigurationUpdated(newConfig);
      expect(I18nUtil.getSystemLanguage()).assertEqual('en-US');

      newConfig.language = 'zh-Hans-CN';
      I18nUtil.updatePropertyOnConfigurationUpdated(newConfig);
      expect(I18nUtil.getSystemLanguage()).assertEqual('zh-Hans-CN');

      newConfig.language = 'zh-Hans-CN';
      I18nUtil.updatePropertyOnConfigurationUpdated(newConfig);
      expect(I18nUtil.getSystemLanguage()).assertEqual('zh-Hans-CN');
      done();
    })

    it('I18nUtils_getTimeZone', 0, (done: Function) => {
      Log.info(TAG, `${TAG} I18nUtils_getTimeZone begin`);
      expect(I18nUtil.getTimeZoneOffsetById('Asia/Shanghai')).assertEqual(0);
      expect(I18nUtil.getTimeZoneOffsetById('UTC')).assertEqual(28800000);
      expect(I18nUtil.getTimeZoneOffsetById('zh-Hans-CN')).assertEqual(28800000);
      expect(I18nUtil.getTimeZoneOffsetById('America/New_York')).assertEqual(46800000);
      done();
    })
  })
}