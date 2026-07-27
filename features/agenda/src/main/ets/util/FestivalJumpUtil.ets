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

import { GlobalDataKeys } from '@app/common/src/main/ets/data/GlobalDataKeys';
import { GlobalData } from '@app/common/src/main/ets/data/GlobalData';
import { FESTIVAL_CONFIG_INFO_MAP } from './FestivalConfig';
import { NetConnectionUtil } from '@app/service.network';

export class FestivalJumpUtil {
  /**
   * 是否需要加载订阅web链接布局
   * @param title 节日节气标题
   * @param startMills 开始时间
   * @param isHoliday 是否Holiday
   * @returns true：需要跳转 false：否
   */
  public static async shouldShowSubscriptionWebView(title: string | undefined, startMills: number,
    isHoliday: boolean | undefined): Promise<boolean> {
    if (!await NetConnectionUtil.isNetAvailable()) {
      return false;
    }
    if (!isHoliday || !title) {
      return false;
    }
    if (!FESTIVAL_CONFIG_INFO_MAP.hasKey(title?.trim())) {
      return false;
    }
    let nowDate: Date = new Date();
    let holidayDate: Date = new Date(startMills);
    // 仅去年、今年显示
    const diffYear = nowDate.getUTCFullYear() - holidayDate.getUTCFullYear();
    if (diffYear < 0 || diffYear > 1) {
      return false;
    }
    return true;
  }
}