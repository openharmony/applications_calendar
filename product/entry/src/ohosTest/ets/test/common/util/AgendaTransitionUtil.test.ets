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


import { describe, expect, it } from '@ohos/hypium'
import { AgendaEventInfo, AgendaTransitionUtil } from '@app/common/index'
import { TestUtil } from '../../utils/TestUtil'

const TAG = 'Base64UtilTest'

export default function AgendaTransitionUtilTest() {
  describe('coverTest', () => {

    it('coverOpen', 0, async (done: Function) => {
      const agendaUtil: AgendaTransitionUtil =new AgendaTransitionUtil();
      agendaUtil.onCardClicked('testId', false, ()=> {}, () => {});
      expect(agendaUtil.geometryId).assertEqual('testId');
      expect(agendaUtil.isMaskEnabled).assertTrue();
      await TestUtil.sleep(50);
      expect(agendaUtil.geometryId).assertEqual('');
      expect(agendaUtil.isMaskEnabled).assertFalse();
      agendaUtil.onBackClicked(false);
      expect(agendaUtil.geometryId).assertEqual('testId');
      expect(agendaUtil.isMaskEnabled).assertTrue();
      await TestUtil.sleep(50);
      expect(agendaUtil.geometryId).assertEqual('');
      expect(agendaUtil.isMaskEnabled).assertFalse();

      done();
    })

    it('buildAgenda', 0, (done: Function) => {
      const agendaUtil: AgendaTransitionUtil =new AgendaTransitionUtil();
      const info: AgendaEventInfo = new AgendaEventInfo();
      info.mId = 123456;
      agendaUtil.buildEventDetail(info);
      expect(agendaUtil.param.id).assertEqual(123456);
      expect(agendaUtil.isShare).assertFalse();
      done();
    })

  })
}