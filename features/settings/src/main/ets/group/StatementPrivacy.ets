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
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { behaviorEvents, BigFontSize, DeviceConfig, FontSizeScaleUtils, ReportUtil, NavPathManager, RouterName, Log } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { NetWorkManger } from '@app/service.network';

const TAG: string = 'StatementPrivacy';

@Component
export struct StatementPrivacy {
  @Consume navPathStack: NavPathStack;

  @Consume isShowSettingPage: boolean;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 主标题
  private title: ResourceStr = '';

  // 描述
  private description: ResourceStr = '';

  //
  private compId: string = '';

  private isBindSheet: boolean = false;

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  @Builder
  buildSettingTitle() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: 8 })
      }
    }
    .flexShrink(1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: 8 })
  }

  @Builder
  buildArrow() {
    Row() {
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          24
        ))
        .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
        .margin({ left: 4 })
    }
    .alignItems(VerticalAlign.Center)
    .constraintSize({ minHeight: 24 })
    .clip(true)
    .flexShrink(0)
  }

  build() {
    Row() {
      this.buildSettingTitle();
      this.buildArrow();
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .constraintSize({
      minHeight: this.rowMinHeight
    })
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .borderRadius(14)
    .onClick(async () => {
      const isUserAgreeNetWork: boolean = NetWorkManger.getInstance().isUserAgreeNetWorkSync();
      if (!isUserAgreeNetWork) {
        return;
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.settingSecurityPrivacy);
      const params: Record<string, number | boolean | string> = {};
      params.sourcePage = NavPathName.SETTING_MAIN;
      params.isInPop = this.isInPop;
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.PAF_PRIVACY_PAGE,
        routerName: (this.isInPop || this.isShowSettingPage) ? RouterName.SETTING_HAP : RouterName.ENTRY_HAP,
        param: params
      })
    })
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .id(this.compId)
  }

  aboutToAppear() {
    this?.onMounted();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };
}