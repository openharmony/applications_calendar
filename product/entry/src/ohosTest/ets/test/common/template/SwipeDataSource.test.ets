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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { SingleSwipeViewModel, SwipeDataSource } from '@app/common';
import { beforeEach } from '@ohos/hypium/src/main/interface';
import { SwipeInfo } from '@app/common/src/main/ets/templates/SwipeDataSource';

class YearInfo extends SwipeInfo {
  public curYear : number = 0;
  public increase(): SwipeInfo {
    return new YearInfo(this.curYear + 1);
  }

  public decrease(): SwipeInfo {
    return new YearInfo(this.curYear - 1);
  }

  constructor(year : number) {
    super();
    this.curYear = year;
  }
}

class SingleYearSwipeData extends SingleSwipeViewModel {
  constructor(index: number, year : YearInfo ) {
    super(index, year);
  }

  public innerUpdate(info: SwipeInfo): void {
  }

  innerOnShowNext(info: SwipeInfo): void {
  }

  innerOnShowPrevious(info: SwipeInfo): void {
  }
}

function getYearInfos(viewModel: SwipeDataSource) : number[] {
  let result : number [] = [];
  const curData = viewModel.getData(viewModel.curIndex) as SingleYearSwipeData;
  const previousYear = curData.getPrevious();
  let info = previousYear?.info as YearInfo;
  result.push(info.curYear);
  info = curData?.info as YearInfo;
  result.push(info.curYear);
  const nextYear = curData.getNext();
  info = nextYear?.info as YearInfo;
  result.push(info.curYear);
  return result;
}

export default function SwipeDataSourceTest() {
  describe('SwipeDataSourceTest', () => {
    let dataSource : SwipeDataSource;
    beforeEach(() => {
      let testSingleSwipe0 = new SingleYearSwipeData(0, new YearInfo(2024));
      let testSingleSwipe1 = new SingleYearSwipeData(1, new YearInfo(2025));
      let testSingleSwipe2 = new SingleYearSwipeData(2, new YearInfo(2023));
      //  2  [0]  1
      dataSource = new SwipeDataSource(0);
      dataSource.initData([
        testSingleSwipe0, testSingleSwipe1, testSingleSwipe2
      ])
    })
    it('curIndex', 0, () => {
      let dataSource = new SwipeDataSource(0);
      expect(dataSource.curIndex).assertEqual(0);
    });

    it('initState', 0, () => {
      const curData = dataSource.getData(dataSource.curIndex) as SingleYearSwipeData;
      let info = curData?.info as YearInfo;
      expect(info.curYear).assertEqual(2024);
      info = curData.getPrevious()?.info as YearInfo;
      expect(info.curYear).assertEqual(2023);
      info = curData.getNext()?.info as YearInfo;
      expect(info.curYear).assertEqual(2025);
    });

    it('onShowNextOnce', 0, () => {
      dataSource.onShowNext();
      //  2     0   [1]
      // 2026  2024  2025
      expect(dataSource.curIndex).assertEqual(1);
      const curData = dataSource.getData(dataSource.curIndex) as SingleYearSwipeData;
      let info = curData?.info as YearInfo;
      expect(info.curYear).assertEqual(2025);
      const nextData = curData.getNext() as SingleYearSwipeData;
      expect(nextData.index).assertEqual(2);
      info = nextData?.info as YearInfo;
      expect(info.curYear).assertEqual(2026);
    });

    it('onShowNextMultiTimes', 0, () => {
      //  2      0   [1]
      // 2026   2024  2025
      dataSource.onShowNext();
      //  [2]    0   1
      // 2026   2027  2025
      dataSource.onShowNext();
      expect(dataSource.curIndex).assertEqual(2);
      const curData = dataSource.getData(dataSource.curIndex) as SingleYearSwipeData;
      let info = curData?.info as YearInfo;
      expect(info.curYear).assertEqual(2026);
      const nextData = curData.getNext() as SingleYearSwipeData;
      info = nextData?.info as YearInfo;
      expect(info.curYear).assertEqual(2027);
    });

    it('onShowPrevious', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      dataSource.onShowPrevious();
      expect(dataSource.curIndex).assertEqual(2);
      let years = getYearInfos(dataSource);
      expect(years).assertDeepEquals([2022, 2023, 2024]);
    });

    it('onShowPreviousMultiTime', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      dataSource.onShowPrevious();
      //  2       0    [1]
      // 2023   2021  2022
      dataSource.onShowPrevious();
      expect(dataSource.curIndex).assertEqual(1);
      let years = getYearInfos(dataSource);
      expect(years).assertDeepEquals([2021, 2022, 2023]);
    });

    it('onShowMix', 0, () => {
      //  [2]    0      1
      // 2023   2024  2022
      dataSource.onShowPrevious();
      //  2      [0]    1
      // 2023   2024  2025
      dataSource.onShowNext();
      expect(dataSource.curIndex).assertEqual(0);
      let years = getYearInfos(dataSource);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    });


    it('onUpdate', 0, () => {
      dataSource.onShowPrevious(); // 2023  2024  2022
      dataSource.onShowPrevious(); // 2023  2021  2022
      dataSource.onShowPrevious(); // 2020  2021  2022
      expect(dataSource.curIndex).assertEqual(0);
      let years = getYearInfos(dataSource);
      expect(years).assertDeepEquals([2020, 2021, 2022]);
      dataSource.updateByInfo(new YearInfo(2024));
      expect(dataSource.curIndex).assertEqual(0);
      years = getYearInfos(dataSource);
      expect(years).assertDeepEquals([2023, 2024, 2025]);
    });
  })
}