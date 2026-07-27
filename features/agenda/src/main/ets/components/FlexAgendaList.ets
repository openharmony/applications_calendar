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
  AgendaEventInfo,
  CloudUtils,
  CompId,
  DeviceConfig,
  GlobalData,
  GlobalDataKeys,
  MIDDLE_WINDOW_WIDTH_VP,
  MIN_WINDOW_WIDTH_VP,
  ModeUtil,
  UnusualMode,
} from '@app/common';

import { AgendaDetail } from '../AgendaDetail/view/AgendaDetail';
import { OpenCloudSyncTip } from './OpenCloudSyncTip';
import { CACHE_SYNC_SWITCH_STATUS, IS_SUPPORT_CLOUD_SYNC } from '@app/common/src/main/ets/dao/CloudUtils';
import lazy { AgendaListView } from '../AgendaList/view/AgendaListView';
import { AgendaDetailSource } from '../common/AgendaEnum';

const TAG: string = "FlexAgendaList";

/**
 * 日程列表适应分栏的父组件
 *
 * @since 2022-09-20
 */
@Component
export struct FlexAgendaList {
  @Consume navPathStack: NavPathStack;

  @Provide calendarUuid: string = '';

  @Provide currentDisplayStartMills: number = 0;

  @Provide currentDisplayEndMills: number = 0;

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  // 小屏判断（特殊模式沿用小屏逻辑）
  @Provide inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP ||
  ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode);

  // 分栏状态：左侧日程列表选中日程id值
  @StorageLink('checkEventId') checkEventId: number = -1;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 是否支持云同步，部分设备上无云空间应用
  @StorageProp(IS_SUPPORT_CLOUD_SYNC) isSupportCloudSync: boolean = false;

  // 云空间开关状态，若未开启则展示提示
  @StorageProp(CACHE_SYNC_SWITCH_STATUS) isCloudSyncOpened: boolean = false;

  // 分栏状态：右侧分栏当前展示的日程id
  @Link showEventId: number;

  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  @Link canEdit: boolean;

  @Link canShare: boolean;

  @Link onBackToday: boolean;

  @Link selectedAgendaCount: number;

  @Link selectable: boolean;

  @Link hideList: boolean;

  // 全部日程列表是否展示节日
  @Link isShowHoliday: boolean;

  @Prop deleteSelected: boolean = false;

  @Prop shareSelected: boolean = false;

  @Prop editSelected: boolean = false;

  @Prop isShowSyncTip: boolean = false;

  @Provide actionFocus: string = FocusPage.AGENDA_LIST_VIEW;

  private readonly hideListTimeParam: AnimateParam = { duration: 300, curve: Curve.Friction };

  @Link isMiddleWindow: boolean;

  @Link isShowDetail: boolean;

  @State needPadding: boolean = false;

  private showBottomTab: boolean = DeviceConfig.instance().config.agendaDetailShowBottomTab;
  // 路由携带的日期时间戳
  private paramsDisplayStartMills: number = 0;
  private paramsDisplayEndMills: number = 0;
  // 路由携带的日程id
  private paramsEventId: number = 0;
  // 显示搜索框的方法
  private showSearchHandler = () => {};

  onActionFocusChange(actionFocus: string) {
    this.actionFocus = actionFocus
  }

  build() {
    Row() {
      Column() {
        // 未登录华为账号时进入全部日程列表，有提示语
        // 已登录华为账号后关闭日历云同步，全部日程列表显示提示语
        if (
          CloudUtils.isCloudAppExist() && ((!this.isSupportCloudSync && this.isShowSyncTip) ||
            (this.isSupportCloudSync && !this.isCloudSyncOpened && this.isShowSyncTip)
          )) {
          OpenCloudSyncTip();
        }
        AgendaListView({
          onSelectedAgendaChange: this.onSelectedAgendaChanged,
          showEventId: $showEventId,
          onBackToday: this.onBackToday,
          selectedAgendaCount: this.selectedAgendaCount,
          selectable: this.selectable,
          hideList: this.hideList,
          paramsDisplayStartMills: this.paramsDisplayStartMills,
          paramsDisplayEndMills: this.paramsDisplayEndMills,
          paramsEventId: this.paramsEventId,
          isShowHoliday: this.isShowHoliday,
        })
      }
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.IDENTITY
            .combine(TransitionEffect.opacity(1)
              .animation(this.hideListTimeParam))
            .combine(TransitionEffect.translate({ x: -this.windowWidth / 2 })
              .animation(this.hideListTimeParam)),
          TransitionEffect.OPACITY
            .combine(TransitionEffect.opacity(1)
              .animation(this.hideListTimeParam))
            .combine(TransitionEffect.translate({ x: -this.windowWidth / 2 })
              .animation(this.hideListTimeParam))
        )
      )
      .id(CompId.AGENDA_LIST_VIEW)
      .layoutWeight(this.isMiddleWindow ? 1 : 2)
      .visibility(this.hideList ? Visibility.None : Visibility.Visible)

      if (!this.inSmallWindow) {
        GridRow({ // 在全屏显示详情的时候,宽度大于840则需要以10/12的栅格比例留白
          columns: { xs: 10, sm: this.hideList ? 12 : 10 },
          breakpoints: {
            value: ['840vp'],
            reference: BreakpointsReference.WindowSize
          },
          direction: GridRowDirection.Row
        }) {
          GridCol({ span: 10, offset: { xs: 0, sm: this.hideList ? 1 : 0 } }) {
            if (this.showEventId !== -1) {
              AgendaDetail({
                deleteFlagChanged: this.deleteSelected,
                shareFlagChanged: this.shareSelected,
                editFlagChanged: this.editSelected,
                deviceShowButtonTab: this.showBottomTab,
                canEdit: $canEdit,
                canShare: $canShare,
                eventId: $showEventId,
                holidayInfo: this.holidayInfo,
                needLeftPadding: false,
                needRightPadding: true,
                sourceType: AgendaDetailSource.AGENDA_LIST,
                onDeleteSuccess: (): void => this.onAgendaDetailDeleteSuccess(),
                showSearchHandler: this.showSearchHandler,
                displayStartMills: this.currentDisplayStartMills,
                displayEndMills: this.currentDisplayEndMills,
                isShowBottom: this.selectable == false,
                onActionFocusChange: (actionFocus: string): void => this.onActionFocusChange(actionFocus),
                paddingLeft: this.hideList && this.needPadding ? 24 : 0,
                paddingRight: this.hideList ? (this.needPadding ? 24 : 0) : 16,
              }).height('100%').id(CompId.FLEX_AGENDA_LIST_AGENDA_DETAIL)
            }
          }
        }.padding({
          bottom: this.windowAvoidAreaNavigationRectHeight
        })
        .onBreakpointChange((bp) => {
          // 小屏需要边距,到直接通过栅格来留白
          this.needPadding = bp === 'xs';
        })
        .id(CompId.AGENDA_DETAIL)
        .layoutWeight(this.isMiddleWindow ? 1 : 3)
      }
    }
    .id(CompId.FLEX_AGENDA_LIST)
    .layoutWeight(1)
  }

  /**
   * 日程详情页删除成功的回调
   */
  onAgendaDetailDeleteSuccess() {
    GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
    if (this.inSmallWindow) {
      this.navPathStack.pop();
    }
  }

  /**
   * PC弹框列表程删除成功的回调
   */
  onBindMenuDeleteSuccess() {
    GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
  }

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
    this.isMiddleWindow = (this.windowWidth > MIN_WINDOW_WIDTH_VP) &&
      (this.windowWidth < MIDDLE_WINDOW_WIDTH_VP);
    this.isShowDetail = !this.inSmallWindow;
    if (this.inSmallWindow) {
      this.hideList = false;
    }
  }

  aboutToAppear(): void {
    this.isShowDetail = !this.inSmallWindow;
  }

  private onSelectedAgendaChanged: (event: AgendaEventInfo | undefined) =>
    void = (event: AgendaEventInfo | undefined): void => {
  };
}

export enum FocusPage {
  AGENDA_LIST_VIEW = 'AgendaListView',
  AGENDA_DETAIL = 'AgendaDetail',
  FLEX_SEARCH_AGENDA = 'FlexSearchAgenda',
}