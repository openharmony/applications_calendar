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

import { EmptyUtils, GlobalThis, Log } from '@app/common';
import { BEGIN, END, VCALENDAR, VcsComponent, VEVENT } from './import/model/VcsComponent';
import { Property } from './import/model/Property';
import { Parameter } from './import/model/Parameter';
import ArrayList from '@ohos.util.ArrayList';
import { RESOURCES } from './import/parser/CalendarParser';
import { taskpool } from '@kit.ArkTS';

/**
 * Encoding name
 */
export const ENCODING_STRING = 'ENCODING';


const QUOTED_PRINTABLE_ENCODING = 'QUOTED-PRINTABLE';

/**
 * 数字负一(-1)
 */
const NEGATIVE_NUM_ONE = -1;

const EQUALS = '=  ';

const TAB = '=\t';

const LINE_FEED = '\n';

const ENTER_LINE_FEED = '\r\n';

const BOM = '\uFEFF';

const COLON = ':';

const SEMICOLON = ';';

const EQUAL_SIGN = '=';

const TAG = 'VCalParser';

const REGEX = new RegExp('\\\\n', 'gm');

export class ParserState {
  /**
   * singleLineStringContent
   */
  public singleLineStringContent: string = '';

  /**
   * 当前操作到字符串的index
   */
  public index: number = 0;
}

export enum VcsParseStatus {
  CALENDAR_PARSED,
  EACH_EVENT_PARSED,
  PARSE_FINISH
}

/**
 * Parses RFC 2445 iCalendar objects.
 */
export class VCalParser {
  private isCancel = false;
  private isCalendarParsed = false;
  private mIndex: number = 0;

  /**
   * Parses the provided text into an iCalendar object.The top-level
   * component must be of type VCALENDAR.
   *
   * @param text The text to be parsed.
   * @param listener VcsParseListener
   * @return The top-level VCALENDAR component.
   * @throws FormatException Thrown if the text could not be parsed into an
   * iCalendar VCALENDAR object.
   */
  public async parseCalendar(
    text: string,
    countryCode = ''
  ):
    Promise<VcsComponent | undefined> {
    this.start();
    const calendar: VcsComponent | undefined = await this.parseComponent(undefined, text, countryCode);
    // 根节点组件名不是VCALENDAR
    if (!calendar || VCALENDAR != calendar.getName()) {
      throw new Error(`parseCalendar Expected ${VCALENDAR} but the result is ${calendar?.getName()}`);
    }
    return calendar;
  }

  private start() {
    this.isCancel = false;
  }

  /**
   * Parses the provided text into an iCalendar component.
   *
   * @param text The text to be parsed.
   * @return The top-level component.
   * @throws FormatException Thrown if the text could not be parsed into an
   * iCalendar component.
   */
  private async parseComponent(
    component: VcsComponent | undefined,
    text: string,
    countryCode = ''
  ):
    Promise<VcsComponent | undefined> {
    let tempText: string = text;
    return await this.parseComponentImpl(component, tempText, countryCode);
  }

  private normalizeText(text: string): string {
    let tempText = text;
    // it's supposed to be \r\n, but not everyone does that
    tempText = tempText.replaceAll(ENTER_LINE_FEED, LINE_FEED);
    tempText = tempText.replaceAll('\r', LINE_FEED);

    // If "= " and "=\t" comes in a non QOP value it will be replaced with "=".Hence adding an extra
    // space and tab for "= " and "=\t" respecetively.
    tempText = tempText.replaceAll('= ', EQUALS).replaceAll(TAB, '=\t\t');

    // For multi line QOP values starting with " " we will replace "=\n " with "= \n "
    // In "= \n " "\n "will be removed in text.replaceAll("\n ", "").In parseLine() if
    // property is QOP encoded we will replace "= " with "=\r\n" and if it is non QOP value
    // replace with "=".The same holds for line starting with tab
    tempText = tempText.replaceAll('=\n ', '= \n ').replaceAll('=\n\t', '=\t\n\t');

    // we deal with line folding, by replacing all "\n " strings
    // with nothing.The RFC specifies "\r\n " to be folded, but
    // we handle "\n " and "\r " too because we can get those.
    tempText = tempText.replaceAll('\n ', '').replaceAll('\n\t', '');

    // 去掉String中的Bom
    tempText = tempText.replaceAll(BOM, '');

    return tempText;
  }

  private async parseComponentImpl(
    component: VcsComponent | undefined,
    text: string,
    countryCode = ''
  ):
    Promise<VcsComponent | undefined> {
    if (EmptyUtils.isEmptyString(text)) {
      Log.warn(TAG, `parseComponentImpl text is empty`);
      return component;
    }
    let currentParsedComponent: VcsComponent | undefined = component;
    let sourceComponent: VcsComponent | undefined = component;
    const state: ParserState = new ParserState();
    let stringContentLines: string[] = [];
    if (countryCode && countryCode !== '') {
      let res: string = '';
      res = JSON.stringify(text);
      res = res.substring(1, res.length - 1);
      stringContentLines = res.split('\\n');
    } else {
      text = this.normalizeText(text);
      stringContentLines = text.split(LINE_FEED);
    }
    if (EmptyUtils.isEmptyArray(stringContentLines)) {
      Log.warn(TAG, `parseComponentImpl stringContentLines is empty`);
      return sourceComponent;
    }
    Log.info(TAG, `parseComponentImpl stringContentLines length is ${stringContentLines.length}`);

    for (this.mIndex = 0; this.mIndex < stringContentLines.length; ) {
      try {
        if (this.isCancel) {
          break
        }
        currentParsedComponent = await this.parseSingleLine(stringContentLines[this.mIndex],
          state, currentParsedComponent, stringContentLines);
        // if the provided component was null, we will return the root
        // NOTE: in this case, if the first line is not BEGIN,FormatException will get thrown.
        if (!sourceComponent) {
          sourceComponent = currentParsedComponent;
        }
      } catch (err) {
        // to be emitting some misformatted iCalendar objects.
        Log.error(TAG, `parseComponentImpl error Cannot parse line ${this.mIndex} for ${err?.message}`);
        this.mIndex++;
      }
    }
    return sourceComponent;
  }

  /**
   * Parses a line into the provided component.Creates a new component if
   * the line is a BEGIN, adding the newly created component to the provided
   * parent.Returns whatever component is the current one (to which new
   * properties will be added) in the parse.
   *
   * BEGIN:VCALENDAR  分割符':'
   * VERSION:1.0
   * TZ:+08:00
   * BEGIN:VEVENT
   * COMPLETED:20231207T130000
   * DTSTART:20231207T120000
   * AALARM:20231207T035000;;;
   * CLASS:PUBLIC
   * DTEND:20231207T130000
   * SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E5=8F=91=E5=A4=AA=E5=A4=AA=E5=A4=AA 分割符';'
   * STATUS:CONFIRMED
   * EVENTTYPEEXT:NORMALEVENTTYPE
   * EVENTALERTTYPE:NORMALALERT
   * EVENTCALENDARTYPE:SOLAR
   * END:VEVENT
   * END:VCALENDAR
   *
   * @param line line
   * @param state state
   * @param component component
   * @param lines lines
   * @return component
   * @throws FormatException FormatException
   */
  private async parseSingleLine(singleLineStringContent: string, state: ParserState,
                                preComponent: VcsComponent | undefined,
                                stringContentLines: string[]): Promise<VcsComponent | undefined> {
    state.singleLineStringContent = singleLineStringContent;
    const contentLength: number = singleLineStringContent.length;

    let splitChar: string = '';
    let name: string = '';

    for (state.index = 0; state.index < contentLength; ) {
      splitChar = singleLineStringContent.charAt(state.index);
      if (splitChar == ';' || splitChar == ':') {
        break;
      }
      state.index++;
    }
    if (state.index >= 0 && state.index < singleLineStringContent.length) {
      name = singleLineStringContent.substring(0, state.index);
      splitChar = singleLineStringContent.charAt(state.index);
    }
    // preComponent == null 时表明是在解析第一个Component
    // 解析第一个Component 第一行的name必须是BEGIN,否则脏文件
    if (!preComponent && BEGIN != name) {
      throw new Error('Expected BEGIN:' + name);
    }
    let property: Property;
    if (BEGIN == name) { // 开始行,一个组件的构建开始,构建完后,添加到parent中
      // start a new component
      const componentName: string = this.extractValue(state);
      Log.info(TAG, `parseSingleLine BEGIN componentName is ${componentName}`)
      const child: VcsComponent = new VcsComponent(componentName, preComponent);
      if (preComponent) {
        preComponent.addChild(child);
      }
      await this.onComponentBeginLineParse(preComponent, componentName);
      this.mIndex++;
      return child;
    } else if (END == name) { // 结束行
      // finish the current component
      const componentName: string = this.extractValue(state);
      Log.info(TAG, `parseSingleLine END componentName is ${componentName} preComponentName is ${preComponent?.getName()} index is ${this.mIndex}`);
      await this.onComponentEndLineParsed(preComponent as VcsComponent, componentName);
      this.mIndex++;
      // 返回当前解析的Component 的parent,解析parent 的下一个child
      return preComponent?.getParent();
    } else if (state.index == contentLength) { // 这一行没有value
      Log.info(TAG, `parseSingleLine no value  state.index ${state.index} contentLength is ${contentLength}`);
      this.onParsingNoValueLine(stringContentLines, singleLineStringContent, preComponent);
      this.mIndex++;
      return preComponent;
    } else {
      // 一行一行的填充属性
      property = new Property(name);
      Log.debug(TAG, `parseSingleLine property propertyName is ${name}`);
      if (RESOURCES === name) {
        return this.fillResourcesComponent(state, preComponent, property);
      }
      return this.fillComponent(state, preComponent, stringContentLines, splitChar, property);
    }
  }

  private fillResourcesComponent(state: ParserState, currentComponent: VcsComponent | undefined,
    property: Property): VcsComponent {
    let value: string = state.singleLineStringContent
    this.mIndex++; // move to next line
    const index = value.indexOf(EQUAL_SIGN);
    value = value.substring(index + 1);
    property.setValue(value);
    currentComponent?.addProperty(property);
    return currentComponent as VcsComponent;
  }

  private onParsingNoValueLine(stringContentLines: string[], singleLineContent: string, preComponent: VcsComponent | undefined) {
    if (this.mIndex == 0 || this.mIndex > stringContentLines.length || !preComponent) {
      return;
    }
    // todo 为什么是获取的上一行
    const singleLineStringContent: string = stringContentLines[this.mIndex - 1];
    let ch: string = '';
    let index = 0;
    for (let index = 0; index < singleLineStringContent.length; index++) {
      ch = singleLineStringContent.charAt(index);
      if (ch == ';' || ch == ':') {
        break;
      }
    }
    if (index < 0 || index > singleLineStringContent.length) {
      Log.warn(TAG, 'onParsingNoValueLine index is invalid!');
      return;
    }
    const name: string = singleLineStringContent.substring(0, index);
    Log.info(TAG, `onParsingNoValueLine index is ${index} name is ${name}`);
    const property: Property | undefined = preComponent.getFirstProperty(name);
    if (property) {
      const value: string = property.getValue() + '\n' + singleLineStringContent;
      property.setValue(value);
    }
  }


  /**
   * SUMMARY;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E8=AF=B7=E9=97=AE=E9=97=AE=E9=97=AE=E5=84=BF=E7=AB=A5=E8=8B=B1=E8=AF=
   * =AD=E4=B8=8E=E4=B8=83=E4=BA=8C=E5=A4=A9=E5=A4=A9=E5=98=A4=E5=98=A4=E5=  是"=" 结尾,标志qop编码的value还有下一行内容,继续循环解析
   * =98=A4=E5=98=A4  到这一行不是"=" 结尾,标志qop编码的value结束了
   * @param state
   * @param currentComponent
   * @param stringContentLines
   * @param splitChar
   * @param property
   * @returns
   */
  private fillComponent(state: ParserState, currentComponent: VcsComponent | undefined, stringContentLines: string[], splitChar: string, property: Property): VcsComponent {
    // 解析qop编码的参数如 CHARSET=UTF-8  ENCODING=QUOTED-PRINTABLE 或 全天日程 DTSTART;VALUE=DATE:20240108
    // 或caldav 时区偏移的日程 DTSTART;TZID=Pacific/Kosrae:20240518T180000
    if (SEMICOLON == splitChar) {
      let parameter: Parameter | undefined = undefined;
      try {
        parameter = this.extractParameter(state);
      } catch (err) {
        Log.error(TAG, `fillComponent error ${err?.message}`);
      }
      while (parameter) {
        property.addParameter(parameter as Parameter);
        parameter = this.extractParameter(state);
      }
    }
    let value: string = this.extractValue(state);
    this.mIndex++; // move to next line
    if (this.isQopEncoded(property)) {
      Log.info(TAG, `fillComponent isQopEncoded true decode`);
      let qopValue: string = this.parseEqualsSpaceSequence(value);
      // 如果不是qop编码 value的结束行,就继续拼接value
      if (!this.isEndOfValue(value)) {
        qopValue = qopValue + this.extractQopValue(stringContentLines);
      }
      value = qopValue.replace('=0D=0A', '=0A');
    } else {
      /*
       * replacing "= " and "=\t" with "\r\n" as we are sure that "\r\n" doesn't exist in value.
       * Also we can't simply replace "= " with "=" and the "=\t"
       * with "=" as "= \t" will be replaced wrongly with "=".
       */
      value = value.replace('= ', ENTER_LINE_FEED).replace(TAB, ENTER_LINE_FEED);
      value = value.replace(ENTER_LINE_FEED, '=');
      value = value.replace(REGEX, ENTER_LINE_FEED);
    }
    property.setValue(value);
    currentComponent?.addProperty(property);
    return currentComponent as VcsComponent;
  }

  private extractQopValue(stringContentLines: string[]): string {
    let parsedSQopString: string = '';
    while (this.mIndex < stringContentLines.length) {
      const value: string = stringContentLines[this.mIndex];
      parsedSQopString = parsedSQopString + this.parseEqualsSpaceSequence(value);
      this.mIndex++;
      if (this.isEndOfValue(value)) {
        break
      }
    }
    return parsedSQopString;
  }


  /**
   * Method to handle "= " or "\t" sequence in the value parameter."= " and "=\t " in the value will be replaced
   * with "=\n " and "=\n\t" respectively and then value will be split at "\n" and each "=" will be replace with
   * "=\r\n" as defined by QOP standard.
   *
   * @author S72938
   * @param valueBuilder - string builder to store the whole QOP value.
   * @param value - current line in multi line QOP value.
   */
  private parseEqualsSpaceSequence(singleLineStringContent: string): string {
    const value: string = singleLineStringContent.replace('= ', '= \n').replace(TAB, '=\n\t');
    const values: string[] = value.split(LINE_FEED);
    let parsedString = '';
    for (let valuesElement of values) {
      if (!this.isEndOfValue(valuesElement)) {
        parsedString = parsedString + valuesElement + ENTER_LINE_FEED;
      } else {
        parsedString = parsedString + valuesElement;
      }
    }
    return parsedString;
  }

  private isEndOfValue(valuesElement: string) {
    return EmptyUtils.isEmptyString(valuesElement) || !valuesElement.endsWith('=');
  }

  private extractParameter(state: ParserState): Parameter | undefined {
    const singleLineStringContent: string = state.singleLineStringContent;
    const length: number = singleLineStringContent.length;
    let startIndex: number = NEGATIVE_NUM_ONE;
    let equalIndex: number = NEGATIVE_NUM_ONE;
    let parameter: Parameter | undefined = undefined;
    while (state.index < length) {
      const char: string = singleLineStringContent.charAt(state.index);
      if (COLON == char) {
        if (parameter) {
          if (equalIndex == NEGATIVE_NUM_ONE) {
            Log.error(TAG, `Expected = within parameter in singleLineStringContent`);
            throw new Error(`Expected = within parameter in singleLineStringContent`);
          }
          parameter.value = singleLineStringContent.substring(equalIndex + 1, state.index);
          Log.info(TAG, `COLON extractParameter set parameter.value`);
        }
        // qqp 编码的循环到内容后,这里会返回null
        return parameter; // may be null
      } else if (SEMICOLON == char) {
        if (parameter) { // 有多个属性的时候,如果已经创建了parameter 直接截取属性值
          if (equalIndex == NEGATIVE_NUM_ONE) {
            Log.error(TAG, `Expected = within parameter in singleLineStringContent`);
            throw new Error(`Expected = within parameter in singleLineStringContent`);
          }
          parameter.value = singleLineStringContent.substring(equalIndex + 1, state.index);
          Log.info(TAG, `SEMICOLON extractParameter set parameter.value`);
          return parameter; // may be null
        } else { // DTSTART;TZID=Pacific/Kosrae:20240518T180000 遍历字符,根据';'到这截取创建属性
          parameter = new Parameter();
          startIndex = state.index;
          Log.info(TAG, `extractParameter new Parameter`);
        }
      } else if ('=' == char) { // DTSTART;TZID=Pacific/Kosrae:20240518T180000 遍历字符, 根据'='到这截取属性名
        equalIndex = state.index;
        if (!parameter || startIndex == NEGATIVE_NUM_ONE) {
          Log.error(TAG, `Expected ; before = in singleLineStringContent`);
          throw new Error(`Expected ; before = in singleLineStringContent`);
        }
        parameter.name = singleLineStringContent.substring(startIndex + 1, equalIndex);
        Log.info(TAG, `extractParameter set parameter name is ${parameter.name}`);
      } else if ('"' == char) {
        Log.info(TAG, `extractParameter quete`);
        return this.getParameter(state, singleLineStringContent, parameter, equalIndex);
      } else {
        Log.debug(TAG, 'no else case');
      }
      state.index++;
    }
    return parameter;
  }

  private getParameter(state: ParserState, singleLineStringContent: string, parameter: Parameter | undefined, equalIndex: number): Parameter {
    if (!parameter) {
      throw new Error(`Expected parameter before " in singleLineStringContent`);
    }
    if (equalIndex == NEGATIVE_NUM_ONE) {
      throw new Error(`Expected = within parameter in singleLineStringContent`);
    }
    if (state.index > equalIndex + 1) {
      throw new Error(`Parameter value cannot contain a " in singleLineStringContent`);
    }
    // ORGANIZER;CN="xxx":mailto:xxx
    // 这种里面的parameter 使用了双引号包裹
    const endQuote: number = singleLineStringContent.indexOf('"', state.index + 1);
    if (endQuote < 0) {
      throw new Error(`Expected closing " in singleLineStringContent`);
    }
    parameter.value = singleLineStringContent.substring(state.index + 1, endQuote);
    state.index = endQuote + 1;
    return parameter;
  }

  private isQopEncoded(property: Property): boolean {
    let expectedList = property.getParameters(ENCODING_STRING);
    if (EmptyUtils.isEmptyArray(expectedList)) {
      return false;
    }
    const parameter: Parameter = expectedList[0];
    return QUOTED_PRINTABLE_ENCODING == parameter.value;
  }

  /**
   * 当组件的开始行被解析完后,有日程的vcs文件,calendar的有效信息解析结束标记是一个Event 行的开始
   * @param currentComponent
   * @param componentName
   */
  private async onComponentBeginLineParse(currentComponent: VcsComponent | undefined, componentName: string) {
    if (VEVENT == componentName) {
      await this.callCalendarParsedIfNecessary(currentComponent);
    }
  }

  private async callCalendarParsedIfNecessary(calendar: VcsComponent | undefined) {
    if (calendar && !this.isCalendarParsed) {
      this.isCalendarParsed = true;
      try {
        taskpool.Task.sendData(VcsParseStatus.CALENDAR_PARSED, calendar);
      } catch (err) {
        Log.logErrorMsg(TAG, 'callCalendarParsedIfNecessary error:', err)
      }
    }
  }


  /**
   * 当组件的结束行被解析完后
   * @param currentComponent
   * @param componentName
   */
  private async onComponentEndLineParsed(currentComponent: VcsComponent, componentName: string) {
    if (VEVENT == componentName) {
      await this.callEachEventParsed(currentComponent);
      return;
    }
    if (VCALENDAR == componentName || componentName.startsWith('VCAL')) {
      // 在这里被回调日历账户解析完,只能是分享了账户但是账户里没有日程
      await this.callCalendarParsedIfNecessary(currentComponent);
      await this.callParseFinished();
    }
  }

  private async callEachEventParsed(event: VcsComponent) {
    try {
      taskpool.Task.sendData(VcsParseStatus.EACH_EVENT_PARSED, event);
    } catch (err) {
      Log.logErrorMsg(TAG, 'callEachEventParsed error:', err)
    }
  }



  private callParseFinished() {
    try {
      taskpool.Task.sendData(VcsParseStatus.PARSE_FINISH);
    } catch (err) {
      Log.logErrorMsg(TAG, 'callParseFinished error:', err)
    }
  }


  private extractValue(state: ParserState): string {
    const singleLineStringContent: string = state.singleLineStringContent;
    if (state.index >= singleLineStringContent.length || singleLineStringContent.charAt(state.index) !== ':') {
      throw new Error(`Expected : before end of line in singleLineStringContent`);
    }
    const value: string = singleLineStringContent.substring(state.index + 1);
    state.index = singleLineStringContent.length - 1;
    return value;
  }
}