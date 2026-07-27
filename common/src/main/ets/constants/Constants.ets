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

// 日历包名
export const CALENDAR_BUNDLE_NAME: string = 'com.openharmony.calendar';

// 云空间包名
export const CLOUD_DRIVE_BUNDLE_NAME: string = 'com.openharmony.clouddrive';

// hover弹出tips的时延
export const TIPS_HOVER_DELAY: number = 700;

export enum ClickSource {
  MAIN_PAGE = 'mainPage',
  MESSAGE_CENTER = 'messageCenter',
  MONTH_SHARE_AGENDA = 'monthShareAgenda'
}

// 折叠屏类型
export enum FoldScreenType {
  UNKNOWN = '0,0,0,0',
  SMALL_UP_DOWN_FOLD = '4,2,0,0' // 上下小折叠
}

// 特殊模式
export enum UnusualMode {
  DEFAULT = 'default',
  HICAR = 'hicar',
  SMALL_UP_DOWN_FOLD = 'small_up_down_fold'
}

// 屏幕高宽比
export enum HeightBreakpoint {
  HEIGHT_SM = 0.8,
  HEIGHT_LG = 1.2
}

// 按钮类型
export enum ButtonImageType {
  TEXT = 0,
  SYMBOL,
  IMAGE
}

/**
 * 滑动的操作类型
 */
export enum SlideActionType {
  START,
  UPDATE,
  END
}

// 班休类型
export enum DayMark {
  NORMAL,
  OFF,
  WORK,
}

// 阿拉伯语标志 用于处理阿语场景下的定制化逻辑
export const ARABIC_LANGUAGE = 'ar';