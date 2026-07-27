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

const TAG: string = '[MonthCard][MonthExtCardViewModel]';

@Observed
export class MonthExtCardViewModel {
  // 第一次创建卡片，数据处理是否完成
  public isDataProcessedFirstTime: boolean = false;
  // 单月行数
  public rowNum: number = 6;
  // 当前卡片选中的日期
  public todayDate: CalendarDate = new CalendarDate()

  constructor() {
  }
}

