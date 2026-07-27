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

import { getHttpsLinks, hasSameHttpsLinks } from '@app/common/src/main/ets/util/HttpUtils';
import { describe, expect, it } from '@ohos/hypium';


export default function HttpUtilsTest() {
  describe('HttpUtilsTest', () => {
    const text = "啊实打实：http://meeting.dingtalk.com/j/cS97AhM5GKQ武汉江夏";
    const text1 = "https://meeting.dingtalk.com/j/cS97AhM5GKQ武汉江夏";
    const text2 = "武汉江夏:https://meeting.dingtalk.com";
    const text3 = "https://meeting.dingtalk.com\r\n武汉江夏武汉江夏";

    it('test_getHttpsLinks', 0, () => {
      const httpSet = getHttpsLinks(text1);
      expect(httpSet.size).assertEqual(1);
      expect(httpSet.has('https://meeting.dingtalk.com/j/cS97AhM5GKQ')).assertTrue();
    });

    it('test_getHttpsLinks_httpStr', 0, () => {
      expect(getHttpsLinks(text).size).assertEqual(1);
      expect(getHttpsLinks(text).has('http://meeting.dingtalk.com/j/cS97AhM5GKQ')).assertTrue();
    });

    it('test_getHttpsLinks_emptyStr', 0, () => {
      expect(getHttpsLinks('').size).assertEqual(0);
    });

    it('test_hasSameHttpsLinks_area', 0, () => {
      expect(hasSameHttpsLinks(text1, text2)).assertFalse();
    });

    it('test_hasSameHttpsLinks_newLine', 0, () => {
      expect(hasSameHttpsLinks(text2, text3)).assertTrue();
    });
  })
}