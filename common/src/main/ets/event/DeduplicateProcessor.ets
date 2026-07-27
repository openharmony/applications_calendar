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

import { AccountUtils } from '../account/AccountUtils';
import { AgendaEventInfo } from '../agenda/AgendaEventInfo';
import { CommonService } from '../dao/CommonService';
import { CalendarService } from '../dao/service/CalendarService';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { Log } from '../default/common/Log';
import { ArkTSUtils, collections, HashMap } from '@kit.ArkTS';

/**
 * 重复日程处理者
 */
@Sendable
export class DeduplicateProcessor {
  private tag:string = 'DeduplicateUtils';
  public static readonly INSTANCE: DeduplicateProcessor = new DeduplicateProcessor();
  private deduplicateCaches : collections.Map<number, collections.Set<number>> = new collections.Map();
  private lock_: ArkTSUtils.locks.AsyncLock = new ArkTSUtils.locks.AsyncLock();

  /**
   * 日程信息数组去重。
   *
   * @param eventInfos 去重后的日程列表
   */
  public async reduceAgendaEventInfos(eventInfos: AgendaEventInfo[], accountMap: HashMap<number,
    CalendarContract.Accounts>): Promise<AgendaEventInfo[]> {
    Log.debug(this.tag, `reduceAgendaEventInfos start`);

    const noNeedProcessEvents: AgendaEventInfo[] = [];
    const resultMap = new Map<string, AgendaEventInfo>();
    for (const item of eventInfos) {
      if (!this.isNeedProcessEvent(item, accountMap)) {
        noNeedProcessEvents.push(item);
        continue;
      }
      await this.startReduce(resultMap, item);
    }
    return Array.from(resultMap.values()).concat(noNeedProcessEvents);
  }

  private async startReduce(resultMap: Map<string, AgendaEventInfo>, item: AgendaEventInfo) {
    const existingItem = resultMap.get(item.hashcode());
    if (existingItem) {
      Log.info(this.tag, `find reduceAgendaEventInfos ${item.mId} ${existingItem.mId}`);
      await this.lock_.lockAsync(() => {
        const cache = this.deduplicateCaches.get(existingItem.mId);
        if (cache) {
          this.deduplicateCaches.get(existingItem.mId)?.add(item.mId);
        } else {
          this.deduplicateCaches.set(existingItem.mId, new collections.Set([item.mId]));
        }
      });
    } else {
      resultMap.set(item.hashcode(), item);
    }
  }

  /**
   * 日程信息数组去重。
   *
   * @param eventInfos 去重后的日程列表
   */
  public async reduceAgendaEventInfosByCalendarUuid(
          eventInfos: AgendaEventInfo[],
          accountMap: HashMap<string, CalendarContract.Accounts>): Promise<AgendaEventInfo[]> {
    Log.debug(this.tag, `reduceWearableAgendaEventInfos start`);

    const noNeedProcessEvents: AgendaEventInfo[] = [];
    const resultMap = new Map<string, AgendaEventInfo>();
    for (const item of eventInfos) {
      if (!this.isNeedProcessEventByCalendarUuid(item, accountMap)) {
        noNeedProcessEvents.push(item);
        continue;
      }
      await this.startReduce(resultMap, item);
    }
    return Array.from(resultMap.values()).concat(noNeedProcessEvents);
  }


  public async getAllReduceEventIds(eventIdList: number[]): Promise<number[]> {
    let eventIds: number[] = [];
    for (const eventId of eventIdList) {
      await this.lock_.lockAsync(() => {
        const ids = this.deduplicateCaches.get(eventId);
        if (ids && ids.size > 0) {
          eventIds.push(...Array.from(ids));
        }
      })
    }
    return eventIds;
  }

  private isNeedProcessEvent(eventInfo: AgendaEventInfo,
                             accountMap: HashMap<number, CalendarContract.Accounts>): boolean {
    return this.isWeLinkEvent(eventInfo) || this.isSelfAccountEvent(eventInfo, accountMap);
  }

  private isNeedProcessEventByCalendarUuid(eventInfo: AgendaEventInfo,
                                           accountMap: HashMap<string, CalendarContract.Accounts>): boolean {
    return this.isWeLinkEvent(eventInfo) ||
      this.isSelfAccountEventByAccount(eventInfo, accountMap.get(eventInfo.mCalendarUuid));
  }

  private isWeLinkEvent(eventInfo: AgendaEventInfo): boolean {
    return (eventInfo.mCreator === AccountUtils.WELINK_ACCOUNT_CREATOR ||
      eventInfo.mCreator === AccountUtils.WELINK_ACCOUNT_CREATOR_OLD);
  }

  private isSelfAccountEvent(eventInfo: AgendaEventInfo,
                             accountMap: HashMap<number, CalendarContract.Accounts>): boolean {
    const accountType = accountMap.get(eventInfo.mCalendarId);
    if (eventInfo.mCalendarId) {
      return (AccountUtils.isDefaultAccount(accountType) ||
      AccountUtils.isCustomAccount(accountType)) &&
        (eventInfo.mCreator === AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR ||
          eventInfo.mCreator === AccountUtils.CALENDAR_ACCOUNT_CREATOR);
    }
    return false;
  }

  private isSelfAccountEventByAccount(eventInfo: AgendaEventInfo, account: CalendarContract.Accounts): boolean {
    if (eventInfo.mCalendarId) {
      return (AccountUtils.isDefaultAccount(account) ||
      AccountUtils.isCustomAccount(account)) &&
        (eventInfo.mCreator === AccountUtils.CALENDAR_DATA_ACCOUNT_CREATOR ||
          eventInfo.mCreator === AccountUtils.CALENDAR_ACCOUNT_CREATOR);
    }
    return false;
  }
}