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


export enum ShareTypeEnum {

  ACCOUNT, // 账户

  AGENDA, // 日程

  STOP_SHARE, // 停止分享

  NOTIFICATION // 普通通知
}


export enum NotifyTypeEnum {

  WEEK = 0, // 弱通知

  POWER = 1 // 强通知
}


export enum NotifyHandlerEnum {

  DEFAULT = -1,

  REFUSE = 0, // 拒绝

  UNDETERMINED = 1, // 待定

  ACCEPT = 2 // 接受

}


export enum MessageStatusTypeEnum {

  UNREAD, // 未读

  READ // 已读
}


export enum SourceTypeEnum {
  ACCOUNT = 0,
  AGENDA = 1,
  MESSAGE = 2,
  PUSH = 3
}


export enum ShareMemberSourceTypeEnum {
  CALENDAR_AGENDA = 1,

  MESSAGE = 2
}


export enum ShareRole {
  INITIATOR = 0, // 发起者
  INVITEE = 1 // 受邀者
}

export enum ShareStatus {
  UNDETERMINED = 'undetermined', // 待定
  ACCEPT = 'accept', // 接受
  REFUSE = 'refuse', // 拒绝
  DEFAULT = 'default',
  CLOUD = 'cloud',
  EXIT = 'exit', // 退出
  UNAVAILABLE = 'unAvailable' // 对端关闭了共享开关
}


export enum MessageCalendarSwitchEnum {
  CLOSE,

  OPEN
}


export enum AcceptStatusEnum {

  /**
   * 发起邀请的初始状态
   */
  INITIAL = 0,

  /**
   * 已接受
   */
  ACCEPTED = 1,

  /**
   * 已拒绝
   */
  REJECTED = 2,

  /**
   * 待处理
   */
  SUSPENDED = 3
}

export enum PushMessagePushTypeEnum {
  BACKGROUND = 'BACKGROUND',
  ALERT = 'ALERT'
}

export enum PushMessageActionEnum {
  DEFAULT = 0, // 默认

  REVOKE = 1 // 撤回
}