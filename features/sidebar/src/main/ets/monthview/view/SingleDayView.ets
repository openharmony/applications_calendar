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

import { SideBarMonthViewLayout } from '../model/SideBarMonthViewLayout';
import { SingleDayViewModel } from '../model/SingleDayViewModel';

// 使用系统组件进行绘制
const TAG = '[SingleDayView]';

@Component
export struct SingleDayView {
  // The way to respond to size changes needs to be optimized.
  @State layout: SideBarMonthViewLayout = SideBarMonthViewLayout.getInstance();

  @StorageProp('themeColor') themeColor: string = '';

  @ObjectLink dayViewModel: SingleDayViewModel;

  getLineOffset(): number {
    if (this.dayViewModel.isSelect || this.dayViewModel.isToday) {
      return this.layout.dayFontSize;
    } else {
      return this.layout.dayFontSize / 2;
    }
  }

  @Builder
  buildLunarLine() {
    Line()
      .strokeWidth(this.layout.dayFontSize)
      .height(this.dayViewModel.lunarLineWidth)
      .backgroundColor(this.themeColor)
      .offset({
        x: 0,
        y: this.getLineOffset()
      })
  }

  @Builder
  buildCircle() {
    Circle()
      .size({
        width: this.layout.selectCircle,
        height: this.layout.selectCircle
      })
      .fill(this.themeColor)
      .fillOpacity(this.dayViewModel.isToday ? 1 : 0)
      .strokeWidth(this.dayViewModel.isSelect ? 1 : 0)
      .stroke(this.themeColor)
      .zIndex(1);
  }

  build() {
    Stack() {
      Text(this.dayViewModel.day === -1 ? `` : this.dayViewModel.day.toString())// 无论判断条件是否变化，Text组件本身不会新建与销毁
        .fontSize(this.layout.dayFontSize)
        .fontColor(this.dayViewModel.isToday ? '#FFFFFF' : '#000000')
        .fontFamily('HarmonyHeiTi')
        .fontStyle(FontStyle.Normal)
        .fontWeight(FontWeight.Bold)
        .opacity(this.dayViewModel.opacity)
        .zIndex(2);
      if (this.dayViewModel.lunarLineWidth) {
        this.buildLunarLine()
      }
      if (this.dayViewModel.isToday || this.dayViewModel.isSelect) {
        this.buildCircle()
      }
    }
  }
}