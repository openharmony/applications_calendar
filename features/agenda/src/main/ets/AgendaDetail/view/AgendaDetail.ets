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

import intl from '@ohos.intl';

import HashMap from '@ohos.util.HashMap';
import emitter from '@ohos.events.emitter';
import {
  AgendaEventInfo,
  AttendeeService,
  behaviorEvents,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  CommonInnerEvent,
  CommonService,
  DateUtil,
  DialogControllerOptions,
  EventService,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPathManager,
  NavPathName,
  ReminderService,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceManager,
  SourceTypeEnum,
  statisticEvents,
  ThrottleFunction,
  I18nUtil,
  DeviceConfig,
  ServiceEnum,
  NotifyTypeEnum,
  NotifyHandlerEnum,
  MessageStatusTypeEnum,
  AppContinueManager,
  ModeUtil,
  UnusualMode,
  AgendaDeleteService,
  AccountUtils,
  AgendaAbilityManager,
  ClickSource,
  EmptyUtils,
  CommonEventHubCode,
  CompId,
  CalendarDate,
  HolidayUtil,
  MIN_WINDOW_WIDTH_VP,
  SafeUtil,
  CreateAgendaSheetFromPage,
  traceEvents,
  CloudUtils,
  CalendarDataFeatureHelper,
  CalendarDataFeature,
  CHINA_COUNTRY_CODE,
} from '@app/common';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import { BottomTab } from './BottomTab';
import { AttendeeRow } from '../../components/AttendeeRow';
import { AgendaReminderInfo } from '../../CreateAgenda/view/AgendaReminderInfo';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { AgendaTitle } from './AgendaTitle';
import lazy { OtherAgendaInfo } from './OtherAgendaInfo';
import { FocusPage } from '../../components/FlexAgendaList';
import { LengthMetrics } from '@kit.ArkUI';
import { AgendaUtil } from '@app/common/src/main/ets/agenda/AgendaUtil';
import lazy { AgendaMap } from './AgendaMap';
import { maskString } from '@app/common/index';
import { AgendaDetailSource } from '../../common/AgendaEnum';
import { ExportVcsCallBack, ImportExportService } from '@app/feature.importexport';
import { FestivalJumpUtil } from '../../util/FestivalJumpUtil';
import { CreateAgendaPageSource } from '../../CreateAgenda/Constants';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { AttachmentViewModel } from '../../AgendaAttachment/viewmodel/AttachmentViewModel';
import { AttachmentList } from '../../AgendaAttachment/view/AttachmentList';
import { Account } from './Account';
// import lazy { harmonyShare } from '@kit.ShareKit'; // ShareKit 注释

const TAG: string = 'AgendaDetail';
const DEFAULT_NUM: number = -1;
const DEFAULT_STR: string = '';
const LOCAL_ACCOUNT_TYPE = 'local';
const CUSTOMER_ACCOUNT_TYPE = 'com.openharmony.custom';
const ACCOUNT_TYPE: string = 'email';
const THROTTLE_FUNC_DELAY = 300;
const EVENT_TO_UPDATE_LIST_DELAY = 200;

const WELINK_ONE_KEY_LEN = 42;
const WELINK_MTG_ONE_KEY_LEN = 29;

export const CONTACT_BIRTHDAY_BUNDLE_NAME = 'com.ohos.contactsdataability';
export const CONTACT_BIRTHDAY_BUNDLE_NAME_2 = 'com.ohos.contacts';

// 禁止触发详情接续的日程详情来源页
const REJECT_AGENDA_SOURCE = [
  AgendaDetailSource.SEARCH_LIST,
  AgendaDetailSource.DAY_VIEW,
  AgendaDetailSource.AGENDA_PAGE,
]

/**
 * 日程详情组件
 *
 * @since 2022-10-10
 */
@Component
export struct AgendaDetail {
  @Consume navPathStack: NavPathStack;

  // 是否显示编辑菜单
  @State isEditMenuShow: boolean = false;

  // 弹窗控制选择器选项，日程详情页面统一配置
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: true,
    customStyle: true,
  };

  @LocalStorageLink('uiAbilityContext') context: common.UIAbilityContext | undefined = undefined;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  private isDivide: boolean = true;

  private isDetailPop: boolean = false; // 是否处于详情子窗

  private isCover: boolean = false;

  // 是否存在于子悬浮窗中
  private isInPop: boolean = false;

  // 是否存在于新Ability中
  private isInNewPage: boolean = false;

  // 日程组件所在的视图类型
  private sourceType: number = AgendaDetailSource.UNKNOWN;

  // 附件相关信息
  @State attachmentViewModel: AttachmentViewModel = new AttachmentViewModel();

  @State checkValuesArray: CalendarContract.Reminders[] = [];

  @State mEventInfo: AgendaEventInfo = new AgendaEventInfo();

  private mImportantEventType: number = 0;

  @State attendeeList: Array<CalendarContract.Attendees> = [];

  @State mIsAllDay: boolean = false;

  @State displayStartMills: number = 0;

  @State displayEndMills: number = 0;

  @State isReload: boolean = false;

  @State isEventInfoReady: boolean = false;

  // 帐户颜色
  @State accountColor: number = DEFAULT_NUM;

  // 帐户展示名
  @State accountDisName: ResourceStr = DEFAULT_STR;

  @State isAcceptAgenda: boolean = false;

  // 日程是否可以编辑
  @Link canEdit: boolean;

  // 日程是否可以分享
  @Link canShare: boolean;

  @Prop holidayInfo: AgendaEventInfo = new AgendaEventInfo();

  @Prop paddingLeft: number = 0;

  @Prop paddingRight: number = 0;

  @Link @Watch('onChangedCheckId') eventId: number;

  // 分享标记位改变，用于父组件实现分享操作
  @Prop @Watch('onShareFlagChanged') shareFlagChanged: boolean = false;

  // 删除标记位改变，用于父组件实现删除操作
  @Prop @Watch('onDeleteFlagChanged') deleteFlagChanged: boolean = false;

  // 删除标记位改变，用于父组件实现删除操作
  @Prop @Watch('onEditFlagChanged') editFlagChanged: boolean = false;

  // 重要提醒开关
  @State isImportantAlert: boolean = false;

  // 来源入口
  @Prop fromType: number = FromType.UNKNOWN;

  // 节假日的国家
  @State holidayCountry: string = '';

  @State region: string = '';

  private deviceShowButtonTab: boolean = true; // 非分栏场景展示下方按键。分栏场景下PC,PAD不展示，折叠屏需要展示

  @StorageProp('themeColor') themeColor: string = '';

  @StorageProp(GlobalDataKeys.IS_NOTIFICATION_GRANTED) isNotificationGranted: boolean = false;

  @State isAgendaCollapse: boolean = false;

  private shouldShowBottomTab(): boolean {
    if (!this.isShowBottom) {
      return false;
    }
    if (AccountUtils.isBirthDayAccountById(this.mEventInfo.mCalendarId)) {
      return false;
    }
    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return false;
    }

    if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
      return false;
    }

    if (!this.deviceShowButtonTab) {
      return false;
    }

    return true;
  }

  // uuid
  private uuid: string = '';

  private scroller: Scroller = new Scroller();

  // 是否显示底部栏
  @Prop isShowBottom: boolean = true;

  //标志是否正在进行删除及退出操作,用以防止删除事件被页面接收到导致二次pop
  private isDeleting = false;

  private isThisAgendaDeleting = false;

  private isThisAgendaAndBeyondDeleting = false;

  //是否需要左边距
  private needLeftPadding: boolean = true;

  //是否需要右边距
  private needRightPadding: boolean = true;

  private accountName: string = DEFAULT_STR;

  private accountType: string = DEFAULT_STR;

  // 分享的viewId
  private shareAnchorViewId: string = CompId.ID_BT_AGENDA_DETAIL_SHARE;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @State account: CalendarContract.Accounts = new CalendarContract.Accounts();

  private instanceKey: string = '';

  @Prop titleHeight: number = 0;

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @State createPageData: emitter.EventData = {
    data: {
      fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
    }
  };

  private isInDetailPop: boolean = false; // 是否处于详情子窗

  private jumpToPopEditPage: (intent: CreateAgendaPageSource) => void = (intent: CreateAgendaPageSource) => {
  }

  // 显示编辑日程跟手弹窗
  @State isEditPopupShow: boolean = false;

  @State editTips: boolean = false;

  @State isSupportEventAttachment: boolean = false;

  private menuHeight: number = this.needCommerce ? 56 : 48;

  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  onShareFlagChanged() {
    this.exportVcsByEvent();
  }

  onEditFlagChanged() {
    this.goToEditEvent();
  }

  onDeleteFlagChanged() {
    this.showDeleteDialog();
  }

  @Builder
  buildAgendaScroll() {
    Stack({ alignContent: Alignment.End }) {
      Scroll(this.scroller) {
        Column() {
          Column().height(this.titleHeight)
          AgendaTitle({
            info: this.mEventInfo,
            displayStartMills: this.displayStartMills,
            displayEndMills: this.displayEndMills,
            isFromMonthView: this.fromType === FromType.MONTH_VIEW,
            marginBottom: this.isAgendaCollapse ? 8 : 12
          });

          if (!AccountUtils.isDefaultAccount(this.account) &&
            !AccountUtils.isCustomAccount(this.account) && // 修复克隆问题
            this.attendeeList.length > 0 && !this.isAgendaCollapse) {
            AttendeeRow({ attendeeList: $attendeeList, eventId: this.eventId, isCover: this.isCover })
              .margin({ bottom: 12 });
          }


          if (this.isEventInfoReady &&
            this.mEventInfo.mImportantEventType !== CalendarContract.EventImportantType.HOLIDAY) {
            AgendaReminderInfo({
              eventInfo: $mEventInfo,
              checkValuesArray: $checkValuesArray,
              mIsAllDay: this.mIsAllDay,
              isInDetailPage: true,
              isEditMode: true,
              isImportantAlert: $isImportantAlert,
              marginTop: this.isNotificationGranted ? 0 : 16,
              marginBottom: this.attachmentViewModel?.attachmentCount === 0 ? 12 : 0,
              isAgendaCollapse: this.isAgendaCollapse
            });
          }

          if (this.isSupportEventAttachment) {
            this.buildAccount();

            AttachmentList({
              attachmentViewModel: this.attachmentViewModel,
              isInDetailPage: true,
              eventUuid: this.uuid,
            }).margin({ bottom: 12 })
              .visibility(this.attachmentViewModel?.attachmentCount === 0 ? Visibility.None : Visibility.Visible);

            this.buildEventDescriptionView();
          }

          OtherAgendaInfo({
            info: this.mEventInfo,
            accountColor: this.accountColor,
            accountDisName: this.accountDisName,
            isCover: this.isCover && !this.isDetailPop,
            checkId: this.eventId,
            isAgendaCollapse: this.isAgendaCollapse
          }).visibility(this.attachmentViewModel?.attachmentCount > 0 ? Visibility.None : Visibility.Visible);

          if (AgendaUtil.isLocationValid(this.mEventInfo.mLatitude, this.mEventInfo.mLongitude)) {
            AgendaMap({
              info: this.mEventInfo,
            }).padding({ left: 1, right: 1 })
          }

          Blank().layoutWeight(1);

          // 操作按钮如果在底部悬浮，需要空白占位抬高内容
          if (this.shouldShowBottomTab()) {
            Blank().height(16 + this.menuHeight)
          }
        }
      }
      .onScrollStart(() => {
        Log.info(TAG, 'buildAgendaScroll is about to scroll');
        this.onActionFocusChange(FocusPage.AGENDA_DETAIL);
      })
      .margin({
        left: this.paddingLeft,
        right: this.paddingRight
      })
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
      .flexShrink(2)
      .edgeEffect(EdgeEffect.Spring)
      .onAppear(() => {
        Log.info(TAG, `agenda detail scroll appear`);
      })

      ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .margin({ top: this.titleHeight })
    }
    .padding({ bottom: this.needCommerce ? 0 : this.windowAvoidAreaNavigationRectHeight })
  }

  @Builder
  buildAccount() {
    if (this.accountColor !== DEFAULT_NUM && this.accountDisName !== DEFAULT_STR && this.mImportantEventType === 0) {
      Column() {
        Account({
          accountColor: this.accountColor,
          accountDisName: this.accountDisName
        })
      }
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .visibility(this.attachmentViewModel?.attachmentCount === 0 ? Visibility.None : Visibility.Visible);
    }
  }

  @Builder
  buildEventDescriptionView() {
    if (EmptyUtils.isNotEmptyString(this.mEventInfo?.mDescription)) {
      Row() {
        SymbolGlyph($r('sys.symbol.doc_plaintext'))
          .fontSize(24)
          .margin({ end: LengthMetrics.vp(16) })
          .fontColor([$r('sys.color.icon_primary')])
          .opacity($r('sys.float.alpha_secondary'))
        Text(this.mEventInfo?.mDescription)
          .fontSize($r('sys.float.Subtitle_M'))
          .lineHeight(22)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .copyOption(CopyOptions.LocalDevice)
      }
      .constraintSize({ minHeight: 56 })
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 4
      })
      .margin({ bottom: 12 })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .visibility(this.attachmentViewModel?.attachmentCount === 0 ? Visibility.None : Visibility.Visible);
    }
  }

  @Builder
  buildAgenda() {
    Column() {
      this.buildAgendaScroll();
      if (this.shouldShowBottomTab()) {
        BottomTab({
          canEdit: this.canEdit,
          info: this.mEventInfo,
          displayStartMills: this.displayStartMills,
          displayEndMills: this.displayEndMills,
          isEditMenuShow: $isEditMenuShow,
          isAcceptAgenda: this.isAcceptAgenda,
          canShare: this.canShare,
          isCover: this.isCover,
          createPageData: $createPageData,
          isEditPopupShow: $isEditPopupShow,
          isInDetailPop: this.isInDetailPop,
          jumpToPopEditPage: this.jumpToPopEditPage,
          editTips: $editTips,
          onClickEdit: (): void => this.goToEditEvent(),
          onClickDelete: (): void => this.showDeleteDialog(),
          onClickShare: (): void => this.startShare(),
        })
      }
    }.height('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  buildHoliday() {
    Scroll() {
      Column() {
        Text(this.holidayInfo?.mTitle)
          .width('100%')
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 12 })
        Text() {
          Span(this.getHolidayTimeStr())
          if (this.holidayCountry != '' && this.accountName != this.region) { // 当地节假日不显示
            Span('·').fontWeight(FontWeight.Bolder)
            Span(this.accountName === CHINA_COUNTRY_CODE ?
            this.holidayCountry : $r('app.string.country_holiday', this.holidayCountry))
          }
        }
        .fontWeight(FontWeight.Regular)
        .fontSize($r('sys.float.ohos_id_text_size_body2'))
        .fontColor($r('sys.color.font_secondary'))
        .width('100%')

        Text($r('app.string.all_day'))
          .fontWeight(FontWeight.Regular)
          .fontSize($r('sys.float.ohos_id_text_size_body2'))
          .fontColor($r('sys.color.font_secondary'))
          .width('100%')
      }
      .align(Alignment.Top)
      .padding({
        left: 12,
        right: 12,
        top: 16,
        bottom: 16
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(16)
    }
    .align(Alignment.Top)
    .height('100%')
    .scrollable(ScrollDirection.Vertical)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .margin({
      start: LengthMetrics.vp(this.needLeftPadding ? 16 : 0),
      end: LengthMetrics.vp(this.needRightPadding ? 16 : 0),
      bottom: LengthMetrics.vp(12),
      top: LengthMetrics.vp(this.titleHeight),
    })
  }

  build() {
    if (this.holidayInfo?.isHoliday()) {
      this.buildHoliday()
    } else if ((this.eventId > 0) && this.isEventInfoReady) {
      this.buildAgenda()
    }
  }

  getHolidayTimeStr() {
    const DATE_INTL_OPT: intl.DateTimeOptions = { month: 'long', day: 'numeric', weekday: 'long' };
    const holidayDate = new Date(this.holidayInfo?.mBegin);
    const stamp: number =
      new CalendarDate(holidayDate.getUTCFullYear(), holidayDate.getUTCMonth(), holidayDate.getUTCDate()).getTime();
    const dateStr: string = DateUtil.intlDateFormatChineseStyle(new CalendarDate(stamp), DATE_INTL_OPT)
    return `${dateStr}`;
  }

  goToEditEvent() {
    Log.info(TAG, `goToEditEvent called`);
    this.onActionFocusChange(FocusPage.AGENDA_DETAIL);
    if (this.isRepeatAgenda() && !this.mEventInfo.isImportantEvent()) {
      this.isEditMenuShow = true;
    } else {
      if (this.isInDetailPop) {
        this.jumpToPopEditPage(CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE);
        return;
      }
      this.createPageData = {
        data: {
          eventInfo: JSON.stringify(this.mEventInfo),
          intent: CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE,
          fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
        }
      }
      this.isEditPopupShow = true;
      this.editTips = false;
    }
  }

  reportPopupStatistic(type: number, isSave: number) {
    let params: ReportHiEventParams = {
      TYPE: type,
      IS_SAVE: isSave
    }
    ReportUtil.reportStatisticEvent(statisticEvents.deleteAgendaSavePopup, params);
  }

  startShare() {
    Log.info(TAG, `start-share`)
    this.exportVcsByEvent(CompId.ID_BT_AGENDA_DETAIL_SHARE_BOTTOM_BTN);
  }

  // ShareKit 注释 - sharableTarget 参数
  // 直接拉起分享面板,不需要展示分享dialog
  exportVcsByEvent(shareAnchorViewId: string = this.shareAnchorViewId /* , sharableTarget?: harmonyShare.SharableTarget */) {
    Log.info(TAG, `shareAnchorViewId:${shareAnchorViewId}`);
    this.onActionFocusChange(FocusPage.AGENDA_DETAIL);
    let params: ReportHiEventParams = {
      FROM_TYPE: this.fromType,
      TYPE: this.mEventInfo.mImportantEventType
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDetailShare, params);
    GlobalThis.getInstance().shareAnchorViewId = shareAnchorViewId;
    if (this.isInNewPage) {
      GlobalThis.getInstance().shareAbilityContext =
        AgendaAbilityManager.getInstance().getAgendaContext(this.instanceKey);
    }
    ServiceManager.getInstance()
      .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE).then((service) => {
      // ShareKit 注释 - start
      // service?.exportVcsByEvents([this.eventId], new ExportVcsCallBack(sharableTarget), false);
      // ShareKit 注释 - end
      service?.exportVcsByEvents([this.eventId], new ExportVcsCallBack(), false);
    });
  }

  private deleteCallback: (success: boolean) => void = (success: boolean) => {
    if (success) {
      this.isDeleting = true;
      this.onDeleteSuccess();
    } else {
      this.isDeleting = false;
    }
  }

  showDeleteDialog() {
    ServiceManager.getInstance()
      .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
      service?.notifyDeleteEventWithCallback(this.mEventInfo.mId, this.displayStartMills, this.deleteCallback,
        !this.isInNewPage);
    });
  }

  subscribeEvents(): void {
    this.systemDataChangeHandler = (data: emitter.EventData) => this.onSystemDataChange(data);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.systemDataChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_LANGUAGE_CHANGED }, this.systemLanguageChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.MONTH_VIEW_DELETE_REPEATED }, this.deleteHandler);
    this.viewDataChangeHandler = (data: emitter.EventData) => this.onViewDataChange(data);
    emitter.on({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, this.viewDataChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_FORM_DETAIL }, this.formDataChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler)

    if (!EmptyUtils.isEmptyString(this.instanceKey, true) && this.sourceType === AgendaDetailSource.AGENDA_PAGE) {
      const context = AgendaAbilityManager.getInstance().getAgendaContext(this.instanceKey);
      if (context) {
        context.eventHub.on(CommonEventHubCode.EVENT_UPDATE_AGENDA_NEW_PAGE, this.updatedInfoByNewWant);
      }
    }
  }

  unsubscribeEvents(): void {
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.systemDataChangeHandler);
    emitter.off(CommonInnerEvent.SYSTEM_LANGUAGE_CHANGED, this.systemLanguageChangeHandler);
    emitter.off(CommonInnerEvent.MONTH_VIEW_DELETE_REPEATED, this.deleteHandler);
    emitter.off(CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL, this.viewDataChangeHandler);
    emitter.off(CommonInnerEvent.EVENT_FORM_DETAIL, this.formDataChangeHandler);
    emitter.off(CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH, this.cardToMonthHandler)
    if (!EmptyUtils.isEmptyString(this.instanceKey, true) && this.sourceType === AgendaDetailSource.AGENDA_PAGE) {
      const context = AgendaAbilityManager.getInstance().getAgendaContext(this.instanceKey);
      if (context) {
        context.eventHub.off(CommonEventHubCode.EVENT_UPDATE_AGENDA_NEW_PAGE, this.updatedInfoByNewWant);
      }
    }
  }

  // 视图层数据改变触发视图刷新，主要用于分栏场景右侧详情
  onViewDataChange(data: emitter.EventData): void {
    if (!data.data) {
      return;
    }
    const updateData = data.data;
    Log.info(TAG,
      `onViewDataChange ${updateData.alwaysRefreshDetail} ${updateData.eventId} ${updateData.sourceType} ${updateData.displayStartMills} ${updateData.oldEventId}`)

    // 1、非分栏场景默认不刷新；2、携带alwaysRefreshDetail参数强制刷新
    if (!this.isDivide && !updateData.alwaysRefreshDetail) {
      return;
    }

    // 非强制更新(编辑日程刷新)则不需要做变更
    if (updateData.eventId === this.eventId &&
      updateData.displayStartMills === this.displayStartMills &&
      updateData.displayEndMills === this.displayEndMills && updateData.alwaysRefreshDetail) {
      return;
    }
    //添加参数用于区分日程列表和搜索列表的刷新
    if (updateData.sourceType && updateData.sourceType !== this.sourceType) {
      return;
    }

    // 强制更新如为编辑场景即存在oldEventId则只更新对应eventId的日程
    if (updateData.alwaysRefreshDetail && updateData.oldEventId !== undefined &&
      updateData.oldEventId !== this.eventId) {
      return;
    }

    if (updateData.eventId !== this.eventId) {
      this.eventId = updateData.eventId;
    }
    if (updateData.displayStartMills !== this.displayStartMills) {
      this.displayStartMills = updateData.displayStartMills;
    }
    if (updateData.displayEndMills !== this.displayEndMills) {
      this.displayEndMills = updateData.displayEndMills;
    }
  }

  // 存储端数据改变触发视图刷新
  onSystemDataChange(data: emitter.EventData): void {
    ThrottleFunction.instance().debounceInstant(this.sourceType + TAG + this.mEventInfo.mId, (): void => {
      if ((data?.data?.table !== 'Calendars' &&
        data?.data?.table !== 'Attendees' &&
        data?.data?.table !== 'Reminders' &&
        data?.data?.table !== 'Events' &&
        data?.data?.table !== 'event_attachments') || data?.data?.isEmitFromEntryPage) {
        return;
      }
      Log.info(TAG, `On Data change, table = ${data?.data?.table}`);
      let oldEventInfo = this.mEventInfo;
      this.queryAgendaInfo(true);
      this.attachmentViewModel?.init(this.uuid);
      if (this.sourceType === AgendaDetailSource.AGENDA_LIST) { // 只有分栏场景才需要发送广播去更新日程列表
        setTimeout(() => {
          const newEventInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.mEventInfo);
          let forceUpdate = oldEventInfo.mBegin !== newEventInfo.mBegin || oldEventInfo.mEnd !== newEventInfo.mEnd;
          Log.info(TAG, `newEventInfo.mBegin(displayStartMills) = ${this.displayStartMills}, 'timeZone=${CalendarDate.timeZone}'`);
          newEventInfo.mBegin = this.displayStartMills;
          newEventInfo.mEnd = this.displayEndMills;
          let eventData: emitter.EventData = {
            data: {
              'newEventInfo': JSON.stringify(newEventInfo),
              'forceUpdate': forceUpdate
            }
          };
          emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_LIST }, eventData);
        }, EVENT_TO_UPDATE_LIST_DELAY)
      }
    }, THROTTLE_FUNC_DELAY)
  }

  /**
   * 根据帐户 ID 获取帐户信息
   * @param 帐户 ID
   */
  async initAccountInfo(id: number, calendarUuid: string) {
    let accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    const accountUuidMap = CommonService.INSTANCE.getAccountByUuidMap(accounts);
    if (!EmptyUtils.isEmptyString(calendarUuid) && accountUuidMap.hasKey(calendarUuid)) {
      this.account = accountUuidMap.get(calendarUuid);
      Log.info(TAG, `init accountInfo by calendar uuid: ${maskString(calendarUuid)}`);
    } else {
      const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
      this.account = accountMap.get(id);
    }
    if (!this.account) {
      Log.error(TAG, 'initAccountInfo get invalid account');
      return;
    }

    this.accountColor = this.account.calendarColor;
    this.accountDisName = AccountUtils.getAccountResourceStr(this.account);
    this.accountName = this.account.accountName;
    this.accountType = this.account.accountType;
    if ((this.accountName === CONTACT_BIRTHDAY_BUNDLE_NAME || this.accountName === CONTACT_BIRTHDAY_BUNDLE_NAME_2) &&
      this.accountType === CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE) {
      this.accountDisName = GlobalThis.getResourceStr($r('app.string.contact_birthday'));
    }
    this.holidayCountry = HolidayUtil.getDisplayCountry(this.accountName);
  }

  onChangedCheckId() {
    Log.log(TAG, `onChangedCheckId id: ${this.eventId}`);
    this.queryAgendaInfo().then(() => {
      // 下树上树，刷新组件
      this.isReload = true;
      SafeUtil.setTimeout(() => {
        this.isReload = false;
      }, 20);
      // 设置接续入口
      this.agendaContinue();
    });

    // 切换日程，加载buildAgenda里面的web
    if (this.eventId > 0 && this.isEventInfoReady) {
      // 滚动回到顶部
      this.scroller.scrollEdge(Edge.Start);
    }
  }

  async aboutToAppear() {
    this.isAgendaCollapse = false;
    this.subscribeEvents();
    if (this.eventId > 0) {
      this.queryAgendaInfo().then(async () => {
        AgendaUtil.logAgenda(this.mEventInfo);
        // 检测WELINK一键URL是否正确设置，辅助定位问题
        if (this.mEventInfo.mHwextServiceUri.length > 0) {
          const uri = this.mEventInfo.mHwextServiceUri.split('=')[0];
          Log.info(TAG, `welink check: ${uri.startsWith('welink')} uri length check:` +
            (uri.length === WELINK_ONE_KEY_LEN || uri.length === WELINK_MTG_ONE_KEY_LEN));
        }
        // 设置接续入口
        await this.agendaContinue();
        // this.immersiveListening(); // ShareKit 注释
      }).catch((error: Error) => {
        Log.logErrorMsg(TAG, `queryAgendaInfo error`, error);
      });
    } else {
      this.agendaContinue();
    }
    this.region = I18nUtil.getSystemRegion();
    if (this.displayStartMills === 0 || this.displayEndMills === 0) {
      // 两个参数有一个为0 时，走入
      Log.error(TAG, `No Valid Input, begin = ${this.displayStartMills}, end = ${this.displayEndMills}`);
    }

    this.isSupportEventAttachment =
      await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
  }

  aboutToDisappear() {
    // this.immersiveDisablingListening(); // ShareKit 注释
    this.unsubscribeEvents();
    this.holidayInfo = new AgendaEventInfo();
    this.agendaContinueEnd();
  }

  // 接续入口设置
  private async agendaContinue() {
    if (!this.mEventInfo) {
      Log.error(TAG, `agenda continue err eventInfo undefined`);
      return;
    }
    if (REJECT_AGENDA_SOURCE.includes(this.sourceType)) { //判断详情页的来源是否允许详情接续
      Log.info(TAG, `agenda continue reject by sourceType ${this.sourceType}`);
      return;
    }
    if (!this.context) {
      Log.error(TAG, `agenda continue get context err`);
      return;
    }
    if (this.mEventInfo.mIsHoliday || this.mEventInfo.mId < 0 || this.holidayInfo?.isHoliday()) { // 节假日程禁用接续
      Log.info(TAG, `agenga is holiday event disable continue`);
      AppContinueManager.getInstance().setAppContinueState(false, this.context);
      return;
    }
    let account = await CalendarService.INSTANCE.queryCalendarById(this.mEventInfo.mCalendarId);
    if (!account) {
      Log.error(TAG, `agenda continue reject by account undefined ${this.mEventInfo.mCalendarId}`);
      return;
    }
    const eventContinueCheck = this.checkAgendaCanContinue(this.mEventInfo, account);
    // 根据当前状态对接续与否进行设置
    AppContinueManager.getInstance().setAppContinueState(eventContinueCheck, this.context);
    if (!eventContinueCheck) {
      return;
    }
    // 接续相关参数的设置
    const pathName =
      this.sourceType === AgendaDetailSource.AGENDA_LIST ? NavPathName.AGENDA_LIST : NavPathName.AGENDA_DETAIL;
    AppContinueManager.getInstance().addContinuePage({
      pageName: pathName,
      event: this.mEventInfo,
      calendarType: account?.accountType || ''
    });
  }

  // 接续结束
  private agendaContinueEnd() {
    if (REJECT_AGENDA_SOURCE.includes(this.sourceType)) { //判断详情页的来源是否允许详情接续
      return;
    }
    const pathName =
      this.sourceType === AgendaDetailSource.AGENDA_LIST ? NavPathName.AGENDA_LIST : NavPathName.AGENDA_DETAIL;
    AppContinueManager.getInstance().removeContinuePage(pathName);
    if (!this.context) {
      return;
    }
    AppContinueManager.getInstance().setAppContinueState(true, this.context); // 恢复接续
  }

  // 用于判断日程是否允许接续
  private checkAgendaCanContinue(agendaInfo: AgendaEventInfo, account: CalendarContract.Accounts) {
    if (!CloudUtils.isCloudAppExist()) { // 不存在云空间应用
      Log.error(TAG, `agenda continue check fail isCloudAppExist`);
      return false;
    }

    if (!CloudUtils.isSupportCloudSync()) { // 设备不支持云同步
      Log.error(TAG, `agenda continue check fail isSupportCloudSync`);
      return false;
    }

    if (!CloudUtils.isCloudSyncOpened()) { // 未打开云同步开关
      Log.error(TAG, `agenda continue check fail isCloudSyncOpened`);
      return false;
    }

    if (agendaInfo.isHoliday()) { // 节假日不进行接续
      Log.error(TAG, `agenda continue check fail is Holiday`);
      return false;
    }

    // 只有默认账户下的日程和独立账户下的日程允许接续(即上云日程)
    if (!AccountUtils.isDefaultAccount(account) && !AccountUtils.isCustomAccount(account)) {
      Log.error(TAG, `agenda continue check fail is third account`);
      return false;
    }

    return true;
  }

  /**
   * @param isEditUpdate: 是否内部更新displayMills,只有在sysDateChange的时候需要去更新开始结束时间
   */
  async queryAgendaInfo(isEditUpdate = false) {
    if (this.eventId <= 0) {
      Log.error(TAG, `queryAgendaInfo eventId is error: ${this.eventId}`);
      return
    }
    this.isAcceptAgenda = false;
    const oldInfo = AgendaEventInfo.deepCloneAgendaEventInfo(this.mEventInfo);
    this.attendeeList =
      await AttendeeService.INSTANCE.queryAttendeeInfoByEventId(this.eventId) as Array<CalendarContract.Attendees>;
    let event = await EventService.INSTANCE.queryEventById(this.eventId) as AgendaEventInfo; // 临时变量存储查询的新内容，防止视图直接刷新
    event.mLatitude = await this.decryptAndParseLocation(event.mLatitudeStr);
    event.mLongitude = await this.decryptAndParseLocation(event.mLongitudeStr);
    if ((event === null) || (event === undefined) || (event.mId < 0)) { // 查不到结果时，
      Log.info(TAG, `queryAgendaInfo get invalid info for: ${this.eventId}`);
      if (!this.isDeleting && !this.isThisAgendaDeleting && !this.isThisAgendaAndBeyondDeleting) { //防止页面删除事件触发
        this.onAgendaNotFound();
      }
      return;
    }
    this.mEventInfo = event; // 确认不会返回上一级后，刷新视图，防止空数据在动效中显示
    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      this.holidayInfo = this.mEventInfo;
    } else {
      this.holidayInfo = new AgendaEventInfo();
    }
    this.getUpdatedInfo(this.mEventInfo);
    this.isImportantAlert = this.mEventInfo.alertType === CalendarContract.AgendaAlertType.IMPORTANT;
    this.mEventInfo.mAttendeeList = this.attendeeList;
    this.checkValuesArray = await this.sortCheckValueArray();
    await this.initAccountInfo(this.mEventInfo.mCalendarId, this.mEventInfo.mCalendarUuid);
    this.canEdit = this.isCanEdit();
    this.mEventInfo.checkValuesArray = this.checkValuesArray;
    this.mIsAllDay = this.mEventInfo.mIsAllDay || this.mEventInfo.isImportantEvent() || this.mEventInfo.isHoliday();
    this.mImportantEventType = this.mEventInfo.mImportantEventType;
    this.isEventInfoReady = true;
    Log.info(TAG, `queryAgendaInfo finish ${this.eventId}`);
    this.uuid = this.mEventInfo.uuid;
    // 通过校验去更新
    if (isEditUpdate && this.checkNeedUpdateMills(oldInfo, this.mEventInfo)) {
      this.displayStartMills = this.mEventInfo.mBegin;
      this.displayEndMills = this.mEventInfo.mEnd;
    }
  }

/**
   * 对传入的经纬度进行校验并返回
   *
   * @param location: 地址经纬度数据
   * @return 如果传入的经纬度为空或不能转为数字则返回-1，否则返回number
   */
  private async decryptAndParseLocation(latitudeOrLongitudeStr: string): Promise<number> {
    const invalidLocation: number = -1;
    if (EmptyUtils.isNotOrEmptyString(latitudeOrLongitudeStr, true)) {
      return invalidLocation;
    }
    try {
      let locationNum: number = Number(latitudeOrLongitudeStr);
      return isNaN(locationNum) ? invalidLocation : locationNum;
    } catch (err) {
      Log.logErrorMsg(TAG, 'decryptAndParseLocation', err);
      return invalidLocation;
    }
  }

async sortCheckValueArray() {
    let checkValuesArrays =
      await ReminderService.INSTANCE.queryReminderInfo(this.eventId) as Array<CalendarContract.Reminders>;
    return checkValuesArrays.sort((a, b) => {
      return a.remindMinutes - b.remindMinutes;
    });
  }

  // 手动处理用户点击动作对折叠屏的开合做适配，弱化变量传递，使用方式实现视图值传递，保证该视图的相对独立性
  private onActionFocusChange: (actionFocus: string) => void = (): void => {
  };

  private onDeleteSuccess: () => void = (): void => {
  };

  // EventInfo更新后需要回传给Root，保证从Root拉起编辑半模态时获取到的是最新的EventInfo
  private getUpdatedInfo: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
  };

  private onAgendaNotFound: () => void = (): void => {
  };

  private systemDataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private viewDataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  // 显示搜索框的方法
  private showSearchHandler = () => {};

  private updatedInfoByNewWant: (info: AgendaEventInfo) => void = (info: AgendaEventInfo): void => {
    this.displayStartMills = info.mBegin;
    this.displayEndMills = info.mEnd;
    Log.info(TAG, `newWant Update Info ${this.eventId} ${this.displayStartMills}`);
  };

  private formDataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    const temp = GlobalThis.getInstance().abilityWant;

    if (!this.isDivide) { // 分栏场景不需要监听卡片跳转日程变更
      if (temp?.parameters?.id) {
        let t = temp.parameters as Object as Param;
        this.eventId = t.id;
      }
    }

    // 热启刷新
    // 重复日程，使用navParam传递的instanceStartMills
    if (temp?.parameters?.instanceStartMills) {
      this.displayStartMills = Number(temp?.parameters?.instanceStartMills ?? 0);
      this.displayEndMills = Number(temp?.parameters?.instanceEndMills ?? 0);
      Log.info(TAG, `formDataChangeHandler, ${this.eventId}, ${this.displayStartMills}, ${this.displayEndMills}`);
    }
  };

  private deleteHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private systemLanguageChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.holidayCountry = HolidayUtil.getDisplayCountry(this.accountName);
  };

  private cardToMonthHandler: () => void = (): void => {
  };

  // 是否重复日程
  private isRepeatAgenda(): boolean {
    return this.mEventInfo.isRepeatEvent() as boolean;
  }

  private isCanEdit(): boolean {
    return (this.accountType === LOCAL_ACCOUNT_TYPE || this.accountType === CUSTOMER_ACCOUNT_TYPE) ? true : false;
  }

  // 通过新旧日程对比去决定是否需要刷新页面存储的开始结束时间
  private checkNeedUpdateMills(oldEventInfo: AgendaEventInfo, newEventInfo: AgendaEventInfo): boolean {
    // 非重复日程直接刷新
    if (!newEventInfo.isRepeatEvent()) {
      return true;
    }

    // 日程时间没有变化则不需要刷新
    if (oldEventInfo.mBegin === newEventInfo.mBegin && oldEventInfo.mEnd === newEventInfo.mEnd) {
      return false;
    }

    // 旧日程为重复日程则直接刷新(重复日程更新场景)
    if (oldEventInfo.isRepeatEvent()) {
      return true;
    }

    // 旧日程和新日程id相同则需要刷新(普通日程修改到重复日程场景)
    if (oldEventInfo.mId === newEventInfo.mId) {
      return true;
    }

    return false;
  }


  // ShareKit 注释 - start
  // private immersiveCallback(sharableTarget: harmonyShare.SharableTarget) {
  //   if (!this.isSupportImmersive()) {
  //     Log.info(TAG, `event not support share`);
  //     return;
  //   }
  //   Log.info(TAG, `immersiveCallback enter`);
  //   this.exportVcsByEvent(this.shareAnchorViewId, sharableTarget);
  // }

  // private immersiveListening() {
  //   if (!this.isSupportImmersive()) {
  //     Log.info(TAG, `event not support share`);
  //     return;
  //   }
  //   harmonyShare.on('knockShare', this.immersiveCallback.bind(this));
  // }

  // private immersiveDisablingListening() {
  //   if (!this.isSupportImmersive()) {
  //     Log.info(TAG, `event not support share`);
  //     return;
  //   }
  //   harmonyShare.off('knockShare', this.immersiveCallback.bind(this));
  // }
  // ShareKit 注释 - end

  private isSupportImmersive(){
    if (AccountUtils.isBirthDayAccountById(this.mEventInfo.mCalendarId)) {
      return false;
    }
    if (this.mEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      return false;
    }
    return true;
  }
}

interface Param {
  id: number;
}