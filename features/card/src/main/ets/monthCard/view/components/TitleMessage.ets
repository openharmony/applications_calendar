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
import { CardUiUtils } from '../../../utils/CardUiUtils';
import { WeekTitleLayout } from '../../layout/MonthCardLayout';
import { SimpleMonthViewModel } from '../../viewModel/components/monthVM/SimpleMonthViewModel';

const TAG: string = '[MonthCard][TitleMessage]';

@Component
export struct TitleMessage {
  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  @ObjectLink viewModel: SimpleMonthViewModel;

  @Prop layoutModel: WeekTitleLayout;

  @Prop lunarDateStr: string;

  getFontSize() {
    const daySize = (this.layoutModel?.titleFontSize ?? 6) - (this.isSmallUp ? 2 : 0);
    return daySize + 2;
  }

  build() {
    Row() {
      Text(CardUiUtils.getMonthTitle(this.viewModel.displayDate.getMonth()))
        .fontColor($r('app.color.red_common'))
        .fontSize(this.getFontSize())
        .maxFontScale(1)
        .fontWeight(FontWeight.Bold)
        .margin({
          left: 5,
          right: 4
        })

      Text(this.lunarDateStr)
        .fontColor($r('sys.color.font_primary'))
        .fontSize(this.getFontSize())
        .maxFontScale(1)
        .fontWeight(FontWeight.Bold)
        .opacity($r('sys.float.alpha_secondary'))
    }
    .width('100%')
  }
}