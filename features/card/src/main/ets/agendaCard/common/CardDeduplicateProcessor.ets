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
import { CalendarAccountType } from '@app/common/src/main/ets/account/AccountConst';

const WELINK_ACCOUNT_CREATOR_OLD: string = 'com.openharmony.it.works';

const WELINK_ACCOUNT_CREATOR: string = 'com.openharmony.it.welink';

const TAG = 'CardDeduplicateUtils';

/**
 * 卡片日程数据去重处理者
 */
export class CardDeduplicateProcessor {
  private readonly CALENDAR_DATA_ACCOUNT_CREATOR: string = 'com.ohos.calendardata';
  private readonly CALENDAR_ACCOUNT_CREATOR: string = 'com.ohos.calendar';
  public static readonly INSTANCE: CardDeduplicateProcessor = new CardDeduplicateProcessor();

  /**
   * 卡片日程信息数组去重。
   *
   * @param eventInfos 去重后的日程列表
   */
  public reduceAgendaCardInfos(agendaCards: AgendaCardInfo[]): AgendaCardInfo[] {
    const uniqueArray = agendaCards.reduce((agendas, current) => {
      const existingItem = agendas.find(item => this.compareData(item, current));
      if (!existingItem) {
        agendas.push(current);
      }
      return agendas;
    }, [] as AgendaCardInfo[]);

    return uniqueArray;
  }

  private compareData(agendaOld: AgendaCardInfo, agendaNew: AgendaCardInfo): boolean {
    return (agendaOld.mBegin === agendaNew.mBegin) &&
      (agendaOld.mEnd === agendaNew.mEnd) &&
    this.isNeedProcessEvent(agendaOld, agendaNew) &&
      (agendaOld.mTitle === agendaNew.mTitle) &&
      (agendaOld.mCalendarId === agendaNew.mCalendarId) &&
      (agendaOld.mLocation === agendaNew.mLocation) &&
      (agendaOld.mIsAllDay === agendaNew.mIsAllDay);
  }

  private isWeLinkEvent(agendaCardInfo: AgendaCardInfo): boolean {
    return (agendaCardInfo.mCreator === WELINK_ACCOUNT_CREATOR ||
      agendaCardInfo.mCreator === WELINK_ACCOUNT_CREATOR_OLD);
  }

  private isNeedProcessEvent(agendaOld: AgendaCardInfo, agendaNew: AgendaCardInfo): boolean {
    return (this.isWeLinkEvent(agendaOld) && this.isWeLinkEvent(agendaNew)) ||
      (this.isSelfAccountEvent(agendaOld) && this.isSelfAccountEvent(agendaNew));
  }

  private isSelfAccountEvent(agendaCardInfo: AgendaCardInfo): boolean {
    return (agendaCardInfo.mCalendarType == CalendarAccountType.CUSTOM_ACCOUNT_TYPE ||
      agendaCardInfo.mCalendarType === CalendarAccountType.LOCAL_ACCOUNT_TYPE) &&
      (agendaCardInfo.mCreator === this.CALENDAR_DATA_ACCOUNT_CREATOR ||
        agendaCardInfo.mCreator === this.CALENDAR_ACCOUNT_CREATOR);
  }
}