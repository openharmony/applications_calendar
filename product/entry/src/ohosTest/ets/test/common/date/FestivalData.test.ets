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

import { describe, expect, it } from '@ohos/hypium'
import { DateManager } from '@app/common/index'
import { FestivalDay, FestivalType } from '@app/common/src/main/ets/date/FestivalData'


export default function FestivalTest() {
  describe('FestivalTest', () => {
    let checkFestival: (year: number, month: number, day: number, festivals: FestivalDay[]) =>
    void = (year: number, month: number, day: number, festivals: FestivalDay[]): void => {
      let dayData = DateManager.getInstance().getDayData(year, month, day);
      expect(dayData).not().assertUndefined();
      if (!dayData) {
        return;
      }
      expect(dayData.festivals).assertDeepEquals(festivals);
    }

    it('DayData_term_01', 0, () => {
      let dayData = DateManager.getInstance().getDayData(2023, 1, 5);
      expect(dayData).not().assertUndefined();
      if (dayData) {
        expect(dayData.lunaMonth).assertEqual(12); // 闰二月
        expect(dayData.lunarDay).assertEqual(14);
        expect(dayData.festivals[0].name).assertEqual('小寒');
      }

    })

    it('DayData_festival_lunarChina', 0, () => {
      let hasError: boolean = true;
      checkFestival(2022, 1, 31, [{
        type: FestivalType.LUNAR_CHINA, name: '除夕', resource: $r('app.string.chinese_new_years_eve')
      }]);
      checkFestival(2022, 2, 1, [{
        type: FestivalType.LUNAR_CHINA, name: '春节', resource: $r('app.string.spring_festival')
      }]);
      checkFestival(2023, 1, 14, [{
        type: FestivalType.LUNAR_CHINA, name: '北方小年', resource: $r('app.string.northern_little_new_year')
      }]);
      checkFestival(2023, 1, 15, [{
        type: FestivalType.LUNAR_CHINA, name: '南方小年', resource: $r('app.string.southern_little_new_year')
      }]);
      checkFestival(2023, 1, 21, [{
        type: FestivalType.LUNAR_CHINA, name: '除夕', resource: $r('app.string.chinese_new_years_eve')
      }]);
      checkFestival(2023, 1, 22, [{
        type: FestivalType.LUNAR_CHINA, name: '春节', resource: $r('app.string.spring_festival')
      }]);
      checkFestival(2023, 2, 5, [{
        type: FestivalType.LUNAR_CHINA, name: '元宵节', resource: $r('app.string.lantern_festival')
      }, {
        type: FestivalType.SOLAR_TERM, name: '六九', resource: $r('app.string.sixth_nine_days')
      }]);
      checkFestival(2023, 4, 5, [{
        type: FestivalType.LUNAR_CHINA, name: '清明节', resource: $r('app.string.qingming_festival')
      }]);
      checkFestival(2023, 6, 22, [{
        type: FestivalType.LUNAR_CHINA, name: '端午节', resource: $r('app.string.dragon_boat_festival')
      }]);
      checkFestival(2023, 8, 22, [{
        type: FestivalType.LUNAR_CHINA, name: '七夕节', resource: $r('app.string.qixi_festival')
      }]);
      checkFestival(2023, 8, 30, [{
        type: FestivalType.LUNAR_CHINA, name: '中元节', resource: $r('app.string.ghost_festival')
      }]);
      checkFestival(2023, 9, 29, [{
        type: FestivalType.LUNAR_CHINA, name: '中秋节', resource: $r('app.string.mid_autumn_festival')
      }]);
      checkFestival(2023, 10, 23, [{
        type: FestivalType.LUNAR_CHINA, name: '重阳节', resource: $r('app.string.double_ninth_festival')
      }]);
      hasError = false;
      expect(hasError).assertFalse();
    })


    it('DayData_festival_solarTerm', 0, () => {
      let hasError: boolean = true;
      checkFestival(2023, 1, 5, [{
        type: FestivalType.SOLAR_TERM, name: '小寒', resource: $r('app.string.minor_cold')
      }]);
      checkFestival(2023, 1, 9, [{
        type: FestivalType.SOLAR_TERM, name: '三九', resource: $r('app.string.third_nine_days')
      }]);
      checkFestival(2023, 1, 18, [{
        type: FestivalType.SOLAR_TERM, name: '四九', resource: $r('app.string.fourth_nine_days')
      }]);
      checkFestival(2023, 1, 20, [{
        type: FestivalType.SOLAR_TERM, name: '大寒', resource: $r('app.string.major_cold')
      }]);
      checkFestival(2023, 1, 27, [{
        type: FestivalType.SOLAR_TERM, name: '五九', resource: $r('app.string.fifth_nine_days')
      }]);
      checkFestival(2023, 2, 4, [{
        type: FestivalType.SOLAR_TERM, name: '立春', resource: $r('app.string.start_of_spring')
      }]);
      checkFestival(2023, 2, 5, [{
        type: FestivalType.LUNAR_CHINA, name: '元宵节', resource: $r('app.string.lantern_festival')
      }, {
        type: FestivalType.SOLAR_TERM, name: '六九', resource: $r('app.string.sixth_nine_days')
      }]);
      checkFestival(2023, 2, 14, [{
        type: FestivalType.SOLAR_TERM, name: '七九', resource: $r('app.string.seventh_nine_days')
      }, {
        type: FestivalType.INTER, name: '情人节', resource: $r('app.string.valentines_day')
      }]);
      checkFestival(2023, 2, 19, [{
        type: FestivalType.SOLAR_TERM, name: '雨水', resource: $r('app.string.rain_water')
      }]);
      checkFestival(2023, 2, 23, [{
        type: FestivalType.SOLAR_TERM, name: '八九', resource: $r('app.string.eighth_nine_days')
      }]);
      checkFestival(2023, 3, 4, [{
        type: FestivalType.SOLAR_TERM, name: '九九', resource: $r('app.string.ninth_nine_days')
      }]);
      checkFestival(2023, 3, 6, [{
        type: FestivalType.SOLAR_TERM, name: '惊蛰', resource: $r('app.string.waking_of_insects')
      }]);
      checkFestival(2023, 3, 21, [{
        type: FestivalType.SOLAR_TERM, name: '春分', resource: $r('app.string.spring_equinox')
      }]);
      checkFestival(2023, 4, 20, [{
        type: FestivalType.SOLAR_TERM, name: '谷雨', resource: $r('app.string.grain_rain')
      }]);
      checkFestival(2023, 5, 6, [{
        type: FestivalType.SOLAR_TERM, name: '立夏', resource: $r('app.string.start_of_summer')
      }]);
      checkFestival(2023, 5, 21, [{
        type: FestivalType.SOLAR_TERM, name: '小满', resource: $r('app.string.grain_full')
      }]);
      checkFestival(2023, 6, 6, [{
        type: FestivalType.SOLAR_TERM, name: '芒种', resource: $r('app.string.grain_in_ear')
      }]);
      checkFestival(2023, 6, 21, [{
        type: FestivalType.SOLAR_TERM, name: '夏至', resource: $r('app.string.summer_solstice')
      }]);
      checkFestival(2023, 7, 7, [{
        type: FestivalType.SOLAR_TERM, name: '小暑', resource: $r('app.string.minor_heat')
      }, {
        type: FestivalType.OFFICIAL_CHINA, name: '七七事变', resource: $r('app.string.july_seventh_incident')
      }]);
      checkFestival(2023, 7, 11, [{
        type: FestivalType.SOLAR_TERM, name: '入伏', resource: $r('app.string.initial_fu')
      }]);
      checkFestival(2023, 7, 21, [{
        type: FestivalType.SOLAR_TERM, name: '中伏', resource: $r('app.string.mid_fu')
      }]);
      checkFestival(2023, 7, 23, [{
        type: FestivalType.SOLAR_TERM, name: '大暑', resource: $r('app.string.major_heat')
      }]);
      checkFestival(2023, 8, 8, [{
        type: FestivalType.SOLAR_TERM, name: '立秋', resource: $r('app.string.start_of_autumn')
      }]);
      checkFestival(2023, 8, 10, [{
        type: FestivalType.SOLAR_TERM, name: '末伏', resource: $r('app.string.final_fu')
      }]);
      checkFestival(2023, 8, 23, [{
        type: FestivalType.SOLAR_TERM, name: '处暑', resource: $r('app.string.end_of_heat')
      }]);
      checkFestival(2023, 9, 8, [{
        type: FestivalType.SOLAR_TERM, name: '白露', resource: $r('app.string.white_dew')
      }]);
      checkFestival(2023, 9, 23, [{
        type: FestivalType.SOLAR_TERM, name: '秋分', resource: $r('app.string.autumn_equinox')
      }]);
      checkFestival(2023, 10, 8, [{
        type: FestivalType.SOLAR_TERM, name: '寒露', resource: $r('app.string.cold_dew')
      }]);
      checkFestival(2023, 10, 24, [{
        type: FestivalType.SOLAR_TERM, name: '霜降', resource: $r('app.string.frosts_descent')
      }]);
      checkFestival(2025, 11, 8, [{
        type: FestivalType.INTER, name: '记者节', resource: $r('app.string.journalist_day')
      }]);
      checkFestival(2023, 11, 22, [{
        type: FestivalType.SOLAR_TERM, name: '小雪', resource: $r('app.string.minor_snow')
      }]);
      checkFestival(2023, 12, 7, [{
        type: FestivalType.SOLAR_TERM, name: '大雪', resource: $r('app.string.major_snow')
      }]);
      checkFestival(2023, 12, 22, [{
        type: FestivalType.SOLAR_TERM, name: '冬至', resource: $r('app.string.winter_solstice')
      }, {
        type: FestivalType.SOLAR_TERM, name: '入九', resource: $r('app.string.first_nine_days')
      }]);
      hasError = false;
      expect(hasError).assertFalse();
    })

    it('DayData_term_jiujiu', 0, () => {
      let hasError: boolean = true;
      checkFestival(2023, 12, 22, [{
        type: FestivalType.SOLAR_TERM, name: '冬至', resource: $r('app.string.winter_solstice')
      }, {
        type: FestivalType.SOLAR_TERM, name: '入九', resource: $r('app.string.first_nine_days')
      }]);
      checkFestival(2023, 12, 31, [{
        type: FestivalType.SOLAR_TERM, name: '二九', resource: $r('app.string.second_nine_days')
      }]);
      checkFestival(2024, 1, 9, [{
        type: FestivalType.SOLAR_TERM, name: '三九', resource: $r('app.string.third_nine_days')
      }]);
      checkFestival(2024, 1, 18, [{
        type: FestivalType.LUNAR_CHINA, name: '腊八节', resource: $r('app.string.labas_festival')
      }, {
        type: FestivalType.SOLAR_TERM, name: '四九', resource: $r('app.string.fourth_nine_days')
      }]);
      checkFestival(2024, 1, 27, [{
        type: FestivalType.SOLAR_TERM, name: '五九', resource: $r('app.string.fifth_nine_days')
      }]);
      checkFestival(2024, 2, 5, [{
        type: FestivalType.SOLAR_TERM, name: '六九', resource: $r('app.string.sixth_nine_days')
      }]);
      checkFestival(2024, 2, 14, [{
        type: FestivalType.SOLAR_TERM, name: '七九', resource: $r('app.string.seventh_nine_days')
      }, {
        type: FestivalType.INTER, name: '情人节', resource: $r('app.string.valentines_day')
      },]);
      checkFestival(2024, 2, 23, [{
        type: FestivalType.SOLAR_TERM, name: '八九', resource: $r('app.string.eighth_nine_days')
      }]);
      checkFestival(2024, 3, 3, [{
        type: FestivalType.SOLAR_TERM, name: '九九', resource: $r('app.string.ninth_nine_days')
      }]);
      hasError = false;
      expect(hasError).assertFalse();
    })

    it('Festival_term_01', 0, () => {
      let dayData = DateManager.getInstance().getDayData(2023, 1, 5);
      expect(dayData).not().assertUndefined();
      if (dayData) {
        expect(dayData.festivals[0].name).assertEqual('小寒');
        expect(dayData.festivals[0].type).assertEqual(FestivalType.SOLAR_TERM);
      }
    })
    it('Festival_term_02', 0, () => {
      let dayData = DateManager.getInstance().getDayData(2023, 1, 2);
      expect(dayData).not().assertUndefined();
      if (dayData) {
        expect(dayData.festivals.length === 0).assertTrue()
      }
    })
    it('Festival_term_03', 0, () => {
      let dayData = DateManager.getInstance().getDayData(1950, 1, 1);
      expect(dayData).not().assertUndefined();
      if (dayData) {
        expect(dayData.festivals.length !== 0).assertTrue();
        expect(dayData.festivals[0].name).assertEqual('元旦');
        expect(dayData.festivals[0].type).assertEqual(FestivalType.INTER);
      }
    })
    it('Festival_term_04', 0, () => {
      let dayData = DateManager.getInstance().getDayData(2024, 1, 1);
      expect(dayData).not().assertUndefined();
      if (dayData) {
        expect(dayData.festivals.length !== 0).assertTrue();
        expect(dayData.festivals[0].name).assertEqual('元旦');
        expect(dayData.festivals[0].type).assertEqual(FestivalType.INTER);
      }
    })
    // 农历假日 位于 节气之前
    it('Festival_term_multi_01', 0, () => {
      let hasError: boolean = true;
      checkFestival(2024, 1, 18, [{
        type: FestivalType.LUNAR_CHINA, name: '腊八节', resource: $r('app.string.labas_festival')
      }, {
        type: FestivalType.SOLAR_TERM, name: '四九', resource: $r('app.string.fourth_nine_days')
      }]);
      hasError = false;
      expect(hasError).assertFalse();
    })
    // 节气 位于 节假日之前
    it('Festival_term_multi_02', 0, () => {
      let hasError: boolean = true;
      checkFestival(2024, 2, 14, [{
        type: FestivalType.SOLAR_TERM, name: '七九', resource: $r('app.string.seventh_nine_days')
      }, {
        type: FestivalType.INTER, name: '情人节', resource: $r('app.string.valentines_day')
      }]);
      hasError = false;
      expect(hasError).assertFalse();
    })
  })
}