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

// 24节气, 节气时序不可变动!
export const MAIN_LUNAR_TERM: ReadonlyArray<string> = [
  '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
  '清明节', '谷雨', '立夏', '小满', '芒种', '夏至',
  '小暑', '大暑', '立秋', '处暑',
  '白露', '秋分', '寒露', '霜降',
  '立冬', '小雪', '大雪', '冬至',
]

// 其他节气
export const SUB_LUNAR_TERM: ReadonlyArray<string> = [
  '入九', '二九', '三九', '四九', '五九', '六九', '七九', '八九', '九九',
  '入伏', '中伏', '末伏'
]

// 所有节气
export const ALL_LUNAR_TERM: ReadonlyArray<string> = MAIN_LUNAR_TERM.concat(SUB_LUNAR_TERM);

// 节气时序不可变动!
export const ALL_LUNAR_TERM_RES: ReadonlyArray<Resource> = [
  $r('app.string.minor_cold'), $r('app.string.major_cold'), $r('app.string.start_of_spring'), $r('app.string.rain_water'), $r('app.string.waking_of_insects'), $r('app.string.spring_equinox'),
  $r('app.string.qingming_festival'), $r('app.string.grain_rain'), $r('app.string.start_of_summer'), $r('app.string.grain_full'), $r('app.string.grain_in_ear'), $r('app.string.summer_solstice'),
  $r('app.string.minor_heat'), $r('app.string.major_heat'), $r('app.string.start_of_autumn'), $r('app.string.end_of_heat'),
  $r('app.string.white_dew'), $r('app.string.autumn_equinox'), $r('app.string.cold_dew'), $r('app.string.frosts_descent'),
  $r('app.string.start_of_winter'), $r('app.string.minor_snow'), $r('app.string.major_snow'), $r('app.string.winter_solstice'),
  $r('app.string.first_nine_days'), $r('app.string.second_nine_days'), $r('app.string.third_nine_days'), $r('app.string.fourth_nine_days'),
  $r('app.string.fifth_nine_days'), $r('app.string.sixth_nine_days'), $r('app.string.seventh_nine_days'), $r('app.string.eighth_nine_days'),
  $r('app.string.ninth_nine_days'), $r('app.string.initial_fu'), $r('app.string.mid_fu'), $r('app.string.final_fu'),
]

export const ALL_LUNAR_MONTH: ReadonlyArray<string> = [
  '正月', '二月', '三月',
  '四月', '五月', '六月',
  '七月', '八月', '九月',
  '十月', '冬月', '腊月',
]