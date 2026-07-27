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
import { WeekTitleLayout, WeekTitleLayoutRule } from '@app/feature.monthview/src/main/ets/layoutmodel/WeekTitleLayoutRule';
import { MonthViewLayoutEnv } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutEnv';
import { FrameLayout } from '@app/feature.monthview/src/main/ets/layoutmodel/FrameLayoutRule';


export default function WeekTitleLayoutRuleTest() {
  describe('WeekTitleLayoutRuleTest', () => {
    let rule: WeekTitleLayoutRule;
    let prop: LayoutProp<WeekTitleLayout>;
    let frameProp: LayoutProp<FrameLayout>;
    beforeEach(() => {
      frameProp = new LayoutProp('FrameLayoutRule', new FrameLayout);
      prop = new LayoutProp('WeekTitleLayout', new WeekTitleLayout)
      rule = new WeekTitleLayoutRule(frameProp, prop);
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
      expect(ret).assertTrue();
    })

    it('onBreakpointChange_100', 0, () => {
      const ret = rule.onBreakpointChange(100);
      expect(rule.bp).assertEqual('xs');
    })

    it('onBreakpointChange_1000', 0, () => {
      const ret = rule.onBreakpointChange(1000);
      expect(rule.bp).assertEqual('lg');
    })
  })
}