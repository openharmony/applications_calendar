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
import { SettingsDataModel } from './SettingsDataModel';
import { CardSingleMonthViewModel } from './CardSingleMonthModel';
import { CompressedDayData } from '../viewModel/components/CardSingleDayViewModel'
import { SettingPreferencesKeys } from '@app/common/src/main/ets/default/util/preferences_util/SettingPreferencesKeys';
import { MonthlyInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { compressData } from '../../utils/CardUtils';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';
import { CHINESE_HOLIDAY_STATE, CHINESE_HOLIDAY_STATE_VALUE } from '@app/common/src/main/ets/date/HolidayUtil';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { PreferencesFiles } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesFiles';
import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { StatementStateKeys } from '@app/common/src/main/ets/default/util/preferences_util/StatementStateKeys';
import { DateUtil, IMonthInfo } from '@app/common/src/main/ets/util/DateUtil';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG: string = 'MonthCardModel';

/**
 * 月视图卡片三个月数据处理
 */
export class MonthCardModel {
  private readonly MAX_MONTH_COUNT: number = 3;
  private displayDate: CalendarDate = new CalendarDate();
  private setting: SettingsDataModel;
  // 0：上月数据，1：当前月数据，2：下月数据
  private singleMonthViewModelArray: CardSingleMonthViewModel[] = new Array(this.MAX_MONTH_COUNT);

  constructor(displayDate?: CalendarDate) {
    this.displayDate = displayDate ?? new CalendarDate();
    this.setting = new SettingsDataModel();
    this.init();
  }

  /**
   * 执行初始化操作
   */
  init() {
    this.buildSettingData();
    this.buildMonthVM();
  }

  /**
   * 初始化 singleMonthlyViewModels 数组
   */
  buildMonthVM() {
    this.singleMonthViewModelArray = new Array(this.MAX_MONTH_COUNT);
    const year = this.displayDate.getFullYear();
    const month = this.displayDate.getMonth();
    Log.info(TAG, `displayDate month ${month}`)
    this.singleMonthViewModelArray[0] = this.buildSigMonthVM(year, month, -1);
    this.singleMonthViewModelArray[1] = this.buildSigMonthVM(year, month);
    this.singleMonthViewModelArray[2] = this.buildSigMonthVM(year, month, 1);
  }

  /**
   * 构造单月数据
   * @param year 年
   * @param month 月：0-11
   * @param offset：月份偏移量
   * @returns
   */
  buildSigMonthVM(year: number, month: number, offset: number = 0) {
    let result: IMonthInfo = DateUtil.getOffsetMonthInfo(
      { year: year, month: month },
      offset
    );
    const monthlyInfo = new MonthlyInfo(result.year, result.month + 1, this.setting.startOfWeek);
    const cardSigMonthVM = new CardSingleMonthViewModel(this.setting, monthlyInfo);
    return cardSigMonthVM;
  }

  /**
   * 初始化系统设置
   */
  buildSettingData() {
    try {
      // 移除用户首选项的缓存后再获取
      PreferencesUtil.removePreferencesFromCacheSync(PreferencesFiles.STATEMENT_STATE);
      PreferencesUtil.removePreferencesFromCacheSync(PreferencesFiles.SETTINGS);
      this.setting.isAgreeStatement = PreferencesUtil.getBooleanValueSync(
        PreferencesFiles.STATEMENT_STATE, StatementStateKeys.KEY_IS_AGREE_STATEMENT, true);

      this.setting.subscriptionCalendar = PreferencesUtil.getNumberValueSync(
        PreferencesFiles.SETTINGS, SettingPreferencesKeys.SUBSCRIPTION_CALENDAR, 0);
      this.setting.isRecessToggleOn = PreferencesUtil.getBooleanValueSync(
        PreferencesFiles.SETTINGS, SettingPreferencesKeys.IS_RECESS_TOGGLE_ON, false);
      this.setting.weekends = PreferencesUtil.getNumberArrayValueSync(
        PreferencesFiles.SETTINGS, SettingPreferencesKeys.WEEKENDS, [0, 6]) as number[];
      if (this.setting?.weekends?.includes(-1)) {
        this.setting.weekends = [0, 6];
      }
      this.setting.startOfWeek = DateUtil.getStartOfWeek(
        PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS, SettingPreferencesKeys.START_OF_WEEK, -1));
      this.setting.showChineseFestival = PreferencesUtil.getBooleanValueSync(PreferencesFiles.HOLIDAY, 'CN', true);
      this.setting.showChineseHolidayState = PreferencesUtil.getStringValueSync(PreferencesFiles.SETTINGS,
        CHINESE_HOLIDAY_STATE, CHINESE_HOLIDAY_STATE_VALUE.CN_OPEN);
      this.setting.systemRegion = i18n.System.getSystemRegion();
      const isTimeZoneLocked = PreferencesUtil.getBooleanValueSync(PreferencesFiles.SETTINGS,
        SettingPreferencesKeys.IS_TIME_ZONE_LOCKED, false);
      if (isTimeZoneLocked) {
        this.setting.timeZone = PreferencesUtil.getStringValueSync(PreferencesFiles.SETTINGS,
          SettingPreferencesKeys.LOCKED_TIME_ZONE, '');
      } else {
        this.setting.timeZone = I18nUtil.getSystemTimeZone();
      }
      CalendarDate.timeZone = this.setting.timeZone;
    } catch (err) {
      Log.logErrorMsg(TAG, 'buildSettingData', err);
    }
  }

  /**
   * 获取当前月份业务所需数据模型
   * @returns
   */
  getCurMonthVM(): CompressedDayData[] {
    const curMonthData = this.singleMonthViewModelArray[1].cardDayViewModels;
    return curMonthData.map(dayData => compressData(dayData));
  }

  /**
   * 获取月视图卡片三个月业务所需数据模型
   * @returns
   */
  getAllMonthVM(): CompressedDayData[][] {
    return this.singleMonthViewModelArray.map(monthlyData => {
      return monthlyData.cardDayViewModels.map(dayData => compressData(dayData));
    });
  }

  /**
   * 根据请求月份获取下个月的月份数据
   * @param requestDate 请求月份
   * @returns
   */
  getSingleMonthVM(date: CalendarDate, directionState: number): CompressedDayData[] {
    const requestDate = this.getRequestDate(date, directionState);
    const monthlyInfo = new MonthlyInfo(requestDate.year, requestDate.month + 1, this.setting.startOfWeek);
    const cardSingleMonthVM = new CardSingleMonthViewModel(
      this.setting,
      monthlyInfo
    );
    return cardSingleMonthVM.cardDayViewModels.map(dayData => compressData(dayData));
  }

  /**
   * 更新点击切换月份后的下个月时间
   * @param date 当前展示时间
   * @param directionState 切换的下一个月方向
   * @returns
   */
  getRequestDate(date: CalendarDate, directionState: number): IMonthInfo {
    // 更新当前月
    let currentDate: IMonthInfo = DateUtil.getOffsetMonthInfo(
      { year: date.getFullYear(), month: date.getMonth() },
      directionState
    );

    // 请求下个月
    return DateUtil.getOffsetMonthInfo(
      { year: currentDate.year, month: currentDate.month },
      directionState
    );
  }

  /**
   * 获取系统设置信息
   * @returns
   */
  getSettingData(): SettingsDataModel {
    return this.setting;
  }
}

