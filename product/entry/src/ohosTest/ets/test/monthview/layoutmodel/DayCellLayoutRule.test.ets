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
import { dayCellBreakPoints, DayCellLayout, DayCellLayoutRule } from '@app/feature.monthview/src/main/ets/layoutmodel/DayCellLayoutRule';
import { MonthViewLayoutEnv } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutEnv';
import { FrameLayout } from '@app/feature.monthview/src/main/ets/layoutmodel/FrameLayoutRule';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';


export default function DayCellLayoutRuleTest() {
  describe('DayCellLayoutRuleTest', () => {
    let rule: DayCellLayoutRule;
    let frameProp: LayoutProp<FrameLayout>;
    let prop: LayoutProp<DayCellLayout>;
    beforeEach(() => {
      frameProp = new LayoutProp('FrameLayoutRule', new FrameLayout);
      prop = new LayoutProp('DayCellLayout', new DayCellLayout);
      rule = new DayCellLayoutRule(frameProp, prop);
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

    it('onChange_env_valid', 0, () => {
      const ret = rule.onChange(new Env(MonthViewLayoutEnv.MODE));
      expect(ret).assertTrue();
    })

    it('onChange_env', 0, () => {
      let env = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
      env.data.set('width', 100);
      const ret = rule.onChange(env);
      expect(ret).assertTrue();
    })

    it('onChange_small_env', 0, () => {
      frameProp.value.isSmall = true;
      frameProp.value.isGrid = false;
      frameProp.value.monthDateWidth = 550;
      let env = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
      env.data.set('width', 550);
      env.data.set('height', 550);
      const ret = rule.onChange(env);
      expect(prop.value.solarFontSize).assertEqual(22);
    })

    it('onChange_large_env', 0, () => {
      frameProp.value.isSmall = false;
      let env = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
      env.data.set('width', 550);
      env.data.set('height', 100);
      const ret = rule.onChange(env);
      expect(prop.value.solarFontSize).assertEqual(12);
    })

    // XIAOYAO 平板竖屏
    it('reCalLayout_1', 0, () => {
      frameProp.value.isSmall = true;
      frameProp.value.isGrid = false;
      frameProp.value.monthDateWidth = 711;
      const ret = rule.reCalLayout(711);
      expect(prop.value.solarFontSize).assertEqual(24);
      expect(prop.value.solarFontHeight).assertEqual(26);
      expect(prop.value.calOrHolFontSize).assertEqual(12);
      expect(prop.value.calOrHolFontHeight).assertEqual(14);
      expect(prop.value.recessFontSize).assertEqual(12);
      expect(prop.value.circleSize).assertEqual(70);
      expect(prop.value.isVerticalCell).assertEqual(true);
    })

    // XIAOYAO 平板横屏 侧边栏不收起
    it('reCalLayout_2', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.isGrid = false;
      frameProp.value.agendaListViewWidth = 420;
      frameProp.value.monthDateWidth = 477;
      const ret = rule.reCalLayout(897);
      expect(prop.value.solarFontSize).assertEqual(20);
      expect(prop.value.solarFontHeight).assertEqual(22);
      expect(prop.value.calOrHolFontSize).assertEqual(10);
      expect(prop.value.calOrHolFontHeight).assertEqual(12);
      expect(prop.value.recessFontSize).assertEqual(10);
      expect(prop.value.circleSize).assertEqual(56);
      expect(prop.value.isVerticalCell).assertEqual(true);
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 477;
      const ret2 = rule.reCalLayout(897);
      expect(prop.value.solarFontSize).assertEqual(12);
      expect(prop.value.solarFontHeight).assertEqual(13);
      expect(prop.value.calOrHolFontSize).assertEqual(9);
      expect(prop.value.calOrHolFontHeight).assertEqual(10);
      expect(prop.value.recessFontSize).assertEqual(9);
      expect(prop.value.circleSize).assertEqual(26);
      expect(prop.value.isVerticalCell).assertEqual(false);
    })

    // XIAOYAO 平板横屏 侧边栏收起
    it('reCalLayout_3', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.isGrid = true;
      frameProp.value.agendaListViewWidth = 420;
      frameProp.value.monthDateWidth = 718;
      const ret = rule.reCalLayout(1138);
      expect(prop.value.solarFontSize).assertEqual(14);
      expect(prop.value.solarFontHeight).assertEqual(16);
      expect(prop.value.calOrHolFontSize).assertEqual(10);
      expect(prop.value.calOrHolFontHeight).assertEqual(12);
      expect(prop.value.recessFontSize).assertEqual(10);
      expect(prop.value.circleSize).assertEqual(28);
      expect(prop.value.isVerticalCell).assertEqual(false);
    })

    it('onBreakpointChange_0', 0, () => {
      const ret = rule.onBreakpointChange(0, 0);
      expect(ret).assertDeepEquals(dayCellBreakPoints[0]);
    })

    it('onBreakpointChange_over_max_size', 0, () => {
      const ret = rule.onBreakpointChange(4000, 4000);
      expect(ret).assertDeepEquals(dayCellBreakPoints[dayCellBreakPoints.length - 1]);
    })

    it('weekNumPadding', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 718;
      rule.reCalLayout(1138);
      expect(prop.value.weekNumPadding).assertEqual(0);
      frameProp.value.isGrid = false;
      rule.reCalLayout(1138);
      expect(prop.value.weekNumPadding).assertEqual(7);
      frameProp.value.isSmall = true;
      frameProp.value.monthDateWidth = 382;
      rule.reCalLayout(382);
      expect(prop.value.weekNumPadding).assertEqual(0);
      frameProp.value.monthDateWidth = 347;
      rule.reCalLayout(347);
      expect(prop.value.weekNumPadding).assertEqual(0);
    })

    it('breakPointDown', 0, () => {
      frameProp.value.isSmall = true;
      frameProp.value.isGrid = false;
      frameProp.value.monthDateWidth = 1138;
      rule.reCalLayout(1138, 401);
      expect(prop.value.circleSize).assertEqual(58);
      rule.reCalLayout(1138, 600);
      expect(prop.value.circleSize).assertEqual(60);
      frameProp.value.isSmall = false;
      frameProp.value.isGrid = false;
      frameProp.value.monthDateWidth = 551;
      rule.reCalLayout(971, 300);
      expect(prop.value.circleSize).assertEqual(50);
      rule.reCalLayout(971, 401);
      expect(prop.value.circleSize).assertEqual(58);
      frameProp.value.isSmall = false;
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 551;
      rule.reCalLayout(971, 300);
      expect(prop.value.circleSize).assertEqual(26);
      rule.reCalLayout(971, 100);
      expect(prop.value.circleSize).assertEqual(26);
    })

    // 宫格化1,正常宫格化
    it('reCalLayout_grid1', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.agendaListViewWidth = 420;
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 718;
      const ret = rule.reCalLayout(1138);
      expect(prop.value.solarFontSize).assertEqual(14);
      expect(prop.value.solarFontHeight).assertEqual(16);
      expect(prop.value.calOrHolFontSize).assertEqual(10);
      expect(prop.value.calOrHolFontHeight).assertEqual(12);
      expect(prop.value.recessFontSize).assertEqual(10);
      expect(prop.value.circleSize).assertEqual(28);
      expect(prop.value.isVerticalCell).assertEqual(false);
    })

    // 宫格化2,最大宫格化
    it('reCalLayout_grid2', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.agendaListViewWidth = 420;
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 9579;
      const ret = rule.reCalLayout(9999);
      expect(prop.value.solarFontSize).assertEqual(18);
      expect(prop.value.solarFontHeight).assertEqual(20);
      expect(prop.value.calOrHolFontSize).assertEqual(14);
      expect(prop.value.calOrHolFontHeight).assertEqual(16);
      expect(prop.value.recessFontSize).assertEqual(14);
      expect(prop.value.circleSize).assertEqual(36);
      expect(prop.value.isVerticalCell).assertEqual(false);
    })

    // 宫格化3,隐藏日程列表
    it('reCalLayout_grid3', 0, () => {
      frameProp.value.isSmall = false;
      frameProp.value.agendaListViewWidth = 420;
      frameProp.value.isGrid = true;
      MonthlyViewStateManager.getInstance().state.hideAgendaWindow = true;
      frameProp.value.monthDateWidth = 886;
      const ret = rule.reCalLayout(886);
      expect(prop.value.solarFontSize).assertEqual(16);
      expect(prop.value.solarFontHeight).assertEqual(18);
      expect(prop.value.calOrHolFontSize).assertEqual(12);
      expect(prop.value.calOrHolFontHeight).assertEqual(14);
      expect(prop.value.recessFontSize).assertEqual(12);
      expect(prop.value.circleSize).assertEqual(32);
      expect(prop.value.isVerticalCell).assertEqual(false);
    })

    // 宫格化4,小屏状态非宫格
    it('reCalLayout_grid4', 0, () => {
      frameProp.value.isSmall = true;
      frameProp.value.agendaListViewWidth = 320;
      frameProp.value.isGrid = true;
      frameProp.value.monthDateWidth = 768;
      const ret = rule.reCalLayout(768);
      expect(prop.value.solarFontSize).assertEqual(24);
      expect(prop.value.solarFontHeight).assertEqual(26);
      expect(prop.value.calOrHolFontSize).assertEqual(12);
      expect(prop.value.calOrHolFontHeight).assertEqual(14);
      expect(prop.value.recessFontSize).assertEqual(12);
      expect(prop.value.circleSize).assertEqual(70);
      expect(prop.value.isVerticalCell).assertEqual(true);
    })
  })
}