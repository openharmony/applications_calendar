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

import { MonthStaticLayout } from '../layoutmodel/FrameLayoutRule';
import { MonthViewLayoutModel } from '../layoutmodel/MonthViewLayoutModel';
import { WeekNumViewModel } from '../viewmodel/WeekNumViewModel';
import { DayCellLayout } from '../layoutmodel/DayCellLayoutRule';
import { I18nUtil, NumberFormatManager } from '@app/common';

const TAG: string = '[MonthlyView][WeekNum]';

@Preview
@Component
export struct WeekNumView {
  // 周数 绑定的 周数数据模型
  @ObjectLink viewModel: WeekNumViewModel;

  @Consume innerShowWeekNumber: boolean;

  // 单天视图绑定的布局参数
  @State dayCellLayout: DayCellLayout = MonthViewLayoutModel.getInstance().dayLayout.value;

  @StorageProp('windowAvoidAreaNavigationRectHeight') navigationHeight: number = 0;

  //系统语言
  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  onLanguageChange() {
    NumberFormatManager.instance().onLanguageChange(this.language);
  }

  build() {
    Column() {
      if (this.innerShowWeekNumber) {
        ForEach(this.viewModel.weekNumbers, (weekNum: number) => {
          Column() {
            Text(NumberFormatManager.instance().numberFormat(weekNum).toString())
              .width('100%')
              .textAlign(TextAlign.Center)
              .align(Alignment.Center)
              .maxFontSize(Math.min(Math.max(this.dayCellLayout.solarFontSize - 4, 10), 12) + 'vp')
              .minFontSize('4vp')
              .fontColor($r('sys.color.font_tertiary'))
              .maxLines(1)
              .padding({ top: 1 })
              .fontWeight(FontWeight.Regular)
              .fontFamily('HarmonyHeiTi')
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .height(this.dayCellLayout.circleSize)
              .width(16)
              .accessibilityLevel('no')
              .flexShrink(1)
            if (I18nUtil.isChineseLanguage(this.language)) {
              Text($r('app.string.week_view'))
                .width('100%')
                .textAlign(TextAlign.Center)
                .align(Alignment.Center)
                .maxFontSize(Math.min(Math.max(this.dayCellLayout.solarFontSize - 4, 10), 12) + 'vp')
                .minFontSize('4vp')
                .fontColor($r('sys.color.font_tertiary'))
                .maxLines(1)
                .fontWeight(FontWeight.Regular)
                .fontFamily('HarmonyHeiTi')
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(16)
                .accessibilityLevel('no')
                .flexShrink(1)
                .offset({ y: -4 })
            }
          }
          .width(16)
          .layoutWeight(1)
        }, (weekNum: number) => weekNum.toString())
      }
    }
    .padding({
      top: (this.navigationHeight > 0 ? MonthStaticLayout.monthAvoidPadding : 8) +
      MonthStaticLayout.weekTitlePaddingBottom + MonthStaticLayout.weekTitleHeight + 1.5,
      bottom: 4,
    })
    .width(16)
    .height('100%')
  }
}