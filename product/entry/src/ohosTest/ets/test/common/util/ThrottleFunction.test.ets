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

import { beforeEach, describe, expect, it } from '@ohos/hypium';

import { ThrottleFunction } from '@app/common/index';
import { TestUtil } from '../../utils/TestUtil';

export default function GlobalDataTest() {
  describe('ThrottleFunctionTest', () => {

    beforeEach(() => {
      ThrottleFunction.instance().reset()
    });

    it('ThrottleFunction_throttle', 0, () => {
      const tag1 = "test1";
      const tag2 = "test2";
      let count = 0;
      const delay = 100;
      ThrottleFunction.instance().throttle(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().throttle(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().throttle(tag2, () => {
        count++
      }, delay);
      expect(count).assertEqual(2);
    });

    it('ThrottleFunction_debounce', 0, async (done: Function) => {
      const tag1 = "test1";
      const tag2 = "test2";
      let count = 0;
      const delay = 50;
      // 第一次运行
      ThrottleFunction.instance().debounce(tag1, () => {
        count++
      }, delay);
      // 第二次运行, 将第一次清除, 重新运行
      ThrottleFunction.instance().debounce(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().debounce(tag2, () => {
        count++
      }, delay);
      // 异步等待执行完成
      await TestUtil.sleep(delay + delay);
      expect(count).assertEqual(2);
      done();
    });

    it('ThrottleFunction_debounceInstant', 0, async (done: Function) => {
      const tag1 = "test1";
      const tag2 = "test2";
      let count = 0;
      const delay = 50;
      ThrottleFunction.instance().debounceInstant(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().debounceInstant(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().debounceInstant(tag1, () => {
        count++
      }, delay);
      ThrottleFunction.instance().debounceInstant(tag2, () => {
        count++
      }, delay);
      // 异步等待执行完成
      await TestUtil.sleep(delay + 50);
      expect(count).assertEqual(3);
      done();
    });

    it('ThrottleQuery', 0, async (done: Function) => {
      let someNumber: number = 0;
      let task = async () => { for (let i = 0; i < 999999; i++) { let j = i; }; someNumber = someNumber + 1; }; // 一个耗时的任务
      let res = ThrottleFunction.instance().throttleQuery('test', async () => { await task() }); // 第一个任务耗时，但是可以启动
      let res1 = ThrottleFunction.instance().throttleQuery('test', async () => { await task() }); // 第二个任务，不应该启动
      setTimeout(() => {
        expect(someNumber).assertEqual(2); // 都完成之后，任务应该都被执行了，someNumber 应该被加了2次
        done();
      }, 2000);
      expect(res).assertTrue();
      expect(res1).assertFalse();
    })
  });
}