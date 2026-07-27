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
export class SideBarMonthViewLayout {
  private static _instance: SideBarMonthViewLayout = new SideBarMonthViewLayout()
  public dayFontSize: number = 12; // 星期日期,天
  public selectCircle: number = 24; // 选中圆形半径
  public monthWidthMargin: number = 8; // 月视图左右边距
  public monthTopMargin: number = 6; // 月视图上边距
  public monthBottomMargin: number = 8; // 月视图下边距
  public yearLegendTopMargin: number = 12;
  public monthPaddingTop: number = 6; //月视图距离标题的间隔

  public sidebarMonthHeight: number = 220; // 侧边栏日历高度
  public sidebarDateSwitchHeight: number = 20; // 月视图月份切换组件高度

  public static getInstance(): SideBarMonthViewLayout {
    return SideBarMonthViewLayout._instance;
  }
}