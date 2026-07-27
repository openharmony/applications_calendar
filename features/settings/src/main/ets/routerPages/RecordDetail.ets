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

import { CommonInnerEvent, CompId, DeviceConfig, GlobalThis, NavPageBuilderFactory, NavPathManager, NavPathName, RouterName, ViewProxy } from '@app/common';
import web_webview from '@ohos.web.webview';
import { emitter } from '@kit.BasicServicesKit';
import { LengthMetrics } from '@kit.ArkUI';

/**
 * 备案号详情页
 */

const TAG: string = 'RecordDetail';

@Builder
function harBuilder(value: object) {
  RecordDetail();
}

const builderName = NavPathName.APP_DISPLAY_RECORD_DETAIL;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct RecordDetail {
  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageLink('language') language: string = '';

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  controller: web_webview.WebviewController = new web_webview.WebviewController();

  @Consume navPathStack: NavPathStack;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private isInPop: boolean = false;

  aboutToAppear(): void {
    const params = NavPathManager.getInstance().getParamByName<PopPageParam>(NavPathName.SETTING_ABOUT,
      RouterName.SETTING_HAP);
    if (!params[0]) {
      return;
    }
    const paramsInter = params[0] as PopPageParam;
    this.isInPop = paramsInter.isInPop;
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
            md: 0,
            lg: 0
          }
        }) {
          Column() {
            Web({
              src: getContext().resourceManager.getStringSync($r('app.string.record_url').id),
              controller: this.controller
            })
              .key('PrivacyComponent_Web')
              .backgroundColor($r('sys.color.background_secondary'))
              .flexShrink(1)
              .backgroundColor($r('sys.color.background_secondary'))
              .darkMode(WebDarkMode.Auto)
              .forceDarkAccess(true)
              .javaScriptAccess(true)
              .domStorageAccess(true)
              .databaseAccess(true)
              .zoomAccess(true)
              .imageAccess(true)
              .onlineImageAccess(true)
              .fileAccess(true)
              .cacheMode(CacheMode.Default)
              .width('100%')
              .height('100%')
          }
        }
      }
      .layoutWeight(1)
    }
  }

  build() {
    NavDestination() {
      this.buildAppDisplayRecord()
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({
      top: this.isInPop ? 0 : $r('sys.float.padding_level4'),
      bottom: this.isInPop ? 0 : this.windowAvoidAreaNavigationRectHeight
    })
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .hideTitleBar(false)
    .title(GlobalThis.getResourceStr($r('app.string.record_manager_system_title'), this.language),
      { paddingStart: LengthMetrics.vp(16) })
  }
}

@Component
export struct NaviTitleBar {
  @Consume navPathStack: NavPathStack;

  //image fillColor
  @State imgFillColor: string = '#000000';

  title: ResourceStr = '';

  private navPath: string = '';

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  build() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
          .opacity($r('sys.float.alpha_primary'))
      }
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .width(40)
      .height(40)
      .id(CompId.BACK_MAIN)
      .onClick(() => {
        this.navPathStack.pop();
        this.openAboutPage()
      })
      .height(56)

      Text(this.title)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8, right: 8 })
        .padding({ right: 16 })
    }
    .height(56)
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  openAboutPage() {
    emitter.emit({ eventId: CommonInnerEvent.SETTINGS_ABOUT });
  }
}
// 子窗跳转参数
export interface PopPageParam {
  isInPop: boolean;
  isImportantRing: boolean;
}