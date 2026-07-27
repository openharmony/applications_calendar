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

import { HashMap } from '@kit.ArkTS';
import { GlobalThis } from '../data/GlobalThis';
import { PreferencesUtil } from '../default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '../default/util/preferences_util/PreferencesFiles';
import { Log } from '../default/common/Log';

// 标识节日缩写
export class FestivalAbbreviationMap {
  private static festivalAbbreviationMap: HashMap<string, string>;

  constructor() {
  }

  static getInstance(): HashMap<string, string> {
    if (!FestivalAbbreviationMap.festivalAbbreviationMap) {
      FestivalAbbreviationMap.init();
    }
    return FestivalAbbreviationMap.festivalAbbreviationMap;
  }

  static freshFestivalAbbreviationMap(language: string) {
    FestivalAbbreviationMap.init(language);
  }

  static init(language: string = '') {
    FestivalAbbreviationMap.festivalAbbreviationMap = new HashMap();
    let holidayAbbreviationArray =
      PreferencesUtil.getStringArrayValueSync(PreferencesFiles.HOLIDAY, 'holidayAbbreviationInfo');
    for (let holidayAbbreviation of holidayAbbreviationArray) {
      let holidayAbbreviationData = holidayAbbreviation.split(':');
      // holidayAbbreviationData[0]为原日程名称 holidayAbbreviationData[1]为缩略字段名称
      FestivalAbbreviationMap.festivalAbbreviationMap.set(holidayAbbreviationData[0], holidayAbbreviationData[1]);
    }
    if (FestivalAbbreviationMap.festivalAbbreviationMap.length !== 0) {
      return;
    }
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.macao_reunification_day'), language),
      GlobalThis.getResourceStr($r('app.string.macao_return_to_china'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.chinese_peoples_police_day'), language),
      GlobalThis.getResourceStr($r('app.string.police_day'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.consumers_rights_day'), language),
      GlobalThis.getResourceStr($r('app.string.consumer_day'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.victory_day_of_the_Chinese_People_war_of_resistance_against_japan'), language),
      GlobalThis.getResourceStr($r('app.string.victory_in_the_war_of_resistance_against_japan'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.national_memorial_day'), language),
      GlobalThis.getResourceStr($r('app.string.public_sacrifice_day'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.september_eighteenth_incident'), language), '九一八');
    FestivalAbbreviationMap.festivalAbbreviationMap.set(
      GlobalThis.getResourceStr($r('app.string.chinese_martyrs_Day'), language),
      GlobalThis.getResourceStr($r('app.string.martyrs_memorial'), language));
    FestivalAbbreviationMap.festivalAbbreviationMap.set('日本投降日', '日本投降');
    FestivalAbbreviationMap.festivalAbbreviationMap.set('辛亥革命纪念日', '辛亥革命');
    FestivalAbbreviationMap.festivalAbbreviationMap.set('抗美援朝纪念日', '抗美援朝');
  }
}