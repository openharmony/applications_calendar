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

import { AgendaEventInfo, CalendarContract,
  CalendarDate,
  CalendarService, CommonService, CornerType, DateUtil, InnerResultSet, Log } from '@app/common';
import { SelectEventInfo } from './SelectEventInfo';
import HashMap from '@ohos.util.HashMap';

const TAG: string = 'DeleteEventProcessor';

/**
 * process event process.
 *
 * @since 2022-10-07
 */
export class DeleteEventProcessor {
  private selectedEvents: Set<number> = new Set();
  private allEventData: SelectEventInfo[] = [];
  private eventContentData: SelectEventInfo[] = [];

  /**
   * Get eventContentData length.
   */
  public getEventContentSize(): number {
    return this.eventContentData.length;
  }

  /**
   * Getter for selectedEvents
   */
  public getSelectedEvents(): Set<number> {
    return this.selectedEvents;
  }

  /**
   * Getter for allEventData
   */
  public getAllEventData(): SelectEventInfo[] {
    return this.allEventData;
  }

  /**
   * 从数据结果集获取日程对象
   *
   * @param resultSet 查询结果集合
   * @return 日程列表
   */
  public async getEventsList(resultSet: InnerResultSet): Promise<SelectEventInfo[]> {
    let itemData: SelectEventInfo[] = [];
    try {
      if (resultSet.rowCount <= 0) {
        Log.error(TAG, 'count = 0');
        return itemData;
      }
      this.allEventData = [];
      let lastAgendaDay: number = -1;
      let accounts: CalendarContract.Accounts[] =
        await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
      const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
      resultSet.goToRow(-1);
      while (resultSet.goToNextRow()) {
        let eventInfo: SelectEventInfo = (AgendaEventInfo.buildEventInfo(resultSet)) as SelectEventInfo;
        if (eventInfo.mBegin === 0) {
          continue;
        }
        eventInfo.mDisplayColor = accountMap.get(eventInfo.mCalendarId).calendarColor;
        eventInfo.mType = SelectEventInfo.SELECT_EVENT_INFO_NORMAL;

        let startDay: number = DateUtil.getJulianDay(eventInfo.mBegin);
        if (startDay !== lastAgendaDay) {
          lastAgendaDay = startDay;
          eventInfo.mCornerType = CornerType.CORNER_UP;
          let headInfo: SelectEventInfo = this.buildHeaderInfo(startDay, eventInfo.mBegin);
          let length: number = itemData.length;
          if (length > 0) {
            itemData[length - 1].mCornerType |= CornerType.CORNER_DOWN;
          }
          itemData.push(headInfo);
        }
        itemData.push(eventInfo);
        this.allEventData.push(eventInfo);
        this.eventContentData.push(eventInfo);
      }
      itemData[itemData.length - 1].mCornerType |= CornerType.CORNER_DOWN;
    } catch (err) {
      Log.logErrorMsg(TAG, 'getEventsList', err);
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
    return itemData;
  }

  private buildContentInfo(id: number, title: string, dtstart: number,
                           dtend: number, location: string, allDay: boolean) {
    let agenda: SelectEventInfo = new SelectEventInfo();
    agenda.mId = id;
    agenda.mTitle = title;
    agenda.mBegin = dtstart;
    agenda.mEnd = dtend;
    agenda.mDisplayColor = -12213274;
    agenda.mCornerType = CornerType.CORNER_NONE;
    agenda.mType = SelectEventInfo.SELECT_EVENT_INFO_NORMAL;
    agenda.mLocation = location;
    agenda.mIsAllDay = allDay;
    return agenda;
  }

  private buildHeaderInfo(agendaDay: number, dtstart: number) {
    let agenda: SelectEventInfo = new SelectEventInfo();
    agenda.mId = 0;
    agenda.mBegin = dtstart;
    agenda.mTitle = agendaDay + '';
    agenda.mType = SelectEventInfo.SELECT_EVENT_INFO_DATA_HEADER;
    return agenda;
  }
}