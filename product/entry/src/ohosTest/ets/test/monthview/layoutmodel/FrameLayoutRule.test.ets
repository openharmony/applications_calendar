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
import { Env, LayoutProp } from '@app/common/index';
import { FrameLayout, FrameLayoutRule } from '@app/feature.monthview/src/main/ets/layoutmodel/FrameLayoutRule';
import { MonthViewLayoutEnv } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutEnv';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';


export default function FrameLayoutRuleTest() {
  describe('FrameLayoutRuleTest', () => {
    let rule: FrameLayoutRule;
    let prop: LayoutProp<FrameLayout>;
    beforeEach(() => {
      prop = new LayoutProp('FrameLayout', new FrameLayout)
      rule = new FrameLayoutRule(prop);
      MonthlyViewStateManager.getInstance().state.hideAgendaWindow = false;
    })

    it('onChange_env_property_invalid', 0, () => {
      const ret = rule.onChange(new Env(MonthViewLayoutEnv.COMPONENT_SIZE));
      expect(ret).assertFalse();
    })

    it('onChange_env_invalid', 0, () => {
      const ret = rule.onChange(new Env('other'));
      expect(ret).assertFalse();
    })

    it('onChange_env', 0, () => {
      let env = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
      env.data.set('width', 100);
      const ret = rule.onChange(env);
      expect(ret).assertFalse();
    })

    it('onChange_env_2', 0, () => {
      let env = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
      env.data.set('width', 100);
      env.data.set('height', 100);
      const ret = rule.onChange(env);
      expect(ret).assertTrue();
    })

    it('onBreakpointChange_0', 0, () => {
      const ret = rule.onBreakpointChange(100, 100);
      expect(rule.bp).assertEqual('xs');
    })

    it('onAgendaSizeChange', 0, () => {
      rule.onBreakpointChange(100, 100);
      expect(prop.value.isSmall).assertTrue();
      rule.setAgendaRadio(100, false);
      expect(prop.value.agendaListViewWidth).assertEqual(100);
      rule.onBreakpointChange(620, 620);
      expect(prop.value.isSmall).assertFalse();
      rule.setAgendaRadio(640, false);
      expect(prop.value.agendaListViewWidth).assertEqual(320);
      rule.setAgendaRadio(660, true); // 0.375 max to 1
      expect(prop.value.agendaListViewWidth).assertEqual(330);
      prop.value.agendaListRatio = 0.2;
      rule.setAgendaRadio(1080, true); // 0.222 min
      expect(prop.value.agendaListViewWidth).assertEqual(240);
      prop.value.agendaListRatio = 1.5;
      rule.setAgendaRadio(1080, true); // 1.25 max
      expect(prop.value.agendaListViewWidth).assertEqual(600);
    })

    it('checkIsGrid1', 0, () => {
      const ret = rule.reCalLayout(400, 400);
      expect(prop.value.isGrid).assertFalse();
    })

    it('checkIsGrid2', 0, () => {
      const ret = rule.reCalLayout(700, 400);
      expect(prop.value.isGrid).assertFalse();
    })

    it('checkIsGrid3', 0, () => {
      const ret = rule.reCalLayout(962, 400);
      expect(prop.value.isGrid).assertTrue();
    })

    it('checkIsGrid4', 0, () => {
      MonthlyViewStateManager.getInstance().state.hideAgendaWindow = true;
      const ret = rule.reCalLayout(700, 400);
      expect(prop.value.isGrid).assertTrue();
    })
  })
}