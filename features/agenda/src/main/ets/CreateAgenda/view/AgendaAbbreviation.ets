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

import {
  AgendaEventInfo,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  GlobalDataKeys,
  Log,
  ReportHiEventParams,
  ReportUtil
} from '@app/common';
import { PasteHelper } from '@app/common/src/main/ets/util/PasteHelper';
import { pasteboard, BusinessError, emitter } from '@kit.BasicServicesKit';
import { parseDataFromPasteString } from '@app/common/src/main/ets/default/util/ShareUtils';

const TAG: string = 'AgendaAbbreviation';

const fullRow: Length = '100%';
const withButton: Length = '85%';

@Component
export struct AgendaAbbreviation {
  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @State textContent: string = '';

  @State buttonStateEffect: boolean = true;

  @Link eventInfo: AgendaEventInfo;

  @State @Watch('onPasteBoardChanged') hasContent: boolean = false;

  private buttonBgColor: ResourceColor = $r('sys.color.comp_background_tertiary');

  private buttonIconColor: ResourceColor = $r('sys.color.font_primary');

  private buttonIconSize: Dimension = '18vp';

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private textAreaHeight: number = 40;

  @State textAreaLen: Length = this.hasContent ? withButton : fullRow;

  // 外部传入起始日期时间戳
  @Prop startTimeStamp: number = -1;


  /**
   * 可以监听剪贴板内是否有内容
   */
  private onPasteBoardChanged(): void {
    Log.info(TAG, 'paste board has content status has changed');
    this.textAreaLen = this.hasContent ? withButton : fullRow;
  }

  /**
   * 给系统剪贴板挂监听
   */
  getSupervisionOnPaste(): void {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    let listener = () => {
      Log.info(TAG, 'pasteHelper: the system board has changed.');
      this.hasContent = PasteHelper.getInstance().askSystemPaste();
      Log.info(TAG, 'hasContent value is: ' + this.hasContent);
    }
    systemPasteboard.on('update', listener);
  }

  /**
   * 取消剪贴板的监听
   */
  cancelSupervisionOnPaste(): void {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    let listener = () => {
      Log.info(TAG, 'pasteHelper: the system board has changed.');
      this.hasContent = PasteHelper.getInstance().askSystemPaste();
      Log.info(TAG, 'hasContent value is: ' + this.hasContent);
    }
    systemPasteboard.off('update', listener);
  }

  aboutToAppear(): void {
    Log.info(TAG, 'agenda abbreviation is about to appear.');
    this.hasContent = PasteHelper.getInstance().askSystemPaste();
    Log.info(TAG, 'aboutToAppear: paste board has content result is: ' + this.hasContent);
    this.getSupervisionOnPaste();
  }

  onPageShow(): void {
    Log.info(TAG, 'agenda abbreviation is on page show.');
    this.hasContent = PasteHelper.getInstance().askSystemPaste();
    Log.info(TAG, 'onPageShow: paste board has content result is: ' + this.hasContent);
  }

  aboutToDisappear(): void {
    Log.info(TAG, 'agenda abbreviation is about to disappear.');
    this.cancelSupervisionOnPaste();
  }

  async refreshBasicInfo(): Promise<void> {
    let nluEventInfo: AgendaEventInfo = await parseDataFromPasteString(this.textContent, this.startTimeStamp);
    this.eventInfo.mTitle = nluEventInfo.mTitle;
    this.eventInfo.mLocation = nluEventInfo.mLocation;
    this.eventInfo.mIsAllDay = nluEventInfo.mIsAllDay;
    this.eventInfo.mBegin = nluEventInfo.mBegin;
    this.eventInfo.mEnd = nluEventInfo.mEnd;
    let eventData: emitter.EventData = {
      data: {
        'refreshTitle': this.eventInfo.mTitle,
        'refreshLocation': this.eventInfo.mLocation,
        'refreshIsAllDay': this.eventInfo.mIsAllDay,
        'refreshBegin': this.eventInfo.mBegin,
        'refreshEnd': this.eventInfo.mEnd,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.INTELLIGENT_REFRESH }, eventData);
  }

  @Builder
  BuildAgendaAbbreviation() {
    TextArea({
      placeholder: $r('app.string.intelligent_creation'),
      text: $$this.textContent
    })
      .backgroundColor(this.isDarkMode && this.needCommerce ? $r('sys.color.comp_background_list_card') :
      $r('sys.color.comp_background_tertiary'))
      .placeholderColor(Color.Gray)//浅灰色 默认语言颜色
      .fontWeight(FontWeight.Medium)//字体粗细
      .selectedBackgroundColor(this.themeColor)//选中背景色
      .caretColor(this.themeColor)//光标颜色
      .maxLength(30)//给最大输入字符数
      .maxLines(2)
      .align(Alignment.Start)
      .constraintSize({ minHeight: this.textAreaHeight })
      .onChange(async (value) => {
        if (value.length !== 0) {
          await this.refreshBasicInfo();
        }
      })
      .onEditChange(async (isEditing) => {
      })
      .flexGrow(1)
      .id(CompId.AGENDA_ABBREVIATION);
  }

  build() {
    Flex({
      justifyContent: FlexAlign.End,
      alignItems: ItemAlign.Center
    }) {
      this.BuildAgendaAbbreviation();
    }
    .margin({ bottom: 12 });
  }
}