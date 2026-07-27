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

import { DEFAULT_FONT, PaintCache } from '@app/common/src/main/ets/graphic/PaintCache';
import { text } from '@kit.ArkGraphics2D';

// 自定义字体名称
export const fontName = 'fontName';
export class MonthPaintCache {

  private static _instance: MonthPaintCache = new MonthPaintCache();
  private agendaBlockFontCollection: text.FontCollection = new text.FontCollection();

  private constructor() {
    this.agendaBlockFontCollection.loadFontSync(fontName, `file://${PaintCache.instance().getFontFamilyPath()}`);
  }

  public static instance(): MonthPaintCache {
    return MonthPaintCache._instance;
  }

  /**
   * 日程块日程的字体集配置
   */
  loadFontSync(): void {
    this.agendaBlockFontCollection.unloadFontSync(fontName);
    const fontFamilyPath = PaintCache.instance().getFontFamilyPath();
    if (!fontFamilyPath.includes(DEFAULT_FONT)) {
      this.agendaBlockFontCollection.loadFontSync(fontName, `file://${fontFamilyPath}`);
    }
  }

  /**
   * 日程块日程的字体集配置
   */
  getAgendaBlockFontCollection(): text.FontCollection {
    return this.agendaBlockFontCollection;
  }
}