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
import { Env, LayoutProp, LayoutRule, Log } from '@app/common/index';
import { FrameLayout } from './FrameLayoutRule';
import { MonthViewLayoutEnv } from './MonthViewLayoutEnv';

const TAG = '[MonthlyView][Layout][WeekTitle]';

interface breakPoint {
  bp: number,
  name: string,
  value: number,
  padding: number,
}

@Observed
export class WeekTitleLayout {
  public static readonly marginDownGap: number = 2; // 周题与第一排宫格的调整间距，第一排宫格的y = height - marginDownGap
  public fontSize: number = 12; // 周标题字体大小
  public leftPadding: number = 12; // 周标题宫格时距左边距离
}

/**
 * 月视图周标题布局规则
 */
export class WeekTitleLayoutRule extends LayoutRule {
  public bp: string = '';
  private prop: LayoutProp<WeekTitleLayout>;
  private frameProp: LayoutProp<FrameLayout>;
  private breakPoints: ReadonlyArray<breakPoint> = [
    { bp: 0, name: 'xs', value: 10, padding: 8 },
    { bp: 240, name: 'sm', value: 10, padding: 9 },
    { bp: 340, name: 'sm2', value: 12, padding: 9 },
    { bp: 600, name: 'md', value: 12, padding: 10 },
    { bp: 840, name: 'lg', value: 12, padding: 11 },
    { bp: 1080, name: 'xl', value: 14, padding: 12 },

    { bp: 1320, name: 'xxl', value: 16, padding: 11 },
    { bp: 99999, name: 'max', value: 18, padding: 14 },
  ];

  constructor(frameProp: LayoutProp<FrameLayout>, prop: LayoutProp<WeekTitleLayout>) {
    super('WeekTitleLayout', [
      MonthViewLayoutEnv.COMPONENT_SIZE,// 自身组件大小
    ]);
    // 建立引用
    this.frameProp = frameProp;
    this.prop = prop;
  }

  onChange(env: Env): boolean {
    if (env.name === MonthViewLayoutEnv.COMPONENT_SIZE) {
      const width = env.data.get('width');
      if (typeof width === 'number') {
        this.reCalLayout(width);
        return true;
      }
    }
    return false;
  }

  // 组件宽度，高度
  reCalLayout(newComponentWidth: number) {
    // 先计算日期区域宽度
    const areaWidth = this.frameProp.value.monthDateWidth;
    // 再触发内部布局变化
    this.onBreakpointChange(areaWidth);
    Log.info(TAG, `layout titleFontSize ${this.prop.value.fontSize}, padding ${this.prop.value.leftPadding}`);
  }

  onBreakpointChange(newComponentWidth: number) {
    const width: number = newComponentWidth;
    let tempBp: string = '';
    for (let i = 0; i < this.breakPoints.length - 1; ++i) {
      if (width >= this.breakPoints[i].bp && width < this.breakPoints[i + 1].bp) {
        tempBp = this.breakPoints[i].name;
        this.prop.value.fontSize = this.breakPoints[i].value;
        this.prop.value.leftPadding = this.breakPoints[i].padding;
        break;
      }
    }
    if (this.bp === tempBp) {
      Log.warn(TAG, `No Need To Change Layout In The Same Screen!`);
      return;
    }
    this.bp = tempBp;
  }
}
