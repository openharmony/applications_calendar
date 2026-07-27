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

import { BigFontSize, FontSizeScaleUtils, GlobalThis, Log, MINUTES_PER_DAY, MINUTES_PER_HOUR } from '@app/common';

const MAX_SELECT_MINUTE: number = 120;

const MAX_SELECT_HOUR: number = 23;

const MAX_SELECT_DAY: number = 30;

const INDEX_MINUTE: number = 0;

const INDEX_HOUR: number = 1;

const INDEX_DAY: number = 2;

@Component
export struct CustomizeReminderPicker {
  @StorageLink('language') @Watch('onLanguageChanged') language: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageProp('themeColor') themeColor: string = '';

  @State mUnitRange: string[] = [];

  @State mMaxValues: number[] = [MAX_SELECT_MINUTE, MAX_SELECT_HOUR, MAX_SELECT_DAY];

  @State mValueRanges: string[][] = [[], [], []];

  @State mUnitIndex: number = 0;

  @State mValueIndexes: number[] = [9, 0, 0];

  onValueChanged: (minute: number) => void = (minute: number) => {
  };

  onLanguageChanged(): void {
    this.generateOrRefreshUnitStr();
  }

  aboutToAppear(): void {
    // 生成右侧拨轮的 分钟、小时、天 文本
    this.generateOrRefreshUnitStr();

    // 生成左侧拨轮的 1-59（分钟）、1-23（小时）、1-30（天） 文本
    for (let unitIndex = 0; unitIndex < this.mUnitRange.length; unitIndex++) {
      if (unitIndex >= this.mMaxValues.length || unitIndex >= this.mValueRanges.length) {
        continue;
      }
      const maxValue = this.mMaxValues[unitIndex];
      const valueRangeArray = this.mValueRanges[unitIndex];
      valueRangeArray.splice(0, valueRangeArray.length);
      for (let valueIndex = 0; valueIndex < maxValue; valueIndex++) {
        valueRangeArray.push(`${valueIndex + 1}`);
      }
    }
  }

  private generateOrRefreshUnitStr(): void {
    this.mUnitRange.splice(0, this.mUnitRange.length);
    this.mUnitRange.push(GlobalThis.getPluralStr($r('app.plural.minutes_ago'), 0).replace('0', ''));
    this.mUnitRange.push(GlobalThis.getPluralStr($r('app.plural.hours_ago'), 0).replace('0', ''));
    this.mUnitRange.push(GlobalThis.getPluralStr($r('app.plural.days_ago'), 0).replace('0', ''));
  }

  build() {
    Row() {
      Stack() {
        ForEach(this.mUnitRange, (unit: string, unitIndex: number) => {
          // 单位不同时，使用不同的TextPicker组件，产生三种单位各自有缓存记忆的效果
          TextPicker({
            range: this.mValueRanges[unitIndex],
            selected: this.mValueIndexes[unitIndex]
          }).onChange((value: string | string[], valueIndex: number | number[]) => {
            if (typeof valueIndex === 'number'){
              this.mValueIndexes[unitIndex] = valueIndex;
              if (this.onValueChanged) {
                this.onValueChanged(this.getCurrentMinute());
              }
            }
          }).textStyle({ font: { size: this.dateFontChange(14) } })
            .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
            .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor })
            .visibility(this.mUnitIndex === unitIndex ? Visibility.Visible : Visibility.Hidden);
        });
      }

      TextPicker({
        range: this.mUnitRange,
      }).onChange((value: string | string[], index: number | number[]) => {
        this.mUnitIndex = index as number;
        if (this.onValueChanged) {
          this.onValueChanged(this.getCurrentMinute());
        }
      }).canLoop(false)
        .textStyle({ font: { size: this.dateFontChange(14) } })
        .disappearTextStyle({ font: { size: this.dateFontChange(14) } })
        .selectedTextStyle({ font: { size: this.dateFontChange(16) }, color: this.themeColor });
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  dateFontChange(def: number) {
    const dateTitleFontSize = FontSizeScaleUtils
      .getLimitFontSizeNum(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD, def);
    return dateTitleFontSize + 'vp';
  }

  private getCurrentMinute(): number {
    if (this.mUnitIndex < 0 || this.mUnitIndex >= this.mValueIndexes.length) {
      return 0;
    }
    const realValue = this.mValueIndexes[this.mUnitIndex] + 1;
    if (this.mUnitIndex === INDEX_MINUTE) {
      return realValue;
    } else if (this.mUnitIndex === INDEX_HOUR) {
      return realValue * MINUTES_PER_HOUR;
    } else if (this.mUnitIndex === INDEX_DAY) {
      return realValue * MINUTES_PER_DAY;
    } else {
      return realValue;
    }
  }
}