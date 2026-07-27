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
import { describe, it, expect } from '@ohos/hypium';
import {
  VCSToICSRRuleTranslator
} from '@app/feature.importexport/src/main/ets/vcalendar/import/VCSToICSRRuleTranslator';
import { TestUtil } from '../utils/TestUtil';

const TAG = 'VCSToICSRRuleTranslatorTest';

export default function VCSToICSRRuleTranslatorTest() {
  describe('VCSToICSRRuleTranslatorTest', () => {

    const vCSToICSRRuleTranslatorTest = new VCSToICSRRuleTranslator();

    it('testGetFormatVcsRuleString', 0, () => {
      const fuc = TestUtil.getPrivateFunction(vCSToICSRRuleTranslatorTest, 'getFormatVcsRuleString');
      if (!fuc) {
        expect(fuc).assertNull();
      } else {
        expect(fuc('') === '').assertTrue();
        expect(fuc('1LD') === '11-').assertTrue();
        expect(fuc('1LD11LD') === '11-111-').assertTrue();
      }
    })

    it('testTrimLastComma', 0, () => {
      const fuc = TestUtil.getPrivateFunction(vCSToICSRRuleTranslatorTest, 'trimLastComma');
      if (!fuc) {
        expect(fuc).assertNull();
      } else {
        expect(fuc('') === '').assertTrue();
        expect(fuc('1LD') === '1LD').assertTrue();
        expect(fuc('1LD,') === '1LD').assertTrue();
      }
    })

    it('testIsDigitChar', 0, () => {
      const fuc = TestUtil.getPrivateFunction(vCSToICSRRuleTranslatorTest, 'isDigitChar');
      if (!fuc) {
        expect(fuc).assertNull();
      } else {
        expect(fuc('', 0)).assertFalse();
        expect(fuc('a', 0)).assertFalse();
        expect(fuc('sdvc', 2)).assertFalse();
        expect(fuc('0', 0)).assertTrue();
        expect(fuc('9', 0)).assertTrue();
        expect(fuc('sss0', 3)).assertTrue();
        expect(fuc('sss9', 3)).assertTrue();
      }
    })

    it('testIsLetter', 0, () => {
      const fuc = TestUtil.getPrivateFunction(vCSToICSRRuleTranslatorTest, 'isLetter');
      if (!fuc) {
        expect(fuc).assertNull();
      } else {
        expect(fuc('')).assertFalse();
        expect(fuc('a')).assertTrue();
        expect(fuc('sdvc')).assertFalse();
        expect(fuc('z')).assertTrue();
        expect(fuc('A')).assertTrue();
        expect(fuc('Z')).assertTrue();
        expect(fuc('0')).assertFalse();
        expect(fuc('0')).assertFalse();
      }
    })

    it('testParseVcsRrule', 0, () => {
      expect(vCSToICSRRuleTranslatorTest.parse('')).assertFalse();
      expect(vCSToICSRRuleTranslatorTest.parse('W1 FR #0')).assertTrue();
      expect(vCSToICSRRuleTranslatorTest.buildRepeatRuleString() === 'FREQ=WEEKLY;COUNT=0;INTERVAL=1;BYDAY=FR;')
        .assertTrue();
      expect(vCSToICSRRuleTranslatorTest.parse('D1 #0')).assertTrue();
      expect(vCSToICSRRuleTranslatorTest.buildRepeatRuleString() === 'FREQ=DAILY;COUNT=0;INTERVAL=1;').assertTrue();
      expect(vCSToICSRRuleTranslatorTest.parse('MD1 28 #0')).assertTrue();
      expect(vCSToICSRRuleTranslatorTest.buildRepeatRuleString() === 'FREQ=MONTHLY;COUNT=0;INTERVAL=1;BYMONTHDAY=28;')
        .assertTrue();
      expect(vCSToICSRRuleTranslatorTest.parse('YM1 6 #0 MD1 28')).assertTrue();
      expect(vCSToICSRRuleTranslatorTest.buildRepeatRuleString() === 'FREQ=YEARLY;COUNT=0;INTERVAL=1;BYMONTH=6;')
        .assertTrue();
      expect(vCSToICSRRuleTranslatorTest.parse('D8 #0')).assertTrue();
      expect(vCSToICSRRuleTranslatorTest.buildRepeatRuleString() === 'FREQ=DAILY;COUNT=0;INTERVAL=8;').assertTrue();
    })

    it('parseOccuranceWeekdayList', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseOccuranceWeekdayList');
      if (func) {
        expect(func('test', 1)).not().assertEqual(0);
        expect(func('test', 2)).not().assertEqual(0);
        expect(func('test', 3)).not().assertEqual(0);
        expect(func('W1 FR #0', 1)).not().assertEqual(0);
        expect(func('D1 #0', 2)).not().assertEqual(0);
        expect(func('MD1 28 #0', 3)).not().assertEqual(0);
      }
    })

    it('getOccurence', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'getOccurence');
      if (func) {
        expect(func('test', 1, 2)).not().assertEqual(0);
        expect(func('test', 1, 3)).not().assertEqual(0);
        expect(func('test', 2, 4)).not().assertEqual(0);
        expect(func('W1 FR #0', 1, 2)).not().assertEqual(0);
        expect(func('D1 #0', 1, 3)).not().assertEqual(0);
        expect(func('MD1 28 #0', 2, 4)).not().assertEqual(0);
      }
    })

    it('getByDay', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'getByDay');
      let strs1: string[] = ['test1', 'test2', 'test3'];
      TestUtil.setPrivateAttribute(vCSToICSRRuleTranslator, 'mOccuranceList', strs1);
      TestUtil.setPrivateAttribute(vCSToICSRRuleTranslator, 'mWeekdayList', strs1);
      if (func) {
        func();
        expect(TestUtil.getPrivateAttribute<string[]>(vCSToICSRRuleTranslator, 'mOccuranceList'))
          .not()
          .assertUndefined();
      }
    })

    it('parseYearDayList', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseYearDayList');
      if (func) {
        expect(func('test', 1)).not().assertEqual(0);
        expect(func('test', 2)).not().assertEqual(0);
        expect(func('test123', 1)).not().assertEqual(0);
        expect(func('test123', 2)).not().assertEqual(0);
      }
    })

    it('parseOccuranceWeekdayList_001', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseOccuranceWeekdayList');
      if (func) {
        const vcsRrule: string = "FREQ=DAILY;WKST=MO;BYDAY=MO,TU,WE,TH";
        const offset: number = -1;
        const result: ESObject = func(vcsRrule, offset);
        expect(result).assertEqual(-1);
      }
    })

    it('parseOccuranceWeekdayList_002', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseOccuranceWeekdayList');
      if (func) {
        const vcsRrule: string = "FREQ=DAILY;WKST=MO;BYDAY=WE,TH,FR,SA,SU";
        const offset: number = 5;
        const result: ESObject = func(vcsRrule, offset);
        expect(result).assertEqual(5);
      }
    })

    it('parseOccuranceWeekdayList_003', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseOccuranceWeekdayList');
      if (func) {
        const vcsRrule: string = "FREQ=DAILY;WKST=MO;BYDAY=MO,TU,SA,SU";
        const offset: number = 100;
        const result: ESObject = func(vcsRrule, offset);
        expect(result).assertEqual(100);
      }
    })

    it('parseOccuranceWeekdayList_004', 0, () => {
      let vCSToICSRRuleTranslator: VCSToICSRRuleTranslator = new VCSToICSRRuleTranslator();
      let func = TestUtil.getPrivateFunction(vCSToICSRRuleTranslator, 'parseOccuranceWeekdayList');
      if (func) {
        const vcsRrule: string = "FREQ=DAILY;WKST=MO;BYDAY=TU,WE,TH,FR,SA,SU";
        const offset: number = 0;
        const result: ESObject = func(vcsRrule, offset);
        expect(result).assertEqual(0);
      }
    })
  })
}