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

import i18n from '@ohos.i18n';
import {
  CalendarDate,
  CornerType, DateUtil,
  GlobalDataKeys,
  isChineseCalendar, Log, LunarDateUtil, ReportUtil, statisticEvents } from '@app/common';
import { DeleteEventProcessor } from '../agenda/DeleteEventProcessor';

const TAG: string = 'DeleteItem';

/**
 * 日程删除列列表项，包含日程item和日期item
 *
 * @since 2022-09-27
 */

export enum SelectState {

  UNDEFINED = -1,

  ALL_SELECT = 1,

  ALL_UNSELECT = 0
}

@Component
export struct EventContentItem {
  @StorageProp('themeColor') themeColor: string = '';

  eventId: number = 0;

  radius: number = 16;

  enableCorner: number = this.radius;

  radiusMap: Array<number[]> = [
    [0, 0, 0, 0],
    [this.enableCorner, this.enableCorner, 0, 0],
    [0, 0, this.enableCorner, this.enableCorner],
    [this.enableCorner, this.enableCorner, this.enableCorner, this.enableCorner]
  ]

  title: ResourceStr = '';

  begin: number = 0;

  end: number = 0;

  color: number = 0;

  cornerType: number = 0;

  location: string = '';

  isAllDay: boolean = false;

  eventProcessor: DeleteEventProcessor = new DeleteEventProcessor();

  handClicked: boolean = false;

  @State checked: boolean = false;

  @StorageLink('is24HourClock') is24HourClock: boolean = false;

  onCheckChanged: (id: number, checked: boolean) => void = (): void => {
  };

  getDateTime(time: number) {
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, { month: 'long', day: 'numeric', weekday: 'long' })
  }

  getLunarTime(time: number) {
    const dateTime = new CalendarDate(time);
    return LunarDateUtil.toLunarDateString(dateTime);
  }

  build() {
    Column() {
      Column() {
        Row() {
          Column() {
            if (this.isAllDay) {
              Text($r('app.string.all_day'))
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
            } else {
              Text(this.getTimeStr(this.begin)).fontSize(12).fontWeight(FontWeight.Medium)
              Text(this.getTimeStr(this.end)).fontSize(12).opacity(0.6).fontWeight(FontWeight.Regular)
            }
          }
          .width(this.is24HourClock ? 32 : 56)
          .alignSelf(ItemAlign.Center)
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 12, bottom: 12 })
          .margin({ right: 8 })

          Column() {
            Row() {
              Column()
                .width(3)
                .height(16)
                .backgroundColor(this.color)
                .borderRadius(1.5)
                .alignSelf(ItemAlign.Start)
                .margin({ top: 2, right: 8 })
              Text(this.title)
                .fontSize(16)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .lineHeight(20)
            }

            if (this.location) {
              Text(this.location)
                .fontSize(14)
                .opacity(0.6)
                .fontWeight(FontWeight.Regular)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 11 })
                .width('100%')
                .lineHeight(16)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .flexGrow(0)
          .padding({ top: 12, bottom: 12 })

          Stack() {
            Checkbox({ name: "ck", group: 'ckgroup' })
              .select(this.checked)
              .selectedColor(this.themeColor)
              .width(20)
              .height(20)
              .onChange((val) => {
                Log.info(TAG, `change value is ${val}`);
                this.onCheckChanged(this.eventId, val);
              })
              .hitTestBehavior(HitTestMode.Block)
          }
          .width(36)
        }
        .padding({ left: 8, right: 8 })
        .borderRadius(16)
        .width('100%')
        .stateStyles({
          pressed: {
            .backgroundColor($r('sys.color.interactive_click'))
          }
        , normal: {
            .backgroundColor($r('app.color.default_background'))
          }
        })

        if ((this.cornerType == CornerType.CORNER_UP) || (this.cornerType == CornerType.CORNER_NONE)) {
          Divider()
            .vertical(false)
            .height(1)
            .strokeWidth('1px')
            .color($r('sys.color.comp_divider'))
            .opacity(0.6)
            .padding({ left: 8, right: 8 })
        }
      }
      .width('100%')
      .padding({
        left: 4,
        right: 4,
        top: this.getHotspotPaddingTop(),
        bottom: this.getHotspotPaddingBottom()
      })
      .borderRadius({
        topLeft: this.radiusMap[this.cornerType][0],
        topRight: this.radiusMap[this.cornerType][1],
        bottomLeft: this.radiusMap[this.cornerType][2],
        bottomRight: this.radiusMap[this.cornerType][3],
      })
      .backgroundColor('#ffffff')
    }
    .width('100%')
    .onClick(() => {
      this.checked = !this.checked;
      this.onCheckChanged(this.eventId, this.checked);
      ReportUtil.reportStatisticEvent(statisticEvents.agendaPressClickItem);
    }).id('delete_item' + this.eventId)
  }

  getHotspotPaddingTop(): number {
    if ((this.cornerType === CornerType.CORNER_NONE) || (this.cornerType === CornerType.CORNER_DOWN)) {
      return 0;
    }
    return 4;
  }

  getHotspotPaddingBottom(): number {
    if ((this.cornerType === CornerType.CORNER_NONE) || (this.cornerType === CornerType.CORNER_UP)) {
      return 0;
    }
    return 4;
  }

  getHeight(): number {
    let extraHeight = (this.cornerType !== CornerType.CORNER_NONE) ? 4 : 0
    return (this.isLowerHeight() ? 48 : 64) + extraHeight;
  }

  isLowerHeight(): boolean {
    return (this.isAllDay) && (!this.location);
  }

  getTimeStr(time: number): string {
    this.is24HourClock = this.is24HourClock;
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !i18n.System.is24HourClock()
    });
  }
}

@Component
export struct HeaderItem {
  begin: number = 0;

  // 其它历法
  @StorageProp('subscriptionCalendar') subscriptionCalendar: number = -1;

  // 系统时间当天的时间戳
  @StorageProp(GlobalDataKeys.CURRENT_DATE) @Watch('onCurrentDateChange') currentDate: number = 0;

  // 系统时间当天的儒略日
  @State currentJulianDay: number = DateUtil.getJulianDay();

  @State isCurrentDay: boolean = false;

  build() {
    Row() {
      Text(this.getDateTime(this.begin))
        .padding({ top: 20, bottom: 10 })
        .fontSize(14)
        .fontColor(this.isCurrentDay ? '#0A59F7' : "#99000000");

      if (isChineseCalendar(this.subscriptionCalendar)) {
        Text(this.getLunarTime(this.begin))
          .padding({ top: 20, bottom: 10 })
          .margin({ left: 5, right: 5 })
          .fontColor('#99000000')
          .fontSize(14)
      }
    }.width('100%')
    .height(48)
    .margin({ top: 4 })
    .padding({ left: 12, right: 12 })
  }

  getDateTime(time: number) {
    const dateTime = new CalendarDate(time);
    this.isCurrentDay = this.currentJulianDay === DateUtil.getJulianDay(time);
    if (dateTime.getFullYear() !== new CalendarDate().getFullYear()) {
      return DateUtil.intlDateFormatChineseStyle(dateTime, {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        weekday: 'long'
      })
    }
    return DateUtil.intlDateFormatChineseStyle(dateTime, { month: 'long', day: 'numeric', weekday: 'long' })
  }

  getLunarTime(time: number) {
    const dateTime = new CalendarDate(time);
    return LunarDateUtil.toLunarDateString(dateTime);
  }

  onCurrentDateChange() {
    const now = new CalendarDate(this.currentDate);
    this.currentJulianDay = DateUtil.date2julianDay(now.getFullYear(), now.getMonth() + 1, now.getDate());
  }
}