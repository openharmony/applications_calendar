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
import { CardAction } from '../../../common/CardAction';
import i18n from '@ohos.i18n';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { CalendarDate } from '@app/common/src/main/ets/date/CalendarDate';

const TAG: string = 'WeekTitleViewModel';

/**
 * 月视图切换轮播按钮的 VM
 */
@Observed
export class MonthSwitchViewModel {
  // 当天日期
  public displayDate: CalendarDate = new CalendarDate();
  // 按钮是否被禁用
  public isButtonBanned: boolean = false;

  constructor() {

  }

  /**
   * 按钮禁用动作
   * @param isButtonBanned 按钮禁用效果
   */
  onIsButtonBannedChange(isButtonBanned: boolean) {
    Log.info(TAG, 'onIsButtonBannedChange: isButtonBanned = ' + isButtonBanned);
    this.isButtonBanned = isButtonBanned;
  }

  /**
   * 显示日期变更
   * @param displayDate
   */
  onDisplayDateChange(displayDate: CalendarDate) {
    Log.info(TAG, 'displayDate = ' + displayDate.toString());
    this.displayDate = displayDate;
  }

  /**
   * 执行按钮点击操作
   * @param component 绑定的页面
   * @param action 按钮执行动作类型
   * @returns 是否成功发起切换动作
   */
  onButtonClick(component: Object, action: CardAction): boolean {
    Log.info(TAG, 'onButtonClick action = ' + action + ', this.isButtonBanned = ' + this.isButtonBanned);
    if (!this.isButtonBanned) {
      this.switchCurMonth(component, action);
      this.isButtonBanned = true;
      return true;
    } else {
      Log.warn(TAG, 'onButtonClick Button has been banned!');
      return false;
    }
  }

  /**
   * 传入date返回对应的年月日字符串
   *
   * @param date 日期
   * @returns 格式化后的字符串
   */
  getDateText(date: CalendarDate): string {
    if (!date) {
      return '';
    }
    const lang: string = i18n.System.getSystemLanguage();
    return date.toLocaleDateString(lang, { year: 'numeric', month: 'short' });
  }

  /**
   * 跳转到下个月
   *
   * @param component 改动作绑定的视图，卡片接口指定需要传入
   * @param directionState
   */
  private switchCurMonth(component: Object, directionState: number) {
    Log.info(TAG, `switchCurMonth need send postCardAction to controller`);
    postCardAction(component, {
      action: 'message',
      params: {
        message: directionState,
        displayDate: this.displayDate.getTime()
      }
    });
  }
}
