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
import lazy { CreateAgendaRoot } from './CreateAgendaRoot';
import { emitter } from '@kit.BasicServicesKit';
import { CREATE_AGENDA_POP_HEIGHT, QUICK_CREATE_AGENDA_POP_HEIGHT } from '../Constants';
import { DeviceConfig } from '@app/common';

const TAG = 'CreatePopupContent';

/**
 * 新建日程跟手弹窗内容组件
 *
 * @since 2024-11-11
 */
@Component
export struct CreatePopupContent {
  @Provide isAgendaAniShowFinish: boolean = false;
  private createPageData: emitter.EventData = {};
  @State isShowCreateAgenda: boolean = false;
  @State isQuickCreate: boolean = false;
  @Link discardDialogInCreateAgendaPageFlag: boolean;

  // 新建/编辑日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  // 宽度是否占满父组件
  private setFullWidth: boolean = false;

  private onCreatePageDismiss: () => void = () => {
  };

  private changeEditedFlag: () => void = () => {
  };

  aboutToAppear(): void {
    // 该值在子组件CreateAgendaRoot里以@Prop接收，没初始值的话子组件会初始化失败
    this.discardDialogInCreateAgendaPageFlag = false;
  }

  build() {
    Column() {
      CreateAgendaRoot({
        createPageData: this.createPageData,
        isShowCreateAgenda: $isShowCreateAgenda,
        discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
        isQuickCreate: this.isQuickCreate,
        onCreatePageDismiss: this.onCreatePageDismiss,
        changeEditedFlag: this.changeEditedFlag
      })
    }
    .backgroundColor(this.isQuickCreate ? $r('sys.color.ohos_id_color_list_card_bg') : undefined)
    .width(this.isQuickCreate ? 346 : this.setFullWidth ? '100%' : 400)
    .height(this.isCreateAgendaPopup ? '100%' : undefined) // 新建日程弹窗跟手时需要设置height，避免无法下拉
    .constraintSize({ maxHeight: this.isQuickCreate ? QUICK_CREATE_AGENDA_POP_HEIGHT : CREATE_AGENDA_POP_HEIGHT })
  }
}

/**
 * 临时方案,pop当前pc不会避让窗口三键,需要手动进行y坐标偏移,因y坐标偏移会导致弹窗超出屏幕故需要计算只在可能遮挡窗口三键时避让
 * @param windowY 当前点击的Y坐标
 * @param isQuickCreate 是否为快速创建
 * @param windowHeight 当前窗口的高度
 */
export function getPopOffsetY(windowY: number, windowHeight: number): number {
  const titleHeight = 48; // 避让高度
  const popHeight = CREATE_AGENDA_POP_HEIGHT;
  const nowHeight = Math.min(popHeight, windowHeight - 80);
  if (windowY <= (nowHeight / 2) + titleHeight) {
    return titleHeight;
  } else {
    return 0;
  }
}