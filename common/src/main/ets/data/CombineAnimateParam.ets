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

import { CalendarDate } from '../date/CalendarDate';
import { MONTH_PER_YEAR } from '../util/DateUtil';

// 关联动效参数类 用于转场动效中Combine动效参数设定
@Observed
export class CombineAnimateParam {
  visibility: boolean = false;
  opacity: number = 0;
  opacityAnimateParam: AnimateParam = {};
  translateOptions?: TranslateOptions = { x: 0, y: 0, z: 0 };
  translateAnimateParam?: AnimateParam = {};
  scaleOption?: ScaleOptions = {
    x: 0,
    y: 0,
    centerX: 0,
    centerY: 0
  };
  scaleAnimateParam?: AnimateParam = {};
}

// 用于年视图缩放的动效参数
export class YearAnimateParam {
  public componentWidth: number = 0; // 用于初始化的当前组件宽高
  public componentHeight: number = 0; // 用于初始化的当前组件宽高
  public centerX: number = 0;
  public centerY: number = 0;

  private nowDisplayMonth: number = 0;


  // 计算当前动效缩放的坐标
  changeYearAnimationParam(displayDate: number,
                           rowCount: number, rowMinHeight : number, scaleUpdate: boolean = false) {
    const displayDateMonth = new CalendarDate(displayDate).getMonth(); // 当前月份
    if (!scaleUpdate && this.nowDisplayMonth === displayDateMonth) {
      return;
    }
    this.nowDisplayMonth = displayDateMonth;
    const componentWidth = this.componentWidth; // 当前年视图组件宽度
    const componentHeight = this.componentHeight; // 当前年视图组件高度
    const widthX = Math.round(componentWidth / rowCount); // 计算每一月的宽度
    const nowCountX = (displayDateMonth % rowCount) + 0.5; // 计算当前时间月份对应的X等分值
    const centerX = nowCountX * widthX; // 获取当前时间月份的中点X坐标
    const heightY = Math.max(Math.round(componentHeight / (MONTH_PER_YEAR / rowCount)), rowMinHeight); // 计算每一月的高度
    const nowCountY = Math.floor((displayDateMonth) / rowCount) + 0.5; // 计算当前时间月份对应的Y等分值
    const centerY = nowCountY * heightY; // 获取当前时间月份的中点Y坐标

    this.centerX = centerX; // 将获取到的值传给动效参数中
    this.centerY = centerY;
  }
}