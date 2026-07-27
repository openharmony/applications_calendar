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
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardSingleDayViewModel } from '../../viewModel/components/CardSingleDayViewModel';
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { ViewModelUtils } from '../../util/ViewModelUtils';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { WIDTH_ONE_IN_FIVE, WIDTH_ONE_IN_SEVEN, WIDTH_ONE_IN_SIXTH, WIDTH_QUARTER } from '../../../common/CardConsts';

const TAG: string = '[MonthCard][SigDay]';

@Component
export struct SingleDayView {
  @Prop viewModel: CardSingleDayViewModel;

  @Prop displayDate: CalendarDate;

  @Prop deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @Prop formId: string;
  @Consume('MonthCardView4x4') agendaNumsMap: Map<number, number>;
  @Consume('MonthCardHolidayView4x4') agendaHolidayNameMap: Map<number, string>;
  @Consume('MonthCardAbbreviationHoliday4x4') festivalAbbreviationRecord: Record<string, string>;

  // 单天视图绑定的布局参数
  private layout: DayLayout = new DayLayout();

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  // 节点索引
  @Prop index: number;

  // 单月行数
  @Prop rowNum: number;

  hasAgenda(julianDay: number): boolean {
    if (EmptyUtils.isUndefinedOrNull(this.agendaNumsMap)) {
      return false;
    }

    const count = this.agendaNumsMap.get(julianDay);

    if (EmptyUtils.isUndefinedOrNull(count)) {
      return false;
    }

    return count > 0;
  }

  getHolidayName(julianDay: number): string {
    if (EmptyUtils.isUndefinedOrNull(this.agendaHolidayNameMap)) {
      return this.viewModel.tagText ?? ' ';
    }
    const holidayName = this.agendaHolidayNameMap.get(julianDay);
    if (EmptyUtils.isUndefinedOrNull(holidayName)) {
      return this.viewModel.tagText ?? ' ';
    }
    if (this.festivalAbbreviationRecord === undefined) {
      return this.viewModel.tagText ?? ' ';
    }
    if (this.festivalAbbreviationRecord[holidayName] !== undefined) {
      return this.festivalAbbreviationRecord[holidayName];
    } else {
      return holidayName;
    }
  }

  getLunarLineBottom(isSmallUp: boolean) {
    return -this.layout.calOrHolFontFirstLunarDayLineHeight + (isSmallUp ? 1 : 0);
  }

  needCircle(viewModel: CardSingleDayViewModel) {
    return viewModel.isCurrentMonth && viewModel.isToday;
  }

  @Builder
  buildCircle() {
    // 当月今天需高亮反白；非当月不做处理
    if (this.needCircle(this.viewModel)) {
      Column()
        .height('100%')
        .width('100%')
        .aspectRatio(1)
        .backgroundColor($r('app.color.red_common'))
        .alignSelf(ItemAlign.Center)
        .borderRadius('100%')
    }
  }

  @Builder
  buildDayText() {
    // 公历日期
    Text(this.viewModel.day.toString())
      .textAlign(TextAlign.Center)
      .fontSize(this.deviceLayout.monthCard4x4FontSize - (this.isSmallUp ? 2 : 0))
      .maxFontScale(1)
      .lineHeight(this.deviceLayout.monthCard4x4FontSize - (this.isSmallUp ? 2 : 0))
      .fontWeight(this.layout.solarFontWeight)
      .fontColor(ViewModelUtils.updateDateTextColor(this.viewModel))
      .opacity(ViewModelUtils.updateDateTextOpacity(this.viewModel))
  }

  // 历法或节假日
  @Builder
  buildHoliday() {
    // 没有节日和历法时空串保持占位
    Text(this.getHolidayName(this.viewModel.julianDay))
      .textAlign(TextAlign.Center)
      .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
      .width(this.layout.calOrHolFontWidth)
      .height(this.layout.calOrHolFontHeight)
      .fontSize(this.layout.calOrHolFontSize)
      .maxFontScale(1)
      .fontColor(ViewModelUtils.updateCalOrHolTextColor(this.viewModel,
        this.agendaHolidayNameMap.get(this.viewModel.julianDay)))
      .opacity(this.viewModel.isCurrentMonth ? 1 : $r('sys.float.alpha_tertiary'))
  }

  // 农历初一的下划线
  @Builder
  buildLunarLine() {
    if (this.viewModel.showLunarLine) {
      Column() {
        Column()
          .width(this.layout.calOrHolFontSize * this.viewModel.tagText.length)
          .height(this.layout.calOrHolFontFirstLunarDayLineHeight)
          .borderRadius(1.5)
          .opacity(this.viewModel.isCurrentMonth ? 1 : $r('sys.float.alpha_tertiary'))// rule: 1.当月 透明度1 非当月 透明度0.4
          .backgroundColor($r('app.color.red_common')) // rule: 初一下划线不区分是否今天和是否选中的规则
      }
      .width('100%')
      .position({
        right: 0.5,
        bottom: this.getLunarLineBottom(this.isSmallUp)
      })
    }
  }

  // 日程红点
  @Builder
  buildDot() {
    if (this.hasAgenda(this.viewModel.julianDay)) {
      Column() {
        Circle()
          .height(3)
          .width(3)
          .opacity(this.needCircle(this.viewModel) ? 1 : $r('sys.float.alpha_tertiary'))
          .fill(this.needCircle(this.viewModel) ? $r('sys.color.ohos_fa_text_contrary') : $r('app.color.red_common'))
      }
      .width('100%')
      .position({
        bottom: this.getLunarLineBottom(this.isSmallUp) - (this.needCircle(this.viewModel) ? 3 : 4)
      })
    }
  }

  @Builder
  buildRecessCircle() {
    if (this.viewModel.showRecessData) {
      Button() {
        Text(this.viewModel.mark === 0 ? '' : (this.viewModel.mark === 1 ? '休' : '班'))
          .fontColor(this.viewModel.mark === 1
            ? $r('app.color.blue_common') : $r('app.color.red_common'))
          .opacity(this.viewModel.isToday ? 1 : this.viewModel.isCurrentMonth ? 1 : 0.8)
          .fontSize(this.layout.recessFontSize)
          .maxFontScale(1)
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
      }
      .type(ButtonType.Circle)
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
      .constraintSize({ minHeight: this.layout.recessFontSize + 3, minWidth: this.layout.recessFontSize + 3 })
      .position({
        right: -1,
        top: -this.layout.recessFontSize * 2 + 8
      })
    }
  }

  /**
   * 跳转到月视图
   */
  jumpToMonthView(obj: FormUtils, year: number, month: number, day: number) {
    Log.info(TAG, `formId: ${this.formId} Jump to month view, year: ${year}, month: ${month + 1}, day: ${day}`);
    try {
      postCardAction(obj, {
        'action': 'router',
        'bundleName': 'com.ohos.calendar',
        'abilityName': 'MainAbility',
        'params': {
          'action': 'CLICK_MONTH_FORM_HEADER',
          'tabIndex': '1',
          'year': year,
          'month': month,
          'day': day,
          'faType': 'MonthCard4x4'
        }
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'jumpToMonthView', err);
    }
  }

  build() {
    Stack() {
      this.buildCircle();
      Column() {
        this.buildDayText();
        this.buildRecessCircle()
        this.buildHoliday();
        this.buildLunarLine();
        this.buildDot();
      }
      .width('100%')
    }
    .accessibilityLevel(this.viewModel.isCurrentMonth ? 'yes' : 'no')
    .accessibilityText(ViewModelUtils.getAccessibilityText(this.viewModel))
    .width(WIDTH_ONE_IN_SEVEN)
    .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
    .alignRules({
      top: {
        anchor: this.index / 7 === 0 ? 'monthViewBase' : `monthView${this.index - 7}`,
        align: this.index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
      },
      left: {
        anchor: this.index % 7 === 0 ? 'monthViewBase' : `monthView${this.index - 1}`,
        align: this.index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
      }
    })
    .id(`monthView${this.index}`)
    .onClick(() => {
      // 非当月也需要跳转到对应的日期
      this.jumpToMonthView(this, this.viewModel.year, this.viewModel.month - 1, this.viewModel.day);
    })
  }
}

export class DayLayout {
  // 选中圆形半径
  public circleSize: number = 48;
  // 日期
  public solarFontWeight: number = FontWeight.Bold;
  public solarFontWidth: number = 20;
  public solarFontHeight: number = 20;
  // 历法或节假日大小
  public calOrHolFontWidth: number = 40;
  public calOrHolFontHeight: number = 12;
  public calOrHolFontSize: number = 9;
  // 班休
  public recessFontSize: number = 7;
  // 历法或节假日的下划线
  public calOrHolFontFirstLunarDayLineHeight: number = 1;
}