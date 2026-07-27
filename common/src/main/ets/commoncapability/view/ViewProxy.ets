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

import { Log } from '../../default/common/Log';
import { ReportUtil } from '../../default/util/ReportUtil';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { behaviorEvents } from '../../default/common/HiEvents';

export class ViewProxy {
  protected tag: string = 'ViewProxy';
  protected logTag: string = ''
  private delegateTag: string = ''

  constructor(delegateTag: string) {
    this.delegateTag = delegateTag;
    this.logTag = `${this.tag}_${this.delegateTag}`
  }


  onHidden() {
    Log.info(this.logTag, "onHidden");
  }

  onShown() {
    hiTraceMeter.startTrace(this.logTag, 0);
    ReportUtil.reportPageDrawn();
    Log.info(this.logTag, "onShown");
    hiTraceMeter.finishTrace(this.logTag, 0);
  };

  onPageHide() {
    Log.info(this.logTag, "onPageHide");
  }

  onPageShow() {
    hiTraceMeter.startTrace(this.logTag, 0);
    ReportUtil.reportPageDrawn();
    Log.info(this.logTag, "onPageShow");
    hiTraceMeter.finishTrace(this.logTag, 0);
  }

  aboutToAppear() {
    Log.info(this.logTag, "aboutToAppear");
  }

  aboutToDisappear() {
    Log.info(this.logTag, "about to disappear");
  }


  onBackPressed(): boolean {
    Log.info(this.logTag, "onBackPressed");
    // 日历-月视图-侧滑退出应用
    ReportUtil.reportWatchBehaviorEvent(behaviorEvents.onBackFromMonth);
    return false;
  };
}