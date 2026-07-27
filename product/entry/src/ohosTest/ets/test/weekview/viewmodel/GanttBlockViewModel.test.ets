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

import { describe, expect, it } from '@ohos/hypium';
import { GanttBlockType, GanttBlockViewModel } from '@app/feature.weekview/src/main/ets/viewmodel/GanttBlockViewModel';
import { AgendaEventInfo, I18nUtil } from '@app/common';

export default function GanttBlockViewModelTest() {
  describe('GanttBlockViewModelTest', () => {
    it('basic_test', 0, () => {
      const block1 = new GanttBlockViewModel();
      block1.setRect(0, 0, 20, 20);
      const block2 = new GanttBlockViewModel();
      block2.setRect(10, 10, 20, 20);
      const block3 = new GanttBlockViewModel();
      block3.setRect(30, 30, 10, 10);

      block1.clearFocus();
      block1.checkFocus();

      const a1: number = 1.000000011;
      const a2: number = 1.000000012;
      const a3: number = 1.000000021;
      expect(block1.smallerThan(a1, a2)).assertFalse();
      expect(block1.smallerThan(a1, a3)).assertTrue();

      expect(block1.containPoint(1, 1)).assertTrue();
      expect(block2.containPoint(1, 1)).assertFalse();
      expect(block2.containPoint(10, 10)).assertTrue();
      expect(block2.intersect(block1)).assertTrue();
      expect(block2.intersect(block3)).assertFalse();
    })

    it('setInfo_isHoliday_branch', 0, () => {
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      const info3 = new AgendaEventInfo();
      const block1 = new GanttBlockViewModel();
      const block2 = new GanttBlockViewModel();
      const block3 = new GanttBlockViewModel();

      info1.mIsHoliday = false;
      block1.setInfo(info1, 14);
      expect(block1.getInfo()).not().assertUndefined();
      expect(block1.type).assertEqual(GanttBlockType.AGENDA);

      info2.mIsHoliday = true;
      block2.setInfo(info2, 14);
      expect(block2.type).assertEqual(GanttBlockType.AGENDA);

      block3.setInfo(info3, 14, true);
      expect(block3.isAllDayAgenda).assertTrue();
    })

    it('fold_item_test', 0, () => {
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      const block = new GanttBlockViewModel();
      const infoList = [info1, info2];

      info1.mBegin = Date.now() - 10000;
      info2.mBegin = Date.now() - 2000;
      block.setFoldInfo(infoList, 10);
      expect(block.type).assertEqual(GanttBlockType.FOLD);
      expect(block.getEarliestDate()).assertEqual(info1.mBegin);
    })

    it('max_line_test_1', 0, () => {
      const block1 = new GanttBlockViewModel();
      block1.isAllDayAgenda = true;
      block1.calculateMaxLines();
      expect(block1.mainTextMaxLines).assertEqual(1);
      block1.reCalculateMaxLines();
      expect(block1.mainTextMaxLines).assertEqual(1);

      const block2 = new GanttBlockViewModel();
      block2.width = 10;
      block2.mainText = '你好你好你好你好你好你好';
      block2.subText = '1';
      block2.fontSize = 16;
      block2.height = 46;
      block2.lineHeight = 18;

      block2.calculateMaxLines();
      expect(block2.mainTextMaxLines).assertEqual(2);
      block2.reCalculateMaxLines();
      expect(block2.mainTextMaxLines).assertEqual(2);

      const block3 = new GanttBlockViewModel();
      block3.width = 10;
      block3.mainText = '你好你好你好你好你好你好';
      block3.fontSize = 16;
      block3.height = 17;
      block3.lineHeight = 18;

      block3.calculateMaxLines();
      expect(block3.mainTextMaxLines).assertEqual(1);
      block3.reCalculateMaxLines();
      expect(block3.mainTextMaxLines).assertEqual(1);
    })

    it('fold_block_max_line_test_1', 0, () => {
      const block1 = new GanttBlockViewModel();
      const info1 = new AgendaEventInfo();
      const info2 = new AgendaEventInfo();
      block1.setFoldInfo([info1, info2], 10);
      block1.height = 28;
      block1.calculateMaxLines();
      expect(block1.mainTextMaxLines).assertEqual(3);
      block1.reCalculateMaxLines();
      expect(block1.mainTextMaxLines).assertEqual(3);

      const block2 = new GanttBlockViewModel();
      block2.setFoldInfo([info1, info2], 10);
      block2.height = 18;
      block2.calculateMaxLines();
      expect(block2.mainTextMaxLines).assertEqual(1);
      block2.reCalculateMaxLines();
      expect(block2.mainTextMaxLines).assertEqual(1);
    })

    it('time_line_test_1', 0, () => {
      const block1 = new GanttBlockViewModel();
      block1.isAllDayAgenda = true;
      block1.calculateMaxLines();
      expect(block1.showTimeText).assertFalse();
      block1.reCalculateMaxLines();
      expect(block1.showTimeText).assertFalse();

      const block2 = new GanttBlockViewModel();
      block2.width = 50;
      block2.mainText = '你好你好你好你好你好你好';
      block2.subText = '1';
      block2.height = 46;
      block2.lineHeight = 18;

      block2.calculateMaxLines();
      expect(block2.showTimeText).assertTrue();
      block2.reCalculateMaxLines();
      expect(block2.showTimeText).assertTrue();

      const block3 = new GanttBlockViewModel();
      block3.width = 20;
      block3.mainText = '你好你好你好你好你好你好';
      block3.height = 17;
      block3.lineHeight = 18;

      block3.calculateMaxLines();
      expect(block3.showTimeText).assertFalse();
      block3.reCalculateMaxLines();
      expect(block3.showTimeText).assertFalse();
    })

    it('getAccessibilityText_0', 0, () => {
      const block1 = new GanttBlockViewModel();
      block1.infoList = [];
      block1.getAccessibilityText();
      expect(block1.getAccessibilityText()).assertEqual('');
      const agendaEventInfo: AgendaEventInfo = new AgendaEventInfo();
      agendaEventInfo.mIsAllDay = true;
      agendaEventInfo.mBegin = 1728604800000;
      agendaEventInfo.mEnd = 1728691200000;
      agendaEventInfo.mTitle = '重阳节';
      block1.infoList.push(agendaEventInfo);
      expect(block1.getAccessibilityText()).assertEqual('2024年10月11日星期五,全天,重阳节,');
      const block2 = new GanttBlockViewModel();
      const agendaEventInfo2: AgendaEventInfo = new AgendaEventInfo();
      agendaEventInfo2.mIsAllDay = false;
      agendaEventInfo2.mBegin = 1728444600000;
      agendaEventInfo2.mEnd = 1728448200000;
      agendaEventInfo2.mTitle = '哈哈';
      block2.infoList = [];
      block2.infoList.push(agendaEventInfo2);
      if (I18nUtil.is24HourClock()) {
        expect(block2.getAccessibilityText()).assertEqual('2024年10月9日星期三,11:30至12:30,哈哈,');
      } else {
        expect(block2.getAccessibilityText()).assertEqual('2024年10月9日星期三,中午11:30至中午12:30,哈哈,');
      }
    })
  })
}