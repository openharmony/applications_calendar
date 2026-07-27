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

import { SingleMonthViewModel } from '../model/SingleMonthViewModel';
import { MonthDaysView } from './MonthDaysView';
import { componentUtils, LengthMetrics } from '@kit.ArkUI';
import { CompId } from '@app/common';

const TAG = "[SideBar][SingleMonthView]";

@Component
export struct SingleMonthView {
  @Prop displayMonth: number = 0; // only init by OneYearView

  @State layout: SideBarMonthViewLayout = SideBarMonthViewLayout.getInstance();

  @ObjectLink viewModel: SingleMonthViewModel;

  private dayArray: number[] = Array.from(new Array<number>(SingleMonthViewModel.dayItemCount))

  dateSelected: Function = (displayMills: number) => {
  };

  aboutToAppear() {
    for (let index = 0; index < SingleMonthViewModel.dayItemCount; ++index) {
      this.dayArray.push(index);
    }
  }

  @Builder
  buildCanvasDaysView() {
    MonthDaysView(
      {
        monthViewModel: this.viewModel
      }
    )
  }

  build() {
    Column() {
      this.buildCanvasDaysView();
    }
    .onClick((event) => {
      let clickDisplayMills = -1;
      const clickX = event.x;
      const clickY = event.y;
      clickDisplayMills = this.viewModel.getClickDisplayMills(clickX, clickY);
      this.dateSelected(clickDisplayMills);
    })
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .width('100%')
    .height('100%')
    .padding({ top: this.layout.monthPaddingTop })
  }
}