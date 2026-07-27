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

import { BigFontSize, FontSizeScaleUtils, GlobalThis, I18nUtil } from '@app/common';
import { ReminderUtil } from '@app/common';

const MAX_SELECT_DAY: number = 30;

@Component
export struct CustomizeAllDayReminderPicker {
  @StorageProp('is24HourClock') is24Hour: boolean = I18nUtil.is24HourClock();

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('language') @Watch('onLanguageChanged') language: string = '';

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @State mUnitRange: string[] = [];

  @State mDayRange: string[] = [];

  @State mDayIndex: number = 0;

  @State mSelectedTime: Date = new Date();

  private customizeHour: number = 9;

  private customizeMinute: number = 0;

  onValueChanged: (minute: number) => void = (minute: number) => {
  };

  onLanguageChanged(): void {
    this.generateOrRefreshDayRangeStr();
  }

  aboutToAppear(): void {
    this.generateOrRefreshDayRangeStr();
    this.mSelectedTime.setHours(this.customizeHour, this.customizeMinute, 0, 0);
  }

  build() {
    Row() {
      TextPicker({
        range: this.mDayRange,
        selected: this.mDayIndex
      }).textStyle({ font: { size: this.dateFontChange(14) } })
        .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
        .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
        .layoutWeight(2)
        .onChange((value: string | string[], index: number | number[]) => {
          this.mDayIndex = index as number;
          if (this.onValueChanged) {
            this.onValueChanged(this.getCurrentMinute());
          }
        });

      TimePicker({ selected: this.mSelectedTime })
        .useMilitaryTime(this.is24Hour)
        .textStyle({ font: { size: this.dateFontChange(14) } })
        .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
        .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
        .layoutWeight(this.is24Hour ? 2 : 3)
        .onChange((timeResult: TimePickerResult) => {
          this.customizeHour = timeResult.hour;
          this.customizeMinute = timeResult.minute;
          this.mSelectedTime.setHours(this.customizeHour, this.customizeMinute, 0, 0);
          if (this.onValueChanged) {
            this.onValueChanged(this.getCurrentMinute());
          }
        });
    }
    .width('100%')
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
  }

  dateFontChange(def: number) {
    const dateTitleFontSize = FontSizeScaleUtils
      .getLimitFontSizeNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD, def);
    return dateTitleFontSize + 'vp';
  }

  private generateOrRefreshDayRangeStr() {
    this.mDayRange.splice(0, this.mDayRange.length);
    for (let valueIndex = 0; valueIndex < MAX_SELECT_DAY; valueIndex++) {
      if (valueIndex === 0) {
        this.mDayRange.push(GlobalThis.getResourceStr($r('app.string.on_the_same_day'), this.language));
      } else {
        this.mDayRange.push(GlobalThis.getPluralStr($r('app.plural.days_ago'), valueIndex, this.language));
      }
    }
  }

  private getCurrentMinute(): number {
    const dayOffset = this.mDayIndex;
    return ReminderUtil.generateAllDayReminderMinute(dayOffset, this.customizeHour, this.customizeMinute);
  }
}