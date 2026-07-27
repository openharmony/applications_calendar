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
  CityTimeZone,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MIN_WINDOW_WIDTH_VP,
  NavPageBuilderFactory,
  NavPathManager,
  NavPathName,
  RouterName,
  ThrottleFunction,
  ViewProxy
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { TimeZoneListItem } from './TimeZoneListItem';
import { TimeZoneViewModel } from './TimeZoneViewModel';
import { EmptyContent } from '@app/common.components';

const TAG: string = 'TimeZonePage';
// 滚动条右侧偏移量
const SCROLL_BAR_OFFSET = 16;

interface TimeZonePageParam {
  isInPop: boolean;
  isFormAgenda: boolean;
}


@Builder
function harBuilder(value: object) {
  TimeZonePage();
}

const builderName = NavPathName.SETTINGS_TIME_ZONE;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct TimeZonePage {
  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageLink('language') @Watch('onLanguageChange') language: string = '';

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  @State viewModel: TimeZoneViewModel = new TimeZoneViewModel();

  @State searchText: string = '';

  @State submitValue: string = '';

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private isInPop: boolean = false;

  private scroller: Scroller = new Scroller();

  // 搜索控制器
  private controller: SearchController = new SearchController();

  private searchPlaceholder: Resource = $r('app.string.searching_for_time_zones');

  private fromAgenda: boolean = false;

  aboutToAppear(): void {
    Log.info(TAG, `TimeZonePage aboutToAppear`);
    // 区分设置和新建日程入口
    let params = NavPathManager.getInstance().getParamByName<TimeZonePageParam>(NavPathName.SETTINGS_TIME_ZONE,
      RouterName.SETTING_HAP);
    if (!params.length) {
      params = NavPathManager.getInstance().getParamByName<TimeZonePageParam>(NavPathName.SETTINGS_TIME_ZONE,
        RouterName.CREATE_AGENDA_MAIN);
    }
    if (!params[0]) {
      return;
    }
    this.fromAgenda = params[0].isFormAgenda;
    this.isInPop = params[0].isInPop;
    this.viewModel.init();
  }

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  onBackPress(): boolean {
    Log.debug(TAG, 'onBackPress Callback in Creat Account View.');
    this.viewProxy.onBackPressed();
    if (this.viewModel.isShowSearch) {
      this.searchText = '';
      this.viewModel.changeShowSearch();
      return true;
    }
    return false;
  }

  async onTimeZoneSelect(cityItem: CityTimeZone): Promise<void> {
    let isConfirm = await this.viewModel.timeZoneChange(cityItem, this.fromAgenda);
    if (isConfirm) {
      if (this.fromAgenda) {
        NavPathManager.getInstance().popRouter(RouterName.CREATE_AGENDA_MAIN);
      } else {
        NavPathManager.getInstance().popRouter(RouterName.SETTING_HAP);
      }
    }
  }

  onLanguageChange() {
    this.viewModel.onLanguageChange(this.language);
  }

  @Builder
  buildCustomTitle() {
    if (this.viewModel.isShowSearch) {
      this.buildSearch();
    } else {
      Text($r('app.string.edit_event_timezone_label'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE,
          20
        ))
        .minFontSize(10)
        .fontWeight(FontWeight.Bold)
        .padding({ start: LengthMetrics.vp(8), top: LengthMetrics.vp(16) })
    }
  }

  @Builder
  buildContent() {
    Column() {
      if (!this.viewModel.isShowSearch) {
        this.buildSearch();
      }
      if (this.viewModel.isShowSearchResult) {
        this.buildSearchResult()
      }

      if (this.viewModel.isShowSearchResult && this.viewModel.searchResultCount === 0) {
        EmptyContent({
          isFromAgenda: this.fromAgenda
        });
      } else {
        this.buildList();
      }
    }
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      start: LengthMetrics.vp(16)
    })
  }

  @Builder
  buildSearch() {
    Column() {
      Search({ value: this.searchText, placeholder: this.searchPlaceholder, controller: this.controller })
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .placeholderColor($r('sys.color.font_secondary'))
        .selectedBackgroundColor(this.themeColor)
        .textFont({ size: $r('sys.float.Body_L') })
        .placeholderFont({
          size: FontSizeScaleUtils.getLimitFontSizeVp(
            GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE,
            16)
        , family: 'serif', style: FontStyle.Normal
        })
        .caretStyle({
          color: this.themeColor
        })
        .maxFontSize(16)
        .minFontSize('16vp')
        .enableKeyboardOnFocus(true)
        .onClick(() => {
          if (this.viewModel.isShowSearch) {
            return;
          }
          this.viewModel.changeShowSearch();
        })
        .onChange(async (value: string) => {
          this.searchText = value;
          ThrottleFunction.instance().debounce(TAG, () => {
            this.viewModel.searchChange(value);
          }, 300)
          Log.info(TAG, 'Search onChange value = ' + value);
        })
    }
    .padding(this.viewModel.isShowSearch ? (this.needCommerce ?
      { start: LengthMetrics.vp(8), end: LengthMetrics.vp(24) } :
      { start: LengthMetrics.vp(8), end: LengthMetrics.vp(8) }) : 0)
    .margin(!this.viewModel.isShowSearch ? {
      top: $r('sys.float.padding_level6'),
      bottom: $r('sys.float.padding_level6'),
      end: LengthMetrics.vp(16)
    } : 0)
  }

  @Builder
  buildSearchResult() {
    Text($r('app.plural.search_results_num', this.viewModel.searchResultCount, this.viewModel.searchResultCount))
      .fontColor($r('sys.color.font_secondary'))
      .width('100%')
      .textAlign(TextAlign.Start)
      .padding({
        start: LengthMetrics.vp(12),
        end: LengthMetrics.vp(8)
      })
      .margin({ top: $r('sys.float.padding_level12'), bottom: $r('sys.float.padding_level2') })
  }

  @Builder
  buildList() {
    Row() {
      List({ scroller: this.scroller }) {
        ListItemGroup() {
          LazyForEach(this.viewModel.dataSource, (item: CityTimeZone, index: number) => {
            ListItem() {
              TimeZoneListItem({
                cityName: item.cityDisplayName,
                timeZoneOffset: item.offset,
                searchText: this.searchText
              })
            }
            .onClick(() => {
              this.onTimeZoneSelect(item);
            })
            .flexShrink(1)
            .constraintSize({ minHeight: 64 })
            .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level6'))
            .hoverEffect(HoverEffect.Highlight)
            .stateStyles({
              pressed: {
                .backgroundColor($r('sys.color.interactive_click'));
              },
              normal: {
                .backgroundColor(Color.Transparent);
              }
            })

          }, (item: CityTimeZone, index: number) => this.viewModel.getTimeZoneListKey(item, index, this.searchText))
        }
        .padding({
          top: $r('sys.float.padding_level2'),
          bottom: $r('sys.float.padding_level2'),
          left: $r('sys.float.padding_level2'),
          right: $r('sys.float.padding_level2')
        })
        .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level6'))
        .divider({
          strokeWidth: 0.5,
          color: $r('sys.color.comp_divider'),
          startMargin: $r('sys.float.padding_level4'),
          endMargin: $r('sys.float.padding_level4')
        })
        .backgroundColor($r('sys.color.comp_background_list_card'))
      }
      .scrollBar(BarState.Off)
      .cachedCount(10)
      .margin({
        top: this.viewModel.isShowSearch && !this.viewModel.isShowSearchResult ? $r('sys.float.padding_level8') : 0
      })
      .width(`calc(100% - ${SCROLL_BAR_OFFSET}vp)`)
      .margin({
        top: $r('sys.float.padding_level2'),
        bottom: $r('sys.float.padding_level2'),
      })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))

      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .width(SCROLL_BAR_OFFSET)
    }
    .layoutWeight(1)
    .alignItems(VerticalAlign.Top)
  }

  build() {
    NavDestination() {
      this.buildContent()
    }
    .padding({
      top: this.isInPop ? 0 : $r('sys.float.padding_level4'),
      bottom: this.inSmallWindow ? this.windowAvoidAreaNavigationRectHeight : 0
    })
    .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') : $r('app.color.color_privacy_background'))
    .hideTitleBar(false)
    .title(this.buildCustomTitle)
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .onBackPressed(() => {
      return this.onBackPress();
    })
  }
}