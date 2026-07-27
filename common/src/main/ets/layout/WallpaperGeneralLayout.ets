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

/**
 * 通用背板样式
 */
export class WallpaperBoardModifierLayout {
  /**
   * 抽取公共背板样式
   * @param instance
   */
  public static decorateAttribute(instance: ColumnAttribute) {
    instance
      .backdropBlur(50) // 背板模糊半径：50
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.1)' }) // 外阴影：12 'rgba(0,0,0,0.1)'
      .backgroundColor('#26ffffff')
      .backgroundBrightness({ rate: 5, lightUpDegree: 300 }) // 背景提亮效果
  }
}

/**
 * 台历模式下的透明度板式
 */
export enum WallpaperOpacity {
  ALPHA_LEVEL_1 = 'ff', // 100
  ALPHA_LEVEL_2 = 'e6', // 90
  ALPHA_LEVEL_3 = 'cc', // 80
  ALPHA_LEVEL_4 = '99', // 60
  ALPHA_LEVEL_5 = '66', // 40
  ALPHA_LEVEL_6 = '33', // 20
}

/**
 * WallpaperColorMap
 * 用于存储台历模式下的色板，后续用于处理不同色板
 */
export class WallpaperColorMap {
  private static _instance: WallpaperColorMap = new WallpaperColorMap();

  public static instance(): WallpaperColorMap {
    return WallpaperColorMap._instance;
  }

  private _sourceColor: string = 'fffefe'; // 假设不包含透明度和#前缀 // '#99fffefe'

  constructor(sourceColor?: string) {
    if (sourceColor) {
      this._sourceColor = sourceColor;
    }
  }

  /**
   * 设置色板主题色
   * @param sourceColor 色板源色
   */
  public setSourceColor(sourceColor?: string) {
    if (sourceColor && this._sourceColor !== sourceColor) {
      this._sourceColor = sourceColor;
    }
  }

  private formatColor(alpha: string): string {
    // 检查_sourceColor是否包含#前缀
    if (this._sourceColor.startsWith('#')) {
      return this._sourceColor;
    }
    // 检查_sourceColor是否包含透明度
    if (this._sourceColor.length === 8) {
      return `#${this._sourceColor}`;
    }
    // 拼接为#rrggbbaa格式
    return `#${alpha}${this._sourceColor}`;
  }

  /**
   * 获取台历颜色颜色
   * @param opacity 台历透明度
   * @returns
   */
  public getColorWithOpacity(opacity: WallpaperOpacity): string {
    return this.formatColor(opacity);
  }
}