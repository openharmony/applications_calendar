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

import { Log } from '../default/common/Log';

const TAG: string = '[Bp2D]';

export interface BreakPoint2D {
  width: number;
  height: number;
}

// 二维断点匹配器
export class BreakPoint2DHelper {
  private breakPoint2Ds: BreakPoint2D[] = []
  private colBreakPoints: number[] = [];
  private rowBreakPoints: number[] = [];

  init(breakPoint2Ds: BreakPoint2D[]) {
    Log.info(TAG, `init start`);
    this.unInit();
    this.breakPoint2Ds = breakPoint2Ds;
    this.initBreakPoint2D();
    Log.info(TAG, `init end`);
  }

  unInit() {
    Log.info(TAG, `unInit start`);
    this.breakPoint2Ds = [];
    this.colBreakPoints = [];
    this.rowBreakPoints = [];
    Log.info(TAG, `unInit end`);
  }

  /*
  return: the best breakpoint index
  *
   * */
  public match(curWidth: number, curHeight: number): number {
    Log.info(TAG, `match start ${curWidth},${curHeight}`);
    const bpCount = this.rowBreakPoints.length;
    if (bpCount === 0) {
      return -1;
    }
    let leftWidth: number = this.rowBreakPoints[0];
    let rightWidth: number = this.rowBreakPoints[0];
    for (let i = 0; i < bpCount; ++i) {
      if (this.rowBreakPoints[i] < curWidth) {
        leftWidth = this.rowBreakPoints[i];
      }
      if (this.rowBreakPoints[i + 1] >= curWidth) {
        rightWidth = this.rowBreakPoints[i + 1];
        break;
      }
    }
    let topHeight: number = this.colBreakPoints[0];
    let bottomHeight: number = this.colBreakPoints[0];
    for (let i = 0; i < bpCount; ++i) {
      if (this.colBreakPoints[i] < curWidth) {
        bottomHeight = this.colBreakPoints[i];
      }
      if (this.colBreakPoints[i + 1] >= curWidth) {
        topHeight = this.colBreakPoints[i + 1];
        break;
      }
    }

    let targetIndex = 0;
    let minDis: number = Number.MAX_VALUE;
    for (let index = 0; index < bpCount; ++index) {
      let width = this.breakPoint2Ds[index].width;
      let height = this.breakPoint2Ds[index].height;
      if (width === leftWidth || width === rightWidth || height === topHeight || height === bottomHeight) {
        const dis = Math.pow(curWidth - width, 2) + Math.pow(curHeight - height, 2);
        if (dis < minDis) {
          minDis = dis;
          targetIndex = index;
        }
      }
    }
    Log.info(TAG, `targetIndex:${targetIndex} width: ${this.breakPoint2Ds[targetIndex].width}, height: ${this.breakPoint2Ds[targetIndex].height}`);
    return targetIndex;
  }

  private initBreakPoint2D() {
    for (let index = 0; index < this.breakPoint2Ds.length; ++index) {
      let item = this.breakPoint2Ds[index];
      this.colBreakPoints.push(item.height);
      this.rowBreakPoints.push(item.width);
    }

    this.colBreakPoints.sort((a, b) => a - b);
    this.rowBreakPoints.sort((a, b) => a - b);
  }
}