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

import { beforeAll, describe, expect, it } from '@ohos/hypium';
import { TitleModel } from '@app/feature.yearview';
import { DAY_PER_WEEK, GlobalData, GlobalDataKeys } from '@app/common';

export default function YearTitleModelTest() {
  describe('YearTitleModelTest', () => {
    beforeAll(() => {
      TitleModel.instance().reset();
      GlobalData.instance().set(GlobalDataKeys.START_OF_WEEK, 0);
    });

    it('TitleModelChineseCase', 0, () => {
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'zh-Hans');
      TitleModel.instance().reset();

      const weekTitles = TitleModel.instance().getWeekTitles();
      expect(weekTitles.length).assertEqual(DAY_PER_WEEK);
      expect(weekTitles[0]).assertEqual('日');
      expect(weekTitles[6]).assertEqual('六');
      expect(weekTitles[7]).assertEqual(undefined);

      expect(TitleModel.instance().getMonthTitle(0)).assertEqual('1月');
      expect(TitleModel.instance().getMonthTitle(11)).assertEqual('12月');
      expect(TitleModel.instance().getMonthTitle(12)).assertEqual(undefined);
    });

    it("TitleModelEnglishCase", 0, () => {
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'en-Latn-US');
      TitleModel.instance().reset();

      const weekTitles = TitleModel.instance().getWeekTitles();
      expect(weekTitles.length).assertEqual(DAY_PER_WEEK);
      expect(weekTitles[0]).assertEqual('S');
      expect(weekTitles[6]).assertEqual('S');
      expect(weekTitles[7]).assertEqual(undefined);

      expect(TitleModel.instance().getMonthTitle(0)).assertEqual('Jan');
      expect(TitleModel.instance().getMonthTitle(11)).assertEqual('Dec');
      expect(TitleModel.instance().getMonthTitle(12)).assertEqual(undefined);
    });

    it('TitleModelStartOfWeekCase', 0, () => {
      GlobalData.instance().set(GlobalDataKeys.START_OF_WEEK, 2);
      GlobalData.instance().set(GlobalDataKeys.LANGUAGE, 'zh-Hans');
      TitleModel.instance().reset();

      const weekTitles = TitleModel.instance().getWeekTitles();
      expect(weekTitles.length).assertEqual(DAY_PER_WEEK);
      expect(weekTitles[0]).assertEqual('二');
      expect(weekTitles[6]).assertEqual('一');
    });
  });
}