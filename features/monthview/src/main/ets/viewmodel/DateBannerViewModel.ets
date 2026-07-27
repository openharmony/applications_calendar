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

import { DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';


@Observed
export class DateBannerViewModel {
  // 其它历法
  public subscriptionCalendar: number = 1;
  //地区
  public systemRegion: string = '';
  public selectDate: DateInfo = new DateInfo();
  // 当前天
  public currentDate: number = 0;


  /**
   * 历法变更
   */
  onSubscriptionCalendar(subscription: number) {
    this.subscriptionCalendar = subscription;
  }

  /**
   * 地区变更
   */
  onSystemRegionChange(systemRegion: string) {
    this.systemRegion = systemRegion;
  }

  /**
   * 当前天变更
   */
  onCurrentDateChange(currentDate: number) {
    this.currentDate = currentDate;
  }
}