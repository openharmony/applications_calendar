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
import { GlobalThis } from '../data/GlobalThis';
import lazy { accessibility } from '@kit.AccessibilityKit';
import { SafeUtil } from './SafeUtil';
import { Log } from '../default/common/Log';
import { BusinessError } from '@ohos.base';

const TAG = 'AccessibilityUtil'
/**
 * 增加按钮控件类型
 *
 * @param text 朗读内容
 * @returns 播报内容
 */
export function addButtonTypeText(text: ResourceStr): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  return GlobalThis.getResourceStrParms($r('app.string.accessibility_button'), content);
}

/**
 * 增加展开/收起状态
 *
 * @param text 朗读内容
 * @param isExpand 是否已展开
 * @returns 播报内容
 */
export function addExpandStatusText(text: ResourceStr, isExpand: boolean): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  const status = isExpand ? GlobalThis.getResourceStr($r('app.string.accessibility_Expanded')) :
    GlobalThis.getResourceStr($r('app.string.accessibility_Collapsed'));
  return status + content;
}

/**
 * 增加 展开/收起状态 + 按钮控件类型
 *
 * @param text 朗读内容
 * @param isExpand 是否已展开
 * @returns 播报内容
 */
export function addExpandStatusAndButton(text: ResourceStr, isExpand: boolean): string {
  return addButtonTypeText(addExpandStatusText(text, isExpand));
}

/**
 * 增加 展开/收起状态
 *
 * @param text 朗读内容
 * @param isExpand 是否已展开
 * @returns 播报内容
 */
export function addExpandStatus(text: ResourceStr, isExpand: boolean): string {
  return barText(addExpandStatusText(text, isExpand));
}

/**
 * 主动播报
 *
 * @param content 播报内容
 */
export function broadcastContent(content: string): void {
  let eventInfo: accessibility.EventInfo = ({
    type: 'announceForAccessibility',
    bundleName: 'com.openharmony.calendar',
    triggerAction: 'common',
    textAnnouncedForAccessibility: content
  });

  accessibility.sendAccessibilityEvent(eventInfo);
}

/**
 * 主动播报,不打断上一次播报
 *
 * @param content 播报内容
 */
export function broadcastContentNotInterrupt(content: string): void {
  let eventInfo: accessibility.EventInfo = ({
    type: 'announceForAccessibilityNotInterrupt',
    bundleName: 'com.openharmony.calendar',
    triggerAction: 'common',
    textAnnouncedForAccessibility: content
  });

  accessibility.sendAccessibilityEvent(eventInfo);
}

/**
 * 控件改变时，主动播报已展开/已收起
 *
 * @param isExpand 展开状态
 */
export function broadcastExpandStatus(isExpand: boolean): void {
  const status = isExpand ? GlobalThis.getResourceStr($r('app.string.accessibility_Expanded')) :
  GlobalThis.getResourceStr($r('app.string.accessibility_Collapsed'));
  broadcastContent(status);
}

export function broadcastSingleWeekStatus(isExpand: boolean): void {
  const month = GlobalThis.getResourceStr($r('app.string.description_Month_Card'));
  const normalMode = GlobalThis.getResourceStr($r('app.string.normal_mode'));
  const singleWeek = GlobalThis.getResourceStr($r('app.string.single_week_mode'));
  const status = isExpand ? `${month}${normalMode}` : `${month}${singleWeek}`;
  broadcastContent(status);
}

export function broadcastFullScreenStatus(isExpand: boolean): void {
  const month = GlobalThis.getResourceStr($r('app.string.description_Month_Card'));
  const fullScreen = GlobalThis.getResourceStr($r('app.string.full_screen_mode'));
  const normalMode = GlobalThis.getResourceStr($r('app.string.normal_mode'));
  const status = isExpand ? `${month}${fullScreen}` : `${month}${normalMode}`;
  broadcastContent(status);
}

/**
 * 增加已选中/未选中状态
 *
 * @param text 朗读内容
 * @param isSelect 是否已展开
 * @returns 播报内容
 */
export function addSelectStatusText(text: ResourceStr, isSelect: boolean): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  const status = isSelect ? GlobalThis.getResourceStr($r('app.string.checkbox_checked')) :
    GlobalThis.getResourceStr($r('app.string.checkbox_not_checked'));
  return status + content;
}

/**
 * 增加未选中状态
 *
 * @param text 朗读内容
 * @param isSelect 是否已选中
 * @returns 播报内容
 */
export function addOnlySelectStatusText(text: ResourceStr, isSelect: boolean): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  const status = isSelect ? GlobalThis.getResourceStr($r('app.string.checkbox_checked')) : '';
  return status + content;
}

/**
 * 增加已选中/未选中状态
 *
 * @param text 朗读内容
 * @param isSelect 是否已展开
 * @returns 播报内容
 */
export function addSelectStatusTextParms(text: ResourceStr, isSelect: boolean,
                                         ...args: Array<string | number>): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStrParms(text, ...args);
  }
  const status = isSelect ? GlobalThis.getResourceStr($r('app.string.checkbox_checked')) :
  GlobalThis.getResourceStr($r('app.string.checkbox_not_checked'));
  return status + content;
}

/**
 * 增加 已选中/未选中状态 + 按钮控件类型
 *
 * @param text 朗读内容
 * @param isExpand 是否已展开
 * @returns 播报内容
 */
export function addSelectStatusAndButton(text: ResourceStr, isSelect: boolean): string {
  return addButtonTypeText(addSelectStatusText(text, isSelect));
}

export function barText(text: ResourceStr): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  return content;
}

export function addSelectStatusAndButtonParams(text: ResourceStr, isSelect: boolean,
                                               ...args: Array<string | number>): string {
  return addButtonTypeText(addSelectStatusTextParms(text, isSelect, ...args));
}

/**
 * 增加今天
 *
 * @param text 朗读内容
 * @param isToday 是否已选中
 * @returns 播报内容
 */
export function addTodayText(text: ResourceStr, isToday: boolean): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  const status = isToday ? GlobalThis.getResourceStr($r('app.string.today')) : '';
  return status + content;
}

/**
 * 设置无障碍元素聚焦
 */
export function focusComponentById(id: string, delay: number): void {
  SafeUtil.setTimeout(async () => {
    let eventInfo: accessibility.EventInfo = ({
      type: 'requestFocusForAccessibility',
      bundleName: 'com.openharmony.calendar',
      triggerAction: 'common',
      customId: id
    });

    accessibility.sendAccessibilityEvent(eventInfo);
  }, delay)
}

/**
 * 控件改变时，主动播报已选中/未选中
 *
 * @param isSelect 选中状态
 */
export function broadcastSelectStatus(isSelect: boolean): void {
  const status = isSelect ? GlobalThis.getResourceStr($r('app.string.checkbox_checked')) :
    GlobalThis.getResourceStr($r('app.string.checkbox_not_checked'));
  broadcastContent(status);
}

/**
 * 朗读增加图片控件类型
 *
 * @param text 朗读内容
 * @returns 播报内容
 */
export function addImageText(text: ResourceStr): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  return GlobalThis.getResourceStrParms($r('app.string.accessibility_image'), content);
}

/**
 * 朗读增加开关控件类型
 *
 * @param text 朗读内容
 * @returns 播报内容
 */
export function addSwitchText(text: ResourceStr, isOn: boolean): string {
  let content = '';
  if (typeof text === 'string') {
    content = text;
  } else {
    content = GlobalThis.getResourceStr(text);
  }
  const status = isOn ? $r('app.string.accessibility_switch_open_text_1') :
    $r('app.string.accessibility_switch_close_text_1');
  return GlobalThis.getResourceStrParms(status, content);
}

export function switchOpenText(isOn: boolean): string {
  return isOn ? GlobalThis.getResourceStr($r('app.string.double_click_finger_close')) :
  GlobalThis.getResourceStr($r('app.string.double_click_finger_open'));
}

/**
 * 开关改变时，主动播报开启/关闭
 *
 * @param isOn 开关状态
 */
export function broadcastSwitchStatus(isOn: boolean): void {
  const status = isOn ? GlobalThis.getResourceStr($r('app.string.accessibility_switch_open_status')) :
  GlobalThis.getResourceStr($r('app.string.accessibility_switch_close_status'));
  broadcastContent(status);
}

/**
 * 重新设置新焦点位置的场景
 * 适用场景：当前焦点所在的控件消失或者隐藏后，需要重新设置新的焦点位置
 *
 * @param customId 组件ID
 * @param type  accessibility.EventType
 * @param action  accessibility.Action
 */
export function sendAccessibilityEvent(customCompId: string,
                                       type: accessibility.EventType = 'requestFocusForAccessibility',
                                       action: accessibility.Action = 'common'): Promise<void> {
  let eventInfo: accessibility.EventInfo = ({
    type,
    bundleName: 'com.openharmony.calendar',
    triggerAction: action,
    customId: customCompId
  });

  return accessibility.sendAccessibilityEvent(eventInfo).then(() => {
    Log.info(TAG, `Succeeded in send event, customId is ${customCompId}`);
  }).catch((err: BusinessError) => {
    Log.logErrorMsg(TAG, `accessibility sendAccessibilityEvent failed: ${err.message}`);
  });
}

