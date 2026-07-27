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
  AccountColor,
  AgendaEventInfo,
  AgendaTransitionUtil,
  CalendarContract,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NotificationTriggerHelper,
  RouterModel,
  RouterName,
  NavPathName,
  TriggerSource,
  ViewProxy,
  CommonInnerEvent,
  BigFontSize,
  EmitterCollector,
  ClickSource,
  MIN_WINDOW_WIDTH_VP,
  AGENDA_SUB_DETAIL_WIDTH,
  PreferencesFiles,
  PreferencesUtil
} from '@app/common';

import lazy { AgendaDetail } from './AgendaDetail';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ImageButton } from '@app/common.components';
import { EditAgendaMenu } from '../../components/EditAgendaMenu';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { emitter } from '@kit.BasicServicesKit';
import { AgendaDetailSource } from '../../common/AgendaEnum';
import { LengthMetrics } from '@kit.ArkUI';
import { sendAccessibilityEvent } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'AgendaDetailCover';

@Component
export struct AgendaDetailCover {
  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @State eventId: number = -1;

  // 沉浸式窗口右上角按钮宽度
  @StorageLink('titleButtonWidth') titleButtonWidth: number = 0;

  // 用于跳转详情子窗的占位用标识位
  @State scaleFlagChanged: boolean = false;

  // 右上角分享按钮被点击
  @State shareFlagChanged: boolean = false;

  // 右上角编辑按钮被点击
  @State editFlagChanged: boolean = false;

  // 右上角删除按钮被点击
  @State deleteFlagChanged: boolean = false;

  // 顶部导航标题
  @State navTitle: Resource = $r('app.string.event_detail');

  @State holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  @State isHoliday: boolean = false;

  @State holidayTitle: string = '';

  // 日程是否可编辑
  @State canEdit: boolean = true;

  // 日程可分享
  @State canShare: boolean = true;

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  // 来源入口
  @State fromType: number = FromType.UNKNOWN;

  @State isEditMenuShow: boolean = false;

  @State mEventInfo: AgendaEventInfo = new AgendaEventInfo();

  @State rightButtonShow: boolean = false;

  // hover态颜色
  @State hoverColor: Resource = $r('app.color.default_background');

  @State detailPadding: number = 16;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //button背景色
  private buttonBackgroundColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  // 该值用于记录是否显示底部按钮,因当前底部按钮在折叠机大屏时需要移至右上角
  private showBottom: boolean = DeviceConfig.instance().config.isShowBottom;

  @State isShowBottom: boolean = this.showBottom;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private scroller: Scroller = new Scroller();

  // 是否支持详情子窗跳转
  private canSubWindow: boolean = false;

  // 是否从详情子窗跳转而来
  private isPop: boolean = false;

  private getUpdatedInfo: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.mEventInfo = info;
    this.navTitle = info.isImportantEvent() ? $r('app.string.important_day') : $r('app.string.event_detail');
    this.rightButtonShow = this.shouldShowOperateButtons();
  };

  private eventToCloseCover: () => void = () => {
  };

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  private isSubDetailCheck: boolean = DeviceConfig.instance().config.isSubDetailCheck;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  // 是否能够打开详情子窗判断
  @State canOpenSubDetail: boolean =
    this.canSubWindow && (!this.isSubDetailCheck || this.windowWidth > AGENDA_SUB_DETAIL_WIDTH);

  // 详情子窗打开状态存储
  @StorageLink(GlobalDataKeys.IS_SUB_WINDOW_DETAIL) isSubWindowDetail: boolean = false;

  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
    this.canOpenSubDetail = this.canSubWindow && (!this.isSubDetailCheck || this.windowWidth > AGENDA_SUB_DETAIL_WIDTH);
    if (this.canOpenSubDetail && this.isSubWindowDetail) {
      this.closeToPopDetail();
    }
    this.checkButtonShowBottom();
  }

  checkButtonShowBottom() {
    const isBigScreen = this.windowWidth > AGENDA_SUB_DETAIL_WIDTH;
    this.isShowBottom = !isBigScreen && this.showBottom;
    this.rightButtonShow = this.shouldShowOperateButtons();
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    if (this.isHoliday) { // 拼接节假日数据
      this.holidayInfo.mTitle = this.holidayTitle;
      this.holidayInfo.mIsHoliday = true;
      this.holidayInfo.mIsAllDay = true;
      this.holidayInfo.mId = -1; // 用作标识，无实际含义
      this.holidayInfo.mBegin = this.instanceStartMills;
      this.holidayInfo.mImportantEventType = -1; // 用作标识，无实际含义
      this.holidayInfo.mEnd = this.instanceEndMills;
      this.holidayInfo.mDisplayColor = AccountColor.RED;
    }
    this.checkButtonShowBottom();
    // 全模态展开动效时弹出通知弹窗会导致全模态弹窗异常,故在展开完成后再请求通知弹窗
    const timeId = setTimeout(() => {
      NotificationTriggerHelper.getInstance().requestNotification(TriggerSource.TRIGGER_NOTIFICATION_BUSINESS);
      clearTimeout(timeId);
    }, AgendaTransitionUtil.ANIMATE_TOTAL_TIME);

    this.eventToCloseCover = () => {
      Log.info(TAG, `emitter close agenda cover`);
      this.agendaTransitionUtil.onBackClicked(false, false, !this.isPop);
    };
    // 卡片点击进入月视图，关闭全模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.eventToCloseCover);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.eventToCloseCover);
    if (this.instanceStartMills === 0 || this.instanceEndMills === 0) {
      // 两个参数有一个为0时，走入
      Log.error(TAG, `No Valid Input, begin = ${this.instanceStartMills}, end = ${this.instanceEndMills}`);
    }
    this.onWindowWidthChange();
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.emitterCollector.off();
  }

  // 是否重复日程第一条
  isFirstRepeatAgenda(): boolean {
    if (!this.mEventInfo.isRepeatEvent()) {
      return false;
    }
    if (this.mEventInfo.mBegin === this.instanceStartMills) {
      return true;
    }
    return false;
  }

  goToEditEvent() {
    if (this.mEventInfo.isRepeatEvent() && !this.mEventInfo.isImportantEvent()) {
      this.isEditMenuShow = true;
    } else {
      this.mAgendaOperateHelper.editAgenda(this.mEventInfo);
    }
  }

  onBackPress(): boolean {
    this.viewProxy.onBackPressed();
    return false;
  }

  pageBackAfterDelete() {
    this.agendaTransitionUtil.onBackClicked(!this.isPop, false, !this.isPop);
  }

  pageRouterBack() {
    this.agendaTransitionUtil.onBackClicked(!this.isPop, false, !this.isPop);
    emitter.emit({ eventId: CommonInnerEvent.EVENT_CLOSE_AGENDA_DETAIL_COVER }); // 通知全部日程、搜索日程页面重新获焦
  }

  closeToPopDetail() {
    this.isSubWindowDetail = true;
    PreferencesUtil.putBooleanValueSync(PreferencesFiles.DEFAULT, GlobalDataKeys.IS_SUB_WINDOW_DETAIL, true);
    const param: Record<string, number | string | boolean | AgendaEventInfo> = {};
    param.id = this.mEventInfo.mId;
    if (this.holidayInfo.isHoliday()) {
      param.holidayInfo = this.holidayInfo;
    }
    param.instanceStartMills = this.mEventInfo.mBegin;
    param.instanceEndMills = this.mEventInfo.mEnd;
    param.fromType = FromType.MONTH_VIEW;
    param.source = 'CLICK_MONTH_SHARE_AGENDA';
    param.isMessageResource = this.mEventInfo.isMessageResource;
    param.isPopShrink = true;
    param.isHoliday = this.mEventInfo.mIsHoliday ?? false;
    param.holidayTitle = this.mEventInfo.mTitle;
    const routerData: RouterModel = {
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: param,
      animated: false
    }
    const eventData: emitter.EventData = {
      data: routerData
    };
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_TO_POPUP }, eventData);
  }

  /**
   * pc端是否展示编辑、分享、删除操作按钮
   */
  private shouldShowOperateButtons(): boolean {
    if (this.isShowBottom) {
      return false;
    }

    if (this.holidayInfo?.mIsHoliday) {
      return false;
    }

    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return false;
    }
    return true;
  }

  /**
   * 日程详情右上角按钮菜单
   */
  @Builder
  NavigationMenus() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.share'),
        flagChanged: this.shareFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_share'),
        compId: CompId.ID_BT_AGENDA_DETAIL_SHARE
      })
        .margin({ left: 8 })
        .visibility(this.canShare ? Visibility.Visible : Visibility.None)
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.square_and_pencil'),
        flagChanged: this.editFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_edit'),
        compId: CompId.AGENDA_DETAIL_EDIT,
        onButtonClick: () => {
          this.goToEditEvent();
        }
      })
        .bindMenu(this.isEditMenuShow, this.buildEditMenu(), {
          placement: Placement.BottomRight,
          onDisappear: () => {
            this.isEditMenuShow = false;
          }
        })
        .visibility(this.canEdit ? Visibility.Visible : Visibility.None)
        .margin({ left: 8 })
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.trash'),
        flagChanged: this.deleteFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: $r('app.string.agenda_menu_item_delete'),
        compId: CompId.AGENDA_DETAIL_DELETE,
      })
        .margin({ left: 8 })
    }
    .height(56)
  }

  /**
   * 日程详情右上角缩放按钮
   */
  @Builder
  jumpToPopMenus() {
    Row() {
      ImageButton({
        buttonType: this.needCommerce ? ButtonType.Normal : ButtonType.Circle,
        image: $r('sys.symbol.arrow_down_right_and_arrow_up_left'),
        flagChanged: this.scaleFlagChanged,
        buttonBackgroundColor: this.buttonBackgroundColor,
        promptText: '退出扩展', // 待提翻
        compId: 'id_bt_agenda_detail_b',
        onButtonClick: () => {
          this.closeToPopDetail();
        }
      })
        .margin({ left: 8 })
    }
    .height(56)
  }

  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    EditAgendaMenu({
      isFirstRepeatAgenda: this.isFirstRepeatAgenda(),
      editThisAgenda: () => {
        this.mAgendaOperateHelper.editThisAgenda(this.mEventInfo, this.instanceStartMills, this.instanceEndMills);
      },
      editThisAgendaAndBeyond: () => {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(
          this.mEventInfo, this.instanceStartMills, this.instanceEndMills);
      },
      onClickEdit: () => {
        this.mAgendaOperateHelper.editAgenda(this.mEventInfo);
      }
    })
  }

  @Builder
  MainContentBuilder() {
    GridRow({
      // 手机边距16,大屏边距24,宽度大于840则需要以10/12的栅格比例留白
      columns: { xs: 10, sm: 10, md: 12 },
      breakpoints: {
        value: ['600vp', '840vp'],
        reference: BreakpointsReference.WindowSize
      },
      direction: GridRowDirection.Row
    }) {
      GridCol({ span: 10, offset: { xs: 0, sm: 0, md: 1 } }) {
        AgendaDetail({
          canEdit: $canEdit,
          canShare: $canShare,
          shareFlagChanged: this.shareFlagChanged,
          deleteFlagChanged: this.deleteFlagChanged,
          isShowBottom: this.isShowBottom,
          eventId: $eventId,
          sourceType: AgendaDetailSource.AGENDA_COVER,
          isDivide: false,
          isCover: true,
          needLeftPadding: true,
          needRightPadding: true,
          scroller: this.scroller,
          holidayInfo: this.holidayInfo,
          displayStartMills: this.instanceStartMills,
          displayEndMills: this.instanceEndMills,
          titleHeight: 64 + this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
          onDeleteSuccess: () => {
            GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
            this.pageBackAfterDelete();
          },
          onAgendaNotFound: () => {
            GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
            this.pageBackAfterDelete();
          },
          fromType: this.fromType,
          getUpdatedInfo: this.getUpdatedInfo,
          paddingLeft: this.detailPadding,
          paddingRight: this.detailPadding,
        })
      }
    }
    .onBreakpointChange((bp) => {
      // 小屏需要边距,到直接通过栅格来留白
      if (bp === 'xs') {
        this.detailPadding = 16;
      } else if (bp === 'sm') {
        this.detailPadding = 24;
      } else if (bp === 'md' && !this.canSubWindow) {
        this.detailPadding = 0;
      }
    })
    .layoutWeight(1)
  }

  @Builder
  GridColContent() {
    Row() {
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize(24)
          .fontColor([$r('sys.color.icon_primary')])
      }
      .margin({
        start: LengthMetrics.resource($r('sys.float.padding_level8')),
        end: LengthMetrics.resource($r('sys.float.padding_level4'))
      })
      .type(ButtonType.Capsule)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .width(40)
      .height(40)
      .onClick(() => {
        this.pageRouterBack();
      })
      Text(this.navTitle)
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
          20
        ))
       // .margin({ left: 8 })
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      if (this.canOpenSubDetail) {
        this.jumpToPopMenus()
      }
      if (this.rightButtonShow) {
        this.NavigationMenus()
      }
    }
    .padding({ right: 16 + this.titleButtonWidth })
    .height(56)
  }

  @Builder
  buildAgenda() {
    Column() {
      this.GridColContent()
      this.MainContentBuilder()
    }
    .transition(
      TransitionEffect.asymmetric(
        TransitionEffect.OPACITY.animation({
          duration: 100,
          curve: Curve.Sharp
        }),
        TransitionEffect.OPACITY.animation({
          duration: 300,
          curve: Curve.Sharp
        }),
      )
    )
    .padding({
      top: this.windowAvoidAreaTopRectHeight + this.buttonTopHeight,
      bottom: this.inSmallWindow ? 0 : this.windowAvoidAreaNavigationRectHeight,
    })
    .backgroundColor($r('sys.color.background_secondary'))
    .id(TAG + '_buildAgenda')
  }

  build() {
    this.buildAgenda()
  }
}