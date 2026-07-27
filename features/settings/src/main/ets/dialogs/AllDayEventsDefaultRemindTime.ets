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
import { CompId, GlobalData, GlobalDataKeys, MINUTES_PER_DAY } from '@app/common';
import { DEFAULT_ALL_DAY_REMINDER_OPTIONS, RadioListDialog, RadioListStyle } from '@app/common.components';
import { SettingStore } from '../Storage';
import settingKeys from '../settingKeys';

/**
 * 全天默认提醒时间弹框
 *
 * @since 2022-08-11
 */
@Component
export struct AllDayEventsDefaultRemindTime {
  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') allDayEventsDefaultRemindTime: number = 0;

  // 单选框的所属群组名称
  private readonly RADIO_GROUP = 'allDayDefaultRemindTime';

  callback: Callback<number> = () => {
  };

  build() {
    Column() {
      RadioListDialog({
        title: $r('app.string.eu3_cl_ab_settings_alldayeventremindertime'),
        compId: CompId.ALL_DAY_EVENTS_DEFAULT_REMIND_TIME,
        style: RadioListStyle.Menu,
        options: DEFAULT_ALL_DAY_REMINDER_OPTIONS,
        radioGroup: this.RADIO_GROUP,
        cancel: this.cancel,
        checkValue: $allDayEventsDefaultRemindTime,
        onChange: (value: number) => {
          GlobalData.instance().set(GlobalDataKeys.ALL_DAY_EVENTS_DEFAULT_REMIND_TIME, value);
          SettingStore.INSTANCE.set(settingKeys.allDayEventsDefaultRemindTime, value);
          this.callback(value)
        }
      })
    }
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };
}
