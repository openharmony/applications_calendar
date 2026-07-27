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
import { common2D } from '@kit.ArkGraphics2D';
import { Log } from '../default/common/Log';

const TAG: string = '[PaletteCache]';
//16进制表示rgb颜色 长度为7位 #FF164E
const rgbHexLength: number = 7;
//16进制表示argb颜色 长度为9位 #FF26AB3E
const argbHexLength: number = 9;

export enum ColorType {
  THEME, // 主题红 100% 透明度主题红
  THEME_OPACITY_60, // 60% 透明度主题红
  THEME_OPACITY_40, // 40% 透明度主题红
  THEME_OPACITY_10, // 20% 透明度主题红

  BLUE, // 蓝色 100% 透明度
  BLUE_OPACITY_60, // 60% 透明度蓝色
  BLUE_OPACITY_40, // 40% 透明度蓝色

  PRIMARY, // 一级文本颜色
  PRIMARY_CONTRARY, // 一级文本反色
  SECONDARY, // 二级文本颜色
  SECONDARY_CONTRARY, // 二级文本反色
  TERTIARY, // 三级文本颜色
  TERTIARY_OPACITY_60, // 三级文本60透明度
  TERTIARY_OPACITY_40, // 三级文本40透明度
  TEXT_OPACITY_90, // 0.9 透明度文本色
  RECESSCIRCLE, // 班休背景圈颜色
  DARK_RECESSCIRCLE, // 班休背景圈颜色反色
  RECESS_CIRCLE_BIG, // 大屏班休背景圈颜色
  DARK_RECESS_CIRCLE_BIG, // 大屏班休背景圈颜色反色
}

export class PaletteCache {
  private static _instance: PaletteCache = new PaletteCache();
  // 普通配色表
  private normalColorMap: LightWeightMap<ColorType, common2D.Color> = new LightWeightMap();
  // 深色模式背景表
  private darkModeColorMap: LightWeightMap<ColorType, common2D.Color> = new LightWeightMap();
  private colorMap: LightWeightMap<ColorType, common2D.Color> = new LightWeightMap();

  private readonly RECESSCIRCLE: common2D.Color = {
    alpha: 255,
    red: 241,
    green: 243,
    blue: 245
  };

  private readonly DARK_RECESSCIRCLE: common2D.Color = {
    alpha: 255,
    red: 0,
    green: 0,
    blue: 0
  };

  // 大屏班休适配背景色
  private readonly RECESS_CIRCLE_BIG: common2D.Color = {
    alpha: 255,
    red: 255,
    green: 255,
    blue: 255
  };

  // 大屏班休适配深色模式背景色
  private readonly DARK_RECESS_CIRCLE_BIG: common2D.Color = {
    alpha: 255,
    red: 25,
    green: 25,
    blue: 25
  };

  // 普通模式
  // 一级文本颜色 ohos_id_color_text_primary_contrary #182431
  private readonly PRIMARY: common2D.Color = {
    alpha: 255,
    red: 24,
    green: 36,
    blue: 49
  };
  // 一级文本反色 ohos_id_color_text_primary_contrary #FFFFFF
  private readonly PRIMARY_CONTRARY: common2D.Color = {
    alpha: 255,
    red: 255,
    green: 255,
    blue: 255
  };
  // 二级文本颜色 ohos_id_color_text_secondary_contrary #182431
  private readonly SECONDARY: common2D.Color = {
    alpha: 153,
    red: 24,
    green: 36,
    blue: 49
  };
  // 二级文本反色 ohos_id_color_text_secondary_contrary #FFFFFF
  private readonly SECONDARY_CONTRARY: common2D.Color = {
    alpha: 153,
    red: 255,
    green: 255,
    blue: 255
  };
  // 三级文本颜色 ohos_id_color_text_tertiary #66182431
  private readonly TERTIARY: common2D.Color = {
    alpha: 102,
    red: 0,
    green: 0,
    blue: 0
  };
  // 三级文本颜色 透明度*0.4 ohos_id_color_text_tertiary #66182431 实际透明度0.24
  private readonly TERTIARY_OPACITY_60: common2D.Color = {
    alpha: 41,
    red: 24,
    green: 36,
    blue: 49
  };
  // 三级文本颜色 透明度*0.4 ohos_id_color_text_tertiary #66182431 实际透明度0.16
  private readonly TERTIARY_OPACITY_40: common2D.Color = {
    alpha: 41,
    red: 24,
    green: 36,
    blue: 49
  };
  // 弱化一级文本色 0.9透明度 #E5182431
  private readonly TEXT_OPACITY_90: common2D.Color = {
    alpha: 229,
    red: 24,
    green: 36,
    blue: 49
  };
  // 深色模式
  // 一级文本颜色 ohos_id_color_text_primary_contrary #182431
  private readonly DARK_PRIMARY: common2D.Color = {
    alpha: 229,
    red: 255,
    green: 255,
    blue: 255
  };
  // 一级文本反色 ohos_id_color_text_primary_contrary #FFFFFF
  private readonly DARK_PRIMARY_CONTRARY: common2D.Color = {
    alpha: 255,
    red: 229,
    green: 229,
    blue: 229
  };
  // 二级文本颜色 ohos_id_color_text_secondary_contrary #182431
  private readonly DARK_SECONDARY: common2D.Color = {
    alpha: 153,
    red: 255,
    green: 255,
    blue: 255
  };
  // 二级文本反色 ohos_id_color_text_secondary_contrary #FFFFFF
  private readonly DARK_SECONDARY_CONTRARY: common2D.Color = {
    alpha: 153,
    red: 229,
    green: 229,
    blue: 229
  };
  // 三级文本颜色 ohos_id_color_text_tertiary #66182431
  private readonly DARK_TERTIARY: common2D.Color = {
    alpha: 102,
    red: 255,
    green: 255,
    blue: 255
  };
  // 三级文本颜色 透明度*0.4 ohos_id_color_text_tertiary #66182431 实际透明度0.24
  private readonly DARK_TERTIARY_OPACITY_60: common2D.Color = {
    alpha: 61,
    red: 255,
    green: 255,
    blue: 255
  };
  // 三级文本颜色 透明度*0.4 ohos_id_color_text_tertiary #66182431 实际透明度0.16
  private readonly DARK_TERTIARY_OPACITY_40: common2D.Color = {
    alpha: 41,
    red: 255,
    green: 255,
    blue: 255
  };
  // 弱化一级文本色 0.9透明度 #E5182431
  private readonly DARK_TEXT_OPACITY_90: common2D.Color = {
    alpha: 229,
    red: 255,
    green: 255,
    blue: 255
  };
  // 主题色 #F76045
  private readonly THEME: common2D.Color = {
    alpha: 255,
    red: 247,
    green: 96,
    blue: 69
  };
  private readonly THEME_OPACITY_60: common2D.Color = {
    alpha: 153,
    red: 247,
    green: 96,
    blue: 69
  };
  private readonly THEME_OPACITY_40: common2D.Color = {
    alpha: 102,
    red: 247,
    green: 96,
    blue: 69
  };

  private readonly THEME_OPACITY_20: common2D.Color = {
    alpha: 51,
    red: 247,
    green: 96,
    blue: 69
  };

  private readonly THEME_OPACITY_10: common2D.Color = {
    alpha: 25,
    red: 247,
    green: 96,
    blue: 69
  };
  // 蓝色 #0A59F7
  private readonly BLUE: common2D.Color = {
    alpha: 255,
    red: 10,
    green: 89,
    blue: 247
  };
  private readonly BLUE_OPACITY_60: common2D.Color = {
    alpha: 153,
    red: 10,
    green: 89,
    blue: 247
  };
  private readonly BLUE_OPACITY_40: common2D.Color = {
    alpha: 102,
    red: 10,
    green: 89,
    blue: 247
  };
  private readonly MAX_COLOR_VALUE: number = 256;
  private isDarkMode: boolean = false;
  private colorMapV2: LightWeightMap<string, common2D.Color> = new LightWeightMap();

  constructor() {
    this.normalColorMap.set(ColorType.PRIMARY, this.PRIMARY);
    this.normalColorMap.set(ColorType.PRIMARY_CONTRARY, this.PRIMARY_CONTRARY);
    this.normalColorMap.set(ColorType.SECONDARY, this.SECONDARY);
    this.normalColorMap.set(ColorType.SECONDARY_CONTRARY, this.SECONDARY_CONTRARY);
    this.normalColorMap.set(ColorType.TERTIARY, this.TERTIARY);
    this.normalColorMap.set(ColorType.TERTIARY_OPACITY_60, this.TERTIARY_OPACITY_60);
    this.normalColorMap.set(ColorType.TERTIARY_OPACITY_40, this.TERTIARY_OPACITY_40);
    this.normalColorMap.set(ColorType.TEXT_OPACITY_90, this.TEXT_OPACITY_90);
    this.normalColorMap.set(ColorType.THEME, this.THEME);
    this.normalColorMap.set(ColorType.THEME_OPACITY_60, this.THEME_OPACITY_60);
    this.normalColorMap.set(ColorType.THEME_OPACITY_40, this.THEME_OPACITY_40);
    this.normalColorMap.set(ColorType.THEME_OPACITY_10, this.THEME_OPACITY_10);
    this.normalColorMap.set(ColorType.BLUE, this.BLUE);
    this.normalColorMap.set(ColorType.BLUE_OPACITY_60, this.BLUE_OPACITY_60);
    this.normalColorMap.set(ColorType.BLUE_OPACITY_40, this.BLUE_OPACITY_40);
    this.normalColorMap.set(ColorType.RECESSCIRCLE, this.RECESSCIRCLE);
    this.normalColorMap.set(ColorType.RECESS_CIRCLE_BIG, this.RECESS_CIRCLE_BIG);

    this.darkModeColorMap.set(ColorType.PRIMARY, this.DARK_PRIMARY);
    this.darkModeColorMap.set(ColorType.PRIMARY_CONTRARY, this.DARK_PRIMARY_CONTRARY);
    this.darkModeColorMap.set(ColorType.SECONDARY, this.DARK_SECONDARY);
    this.darkModeColorMap.set(ColorType.SECONDARY_CONTRARY, this.DARK_SECONDARY_CONTRARY);
    this.darkModeColorMap.set(ColorType.TERTIARY, this.DARK_TERTIARY);
    this.darkModeColorMap.set(ColorType.TERTIARY_OPACITY_60, this.DARK_TERTIARY_OPACITY_60);
    this.darkModeColorMap.set(ColorType.TERTIARY_OPACITY_40, this.DARK_TERTIARY_OPACITY_40);
    this.darkModeColorMap.set(ColorType.TEXT_OPACITY_90, this.DARK_TEXT_OPACITY_90);
    this.darkModeColorMap.set(ColorType.THEME, this.THEME);
    this.darkModeColorMap.set(ColorType.THEME_OPACITY_60, this.THEME_OPACITY_60);
    this.darkModeColorMap.set(ColorType.THEME_OPACITY_10, this.THEME_OPACITY_20);
    this.darkModeColorMap.set(ColorType.THEME_OPACITY_40, this.THEME_OPACITY_40);
    this.darkModeColorMap.set(ColorType.BLUE, this.BLUE);
    this.darkModeColorMap.set(ColorType.BLUE_OPACITY_60, this.BLUE_OPACITY_60);
    this.darkModeColorMap.set(ColorType.BLUE_OPACITY_40, this.BLUE_OPACITY_40);
    this.darkModeColorMap.set(ColorType.RECESSCIRCLE, this.DARK_RECESSCIRCLE);
    this.darkModeColorMap.set(ColorType.RECESS_CIRCLE_BIG, this.DARK_RECESS_CIRCLE_BIG);

    this.colorMap = this.normalColorMap;
  }

  public static instance(): PaletteCache {
    return PaletteCache._instance;
  }

  setDarkMode(isDarkMode: boolean): void {
    this.colorMap = isDarkMode ? this.darkModeColorMap : this.normalColorMap;
    this.isDarkMode = isDarkMode;
  }

  resourceToColor(resource: Resource): common2D.Color {
    const colorValue = getContext().resourceManager.getColorSync(resource.id);
    let rest = colorValue;
    const blue = rest % this.MAX_COLOR_VALUE;
    rest = (rest - blue) / this.MAX_COLOR_VALUE;
    const green = rest % this.MAX_COLOR_VALUE;
    rest = (rest - green) / this.MAX_COLOR_VALUE;
    const red = rest % this.MAX_COLOR_VALUE;
    rest = (rest - red) / this.MAX_COLOR_VALUE;
    const alpha = rest % this.MAX_COLOR_VALUE;
    return {
      alpha,
      red,
      green,
      blue
    };
  }

  getColorV2(resource: Resource): common2D.Color {
    const key: string = `${resource.id}-${this.isDarkMode}`;
    if (this.colorMapV2.hasKey(key)) {
      return this.colorMapV2.get(key);
    }

    const color = this.resourceToColor(resource);
    this.colorMapV2.set(key, color);
    return color;
  }

  getColor(colorType: ColorType): common2D.Color {
    return this.colorMap.get(colorType);
  }

  /**
   * 把用16进制表示的颜色转化成common2D.Color（ARGB表示），并放入colorMapV2
   * @param hexColor :用16进制表示的颜色 如#F23FE15E
   * @returns common2D.Color
   */
  getHexColor(hexColor: string): common2D.Color {
    if (this.colorMapV2.hasKey(hexColor)) {
      return this.colorMapV2.get(hexColor);
    }

    //校验是否为16进制string
    if (!this.isHexString(hexColor)) {
      Log.error(TAG, 'Error Hexadecimal Color');
      //返回默认颜色
      const defaultColor: common2D.Color = {
        alpha: 255,
        red: 209,
        green: 81,
        blue: 58
      }
      return defaultColor;
    }

    let argbColor: common2D.Color = {
      alpha: 255,
      red: 0,
      green: 0,
      blue: 0
    }

    //RGB颜色表达形式
    if (hexColor.length === rgbHexLength) {
      argbColor.red = parseInt(hexColor.substring(1, 3), 16);
      argbColor.green = parseInt(hexColor.substring(3, 5), 16);
      argbColor.blue = parseInt(hexColor.substring(5, 7), 16);
    }

    //ARGB颜色表达形式
    if (hexColor.length === argbHexLength) {
      argbColor.alpha = parseInt(hexColor.substring(1, 3), 16);
      argbColor.red = parseInt(hexColor.substring(3, 5), 16);
      argbColor.green = parseInt(hexColor.substring(5, 7), 16);
      argbColor.blue = parseInt(hexColor.substring(7, 9), 16);
    }

    this.colorMapV2.set(hexColor, argbColor);
    return argbColor;
  }

  isHexString(hexColor: string): boolean {
    if (hexColor.charAt(0) != '#' && (hexColor.length === rgbHexLength || hexColor.length === argbHexLength)) {
      return false;
    }

    //去掉#号
    hexColor = hexColor.substring(1);

    // 正则表达式匹配16进制字符串
    const hexRegex = /^[0-9a-fA-F]+$/;
    return hexRegex.test(hexColor);
  }
}