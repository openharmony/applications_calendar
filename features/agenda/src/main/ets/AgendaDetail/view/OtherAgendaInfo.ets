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

import { AgendaEventInfo, CompId, SafeUtil } from '@app/common';
import lazy { EventOtherWelinkInfo } from './EventOtherWelinkInfo';
import { EventOtherInfo } from './EventOtherInfo';
import { DEFAULT_NUM, DEFAULT_STR } from '../../CreateAgenda/Constants';

@Component
export struct OtherAgendaInfo {
  @Prop @Watch('onInfo') info: AgendaEventInfo;

  @Prop @Watch('onCheckIdChange') checkId: number;

  @State mImportantEventType: number = 0;

  @State mDescription: string = '';

  @State isReload: boolean = false;

  // 帐户颜色
  @Prop accountColor: number = DEFAULT_NUM;

  // 帐户展示名
  @Prop accountDisName: ResourceStr = DEFAULT_STR;

  @Link isAgendaCollapse: boolean;

  private isCover: boolean = false;

  private eventId: number = -1;

  onInfo() {
    if (this.eventId === this.info.mId && this.eventId !== -1 &&
      (this.mDescription === this.info.mDescription || this.mDescription === this.info.mHwextServiceDescription)) {
      return;
    }
    this.eventId = this.info.mId
    this.mImportantEventType = this.info.mImportantEventType;
  }

  onCheckIdChange() {
    // 下树上树，刷新组件
    this.isReload = true;
    SafeUtil.setTimeout(() => {
      this.isReload = false;
    }, 20)
  }

  aboutToAppear(): void {
    this.mImportantEventType = this.info.mImportantEventType;
  }

  getDescription() {
    let mDescription = this.info.mDescription;
    if (this.isShowHtml()) {
      mDescription = this.info.mHwextServiceDescription.startsWith('<html>') ?
      this.info.mHwextServiceDescription : this.info.mDescription;
    }
    return mDescription;
  }

  isShowHtml() {
    // 低概率 this.accountDisName.length 报错
    // this.accountDisName = accountMap.get(id).calendarDisplayName ?? ''; 值为0|false
    // this.accountDisName = GlobalThis.getResourceStr($r('app.string.contact_birthday')); 值为非字符串
    return (this.info.mHwextServiceDescription && this.info.mHwextServiceType === 'Meeting') ||
      ((typeof this.accountDisName === 'string') && this.accountDisName && (this.accountDisName?.length !== 0) &&
        (this.accountDisName?.startsWith('WeLink', 0)));
  }

  build() {
    Stack() {
      if (this.isShowHtml()) {
        // 先下树再上树
        if (!this.isReload) {
          EventOtherWelinkInfo({
            accountColor: this.accountColor,
            accountDisName: this.accountDisName,
            description: this.getDescription(),
            mImportantEventType: this.mImportantEventType,
            isCover: this.isCover,
            isAgendaCollapse: this.isAgendaCollapse,
            eventUuid: this.info.uuid
          })
        }
      } else {
        EventOtherInfo({
          accountColor: this.accountColor,
          accountDisName: this.accountDisName,
          description: this.getDescription(),
          mImportantEventType: this.mImportantEventType
        }).id(CompId.EVENT_OTHER_INFO)
      }
    }
  }
}