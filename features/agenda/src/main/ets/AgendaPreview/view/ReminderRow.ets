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

import { BigFontSize, CalendarContract, FontSizeScaleUtils, ReminderUtil, I18nUtil, Log } from '@app/common';
import { DividerLine } from '../../CreateAgenda/view/DividerLine';

const TAG = 'ReminderRow';

@Component
export struct ReminderRow {
  @Prop checkValuesArray: CalendarContract.Reminders[];

  @Prop mIsAllDay: boolean;

  private needShowImportantAler: boolean = true;

  @StorageLink('language') @Watch('onLanguageChange') language : string = '';

  @State reminderSeparator: string = '';

  private paddingLeft: Length = $r('sys.float.padding_level4');

  private paddingRight: Length = $r('sys.float.padding_level4');

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  aboutToAppear(): void {
    this.setReminderSeparator();
  }

  private setReminderSeparator() {
    const newLanguage = I18nUtil.getSystemLanguage();
    const isEnglish = I18nUtil.isEnglishLanguage(newLanguage);
    this.reminderSeparator = isEnglish ? ', ' : ','; // 英文逗号之后要有空格
  }

  onLanguageChange() {
    this.setReminderSeparator();
  }

  @Builder
  buildRowReminder() {
    Row() {
      Text($r('app.string.preferences_reminder_title'))
        .align(Alignment.Start)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))

      Text() {
        // 若日程本来没有提醒时间时，需要显示“无”
        if (this.checkValuesArray.length === 0) {
          Span($r('app.string.no_calendar_display_name'));
        } else {
          if (this.checkValuesArray.length > 0) {
            Span(ReminderUtil.getReminderText(this.checkValuesArray[0].remindMinutes,
              this.mIsAllDay, this.language))
          }
          if (this.checkValuesArray.length > 1 && !FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale)) {
            Span(this.reminderSeparator)
            Span(ReminderUtil.getReminderText(this.checkValuesArray[1].remindMinutes,
              this.mIsAllDay, this.language))
          }
          if (this.checkValuesArray.length > 2 && !this.mIsAllDay &&
            !FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale)) { //非全天日程可以显示三项
            Span(this.reminderSeparator)
            Span(ReminderUtil.getReminderText(this.checkValuesArray[2].remindMinutes,
              this.mIsAllDay, this.language))
          }
          if ((this.checkValuesArray.length > 2 && this.mIsAllDay) ||
            (this.checkValuesArray.length > 3 && !this.mIsAllDay) ||
            (this.checkValuesArray.length > 1 && FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale))) {
            Span('...')
          }
        }
      }
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_secondary'))
        .textAlign(TextAlign.End)
        .margin({ right: $r('sys.float.padding_level4') })
        .wordBreak(WordBreak.BREAK_WORD)
        .flexShrink(1)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level8'))
    .height(56)
    .padding({ left: $r('sys.float.padding_level4') })
    .backgroundColor(Color.Transparent)
    .accessibilityLevel('yes')
    .accessibilityGroup(true)

    DividerLine().padding({ left: this.paddingLeft, right: this.paddingRight })
      .visibility(this.needShowImportantAler ? Visibility.Visible : Visibility.Hidden)
  }

  @Builder
  buildColumnReminder() {
    Column() {
      Row() { // 此处的 row 作为 text 的容器，限制text的大小
        Text($r('app.string.preferences_reminder_title'))
          .align(Alignment.Start)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .padding({ left: 0 })
          .layoutWeight(FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale) ? 1 : undefined)
          .margin({
            top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
            bottom: 0
          })
      }

      Text() {
        if (this.checkValuesArray.length > 0) {
          Span(ReminderUtil.getReminderText(this.checkValuesArray[0].remindMinutes,
            this.mIsAllDay, this.language))
        }
        if (this.checkValuesArray.length > 1 && !FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale)) {
          Span(this.reminderSeparator)
          Span(ReminderUtil.getReminderText(this.checkValuesArray[1].remindMinutes,
            this.mIsAllDay, this.language))
        }
        if (this.checkValuesArray.length > 2 && !this.mIsAllDay &&
          !FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale)) { //非全天日程可以显示三项
          Span(this.reminderSeparator)
          Span(ReminderUtil.getReminderText(this.checkValuesArray[2].remindMinutes,
            this.mIsAllDay, this.language))
        }
        if ((this.checkValuesArray.length > 2 && this.mIsAllDay) ||
          (this.checkValuesArray.length > 3 && !this.mIsAllDay) ||
          (this.checkValuesArray.length > 1 && FontSizeScaleUtils.isGreaterThanStandard(this.fontSizeScale))) {
          Span('...')
        }
      }
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Regular)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .fontColor($r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_secondary'))
        .textAlign(TextAlign.Start)
        .margin({ right: $r('sys.float.padding_level4') })
        .wordBreak(WordBreak.BREAK_WORD)
        .constraintSize({ minHeight: 56 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level8'))
    .constraintSize({ minHeight: 56 })
    .padding({ left: $r('sys.float.padding_level4') })
    .backgroundColor(Color.Transparent)
    .accessibilityLevel('yes')
    .accessibilityGroup(true)

    DividerLine().padding({ left: this.paddingLeft, right: this.paddingRight })
      .visibility(this.needShowImportantAler ? Visibility.Visible : Visibility.Hidden)
  }

  build() {
    if (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD) {
      this.buildColumnReminder()
    } else {
      this.buildRowReminder()
    }
  }
}