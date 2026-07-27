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

// 设备类型
export enum deviceType {
  PC = 0,
  PHONE = 1,
  TABLET = 2,
}

// 主页面上的tab类型
export enum TabType {
  YEAR = 0,
  MONTH = 1,
  WEEK = 2,
  DAY = 3,
  AGENDA = 4,
  SEARCH = 5,
  AGENDA_DETAIL = 6,
  MINI_MONTH = 7,
}

// 用户授权状态
export enum PermissionState {
  DENIED = -1,
  UNCONFIRMED,
  CONFIRMED
}

// 通知申请权限的状态
export enum NotificationRequestState {
  NOT_REQUEST = 0,
  REQUEST_FAILED = 1,
  REQUEST_SUCCESS = 2
}

// 穿戴设备的主页面上的tab类型 枚举参数参与 Tab 组件业务，无法复用手机枚举
export enum WearableTabType {
  MONTH = 0,
  WEEK = 1,
  AGENDA = 2,
}

// 弹窗控制器选项
export interface DialogControllerOptions {
  // 弹窗在竖直方向上的对齐方式
  alignment?: DialogAlignment;

  // 弹窗相对alignment所在位置的偏移量
  offset?: Offset;

  // 是否允许点击遮障层退出
  autoCancel?: boolean;

  // 弹窗容器样式是否自定义
  customStyle?: boolean;
}

/**
 * 弹窗特定属性（根据设备形态做区分）
 *
 */
export class DialogParams {
  // 弹窗宽度
  public width: number;

  // 按钮分割线是否显示
  public dividerShow: boolean;

  // 按钮颜色
  public buttonBackgroundColor: ResourceColor;

  // 按钮上间距
  public buttonTopPadding: number;

  // 按钮下间距
  public buttonBottomPadding: number;

  constructor(width: number, dividerShow: boolean, buttonBackgroundColor: ResourceColor,
              buttonTopPadding: number, buttonBottomPadding: number) {
    this.width = width;
    this.dividerShow = dividerShow;
    this.buttonBackgroundColor = buttonBackgroundColor;
    this.buttonTopPadding = buttonTopPadding;
    this.buttonBottomPadding = buttonBottomPadding;
  }

}