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

import { CompId } from '@app/common';
import { SubTitle } from '@app/common.components';
import { ISettingItem } from '../groupConfig/declare';
import { GroupItem } from './GroupItem';
import { StartOfWeekSettingItem } from './StartOfWeekSettingItem';
import { WeekendsSettingItem } from './WeekendsSettingItem';
import { DefaultReminderTimeItem } from './DefaultReminderTimeItem';
import { DefaultReminderTimeForAllDayEvent } from './DefaultReminderTimeForAllDayEvent';
import { CalendarChoseItem } from './CalendarChoseItem';
import { StatementPrivacy } from './StatementPrivacy';
import { About } from './About';
import { TimeZone } from './TimeZone'

/**
 * 设置单元(族)
 *
 * @since 2022-06-25
 */
@Component
export struct Group {
  // 设置族的标题
  @State title: Resource = $r('app.string.preferences_general_title');

  // 设置族数据
  @State items: ISettingItem[] = [];

  // 设置界面隐藏的设置项
  @StorageLink('settingsHiddenItems') settingsHiddenItems: string[] = [];

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  // 是否半模态
  private isBindSheet: boolean = false;

  private index: number = 0;

  private compId: string = '';

  build() {
    Column() {
      SubTitle({ title: this.title, compId: this.compId })
        .visibility(this.index === 0 ? Visibility.None : Visibility.Visible)
      List() {
        ForEach(this.items, (item: ISettingItem) => {
          if (!this.settingsHiddenItems.includes(
                  item.settingKey as string) && !item.hide) { // settingsHiddenItems存放的设置项不显示
            ListItem() {
              if (item.compId === CompId.SETTINGS_START_OF_WEEK) {
                StartOfWeekSettingItem({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  compId: item.compId,
                  openDialog: this.openDialog
                })
              } else if (item.compId === CompId.SETTINGS_WEEKENDS) {
                WeekendsSettingItem({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  compId: item.compId,
                  openDialog: this.openDialog
                })
              } else if (item.compId === CompId.SETTINGS_DEFAULT_REMINDER_TIME) {
                DefaultReminderTimeItem({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  compId: item.compId,
                  openDialog: this.openDialog
                })
              } else if (item.compId === CompId.SETTINGS_REMINDER_TIME_FOR_ALLDAY_EVENT) {
                DefaultReminderTimeForAllDayEvent({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  compId: item.compId,
                  openDialog: this.openDialog
                })
              } else if (item.compId === CompId.SETTINGS_CALENDAR) {
                CalendarChoseItem({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  openDialog: this.openDialog,
                  compId: item.compId
                })
              } else if (item.compId === CompId.SETTINGS_TIME_ZONE) {
                TimeZone({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  openDialog: this.openDialog,
                  compId: item.compId,
                  isInPop: this.isInPop,
                })
              } else if (item.compId === CompId.SETTINGS_About) {
                About({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  openDialog: this.openDialog,
                  compId: item.compId,
                  isInPop: this.isInPop,
                  isBindSheet: this.isBindSheet
                })
              } else {
                GroupItem({
                  title: item.title,
                  description: item.description,
                  action: item.action,
                  event: item.event,
                  onMounted: item.onMounted,
                  settingKey: item.settingKey,
                  defaultVal: item.defaultVal,
                  openDialog: this.openDialog,
                  formatExtraInfo: item.formatExtraInfo,
                  compId: item.compId,
                })
              }
            }
          }
        })
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(16)
      .padding({
        top: 4,
        bottom: 4,
        left: 4,
        right: 4
      })
      .divider({
        strokeWidth: 0.5,
        color: $r('sys.color.comp_divider'),
        startMargin: 8,
        endMargin: 8
      })
    }
  }

  // 打开弹框
  private openDialog: Function = () => {
  };
}
