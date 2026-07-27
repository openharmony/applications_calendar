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
import { BigFontSize, DeviceConfig, FontSizeScaleUtils, CompId, Log } from '@app/common';


/**
 * 空内容
 *
 */
const TAG: string = 'EmptyContent';

@Component
export struct EmptyContent {

  @State antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //键盘规避
  @StorageProp('keyBoardHeight') keyBoardHeight: number = 0;

  @State isFromAgenda: boolean = false;

  // 用于判断是否需要动态变换边距
  private emptyAgendaListAvoid: boolean = DeviceConfig.instance().config.emptyAgendaListAvoid;

  getBottomPadding(keyBoardHeight: number): number {
    // 新建/编辑日程半模态已经适配了避让键盘，不需要再次避让
    if (!this.emptyAgendaListAvoid || this.isFromAgenda) {
      return 0;
    }
    const emptyBottomPadding = keyBoardHeight === 0 ? 0 : keyBoardHeight;
    return emptyBottomPadding;
  }

  aboutToAppear() {}

  build() {
    Column() {
      Image($r('app.media.ic_no_result'))
        .width(120)
        .height(120)
        .margin({
          bottom: $r('sys.float.padding_level4'),
        })
        .draggable(false)
        .edgeAntialiasing(this.antialiasingNumber)
      Text($r('app.string.search_no_content_text'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          20
        ))
        .fontColor($r('sys.color.font_secondary'))
    }
    .id(CompId.EMPTY_CONTAINER)
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .padding({ bottom: this.getBottomPadding(this.keyBoardHeight) })
  }
}