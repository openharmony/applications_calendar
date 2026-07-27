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

import { describe, expect, it } from '@ohos/hypium';
import { canScroll, equalsIgnoreCase, retryUtil } from '@app/common/src/main/ets/util/CommonUtils';


export default function CommonUtilsTest() {
  describe('CommonUtilsTest', () => {
    it('equalsIgnoreCase', 0, () => {
      expect(equalsIgnoreCase('test', 'test')).assertTrue();
      expect(equalsIgnoreCase('test', 'Test')).assertTrue();
      expect(equalsIgnoreCase('Test', 'test')).assertTrue();
      expect(equalsIgnoreCase('1', 'test')).assertFalse();
      expect(equalsIgnoreCase('', 'test')).assertFalse();
    });

    it('canScroll', 0, () => {
        let scroll: boolean = canScroll(7, 1, 300);
        expect(scroll).assertTrue();
    });


    it('retryUtil_SuccessAfterRetries', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error('Simulated error');
        }
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 100);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(3);
    });

    it('retryUtil_FailureAfterMaxRetries', 0, async () => {
      const functionToRetry = () => {
        throw new Error('Simulated error');
      };

      const result = await retryUtil(functionToRetry, 2, 100);
      expect(result).assertUndefined();
    });

    it('retryUtil_SuccessWithCheckFunction', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        return attemptCount === 2 ? 'Success' : 'Fail';
      };

      const checkFunction = (result: string) => result === 'Success';

      const result = await retryUtil(functionToRetry, 2, 100, checkFunction);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(2);
    });

    it('retryUtil_SuccessOnFirstAttempt', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 100);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessOnLastAttempt', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        if (attemptCount < 3) {
          throw new Error('Simulated error');
        }
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 100);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(3);
    });

    it('retryUtil_SuccessWithZeroRetries', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 0, 100);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithImmediateRetry', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        if (attemptCount < 2) {
          throw new Error('Simulated error');
        }
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 2, 0);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(2);
    });

    it('retryUtil_SuccessWithCheckFunction_FailFirstTime', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        return attemptCount === 2 ? 'Success' : 'Fail';
      };

      const checkFunction = (result: string) => result === 'Success';

      const result = await retryUtil(functionToRetry, 2, 100, checkFunction);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(2);
    });

    it('retryUtil_FailureWithCheckFunction', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        return 'Fail';
      };

      const checkFunction = (result: string) => result === 'Success';

      const result = await retryUtil(functionToRetry, 2, 100, checkFunction);
      expect(result).assertUndefined();
      expect(attemptCount).assertEqual(3); // 2 retries + 1 initial attempt
    });

    it('retryUtil_SuccessWithImmediateReturn', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 100);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithMaxRetriesZero', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 0, 100);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithMaxRetriesOne', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        if (attemptCount < 2) {
          throw new Error('Simulated error');
        }
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 1, 100);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(2);
    });

    it('retryUtil_SuccessWithMaxRetriesFive', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        if (attemptCount < 4) {
          throw new Error('Simulated error');
        }
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 5, 100);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(4);
    });

    it('retryUtil_SuccessWithCheckFunction_Delayed', 0, async () => {
      let attemptCount = 0;
      const functionToRetry = () => {
        attemptCount++;
        return attemptCount === 3 ? 'Success' : 'Fail';
      };

      const checkFunction = (result: string) => result === 'Success';

      const result = await retryUtil(functionToRetry, 3, 100, checkFunction);
      expect(result).assertEqual('Success');
      expect(attemptCount).assertEqual(3);
    });

    it('retryUtil_SuccessWithImmediateCheckFunction', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const checkFunction = (result: string) => result === 'Success';

      const result = await retryUtil(functionToRetry, 3, 100, checkFunction);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithNoCheckFunction', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 100);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithNoMaxRetries', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithNoRetryDelay', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry, 3, 0);
      expect(result).assertEqual('Success');
    });

    it('retryUtil_SuccessWithAllParametersDefault', 0, async () => {
      const functionToRetry = () => {
        return 'Success';
      };

      const result = await retryUtil(functionToRetry);
      expect(result).assertEqual('Success');
    });
  })
}