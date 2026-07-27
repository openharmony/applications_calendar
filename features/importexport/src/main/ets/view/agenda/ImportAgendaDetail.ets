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

import { AgendaEventInfo, BigFontSize, CalendarDate, DateUtil } from '@app/common/index';
import { LengthMetrics } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';

interface IRichText {
  isHighLight: boolean;
  text: string | Resource;
};

const TAG: string = 'ImportAgendaDetail';

const BTN_MARGIN_LEFT: number = 6;
const TIME_WIDTH_24_HOUR: number = 32;
const TIME_WIDTH_12_HOUR: number = 48;
const START_TIME_24_HOUR: string = '00:00';
const START_TIME_12_HOUR: string = '半夜00:00';
const END_TIME_24_HOUR: string = '24:00';
const END_TIME_12_HOUR: string = '半夜12:00';

/**
 * 单个日程组件
 */
@Component
export struct ImportAgendaDetail {
  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp('is24HourClock') is24HourClock: boolean = false;

  // @State 不支持直接使用 ResourceStr，使用数组规避
  @State timeTextStrList: Array<ResourceStr> = [];

  @State titleSpanStrList: Array<IRichText> = [];

  @State timeWidth: number = TIME_WIDTH_24_HOUR;

  @Prop accountColor: number;

  // 日程实例
  @Prop info: AgendaEventInfo;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  viewType: number = -1;

  aboutToAppear() {
    this.timeWidth = this.is24HourClock ? TIME_WIDTH_24_HOUR : TIME_WIDTH_12_HOUR;
    if (this.info) {
      this.transTitleMessage();
      this.transTimeMessage();
    }
  }

  /**
   * 日程时间组件：深色
   * @param timeMessage 显示的时间内容
   */
  @Builder
  TimeMessageBlack(timeMessage: ResourceStr) {
    Text(timeMessage)
      .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
      .minFontSize('4vp')
      .maxFontScale(1)
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Medium)
      .maxLines(1)
      .lineHeight(14)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignSelf(ItemAlign.Center)
  }

  /**
   * 日程时间组件：浅色
   * @param timeMessage 显示的时间内容
   */
  @Builder
  TimeMessageLight(timeMessage: ResourceStr) {
    Text(timeMessage)
      .opacity(0.4)
      .fontColor($r('sys.color.font_primary'))
      .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
      .minFontSize('4vp')
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .lineHeight(14)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignSelf(ItemAlign.Center)
  }

  /**
   * 日程时间组件：整天
   * @param timeMessage 显示的时间内容
   */
  @Builder
  TimeMessageAllDay(timeMessage: ResourceStr) {
    Text(timeMessage)
      .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
      .minFontSize('4vp')
      .maxFontScale(1)
      .fontColor($r('sys.color.font_primary'))
      .opacity(0.9)
      .fontWeight(FontWeight.Bold)
      .maxLines(1)
      .lineHeight(14)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .alignSelf(ItemAlign.Center)
      .margin({ top: 6 })
  }

  @Builder
  DividerUp() {
    Column()
      .width(1)
      .height(7)
      .backgroundColor($r('sys.color.comp_divider'))
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 1, bottom: 4 })
  }

  @Builder
  DividerDown() {
    Column()
      .width(1)
      .height(7)
      .backgroundColor($r('sys.color.comp_divider'))
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 4, bottom: 1 })
  }

  @Builder
  DividerAllDay() {
    Column()
      .width(1)
      .height(42)
      .backgroundColor($r('sys.color.comp_divider'))
      .opacity(0.1)
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 4, bottom: 4 })
  }

  @Builder
  AccountCircle() {
    Circle()
      .width(5)
      .height(5)
      .fillOpacity(0)
      .alignSelf(ItemAlign.Center)
      .stroke(this.accountColor)
      .strokeWidth(2)
  }

  /**
   * 日程标题组件
   */
  @Builder
  AgendaTitle() {
    Text() {
      ForEach(this.titleSpanStrList, (item: IRichText) => {
        Span(item.text)
          .fontColor(item.isHighLight ? this.themeColor : $r('sys.color.font_primary'))
          .fontSize(16)
      }, (item: IRichText, index: number | undefined): string => '' + this.info.mId + index)
    }
    .fontColor($r('sys.color.font_primary'))
    .maxLines(this.fontSizeScale < BigFontSize.BIG_FONT_SIZE_SCALE ? 2 : 3)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
    .layoutWeight(1)
    .direction(i18n.isRTL(i18n.getSystemLocale()) ? Direction.Rtl : Direction.Ltr)
  }

  /**
   * 日程地点组件
   */
  @Builder
  AgendaLocation() {
    Text(this.info.mLocation)
      .opacity(0.6)
      .fontSize(14)
      .fontWeight(FontWeight.Normal)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .textAlign(i18n.isRTL(i18n.getSystemLocale()) ? TextAlign.End : TextAlign.Start)
  }

  build() {
    Row() {
      Row() {
        if (this.info) {
          Column() {
            if (this.timeTextStrList.length === 1) {
              this.AccountCircle()
              this.TimeMessageAllDay(this.timeTextStrList[0]);
            } else {
              this.TimeMessageBlack(this.timeTextStrList[0]);
              // 线加圆圈
              Column() {
                this.DividerUp()
                this.AccountCircle()
                this.DividerDown()
              }.alignItems(HorizontalAlign.Center)

              this.TimeMessageLight(this.timeTextStrList[1]);
            }
          }
          .margin({ start:LengthMetrics.vp(12), top:LengthMetrics.vp(9), bottom: LengthMetrics.vp(9) })
          .height(58)
          .alignSelf(ItemAlign.Center)
          .justifyContent(FlexAlign.Center)
          .opacity(1)

          Column() {
            Column() {
              //  日程头
              Row() {
                this.AgendaTitle()
              }
              .opacity(1)

              // 地址
              Row() {
                if (this.info?.mLocation) {
                  this.AgendaLocation();
                }
              }
              .margin({ top: 5 })
              .visibility(this.info?.mLocation ? Visibility.Visible : Visibility.None)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .margin({ start:LengthMetrics.vp(12) })
          .layoutWeight(1)
        } else {
          Row() {
            Text($r('app.string.agenda_empty_text'))
              .opacity(0.6)
              .fontSize(16)
              .fontWeight(FontWeight.Normal)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .margin({ start: LengthMetrics.vp(8)})
          }
          .constraintSize({ minHeight: 56 })
          .width('100%')
        }
      }
      .padding(4)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .alignItems(VerticalAlign.Center)
      .borderRadius(20)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor($r('sys.color.comp_background_list_card'))
        }
      })
    }
  }

  /**
   * 获取显示的标题信息
   */
  private transTitleMessage() {
    this.titleSpanStrList = [];

    if (this.info?.mTitle.length === 0) {
      this.titleSpanStrList.push({ isHighLight: false, text: $r('app.string.no_title_label') });
      return;
    }

    this.titleSpanStrList.push({ isHighLight: false, text: this.info?.mTitle });
  }

  /**
   * 获取显示的时间信息
   */
  private transTimeMessage() {
    this.timeTextStrList = [];
    if (this.info?.mIsAllDay || (this.info?.mIsMultiDayEvent && this.info?.mFlag === AgendaEventInfo.FLAG_MID)) {
      this.timeTextStrList.push($r('app.string.all_day'));
      return;
    }
    if (this.info?.mIsMultiDayEvent && this.info?.mFlag === AgendaEventInfo.FLAG_START) {
      this.timeTextStrList.push(this.getTimeStr(this.info?.mBegin))
      this.timeTextStrList.push(this.is24HourClock ? END_TIME_24_HOUR : END_TIME_12_HOUR)
    } else if (this.info?.mIsMultiDayEvent && this.info?.mFlag === AgendaEventInfo.FLAG_END) {
      this.timeTextStrList.push(this.is24HourClock ? START_TIME_24_HOUR : START_TIME_12_HOUR)
      this.timeTextStrList.push(this.getTimeStr(this.info?.mEnd))
    } else {
      this.timeTextStrList.push(this.getTimeStr(this.info?.mBegin))
      this.timeTextStrList.push(this.getTimeStr(this.info?.mEnd))
    }
  }

  /**
   * 时间戳转化为 24 小时或 12 小时制时间 ——> 小时:分钟
   * @param time 时间戳
   * @returns 转化后的时间字符串
   */
  private getTimeStr(time: number): string {
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, {
      hour: 'numeric',
      minute: '2-digit',
      hour12: !this.is24HourClock
    });
  }
}

