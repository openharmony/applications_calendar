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
import {
  DAY_PER_WEEK,
  Env,
  FoldScreenType,
  GlobalDataKeys,
  LayoutProp,
  LayoutRule,
  Log,
  UnusualMode
} from '@app/common/index';
import { MonthViewLayoutEnv } from './MonthViewLayoutEnv';
import { FrameLayout } from './FrameLayoutRule';
import { MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';

const TAG = '[MonthlyView][Layout][DayCell]';

export class ReadOnlyDayCellProp {
  public static readonly agendaMarginTop: number = 4; // 日程标点到下划线的垂直距离
  public static readonly verticalGap: number = 3;
  public static readonly calOrHolFontMarginTop: number = vp2px(2); //左右视图向下偏移一段距离以保持底部对齐
  // 选中圈
  public static readonly circleLine: number = 1;
}

@Observed
export class DayCellLayout {
  // 选中圈
  public circleSize: number = 48;
  // 日期
  public solarFontSize: number = 18;
  public solarFontHeight: number = 20;
  // 周数偏移量,通过宽度和日期计算而来
  public weekNumPadding: number = 0;
  // 班休
  public recessFontSize: number = 8;
  // 历法或节假日
  public calOrHolFontSize: number = 10;
  public calOrHolFontHeight: number = 12;
  public lunarLineWidth: number = 20;
  public isVerticalCell: boolean = true; // 月视图的宫格是否是垂直布局
  // 日程标点
  public agendaPointSize: number = 4;
}

export interface DayCellBreakPoint {
  width: number;
  minHeight: number; // 用于触发断点降级的最小高度
  value: DayCellLayout;
}

const hiCarDayCellLayout: DayCellLayout = {
  solarFontSize: 20,
  solarFontHeight: 28,
  weekNumPadding: 0,
  calOrHolFontSize: 8,
  calOrHolFontHeight: 12,
  recessFontSize: 10,
  circleSize: 42,
  lunarLineWidth: 16,
  agendaPointSize: 3,
  isVerticalCell: false
}

// 上下小折叠
const smallUpDownFoldDayCellLayout: DayCellLayout = {
  solarFontSize: 14,
  solarFontHeight: 16,
  weekNumPadding: 0,
  calOrHolFontSize: 8,
  calOrHolFontHeight: 10,
  recessFontSize: 8,
  circleSize: 40,
  lunarLineWidth: 20,
  agendaPointSize: 2,
  isVerticalCell: true,
}

//gridDayCellBreakPoints里的元素要按照width从大到小排列
export const gridDayCellBreakPoints: ReadonlyArray<DayCellBreakPoint> = [
  {
    width: 280,
    minHeight: 0,
    value: {
      solarFontSize: 11,
      solarFontHeight: 8,
      weekNumPadding: 0,
      calOrHolFontSize: 9,
      calOrHolFontHeight: 7,
      recessFontSize: 8.5,
      circleSize: 25,
      lunarLineWidth: 10,
      agendaPointSize: 2,
      isVerticalCell: false,
    }
  },
  {
    width: 340,
    minHeight: 170,
    value: {
      solarFontSize: 12,
      solarFontHeight: 10,
      weekNumPadding: 0,
      calOrHolFontSize: 9,
      calOrHolFontHeight: 7,
      recessFontSize: 8.5,
      circleSize: 19,
      lunarLineWidth: 10,
      agendaPointSize: 2,
      isVerticalCell: false,
    }
  },
  {
    width: 400,
    minHeight: 260,
    value: {
      solarFontSize: 14,
      solarFontHeight: 12,
      weekNumPadding: 0,
      calOrHolFontSize: 11,
      calOrHolFontHeight: 10,
      recessFontSize: 10.5,
      circleSize: 23,
      lunarLineWidth: 12,
      agendaPointSize: 3,
      isVerticalCell: false,
    }
  },
  {
    width: 480,
    minHeight: 0,
    value: {
      solarFontSize: 16,
      solarFontHeight: 13,
      weekNumPadding: 0,
      calOrHolFontSize: 12,
      calOrHolFontHeight: 10,
      recessFontSize: 11.5,
      circleSize: 29,
      lunarLineWidth: 14,
      agendaPointSize: 3,
      isVerticalCell: false,
    }
  },
  {
    width: 600,
    minHeight: 0,
    value: {
      solarFontSize: 16,
      solarFontHeight: 14,
      weekNumPadding: 0,
      calOrHolFontSize: 12,
      calOrHolFontHeight: 10,
      recessFontSize: 11.5,
      circleSize: 29,
      lunarLineWidth: 14,
      agendaPointSize: 3,
      isVerticalCell: false,
    }
  },
  {
    width: 840,
    minHeight: 0,
    value: {
      solarFontSize: 18,
      solarFontHeight: 16,
      weekNumPadding: 0,
      calOrHolFontSize: 13,
      calOrHolFontHeight: 12,
      recessFontSize: 12.5,
      circleSize: 31,
      lunarLineWidth: 15,
      agendaPointSize: 2,
      isVerticalCell: false,
    }
  },
  {
    width: 1080,
    minHeight: 0,
    value: {
      solarFontSize: 20,
      solarFontHeight: 18,
      weekNumPadding: 0,
      calOrHolFontSize: 15,
      calOrHolFontHeight: 14,
      recessFontSize: 14.5,
      circleSize: 35,
      lunarLineWidth: 16,
      agendaPointSize: 2,
      isVerticalCell: false,
    }
  },
  {
    width: 1320,
    minHeight: 0,
    value: {
      solarFontSize: 22,
      solarFontHeight: 20,
      weekNumPadding: 0,
      calOrHolFontSize: 17,
      calOrHolFontHeight: 16,
      recessFontSize: 16.5,
      circleSize: 39,
      lunarLineWidth: 18,
      agendaPointSize: 2,
      isVerticalCell: false,
    }
  }
]

export const dayCellBreakPoints: ReadonlyArray<DayCellBreakPoint> = [
  {
    width: 280,
    minHeight: 0,
    value: {
      solarFontSize: 12,
      solarFontHeight: 14,
      weekNumPadding: 0,
      calOrHolFontSize: 6,
      calOrHolFontHeight: 7,
      recessFontSize: 6,
      circleSize: 32,
      lunarLineWidth: 15,
      agendaPointSize: 2,
      isVerticalCell: true,
    }
  },
  { // 因启用了小折叠的onSizeChange,故当前小折叠外屏使用的是当前的layout参数
    width: 340,
    minHeight: 170,
    value: {
      solarFontSize: 14,
      solarFontHeight: 16,
      weekNumPadding: 0,
      calOrHolFontSize: 8,
      calOrHolFontHeight: 9,
      recessFontSize: 8,
      circleSize: 40,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 400,
    minHeight: 260,
    value: {
      solarFontSize: 18,
      solarFontHeight: 20,
      weekNumPadding: 0,
      calOrHolFontSize: 10,
      calOrHolFontHeight: 12,
      recessFontSize: 10,
      circleSize: 50,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 480,
    minHeight: 320,
    value: {
      solarFontSize: 20,
      solarFontHeight: 22,
      weekNumPadding: 0,
      calOrHolFontSize: 10,
      calOrHolFontHeight: 12,
      recessFontSize: 10,
      circleSize: 56,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 600,
    minHeight: 400,
    value: {
      solarFontSize: 22,
      solarFontHeight: 24,
      weekNumPadding: 0,
      calOrHolFontSize: 12,
      calOrHolFontHeight: 14,
      recessFontSize: 12,
      circleSize: 58,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 840,
    minHeight: 620,
    value: {
      solarFontSize: 24,
      solarFontHeight: 26,
      weekNumPadding: 0,
      calOrHolFontSize: 12,
      calOrHolFontHeight: 14,
      recessFontSize: 12,
      circleSize: 70,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 1080,
    minHeight: 640,
    value: {
      solarFontSize: 26,
      solarFontHeight: 28,
      weekNumPadding: 0,
      calOrHolFontSize: 14,
      calOrHolFontHeight: 16,
      recessFontSize: 14,
      circleSize: 72,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: true
    }
  },
  {
    width: 1320,
    minHeight: 560,
    value: {
      solarFontSize: 26,
      solarFontHeight: 28,
      weekNumPadding: 0,
      calOrHolFontSize: 14,
      calOrHolFontHeight: 16,
      recessFontSize: 14,
      circleSize: 60,
      lunarLineWidth: 20,
      agendaPointSize: 3,
      isVerticalCell: false
    }
  }
];

/**
 * 月视图周标题布局规则
 */
export class DayCellLayoutRule extends LayoutRule {
  private frameProp: LayoutProp<FrameLayout>;
  private prop: LayoutProp<DayCellLayout>;
  private bp: string = '';
  private needSmall: boolean = false;

  constructor(frameProp: LayoutProp<FrameLayout>, prop: LayoutProp<DayCellLayout>) {
    super('MonthViewLayoutRule', [
      MonthViewLayoutEnv.COMPONENT_SIZE,// 自身组件大小
      MonthViewLayoutEnv.MODE, //组件所处模式
    ]);
    // 建立引用
    this.frameProp = frameProp;
    this.prop = prop;
    this.needSmall = AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE) === FoldScreenType.SMALL_UP_DOWN_FOLD;
  }

  onChange(env: Env): boolean {
    if (env.name === MonthViewLayoutEnv.COMPONENT_SIZE) {
      const width = env.data.get('width');
      const height = env.data.get('height');
      if (typeof width === 'number' && typeof height === 'number') {
        this.reCalLayout(width, height);
        return true;
      } else if (typeof width === 'number') {
        this.reCalLayout(width);
        return true;
      }
    } else if (env.name === MonthViewLayoutEnv.MODE) {
      if (AppStorage.get(GlobalDataKeys.UNUSUAL_MODE) === UnusualMode.HICAR) {
        this.updateDayLayout(hiCarDayCellLayout);
      } else if (AppStorage.get(GlobalDataKeys.UNUSUAL_MODE) === UnusualMode.SMALL_UP_DOWN_FOLD) {
        this.updateDayLayout(smallUpDownFoldDayCellLayout);
      }
      return true;
    }
    return false;
  }

  // 组件宽度，高度
  reCalLayout(newComponentWidth: number, newHeight: number = 9999) {
    // 再触发内部布局变化
    // 减去日程列表宽度？
    const isGrid = this.frameProp.value.isGrid;
    const areaWidth = this.frameProp.value.monthDateWidth;
    const forceSmall = MonthlyViewStateManager.getInstance().modeState.isForceSmall;
    const isInSmallFold = MonthlyViewStateManager.getInstance().modeState.isInSmallFold;
    if (!forceSmall && !isInSmallFold) {
      const bp = // 因存在特殊小屏逻辑需要保留小屏状态下的布局逻辑
        this.frameProp.value.isGrid && !this.frameProp.value.isSmall ?
        this.onGridBreakpointChange(areaWidth, newHeight) :
        this.onBreakpointChange(areaWidth, newHeight);
      this.updateDayLayout(bp.value);
    }
    this.updateWeekNumPadding(areaWidth, isInSmallFold);
    this.frameProp.value.weekRowHeight = this.prop.value.circleSize + 2; // circleLine
    Log.info(TAG, `layoutDay ${areaWidth} ${this.prop.value.circleSize} ${this.prop.value.solarFontSize} ${isGrid}`)
  }

  // 通过当前宽度获取日期宽度,并计算周数的边距
  updateWeekNumPadding(areaWidth: number, isInSmallFold: boolean = false) {
    if (this.frameProp.value.isGrid || isInSmallFold) {
      this.prop.value.weekNumPadding = 0;
      return;
    }
    const dateWidth = Math.floor((areaWidth - 32) / DAY_PER_WEEK * 100) / 100; // 32为边距
    if (dateWidth <= this.prop.value.circleSize) {
      this.prop.value.weekNumPadding = 0;
      return;
    }
    this.prop.value.weekNumPadding = (dateWidth - this.prop.value.circleSize) / 4;
  }

  onBreakpointChange(width: number, height: number): DayCellBreakPoint {
    let breakPoint: number = dayCellBreakPoints.length - 1;
    for (let i = 0; i < dayCellBreakPoints.length; i++) {
      const layout: DayCellBreakPoint = dayCellBreakPoints[i];
      if (width < layout.width) {
        breakPoint = i;
        break;
      }
    }
    while (breakPoint > 0 && dayCellBreakPoints[breakPoint].minHeight >= height) {
      breakPoint--;
    }
    breakPoint = breakPoint < 0 ? dayCellBreakPoints.length - 1 : breakPoint;
    // 查询不到,返回最后一个元素
    Log.info(TAG, `match dayCellBreakPoints index :${breakPoint}`);
    return dayCellBreakPoints[breakPoint];
  }

  onGridBreakpointChange(width: number, height: number): DayCellBreakPoint {
    let breakPoint: number = gridDayCellBreakPoints.length - 1;
    for (let i = 0; i < gridDayCellBreakPoints.length; i++) {
      const layout: DayCellBreakPoint = gridDayCellBreakPoints[i];
      if (width < layout.width) {
        breakPoint = i;
        break;
      }
    }
    while (breakPoint > 0 && gridDayCellBreakPoints[breakPoint].minHeight >= height) {
      breakPoint--;
    }
    breakPoint = breakPoint < 0 ? gridDayCellBreakPoints.length - 1 : breakPoint;
    // 查询不到,返回最后一个元素
    Log.info(TAG, `match gridDayCellBreakPoints index :${breakPoint}`);
    return gridDayCellBreakPoints[breakPoint];
  }

  // 不能直接等于,需要对值重新赋值
  updateDayLayout(bp: DayCellLayout) {
    this.prop.value.circleSize = bp.circleSize - (this.needSmall ? 4 : 0);
    this.prop.value.solarFontSize = bp.solarFontSize;
    this.prop.value.solarFontHeight = bp.solarFontHeight;
    this.prop.value.recessFontSize = bp.recessFontSize;
    this.prop.value.calOrHolFontSize = bp.calOrHolFontSize;
    this.prop.value.calOrHolFontHeight = bp.calOrHolFontHeight;
    this.prop.value.lunarLineWidth = bp.lunarLineWidth;
    this.prop.value.agendaPointSize = bp.agendaPointSize;
    this.prop.value.isVerticalCell = bp.isVerticalCell;
  }
}
