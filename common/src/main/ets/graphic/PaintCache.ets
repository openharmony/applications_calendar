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

import { LightWeightMap } from '@kit.ArkTS';
import { drawing, text } from '@kit.ArkGraphics2D';
import { FileUtils } from '../util/FileUtils';
import { Log } from '../default/common/Log';

const TAG = 'PaintCache';

export interface TextArg {
  text: string;
  fontSize: number;
  bold: boolean;
  fontFamily: string;
}

//THEME_PATH_ONE 标志位的路径，字体文件会在/data/themes/a/app和/data/themes/b/app来回存放
//例如当前字体文件存放于a目录下，flag文件也在a目录下，用户更换主题字体后，字体文件会存放在b目录下，flag文件移动到b目录下，
//flag表示字体文件存在于哪个目录下，flag文件只有一个
const THEME_FONT_FLAG_PATH_ONE = '/data/themes/a/app/flag';
const THEME_FONT_FLAG_PATH_TWO = '/data/themes/b/app/flag';

//当系统字体为默认字体时，
export const DEFAULT_FONT = 'defaultFont';


/**
 * 文本的起始点为 x轴 左对齐 y轴基线对齐，故
 * 中心点为 x轴 width / 2; y轴 0 - (metric.descent - metric.ascent) / 2;
 **/
export interface TextInfo {
  arg: TextArg;
  width: number;
  height: number;

  // 文字baseline距离文字底部的间距，设置文本y轴坐标时需设置其baseline值，不能设置bottom值
  baseline: number;
  centerY: number;
  centerX: number;
  blob: drawing.TextBlob;
}

export class PaintCache {
  private static _instance: PaintCache = new PaintCache();
  private path: drawing.Path = new drawing.Path();
  private brush: drawing.Brush = new drawing.Brush();
  private pen: drawing.Pen = new drawing.Pen();
  private fontCollection: text.FontCollection = new text.FontCollection();
  private paragraphStyle: text.ParagraphStyle = {}
  private graphBuilder: text.ParagraphBuilder = new text.ParagraphBuilder(this.paragraphStyle, this.fontCollection);
  private fontMap: LightWeightMap<string, drawing.Font> = new LightWeightMap();
  private textInfoMap: LightWeightMap<string, TextInfo> = new LightWeightMap();
  private fontFamilyMap: LightWeightMap<string, drawing.Typeface> = new LightWeightMap();
  private fontFamilyPath: string = '';

  public static instance(): PaintCache {
    return PaintCache._instance;
  }

  getBlobKey(arg: TextArg): string {
    return `${arg.fontSize}-${arg.bold}-${arg.text}-${arg.fontFamily}`;
  }

  getFont(arg: TextArg): drawing.Font {
    const key = `${arg.fontSize}-${arg.bold}`;
    if (this.fontMap.hasKey(key)) {
      return this.fontMap.get(key);
    }

    const font = new drawing.Font();
    font.enableEmbolden(arg.bold);
    font.setSize(arg.fontSize);
    font.enableSubpixel(true);
    this.fontMap.set(key, font);
    return font;
  }

  // 短期缓存控制策略，串长度小于10才设置缓存。具体规则后续根据实际情况调整。
  cacheRule(text: string): boolean {
    return text.length <= 10;
  }

  getText(arg: TextArg): TextInfo {
    const key = this.getBlobKey(arg);
    if (this.textInfoMap.hasKey(key)) {
      return this.textInfoMap.get(key);
    }

    const info = this.makeTextInfo(arg);

    if (this.cacheRule(arg.text)) {
      this.textInfoMap.set(key, info);
    }

    return info;
  }

  isInTextCache(arg: TextArg): boolean {
    const key = this.getBlobKey(arg);
    return this.textInfoMap.hasKey(key);
  }

  makeTextInfo(arg: TextArg): TextInfo {
    const font = this.getFont(arg);
    const width = font.measureText(arg.text, drawing.TextEncoding.TEXT_ENCODING_UTF8);
    const metric = font.getMetrics();
    // decent为正值，表示底部距离baseline的距离，ascent为负值，表示顶部距离baseline的距离，两者相减为文字的总高度
    const height = metric.descent - metric.ascent;

    const fontFamilyPath = arg.fontFamily;
    //设置fontFamily
    if (fontFamilyPath !== DEFAULT_FONT) { //default.ttf为默认字体，设置会报错，因此为默认字体时不设置该值
      // 如果 fontFamilyMap 的大小超过 15，则删除 5 个元素
      if (this.fontFamilyMap.length > 15) {
        const keys = Array.from(this.fontFamilyMap.keys());
        for (let i = 0; i < 5 && i < keys.length; i++) {
          if (fontFamilyPath !== keys[i]) {//当前使用的字体缓存不删除
            this.fontFamilyMap.remove(keys[i]);
          }
        }
      }
      if (!this.fontFamilyMap.hasKey(fontFamilyPath)) {
        Log.info(TAG, `fontFamilyName: ${fontFamilyPath.split('/').pop()}`);
        this.fontFamilyMap.set(fontFamilyPath, drawing.Typeface.makeFromFile(fontFamilyPath));
      }
      const typeFace = this.fontFamilyMap.get(fontFamilyPath);
      try {
        font.setTypeface(typeFace);
      } catch (error) {
        Log.logErrorMsg(TAG, `typeFace: ${typeFace}, fontFamilyName: ${fontFamilyPath.split('/').pop()}`, error);
      }
    }

    const info: TextInfo = {
      arg: arg,
      blob: drawing.TextBlob.makeFromString(arg.text, font),
      width: width,
      height: height,
      baseline: metric.descent,
      centerX: width / 2,
      centerY: metric.descent - height / 2,
    };
    return info;
  }

  setFontFamilyPath(path: string): void {
    this.fontFamilyPath = path;
  }

  getFontFamilyPath(): string {
    if (!this.fontFamilyPath) {
      const paths = [THEME_FONT_FLAG_PATH_ONE, THEME_FONT_FLAG_PATH_TWO];
      //判断字体文件是在a目录下还是b目录下
      for (const path of paths) {
        if (FileUtils.isFileExist(path)) {
          //字体文件存放在fonts目录下
          this.fontFamilyPath = this.checkAndReturnPath(path.replace(/\/flag$/, '/fonts'));
          return this.fontFamilyPath;
        }
      }
      this.fontFamilyPath = DEFAULT_FONT;
    }
    return this.fontFamilyPath;
  }

  /**
   * 判断是否存在字体ttf文件
   * default.ttf为默认字体，不能被读取，返回DEFAULT_FONT
   * @param path
   * @returns
   */
  checkAndReturnPath(path: string): string {
    if (FileUtils.isFileExist(path)) {
      const childFiles = FileUtils.getChildFiles(path);
      const ttfFile = childFiles.find(file => file.endsWith('.ttf'));
      if (ttfFile) {
        return ttfFile.startsWith('default') ? DEFAULT_FONT : `${path}/${ttfFile}`;
      }
    }
    return DEFAULT_FONT;
  }

  getBrush(): drawing.Brush {
    return this.brush;
  }

  getPen(): drawing.Pen {
    return this.pen;
  }

  getPath(): drawing.Path {
    return this.path;
  }

  getGraphBuilder(): text.ParagraphBuilder {
    return this.graphBuilder;
  }

}