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
import { BigFontSize } from '../constants/BigFontSize';
import { Log } from '../default/common/Log';

const TAG: string = 'FontSizeScaleUtils';

/**
 * 大字体工具类
 */
export class FontSizeScaleUtils {
  public static isGreaterThanStandard(fontSizeScale: number): boolean {
    // 判断是否为 标准 大字体模式
    return fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  public static isGreaterThan2X(fontSizeScale: number): boolean {
    // 判断是否为 2倍 大字体模式
    return fontSizeScale > BigFontSize.BIG_FONT_SIZE_SCALE_2X;
  }

  public static isGreaterThanSpecial(fontSizeScale: number): boolean {
    // 判断是否为 特殊 大字体模式
    return fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL;
  }


  /**
   * 获取大字体下的高度 number类型返回
   * @param fontSizeScale 大字体尺寸
   * @param maxScale 尺寸限制
   * @param defSize 默认的大小
   * @returns 以number类型返回的组件高度
   */
  public static getLimitHeightNum(fontSizeScale: number | undefined, maxScale: number, defSize: number): number {
    if (!fontSizeScale) {
      Log.error(TAG, 'fontSizeScale is undefined in getLimitHeightNum!')
      return defSize;
    }
    return fontSizeScale > maxScale ? defSize * maxScale : defSize * fontSizeScale;
  }

  /**
   * 获取大字体下的高度 vp 类型返回
   * @param fontSizeScale 大字体尺寸
   * @param maxScale 尺寸限制
   * @param defSize 默认的大小
   * @returns 以 vp 类型返回的组件高度
   */
  public static getLimitHeightVp(
    fontSizeScale: number | undefined,
    maxScale: number,
    defSize: number
  ): string {
    if (!fontSizeScale) {
      Log.error(TAG, 'fontSizeScale is undefined in getLimitHeightVp!')
      return '';
    }
    const limitHeight: number = FontSizeScaleUtils.getLimitHeightNum(fontSizeScale, maxScale, defSize);
    return `${limitHeight}vp`;
  }

  /**
   * 获取大字体下的尺寸 vp 类型返回 , 对于页面上一些场景，按照规范UX要求字体最大放大倍数限制为2倍或1.75倍
   * @param fontSizeScale 大字体尺寸
   * @param maxScale 尺寸限制
   * @param defSize 默认的大小
   * @returns 以 vp 类型返回的组件尺寸
   */
  public static getLimitFontSizeVp(
    fontSizeScale: number | undefined,
    maxScale: number,
    defSize: number | undefined
  ): string {
    if (!fontSizeScale) {
      Log.error(TAG, 'fontSizeScale is undefined in getLimitFontSizeVp!')
      return '';
    }
    if (!defSize) {
      Log.error(TAG, 'defSize is undefined in getLimitFontSizeVp!')
      return '';
    }
    return fontSizeScale > maxScale ? `${defSize * maxScale}vp` : `${defSize * fontSizeScale}vp`;
  }

  /**
   * 获取大字体下的尺寸 number 类型返回 , 对于页面上一些场景，按照规范UX要求字体最大放大倍数限制为2倍或1.75倍
   * @param fontSizeScale 大字体尺寸
   * @param maxScale 尺寸限制
   * @param defSize 默认的大小
   * @returns 以 number 类型返回的组件尺寸
   */
  public static getLimitFontSizeNum(
    fontSizeScale: number | undefined,
    maxScale: number,
    defSize: number | undefined
  ): number {
    if (!defSize) {
      Log.error(TAG, 'defSize is undefined in getLimitFontSizeNum!')
      return 0;
    }
    if (!fontSizeScale) {
      Log.error(TAG, 'fontSizeScale is undefined in getLimitFontSizeNum!')
      return defSize;
    }
    return fontSizeScale > maxScale ? defSize * maxScale : defSize * fontSizeScale;
  }

  public static fontSizeNumToVp(fontSize: number): string {
    return fontSize + 'vp';
  }

  public static getNormalBigFontSizeInterval(fontSizeScale: number, def: number = 12) {
    return fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_3X ? 24 :
      fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_2X ? 20 :
        fontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE ? 16 : def;
  }

  /**
   * 大字体按钮上下间距
   * @param nowFontSizeScale 自定义最大放大倍数（限制最大倍数情况下使用）
   * @param def 默认上下间距
   * @returns
   */
  public static buttonInterval(def: number, nowFontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD) {
    if (nowFontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE_3X) {
      return 8;
    } else if (nowFontSizeScale >= BigFontSize.BIG_FONT_SIZE_SCALE) {
      return 4;
    } else {
      return def;
    }
  }

  /**
   * 针对情感化卡片做单独适配
   * @param fontSizeScale 系统字体大小
   * @param def 默认上下间距
   * @returns 间距
   */
  public static getEveryGearPadding(fontSizeScale: number, def: number) {
    return fontSizeScale >= BigFontSize.BIG_FONT_SIZE_TWO ? 8 : fontSizeScale >= BigFontSize.BIG_FONT_SIZE ? def : 16;
  }
}