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

export const DEFAULT_NUM: number = -1;

export const DEFAULT_STR: string = '';

export const TAB_CONTROLLER_HEIGHT = 30;

export const NAVIGATION_HEIGHT = 58;

export const ACCOUNT_CIRCLE_WIDTH: number = 4;

export const ACCOUNT_CIRCLE_LEFT_MARGIN: number = 8;

export const MORE_IMAGE_WIDTH: number = 24;

export const CREATE_AGENDA_POP_HEIGHT: number = 560;

export const QUICK_CREATE_AGENDA_POP_HEIGHT: number = 400;

export enum AgendaType {
  DEFAULT = 0,
  IMPORTANT = 1
}

// 传入时间的处理类型
export enum SaveTimeType {
  DEFAULT, // 默认取当前时间
  SAVE_START_TIME, // 保留传入开始时分
  SAVE_ALL_TIME, // 保留传入开始时分和时长
}

// 新建页面的类型
export enum CreateAgendaPageSource {
  DEFAULT_CREATE_AGENDA_PAGE = 'default', // 默认新建页面
  NLU_CREATE_AGENDA_PAGE = 'createByNLU', // 拖拽传入的NLU解析后的日程
  EDIT_CREATE_AGENDA_PAGE = 'edit', // 编辑非重复日程或者所有重复日程
  EDIT_THIS_AGENDA = 'edit_this_agenda', // 编辑单个重复日程
  EDIT_THIS_AGENDA_AND_BEYOND = 'edit_this_agenda_and_beyond' // 编辑单个重复日程及以后的日程
}