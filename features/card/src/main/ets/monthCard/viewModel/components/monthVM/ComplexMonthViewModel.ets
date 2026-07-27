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
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { decompressData } from '../../../../utils/CardUtils';
import { CompressedDayData } from '../CardSingleDayViewModel';
import { SwiperMonthDataArray } from '../../../common/MonthlyDataArray';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

const TAG: string = '[MonthCard][ComplexMonthViewModel]';
const LENGTH_OF_TIME: number = 13;
const LENGTH_OF_SWIPER: number = 3;

/**
 * 复杂月视图的VM
 */
@Observed
export class ComplexMonthViewModel {
  // formID
  public formId: string = '';
  // 滑动控制器
  public swiperController: SwiperController = new SwiperController();
  // 当前标签
  public curIndex: number = 1;
  // 目标标签
  public targetIndex: number = 1;
  // 刷新视图用标志位
  public swiperFlag: boolean = false;
  // 全量月视图显示内容
  public cardSingleMonthVMArr: SwiperMonthDataArray = new Array(LENGTH_OF_SWIPER);
  // 月视图上的设备维度布局
  public deviceLayout: DeviceLayout = new SmallDeviceLayout();
  // 当天日期
  public displayDate: CalendarDate = new CalendarDate();
  // 反向告知兄弟组件按钮禁用行为
  private onIsButtonBannedHandle: Function = (isButtonBanned: boolean) => {

  }

  constructor(onIsButtonBannedChange: (isButtonBanned: boolean) => void,) {
    this.onIsButtonBannedHandle = onIsButtonBannedChange;
  }

  /**
   * 月视图完成刷新后 按钮接触禁用
   * @param isButtonBanned
   */
  onIsButtonBannedChange(isButtonBanned: boolean) {
    this.onIsButtonBannedHandle(isButtonBanned);
  }

  onDisplayDateChange(displayDate: CalendarDate) {
    this.displayDate = displayDate;
  }

  /**
   * 全量更新
   * @param cardSingleMonthVMJSONStr 需要刷新的数据 三个月全量的数据
   * @returns 是否完成刷新逻辑
   */
  onMonthVMChange(cardSingleMonthVMJSONStr: string): boolean {
    if (EmptyUtils.isNotOrEmptyString(cardSingleMonthVMJSONStr)) {
      Log.error(TAG, `cardSingleMonthVMJSONStr is null!`);
      return false;
    }
    try {
      const monthsData: CompressedDayData[][] = JSON.parse(cardSingleMonthVMJSONStr);
      this.cardSingleMonthVMArr = monthsData.map(monthData => {
        return monthData.map(dayData => decompressData(dayData));
      });
      this.curIndex = 1;
    } catch (error) {
      Log.logErrorMsg(TAG, `JSON parse error`, error);
    }
    return true;
  }

  /**
   * 更新上个月
   * @param preMonthVMJSONStr 需要刷新的数据 单个月的数据
   * @returns 是否完成刷新逻辑
   */
  onPreVMChange(preMonthVMJSONStr: string): boolean {
    Log.info(TAG, `formId: ${this.formId} last month viewmodel change`);
    if (EmptyUtils.isNotOrEmptyString(preMonthVMJSONStr)) {
      Log.error(TAG, `preMonthVMJSONStr is null!`);
      return false;
    }
    try {
      const preIndex = this.curIndex + 1 > 2 ? 0 : this.curIndex + 1;
      const preMonthData: CompressedDayData[] = JSON.parse(preMonthVMJSONStr.substring(LENGTH_OF_TIME))
      this.cardSingleMonthVMArr[preIndex] = preMonthData.map(dayData => decompressData(dayData));
      this.swiperController.showPrevious();
    } catch (error) {
      Log.logErrorMsg(TAG, `JSON parse error`, error);
      return false;
    }
    return true;
  }

  /**
   * 更新下个月
   * @param nextMonthVMJSONStr 需要刷新的数据 单个月的数据
   * @returns 是否完成刷新逻辑
   */
  onNextVMChange(nextMonthVMJSONStr: string): boolean {
    Log.info(TAG, `formId: ${this.formId} next month viewmodel change`);
    if (EmptyUtils.isNotOrEmptyString(nextMonthVMJSONStr)) {
      Log.error(TAG, `nextMonthVMJSONStr is null!`);
      return false;
    }
    try {
      const nextIndex = this.curIndex - 1 < 0 ? 2 : this.curIndex - 1;
      const nexMonthData: CompressedDayData[] = JSON.parse(nextMonthVMJSONStr.substring(LENGTH_OF_TIME));
      this.cardSingleMonthVMArr[nextIndex] = nexMonthData.map(dayData => decompressData(dayData));
      this.swiperController.showNext();
    } catch (error) {
      Log.logErrorMsg(TAG, `JSON parse error`, error);
      return false;
    }
    return true;
  }

  onDeviceLayoutChange(deviceLayout: DeviceLayout) {
    this.deviceLayout = deviceLayout;
  }


  onAnimationStart(index: number, targetIndex: number) {
    Log.log(TAG, `formId: ${this.formId} onAnimationStart startIndex ${index}, endIndex ${targetIndex}, swiperFlag ${this.swiperFlag}`);
    // 添加标志位用于确定是否执行过AnimationStart
    if (this.swiperFlag) {
      return;
    }
    if (index === targetIndex) {
      return;
    }

    this.swiperFlag = !this.swiperFlag;
    this.targetIndex = targetIndex;
  }

  onSwiperChange(index: number) {
    Log.log(TAG, `formId: ${this.formId} onChange Index ${index}, swiperFlag ${this.swiperFlag}`);

    // 标志位判断是否执行过AnimationStart
    if (this.swiperFlag) {
      // 执行过AnimationStart,无需再次刷新
      this.swiperFlag = !this.swiperFlag;
      this.curIndex = index;
      this.onIsButtonBannedChange(false);
      return;
    }

    // 未执行过则需要刷新,更改标志位标志正在刷新
    this.swiperFlag = !this.swiperFlag;
    this.targetIndex = index;
    this.curIndex = index;
    this.onIsButtonBannedChange(false);
    this.swiperFlag = !this.swiperFlag;
  }
}