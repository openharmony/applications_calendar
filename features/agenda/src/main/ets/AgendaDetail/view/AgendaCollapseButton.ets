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
import { BigFontSize, FontSizeScaleUtils } from '@app/common';
import { AgendaCollapseStateRecord } from '../../helpers/AgendaCollapseStateRecord';

/**
 * 日程详情折叠按钮
 */
@Component
export struct AgendaCollapseButton {

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  eventUuid: string = '';

  @Link isCollapse: boolean;

  aboutToAppear(): void {
    this.isCollapse = AgendaCollapseStateRecord.instance().query(this.eventUuid);
  }

  build() {
    Column() {
      Row() {
        Text(this.isCollapse ? $r('app.string.expand_more_info') : $r('app.string.collapse_more_info'))
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_secondary'))
          .constraintSize({
            maxWidth: '90%'
          })
          .maxLines(2)

        SymbolGlyph(this.isCollapse ? $r('sys.symbol.chevron_down') : $r('sys.symbol.chevron_up'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .flexShrink(1)
      }
    }
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .onClick(()=>{
      this.isCollapse = !this.isCollapse;
      AgendaCollapseStateRecord.instance().record(this.eventUuid, this.isCollapse);
    })
  }
}