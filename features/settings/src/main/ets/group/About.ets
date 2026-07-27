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

import { Action, eventAction } from '../groupConfig/declare';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { BigFontSize, DeviceConfig, FontSizeScaleUtils, Log, NavPathManager, RouterName } from '@app/common';
import { HalfModeAboutPage } from './HalfModeAboutPage';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'About';

@Component
export struct About {
  @State isShowAppDisplayRecordPage: boolean = false;

  @State isNeedShowNetWorkDialog: boolean = false;

  @State @Watch('onIsShowAboutPage') isShowAboutPage: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  // 主标题
  private title: ResourceStr = '';

  // 描述
  private description: ResourceStr = '';

  // 触发的行为类型，赋初值防止ArkTS报错
  private action: Action = eventAction.ROUTER;

  // 设置项key值
  private settingKey: string = '';

  // 设置项的默认值
  private defaultVal: string | number = '';

  //
  private compId: string = '';

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  private isBindSheet: boolean = false;

  private isShowAbout: boolean = DeviceConfig.instance().config.showAboutInSetting;

  onIsShowAboutPage() {
    Log.info(TAG, 'Try to Show About, and isShowAboutPage = ' + this.isShowAboutPage)
  }

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
        .fontColor([$r('sys.color.icon_fourth')])
        .margin({ left: 4 })
    }
    .alignItems(VerticalAlign.Center)
    .constraintSize({ minHeight: 24 })
    .clip(true)
    .flexShrink(0)
  }

  @Builder
  buildCreateAboutPage() {
    Column() {
      HalfModeAboutPage({
        isShowAboutPage: $isShowAboutPage
      });
    }
    .height('100%')
    .width('100%')
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
      minHeight:this.rowMinHeight
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
    .focusBox({ margin: LengthMetrics.vp(-2) })
    .onClick(() => {
      if (this.isInPop || this.isBindSheet) {
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.SETTING_ABOUT,
          routerName: RouterName.SETTING_HAP,
          param: { isInPop: this.isInPop }
        })
        return;
      }

      if (this.isShowAbout) {
        this.isShowAboutPage = true;
      } else {
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.SETTING_ABOUT,
          routerName: RouterName.ENTRY_HAP,
          param: {}
        })
      }
    })
    .bindSheet($$this.isShowAboutPage, this.buildCreateAboutPage(), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.CENTER,
      backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
      maskColor: $r('sys.color.ohos_id_color_mask_thin'),
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
    })
    .id(this.compId)
  }

  aboutToAppear() {
    this?.onMounted();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 打开弹框
  private openDialog: Function = () => {
  };
}