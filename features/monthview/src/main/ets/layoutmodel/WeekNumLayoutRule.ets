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
import { MonthViewLayoutEnv } from './MonthViewLayoutEnv';
import { FrameLayout } from './FrameLayoutRule';

const TAG = '[MonthlyView][Layout][WeekNum]';

interface breakPoint {
  bp: number,
  name: string,
  value: number
}

@Observed
export class WeekNumLayout {
  public width: number = 16; // 周数宫格的宽度
  public fontSize: number = 10; // 周数文字大小, 第几周
  public marginUp: number = 22; // 周数文字中心离上边框距离
}

/**
 * 月视图周标题布局规则
 */
export class WeekNumLayoutRule extends LayoutRule {
  public bp: string = '';
  private prop: LayoutProp<WeekNumLayout>;
  private frameProp: LayoutProp<FrameLayout>;
  private breakPoints: breakPoint[] = [
    { bp: 0, name: 'xs', value: 8 },
    { bp: 360, name: 'sm', value: 10 },
    { bp: 600, name: 'md', value: 10 },
    { bp: 840, name: 'lg', value: 12 },
    { bp: 1080, name: 'xl', value: 12 },
    { bp: 1320, name: 'xxl', value: 12 },
    { bp: 99999, name: 'max', value: 12 },
  ];

  constructor(frameProp: LayoutProp<FrameLayout>, prop: LayoutProp<WeekNumLayout>) {
    super('WeekNumLayoutRule', [
      MonthViewLayoutEnv.COMPONENT_SIZE,// 自身组件大小
    ]);
    // 建立引用
    this.frameProp = frameProp;
    this.prop = prop;
  }

  onChange(env: Env): boolean {
    if (env.name === MonthViewLayoutEnv.COMPONENT_SIZE) {
      const width = env.data.get('width');
      const height = env.data.get('height');
      if (typeof width === 'number' && typeof height === 'number') {
        if (!this.frameProp.value.isSmall) {
          const finalWidth = height < (width / 2) ? height : width;
          this.reCalLayout(finalWidth);
        } else {
          this.reCalLayout(width);
        }
        return true;
      } else if (typeof width === 'number') {
        this.reCalLayout(width);
        return true;
      }
    }
    return false;
  }

  // 组件宽度，高度
  reCalLayout(newComponentWidth: number) {
    // 再触发内部布局变化
    this.onBreakpointChange(newComponentWidth);
    Log.info(TAG, `layout weekNumSize ${this.prop.value.fontSize}`)
  }

  onBreakpointChange(width: number) {
    let tempBp: string = '';
    for (let i = 0; i < this.breakPoints.length - 1; ++i) {
      if (width >= this.breakPoints[i].bp && width < this.breakPoints[i + 1].bp) {
        tempBp = this.breakPoints[i].name;
        this.prop.value.fontSize = this.breakPoints[i].value;
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
