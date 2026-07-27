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
  CompId,
  DeviceConfig,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ReportHiEventParams,
  ReportUtil,
  SafeUtil,
  statisticEvents,
  ThrottleFunction
} from '@app/common';
import { addSelectStatusAndButton, broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'TabController';

interface barTextIndexItem {
  barText: Resource;
  id: string;
}

const TAB_NUM: number = 2; // 标签页数量
const TAB_PER: number = 100 / TAB_NUM; //标签页所占比例
const MAX_WIDTH: number = 420; // 420 能保证直板和折叠屏折叠态都与下面对齐，小了会导致直板机被压缩
const PADDING: number = 16; // 容器组件内边距,保证与下面ListItem对齐

@Component
export struct TabController {
  // 当前日程
  @Consume currentIndex: number;

  @State tabBarHeight: number = 56;

  private barTextIndexMap: barTextIndexItem[] = [
    { barText: $r('app.string.schedule_view'), id: CompId.TABS_SCHEDULE },
    { barText: $r('app.string.create_important_day'), id: CompId.TABS_IMPORTANT_EVENT }
  ];

  @State isAnimate: boolean = false;

  @State maxTabBarWidth: number = 326; // tab栏初始化宽度

  // 按钮上下外边距
  private buttonMarginHeight: number = 2;

  // 按钮左右外边距
  private buttonMarginWidth: number = 2;

  private backgroundMargin: number = 8; // 背景板的外边距

  @State buttonWidth: number = (this.maxTabBarWidth / TAB_NUM) - (this.buttonMarginWidth * 2);

  @State buttonMoveDis: number = (this.maxTabBarWidth - this.buttonMarginWidth * 2 - this.buttonWidth) / (TAB_NUM - 1);

  private backgroundHeight: number = this.tabBarHeight - this.backgroundMargin * 2;

  @State buttonHeight: number = this.backgroundHeight - this.buttonMarginHeight * 2;

  @State buttonPosX: number = this.currentIndex * TAB_PER;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onTabChange: (type: number) => void = (type: number): void => {
  };

  onSegmentTabsIndexChange(targetIndex: number) {
    ThrottleFunction.instance().debounceInstant(TAG, () => {
      Log.info(TAG, `Agenda Tab Change ${this.currentIndex} to ${targetIndex}`);
      this.currentIndex = targetIndex;
      this.changeButtonPoxByIndex(targetIndex);
      let params: ReportHiEventParams = {
        TARGET_PAGE: this.currentIndex
      };
      ReportUtil.reportStatisticEvent(statisticEvents.agendaSwitchTab, params);
      broadcastSelectStatus(true);
      SafeUtil.setTimeout(() => {
        // 在tabController响应状态变量变化时,如果触发tabChange并修改标题栏其他组件的状态变化,会导致此变化失效
        this.onTabChange(targetIndex);
      }, 30);
    }, 100);
  }

  build() {
    Column() {
      Row() {
        this.buildButton()
        ForEach(this.barTextIndexMap, (item: barTextIndexItem, index: number) => {
          this.buildBarText(item, index)
        })
      }
      .padding({ left: this.buttonMarginWidth, right: this.buttonMarginWidth })
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .justifyContent(FlexAlign.SpaceAround)
      .height(this.backgroundHeight)
      .borderRadius(this.tabBarHeight / 2)
    }
    .id(CompId.TAB_CONTROLLER)
    .renderGroup(!this.isAnimate)
    .constraintSize({
      maxWidth: MAX_WIDTH,
      minHeight: this.backgroundHeight, maxHeight: 56
    }) // 触发限制后，里面使用百分比的组件不会刷新!
    .width('100%')
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => this.handleAreaChange(ov, nv))
    .padding({
      left: PADDING,
      right: PADDING,
      top: 8,
      bottom: 8
    })
  }

  @Builder
  buildButton() {
    Button()
      .type(ButtonType.Normal)
      .backgroundColor(this.isDarkMode && this.needCommerce ? $r('sys.color.comp_background_list_card') :
      $r('app.color.slide_tab_bar_button_color'))
      .width(this.buttonWidth)
      .borderRadius(this.buttonHeight / 2)
      .height(this.buttonHeight)
      .position({ start: LengthMetrics.vp(this.buttonPosX), top: LengthMetrics.vp(this.buttonMarginHeight) })
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .focusable(false)
  }

  @Builder
  buildBarText(item: barTextIndexItem, targetIndex: number) {
    Text(item.barText)
      .size({ height: this.buttonHeight })// width: TAB_PER + '%'
      .width(this.buttonWidth)
      .textAlign(TextAlign.Center)
      .fontSize('14vp')
      .fontColor(this.currentIndex === targetIndex ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
      .fontWeight(FontWeight.Medium)
      .id(item.id)
      .onClick(event => this.onSegmentTabsIndexChange(targetIndex))
      .borderRadius(this.tabBarHeight / 2)
      .hoverEffect(this.currentIndex === targetIndex ? HoverEffect.None : HoverEffect.Highlight)
      .accessibilityText(item.barText)
      .accessibilityDescription(this.currentIndex === targetIndex ? ' ' :
        GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
      .accessibilitySelected(this.currentIndex === targetIndex)
      .accessibilityRole(5)
  }

  handleAreaChange(ov: SizeOptions, nv: SizeOptions) {
    if (ov.width === nv.width && ov.height === nv.height) {
      return;
    }
    const newWidth = nv.width as number;
    Log.log(TAG, `handleAreaChange width: ${newWidth}`);
    const rowWidth = newWidth - PADDING * 2;
    // 计算button宽度
    this.buttonWidth = Math.round((rowWidth - this.buttonMarginWidth * 2) / TAB_NUM);
    // 计算每次移动距离
    this.buttonMoveDis = Math.round((rowWidth - this.buttonMarginWidth * 2 - this.buttonWidth) / (TAB_NUM - 1));
    // 计算当前按钮坐标点
    this.buttonPosX = this.currentIndex * this.buttonMoveDis;
    Log.debug(TAG, `btnWidth:${this.buttonWidth} btnMoveDis:${this.buttonMoveDis} buttonPosX:${this.buttonPosX}`);
  }

  changeButtonPoxByIndex(targetIndex: number) {
    Log.info(TAG, 'changeButtonPoxByIndex:' + targetIndex);
    this.isAnimate = true;
    animateTo({
      duration: 300,
      onFinish: () => {
        this.isAnimate = false;
      }
    }, () => {
      let newButtonPosX: Length = targetIndex * this.buttonMoveDis;
      Log.debug(TAG, 'buttonPosX from : ' + this.buttonPosX + ' to:' + newButtonPosX);
      this.buttonPosX = newButtonPosX;
    });
  }
}