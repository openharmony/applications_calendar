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
  AttendeeService,
  BigFontSize,
  CalendarContract,
  CommonInnerEvent,
  DataSourceTemplate,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalThis,
  NavPageBuilderFactory,
  NavPathManager,
  RouterName,
  ViewProxy
} from '@app/common';

import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';

type Attendee = CalendarContract.Attendees;

const TAG: string = 'AttendeeList';

@Builder
function harBuilder(value: object) {
  AttendeeList();
}

const builderName = NavPathName.ATTENDEE_LIST;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

class AttendeeListDataSource extends DataSourceTemplate<Attendee> {
}

@Component
export struct AttendeeList {
  @Consume navPathStack: NavPathStack;

  list: Attendee[] = [];

  eventId: number = -1;

  dataSource: AttendeeListDataSource = new AttendeeListDataSource(this.list);

  //image fillColor
  @State imgFillColor: string = '#000000';

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private mScroller = new Scroller();

  private modifier: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.chevron_backward'));

  @StorageLink('windowFocused') windowFocused: boolean = true;

  @Builder
  buildNavigationRow() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
      }
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
      .focusable(true)
      .backgroundColor(this.buttonBackgroundColor)
      .width(40)
      .height(40)
      .onClick(() => {
        this.navPathStack.pop();
      })
      .focusable(true)
      .height(56)
      .margin({ right: 8 })

      Text($r('app.string.online_meeting_participant_title'))
        .fontColor($r('sys.color.font_primary'))
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16 })
  }

  @Builder
  buildItem(name: string, email: string) {
    Row() {
      SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
        .fontSize('48vp')
        .margin({ right: 16 })
        .fontColor([$r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_fourth'))
      Column() {
        Text(name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(email)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 14, bottom: 14 })
      .layoutWeight(1)
    }
  }

  @Builder
  buildList() {
    Column() {
      Text($r('app.string.online_meeting_participant'))
        .fontSize(14)
        .padding({ left: 12, top: 12 })
        .width('100%')
        .fontColor($r('sys.color.font_primary'))
        .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
        ))

      List() {
        LazyForEach(this.dataSource, (item: Attendee) => {
          this.buildItem(item.attendeeName, item.attendeeEmail)
        }, (item: Attendee, index: number) => {
          return `${Date.now()}-${index}`;
        })
      }
      .divider({ strokeWidth: '1px', startMargin: 60, color: $r('sys.color.comp_divider') })
      .borderRadius(16)
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
    }
    .layoutWeight(1)
    .margin({ bottom: 68 })
  }

  // 帐户管理界面标题栏
  @Builder
  AttendeeTitle() {
    Row() {
      Text($r('app.string.online_meeting_participant_title'))
        .constraintSize({ minHeight: 48 })
        .fontWeight(FontWeight.Bold)
        .maxFontSize($r('sys.float.Title_S'))
        .minFontSize('6vp')
        .maxLines(1)
    }
    .padding({ start: LengthMetrics.vp(8) })
    .height('100%')
    .layoutWeight(1)
    .alignSelf(ItemAlign.Center)
    .opacity(this.windowFocused ? 1 : 0.4)
  }

  aboutToAppear() {
    const paramsArray = NavPathManager.getInstance().getParamByName<Param>(NavPathName.ATTENDEE_LIST,
      RouterName.ENTRY_HAP);
    if (!paramsArray[0]) {
      return;
    }

    const params: Param = paramsArray[0] as Param;
    this.list = params.list;
    this.eventId = params.eventId;
    this.dataSource = new AttendeeListDataSource(this.list);
    this.dataChangeHandler = (data: emitter.EventData) => {
      this.onDataChange(data)
    };
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.dataChangeHandler);
  }

  async onDataChange(data: emitter.EventData) {
    this.list =
      await AttendeeService.INSTANCE.queryAttendeeInfoByEventId(this.eventId) as Array<CalendarContract.Attendees>;
    this.dataSource.setData(this.list);
  }

  build() {
    NavDestination() {
        GridRow({
          columns: { xs: 12, sm: 48, md: 8, lg: 12 },
          gutter: 0
        }) {
          GridCol({
            span: { xs: 10, sm: 44, md: 6, lg: 8 },
            offset: { xs: 0, sm: 2, md: 1, lg: 2 }
          }) {
            Scroll(this.mScroller) {
              this.buildList()
            }
            .scrollBar(BarState.Off)
            .width('100%')
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
          }
          GridCol({
            span: { xs: 2, sm: 2, md: 1, lg: 2 }
          }) {
            Row() {
              ScrollBar({ scroller: this.mScroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
            }
            .margin({ top: $r('sys.float.padding_level8'), bottom: 68 })
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
        }
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({
      top: this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
      bottom: this.windowAvoidAreaNavigationRectHeight
    })
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .hideTitleBar(false)
    .title(this.AttendeeTitle(), { paddingStart: LengthMetrics.vp(16) })
    .backButtonIcon(this.modifier.opacity(this.windowFocused ? 1 : 0.4))
  }

  private dataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };
}

interface Param {
  list: Array<Attendee>;
  eventId: number;
}