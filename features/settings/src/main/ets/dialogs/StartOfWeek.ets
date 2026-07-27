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
import { behaviorEvents, CommonInnerEvent, CompId, GlobalData, GlobalDataKeys, StartOfWeekUtils } from '@app/common';
import { RadioListDialog, RadioListDialogOption, RadioListStyle } from '@app/common.components';
import { SettingStore } from '../Storage';
import settingKeys from '../settingKeys';
import { ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'StartOfWeekDialog';

// 星期配置项，周日~周六对应算法值中的0~6
export const options: RadioListDialogOption[] = [
  { label: $r('app.string.default_week_start_day'), value: -1, compId: CompId.LOCAL_DEFAULT },
  { label: $r('app.string.Sunday'), value: 0, compId: CompId.SUNDAY },
  { label: $r('app.string.Monday'), value: 1, compId: CompId.MONDAY },
  { label: $r('app.string.Tuesday'), value: 2, compId: CompId.TUESDAY },
  { label: $r('app.string.Wednesday'), value: 3, compId: CompId.WEDNESDAY },
  { label: $r('app.string.Thursday'), value: 4, compId: CompId.THURSDAY },
  { label: $r('app.string.Friday'), value: 5, compId: CompId.FRIDAY },
  { label: $r('app.string.Saturday'), value: 6, compId: CompId.SATURDAY }
];

/**
 * 一周开始日弹框
 *
 * @since 2022-07-26
 */
@Component
export struct StartOfWeek {
  // 一周开始日
  @StorageLink('startOfWeek') startOfWeek: number = 0;

  // 单选框的所属群组名称
  private readonly RADIO_GROUP: string = 'startOfWeek';

  callback: Callback<number> = () => {
  };

  build() {
    Column() {
      RadioListDialog({
        title: $r('app.string.preferences_week_start_day_title'),
        compId: CompId.WEEK_STARTS_ON,
        options: options,
        radioGroup: this.RADIO_GROUP,
        style: RadioListStyle.Menu,
        cancel: this.cancel,
        checkValue: this.startOfWeek,
        onChange: (value: number) => {
          GlobalData.instance().set(GlobalDataKeys.START_OF_WEEK, value);
          SettingStore.INSTANCE.set(settingKeys.startOfWeek, value);
          StartOfWeekUtils.setSettingsStartOfWeek(value);
          let params: ReportHiEventParams = {
            WEEK_DAY: value
          };
          emitter.emit({ eventId: CommonInnerEvent.SETTINGS_START_OF_WEEK });
          ReportUtil.reportBehaviorEvent(behaviorEvents.settingsWeekSelectStartTime, params);
          this.callback(value);
        }
      });
    };
  }

  // 关闭弹窗
  private cancel: () => void = (): void => {
  };
}
