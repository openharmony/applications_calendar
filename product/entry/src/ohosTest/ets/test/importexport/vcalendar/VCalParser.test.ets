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

import { beforeEach, describe, expect, it } from '@ohos/hypium'
import { ParserState, VCalParser } from '@app/feature.importexport/src/main/ets/vcalendar/VCalParser'
import { TestUtil } from '../../utils/TestUtil'
import { VcsComponent } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/VcsComponent'
import { Property } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Property'
import { Parameter } from '@app/feature.importexport/src/main/ets/vcalendar/import/model/Parameter'

export default function VCalParserTest() {
  describe('VCalParserTest', () => {
    let parser: VCalParser;
    beforeEach(() => {
      parser = new VCalParser();
    });

    it('startTest', 0, () => {
      let start: Function | null = TestUtil.getPrivateFunction(parser, 'start');
      if (!start) {
        expect(start).assertNull();
      } else {
        start();
        const isCancel: boolean = TestUtil.getPrivateAttribute(parser, 'isCancel');
        expect(isCancel).assertFalse();
      }
    });

    it('parseComponentTest', 0, async () => {
      let parseComponent: Function | null = TestUtil.getPrivateFunction(parser, 'parseComponent');
      if (!parseComponent) {
        expect(parseComponent).assertNull();
      } else {
        expect((await parseComponent()) as VcsComponent | undefined).assertUndefined();
      }
    });

    it('normalizeTest_001', 0, async () => {
      let normalize: Function | null = TestUtil.getPrivateFunction(parser, 'normalizeText');
      if (!normalize) {
        expect(normalize).assertNull();
      } else {
        const inputStr: string = 'This is a test string'
        const outputStr: string = normalize(inputStr);
        expect(outputStr).assertEqual('This is a test string');
      }
    });

    it('normalizeTest_002', 0, async () => {
      let normalize: Function | null = TestUtil.getPrivateFunction(parser, 'normalizeText');
      if (!normalize) {
        expect(normalize).assertNull();
      } else {
        const inputStr: string = 'This is a test string\r\n'
        const outputStr: string = normalize(inputStr);
        expect(outputStr).assertEqual('This is a test string\n');
      }
    });

    it('normalizeTest_003', 0, async () => {
      let normalize: Function | null = TestUtil.getPrivateFunction(parser, 'normalizeText');
      if (!normalize) {
        expect(normalize).assertNull();
      } else {
        const inputStr: string = 'This is a test string= 1'
        const outputStr: string = normalize(inputStr);
        expect(outputStr).assertEqual('This is a test string=  1');
      }
    });

    it('normalizeTest_004', 0, async () => {
      let normalize: Function | null = TestUtil.getPrivateFunction(parser, 'normalizeText');
      if (!normalize) {
        expect(normalize).assertNull();
      } else {
        const inputStr: string = 'This is a test string\uFEFF'
        const outputStr: string = normalize(inputStr);
        expect(outputStr).assertEqual('This is a test string');
      }
    });

    it('parseEqualsSpaceSequenceTest_001', 0, async () => {
      let parseEqualsSpaceSequence: Function | null = TestUtil.getPrivateFunction(parser, 'parseEqualsSpaceSequence');
      if (!parseEqualsSpaceSequence) {
        expect(parseEqualsSpaceSequence).assertNull();
      } else {
        const inputStr: string = 'This is a test string\n abc=';
        const outputStr: string = parseEqualsSpaceSequence(inputStr);
        expect(outputStr).assertEqual('This is a test string abc=\r\n');
      }
    });

    it('parseEqualsSpaceSequenceTest_002', 0, async () => {
      let parseEqualsSpaceSequence: Function | null = TestUtil.getPrivateFunction(parser, 'parseEqualsSpaceSequence');
      if (!parseEqualsSpaceSequence) {
        expect(parseEqualsSpaceSequence).assertNull();
      } else {
        const inputStr: string = 'This is a test string\n abc';
        const outputStr: string = parseEqualsSpaceSequence(inputStr);
        expect(outputStr).assertEqual('This is a test string abc');
      }
    });


    it('isEndOfValueTest_001', 0, async () => {
      let isEndOfValue: Function | null = TestUtil.getPrivateFunction(parser, 'isEndOfValue');
      if (!isEndOfValue) {
        expect(isEndOfValue).assertNull();
      } else {
        const inputStr: string = '';
        const result: string = isEndOfValue(inputStr);
        expect(result).assertTrue();
      }
    });

    it('isEndOfValueTest_002', 0, async () => {
      let isEndOfValue: Function | null = TestUtil.getPrivateFunction(parser, 'isEndOfValue');
      if (!isEndOfValue) {
        expect(isEndOfValue).assertNull();
      } else {
        const inputStr: string = 'abc';
        const result: string = isEndOfValue(inputStr);
        expect(result).assertTrue();
      }
    });

    it('isQopEncodedTest_001', 0, async () => {
      let isQopEncoded: Function | null = TestUtil.getPrivateFunction(parser, 'isQopEncoded');
      if (!isQopEncoded) {
        expect(isQopEncoded).assertNull();
      } else {
        const input: Property = new Property('abc');
        const result: string = isQopEncoded(input);
        expect(result).assertFalse();
      }
    });

    it('parseComponentImplTest_001', 0, async (done: Function) => {
      let parseComponentImpl: Function | null = TestUtil.getPrivateFunction(parser, 'parseComponentImpl');
      if (!parseComponentImpl) {
        expect(parseComponentImpl).assertNull();
      } else {
        const component: VcsComponent = new VcsComponent('AAA',undefined);
        const text: string = 'AAA';
        const isCalDev: boolean = false;
        const countryCode = 'countryCode';
        const result: VcsComponent | undefined = await parseComponentImpl(component, text, isCalDev, countryCode);
        expect(result !== undefined).assertTrue();
        done();
      }
    });

    it('parseComponentImplTest_002', 0, async (done: Function) => {
      let parseComponentImpl: Function | null = TestUtil.getPrivateFunction(parser, 'parseComponentImpl');
      if (!parseComponentImpl) {
        expect(parseComponentImpl).assertNull();
      } else {
        const component: VcsComponent = new VcsComponent('AAA',undefined);
        const text: string = 'AAA';
        const isCalDev: boolean = false;
        const result: VcsComponent | undefined = await parseComponentImpl(component, text, isCalDev);
        expect(result !== undefined).assertTrue();
        done();
      }
    });

    it('parseComponentImplTest_003', 0, async (done: Function) => {
      let parseComponentImpl: Function | null = TestUtil.getPrivateFunction(parser, 'parseComponentImpl');
      if (!parseComponentImpl) {
        expect(parseComponentImpl).assertNull();
      } else {
        const component: VcsComponent = new VcsComponent('AAA',undefined);
        const text: string = '';
        const isCalDev: boolean = false;
        const countryCode = 'countryCode';
        const result: VcsComponent | undefined = await parseComponentImpl(component, text, isCalDev, countryCode);
        expect(result !== undefined).assertTrue();
        done();
      }
    });

    it('parseComponentImplTest_004', 0, async (done: Function) => {
      let parseComponentImpl: Function | null = TestUtil.getPrivateFunction(parser, 'parseComponentImpl');
      if (!parseComponentImpl) {
        expect(parseComponentImpl).assertNull();
      } else {
        const component: VcsComponent = new VcsComponent('AAA',undefined);
        const text: string = 'AAA';
        const isCalDev: boolean = false;
        const countryCode = 'countryCode';
        const result: VcsComponent | undefined = await parseComponentImpl(component, text, isCalDev, countryCode);
        expect(result !== undefined).assertTrue();
        done();
      }
    });

    it('getParameterTest_001', 0, async () => {
      let getParameter: Function | null = TestUtil.getPrivateFunction(parser, 'getParameter');
      if (!getParameter) {
        expect(getParameter).assertNull();
      } else {
        const state: ParserState = new ParserState();
        const singleLineStringContent: string = '';
        const parameter: Parameter | undefined = undefined;
        const equalIndex: number = 1;
        try {
          getParameter(state, singleLineStringContent, parameter, equalIndex);
        } catch (e) {
          expect(e.message).assertEqual("Expected parameter before \" in singleLineStringContent");
        }
      }
    });

    it('getParameterTest_002', 0, async () => {
      let getParameter: Function | null = TestUtil.getPrivateFunction(parser, 'getParameter');
      if (!getParameter) {
        expect(getParameter).assertNull();
      } else {
        const state: ParserState = new ParserState();
        const singleLineStringContent: string = '';
        const parameter: Parameter = new Parameter();
        const equalIndex: number = -1;
        try {
          getParameter(state, singleLineStringContent, parameter, equalIndex);
        } catch (e) {
          expect(e.message).assertEqual("Expected = within parameter in singleLineStringContent");
        }
      }
    });

    it('getParameterTest_003', 0, async () => {
      let getParameter: Function | null = TestUtil.getPrivateFunction(parser, 'getParameter');
      if (!getParameter) {
        expect(getParameter).assertNull();
      } else {
        let state: ParserState = new ParserState();
        state.index = 5;
        const singleLineStringContent: string = '';
        const parameter: Parameter = new Parameter();
        const equalIndex: number = 3;
        try {
          getParameter(state, singleLineStringContent, parameter, equalIndex);
        } catch (e) {
          expect(e.message).assertEqual("Parameter value cannot contain a \" in singleLineStringContent");
        }
      }
    });

    it('getParameterTest_004', 0, async () => {
      let getParameter: Function | null = TestUtil.getPrivateFunction(parser, 'getParameter');
      if (!getParameter) {
        expect(getParameter).assertNull();
      } else {
        let state: ParserState = new ParserState();
        const singleLineStringContent: string = 'ORGANIZER;CN=\\"xxx\\":mailto:xxx';
        const parameter: Parameter = new Parameter();
        const equalIndex: number = 0;
        try {
          getParameter(state, singleLineStringContent, parameter, equalIndex);
        } catch (e) {
          expect(e.message).assertEqual('Expected closing " in singleLineStringContent');
        }
      }
    });

    it('getParameterTest_005', 0, async () => {
      let getParameter: Function | null = TestUtil.getPrivateFunction(parser, 'getParameter');
      if (!getParameter) {
        expect(getParameter).assertNull();
      } else {
        let state: ParserState = new ParserState();
        const singleLineStringContent: string = 'ORGANIZER;CN=\"xxx\":mailto:xxx';
        state.singleLineStringContent= singleLineStringContent;
        state.index = 13
        const parameter: Parameter = new Parameter();
        const equalIndex: number = 13;
        const result: Parameter = getParameter(state, singleLineStringContent, parameter, equalIndex);
        expect(result.value).assertEqual('xxx');
      }
    });

    it('extractValue_001', 0, async () => {
      let extractValue: Function | null = TestUtil.getPrivateFunction(parser, 'extractValue');
      if (!extractValue) {
        expect(extractValue).assertNull();
      } else {
        let state: ParserState = new ParserState();
        state.singleLineStringContent = 'test';
        state.index = 5;
        try {
          extractValue(state);
        } catch (e) {
          expect(e.message).assertEqual('Expected : before end of line in singleLineStringContent');
        }
      }
    });

    it('extractValue_002', 0, async () => {
      let extractValue: Function | null = TestUtil.getPrivateFunction(parser, 'extractValue');
      if (!extractValue) {
        expect(extractValue).assertNull();
      } else {
        let state: ParserState = new ParserState();
        state.singleLineStringContent = 'test:value';
        state.index = 4;
        const result: string = extractValue(state);
        expect(result).assertEqual('value');
      }
    });
  })
}