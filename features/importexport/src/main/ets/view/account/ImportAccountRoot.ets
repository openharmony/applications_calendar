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

import { CommonInnerEvent, DeviceConfig, GlobalThis, NavPageBuilderFactory, NavPathName, ViewProxy } from '@app/common/index';
import { ImportAccountGroupList } from './ImportAccountGroupList';
import emitter from '@ohos.events.emitter';

const TAG: string = 'CreateAgendaRoot';

@Builder
function harBuilder(value: object) {
  ImportAccountRoot();
}

const builderName = NavPathName.IMPORT_ACCOUNT;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

/**
 * 全部帐户界面
 *
 * @since 2023-12-22
 */

@Component
export struct ImportAccountRoot {
  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageLink('language') language: string = '';

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  @Builder
  buildContent() {
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
            md: 6,
            lg: 8
          },
          offset: {
            xs: 0,
            sm: 0,
            md: 1,
            lg: 2
          }
        }) {
          ImportAccountGroupList()
        }
      }
    }
    .height('100%')
  }

  build() {
    NavDestination() {
      this.buildContent()
    }
    .padding({
      top: this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
      bottom: this.windowAvoidAreaNavigationRectHeight
    })
    .title(GlobalThis.getResourceStr($r('app.string.title_account'), this.language))
    .backgroundColor($r('sys.color.background_secondary'))
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
  }

  // 侧滑或者返回，拉起半模态
  aboutToDisappear() {
    emitter.emit({ eventId: CommonInnerEvent.VCS_SHOW_PAGE })
  }

  @Builder
  NaviTitle() {
    NaviTitleBar()
  }
}

@Component
struct NaviTitleBar {
  @Consume navPathStack: NavPathStack;

  //image fillColor
  @State imgFillColor: string = '#000000';

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  build() {
    Row() {
      Stack() {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.chevron_backward'))
            .fontSize('24vp')
            .fontColor([$r('sys.color.icon_primary')])
        }
        .focusable(true)
        .backgroundColor(this.buttonBackgroundColor)
        .width(40)
        .height(40)
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor(this.buttonBackgroundColor)
        .onClick(() => {
          this.navPathStack.pop();
        })
      }

      Text($r('app.string.Import_account'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 8 })
    }
    .height(56)
    .margin({ left: 16 })
  }
}