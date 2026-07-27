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
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { CardSingleDayViewModel } from '../../../monthCard/viewModel/components/CardSingleDayViewModel';
import { CardUiUtils } from '../../../utils/CardUiUtils';
import { DeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { WIDTH_ONE_IN_FIVE, WIDTH_ONE_IN_SEVEN, WIDTH_ONE_IN_SIXTH, WIDTH_QUARTER } from '../../../common/CardConsts';

const TAG: string = '[AgendaCardView][NoAgendaCardView]'

/**
 *  无日程时卡片视图
 */
@Component
export struct NoAgendaCardView {
  @Prop today: number = FormUtils.getCurrentJulianDay();

  @Prop days: CardSingleDayViewModel[] = [];

  @Prop rowNum: number = 6;

  @Prop startOfWeek: number = -1;

  @Prop weekends: number[] = [];

  @Prop deviceLayout: DeviceLayout;

  @Prop isRTL: boolean;

  private weekTitles: Resource[] = [
    $r('app.string.Card_Sun'),
    $r('app.string.Card_Mon'),
    $r('app.string.Card_Tue'),
    $r('app.string.Card_Wed'),
    $r('app.string.Card_Thu'),
    $r('app.string.Card_Fri'),
    $r('app.string.Card_Sat')
  ]

  @Prop isShowText: Resource = $r('app.string.no_agenda_week');

  @Prop lunarDateStr: string;

  aboutToAppear() {
    let time: CalendarDate = FormUtils.julianDay2Date(this.today);
    Log.info(TAG, `show date = ${time}`);
  }

  build() {
    RelativeContainer() {
      this.buildTitle();

      this.buildMonthView();
    }
    .padding(12)
    .backgroundColor($r('app.color.color_card_bg_ext'))
    .width('100%')
  }

  @Builder
  buildTitle() {
    Text(FormUtils.getWeekMessage(FormUtils.julianDay2Date(this.today)))
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_primary'))
      .fontSize($r('sys.float.ohos_id_text_size_body3'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.Start)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      })
      .id('week')

    Text(this.isShowText)
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize($r('sys.float.Body_S'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.End)
      .alignRules({
        top: { anchor: '__container__', align: VerticalAlign.Top },
        left: { anchor: 'week', align: HorizontalAlign.End },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .id('info')

    Text(this.lunarDateStr)
      .fontColor($r('sys.color.font_primary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize($r('sys.float.Body_S'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .textAlign(TextAlign.End)
      .margin({ top: 4 })
      .alignRules({
        top: { anchor: 'info', align: VerticalAlign.Bottom },
        right: { anchor: '__container__', align: HorizontalAlign.End }
      })
      .id('day')

    Text(`${FormUtils.julianDay2Date(this.today).getDate()}`)
      .fontColor('#F76045')
      .fontSize(40)
      .maxFontScale(1)
      .lineHeight(40)
      .fontWeight(FontWeight.Bold)
      .margin({ left: this.isRTL ? undefined : -2, right: this.isRTL ? -2 : undefined, top: 4 })
      .textAlign(TextAlign.Start)
      .padding({ bottom: 24 })
      .alignRules({
        top: { anchor: 'info', align: VerticalAlign.Bottom },
        left: { anchor: '__container__', align: HorizontalAlign.Start },
      })
      .id('date')
  }

  @Builder
  buildMonthView() {
    ForEach(this.weekTitles, (item: Resource, index: number) => {
      Text(this.weekTitles[(this.startOfWeek + index) % 7])
        .fontSize(12)
        .maxFontScale(1)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .opacity(this.weekends?.includes((this.startOfWeek + index) % 7)
          ? $r('sys.float.alpha_tertiary')
          : $r('sys.float.alpha_primary'))
        .fontWeight(FontWeight.Medium)
        .width(WIDTH_ONE_IN_SEVEN)// 各占屏幕的1/7
        .alignRules({
          top: { anchor: 'date', align: VerticalAlign.Bottom },
          left: {
            anchor: index === 0 ? '__container__' : `weekTitle${index - 1}`,
            align: index === 0 ? HorizontalAlign.Start : HorizontalAlign.End
          }
        })
        .id(`weekTitle${index}`)
    })

    RelativeContainer() {
      ForEach(new Array(this.rowNum).fill(''), (item: string, index: number) => {
        this.buildWeekDay(index);
      })
    }
    .alignRules({
      top: { anchor: 'weekTitle0', align: VerticalAlign.Bottom },
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom },
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      right: { anchor: '__container__', align: HorizontalAlign.End }
    })
    .id('monthViewBase')
    .width('100%')
  }

  @Builder
  buildWeekDay(index: number) {
    ForEach(new Array(7).fill(''), (item: string, num: number) => {
      if (this.days[index * 7 + num]) {
        this.buildSigDay(index * 7 + num)
      }
    })
  }

  @Builder
  buildCircle() {
    Column()
      .width(28)
      .height(28)
      .backgroundColor($r('app.color.red_common'))
      .alignSelf(ItemAlign.Center)
      .borderRadius(14)
  }

  @Builder
  buildSigDay(index: number) {
    if (this.days[index].isToday) {
      Stack() {
        this.buildCircle()
        Text(this.days[index].day.toString())
          .fontSize(this.deviceLayout.noCardAgendaFontSize4x4)
          .maxFontScale(1)
          .textAlign(TextAlign.Center)
          .visibility(this.days[index].isCurrentMonth ? Visibility.Visible : Visibility.Hidden)
          .fontColor(this.days[index].isToday ? '#FFFFFF' : $r('sys.color.font_primary'))
          .fontWeight(FontWeight.Bold)
          .width(WIDTH_ONE_IN_SEVEN)
          .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
      }
      .alignRules({
        top: {
          anchor: index / 7 === 0 ? 'monthViewBase' : `monthView${index - 7}`,
          align: index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
        },
        left: {
          anchor: index % 7 === 0 ? 'monthViewBase' : `monthView${index - 1}`,
          align: index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
        }
      })
      .id(`monthView${index}`)
    } else {
      Text(this.days[index].day.toString())
        .fontSize(this.deviceLayout.noCardAgendaFontSize4x4)
        .maxFontScale(1)
        .textAlign(TextAlign.Center)
        .visibility(this.days[index].isCurrentMonth ? Visibility.Visible : Visibility.Hidden)
        .fontColor(this.days[index].isToday ? '#FFFFFF' : $r('sys.color.font_primary'))
        .opacity((this.days[index].isWeekends && !this.days[index].isToday) ? 0.4 : 0.9)
        .fontWeight(FontWeight.Bold)
        .width(WIDTH_ONE_IN_SEVEN)
        .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
        .alignRules({
          top: {
            anchor: index / 7 === 0 ? 'monthViewBase' : `monthView${index - 7}`,
            align: index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
          },
          left: {
            anchor: index % 7 === 0 ? 'monthViewBase' : `monthView${index - 1}`,
            align: index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
          }
        })
        .id(`monthView${index}`)
    }
  }
}
