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

import { FoldScreenType, GlobalDataKeys, Log, DeviceConfig } from '@app/common';
import { WidthLimitType } from '@app/common.components';
// 控制主界面的相关布局逻辑
const TAG: string = 'MainPageLayout';

interface breakPoint {
  value: number,
  name: string,
}

@Observed
export class MainPageLayout {
  stack: boolean = false; // 侧边栏按钮，日期标题，Tab控件 是否层叠
  public dateTitleFontSize: Resource = $r('sys.float.Title_S'); // 日期标题字体大小
  public dateTitleFontPhoneSize: Resource = $r('sys.float.Title_M'); // 手机日期标题字体大小
  dateTitleOffsetX: number = 48; // 日期标题X偏移
  dateTitleOffsetY: number = 0; // 日期标题Y偏移
  tabViewOffsetY: number = 56; // Tabs主界面Y偏移
  menuBarTopMargin: number = 0; // 菜单栏Top外边距,PC预留
  menuBarHeight: number = 56; // 菜单栏统一高度
  showSideBarButton: boolean = true; // 控制按钮显隐
  widthLimitType: number = 0; // 最大宽度限制类型
  public needHideAgendaFolding: boolean = false; //开合按钮是否需要显示
}

@Observed
export class SidebarLayout {
  sideBarOverlay: boolean = false; //侧边栏是否为悬浮态
}

// 断点
// 半屏显示 961/815/700/613/554
const breakPoints: breakPoint[] = [
  { value: 0, name: 'xs' },
  { value: 360, name: 'sm' }, // 手机竖屏
  { value: 620, name: 'md' }, // 折叠屏展开 默认600扩充至620,半屏显示【大2档】613，需显示为md模式，换行展示
  { value: 840, name: 'lg' }, // 平板
  { value: 1080, name: 'xl' },
  { value: 1320, name: 'xxl' },
]


// 布局管理器，支持多个版本不同设备形态的布局
export class MainPageLayoutManager {
  private static _instance: MainPageLayoutManager = new MainPageLayoutManager()
  bp: string = '';
  layout: MainPageLayout = new MainPageLayout();
  sidebarLayout: SidebarLayout = new SidebarLayout();
  public breakPoints: breakPoint[] = breakPoints;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;
  private sideBarWidth = DeviceConfig.instance().config.deviceLayout.sidebarWidth;
  private readonly smallSideBarWidth: number = 240; // 侧边栏宽度非悬浮状态应为240，适配三折叠手机屏幕宽度很宽的情况

  constructor() {
  }

  public static getInstance(): MainPageLayoutManager {
    return MainPageLayoutManager._instance;
  }

  init(width: number, height: number) {
    const screenType: FoldScreenType | undefined = AppStorage.get<FoldScreenType>(GlobalDataKeys.FOLD_SCREEN_TYPE);
    Log.info(TAG, `width:${width} height:${height}`);
    if (!width || !height) {
      Log.info(TAG, `width or height is null`);
      return;
    }
    for (let i = 0; i < this.breakPoints.length - 1; ++i) {
      if (width >= this.breakPoints[i].value && width < this.breakPoints[i+1].value) {
        this.bp = this.breakPoints[i].name;
        break;
      }
    }
    // 判断是否为特殊适配设备,特殊适配因高度不足需要缩减tab栏高度
    this.layout.menuBarHeight = screenType === FoldScreenType.SMALL_UP_DOWN_FOLD ? 50 : 56;

    this.onBreakpointChange(this.bp);
  }

  onBreakpointChange(bp: string) {
    Log.info(TAG, `bp:${bp}`);
    this.bp = bp;
    if (this.bp === 'xs') { // 最小宽度类型设备 折叠屏 X5 外竖屏
      this.layout.stack = true;
      this.layout.needHideAgendaFolding = true;
      this.layout.widthLimitType = WidthLimitType.minWidth;
      this.sidebarLayout.sideBarOverlay = true;
    } else if (this.bp === 'sm') { // 最小宽度类型设备 手机 竖屏
      this.layout.stack = true;
      this.layout.needHideAgendaFolding = true;
      this.layout.widthLimitType = WidthLimitType.minWidth;
      this.sidebarLayout.sideBarOverlay = true;
    } else if (this.bp === 'md') { // 折叠屏展开态 PC最小窗口
      this.layout.stack = this.needCommerce;
      this.layout.needHideAgendaFolding = false;
      this.layout.widthLimitType = WidthLimitType.midWidth;
      this.sidebarLayout.sideBarOverlay = true;
    } else if (this.bp === 'lg') { // 平板 横屏
      this.layout.stack = false;
      this.layout.needHideAgendaFolding = false;
      this.layout.widthLimitType = WidthLimitType.maxWidth;
      this.sidebarLayout.sideBarOverlay = true;
    } else if (this.bp === 'xl') { // 平板 横屏 有侧边栏
      this.layout.stack = false;
      this.layout.needHideAgendaFolding = false;
      this.layout.widthLimitType = WidthLimitType.maxWidth;
      this.sidebarLayout.sideBarOverlay = false;
    } else if (this.bp === 'xxl') { //  PC 最大化
      this.layout.stack = false;
      this.layout.needHideAgendaFolding = false;
      this.layout.widthLimitType = WidthLimitType.maxWidth;
      this.sidebarLayout.sideBarOverlay = false;
    }
    this.updateDateTextProp();
    this.updateSideBarWidth();
    Log.debug(TAG, `layout` + JSON.stringify(this.layout));
    Log.debug(TAG, `sideBarLayout` + JSON.stringify(this.sidebarLayout));
  }

  updateSideBarWidth() {
    if (this.sideBarWidth === this.smallSideBarWidth) {
      // 针对默认侧边栏宽度为240的 ，使用设备默认侧边栏宽度 （pad,pc默认值为240）
      Log.info(TAG, 'updateSideBarWidth default value, not phone ');
      AppStorage.setOrCreate(GlobalDataKeys.SIDEBAR_WIDTH, this.sideBarWidth);
      return;
    }
    if (this.sidebarLayout.sideBarOverlay) {
      // 侧边栏为悬浮显示状态，使用设备默认侧边栏宽度默认
      Log.info(TAG, 'updateSideBarWidth default value, sideBarOverlay');
      AppStorage.setOrCreate(GlobalDataKeys.SIDEBAR_WIDTH, this.sideBarWidth);
      return;
    }
    Log.info(TAG, 'updateSideBarWidth smallSideBarWidth');
    // 是手机并且侧边栏不是悬浮显示状态时，侧边栏宽度设为240（三折叠）
    AppStorage.setOrCreate(GlobalDataKeys.SIDEBAR_WIDTH, this.smallSideBarWidth);
  }

  // 刷新日期标题相关属性
  updateDateTextProp() {
    if (this.layout.stack) { // 层叠, 小屏态
      this.layout.tabViewOffsetY = this.layout.menuBarHeight; // Tab下移到第二层
    } else {
      this.layout.tabViewOffsetY = 0; // 非小屏需要将tab上移至与按钮平行
    }
  }
}

// 虚拟栅格节点
@Component
export struct MainPageVirtualGrid {
  build() {
    GridRow({
      // 启用xs、sm、md、lg、xl、xxl共5个断点，断点范围数量不可超过断点可取值数量-1
      breakpoints: {
        value: breakPoints.filter(bp => bp.value > 0).map(bp => bp.value + 'vp'),
        reference: BreakpointsReference.WindowSize
      }, // 直接感知界面尺寸
      direction: GridRowDirection.Row
    })
      .width('100%')
      .onBreakpointChange((breakpoint) => MainPageLayoutManager.getInstance().onBreakpointChange(breakpoint))
  }
}