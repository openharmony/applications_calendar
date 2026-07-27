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

import { GlobalData, GlobalDataKeys } from '@app/common';
import { FestivalJumpUtil } from '@app/feature.agenda/src/main/ets/util/FestivalJumpUtil';
import { describe, expect, it, MockKit, when } from '@ohos/hypium';

export default function FestivalJumpUtilTest() {
  describe('FestivalJumpUtilTest', () => {

    it('shouldShowSubscriptionWebView_1', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(mockfunc)(GlobalDataKeys.IS_NETWORK_AVAILABLE).afterReturn(false);
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView('test', 123456789, true)).assertFalse();
      mocker.clearAll();
      done();
    });

    it('shouldShowSubscriptionWebView_2', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(mockfunc)(GlobalDataKeys.IS_NETWORK_AVAILABLE).afterReturn(true);
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView(undefined, 123456789, false)).assertFalse();
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView('test', 123456789, undefined)).assertFalse();
      mocker.clearAll();
      done();
    });

    it('shouldShowSubscriptionWebView_3', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(mockfunc)(GlobalDataKeys.IS_NETWORK_AVAILABLE).afterReturn(true);
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView('test', 123456789, true)).assertFalse();
      mocker.clearAll();
      done();
    });

    it('shouldShowSubscriptionWebView_4', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(mockfunc)(GlobalDataKeys.IS_NETWORK_AVAILABLE).afterReturn(true);
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView('春节', 123456789, true)).assertFalse();
      mocker.clearAll();
      done();
    });

    it('shouldShowSubscriptionWebView_5', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc: Function = mocker.mockFunc(GlobalData.instance(), GlobalData.instance().get);
      when(mockfunc)(GlobalDataKeys.IS_NETWORK_AVAILABLE).afterReturn(true);
      expect(await FestivalJumpUtil.shouldShowSubscriptionWebView('春节', new Date().getTime(), true)).assertTrue();
      mocker.clearAll();
      done();
    });
  })
}