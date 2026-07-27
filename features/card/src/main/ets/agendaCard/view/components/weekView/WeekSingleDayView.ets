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
import { CardSingleDayViewModel } from '../../../../monthCard/viewModel/components/CardSingleDayViewModel';
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { DateUtil } from '@app/common/src/main/ets/util/DateUtil';
import { SubscriptionCalendar } from '@app/common/src/main/ets/constants/SettingEnumConstants';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { CardAction } from '../../../../common/CardAction';
import { date2julianDay } from '../../../../utils/TimeUtils';

const TAG: string = '[AgendaCard4x6][SigDay]';

@Component
export struct WeekSingleDayView {
  @Prop viewModel: CardSingleDayViewModel;

  @Prop displayDate: CalendarDate;

  @Prop deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @Prop formId: string;

  @Prop isActiveDay: boolean = false;

  @Prop isAgreeStatement: boolean = true;

  // 当前选中日
  @Link activeDay: number

  // 单天视图绑定的布局参数
  private layout: DayLayout = new DayLayout();

  aboutToAppear(): void {
    Log.log(TAG, `WeekSingleDayView is created`);
  }

  @Builder
  buildCircle() {
    // 是选中日才画圆
    if (this.isActiveDay) {
      // 选中日是今天，画实心圆
      if (this.viewModel.isToday) {
        Column()
          .width(this.layout.circleSize)
          .height(this.layout.circleSize)
          .backgroundColor($r('app.color.red_common'))
          .alignSelf(ItemAlign.Center)
          .borderRadius(this.layout.circleSize / 2)
        // 选中日非今天，画空心圆
      } else {
        Column()
          .width(this.layout.circleSize)
          .height(this.layout.circleSize)
          .border({
            width: 1,
            radius: this.layout.circleSize / 2,
            color: $r('app.color.red_common')
          })
          .alignSelf(ItemAlign.Center)
          .borderRadius(this.layout.circleSize / 2)
      }
    }
  }

  @Builder
  buildDayText() {
    // 公历日期
    Text(this.viewModel.day.toString())
      .textAlign(TextAlign.Center)
      .fontSize(this.deviceLayout.noCardAgendaFontSize4x4)
      .maxFontScale(1)
      .lineHeight(this.deviceLayout.noCardAgendaFontSize4x4)
      .fontWeight(this.layout.solarFontWeight)
      .fontColor(this.updateDateTextColor())
      .opacity(this.updateDateTextOpacity())
  }

  // 历法或节假日
  @Builder
  buildHoliday() {
    // 没有节日和历法时空串保持占位
    Text(this.viewModel.tagText ?? ' ')
      .textAlign(TextAlign.Center)
      .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
      .width(this.layout.calOrHolFontWidth)
      .height(this.layout.calOrHolFontHeight)
      .fontSize(this.layout.calOrHolFontSize)
      .maxFontScale(1)
      .fontColor(this.updateCalOrHolTextColor())
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
        bottom: -this.layout.calOrHolFontFirstLunarDayLineHeight
      })
    }
  }

  // 班休
  @Builder
  buildRecessCircle() {
    if (this.isAgreeStatement && this.viewModel.showRecessData) {
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
      .backgroundColor($r('app.color.color_card_bg'))
      .constraintSize({ minHeight: this.layout.recessFontSize + 4, minWidth: this.layout.recessFontSize + 4 })
      .position({
        right: 5,
        top: -this.layout.recessFontSize * 2 + 3
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

  /**
   * 更新日期字体透明度
   * @returns
   */
  updateDateTextOpacity() {
    if (this.viewModel.isToday) {
      return 1; // 今天
    }
    if (!this.viewModel.isCurrentMonth) {
      return 0.5; // 非当月
    }
    if (this.viewModel.showRecessData) {
      return 1; // 显示班休时使用强调色
    }
    if (this.viewModel.isWeekends) {
      return $r('sys.float.alpha_tertiary'); // 周末
    }
    return 1; // 其它场景
  }

  /**
   * 更新日期字体颜色
   * @returns
   */
  updateDateTextColor() {
    // 今天选中，字体颜色反转白色
    if (this.viewModel.isToday && this.isActiveDay) {
      return $r('sys.color.ohos_fa_text_contrary');
    }
    // 今天非选中，字体颜色红色
    if (this.viewModel.isToday) {
      return $r('app.color.red_common');
    }
    // 显示班休 1：休 蓝色  2：班 红色
    if (this.viewModel.showRecessData) {
      if (this.viewModel.mark === 1) {
        return $r('app.color.blue_common')
      } else if (this.viewModel.mark === 2) {
        return $r('app.color.red_common')
      }
    }
    // 非当月
    if (!this.viewModel.isCurrentMonth) {
      return $r('sys.color.font_tertiary');
    }
    // 当月, 非今天，非班休 默认黑色
    return $r('sys.color.font_primary');
  }

  /**
   * 更新节假日、历法字体颜色
   * @returns
   */
  updateCalOrHolTextColor() {
    // 1.今天选中 反转白色
    if (this.viewModel.isToday && this.isActiveDay) {
      return $r('sys.color.ohos_fa_text_contrary');
    }
    // 2.今天未选中 或为 节假日 红色
    if (this.viewModel.isToday || this.viewModel.hasFestivals) {
      return $r('app.color.red_common');
    }
    // 3.非节假日，非今天，默认灰色 与应用内保持一致
    return $r('sys.color.font_tertiary');
  }

  getAccessibilityText(): string {
    // todo 待提翻
    let dateOption: Record<string, string> = {
      'year': 'numeric',
      'month': 'long',
      'day': 'numeric',
      'weekday': 'long',
    };

    let date = new CalendarDate()
    date.setFullYear(this.viewModel.year);
    date.setMonth(this.viewModel.month - 1);
    date.setDate(this.viewModel.day);
    let now = DateUtil.intlDateFormatChineseStyle(date, dateOption, true);
    let toDay = this.viewModel.isToday ? '今天' : '';
    let subscriptionCalendar = '';
    if (this.viewModel.subscriptionCalendar == SubscriptionCalendar.CHINESE_CALENDAR &&
      !this.viewModel.hasFestivals) {
      subscriptionCalendar = '农历';
    }
    return toDay + ',' + now + ',' + subscriptionCalendar + this.viewModel.tagText;
  }

  @Builder
  buildAgendaDot() {
    if (this.isAgreeStatement && this.viewModel.showAgendaDot) {
      Column() {
        Circle()
          .width(this.deviceLayout.agendaDot)
          .height(this.deviceLayout.agendaDot)
          .fill(this.viewModel.isToday && this.isActiveDay
            ? $r('sys.color.ohos_fa_text_contrary') : $r('app.color.red_common'))
          .opacity(this.viewModel.isToday && this.isActiveDay ? 1 : $r('sys.float.alpha_tertiary'))
      }
      .width('100%')
      .position({
        bottom: -6
      })
    }
  }

  build() {
    Stack() {
      this.buildCircle();
      Column() {
        this.buildDayText();
        this.buildRecessCircle();
        this.buildHoliday();
        this.buildLunarLine();
        this.buildAgendaDot();
      }
      .width('100%')
    }
    .accessibilityLevel(this.viewModel.isCurrentMonth ? 'yes' : 'no')
    .accessibilityText(this.getAccessibilityText())
    .width('14%')
    .height('10.67%')
    .onClick(() => {
      if (!this.isAgreeStatement) {
        Log.warn(TAG, 'click has not yet authorized');
        return;
      }
      const dayInfo = this.viewModel;
      this.activeDay = date2julianDay(dayInfo.year, dayInfo.month, dayInfo.day);
      Log.info(TAG, 'click activeDay:' + this.activeDay);
      // 触发查询日程操作
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.SEARCH_AGENDA_4X6,
          julianDay: this.activeDay
        }
      });
    })
  }
}

export class DayLayout {
  // 选中圆形直径
  public circleSize: number = 44;
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