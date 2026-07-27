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

import { AgendaEventInfo } from '@app/common';

export { SelectEventInfo };

/**
 * Event Bean for multi delete page.
 *
 * @since 2022-10-07
 */
class SelectEventInfo extends AgendaEventInfo {
  /**
   * 日程内容
   */
  public static SELECT_EVENT_INFO_NORMAL: number = 0;

  /**
   * 头布局
   */
  public static SELECT_EVENT_INFO_DATA_HEADER: number = 1;

  public mType: number = 0;

  private mIsSelected: boolean = false;

  /**
   * Getter for mType
   */
  public getSelectEventType(): number {
    return this.mType;
  }

  /**
   * Getter for mIsSelected
   */
  public getSelected(): boolean {
    return this.mIsSelected;
  }

  /**
   * Setter for isSelected
   */
  public setSelected(isSelected: boolean) {
    this.mIsSelected = isSelected;
  }
}