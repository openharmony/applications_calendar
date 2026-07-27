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
import { MonthSwitchViewModel } from '../../viewModel/components/CarouselPanelViewModel';
import { CardAction } from '../../../common/CardAction';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG: string = '[MonthCard][CarouselPanel]';

@Component
export struct CarouselPanel {
  @ObjectLink viewModel: MonthSwitchViewModel;

  // 左箭头
  @Builder
  buildLeftArrow() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize('24vp')
        .fontColor([$r('app.color.red_common')])
    }
    .accessibilityText($r('app.string.accessibility_card_pre_month'))
    .width(30)
    .height(30)
    .responseRegion({ x: -10, width: 50 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      Log.info(TAG, `buildLeftArrow click left button`)
      this.viewModel.onButtonClick(this, CardAction.SWITCH_TO_PRE_MONTH);
    })
  }

  // 年、月
  @Builder
  buildTitle() {
    Row() {
      Text(this.viewModel.getDateText(this.viewModel.displayDate))
        .fontSize('sys.float.Subtitle_L')
        .maxFontScale(1)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.red_common'))
    }
    .accessibilityLevel('yes')
    .margin({ left: 24, right: 24 })
  }

  // 右箭头
  @Builder
  buildRightArrow() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontColor([$r('app.color.red_common')])
        .fontSize('24vp')
    }
    .accessibilityText($r('app.string.accessibility_card_next_month'))
    .width(30)
    .height(30)
    .responseRegion({ x: -10, width: 50 })
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      Log.info(TAG, `buildRightArrow click right button`)
      this.viewModel.onButtonClick(this, CardAction.SWITCH_TO_NEXT_MONTH);
    })
  }

  build() {
    Row() {
      this.buildLeftArrow();
      this.buildTitle();
      this.buildRightArrow();
    }
  }
}