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
import { beforeAll, beforeEach, describe, it } from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import { Log } from '@app/common/index';

const TAG = 'SingleMonthlyViewModel';
const driver = Driver.create();

export default function SingleMonthlyViewModel() {
  describe('SingleMonthlyViewModel', () => {
    beforeAll(async (done: Function) => {
      Log.info(TAG, `SingleMonthlyViewModel beforeAll`);
      done();
    })

    beforeEach(async (done: Function) => {
      // 点击进入月视图
      Log.info(TAG, `${TAG}click month tab begin`);
      done()
    })
  })
}