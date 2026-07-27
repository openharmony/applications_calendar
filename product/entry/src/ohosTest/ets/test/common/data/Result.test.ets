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

import { ErrorCode, Result } from '@app/common/index';

export default function ResultTest() {
  describe('ResultTest', () => {
    it('testResultCodeMsg', 0, () => {
      let result = new Result(ErrorCode.NO_DB, 'updateCalDevAccountById dsHelper is null', 0);
      expect(result.isSuccess()).assertEqual(false);
      result = Result.copyResult(result, 1);
      expect(result.code === ErrorCode.NO_DB).assertEqual(true);
      expect(result.message === 'updateCalDevAccountById dsHelper is null').assertTrue();
      expect(result.data === 1).assertTrue();
      let stringResult = Result.buildSuccessResult('success');
      expect(stringResult.isSuccess()).assertTrue();
      let undefinedResult = Result.buildByError(new Error('xxxx'));
      expect(undefinedResult.code === ErrorCode.UN_KNOWN).assertTrue();

      let dataResult = Result.buildByErrorWithData(new Error('xxxx'), 10);
      expect(dataResult.data === 10).assertTrue();
    });

  });
}