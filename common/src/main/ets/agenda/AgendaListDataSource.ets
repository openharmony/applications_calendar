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

import { AgendaEventInfo } from './AgendaEventInfo';
import { DataSourceTemplate } from '../templates/BasicDataSource';

/**
 * 日程列表的懒加载数据源
 */
export class AgendaListDataSource extends DataSourceTemplate<AgendaListItemViewModel> {
  constructor(agendaDataList: AgendaListItemViewModel[]) {
    super(agendaDataList);
  }

  public getDataList() : AgendaListItemViewModel[] {
    return this.mDataSource;
  }
}

@Observed
export class AgendaListItemViewModel extends AgendaEventInfo {
  public isSelected: boolean = false;

  public getEditAblePropStr(): string {
    return `${super.getEditAblePropStr()}-${this.isSelected}`;
  }

  /**
   * 当前项是否可以多选
   */
  canMultiSelect(): boolean {
    return !this.isHoliday() && !this.isContactBirthday();
  }

  constructor(agenda: AgendaEventInfo | undefined = undefined) {
    super(agenda);
  }
}