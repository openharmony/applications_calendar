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
import { Env } from '@app/common';
import { MonthViewLayoutEnv } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutEnv';
import { MonthViewLayoutModel } from '@app/feature.monthview/src/main/ets/layoutmodel/MonthViewLayoutModel';
import { describe, expect, it } from '@ohos/hypium';

export default function MonthViewLayoutModelTest() {

  describe('MonthViewLayoutModelTest', () => {
    const layoutModel = new MonthViewLayoutModel();
    it('MonthlyViewLayout_001', 0, () => {
      layoutModel.onSizeChange(200, 200);
      expect(layoutModel.dayLayout.value.circleSize).assertEqual(32);
    })

    it('MonthlyViewLayout_002', 0, () => {
      layoutModel.compSizeEnv.data.set('width', 420);
      layoutModel.compSizeEnv.data.set('height', 420);
      layoutModel.onSizeRefresh();
      expect(layoutModel.dayLayout.value.circleSize).assertEqual(56);
    })

    it('MonthlyViewLayout_003', 0, () => {
      AppStorage.setOrCreate('windowWidth', 800);
      AppStorage.setOrCreate('windowHeight', 600);
      layoutModel.onSizeChange(800, 600);
      layoutModel.onDivideInit(true);
      let needHide = layoutModel.onDivideChange(0, false);
      layoutModel.onDivideEnd(0);
      expect(needHide).assertTrue();
      expect(layoutModel.frameProp.value.agendaListRatio.toFixed(4)).assertEqual('0.4286');
      layoutModel.onDivideInit(false);
      needHide = layoutModel.onDivideChange(0, false);
      layoutModel.onDivideEnd(0);
      expect(needHide).assertFalse();
      expect(layoutModel.frameProp.value.agendaListRatio.toFixed(4)).assertEqual('0.4286');
      layoutModel.onDivideInit(false);
      needHide = layoutModel.onDivideChange(-400, false);
      layoutModel.onDivideEnd(0);
      expect(needHide).assertFalse();
      expect(layoutModel.frameProp.value.agendaListRatio.toFixed(4)).assertEqual('0.6667');
      layoutModel.onDivideInit(false, 'ug-CN');
      needHide = layoutModel.onDivideChange(400, false);
      layoutModel.onDivideEnd(0);
      expect(needHide).assertFalse();
      expect(layoutModel.frameProp.value.agendaListRatio.toFixed(4)).assertEqual('0.6667');
    })
  })
}