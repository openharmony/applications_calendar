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
import { BreakPoint2D, BreakPoint2DHelper, Env, LayoutProp, LayoutRule, Log } from '@app/common/index';
import { YearViewLayoutEnv } from './YearViewLayoutEnv';

const TAG = 'LayoutRule-SingleDay'

@Observed
export class DayLayout {
  public dayFontSize: number = 8.5; // 星期日期,天
  public selectCircle: number = 12; // 选中圆形半径
  public lunarLineWidth: number = 6; // 农历初一下划线宽度
}

export class DayLayoutBp implements BreakPoint2D {
  public width: number = 0;
  public height: number = 0;
  public layout: DayLayout = new DayLayout();
}

export const dayLayoutBps: DayLayoutBp[] = [
  { width: 700, height: 325, layout: { dayFontSize: 8, selectCircle: 10, lunarLineWidth: 5 } }, // 折叠机展开态上下分屏
  { width: 360, height: 625, layout: { dayFontSize: 9, selectCircle: 12, lunarLineWidth: 6 } }, // 直板手机竖屏 {折叠态竖屏}
  { width: 700, height: 670, layout: { dayFontSize: 10, selectCircle: 14, lunarLineWidth: 6 } }, // 折叠机展开态竖屏
  { width: 670, height: 700, layout: { dayFontSize: 10, selectCircle: 12, lunarLineWidth: 6 } }, // 折叠屏展开横屏
  { width: 830, height: 430, layout: { dayFontSize: 10, selectCircle: 14, lunarLineWidth: 6 } }, // PC 窗口化 最小宽度
  { width: 830, height: 650, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 6 } }, // PC 窗口化 默认宽度
  { width: 830, height: 960, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 6 } }, // PC 窗口化 最小宽度
  { width: 1080, height: 760, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 8 } }, // 平板 横屏 侧边栏显示
  { width: 1280, height: 760, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 8 } }, // 平板 横屏 侧边栏收起
  { width: 1280, height: 800, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 6 } }, //
  { width: 1440, height: 430, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 6 } }, // PC 窗口化
  { width: 1440, height: 763, layout: { dayFontSize: 12, selectCircle: 16, lunarLineWidth: 6 } }, // 平板
  { width: 1448, height: 962, layout: { dayFontSize: 16, selectCircle: 24, lunarLineWidth: 10 } }, // PC全屏,侧边栏展开
  { width: 1728, height: 1152, layout: { dayFontSize: 16, selectCircle: 24, lunarLineWidth: 10 } },// KLV 全屏 最大宽度
]

export class SingleDayLayoutRule extends LayoutRule {
  private dayLayout: LayoutProp<DayLayout>;
  // BreakPoint2D
  private bpHelper: BreakPoint2DHelper = new BreakPoint2DHelper();
  private lastTargetIndex: number = -1;

  constructor(dayLayout: LayoutProp<DayLayout>) {
    super('SingleDayLayoutRule', [YearViewLayoutEnv.COMPONENT_SIZE]);

    this.dayLayout = dayLayout;
    this.bpHelper.init(dayLayoutBps);
  }

  reCalLayout(width: number, height: number, fontSizeScale: number) {
    Log.info(TAG, `reCalLayout width:${width}, height${height}, fontSizeScale${fontSizeScale}`);
    let targetIndex = this.bpHelper.match(width, height);
    if (targetIndex === this.lastTargetIndex) {
      return;
    }
    Log.info(TAG, `Index from :${this.lastTargetIndex} to ${targetIndex}`)
    this.lastTargetIndex = targetIndex;
    this.dayLayout.value.dayFontSize = dayLayoutBps[targetIndex].layout.dayFontSize;
    this.dayLayout.value.selectCircle = dayLayoutBps[targetIndex].layout.selectCircle;
    this.dayLayout.value.lunarLineWidth = dayLayoutBps[targetIndex].layout.lunarLineWidth;
    Log.info(TAG,
      `targetIndex:${targetIndex} dayLayout${this.dayLayout.value.dayFontSize} ${this.dayLayout.value.selectCircle}`);
  }

  onChange(env: Env): boolean {
    let width = env.data.get('width') as number;
    let height = env.data.get('height') as number;
    let fontSizeScale = env.data.get('fontSizeScale') as number ?? 1;
    this.reCalLayout(width, height, fontSizeScale);
    return true;
  }
}

