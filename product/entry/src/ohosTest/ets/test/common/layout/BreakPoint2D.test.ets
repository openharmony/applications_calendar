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
import { BreakPoint2D, BreakPoint2DHelper } from '@app/common/index';

const TAG = 'BreakPoint2DTest';

let testBreakPoints = new Array<BreakPoint2D>();
let testBreakPoint2DHelper = new BreakPoint2DHelper();

export default function BreakPoint2DTest() {
  describe('BreakPoint2DTest', () => {
    beforeEach(() => {
      testBreakPoints = new Array<BreakPoint2D>();
      testBreakPoint2DHelper = new BreakPoint2DHelper();
    });

    it('testBreakPoint2DHelper_without_init', 0, async (done: Function) => {
      let index = testBreakPoint2DHelper.match(0, 0);
      expect(index).assertEqual(-1);
      done()
    })

    it('testBreakPoint2DHelper_duplicate_init', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([{
        width: 100, height: 200
      }]);
      testBreakPoint2DHelper.init([{
        width: 100, height: 200
      }]);
      let index = testBreakPoint2DHelper.match(0, 0);
      expect(index).assertEqual(0);
      done()
    })

    it('BreakPoint2DTest_001', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([{
        width: 100, height: 200
      }]);
      let index = testBreakPoint2DHelper.match(0, 0);
      expect(index).assertEqual(0);
      done()
    })

    // 相同断点,返回第一个匹配的
    it('BreakPoint2DTest_duplicate_bp', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 100, height: 200
        },
        {
          width: 100, height: 200
        }
      ]);
      let index = testBreakPoint2DHelper.match(100, 100);
      expect(index).assertEqual(0);
      done()
    })

    // 相同距离的断点,返回第一个匹配的
    it('BreakPoint2DTest_same_distance', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 100, height: 200
        },
        {
          width: 100, height: 300
        }
      ]);
      let index = testBreakPoint2DHelper.match(100, 250);
      expect(index).assertEqual(0);
      done()
    })

    // 相同距离的断点,返回第一个匹配的
    it('BreakPoint2DTest_same_distance_4', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 100, height: 100
        },
        {
          width: 100, height: 200
        },
        {
          width: 200, height: 100
        },
        {
          width: 200, height: 200
        }
      ]);
      let index = testBreakPoint2DHelper.match(150, 150);
      expect(index).assertEqual(0);
      done()
    })

    it('BreakPoint2DTest_match_001', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 100, height: 100
        },
        {
          width: 100, height: 101
        },
      ]);
      let index = testBreakPoint2DHelper.match(100, 102);
      expect(index).assertEqual(1);
      done()
    })

    it('BreakPoint2DTest_match_002', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 100, height: 100
        },
        {
          width: 100, height: 101
        },
        {
          width: 100, height: 103
        },
      ]);
      let index = testBreakPoint2DHelper.match(100, 102);
      expect(index).assertEqual(1);
      done()
    })


    it('BreakPoint2DTest_match_003', 0, async (done: Function) => {
      testBreakPoint2DHelper.init([
        {
          width: 360, height: 625
        },
        {
          width: 700, height: 670
        },
        {
          width: 670, height: 700
        },
      ]);
      let index = testBreakPoint2DHelper.match(345, 621);
      expect(index).assertEqual(0);
      done()
    })

  })
}