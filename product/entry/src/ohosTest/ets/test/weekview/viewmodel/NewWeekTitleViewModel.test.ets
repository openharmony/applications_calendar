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
import { afterEach, beforeAll, describe, expect, it } from '@ohos/hypium/src/main/interface';
import { MockKit } from '@ohos/hypium';
import { GlobalDataKeys, TabType } from '@app/common';
import { NewWeekTitleViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/NewWeekTitleViewModel';
import { RootViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/RootViewModel';
import { i18n } from '@kit.LocalizationKit';

export default function NewWeekTitleViewModelTest() {

  describe('NewWeekTitleViewModelTest', () => {
    let mocker: MockKit;

    beforeAll(() => {
      mocker = new MockKit();
    })

    afterEach(() => {
      mocker.clearAll();
    })

    it('resetWeekTitles', 0, () => {
      const tabType1 = TabType.WEEK;
      let weekTitleVM: NewWeekTitleViewModel = new NewWeekTitleViewModel();
      weekTitleVM.init();
      //设置一周的开始为周一
      weekTitleVM.startOfWeek = 1;
      weekTitleVM.resetWeekTitles(tabType1);
      //staticWeekDayInfoList的第一个元素为一周的开始，验证是与设置的一样
      expect(weekTitleVM.staticWeekDayInfoList[0].dayOfWeek).assertEqual(1);
    })

    it('resetWeekends', 0, () => {
      AppStorage.setOrCreate(GlobalDataKeys.THEME_COLOR, '#F76045');
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();
      //设置周末为周一
      AppStorage.setOrCreate(GlobalDataKeys.WEEKENDS, [0]);

      rootVM.weekTitleVM.resetWeekends(rootVM.dateVMs);
      expect(rootVM.weekTitleVM.staticWeekDayInfoList[0].isWeekend).assertEqual(true);

    })

    it('onLanguageChange_ar', 0, () => {
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();

      rootVM.weekTitleVM.onLanguageChange('ar');
      expect(rootVM.weekTitleVM.isRTL).assertEqual(true);
      expect(rootVM.weekTitleVM.isAR).assertEqual(true);
    })

    it('onLanguageChange_arDZ', 0, () => {
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();
      rootVM.weekTitleVM.onLanguageChange('ar-DZ');
      expect(rootVM.weekTitleVM.isRTL).assertEqual(true);
      expect(rootVM.weekTitleVM.isAR).assertEqual(true);
    })

    it('onLanguageChange_zhHansCN', 0, () => {
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();

      rootVM.weekTitleVM.onLanguageChange('zh-Hans-CN');
      expect(rootVM.weekTitleVM.isRTL).assertEqual(false);
      expect(rootVM.weekTitleVM.isAR).assertEqual(false);

    })
    it('onLanguageChange_ugHansCN', 0, () => {
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();

      rootVM.weekTitleVM.onLanguageChange('ug-Hans-CN');
      expect(rootVM.weekTitleVM.isRTL).assertEqual(false);
      expect(rootVM.weekTitleVM.isAR).assertEqual(false);
    })

    it('onLanguageChange_ug', 0, () => {
      const tabType2 = TabType.WEEK;
      let rootVM: RootViewModel = new RootViewModel(tabType2);
      rootVM.initVMs();

      rootVM.weekTitleVM.onLanguageChange('ug');
      expect(rootVM.weekTitleVM.isRTL).assertEqual(true);
      expect(rootVM.weekTitleVM.isAR).assertEqual(false);
    })

  });
}