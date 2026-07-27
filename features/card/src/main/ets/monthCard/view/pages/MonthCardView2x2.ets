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
import { InitCardView2x2 } from '../../../view/InitCardView';
import MonthCardLayoutFactory, { MonthCardLayout } from '../../layout/MonthCardLayout';
import { TitleMessage } from '../components/TitleMessage';
import { WeekTitle } from '../components/WeekTitles';
import { SimpleMonthView } from '../components/monthView/SimpleMonthView';
import { FormName } from '../../../utils/FormName';
import { MonthCardVM2x2 } from '../../viewModel/pages/MonthCardVM2x2';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { crossDayExceptionCheckAndRetry } from '../../../utils/CardUtils';
import { isChineseCalendar } from '@app/common';
import { CardUiUtils } from '../../../utils/CardUiUtils';
import { FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardAction } from '../../../common/CardAction';

const TAG: string = 'MonthCardView2x2';

@Component
export struct MonthCardView2x2 {
  // 一周开始日
  @LocalStorageProp('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = -1;

  // 周末
  @LocalStorageProp('weekends') @Watch('onWeekendsChange') weekends: number[] = [];

  // 当前月数据
  @LocalStorageProp('curMonthVM') @Watch('onCurMonthVM') curMonthVM: string = '';

  // 卡片ID
  @LocalStorageProp('formId') @Watch('onFormIdChange') formId: string = '';

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();

  @State monthCardVM: MonthCardVM2x2 = new MonthCardVM2x2(FormName.MONTH_CARD_2X2);

  private monthCardLayout: MonthCardLayout = MonthCardLayoutFactory.createLayout(FormName.MONTH_CARD_2X2);

  @LocalStorageProp('currentJulianDay') julianDayOfNow: number = 0;

  /** 监听日历应用历法改变 用于判断农历日期的显隐性 */
  @LocalStorageProp('subscriptionCalendar') @Watch('onSubscriptionCalendarChange') subscriptionCalendar: number = 0;

  /** 卡片上的农历日期显示 */
  @State lunarDateStr: string = '';

  /** 用于跨天更新农历日期 */
  @LocalStorageProp('updateLunarInfoStr') @Watch('onLunarInfoStrChange') updateLunarInfoStr: string = '';

  onStartOfWeekChange() {
    Log.info(TAG, ` formId: ${this.formId} onStartOfWeekChange startOfWeek = ` + this.startOfWeek);
    this.monthCardVM.onStartOfWeekChange(this.startOfWeek);
  }

  onWeekendsChange() {
    Log.info(TAG, ` formId: ${this.formId} onWeekendsChange weekends = ` + JSON.stringify(this.weekends));
    this.monthCardVM.onWeekendsChange(this.weekends);
  }

  onFormIdChange() {
    this.monthCardVM.onFormIdChange(this.formId);
  }

  onCurMonthVM() {
    const result = this.monthCardVM.onCurMonthVM(this.curMonthVM);
    if (!result && this.curMonthVM !== '') {
      Log.warn(TAG, `formId: ${this.formId} onCurMonthVM failed, request refresh`);
      postCardAction(this, {
        action: 'message',
        params: {
          message: CardAction.REFRESH_MONTH_VIEW
        }
      });
    }
    this.onSubscriptionCalendarChange();
  }

  private onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange: ${this.timeZone}`);
    CalendarDate.timeZone = this.timeZone;
    this.onCurMonthVM();
  }

  aboutToAppear(): void {
    Log.warn(TAG, `formId: ${this.formId} aboutToAppear start`);
    this.monthCardVM.weekTitleVM.weekTitles.forEach((value, key) => {
      Log.warn(TAG, `aboutToAppear key: ${key}, resourceId: ${value.id}`);
    })
    if (this.curMonthVM !== '') {
      this.onCurMonthVM();
    }
    this.onStartOfWeekChange();
    this.onSubscriptionCalendarChange();
    crossDayExceptionCheckAndRetry(this, this.julianDayOfNow);
    Log.log(TAG, `formId: ${this.formId} aboutToAppear end`);
  }

  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`);
  }

  build() {
    Column() {
      if (this.monthCardVM.isDataProcessedFirstTime) {
        TitleMessage({
          viewModel: this.monthCardVM.monthViewModel,
          layoutModel: this.monthCardLayout.weekTitleLayout,
          lunarDateStr: this.lunarDateStr
        });

        // 日、一、二、三...
        WeekTitle({
          viewModel: this.monthCardVM.weekTitleVM,
          layoutModel: this.monthCardLayout.weekTitleLayout
        });
        // 天
        SimpleMonthView({
          viewModel: this.monthCardVM.monthViewModel,
          layoutModel: this.monthCardLayout.monthViewLayout
        });
      } else {
        InitCardView2x2();
      }
    }
    .accessibilityText(this.monthCardVM.getAccessibilityText())
    .onClick(() => {
      this.monthCardVM.jumpToMonthView(this);
    })
    .padding(12)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.color_card_bg_ext'))
  }

  onSubscriptionCalendarChange() {
    Log.info(TAG, `onSubscriptionCalendarChange subscriptionCalendar= ${this.subscriptionCalendar}`);
    if (isChineseCalendar(this.subscriptionCalendar)) {
      this.julianDayOfNow = FormUtils.getCurrentJulianDay();
      this.lunarDateStr = CardUiUtils.getLunarText(this.julianDayOfNow);
    } else {
      this.lunarDateStr = '';
    }
  }

  onLunarInfoStrChange() {
    this.onSubscriptionCalendarChange();
  }
}