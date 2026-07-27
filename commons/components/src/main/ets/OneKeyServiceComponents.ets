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

import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import {
  AgendaEventInfo,
  AgendaItemLayout,
  behaviorEvents,
  BigFontSize,
  CalendarLayoutManager,
  CompId,
  GlobalThis,
  HiEventParamsConfirm,
  Log,
  ReportHiEventParams,
  ReportUtil,
  statisticEvents,
  TabType,
  ViewProxy
} from '@app/common';
import { addButtonTypeText } from '@app/common/src/main/ets/util/AccessibilityUtil';
import lazy { pointer } from '@kit.InputKit';
import { common } from '@kit.AbilityKit';


const TAG = 'OneKeyServiceButton';

export enum OneKeyServiceButtonType {
  LARGE,
  SMALL,
}

@Component
export struct OneKeyServicePlaceholder {
  info: AgendaEventInfo = new AgendaEventInfo();

  isExpired: boolean = false;

  textStr: Resource = {} as Resource;

  @State agendaLayout: AgendaItemLayout = CalendarLayoutManager.getInstance().agendaLayout;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  aboutToAppear() {
    if (this.info.isOnlineMeeting()) {
      this.textStr = $r('app.string.online_meeting');
    }
  }

  build() {
    Text(this.textStr)
      .opacity(this.isExpired ? $r('sys.float.alpha_tertiary') : $r('sys.float.alpha_secondary'))
      .fontColor($r('sys.color.font_primary'))
      .fontSize(this.agendaLayout.subTextFontSize)
      .fontWeight(FontWeight.Regular)
      .lineHeight(16)
      .layoutWeight(1)
      .maxLines(this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL ? 2 : 1)
  }
}

@Component
export struct OneKeyServiceButton {
  @LocalStorageLink('uiAbilityContext') context: common.UIAbilityContext | undefined = undefined;

  @Prop info: AgendaEventInfo = new AgendaEventInfo();

  @Prop serviceUri: string

  type: OneKeyServiceButtonType = OneKeyServiceButtonType.SMALL;

  btnStr: Resource = {} as Resource;

  viewType: number = -1;

  buttonPadding: number = 0;

  @StorageProp('themeColor') themeColor: string = '';

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private needCenter: boolean = true; // 按钮是否需要居中

  @State agendaLayout: AgendaItemLayout = CalendarLayoutManager.getInstance().agendaLayout;

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
  }

  onBtnClick() {
    Log.info(TAG, 'Click Join Meeting Button');
    if (!this.serviceUri) {
      return;
    }

    let want: Want = { uri: this.serviceUri }

    this.context?.startAbility(want, (err: BusinessError) => {
      if (!err.code) {
        this.reportEvents(HiEventParamsConfirm.TRUE);
        console.error(`oneKeyServiceComponent ${err.message}`);
        return;
      }
      this.reportEvents(HiEventParamsConfirm.FALSE);
      console.debug(`oneKeyServiceComponent ${err.message}`);
    });
  }

  reportEvents(isSuccess: number) {
    const start = this.serviceUri.indexOf('//') + 2;
    const end = this.serviceUri.indexOf('/', start);
    let params: ReportHiEventParams = {
      ONE_KEY_TIME: this.getTime(),
      OUTER_PNAME: this.serviceUri.substring(start, end),
      IS_SUCCESS: isSuccess,
      EVENT_TYPE: this.info.mHwextServiceType
    }
    ReportUtil.reportBehaviorEvent(behaviorEvents.oneclickServiceGoAppAgenda, params)
    const clickAgendaEvent: string = this.viewType === TabType.AGENDA_DETAIL ?
    statisticEvents.agendaDetailServiceMeeting : statisticEvents.agendaListServiceMeeting
    ReportUtil.reportStatisticEvent(clickAgendaEvent);
  }

  // 获取点击跳转会议时间在会议前、中、后的情况
  getTime() {
    const infoStartTime: number = this.info.mBegin;
    const infoEndTime: number = this.info.mEnd;
    const data = new Date().getTime();
    if (data < infoStartTime) {
      return 0;
    }
    if (data < infoEndTime) {
      return 1;
    }
    return 2;
  }

  build() {
    Column() {
      Text(this.info.getOneKeyServiceBtnStr())
        .fontColor(this.themeColor)
        .fontWeight(GlobalThis.getResourceStr($r('sys.string.ohos_id_text_font_family_medium')))
        .fontSize(this.agendaLayout.subTextFontSize)
    }
    .flexShrink(1)
    .accessibilityText(this.info.getOneKeyServiceBtnStr())
    .accessibilityLevel('yes')
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .alignSelf(this.needCenter ? ItemAlign.Center : ItemAlign.Start)
    .backgroundColor($r('app.color.default_background'))
    .onClick(() => this.onBtnClick())
    .padding({ top: this.buttonPadding, bottom: this.buttonPadding })
    .hitTestBehavior(HitTestMode.Block)
    .id(CompId.AGENDA_JOIN_MEETING_BTN)
    .onHover((isHover?: boolean) => {
      if (isHover) {
        cursorControl.setCursor(pointer.PointerStyle.HAND_POINTING);
      } else {
        cursorControl.restoreDefault();
      }
    })
  }
}
