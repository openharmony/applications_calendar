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

import { AgendaEventInfo,
  BigFontSize,
  CalendarDate,
  CornerType, DateUtil,
  FontSizeScaleUtils,
  GlobalDataKeys,
  isChineseCalendar, Log, LunarDateUtil } from '@app/common/index';
import { ImportAllAgendaListItemContent } from './ImportAllAgendaListItemContent';

const TAG: string = 'ImportAllAgendaItem';

const ONE_DAY_MILL: number = 86400000;

/**
 * 日程list 的item样式
 *
 * @since 2022-09-20
 */
@Component
export struct ImportAllAgendaItem {
  @Consume navPathStack: NavPathStack;

  @Prop info: AgendaEventInfo;

  radius: number = 16;

  radiusMap: Array<number[]> = [
    [0, 0, 0, 0],
    [this.radius, this.radius, 0, 0],
    [0, 0, this.radius, this.radius],
    [this.radius, this.radius, this.radius, this.radius]
  ]

  @StorageProp('themeColor') themeColor: string = '';

  // 其它历法
  @StorageProp('subscriptionCalendar') subscriptionCalendar: number = -1;

  @StorageProp(GlobalDataKeys.CURRENT_DATE) currentDate: number = 0;

  //判断时间是否小于当天0点
  @State isToday: boolean = false;

  private accountColor: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  getDateTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      const nowDate: CalendarDate = new CalendarDate(this.currentDate);
      const today: number = new CalendarDate(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate()).getTime();

      const gapTime = Math.floor((jDate.getTime() - today) / ONE_DAY_MILL);
      this.isToday = (gapTime === 0);

      let dateString: string | Resource;
      const year = jDate.getFullYear();
      if (year !== nowDate.getFullYear()) {
        dateString = DateUtil.intlDateFormatChineseStyle(jDate, {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
      } else {
        dateString = DateUtil.intlDateFormatChineseStyle(jDate, { month: 'long', day: 'numeric' });
      }

      return dateString;
    }
    let localDate = new CalendarDate().setHours(0, 0, 0, 0);
    Log.debug(TAG, `localDate ` + localDate);
    if (localDate < time) {
      this.isToday = true;
    }
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, { month: 'long', day: 'numeric' });
  }

  getWeekTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      return DateUtil.intlDateFormatChineseStyle(jDate, { weekday: 'long' });
    }
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, { weekday: 'long' });
  }

  getLunarTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      return LunarDateUtil.toLunarDateString(jDate);
    }
    const dateTime = new CalendarDate(time);
    return LunarDateUtil.toLunarDateString(dateTime);
  }

  build() {
    Column() {
      if (this.info.mIsSetDayHead) {
        Row() {
          Text(this.getDateTime(this.info.mBegin))
            .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
              16
            ))
            .fontWeight(FontWeight.Bold)
            .fontColor($r('sys.color.font_primary'))
            .opacity($r('sys.float.alpha_90'))

          if (isChineseCalendar(this.subscriptionCalendar)) {
            Text(this.getLunarTime(this.info.mBegin))
              .fontWeight(FontWeight.Normal)
              .margin({ left: 12, right: 5 })
              .fontColor($r('sys.color.font_primary'))
              .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
                this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
                12
              ))
              .opacity($r('sys.float.alpha_secondary'))
          }
        }
        .alignItems(VerticalAlign.Center)
        .width('100%')
        .margin({ top: 8 })
        .padding({ right: 12 })
      }

      Column() {
        ImportAllAgendaListItemContent({
          info: this.info,
          accountColor: this.accountColor
        })
      }
      .padding({
        top: this.getHotspotPaddingTop(),
        bottom: this.getHotspotPaddingBottom()
      })
      .margin({ bottom: 12 })
      .width('100%')
      .borderRadius({
        topLeft: this.radiusMap[this.info.mCornerType][0],
        topRight: this.radiusMap[this.info.mCornerType][1],
        bottomLeft: this.radiusMap[this.info.mCornerType][2],
        bottomRight: this.radiusMap[this.info.mCornerType][3],
      })
    }
    .width('100%')
  }

  getHotspotPaddingTop(): number {
    if (this.info.mCornerType === CornerType.CORNER_NONE || this.info.mCornerType === CornerType.CORNER_DOWN) {
      return 0;
    }
    return 4;
  }

  getHotspotPaddingBottom(): number {
    if (this.info.mCornerType === CornerType.CORNER_NONE || this.info.mCornerType === CornerType.CORNER_UP) {
      return 0;
    }
    return 4;
  }
}