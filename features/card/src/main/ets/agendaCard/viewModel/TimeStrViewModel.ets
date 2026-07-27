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

import { AgendaCardInfo } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { getTimeStr } from '../../utils/TimeUtils';
import { Log } from '@app/common/src/main/ets/default/common/Log';

const TAG: string = 'TimeStrViewModel';

/**
 * 日程时间转换对象
 * 由于@Builder特殊机制，布局内调用函数传参数，即使相关字段发生改变吗，也不会使布局重新加载，
 * 所以引用此方法
 */
@Observed
export class TimeStrViewModel {
  public agenda: AgendaCardInfo = new AgendaCardInfo();
  @Track public timeStrStart: ResourceStr = '';
  @Track public timeStrEnd: ResourceStr = '';

  constructor(agenda?: AgendaCardInfo) {
    if (!agenda) {
      return;
    }
    this.agenda = agenda;
    this.parseTimeStr();
  }

  /**
   * 将日程的起止时间(毫秒戳)进行本地化解析
   *
   * 如12小时制 下午01:00-下午02：00
   * 如24小时制 13:00-14:00
   */
  parseTimeStr() {
    if (this.agenda.mIsAllDay || (this.agenda.mIsMultiDayEvent && this.agenda.mFlag === AgendaCardInfo.FLAG_MID)) {
      this.timeStrStart = $r('app.string.all_day');
      return;
    }
    if (this.agenda.mIsMultiDayEvent && this.agenda.mFlag === AgendaCardInfo.FLAG_START) {
      this.timeStrStart = getTimeStr(this.agenda.mBegin);
      this.timeStrEnd = $r('app.string.start_date');
    } else if (this.agenda.mIsMultiDayEvent && this.agenda.mFlag === AgendaCardInfo.FLAG_END) {
      this.timeStrStart = getTimeStr(this.agenda.mEnd);
      this.timeStrEnd = $r('app.string.end_date');
    } else {
      this.timeStrStart = getTimeStr(this.agenda.mBegin);
      this.timeStrEnd = getTimeStr(this.agenda.mEnd);
    }
  }
}