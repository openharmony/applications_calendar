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
  AccountUtils,
  AgendaAbilityManager,
  AgendaEventInfo,
  AgendaListItemViewModel,
  AgendaTransitionUtil,
  AGENDA_SUB_DETAIL_WIDTH,
  behaviorEvents,
  CornerType,
  DateUtil,
  DialogControllerOptions,
  Log,
  maskString,
  NavPathManager,
  PreviewFromType,
  ReportUtil,
  RouterName,
  statisticEvents,
  TabType,
  ThrottleFunction,
  VibratorUtils,
  VibrationType,
  DeviceConfig,
  AgendaDeleteService,
  ServiceEnum,
  ServiceManager,
  FromType,
  CommonInnerEvent,
  CompId,
  CalendarContract,
  CalendarService,
  CommonService,
  CalendarAccountType,
  EmptyUtils,
  RouterModel,
  GlobalDataKeys,
} from '@app/common';
import {
  AgendaMenu,
  AgendaMenuOpt,
  AgendaListItemContent,
  AgendaEditMenuOpt,
  AgendaOperateHelper,
  generateAgendaEditOption
} from '@app/feature.agenda'
import lazy { buildUDC } from '@app/common/src/main/ets/default/util/ShareUtils';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { CACHE_SYNC_SWITCH_STATUS, CloudUtils } from '@app/common/src/main/ets/dao/CloudUtils';
import lazy { PreviewMenu } from '@app/feature.agenda/src/main/ets/AgendaPreview/view/PreviewMenu';
import lazy { PreviewContent } from '@app/feature.agenda/src/main/ets/AgendaPreview/view/PreviewContent';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { HashMap } from '@kit.ArkTS';
import lazy { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { MonthlyModeState, MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';

const SWITCH_ON: number = 1;

const TAG = 'MonthAgendaItem';

/**
 * 月视图中的日程list 的item样式
 *
 * @since 2022-11-18
 */
@Component
export struct MonthAgendaItem {
  @Consume navPathStack: NavPathStack;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Consume isOnDropAllowed: boolean;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @StorageLink(CACHE_SYNC_SWITCH_STATUS) syncSwitchStatus: number = 0;

  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

  private isSmall: boolean = true;

  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  //详情子窗打开状态存储
  @StorageLink(GlobalDataKeys.IS_SUB_WINDOW_DETAIL) isSubWindowDetail: boolean = DeviceConfig.instance().config.isDefaultSubDetail;

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  private isSubDetailCheck: boolean = DeviceConfig.instance().config.isSubDetailCheck;

  @State modeState: MonthlyModeState = MonthlyViewStateManager.getInstance().modeState;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  shareSwitchDialogController: CustomDialogController | null = new CustomDialogController({
    builder: AlertDialog({
      content: $r('app.string.share_clound_switch'),
      primaryButton: {
        value: $r('app.string.cancel_dialog_button'),
        action: () => {
        },
        fontColor: this.themeColor
      },
      secondaryButton: {
        value: $r('app.string.share_open'),
        action: () => {
          CloudUtils.jumpCloudDrivePage();
        },
        fontColor: this.themeColor
      },
    }),
    alignment: this.dialogControllerOptions.alignment,
    autoCancel: this.dialogControllerOptions.autoCancel,
  });

  @State info: AgendaListItemViewModel = new AgendaListItemViewModel();

  private radius: number = 16;

  @State geometry: string = '';

  @State transitionOption: GeometryTransitionOptions = {};

  private index: number = 0;

  @Prop isScrolling: boolean = false;

  @State isBirthdayAccount: boolean = false;

  // 菜单选项
  @State menuOpts: AgendaMenuOpt[] = [];

  // 二级编辑菜单选项
  private menuEditOpts: Array<AgendaEditMenuOpt> = [];

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private onAniStart: () => void = () => {
    this.geometry = this.getGeometryId();
    this.transitionOption = AgendaTransitionUtil.option;
  }

  private onAniEnd: () => void = () => {
    this.geometry = '';
    this.transitionOption = {};
  }

  radiusMap: Array<number[]> = [
    [0, 0, 0, 0],
    [this.radius, this.radius, 0, 0],
    [0, 0, this.radius, this.radius],
    [this.radius, this.radius, this.radius, this.radius]
  ];

  private isRightClickToDeleteAllowed: boolean = DeviceConfig.instance().config.isRightClickToDeleteAllowed;

  @Builder
  existMenu() {
    AgendaMenu({
      isSmallWindow: false,
      menuOpts: this.menuOpts,
      menuEditOpts: this.menuEditOpts,
      onCopyHandle: () => {
        emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': this.info?.mId } });
      },
      onDeleteHandle: () => {
        ServiceManager.getInstance()
          .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
          service?.notifyDeleteEvent(this.info.mId, this.info?.mBegin, true);
        });
      },
      onShareHandle: () => {
        emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
          data: {
            compId: CompId.NORMAL_AGENDA_LIST_ITEM + this.info.mId,
            eventIds: [this.info.mId]
          }
        })
      },
      onViewHandle: () => {
        this.agendaOnClick();
      },
      onEditHandle: (editType: number) => {
        this.onEditHandle(editType);
      },
    })
  }

  private onEditHandle(opt: AgendaEditMenuOpt) {
    const instanceStartMills = this.info.mBegin;
    const instanceEndMills = this.info.mEnd;
    switch (opt) {
      case AgendaEditMenuOpt.ALL_AGENDA: {
        this.mAgendaOperateHelper.editAgenda(this.info);
        break;
      }
      case AgendaEditMenuOpt.ONLY_THIS_AGENDA: {
        this.mAgendaOperateHelper.editThisAgenda(this.info, instanceStartMills, instanceEndMills);
        break;
      }
      case AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA: {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(this.info, instanceStartMills, instanceEndMills);
        break;
      }
    }
  }

  build() {
    Column() {
      AgendaListItemContent({
        viewType: TabType.MONTH,
        info: this.info,
        isScrolling:this.isScrolling,
        inMonthView: true,
      })
    }
    .width('100%')
    .borderRadius({
      topLeft: this.radiusMap[this.info?.mCornerType as number][0],
      topRight: this.radiusMap[this.info?.mCornerType as number][1],
      bottomLeft: this.radiusMap[this.info?.mCornerType as number][2],
      bottomRight: this.radiusMap[this.info?.mCornerType as number][3],
    })
    .bindContextMenu(this.modeState.isInSmallFold
      ? null
      : this.PreviewMenuBuilder(this.info), ResponseType.LongPress,
      {
        preview: this.PreviewContentBuilder(this.info),
        previewAnimationOptions: {
          scale: [0.95, 1.0],
          hoverScale: [1.0, 0.95]
        },
        placement: this.isSmall ? Placement.BottomLeft : Placement.Left,
        aboutToAppear:()=>{
          //触发震动
          VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
        },
      })
    .bindContextMenu(this.existMenu(), ResponseType.RightClick)
    .onMouse((ev) => {
      if (ev.button === MouseButton.Right && ev.action === MouseAction.Press) {
        this.generateAgendaOption();
      } else if (ev.button === MouseButton.Left && ev.action === MouseAction.Press) {
        this.isOnDropAllowed = false;
      } else if (ev.button === MouseButton.Left && ev.action === MouseAction.Release) {
        this.isOnDropAllowed = true;
      }
    })
    .onPreDrag((status: PreDragStatus)=>{
      // READY_TO_TRIGGER_DRAG_ACTION：拖拽准备完成，可发起拖拽阶段。(按下500ms时触发)
      if (status == PreDragStatus.READY_TO_TRIGGER_DRAG_ACTION) {
        this.isOnDropAllowed = false;
      }
    })
    .onDragStart((event: DragEvent) => {
      this.isOnDropAllowed = false;
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.info);
      //触发震动
      VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
    })
    .onDragEnd(() => {
      this.isOnDropAllowed = true;
    })
    .borderRadius($r('sys.float.corner_radius_level10'))
    .draggable(true)
    .geometryTransition(this.geometry, this.transitionOption)
    .accessibilityLevel('yes')
    .accessibilityText(this.info.getAccessibilityText())
    .accessibilityGroup(true)
    .onClick(() => {
      this.agendaOnClick();
    })
    .id(this.info.getEditAblePropStr())
    .focusBox({ margin: LengthMetrics.vp(-2) })
  }

  @Builder
  PreviewMenuBuilder(info: AgendaEventInfo) {
    if (info.isSupportShare()) {
      PreviewMenu({
        info
      })
    }
  }

  @Builder
  PreviewContentBuilder(info: AgendaEventInfo) {
    PreviewContent({
      info,
      previewFromType: PreviewFromType.MONTH_VIEW,
      displayStartMills: info?.mBegin,
      displayEndMills: info?.mEnd,
      onPreviewClick: () => {
        ContextMenu.close();
        setTimeout(() => {
          this.agendaOnClick();
        }, 300)
      }
    }).borderRadius($r('sys.float.corner_radius_level12'))
  }

  agendaOnClick() {
    Log.warn(TAG, `on click id = ${this.info?.mId}, title: ${maskString(this.info.mTitle)}, ` +
      `begin = ${this.info?.mBegin}, end = ${this.info?.mEnd}`);
    if (AccountUtils.isBirthDayAccountById(this.info.mCalendarId)) {
      Log.info(TAG, 'click to contact detail');
      return;
    }
    if (this.modeState.isInSmallFold || this.needCommerce) {
      this.toListPage(this.info);
    } else {
      if (!this.info?.mEnd || !this.info?.mBegin) {
        // 两个参数有一个为0 或 不存在时，走入
        Log.error(TAG, `No Valid Input, begin = ${this.info?.mBegin}, end = ${this.info?.mEnd}`);
      }
      const canJumpDetailPop = this.checkCanOpenDetailPop();
      Log.info(TAG,
        `jump to agenda detail pop: ${this.isSubWindowDetail} ${this.isSubDetailCheck} ${this.windowWidth}`);
      if (this.isSubWindowDetail && canJumpDetailPop) {
        this.jumpToPopDetail();
      } else {
        this.agendaTransitionUtil.buildEventDetail(this.info, FromType.MONTH_VIEW, canJumpDetailPop);
        this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), true, this.onAniStart, this.onAniEnd);
      }
    }
    ReportUtil.reportStatisticEvent(statisticEvents.monthCardViewAgendaDetail);
  }

  jumpToPopDetail() {
    const param: Record<string, number | string | boolean | AgendaEventInfo> = {};
    param.id = this.info.mId;
    if (this.info.mIsHoliday) {
      param.holidayInfo = this.info;
    }
    param.instanceStartMills = this.info.mBegin;
    param.instanceEndMills = this.info.mEnd;
    param.fromType = FromType.MONTH_VIEW;
    param.source = 'CLICK_MONTH_SHARE_AGENDA';
    param.isMessageResource = this.info.isMessageResource;
    param.isPopShrink = false;
    param.isHoliday = this.info.mIsHoliday ?? false;
    param.holidayTitle = this.info.mTitle;
    const routerData: RouterModel = {
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: param
    }
    const eventData: emitter.EventData = {
      data: routerData
    };
    emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_TO_POPUP }, eventData);
  }

  toListPage(info: AgendaEventInfo) {
    if (this.needCommerce) {
      AgendaAbilityManager.getInstance()
        .startAbilityByEventId(info.mId, info.mBegin, info.mEnd, info.mIsHoliday,
          info.mTitle);
      return;
    }

    try {
      ThrottleFunction.instance().throttle(TAG, (): void => {
        const param: Record<string, string | number | boolean | AgendaEventInfo> = {};
        param.id = info?.mId;
        param.holidayInfo = this.info;
        param.instanceStartMills = info?.mBegin;
        param.instanceEndMills = info?.mEnd;
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_DETAIL,
          routerName: RouterName.ENTRY_HAP,
          param: param
        });
        return;
      }, 200)
    } catch (err) {
      Log.logErrorMsg(TAG, `jump to detail path err`, err);
    }
  }

  // 判断是否能够打开详情子窗
  checkCanOpenDetailPop() {
    return !this.isSubDetailCheck || this.windowWidth >= AGENDA_SUB_DETAIL_WIDTH;
  }


  getHotspotPaddingTop(): number {
    if (this.info?.mCornerType === CornerType.CORNER_NONE || this.info?.mCornerType === CornerType.CORNER_DOWN) {
      return 0;
    }
    return 4;
  }

  getHotspotPaddingBottom(): number {
    if (this.info?.mCornerType === CornerType.CORNER_NONE || this.info?.mCornerType === CornerType.CORNER_UP) {
      return 0;
    }
    return 4;
  }

  getGeometryId(): string {
    const extraId = // 跨天重复日程需要额外的mBegin用于区分同一天的不同日程
      (EmptyUtils.isEmptyString(this.info?.mRepeatRule) && this.info?.mStartDay !== this.info?.mEndDay ? 0 :
        this.info?.mBegin);
    return '' + this.info?.mId + '-' + this.index + '-' + extraId;
  }

  aboutToAppear() {
    const currentJulianDay: number = DateUtil.getJulianDay();
    if (this.agendaTransitionUtil.formerId === this.getGeometryId()) {
      Log.info(TAG, `init agenda transition ${this.index} ${this.agendaTransitionUtil.formerId}`);
      this.onAniStart();
    }
    Log.info(TAG, `currentJulianDay ==${currentJulianDay}, instanceId ==${this.info?.mId}`);
  }

  async generateAgendaOption() {
    if (this.menuOpts.length > 0) {
      return;
    }
    const event = this.info;

    if (!event || !this.isRightClickToDeleteAllowed) {
      this.menuOpts = [];
      return;
    }
    let menuOpt: AgendaMenuOpt[] = [];
    menuOpt.push(AgendaMenuOpt.VIEW);

    let accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
    const accountType = accountMap.get(event.mCalendarId)?.accountType;

    if (!event.isHoliday()) {
      menuOpt.push(AgendaMenuOpt.COPY);
    }

    // 不是服务日程和节假日可分享
    if (!event.mHwextServiceType && !event.isHoliday() && accountType !== CalendarAccountType.EMAIL_ACCOUNT_TYPE) {
      menuOpt.push(AgendaMenuOpt.SHARE);
    }

    if (event.mHwextServiceType === 'Meeting') {
      menuOpt.push(AgendaMenuOpt.SHARE);
    }

    if (!event.mHwextServiceType && !event.isHoliday() && accountType !== CalendarAccountType.EMAIL_ACCOUNT_TYPE) {
      menuOpt.push(AgendaMenuOpt.EDIT);
    }

    // 不是节假日可删除
    if (!event.isHoliday()) {
      menuOpt.push(AgendaMenuOpt.DELETE);
    }
    this.menuOpts = menuOpt;
    this.menuEditOpts = generateAgendaEditOption(this.info);
    return;
  }
}