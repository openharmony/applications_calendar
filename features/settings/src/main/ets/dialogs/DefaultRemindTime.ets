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
import { behaviorEvents, CompId, GlobalData, GlobalDataKeys } from '@app/common';
import { DEFAULT_REMINDER_OPTIONS, RadioListDialog, RadioListStyle } from '@app/common.components';
import { SettingStore } from '../Storage';
import settingKeys from '../settingKeys';
import { HiEventParamsConfirm, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';

/**
 * 默认提醒时间弹框
 *
 * @since 2022-08-11
 */
@Component
export struct DefaultRemindTime {
  // 默认提醒时间
  @StorageLink('defaultRemindTime') defaultRemindTime: number = 10;

  // 单选框的所属群组名称
  private readonly RADIO_GROUP = 'defaultRemindTime';

  callback: Callback<number> = () => {
  };

  build() {
    Column() {
      RadioListDialog({
        title: $r('app.string.preferences_default_reminder_title'),
        compId: CompId.DEFAULT_REMINDER_TIME,
        options: DEFAULT_REMINDER_OPTIONS,
        radioGroup: this.RADIO_GROUP,
        cancel: this.cancel,
        style: RadioListStyle.Menu,
        checkValue: this.defaultRemindTime,
        onChange: (value: number) => {
          GlobalData.instance().set(GlobalDataKeys.DEFAULT_REMIND_TIME, value);
          SettingStore.INSTANCE.set(settingKeys.defaultRemindTime, value);
          let params: ReportHiEventParams = {
            REMINDER_MINUTE: value,
            IS_ALLDAY: HiEventParamsConfirm.FALSE,
          }
          this.callback(value)
          ReportUtil.reportBehaviorEvent(behaviorEvents.settingsRemindSelect, params);
        }
      })
    }
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };
}
