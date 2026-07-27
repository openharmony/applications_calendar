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

import {
  CityTimeZone,
  CommonInnerEvent,
  CompId,
  DataSourceTemplate,
  Log,
  ServiceEnum,
  ServiceManager,
} from '@app/common';
import { TimeZoneService } from '@app/service.timezone'
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'TimeZoneViewModel';

@Observed
class TimeZoneSource extends DataSourceTemplate<CityTimeZone> {
  constructor(timeZoneDataList: CityTimeZone[]) {
    super(timeZoneDataList);
  }
}

@Observed
export class TimeZoneViewModel {
  private timeZoneList: CityTimeZone[] = [];
  private originalTimeZoneList: CityTimeZone[] = [];
  @Track public dataSource: TimeZoneSource = new TimeZoneSource([]);
  @Track public isShowSearch: boolean = false;
  @Track public isShowSearchResult: boolean = false;
  @Track public searchResultCount: number = 0;

  init() {
    this.getTimeZoneList();
  }

  private async getTimeZoneList() {
    const service = await ServiceManager.getInstance()
      .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
    if (!service) {
      Log.warn(TAG, `syncTimeZoneData TimeZoneService is undefined`);
      return;
    }
    this.timeZoneList = await service.getTimeZoneList();
    this.originalTimeZoneList = [...this.timeZoneList];
    this.dataSource.setData(this.timeZoneList);
  }

  searchChange(value: string) {
    if (value) {
      let searchList: CityTimeZone[] = this.originalTimeZoneList.filter((item: CityTimeZone) => {
        return item.cityDisplayName.includes(value) || item.offset.includes(value);
      });
      this.searchResultCount = searchList.length;
      this.isShowSearchResult = true;
      this.dataSource.setData(searchList);
    } else {
      this.searchResultCount = 0;
      this.isShowSearchResult = false;
      this.resetTimeZoneList();
    }
  }

  resetTimeZoneList() {
    this.dataSource.setData(this.timeZoneList);
  }

  async timeZoneChange(cityItem: CityTimeZone, fromAgenda: boolean): Promise<boolean> {
    // 来自创建日程的时区选择事件
    if (fromAgenda) {
      let eventData: emitter.EventData = {
        data: {
          'cityDisplayName': cityItem.cityDisplayName,
          'timezoneId': cityItem.timezoneId,
          'offset': cityItem.offset,
          'cityId': cityItem.cityId,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.AGENDA_TIME_ZONE_CHANGED }, eventData);
      return true;
    } else {
      let isConfirm = await this.updateLockedTimeZone(cityItem.timezoneId);
      return isConfirm;
    }
  }

  private async updateLockedTimeZone(timeZoneId: string): Promise<boolean> {
    const service = await ServiceManager.getInstance()
      .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
    if (!service) {
      Log.warn(TAG, `updateLockedTimeZone server is null`);
      return false;
    }
    const updateTimeZone = await service.updateLockedTimeZone(timeZoneId);
    return updateTimeZone;
  }

  public async onLanguageChange(language: string) {
    const service = await ServiceManager.getInstance()
      .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
    if (!service) {
      Log.warn(TAG, `syncTimeZoneData TimeZoneService is undefined`);
      return;
    }
    let flag = await service.updateTimeZoneList(language);
    if (flag) {
      await this.getTimeZoneList()
    }
  }

  getTimeZoneListKey(city: CityTimeZone, index: number, searchText: string) {
    return `${index}-${city.cityDisplayName}-${city.timezoneId}-${city.cityId}-${searchText}`;
  }

  changeShowSearch() {
    animateTo({
      duration: 200,
      curve: Curve.Linear,
      onFinish: () => {
        if (this.isShowSearch) {
          focusControl.requestFocus(CompId.TIME_ZONE_SEARCH_INPUT);
        }
      }
    }, () => {
      this.isShowSearch = !this.isShowSearch;
    });
  }
}