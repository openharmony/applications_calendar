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
import { I18nUtil } from '../I18nUtil';
import { HashMap } from '@kit.ArkTS';
import { Log } from '../../default/common/Log';
import { common2D, text } from '@kit.ArkGraphics2D';

const TAG: string = `TextParagraphManager`;

/**
 * TextParagraphManager
 * 用于存储特殊文本的文本对象，如特殊语言的绘制工作
 */
export class TextParagraphManager {
  private static _instance: TextParagraphManager = new TextParagraphManager();
  public static instance(): TextParagraphManager {
    return TextParagraphManager._instance;
  }

  private _language : string = ''
  constructor() {
    this._language = I18nUtil.getSystemLanguage();
  }

  public onLanguageChange(language : string) {
    if (this._language === language) {
      return;
    }
    this._language = language;
    this._paragraphCacheMap.clear();
  }

  private buildParagraphGraph(dayText: string, color: common2D.Color, fontSize:number = 10): text.Paragraph {
    let myTextStyle: text.TextStyle = {
      fontSize: vp2px(fontSize),
      color: color,
      fontWeight: 5
    };
    let myParagraphStyle: text.ParagraphStyle = {
      textStyle: myTextStyle,
      align: text.TextAlign.JUSTIFY
    };
    let fontCollection = new text.FontCollection();
    let paragraphGraphBuilder = new text.ParagraphBuilder(myParagraphStyle, fontCollection);
    paragraphGraphBuilder.pushStyle(myTextStyle);
    let tagText: string = dayText;
    paragraphGraphBuilder.addText(tagText);
    return paragraphGraphBuilder.build();
  }

  private _paragraphCacheMap: HashMap<string, text.Paragraph> = new HashMap<string, text.Paragraph>()

  getTextParagraph(text: string, width: number, color: common2D.Color, fontSize?: number) {
    const key = text + `_${width}_${color.alpha}_${color.red}_${color.green}_${color.blue}_${fontSize}`;
    let paragraph = this._paragraphCacheMap.get(key);
    if (!paragraph) {
      paragraph = this.buildParagraphGraph(text, color, fontSize);
      paragraph.layoutSync(width + 2);
      this._paragraphCacheMap.set(key, paragraph);
      Log.info(TAG, `paragraphCacheMap length:${this._paragraphCacheMap.length}`);
    }
    return paragraph;
  }
}