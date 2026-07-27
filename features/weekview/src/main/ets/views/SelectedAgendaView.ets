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
import { RootViewModel } from '../viewmodel/RootViewModel';
import { AgendaDetail, AgendaDetailSource } from '@app/feature.agenda';
import { AgendaEventInfo, CombineAnimateParam, CompId, DeviceConfig } from '@app/common';
import { RootModel } from '../model/RootModel';

const TAG: string = 'SelectedAgendaView';

//提出图片通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct SelectedAgendaView {
  @Consume @Watch('onRootVMChange') rootVM: RootViewModel;

  @State canEdit: boolean = true;

  @State canShare: boolean = true;

  @State eventId: number = -1;

  @State holidayInfo: AgendaEventInfo | undefined = undefined;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @Consume SelectedAgendaViewAnimateParam: CombineAnimateParam;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onRootVMChange(): void {
    if (this.rootVM.selectAgendaInfo) {
      this.eventId = this.rootVM.selectAgendaInfo.mId;
      this.holidayInfo = this.rootVM.selectAgendaInfo;
    } else {
      this.eventId = -1;
      this.holidayInfo = undefined;
    }
  }

  aboutToAppear() {
    //分屏状态需要初始化时重新赋值
    if (this.rootVM.selectAgendaInfo) {
      this.eventId = this.rootVM.selectAgendaInfo.mId;
      this.holidayInfo = this.rootVM.selectAgendaInfo;
    }
  }

  build() {
    if (this.rootVM.isDivide) {
      Column() {
        if (this.rootVM.selectAgendaInfo === undefined) {
          Column() {
            Image($r('app.media.ic_no_agenda')).width(96).height(96).commonProperties().edgeAntialiasing(this.antialiasingNumber)
            Text($r('app.string.agenda_empty_text')).fontSize(14).opacity(0.6).id(CompId.NO_AGENDA)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height('100%')
        } else {
          AgendaDetail({
            canEdit: $canEdit,
            canShare: $canShare,
            eventId: $eventId,
            holidayInfo: this.holidayInfo,
            sourceType: AgendaDetailSource.DAY_VIEW,
            displayStartMills: this.rootVM.selectAgendaInfo?.mBegin,
            displayEndMills: this.rootVM.selectAgendaInfo?.mEnd,
            needLeftPadding: false,
            needRightPadding: false,
            onDeleteSuccess: () => {
            },
            paddingLeft: 0,
            paddingRight: 16,
          })
            .width('100%')
            .height('100%')
            .id(CompId.SELECTED_AGENDA_VIEW_AGENDA_DETAIL)
        }
      }
      .visibility(this.SelectedAgendaViewAnimateParam.visibility ? Visibility.Visible : Visibility.Hidden)
      .transition(
        TransitionEffect.OPACITY
          .combine(TransitionEffect.translate(this.SelectedAgendaViewAnimateParam.translateOptions)
            .animation(this.SelectedAgendaViewAnimateParam.translateAnimateParam))
          .combine(TransitionEffect.opacity(this.SelectedAgendaViewAnimateParam.opacity)
            .animation(this.SelectedAgendaViewAnimateParam.opacityAnimateParam))
          .combine(TransitionEffect.scale(this.SelectedAgendaViewAnimateParam.scaleOption)
            .animation(this.SelectedAgendaViewAnimateParam.scaleAnimateParam))
      )
      .size({ width: this.rootVM.detailWidth, height: this.rootVM.bottomHeight })
      .padding({ right: $r('sys.float.padding_level8') })
    }
  }
}