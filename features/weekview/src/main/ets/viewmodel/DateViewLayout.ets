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

import { Log, SingleInstanceHelper } from '@app/common';

const TAG: string = 'DateViewLayout';

interface dateCellBreakPoint {
  width: number,
  layout: layout
}

interface layout {
  weekTitleFontSize: number,
  solarDateFontSize: number,
  agendaDotRadius: number,
  extraInfoFontSize: number,
  selectMaxCircleRadius: number,
  selectMinCircleRadius: number,
  extraInfoCharCodeWidth: number,
  extraInfoHeight: number,
}

// 布局管理器，支持多个版本不同设备形态的布局
export class DateViewLayoutManager {
  public dateCellBreakPoint: dateCellBreakPoint[] = [
    {
      width: 280,
      layout: {
        solarDateFontSize: 12,
        extraInfoFontSize: 6,
        weekTitleFontSize: 10,
        selectMaxCircleRadius: 16,
        selectMinCircleRadius: 16,
        agendaDotRadius: 1,
        extraInfoCharCodeWidth: 5,
        extraInfoHeight: 8,
      }
    },
    {
      width: 340,
      layout: {
        solarDateFontSize: 14,
        extraInfoFontSize: 8,
        weekTitleFontSize: 10,
        selectMaxCircleRadius: 20,
        selectMinCircleRadius: 20,
        agendaDotRadius: 1,
        extraInfoCharCodeWidth: 7,
        extraInfoHeight: 10,
      }
    },
    {
      width: 480,
      layout: {
        solarDateFontSize: 18,
        extraInfoFontSize: 10,
        weekTitleFontSize: 12,
        selectMaxCircleRadius: 25,
        selectMinCircleRadius: 23,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 9,
        extraInfoHeight: 12,
      }
    },
    {
      width: 600,
      layout: {
        solarDateFontSize: 20,
        extraInfoFontSize: 10,
        weekTitleFontSize: 12,
        selectMaxCircleRadius: 28,
        selectMinCircleRadius: 24,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 9,
        extraInfoHeight: 12,
      }
    },
    {
      width: 740,
      layout: {
        solarDateFontSize: 18,
        extraInfoFontSize: 10,
        weekTitleFontSize: 12,
        selectMaxCircleRadius: 25,
        selectMinCircleRadius: 23,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 9,
        extraInfoHeight: 12,
      }
    },
    {
      width: 840,
      layout: {
        solarDateFontSize: 20,
        extraInfoFontSize: 10,
        weekTitleFontSize: 12,
        selectMaxCircleRadius: 28,
        selectMinCircleRadius: 24,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 9,
        extraInfoHeight: 12,
      }
    },
    {
      width: 960,
      layout: {
        solarDateFontSize: 22,
        extraInfoFontSize: 12,
        weekTitleFontSize: 14,
        selectMaxCircleRadius: 31,
        selectMinCircleRadius: 26,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 11,
        extraInfoHeight: 14,
      }
    },
    {
      width: 1200,
      layout: {
        solarDateFontSize: 24,
        extraInfoFontSize: 12,
        weekTitleFontSize: 14,
        selectMaxCircleRadius: 35,
        selectMinCircleRadius: 29,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 11,
        extraInfoHeight: 14,
      }
    },
    {
      width: 99999,
      layout: {
        solarDateFontSize: 26,
        extraInfoFontSize: 14,
        weekTitleFontSize: 14,
        selectMaxCircleRadius: 36,
        selectMinCircleRadius: 30,
        agendaDotRadius: 1.5,
        extraInfoCharCodeWidth: 13,
        extraInfoHeight: 16,
      }
    },
  ];

  constructor() {
  }

  static getInstance(): DateViewLayoutManager {
    return SingleInstanceHelper.createOrGet(DateViewLayoutManager, 'DateViewLayoutManager');
  }

  init() {
  }

  // 根据宽度获取日期断点
  getDateCellBreakPoint(width: number): number | undefined {
    try {
      for (let i = 0; i < this.dateCellBreakPoint.length; i++) {
        const layout: dateCellBreakPoint = this.dateCellBreakPoint[i];
        if (width <= layout.width) {
          return i;
        }
      }
      return this.dateCellBreakPoint.length - 1;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getDateCellBreakPoint', err);
    }
    return undefined;
  }
}