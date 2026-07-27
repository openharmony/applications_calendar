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

import { AgendaEventInfo,
  CalendarDate,
  CommonInnerEvent,
  DataSourceTemplate,
  DeviceConfig, GlobalThis, NavPageBuilderFactory, NavPathName, ViewProxy, } from '@app/common/index';
import { ImportAllAgendaItem } from './ImportAllAgendaItem';
import emitter from '@ohos.events.emitter';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'ImportAllAgendaList';

/**
 * 日程列表主要页面
 *
 * @since 2022-09-20
 */

interface RouterParam {
  datas: AgendaEventInfo[],
  accountColor: number,
  checkedAccId: number
}

@Builder
function harBuilder(value: object) {
  ImportAllAgendaList();
}

const builderName = NavPathName.IMPORT_SHOW_AGENDA;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

class AgendaEventListDataSource extends DataSourceTemplate<AgendaEventInfo> {
}

@Component
export struct ImportAllAgendaList {
  @Consume navPathStack: NavPathStack;

  @StorageProp('themeColor') themeColor: string = '';

  @State datas: AgendaEventInfo[] = [];

  dataSource: AgendaEventListDataSource = new AgendaEventListDataSource(this.datas);

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageLink('language') language: string = '';

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private dateSet: Set<string> = new Set<string>();

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private accountColor: number = 0;

  private checkedAccId: number = 0;

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    const params: RouterParam[] = this.navPathStack
      .getParamByName(NavPathName.IMPORT_SHOW_AGENDA) as RouterParam[];
    if (!params) {
      return;
    }
    const paramInter = params[0] as RouterParam;
    this.datas = paramInter?.datas;
    this.accountColor = paramInter?.accountColor;
    this.checkedAccId = paramInter?.checkedAccId;
    this.setDayHead();
    this.dataSource = new AgendaEventListDataSource(this.datas);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    let eventData: emitter.EventData = {
      data: {
        'checkedAccId': this.checkedAccId,
        'accountColor': this.accountColor
      }
    };
    emitter.emit({ eventId: CommonInnerEvent.VCS_ACCOUNT_CHANGE }, eventData);
  }

  //设置mIsSetDayHead属性
  setDayHead() {
    let sortList: (
      a: AgendaEventInfo,
      b: AgendaEventInfo) => number = (a: AgendaEventInfo, b: AgendaEventInfo): number => {
      if (a.mBegin !== b.mBegin) {
        return a.mBegin - b.mBegin;
      }

      if (a.mEnd !== b.mEnd) {
        return a.mEnd - b.mEnd;
      }
      const getTitle = (item: AgendaEventInfo): string => {
        return item.mTitle ?? '';
      };
      return getTitle(a).localeCompare(getTitle(b));
    }
    this.datas.sort((a: AgendaEventInfo, b: AgendaEventInfo) => sortList(a, b));
    this.datas.forEach(item => {
      const dateTime = new CalendarDate(item.mBegin).toLocaleDateString();
      if (this.dateSet.has(dateTime)) {
        item.mIsSetDayHead = false;
      } else {
        item.mIsSetDayHead = true;
        this.dateSet.add(dateTime);
      }
    });
  }

  build() {
    NavDestination() {
      this.buildContent()
    }
    .onShown(() => {
      this.viewProxy.onShown()
    })
    .onHidden(() => {
      this.viewProxy.onHidden()
    })
    .onBackPressed(() => {
      return this.handleOnBackPressed();
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({
      top: this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
    })
    .title(GlobalThis.getResourceStr($r('app.string.all_agenda'), this.language),
      { paddingStart: LengthMetrics.vp(16) })
    .hideTitleBar(false)
  }

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
          Column() {
            List() {
              LazyForEach(this.dataSource, (item: AgendaEventInfo, index: number) => {
                ListItem() {
                  ImportAllAgendaItem({
                    info: item,
                    accountColor: this.accountColor
                  })
                }
              })
            }
            .contentEndOffset(this.windowAvoidAreaNavigationRectHeight)
            .scrollBar(BarState.Off)
          }
          .padding({ left: 16, right: 16 })
          .width('100%')
          .backgroundColor($r('sys.color.background_secondary'))
        }
      }
    }
    .height('100%')
  }

  @Builder
  NaviTitle() {
    NaviTitleBar()
  }

  private handleOnBackPressed(): boolean {
    return this.dealOnBackPressed();
  }

  private dealOnBackPressed(): boolean {
    return this.viewProxy.onBackPressed();
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
            .opacity($r('sys.float.alpha_primary'))
        }
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
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

      Text($r('app.string.all_agenda'))
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