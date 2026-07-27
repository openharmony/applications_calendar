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
import { DataSourceTemplate } from '@app/common';

export enum eventAction {
  ROUTER = 'router',
  SWITCH = 'switch',
  DIALOG = 'dialog'
}

export interface ItemOption {
  label: string;
  value: number;
  checked?: boolean;
  disabled?: boolean;
}

// router（箭头项），switch（开关项）
export type Action = eventAction.DIALOG | eventAction.ROUTER | eventAction.SWITCH;

export interface ISettingItem {
  title: ResourceStr; // 单项标题
  description?: ResourceStr; // 描述
  // 是否隐藏该项,如果该设置项对应的功能没上,代码里绝对不能有这个配置,不允许通过hide = true的方法在视图上不显示来规避
  hide?: boolean;
  action: Action; // 事件类型
  event?: Function; // 事件
  init?: Function; // 初始化事件
  extra?: string; // 附加信息
  // 本地存储的key 注意 不需要本地首选的存储的,这个值必须是空,否则造成脏数据和beta问题
  settingKey?: string;

  // 本地首选的存储的默认值,settingKey不为空时,这个必须有值,不能是空
  defaultVal?: string | number; // 默认值
  syncState?: Function; // 同步持久化信息到状态管理
  openDialog?: Function; // 打开弹框
  formatExtraInfo?: Function; // 格式化附加信息
  onMounted?: Function; // 组件挂载
  compId: string; // 界面元素id，便于自动化用例设计的时候捕捉操作控件属性
}

export interface IsSettingData {
  groupName: Resource; // 设置单元(族)名称
  compId: string; //设置单元(族)id
  hide?: boolean; // 隐藏该项
  items: ISettingItem[]; // 各项数据集
}

@Observed
export class SettingDataSources extends DataSourceTemplate<IsSettingData> {
  constructor(settingDataList: IsSettingData[]) {
    super(settingDataList);
  }
}