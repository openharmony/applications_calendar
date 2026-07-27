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
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DateTitleUtil,
  DeviceConfig,
  GlobalDataKeys,
  MIN_WINDOW_SPLIT_SCREEN_WIDTH_VP,
  TabType,
  UnusualMode
} from '@app/common';
import emitter from '@ohos.events.emitter';
import { LengthMetrics } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';

/**
 * 主界面日期标题组件
 */
@Component
export struct DateTitle {
  // 主界面tabIndex
  @Prop tabsIndex: TabType = TabType.MONTH;

  // 距离顶部的额外高度
  @Prop marginTop: Length;

  // 额外下边距
  @Prop marginBottom: Length;

  // 文字高度
  @Prop textHeight: Length;

  // 是否需要对边距进行限制
  @Prop needPadding: boolean;

  // 是否需要隐藏菜单栏
  @Prop hideMenu: boolean = false;

  // 文字高度
  private textWidth: Length = 'calc(100% - 208vp)'; // 48偏移加上48的按钮*3加上16的边距

  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayDate: number = 0;

  // 系统语言
  @StorageLink('language') language: string = '';

  // 字体大小缩放
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('windowFocused') windowFocused: boolean = true;

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  //日期文本
  @State dateTitleText: ResourceStr = '';

  // 是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private shouldShowSmallerFontSize(): boolean {
    if (this.needCommerce) {
      return true;
    }
    if (!AppStorage.get(GlobalDataKeys.UNUSUAL_MODE)) {
      return false;
    }
    if (AppStorage.get(GlobalDataKeys.UNUSUAL_MODE) === UnusualMode.SMALL_UP_DOWN_FOLD) {
      return true;
    }
    return false;
  }

  getFontSize(): Length {
    if (this.language === 'zh-Hans-CN' || this.language === 'zh-Hans') {
      // PC 适老化分屏场景
      if (this.windowWidth < MIN_WINDOW_SPLIT_SCREEN_WIDTH_VP && this.needPadding) {
        return '16vp';
      }
      return '20vp';
    }
    return '16vp';
  }

  getWidth(): Length | undefined {
    //特殊情况： PC 分屏-显示大小最大档，配合换行
    if (this.needCommerce && this.windowWidth < MIN_WINDOW_SPLIT_SCREEN_WIDTH_VP) {
      return 60;
    }
    // 其他都是正常情况，width 使用maxWidth自适应代替
    // 层叠布局，返回文本宽度
    if (this.needPadding) {
      return this.textWidth;
    }
    // 默认返回 undefined
    return undefined;
  }

  aboutToAppear() {
    this.updateDisplayText(this.tabsIndex);
    emitter.on({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, this.eventSwitchTabHandler);
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SWITCH_MAIN_PAGE_TAB, this.eventSwitchTabHandler);
  }

  private eventSwitchTabHandler = (eventData: emitter.EventData) => {
    if (eventData.data?.tabIndex !== undefined) {
      const tabIndex: number = eventData.data.tabIndex as number;
      this.updateDisplayText(tabIndex);
    }
  };

  onDisplayDateChange() {
    this.updateDisplayText(this.tabsIndex);
  }

  updateDisplayText(tabIndex: number) {
    this.dateTitleText = DateTitleUtil.formatTitle(this.displayDate, tabIndex, this.language);
  }

  build() {
    Text(this.dateTitleText)
      .maxFontSize(this.shouldShowSmallerFontSize() ? this.getFontSize() : '24vp')
      .minFontSize('12vp')
      .fontColor($r('sys.color.font_primary'))
      .fontWeight(FontWeight.Bold)
      .id(CompId.MAIN_PAGE_DATE_INFO)
      .padding({
        start: LengthMetrics.resource($r('sys.float.padding_level8'))
      })
      .height(this.textHeight)
      .maxLines(this.needCommerce && this.windowWidth < MIN_WINDOW_SPLIT_SCREEN_WIDTH_VP && this.needPadding ? 2 : 1)
      .constraintSize({
        maxWidth: this.getWidth()
      })
      .align(Alignment.Center)
      .margin({ bottom: this.marginBottom, top: this.marginTop })
      .zIndex(3)
      .focusable(true)
      .defaultFocus(true)
      .onAppear(() => {
        //初始化尝试默认聚焦在标题上
        focusControl.requestFocus(CompId.MAIN_PAGE_DATE_INFO);
      })
      .focusBox({ margin: LengthMetrics.vp(-2) })
      .opacity(!this.windowFocused && this.needCommerce ? 0.4 : 1)
      .visibility(this.hideMenu ? Visibility.None : Visibility.Visible)
      .onKeyEvent((event) => {
        if (event.keyCode === KeyCode.KEYCODE_DPAD_UP || event.keyCode === KeyCode.KEYCODE_DPAD_DOWN ||
          event.keyCode === KeyCode.KEYCODE_DPAD_LEFT || event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
          event.stopPropagation()
        }
      })
  }
}