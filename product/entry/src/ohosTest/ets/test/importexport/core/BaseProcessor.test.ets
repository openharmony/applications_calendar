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
import { BaseProcessor, TaskState } from '@app/feature.importexport/src/main/ets/core/BaseProcessor';
import { describe, expect, it } from '@ohos/hypium';
import hilog from '@ohos.hilog';

const TAG: string = 'BaseProcessorTest';

class ProcessorTest extends BaseProcessor {
  public async run(): Promise<boolean> {
    return await new Promise((resolve: Function) => {
      hilog.info(0x000, TAG, 'run');
      resolve(true);
    });
  }

  public getType(): number {
    hilog.info(0x000, TAG, 'getType');
    return 1;
  }

  public isImportType(): boolean {
    hilog.info(0x000, TAG, 'isImportType');
    return true;
  }

  public isSupportCancel(): boolean {
    return false;
  }
}

export default function BaseProcessorTest() {
  describe('BaseProcessorTest', () => {

    it('run', 0, async () => {
      let processor = new ProcessorTest();
      expect(await processor.run()).assertEqual(true);
    });

    it('cancel', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.cancel(true)).assertEqual(false);
    });

    it('isAfterState', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.isAfterState(TaskState.STATE_WAITING)).assertEqual(false);
    });

    it('isAtLeastState', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.isAtLeastState(TaskState.STATE_WAITING)).assertEqual(true);
    });

    it('getJobId', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.getJobId()).assertEqual(0);
    });

    it('isCanDoOtherTask', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.isCanDoOtherTask()).assertEqual(true);
    });

    it('getType', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.getType()).assertEqual(1);
    });

    it('isImportType', 0, () => {
      let processor = new ProcessorTest();
      expect(processor.isImportType()).assertEqual(true);
    });
  })
}