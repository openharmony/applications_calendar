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
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  GlobalThis,
  Log,
  NavPathManager,
  NavPathName,
  RouterName,
  ViewProxy
} from '@app/common';
import { call } from '@kit.TelephonyKit';
import { emitter } from '@kit.BasicServicesKit';
import { VersionInfo } from '../routerPages/VersionInfo';

/**
 * 设置-关于
 */

const TAG: string = 'HalfModeAboutPage';

@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct HalfModeAboutPage {
  @Link isShowAboutPage: boolean;

  @Consume navPathStack: NavPathStack;

  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageLink('themeColor') themeColor: string = '';

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private settingsAboutHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowAboutPage = true;
  };

  aboutToAppear(): void {
    // PC上点击备案号详情页返回关于详情页
    emitter.on({ eventId: CommonInnerEvent.SETTINGS_ABOUT }, this.settingsAboutHandler);
  }

  aboutToDisappear(): void {
    emitter.off(CommonInnerEvent.SETTINGS_ABOUT, this.settingsAboutHandler);
  }

  @Builder
  buildTitleBar() {
    HalfModeNaviTitleBar({
      title: $r('app.string.about'),
      onClosePage: () => {
        this.isShowAboutPage = false;
      }
    })
  }

  @Builder
  buildAppDisplayRecord() {
    Column() {
      GridRow({
        columns: {
          xs: 2,
          sm: 4,
          md: 8,
          lg: 12
        },
        gutter: 0
      }) {
        GridCol({
          span: {
            xs: 2,
            sm: 4,
            md: 8,
            lg: 12
          },
          offset: {
            xs: 0,
            sm: 0,
            md: 1,
            lg: 0
          }
        }) {
          Navigation()
            .width('100%')
            .height(56)
            .title(this.buildTitleBar())
            .titleMode(NavigationTitleMode.Mini)
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .margin({ bottom: 8 })
        }
      }

      this.calendarImage()
    }
    .padding({ bottom: 16 })
    .backgroundColor(Color.Transparent)
  }

  @Builder
  calendarImage() {
    Column() {
      Image($r('app.media.calendar_about'))
        .width(72)
        .height(72)
        .fillColor($r('sys.color.ohos_fa_icon_fourth'))
        .edgeAntialiasing(this.antialiasingNumber)
        .margin({ left: 4, right: 6, bottom: 6 })
        .borderRadius(18)
    }

    Text($r('app.string.calendar'))
      .fontSize(20)
      .fontWeight(FontWeight.Medium)
      .fontFamily('HarmonyHeiTi')
      .maxLines(1)
  }

  build() {
    NavDestination() {
      this.buildAppDisplayRecord()
    }
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }
}

@Component
struct HalfModeNaviTitleBar {
  //image fillColor
  @State imgFillColor: string = '#000000';

  title: ResourceStr = '';

  build() {
    Row() {
      Column() {
        Text(this.title)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .flexShrink(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize('18vp')
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_primary'))
        }
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.cancel_dialog_button')))
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .width(40)
        .height(40)
        .id(CompId.BACK_MAIN)
        .onClick(() => {
          this.onClosePage()
        })
      }
      .flexShrink(0)
    }
    .height(56)
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16 })
    .margin({ top: 8 })
  }

  // 关闭半模态
  private onClosePage: () => void = (): void => {
  };
}