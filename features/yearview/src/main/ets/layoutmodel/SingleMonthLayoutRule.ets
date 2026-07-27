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

const TAG = 'LayoutRule-SingleMonth'

@Observed
export class MonthLayout {
  public legendFontSize: number = 10; // 农历TAG 字体大小
  public monthFontSize: number = 16; // 月份字体大小
}

export class MonthLayoutBp implements BreakPoint2D {
  public width: number = 0;
  public height: number = 0;
  public layout: MonthLayout = new MonthLayout();
}

export const monthLayoutBps: MonthLayoutBp[] = [
  { width: 360, height: 625, layout: { legendFontSize: 10, monthFontSize: 16 } }, // 直板手机竖屏 {折叠态竖屏}
  { width: 700, height: 670, layout: { legendFontSize: 10, monthFontSize: 18 } }, // 折叠机展开态竖屏
  { width: 670, height: 700, layout: { legendFontSize: 10, monthFontSize: 18 } }, // 折叠屏展开横屏
  { width: 830, height: 430, layout: { legendFontSize: 10, monthFontSize: 16 } }, // PC 窗口化 最小宽度 最小高度 4 * 3
  { width: 830, height: 650, layout: { legendFontSize: 10, monthFontSize: 18 } }, // PC 窗口化 默认宽度 默认高度 3 * 4
  { width: 830, height: 960, layout: { legendFontSize: 10, monthFontSize: 18 } }, // PC 窗口化 最小宽度 最大高度 3 * 4
  { width: 1080, height: 760, layout: { legendFontSize: 10, monthFontSize: 18 } }, // 平板 横屏 侧边栏显示
  { width: 1280, height: 760, layout: { legendFontSize: 10, monthFontSize: 18 } }, // 平板 横屏 侧边栏收起
  { width: 1280, height: 800, layout: { legendFontSize: 10, monthFontSize: 22 } },
  { width: 1440, height: 430, layout: { legendFontSize: 10, monthFontSize: 18 } }, // PC 窗口化 最大宽度 最小高度 6 * 2
  { width: 1440, height: 763, layout: { legendFontSize: 10, monthFontSize: 22 } }, // 平板
  { width: 1728, height: 1152, layout: { legendFontSize: 12, monthFontSize: 24 } },// KLV 全屏 最大宽度 最大高度
]

export class SingleMonthLayoutRule extends LayoutRule {
  private monthLayout: LayoutProp<MonthLayout>;
  private bpHelper: BreakPoint2DHelper = new BreakPoint2DHelper();
  private lastTargetIndex: number = -1;

  constructor(monthLayout: LayoutProp<MonthLayout>) {
    super('SingleMonthLayoutRule', [YearViewLayoutEnv.COMPONENT_SIZE]);
    this.monthLayout = monthLayout;
    this.bpHelper.init(monthLayoutBps);
  }

  reCalLayout(width: number, height: number): void {
    Log.info(TAG, `reCalLayout width:${width}, height${height}`);
    let targetIndex = this.bpHelper.match(width, height);
    if (targetIndex === this.lastTargetIndex) {
      return;
    }
    Log.info(TAG, `Index from :${this.lastTargetIndex} to ${targetIndex}`)
    this.lastTargetIndex = targetIndex;
    this.monthLayout.value = monthLayoutBps[targetIndex].layout;
    Log.info(TAG, `targetIndex:${targetIndex} monthLayout ${this.monthLayout.value.monthFontSize}`);
  }

  onChange(env: Env): boolean {
    let width = env.data.get('width') as number;
    let height = env.data.get('height') as number;
    this.reCalLayout(width, height);
    return true;
  }
}

