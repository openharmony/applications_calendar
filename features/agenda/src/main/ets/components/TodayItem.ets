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

import { CalendarDate, DateUtil, isChineseCalendar, LunarDateUtil } from '@app/common';

/**
 * 日程列表无今日日程时显示
 *
 * @since 2023-04-04
 */

@Component
export struct TodayItem {
  // 其它历法
  @StorageProp('subscriptionCalendar') subscriptionCalendar: number = -1;

  /**
   * 获取格式化日期字符串
   * @param isLunar
   *
   * @return 格式化日期字符串
   */
  getFormatDate(isLunar: boolean): string {
    const date: CalendarDate = new CalendarDate();
    return isLunar ? LunarDateUtil.toLunarDateString(date)
      : DateUtil.intlDateFormatChineseStyle(date, { month: 'long', day: 'numeric', weekday: 'long' });
  }

  build() {
    Column() {
      Row() {
        Text(this.getFormatDate(false))
          .padding({ top: 20, bottom: 10 })
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#0A59F7')

        if (isChineseCalendar(this.subscriptionCalendar)) {
          Text(this.getFormatDate(true))
            .padding({ top: 20, bottom: 10 })
            .fontWeight(FontWeight.Medium)
            .margin({ left: 5, right: 5 })
            .fontColor('#0A59F7')
            .fontSize(14)
        }
      }
      .width('100%')
      .height(48)
      .margin({ top: 4 })
      .padding({ left: 12, right: 12 })

      Row() {
        Text($r('app.string.no_schedule_today_tip'))
          .fontSize(12)
          .opacity(0.6)
          .fontWeight(FontWeight.Regular)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .height('100%')
          .borderRadius(16)
          .padding({ left: 8, right: 8 })
          .stateStyles({
            pressed: {
              .backgroundColor($r('sys.color.interactive_click'))
            },
            normal: {
              .backgroundColor($r('app.color.default_background'))
            }
          })
      }
      .width('100%')
      .height(56)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .padding({
        left: 4,
        right: 4,
        top: 4,
        bottom: 4
      })
      .borderRadius(16)
      .backgroundColor('#ffffff')
      .onClick(this.onClickItem)
    }
    .padding({ left: 12, right: 12 })
    .width('100%')
  }

  private onClickItem: () => void = () => {
  };
}
