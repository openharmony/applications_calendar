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

import emitter from '@ohos.events.emitter';
import {
  BigFontSize,
  CalendarUtils,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  FoldScreenType,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  Log,
  ReportHiEventParams,
  ReportUtil,
  statisticEvents,
  ThrottleFunction
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { barText } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { i18n } from '@kit.LocalizationKit';

// 自定义滑动组件  后续随PC整体删除 换用组件@ohos.arkui.advanced.SegmentButton
const TAG = 'SlideTabBar'

export enum WidthLimitType {
  minWidth = 0, // 宽度小于384
  midWidth = 1, // 384-840之间
  maxWidth = 2, // 宽度840-最大
}

enum SpecialMdWidth {
  // 特殊处理智慧多窗下MD级别屏幕宽度自由变化场景宽度断点
  Level1Width = 635, // 宽度为620-635
  Level2Width = 660, // 宽度为635-660
}

enum SpecialMdTabBarWidth {
  // 特殊处理智慧多窗下MD级别屏幕宽度自由变化场景宽度断点
  Level1Width = 215, // 宽度为620-635 tabBar最大宽度
  Level2Width = 230, // 宽度为635-660 tabBar最大宽度
}

declare type ItemRestriction<T> = [T, T, T?, T?, T?];

interface SegmentButtonTextItem {
  text: ResourceStr;
}

interface barTextIndexItem {
  barText: Resource;
  id: string;
}

@Preview
@Component
export struct SlideTabBar {
  @StorageLink('tabIndex') @Watch('onTabIndexChange') tabsIndex: number = 1;

  @LocalStorageProp('windowHeight') @Watch('onWindowHeightChange') windowHeight: number = 0;

  @Prop tabBarHeight: number;

  @Consume sideBarOverlay: boolean;

  @Consume isMaximizeRecovery: boolean;

  @Watch('onWidthLimitTypeChange') @Prop widthLimitType: number = 0;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  @State innerWidth: number = 360; // tab栏初始化宽度

  @State maxTabBarWidth: number = this.innerWidth;

  @State isAnimate: boolean = false;

  @State @Watch('onSegmentTabsIndexChange') segmentTabsIndex: number[] = [this.tabsIndex];

  @StorageLink('windowFocused') windowFocused: boolean = true;

  @StorageLink(GlobalDataKeys.FOLD_SCREEN_TYPE) screenType: string = FoldScreenType.UNKNOWN;

  @State showSlideTab: boolean = true;

  tabText: ItemRestriction<SegmentButtonTextItem> = [
    { text: $r('app.string.year'), },
    { text: $r('app.string.month') },
    { text: $r('app.string.week_view') },
    { text: $r('app.string.day_view') }]

  @StorageProp('fontSizeScale') fontSizeScale: number =
    BigFontSize.BIG_FONT_SIZE_STANDARD;

  private readonly SLIDE_TAB_MARGIN: number = 16; //tab栏外边距16

  private readonly hideTabHeight = 300; // 需要隐藏tab栏的窗口高度,分屏适配

  private readonly hideTabHeightFold = 350; // 需要隐藏tab栏的窗口高度,小折叠单独分屏适配

  // 调整 TAB栏 宽度的内边距
  private readonly defRightPadding = 305; // TAB栏 右侧内边距

  private readonly sideBarOverlayLeftPadding = 188; // TAB栏 左侧内边距（sideBarOverlay 打开）

  private readonly defLeftPadding = 142; // TAB栏 左侧内边距（sideBarOverlay 关闭）

  private readonly titleWidthPhone = 208; //手机左上角的标题宽度

  private readonly buttonWidthPhone = 212; //手机右上角按钮的宽度(4个按钮加边距)

  private indexNum: number = 4; // 标签页数量

  private indexPer: number = 100 / this.indexNum; //标签页所占比例

  @State buttonPosX: number = this.tabsIndex * this.indexPer / 100;

  private backgroundMargin: number = 8; // 背景板的外边距

  // 按钮上下外边距
  private buttonMarginHeight: number = 2;

  // 按钮左右外边距
  private buttonMarginWidth: number = 2;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 用于平板宽高达到指定比例时转换为上下布局
  private needCheckRatio: boolean = DeviceConfig.instance().config.needCheckRatio;

  // tab 栏是否换行
  @Prop stack: boolean = false;

  private backgroundHeight: number = this.tabBarHeight - this.backgroundMargin * 2;

  @State buttonHeight: number = this.backgroundHeight - this.buttonMarginHeight * 2;

  private barTextIndexMap: barTextIndexItem[] = [
    { barText: $r('app.string.year'), id: CompId.TABS_YEAR },
    { barText: $r('app.string.month'), id: CompId.TABS_MONTH },
    { barText: $r('app.string.week_view'), id: CompId.TABS_WEEK },
    { barText: $r('app.string.day_view'), id: CompId.TABS_DAY }];

  @State buttonText: Resource = this.barTextIndexMap[this.tabsIndex]?.barText;

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  onWindowWidthChange() {
    Log.info(TAG, `onWindowWidthChange: ${this.windowWidth}-${this.stack}`)
    if (this.widthLimitType !== WidthLimitType.midWidth) {
      return;
    }
    // 适配自由多窗情况下尺寸为md 但是屏幕宽度不足导致按钮挤压的情况
    Log.info(TAG, `onWindowWidthChange to onWidthLimitTypeChange`);
    this.onWidthLimitTypeChange();
  }

  onWindowHeightChange() {
    const hideHeight =
      this.screenType === FoldScreenType.SMALL_UP_DOWN_FOLD ? this.hideTabHeightFold : this.hideTabHeight;
    this.showSlideTab = this.windowHeight > hideHeight;
  }

  aboutToAppear() {
    this.onWidthLimitTypeChange();
    this.onWindowHeightChange();
    emitter.on({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, this.eventSwitchTabHandler);
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SWITCH_MAIN_PAGE_TAB, this.eventSwitchTabHandler);
  }

  private eventSwitchTabHandler = (eventData: emitter.EventData) => {
    if (eventData.data?.tabIndex !== undefined) {
      const tabIndex: number = eventData.data.tabIndex as number;
      if (tabIndex !== this.tabsIndex) {
        this.tabsIndex = tabIndex;
        return;
      }
      // 全局 tabIndex 已先更新时，仍需同步 subtab 的派生选中态和滑块位置。
      this.onTabIndexChange();
    }
  };

  onWidthLimitTypeChange() {
    this.maxTabBarWidth = this.widthForWidthInner(this.widthLimitType);
    Log.info(TAG, `maxTabBarWidth: ${this.maxTabBarWidth}`)
  }

  widthForWidthInner(widthLimitType: number): number {
    if (widthLimitType === WidthLimitType.midWidth) {
      if (this.windowWidth < SpecialMdWidth.Level1Width) {
        Log.info(TAG, `widthForWidthInner windowWidth : ${this.windowWidth} return Level1Width`);
        // 自由多窗特殊场景下，宽度不够导致按钮挤压特殊处理
        return SpecialMdTabBarWidth.Level1Width;
      }

      if (this.windowWidth < SpecialMdWidth.Level2Width) {
        Log.info(TAG, `widthForWidthInner windowWidth : ${this.windowWidth} return Level2Width`);
        // 自由多窗特殊场景下，宽度不够导致按钮挤压特殊处理
        return SpecialMdTabBarWidth.Level2Width;
      }

      return 255; // 宽度为384-840时tabBars限制最大宽度
    } else if (widthLimitType === WidthLimitType.maxWidth) {
      return 285; // 宽度为宽度为840-最大时tabBars限制最大宽度
    } else {
      return 360; // default
    }
  }

  onChangeFontSize(num: number) {
    return FontSizeScaleUtils.getLimitHeightNum(
      this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SIX,
      num);
  }

  @Builder
  slideTabBarOriButton() {
    Row() {
      this.buildButton()
      ForEach(this.barTextIndexMap, (item: barTextIndexItem, index: number) => {
        this.buildBarText(item, index)
      }, (item: barTextIndexItem, index: number) => {
        return item.id;
      })
    }
    .margin({
      top: this.backgroundMargin,
      bottom: this.backgroundMargin
    })
    .padding({ start: LengthMetrics.vp(this.buttonMarginWidth), end: LengthMetrics.vp(this.buttonMarginWidth) })
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .justifyContent(FlexAlign.SpaceAround)
    .constraintSize({ maxWidth: this.stack ? '100%' : this.maxTabBarWidth })
    .width(`100%`)
    .height(this.backgroundHeight)
    .borderRadius(this.tabBarHeight / 2)
  }

  @Builder
  buildBarText(item: barTextIndexItem, targetIndex: number) {
    Text(item.barText)
      .size({ height: this.buttonHeight, width: this.indexPer + '%' })
      .textAlign(TextAlign.Center)
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_TWO)
      .maxFontSize($r('sys.float.Body_M'))
      .minFontSize('6vp')
      .maxLines(1)
      .fontColor(this.tabsIndex === targetIndex ? $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
      .fontWeight(FontWeight.Medium)
      .id(item.id)
      .nextFocus({
        left: i18n.isRTL(i18n.getSystemLocale()) ?
          this.barTextIndexMap[Math.min(Number(targetIndex) + 1, this.indexNum - 1)].id :
          this.barTextIndexMap[Math.max(Number(targetIndex) - 1, 0)].id,
        right: i18n.isRTL(i18n.getSystemLocale()) ?
          this.barTextIndexMap[Math.max(Number(targetIndex) - 1, 0)].id :
          this.barTextIndexMap[Math.min(Number(targetIndex) + 1, this.indexNum - 1)].id
      })
      .onClick(event => {
        this.onButtonClick(targetIndex);
      })
      .focusBox({ margin: LengthMetrics.vp(-2) })
      .focusable(true)
      .focusOnTouch(true)
      .borderRadius(this.tabBarHeight / 2)
      .hoverEffect(this.tabsIndex === targetIndex ? HoverEffect.None : HoverEffect.Highlight)
      .accessibilityText(barText(item.barText))
      .accessibilityRole(5)
      .accessibilityChecked(this.tabsIndex === targetIndex ? true : false)
      .accessibilityDescription(this.tabsIndex === targetIndex ? ' ' : '')
  }

  @Builder
  buildButton() {
    Button()
      .type(ButtonType.Normal)
      .opacity(1)
      .backgroundColor($r('app.color.slide_tab_bar_button_color'))
      .width(this.indexPer + '%')
      .borderRadius(this.buttonHeight / 2)
      .height(this.buttonHeight)
      .position({ start: LengthMetrics.percent(this.buttonPosX), top: LengthMetrics.vp(this.buttonMarginHeight) })
      .shadow({
        radius: 8,
        offsetY: 4,
        color: '#19000000'
      })
      .focusable(false)
      .id('slide-button')
  }

  build() {
    Column() {
      this.slideTabBarOriButton()
    }
    .margin({ bottom: this.onChangeFontSize(4) })
    .renderGroup(!this.isAnimate && !this.isMaximizeRecovery)
    .height(this.tabBarHeight)
    .padding({
      start: LengthMetrics.vp(this.getPadding(this.stack, true)),
      end: LengthMetrics.vp(this.getPadding(this.stack, false)),
      top: LengthMetrics.vp(this.buttonTopHeight)
    })
    .width(`100%`)
    .alignItems(HorizontalAlign.Center)
    .id(CompId.SLIDE_TAB_BAR)
    .visibility(this.showSlideTab ? Visibility.Visible : Visibility.None)
    .opacity(!this.windowFocused && this.needCommerce ? 0.4 : 1)
  }

  /**
   * 用于规避日历tab栏左右控件的边距计算
   * @param isStack 上层监听更新,当前tab是否处于第二行
   * @param isLeft 是否为左边距计算
   * @returns
   */
  getPadding(isStack: boolean, isLeft: boolean): number {
    if (isStack) { // 当前处于第二行,无需规避
      return this.SLIDE_TAB_MARGIN;
    }
    if (!this.needCommerce && this.needCheckRatio) { // 当前只有平板需要添加170边距
      return 170;
    }
    if (!this.needCommerce) { // 非PC且未满足needCheckRatio则不需要边距
      return isLeft ? this.titleWidthPhone : this.buttonWidthPhone;
    }
    if (isLeft) { // PC左右边距不一致
      return this.sideBarOverlay ? this.sideBarOverlayLeftPadding : this.defLeftPadding;
    } else {
      return this.titleButtonWidth + this.defRightPadding;
    }
  }

  onButtonClick(targetIndex: number) {
    // 检查当前index
    Log.info(TAG, 'tabsIndex:' + this.tabsIndex + ' targetIndex:' + targetIndex);

    // 当前tab栏单击触发回到今天
    if (this.tabsIndex === targetIndex) {
      this.onBackToToday();
    }
    const oldTabIndex = this.tabsIndex;
    this.tabsIndex = targetIndex;
    let eventData: emitter.EventData = {
      data: {
        'tabIndex': targetIndex,
        'oldTabIndex': oldTabIndex,
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB }, eventData);
  }

  // 年视图点击月份等场景，需要联动进行滑动
  onTabIndexChange() {
    Log.info(TAG, 'onTabIndexChange:' + this.tabsIndex);
    if (this.segmentTabsIndex[0] !== this.tabsIndex) {
      this.segmentTabsIndex[0] = this.tabsIndex;
    }
    this.changeButtonPoxByIndex(this.tabsIndex)
  }

  changeButtonPoxByIndex(targetIndex: number) {
    Log.info(TAG, 'changeButtonPoxByIndex:' + targetIndex);
    this.isAnimate = true;
    animateToImmediately({
      duration: 300,
      onFinish: () => {
        this.isAnimate = false;
      }
    }, () => {
      let newButtonPosX: number = targetIndex * this.indexPer / 100;
      Log.debug(TAG, 'buttonPosX from : ' + this.buttonPosX + ' to:' + newButtonPosX);
      this.buttonPosX = newButtonPosX;
    });
  }

  onSegmentTabsIndexChange() {
    Log.info(TAG, 'onSegmentTabsIndexChange:' + this.segmentTabsIndex);
    if (this.segmentTabsIndex[0] !== this.tabsIndex) {
      this.onButtonClick(this.segmentTabsIndex[0]);
    }
  }

  // 重复点击回到今天事件
  private onBackToToday: () => void = () => {
    // 同一天不触发回到今天
    if (CalendarUtils.isSameDay(Date.now(), GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number)) {
      return;
    }

    // 1. 修改全局 DisplayDay
    GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
    // 2. 触发事件,通知各个模块响应 回到今天
    emitter.emit({ eventId: CommonInnerEvent.BACK_TO_TODAY });
    // 3. 打点操作
    let params: ReportHiEventParams = {
      SOURCE_PAGE: this.tabsIndex
    }
    ReportUtil.reportStatisticEvent(statisticEvents.backToToday, params);
  };
}