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

import { CalendarDate, DateRange, DAY_PER_WEEK, HOURS_PER_DAY, TabType } from '@app/common';
import { DayModel } from './DayModel';

export class RootModel {
  private static _instance: RootModel = new RootModel();
  public readonly GANTT_VIEW_SCALE_KEY: string = 'GANTT_VIEW_SCALE_KEY'; // 当前甘特图缩放的KEY值
  public readonly SWIPER_ITEM_COUNT: number = 3;
  public readonly DATE_MARGIN_TOP: number = 8;
  public readonly DATE_MARGIN_BOTTOM: number = 12;
  public readonly SWIPER_DURATION: number = 300;
  public readonly GRID_NAVI_MARGIN: number = 12; // 甘特图底部导航栏规避高度
  public readonly GRID_MARGIN_BOTTOM: number = 20;
  public readonly BLOCK_SPACE: number = 1.5; // 当前甘特图日程块间距
  public weekends: number[] = [];
  public weekTitles: string[] = [];
  public dayModelMatrix: Array<DayModel[]> = [];
  public startOfWeek: number = 0;
  public dateRange: DateRange.Range = { start: Date.now(), end: Date.now() };
  public systemRegion: string = 'CN';
  public subscriptionCalendar: number = 0; // 目前只有农历日程,需要摘到公用定义去，目前枚举在feature/setting
  public language: string = ''; //系统语言
  public curTab: TabType = TabType.MONTH;
  public displayDate: number = new CalendarDate().setHours(0, 0, 0, 0);
  public is24HourClock: boolean = false;
  public readonly SWIPER_ARRAY: number[] = Array.from(new Array<number>(this.SWIPER_ITEM_COUNT));
  public readonly WEEK_ARRAY: number[] = Array.from(new Array<number>(DAY_PER_WEEK));
  public readonly GRID_ROW_ARRAY: number[] = Array.from(new Array<number>(HOURS_PER_DAY));
  public scale: number = 1;
  private readonly HOUR_COUNT: number = HOURS_PER_DAY - 1;
  public readonly HOUR_ARRAY: number[] = Array.from(new Array<number>(this.HOUR_COUNT));
  private readonly DAY_COUNT: number = DAY_PER_WEEK + 1;
  public readonly WEEK_ROW_ARRAY: number[] = Array.from(new Array<number>(this.DAY_COUNT));

  static instance(): RootModel {
    return RootModel._instance;
  }
}