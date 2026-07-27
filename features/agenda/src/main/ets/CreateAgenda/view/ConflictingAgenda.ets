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

import { AgendaEventInfo, AgendaListItemViewModel, DeviceConfig, FontSizeScaleUtils, GlobalThis, Log } from '@app/common';
import { AgendaListItemContent } from '../../AgendaDetail/view/AgendaListItemContent';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'ConflictingAgenda'

/**
 * 冲突日程气泡
 */
@Component
export struct ConflictingAgenda {
  @Link agendaList: AgendaEventInfo[];

  @StorageLink('language') @Watch('getButtonText') language: string = '';

  @State handlePopup: boolean = false;

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  private popWidth: number = DeviceConfig.instance().config.deviceLayout.conflictingAgendaPopUpWidth;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonRadius: Resource =
    this.needCommerce ? $r('sys.float.ohos_id_corner_radius_default_s') : $r('sys.float.corner_radius_level10')

  private readonly WINDOW_MARGIN: number = 16;

  private popScroller: Scroller = new Scroller();

  aboutToAppear() {
  }

  getButtonText() {
    return GlobalThis.getPluralStr($r('app.plural.conflicting_agendas'), this.agendaList.length, this.language);
  }

  @Builder
  popupBuilder() {
    Row(){
      List({ space: 8, scroller: this.popScroller }) {
        ForEach(this.agendaList, (agenda: AgendaListItemViewModel) => {
          ListItem() {
            AgendaListItemContent({
              info: agenda,
              isConflictingAgenda: true
            })
          }
        })
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
      .margin({
        start: LengthMetrics.vp(12),
        top: LengthMetrics.vp(12),
        bottom: LengthMetrics.vp(12),
      })
      .scrollBar(BarState.Off)
      .width('calc(100% - 24vp)')
      .constraintSize({ maxHeight: 300 })

      ScrollBar({ scroller: this.popScroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .width(12)
        .height(this.agendaList.length * 72)
        .constraintSize({ maxHeight: 300 })
        .margin({
          top: $r('sys.float.padding_level6'),
          bottom: $r('sys.float.padding_level6'),
        })
    }
  }

  build() {
    Button({ type: ButtonType.Normal }) {
      Text(this.getButtonText())
        .fontSize(FontSizeScaleUtils.fontSizeNumToVp(14))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .margin({ left: 12, right: 12 })
    }
    .height(32)
    .borderRadius(this.buttonRadius)
    .onClick(() => {
      const windowWidth = this.windowWidth;
      this.popWidth = DeviceConfig.instance().config.deviceLayout.conflictingAgendaPopUpWidth;
      if (windowWidth - this.WINDOW_MARGIN < this.popWidth) {
        this.popWidth = windowWidth - this.WINDOW_MARGIN;
      }
      this.handlePopup = true;
    })
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .bindPopup(this.handlePopup, {
      builder: this.popupBuilder,
      popupColor: $r('sys.color.ohos_id_color_panel_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      radius: 20,
      width: this.popWidth,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      enableArrow: true,
      onStateChange: (event) => {
        Log.info(TAG, `popup isVisible = ${event.isVisible}`);
        if (!event.isVisible) {
          this.handlePopup = false
        }
      }
    })
  }
}
