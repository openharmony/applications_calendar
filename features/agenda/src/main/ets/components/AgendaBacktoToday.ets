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

import { ARABIC_LANGUAGE, CompId, I18nUtil, NumberFormatManager } from '@app/common';

@Component
export struct AgendaBackToToday {
  // 按钮中心日期
  @Prop dayText: string = '';

  // 系统地区
  @StorageProp('systemRegion') systemRegion: string = 'CN';

  @StorageLink('themeColor') themeColor: string = '';

  @StorageProp('language') @Watch('onLanguageChange') language: string = 'zh';

  @State isChineseLanguage: boolean = I18nUtil.isChineseLanguage(this.language);

  @State isAR:boolean = this.language.includes(ARABIC_LANGUAGE);

  onLanguageChange() {
    this.isAR = this.language.includes(ARABIC_LANGUAGE);
    NumberFormatManager.instance().onLanguageChange(this.language);
    this.isChineseLanguage = I18nUtil.isChineseLanguage(this.language);
    this.dayText = NumberFormatManager.instance().numberFormat(new Date().getDate());
  }

  build() {
    Stack() {
      Row()
        .height(48)
        .width(48)
        .borderRadius(24)
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .shadow({ radius: 24, color: '#0f000000', offsetY: 24 })
      if (this.systemRegion === 'CN' && this.isChineseLanguage) { // TODO
        Text('今')
          .fontColor(this.themeColor)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
      } else {
        Image($r('app.media.ic_public_go_back_today'))
          .height(24)
          .width(24)
          .draggable(false)
          .fillColor(this.themeColor)
        Text(this.dayText)
          .fontColor(this.themeColor)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .height(48)
          .width(48)
          .position({ y: 3 })
      }
    }
    .width(48)
    .height(48)
    .onClick(() => {
      this.onBackToToday();
    })
    .id(CompId.BACK_TO_TODAY)
  }

  // 点击事件
  private onBackToToday: () => void = () => {
  };
}