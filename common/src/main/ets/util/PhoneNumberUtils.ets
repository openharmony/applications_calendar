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
import { Log } from '../default/common/Log';

const TAG = 'PhoneNumberUtils'

/**
 * 手机号处理工具类
 */
export class PhoneNumberUtils {
  /**
   * 中国各行政区手机号国际码
   * 中国大陆：+86
   * 香港地区:+852
   * 澳门地区:+853
   * 台湾地区:+886
   */
  public static CHINA_INTERNATIONAL_CODES = ['+86', '+852', '+853', '+886'];

  /**
   * 去除手机号中的国家码(暂时仅支持中国地区)
   */
  public static removeInternationalCode(phoneNumber: string): string {
    // 判空
    if (!phoneNumber) {
      return phoneNumber;
    }
    // 不包含国际码
    if (!phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    // 依次判断是否包含各国际码
    for (const code of PhoneNumberUtils.CHINA_INTERNATIONAL_CODES) {
      if (phoneNumber.startsWith(code)) {
        return phoneNumber.substring(code.length);
      }
    }
    // 暂不支持的国际码
    Log.warn(TAG, 'International code not supported currently:' + phoneNumber.substring(0, 3));
    // 如果不是支持的国际码，则默认取手机号后11位
    return phoneNumber.length > 11 ? phoneNumber.substring(phoneNumber.length - 11) : phoneNumber;
  }
}
