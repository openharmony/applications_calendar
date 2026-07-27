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
import { SideBarMonthView } from './monthview/view/SideBarMonthView';
import { CompId, DeviceConfig, GlobalDataKeys, FeatureType, Log, traceEvents } from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';
import { deviceInfo } from '@kit.BasicServicesKit';

const TAG: string = 'SideBar';

/**
 * 侧边栏内容首页
 *
 * @since 2022-06-25
 */
@Component
export struct SideBar {
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @Link displayDate: number;

  @Prop blankHeight: number; //用于左上角留空用的空白高度

  @Consume sideBarOverlay: boolean;

  @Consume @Watch('onShowLeftBarChange') isShowLeftBar: boolean;

  @Consume sidebarVisible: boolean;

//系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  @StorageLink('windowFocused') windowFocused: boolean = true;

  // 滚动器
  private scroller: Scroller = new Scroller();

  private isShowMiniMonth: boolean = DeviceConfig.instance().config.isShowMiniMonth;

  private sidebarBackgroundColor: string | Resource = DeviceConfig.instance().config.deviceLayout.sidebarBackgroundColor;

  private sidebarBackgroundColorOverlay: string | Resource = DeviceConfig.instance().config.deviceLayout.sidebarBackgroundColorOverlay;
  
  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @BuilderParam accountManagerBuilder: () => void = this.initItemFunc;

  private initAccountManageLoader: () => Promise<void> = async () => {
    Log.info(TAG, `initPermissionChangeDialogLoader start`);
    let accountManagerPage = await import('./account/AccountManage');
    this.accountManagerBuilder = accountManagerPage.pageBuilder;
    Log.info(TAG, `initPermissionChangeDialogLoader end`);
  }

  onShowLeftBarChange() {
    if (this.isShowLeftBar) {
      this.initAccountManageLoader();
    }
  }

  aboutToAppear() {
    this.onShowLeftBarChange();
  }

  aboutToDisappear(): void {
  }

  @Builder
  initItemFunc() {
  };

  @Builder
  sideBarDivider() {
    Divider()
      .vertical(true)
      .strokeWidth('1px')
      .color($r('sys.color.comp_divider'))
      .height('100%')
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
  }

  @Builder
  buildPCIcon() {
    Row() {
      Image($r('app.media.ic_privacy_icon'))
        .width(24)
        .height(24)
        .autoResize(false)
        .draggable(false)
        .interpolation(this.antialiasingNumber > 0 ? ImageInterpolation.Medium : ImageInterpolation.Low)
        .id('sd_icon')

      Text($r('app.string.calendar'))
        .margin({ start: LengthMetrics.vp(12) })
        .height(20)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .fontSize(16)
        .id('sd_title')
    }
    .position({
      start: LengthMetrics.resource($r('sys.float.padding_level12')),
      top: LengthMetrics.vp(this.buttonTopHeight + this.windowAvoidAreaTopRectHeight + 8)
    })
    .height(40)
    .justifyContent(FlexAlign.Center)
    .visibility(this.isShowLeftBar ? Visibility.Visible : Visibility.None)
    .zIndex(2)
    .opacity(this.windowFocused ? 1 : 0.4)
  }

  @Builder
  buildSidebar() {
    Column()
      .height(this.blankHeight)
      .width('100%')
      .flexShrink(0)
    Scroll(this.scroller) {
      Column() {
        if (this.isShowLeftBar) {
          //账户管理
          this.accountManagerBuilder();
          // 底部占位
          Row() {
          }
          .size({
            width: '100%',
            height: this.isShowMiniMonth ? this.windowAvoidAreaNavigationRectHeight :
              (this.windowAvoidAreaNavigationRectHeight > 0 ? 28 : 16)
          })
        }
      }.layoutWeight(1)
    }
    .align(Alignment.Top)
    .width('100%')
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Auto)
    .padding({ left: 16, right: 16, bottom: 8 })
    .flexShrink(1)
    .onScrollStart(() => {
      hiTraceMeter.finishTrace(traceEvents.accountListSwipe, 0)
    })
    .onScrollStop(() => {
      hiTraceMeter.finishTrace(traceEvents.accountListSwipe, 0)
    })
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

    //迷你月视图
    if (this.isShowMiniMonth) {
      Divider()
        .width('100%')
        .height(1)
        .color($r('sys.color.comp_divider'))
      SideBarMonthView({
        displayDate: $displayDate,
      }).flexShrink(0)
    }
  }

  build() {
    Row() {
      if (this.needCommerce) {
        this.buildPCIcon();
      }
      Flex({ justifyContent: FlexAlign.Start, direction: FlexDirection.Column }) {
        //为按钮留出的空白
        this.buildSidebar();
      }
      .height('100%')
      .backgroundColor(this.sideBarOverlay ? this.sidebarBackgroundColorOverlay :
        (this.needCommerce ? (this.windowFocused ? Color.Transparent : $r('sys.color.background_tertiary')) :
          this.sidebarBackgroundColor))
      .visibility(this.sidebarVisible ? Visibility.Visible : Visibility.None)
      .layoutWeight(1)

      if (!this.sideBarOverlay && !this.isDarkMode) {
        // 临时方案，后续等组件修改后适配
        this.sideBarDivider();
      }
    }
    .id(CompId.SIDEBAR)
    .useEffect(this.needCommerce, deviceInfo.sdkApiVersion >= 14 ? EffectType.WINDOW_EFFECT : undefined)
  }
}
