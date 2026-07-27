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
import { MonthlyInfo, DateInfo } from '@app/common/src/main/ets/default/calendar/MonthlyInfo';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { DayData } from '@app/common/src/main/ets/date/Date';
import { SettingsDataModel } from './SettingsDataModel';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { SingleDayViewModel } from './SingleDayViewModel';
import { CardSingleDayViewModel } from '../viewModel/components/CardSingleDayViewModel';

const TAG: string = 'MonthCard_SigMonthVM';

/**
 * 月视图卡片单月数据模型
 */
export class CardSingleMonthViewModel {
  // 由于当前框架限制，无法直接使用月视图单日数据模型，使用业务所需数据模型处理
  public cardDayViewModels: CardSingleDayViewModel[] = [];
  private dayViewModels: SingleDayViewModel[] = [];
  private settings: SettingsDataModel;

  constructor(settings: SettingsDataModel, monthlyInfo: MonthlyInfo) {
    this.settings = settings;
    const displayDays: DayData[] = monthlyInfo.getDisplayDays();
    displayDays.forEach((item, index) => {
      this.dayViewModels.push(new SingleDayViewModel(
        settings,
        item,
        new DateInfo(monthlyInfo.solarYear, monthlyInfo.solarMonth)
      ));
      this.cardDayViewModels.push(this.dayViewModels[index].cardData);
    })
  }

}

