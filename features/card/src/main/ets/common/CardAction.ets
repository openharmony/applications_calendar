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

export enum CardAction {
  FINISH_FIRST_DATA_PROCESSING, // 第一次数据代理数据传输结束

  REFRESH_MONTH_VIEW, // 日程卡刷新月视图

  UPDATE_FIXED_EVENT_ID, // 更新固定日程ID

  DEFAULT_STATE, // 月视图卡片跨天刷新
  SWITCH_TO_NEXT_MONTH, // 月视图切换到下个月
  SWITCH_TO_PRE_MONTH, // 月视图切换到上个月
  REFRESH_AGENDA_DOT, // 月视图刷新日程红点

  CLICK_DELAY_REFRESH, // 透明卡_点击延时刷新
  REFRESH_DAY_4X6, // 4X6卡片_刷新天
  UPDATE_LATEST_EVENT_ID, // 更新最新的日程ID

  SEARCH_AGENDA_4X6, // 4X6卡片_查询日程
  REMOVE_ADDED_4X6, // 4X6卡片_清除卡片框架绑定数据

  REFRESH_CARD_DATA_AND_VIEW, // 透明卡_刷新数据+视图

  CALCULATE_IMPORTANT_CARD_MODE, // 重要日卡片，尝试重新计算卡片模式

  FESTIVAL_ABBREVIATION_CHANGE, // 节假日缩略字段变化

  REFRESH_TIME_ZONE, // 用于刷新时区数据
}

