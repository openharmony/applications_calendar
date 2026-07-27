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

import { AgendaEventInfo } from '../../../agenda/AgendaEventInfo';
import { Service } from '../../framework/Service';

/**
 * 日程服务
 */
export abstract class AgendaService extends Service {
  abstract updateRepeatAgendaTitle(agendaInfo: AgendaEventInfo, date: number);

  abstract updateNormalAgendaTitle(agendaInfo: AgendaEventInfo, startMills: number);

  abstract agendaTitleDayOffset(agendaInfo: AgendaEventInfo, instancesStartMills: number, referenceDate: number);
}