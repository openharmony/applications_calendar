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
import { CardSingleDayViewModel } from '../../viewModel/components/CardSingleDayViewModel';
import { Log } from '@app/common/src/main/ets/default/common/Log';

import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { InitCardView2x4_4x4 } from '../../../view/InitCardView';
import { WeekTitle } from '../components/WeekTitles';
import { FormName } from '../../../utils/FormName';
import { MonthCardVM4x4 } from '../../viewModel/pages/MonthCardVM4x4';
import MonthCardLayoutFactory, { MonthCardLayout } from '../../layout/MonthCardLayout';
import { CarouselPanel } from '../components/CarouselPanel';
import { SwiperMonthView } from '../components/monthView/ComplexMonthView';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { DayAgendaNumInfo } from '../../../agendaCard/common/DayAgendaNumInfo';
import { CardAction } from '../../../common/CardAction';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { crossDayExceptionCheckAndRetry } from '../../../utils/CardUtils';
import { DayAgendaHolidayInfo } from '../../common/DayAgendaHolidayInfo';

const TAG: string = 'MonthCardView4x4';


@Component
export struct MonthCardView4x4 {
  // 一周开始日
  @LocalStorageProp('startOfWeek') @Watch('onStartOfWeekChange') startOfWeek: number = -1;

  // 周末
  @LocalStorageProp('weekends') @Watch('onWeekendsChange') weekends: number[] = [];

  // 卡片ID
  @LocalStorageProp('formId') @Watch('onFormIdChange') formId: string = '';

  // 卡片数据代理返回的 JSON 数组 - 1个月数据-按天分组
  @LocalStorageProp('dayAgendaNumInfo') @Watch('onDayAgendaNumInfoChange') dayAgendaNumInfo: DayAgendaNumInfo[] = [];

  @LocalStorageProp('displayDate') displayDate: number = 0;

  // 一月数据，julianday和数量映射
  @Provide('MonthCardView4x4') agendaNumsMap: Map<number, number> = new Map<number, number>();

  // 一月数据，julianday与月视图节假日名称映射
  @Provide('MonthCardHolidayView4x4') agendaHolidayNameMap: Map<number, string> = new Map<number, string>();

  // 一月数据，节假日名称与节假日缩略名称映射
  @Provide('MonthCardAbbreviationHoliday4x4') festivalAbbreviationRecord: Record<string, string> = {};

  // 卡片上全量数据，仅初始化时被使用
  @LocalStorageProp('cardSingleMonthVMJSONStr') @Watch('onMonthVMChange') cardSingleMonthVMJSONStr: string = '';

  // 上个月数据
  @LocalStorageProp('preMonthVMJSONStr') @Watch('onPreVMChange') preMonthVMJSONStr: string = '';

  // 下个月数据
  @LocalStorageProp('nextMonthVMJSONStr') @Watch('onNextVMChange') nextMonthVMJSONStr: string = '';

  // 设备规格
  @LocalStorageProp('deviceLayout') @Watch('onDeviceLayoutChange') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  @LocalStorageProp('timeZone') @Watch('onTimeZoneChange') timeZone: string = I18nUtil.getSystemTimeZone();
  
  // 是否进入日历隐私授权
  @LocalStorageProp('isAgreeStatement') @Watch('isAgreeStatementChange') isAgreeStatement: boolean = false;

  @State cardSingleMonthVMArr: Array<CardSingleDayViewModel[]> = new Array(3);

  @State monthCardVM: MonthCardVM4x4 = new MonthCardVM4x4(FormName.MONTH_CARD_4X4);

  private monthCardLayout: MonthCardLayout = MonthCardLayoutFactory.createLayout(FormName.MONTH_CARD_4X4);

  @LocalStorageProp('currentJulianDay') @Watch('onJulianDayOfNowChange') julianDayOfNow: number = 0;

  @LocalStorageProp('holidayInfo') @Watch('onHolidayInfoChange') holidayInfo: DayAgendaHolidayInfo[] = [];

  @LocalStorageProp('festivalAbbreviation') @Watch('onFestivalAbbreviationChange') festivalAbbreviation: string = '';

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

  onDayAgendaNumInfoChange() {
    if (!this.isAgreeStatement) {
      Log.warn(TAG, `onDayAgendaNumInfoChange, isAgreeStatement is false`);
      return;
    }

    if (EmptyUtils.isUndefinedOrNull(this.dayAgendaNumInfo)) {
      Log.warn(TAG, `this.dayAgendaNumInfo is null`);
      return;
    }

    const tempMap = new Map<number, number>();
    this.dayAgendaNumInfo.forEach((item: DayAgendaNumInfo) => {
      let julianDay = new CalendarDate(item.startTimeOfDay).getJulianDay();
      tempMap.set(julianDay, item.agendaNum);
    });
    this.agendaNumsMap = tempMap;

    Log.info(TAG, `formId: ${this.formId}, agendaNumsMap.size: ${this.agendaNumsMap.size}`);
  }

  // 调整时间
  onJulianDayOfNowChange() {
    Log.info(TAG, `onJulianDayOfNowChange, formId: ${this.formId}, julianDayOfNow: ${this.julianDayOfNow}`);
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_AGENDA_DOT
      }
    });
  }

  /**
   * 授权后会回到当月
   */
  isAgreeStatementChange() {
    Log.info(TAG, `isAgreeStatementChange, formId: ${this.formId}, isAgreeStatement = ${this.isAgreeStatement}`);
    if (!this.isAgreeStatement) {
      return;
    }

    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_AGENDA_DOT
      }
    });
  }

  // 全量更新
  onMonthVMChange() {
    this.monthCardVM.onMonthVMChange(this.cardSingleMonthVMJSONStr);
  }

  // 更新上个月
  onPreVMChange() {
    this.monthCardVM.onPreVMChange(this.preMonthVMJSONStr);
  }

  // 更新下个月
  onNextVMChange() {
    this.monthCardVM.onNextVMChange(this.nextMonthVMJSONStr);
  }

  // 设备布局
  onDeviceLayoutChange() {
    this.monthCardVM.onDeviceLayoutChange(this.deviceLayout);
  }

  private onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange: ${this.timeZone}`);
    CalendarDate.timeZone = this.timeZone;
    if (this.cardSingleMonthVMJSONStr !== '') {
      this.monthCardVM.onMonthVMChange(this.cardSingleMonthVMJSONStr);
    }

    // 调整时区
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_AGENDA_DOT
      }
    });
  }

  aboutToAppear(): void {
    Log.warn(TAG, `formId: ${this.formId} aboutToAppear start`);
    if (this.cardSingleMonthVMJSONStr !== '') {
      this.monthCardVM.onMonthVMChange(this.cardSingleMonthVMJSONStr);
    }
    this.onStartOfWeekChange();
    this.onFestivalAbbreviationChange();
    crossDayExceptionCheckAndRetry(this, this.julianDayOfNow);
    this.exceptionCheckAndRetry();
    Log.log(TAG, `formId: ${this.formId} aboutToAppear end`);
  }

  aboutToDisappear(): void {
    Log.info(TAG, `formId: ${this.formId} aboutToDisappear`);
  }

  build() {
    Column() {
      if (this.monthCardVM.isDataProcessedFirstTime) {
        CarouselPanel({
          viewModel: this.monthCardVM.monthSwitchVM,
        })

        WeekTitle({
          viewModel: this.monthCardVM.weekTitleVM,
          layoutModel: this.monthCardLayout.weekTitleLayout
        });
        SwiperMonthView({
          viewModel: this.monthCardVM.monthViewModel,
          layoutModel: this.monthCardLayout.monthViewLayout
        })

      } else {
        InitCardView2x4_4x4({ cardType: 'monthCard' });
      }
    }
    .accessibilityText(this.monthCardVM.getAccessibilityText())
    .backgroundColor($r('app.color.color_card_bg_ext'))
    .padding({ top: 12 })
    .onClick(() => {
      this.monthCardVM.jumpToMonthView(this);
    })
    .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
      const width = newValue.width;
      const height = newValue.height;
      const oldWidth = oldValue.width;
      const oldHeight = oldValue.height;
      Log.info(TAG, `onSizeChange oldWidth: ${oldWidth}, oldHeight: ${oldHeight}, newWidth: ${width}, newHeight: ${height}`);
    })
  }

  /**
   * 卡片非当月静置3分钟再返回，会回到当月当天
   * 重启则重走onAddForm重新走代理，无需额外刷新
   */
  exceptionCheckAndRetry() {
    // 非当月静置3分钟,需刷新
    const displayDateYear = new CalendarDate(this.displayDate).getFullYear();
    const displayDateMonth = new CalendarDate(this.displayDate).getMonth();
    const nowYear = new CalendarDate().getFullYear();
    const nowMonth = new CalendarDate().getMonth();
    const isEqualNowMonth = displayDateYear === nowYear && displayDateMonth === nowMonth;

    // 左右切换月份后，显示时间的月份处于当前月份
    if (isEqualNowMonth) {
      Log.warn(TAG, `exceptionCheckAndRetry, displayDateMonth is nowMonth`);
      return;
    }

    Log.warn(TAG, `exceptionCheckAndRetry. displayDateMonth= ${displayDateMonth}, nowMonth= ${nowMonth}`);
    postCardAction(this, {
      action: 'message',
      params: {
        message: CardAction.REFRESH_AGENDA_DOT
      }
    });
  }

  onHolidayInfoChange() {
    Log.info(TAG, `onHolidayInfoChange, formId: ${this.formId}`);
    if (!this.isAgreeStatement) {
      Log.warn(TAG, `onHolidayInfoChange, isAgreeStatement is false`);
      return;
    }
    if (EmptyUtils.isUndefinedOrNull(this.holidayInfo)) {
      Log.warn(TAG, `this.holidayInfo is null`);
      return;
    }
    const tempMap = new Map<number, string>();
    this.holidayInfo.forEach((item: DayAgendaHolidayInfo) => {
      if (!tempMap.has(item.startDay)) {
        tempMap.set(item.startDay, item.title);
      }
    });
    this.agendaHolidayNameMap = tempMap;
  }

  onFestivalAbbreviationChange() {
    Log.info(TAG, `onFestivalAbbreviationChange, formId: ${this.formId}`);
    if (EmptyUtils.isEmptyString(this.festivalAbbreviation)) {
      Log.warn(TAG, 'onFestivalAbbreviationChange festivalAbbreviation is null')
      return;
    }
    try {
      this.festivalAbbreviationRecord = JSON.parse(this.festivalAbbreviation);
    } catch (err) {
      Log.logErrorMsg(TAG, 'onFestivalAbbreviationChange error', err);
    }
  }
}



