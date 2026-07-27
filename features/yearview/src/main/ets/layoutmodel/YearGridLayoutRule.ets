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
import { BigFontSize, Env, LayoutProp, LayoutRule, Log } from '@app/common/index';
import { GridProp, GridTemplate } from './YearViewLayoutProp';
import { YearViewLayoutEnv } from './YearViewLayoutEnv';
import { DayLayout } from './SingleDayLayoutRule';

const TAG = 'LayoutRule-YearGrid'

export class YearGridLayoutRule extends LayoutRule {
  private gridProp: LayoutProp<GridProp>;
  private dayLayout: LayoutProp<DayLayout>;

  constructor(gridProp: LayoutProp<GridProp>, dayLayout: LayoutProp<DayLayout>) {
    super('YearGridLayoutRule', [YearViewLayoutEnv.COMPONENT_SIZE]);
    this.gridProp = gridProp;
    this.dayLayout = dayLayout;
  }

  onChange(env: Env): boolean {
    let width = env.data.get('width') as number;
    let height = env.data.get('height') as number;
    let fontSizeScale = env.data.get('fontSizeScale') as number ?? 1;
    if (fontSizeScale === BigFontSize.BIG_FONT_SIZE_STANDARD || 
    fontSizeScale === BigFontSize.BIG_FONT_SIZE_SCALE_3X) { // 系统字体为标准字体和最大档位时的最小宽高计算
      this.gridProp.value.minHeight = this.dayLayout.value.selectCircle * fontSizeScale * 7;
      this.gridProp.value.minWidth = this.dayLayout.value.selectCircle * fontSizeScale * 7;
    } else { // 中间档位时最小宽高计算
      this.gridProp.value.minHeight = this.dayLayout.value.selectCircle * (fontSizeScale + 0.5) * 7;
      this.gridProp.value.minWidth = this.dayLayout.value.selectCircle * (fontSizeScale + 0.5) * 7;
    }
    return this.reCalGridProp(width, height);
  }

  calRatioBp(newWidth: number, newHeight: number): GridProp | null {
    if (newWidth <= 0 || newHeight <= 0) {
      return null;
    }
    const ratio = newWidth / newHeight;
    Log.info(TAG, `ratio:${ratio}`);
    let res: GridProp = ratioBps[0].prop;
    let ratioIndex = 0;
    // 对断点进行匹配
    for (let i = 0; i < ratioBps.length; ++i) {
      if (ratio < ratioBps[i].ratio) {
        ratioIndex = i;
        break;
      }
    }
    // 分屏适配场景,当宽度不够展示当前断点月份时对断点进行降级
    for (let i = ratioIndex; i >= 0; i--) {
      const expectWidth = ratioBps[i].prop.colCount * this.gridProp.value.minWidth;
      if (expectWidth <= newWidth) {
        res = ratioBps[i].prop;
        Log.info(TAG, `ratioIndex:${i} ${expectWidth} ${newWidth}`);
        break;
      }
    }
    return res;
  }

  reCalGridProp(newWidth: number, newHeight: number): boolean {
    let prop = this.calRatioBp(newWidth, newHeight);
    if (prop === null) {
      Log.error(TAG, `prop null`);
      return false;
    }
    if (this.gridProp.value === prop) {
      Log.info(TAG, `prop no change`);
      return true;
    }
    this.gridProp.value.template = prop.template;
    this.gridProp.value.colsTemplateStr = prop.colsTemplateStr;
    this.gridProp.value.rowsTemplateStr = prop.rowsTemplateStr;
    this.gridProp.value.rowsHeight = prop.rowsHeight;
    this.gridProp.value.colCount = prop.colCount;
    this.gridProp.value.minHeight = Math.max(prop.minHeight, this.gridProp.value.minHeight);
    const heightRatio = 0.026;
    this.gridProp.value.paddingBottom = newHeight * heightRatio;
    const gridValue = this.gridProp.value;
    Log.info(TAG, `gridProp ${gridValue.colsTemplateStr} ${gridValue.rowsTemplateStr} ${gridValue.minWidth}`);
    return true;
  }
}

// 月视图断点
interface ratioBreakPoint {
  ratio: number;
  prop: GridProp;
}

const ratioBps: ratioBreakPoint[] = [
  {
    ratio: 0.4, // 折叠态竖屏 0.55   初始化场景以整个窗口进行计算 0.46
    prop: {
      template: GridTemplate.LAYOUT_2_6,
      colsTemplateStr: '1fr 1fr',
      rowsTemplateStr: '1fr 1fr 1fr 1fr 1fr 1fr',
      rowsHeight: '13.33%',
      colCount: 2,
      paddingBottom: 24,
      minWidth: 100,
      minHeight: 100
    }
  },
  {
    ratio: 0.8,
    prop: {
      template: GridTemplate.LAYOUT_3_4,
      colsTemplateStr: '1fr 1fr 1fr',
      rowsTemplateStr: '1fr 1fr 1fr 1fr',
      rowsHeight: '22%',
      colCount: 3,
      paddingBottom: 24,
      minWidth: 100,
      minHeight: 100
    }
  },
  {
    ratio: 2.5,
    prop: {
      template: GridTemplate.LAYOUT_4_3,
      colsTemplateStr: '1fr 1fr 1fr 1fr',
      rowsTemplateStr: '1fr 1fr 1fr',
      rowsHeight: '30.33%',
      colCount: 4,
      paddingBottom: 24,
      minWidth: 100,
      minHeight: 100
    }
  },
  {
    ratio: 5,
    prop: {
      template: GridTemplate.LAYOUT_6_2,
      colsTemplateStr: '1fr 1fr 1fr 1fr 1fr 1fr',
      rowsTemplateStr: '1fr 1fr',
      rowsHeight: '48%',
      colCount: 6,
      paddingBottom: 24,
      minWidth: 100,
      minHeight: 100
    }
  }
];