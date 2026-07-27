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

import { behaviorEvents, CommonInnerEvent, CompId, GlobalData, GlobalDataKeys } from '@app/common';
import { RadioListDialog, RadioListDialogOption, RadioListStyle } from '@app/common.components';
import { SettingStore } from '../Storage';
import settingKeys from '../settingKeys';
import { ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { currentSupportOptions } from '../data/calendar/CalendarConfig';
import { emitter } from '@kit.BasicServicesKit';

/**
 * 设置其他历法
 *
 * @since 2024-02-26
 */

//历法配置项
export const options: RadioListDialogOption[] = currentSupportOptions;

@Component
export struct SubscriptionCalendar {
  // 其它历法
  @StorageLink('subscriptionCalendar') subscriptionCalendar: number = -1;

  //标记位
  @State isBackToPage: boolean = false;

  // 单选框的所属群组名称
  private readonly RADIO_GROUP = 'subscriptionCalendar';

  // 已选择历法（0表示未选择，1表示已选择）
  private choseSubscriptionCalendar = 1;

  callback: Callback<number> = () => {
  };

  build() {
    Column() {
      RadioListDialog({
        title: $r('app.string.subscription_calendar'),
        compId: CompId.ALTERNATE_CALENDARS,
        options: options,
        radioGroup: this.RADIO_GROUP,
        cancel: this.cancel,
        style: RadioListStyle.Menu,
        checkValue: this.subscriptionCalendar,
        onChange: (value: number) => {
          GlobalData.instance().set(GlobalDataKeys.SUBSCRIPTION_CALENDAR, value);
          SettingStore.INSTANCE.set(settingKeys.subscriptionCalendar, value);
          if (!GlobalData.instance().get(GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR)) {
            GlobalData.instance().set(GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR, true);
            SettingStore.INSTANCE.set(settingKeys.isChooseSubscriptionCalendar, this.choseSubscriptionCalendar);
          }
          let params: ReportHiEventParams = {
            DISPLAY_NAME: value
          }
          emitter.emit({ eventId: CommonInnerEvent.SETTINGS_OTHER_CALENDAR });
          ReportUtil.reportBehaviorEvent(behaviorEvents.settingsSelectCalendar, params);
          this.callback(value);
        }
      })
    }
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };
}