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

// 日程详情页入口
export enum AgendaDetailSource {
  UNKNOWN = -1,
  AGENDA_LIST = 0, // 全部日程列表分栏详情
  SEARCH_LIST, // 搜索日程列表分栏详情
  DAY_VIEW, // 日视图分栏详情
  AGENDA_COVER, // 日程全模态页面
  AGENDA_ROUTER, // 日程navPath跳转页面
  AGENDA_PAGE // 日程子窗页面
}

// 搜索页面归属
export enum SearchFromPage {
  MAIN_PAGE, // 主页面
  SEARCH_ROOT, // 搜索子窗
  AGENDA_LIST_PAGE, // 全部日程列表
}