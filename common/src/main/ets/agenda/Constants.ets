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

// 日程服务类型-->一键服务按钮文字map 卡片框架限制，不支持额外导包
const SERVICE_TYPE_ARR: [string, Resource][] = [
  ['Meeting', $r('app.string.join_the_meeting')],
  ['Watching', $r('app.string.watch_now')],
  ['Repayment', $r('app.string.repay_now')],
  ['Live', $r('app.string.start_live_broadcast')],
  ['Shopping', $r('app.string.start_shopping')],
  ['Trip', $r('app.string.view_now')],
  ['Class', $r('app.string.start_the_class')],
  ['SportsEvents', $r('app.string.watch_now')],
  ['SportsExercise', $r('app.string.start_exercising')],
]

export const SERVICE_TYPE_MAP: ReadonlyMap<string, Resource> = new Map(SERVICE_TYPE_ARR);
export const AGENDA_SEARCH_DATE_BEGIN = '1900-1-1'; // 默认搜索日程开始范围
export const AGENDA_SEARCH_DATE_END = '2101-1-1'; // 默认搜索日程结束范围
export const MINUTES_BEFORE_MEETING = 15; // 开会前15分钟,用于一键入会按钮的显示
export const AGENDA_SUB_DETAIL_WIDTH = 620; // 用于日程是否显示详情子窗的宽度校验

// 长按预览入口
export enum PreviewFromType {
  SEARCH_AGENDA_VIEW = 0,
  MONTH_VIEW = 1,
  AGENDA_LIST = 2
}

// 新建半模态拉起入口
export enum CreateAgendaSheetFromPage {
  MAIN_PAGE,
  IMPORTANT_CARD_SELECT,
  AGENDA_LIST_PAGE,
}