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
 * 帐户颜色   转换备注: 十进制-43956 对应 十六进制FFFF FFFF FFFF 544C,后6位FF544C即为对应的颜色'#FF544C'
 */
export const enum AccountColor {
  // 朱彤色 对应d1513a
  RED = -3059398,

  // 蜜橘色 对应d67538
  DARK_ORANGE = -2722504,

  // 赤金色 对应c7a200
  LIGHT_ORANGE = -3694080,

  // 嫩绿色 对应6ba65f
  GREEN = -9722273,

  // 青翠色 对应1981d8
  TURQUOISE = -15105576,

  // 靛青色 对应675ec7
  BLUE = -10002745,

  // 绛紫色 对应925ac7
  PURPLE = -7185721
}

export const enum EmuiAccountColor {
  // 朱彤色
  RED = -1686170,

  // 蜜橘色
  DARK_ORANGE = -1216735,

  // 赤金色
  LIGHT_ORANGE = -537088,

  // 嫩绿色
  GREEN = -10175652,

  // 青翠色
  TURQUOISE = -10367042,

  // 靛青色
  BLUE = -12213274,

  // 绛紫色
  PURPLE = -5486091,

  // 灰色
  GREY = -8355712
}

export const ALL_ACCOUNT_COLOR: ReadonlyArray<number> = [
  AccountColor.RED,
  AccountColor.DARK_ORANGE,
  AccountColor.LIGHT_ORANGE,
  AccountColor.GREEN,
  AccountColor.TURQUOISE,
  AccountColor.PURPLE,
  AccountColor.BLUE
];

export interface OldAccountColor {
  oldAccountColor: number,
  nowAccountColor: number
}

// 原来用过的颜色
export const oldAccountColorList: OldAccountColor[] = [
  {oldAccountColor: -43956, nowAccountColor :AccountColor.RED},
  {oldAccountColor: -1081288, nowAccountColor :AccountColor.DARK_ORANGE},
  {oldAccountColor: -2581742, nowAccountColor :AccountColor.LIGHT_ORANGE},
  {oldAccountColor: -8019158, nowAccountColor :AccountColor.GREEN},
  {oldAccountColor: -11029863, nowAccountColor :AccountColor.TURQUOISE},
  {oldAccountColor: -11697938, nowAccountColor :AccountColor.BLUE},
  {oldAccountColor: -5281630, nowAccountColor :AccountColor.PURPLE},

  {oldAccountColor: -1686170, nowAccountColor :AccountColor.RED},
  {oldAccountColor: -1216735, nowAccountColor :AccountColor.DARK_ORANGE},
  {oldAccountColor: -537088, nowAccountColor :AccountColor.LIGHT_ORANGE},
  {oldAccountColor: -10175652, nowAccountColor :AccountColor.GREEN},
  {oldAccountColor: -10367042, nowAccountColor :AccountColor.TURQUOISE},
  {oldAccountColor: -12213274, nowAccountColor :AccountColor.BLUE},
  {oldAccountColor: -5486091, nowAccountColor :AccountColor.PURPLE},

  {oldAccountColor: -565179, nowAccountColor :AccountColor.RED}, // f76045
  {oldAccountColor: -161214, nowAccountColor :AccountColor.DARK_ORANGE}, // fd8a42
  {oldAccountColor: -1327360, nowAccountColor :AccountColor.LIGHT_ORANGE}, // ebbf00
  {oldAccountColor: -8469392, nowAccountColor :AccountColor.GREEN}, // 7ec470
  {oldAccountColor: -14837505, nowAccountColor :AccountColor.TURQUOISE}, // 1d98ff
  {oldAccountColor: -8753173, nowAccountColor :AccountColor.BLUE}, // 7a6feb
  {oldAccountColor: -5412117, nowAccountColor :AccountColor.PURPLE}, // ad6aeb

  {oldAccountColor: -6678784, nowAccountColor :AccountColor.RED}, // 9A1700
  {oldAccountColor: -5488128, nowAccountColor :AccountColor.DARK_ORANGE}, // AC4200
  {oldAccountColor: -6258176, nowAccountColor :AccountColor.LIGHT_ORANGE}, // A08200
  {oldAccountColor: -15100928, nowAccountColor :AccountColor.GREEN}, // 199400
  {oldAccountColor: -16756331, nowAccountColor :AccountColor.TURQUOISE}, // 005195
  {oldAccountColor: -15859554, nowAccountColor :AccountColor.BLUE}, // 0E009E
  {oldAccountColor: -11534181, nowAccountColor :AccountColor.PURPLE}, // 50009B
]