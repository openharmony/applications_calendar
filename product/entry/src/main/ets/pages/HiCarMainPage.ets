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
  AgendaDeleteService,
  AgendaEventInfo,
  BigFontSize,
  ButtonImageType,
  ButtonLayoutParam,
  CalendarContract,
  CalendarDate,
  CalendarLayoutManager,
  CalendarService,
  CloudUtils,
  CommonInnerEvent,
  CommonService,
  DateInfo,
  DateTitleUtil,
  DateUtil,
  DialogControllerOptions,
  EmitterCollector,
  EventService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  isSyncAbleAccount,
  Log,
  ModeUtil,
  MonthlyInfo,
  NavPathManager,
  NavPathName,
  RouterName,
  ServiceEnum,
  ServiceManager,
  TabType,
  UnusualMode
} from '@app/common';
import { BackToTodayToolbarButton, CommonTextDialog, ImageButton } from '@app/common.components';
import { DateTitle } from '../common/comp/DateTitle';
import { MainTabComponent } from './MainTabComponent';
import { ActionType, EmitterFormHandler, ParametersInter } from './EmitterFormHandler';
import { LengthMetrics } from '@kit.ArkUI';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { DeleteAgendaRadio, DeleteMode } from '@app/feature.agenda';
import {
  MonthlyViewTemporaryAgendaData
} from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewTemporaryAgendaData';
import { SingleMonthAgendaManager } from '@app/feature.monthview/src/main/ets/viewmodel/SingleMonthAgendaManager';
import { MonthlyViewStateManager } from '@app/feature.monthview/src/main/ets/viewmodel/MonthlyViewState';

const TAG = 'HiCarMainPage';

@Builder
export function hiCarMainPageLoader() {
  HiCarMainPage();
}

@Component
export struct HiCarMainPage {
  @Provide isAnimation: boolean = false;
  @Provide isOnDropAllowed: boolean = false;
  @Provide isMaximizeRecovery: boolean = false; // 窗口是否最大化恢复
  @Provide hideAgendaWindowMonth: boolean = true; // 月视图是否隐藏日程列表
  @Provide hideAgendaWindowDay: boolean = true; // 日视图是否隐藏日程详情
  @Provide needShowHideButton: boolean = false; // 是否需要显示详情开合按钮
  @Provide keyCtrlState: boolean = false; // Ctrl 键的状态
  @StorageProp('themeColor') themeColor: string = '';
  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;
  // 全局展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) @Watch('onDisplayDateChange') displayMills: number = 0;

  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  // 是否显示回到今天
  @State showBackToTodayButton: boolean = false;

  @State buttonFlag: boolean = false; // 按钮标识位,无实际意义

  @State buttonLayout: ButtonLayoutParam = CalendarLayoutManager.getInstance().buttonLayout;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

  private deleteAgenda: AgendaEventInfo | undefined = undefined; // 要删除的agenda

  private deleteTimestamp: number = -1; // 涉及删除的时间

  private deleteAccountType: string = '';

  private agendaDeleteService: AgendaDeleteService | undefined = undefined;

  private emitterCollector : EmitterCollector = new EmitterCollector();

  // 当前展示的日期
  @StorageLink(GlobalDataKeys.DISPLAY_DATE) displayDate: number = 0;

  // tab页签索引，无缓存情况下首次进入日历应用显示月视图
  @State tabsIndex: number = TabType.MONTH;

  @StorageLink('language') language: string = '';

  // 删除重复日程弹框
  deleteRepeatAgendaDialogController: CustomDialogController | null = new CustomDialogController({
    builder: DeleteAgendaRadio({
      confirm: (checkValue) => {
        if (!this.deleteAgenda) {
          return;
        }
        if (checkValue === DeleteMode.ONLY_THIS_AGENDA) {
          this.agendaDeleteService?.addExclusiveToRepeatRule(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else if (checkValue === DeleteMode.THIS_AND_FUTURE_AGENDA) {
          this.agendaDeleteService?.updateEndTime(this.deleteAgenda?.mId, this.deleteTimestamp);
        } else {
          this.agendaDeleteService?.deleteEvent(this.deleteAgenda.mId);
        }
      },
      showCloudSyncTip: isSyncAbleAccount('', this.deleteAccountType) &&
      CloudUtils.isSupportCloudSync() && CloudUtils.isCloudSyncOpened(),
      title: this.agendaDeleteService?.getDeleteAgendaDialogTitle(this.deleteAgenda?.mTitle || ''),
      isFirstRepeatAgenda: this.deleteAgenda?.mBegin === this.deleteTimestamp,
    }),
    alignment: DialogAlignment.Center,
  });

  // 删除非重复日程弹框
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: this.agendaDeleteService?.getDeleteMessage(this.deleteAgenda, this.deleteAccountType),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        if (!this.deleteAgenda) {
          return;
        }
        this.agendaDeleteService?.deleteEvent(this.deleteAgenda?.mId);
      },
      onCancelClick: () => {
        Log.info(TAG, 'click cancel');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  private deleteAgendaHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.deleteEvent(data);
  };

  // 判断回到今天按钮是否显示
  private onDisplayDateChange() {
    const displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    const julianDayOfDisplayDate = DateUtil.getJulianDay(displayDate)
    if (julianDayOfDisplayDate === DateUtil.getJulianDay(Date.now())) {
      this.showBackToTodayButton = false;
    } else {
      this.showBackToTodayButton = true;
    }
  }

  aboutToAppear(): void {
    Log.info(TAG, `aboutToAppear ${this.unusualMode}`);
    this.getMonthlyAgenda(); // verde小屏需要做月视图日程数据初始化
    let tempOne: Object | undefined = GlobalThis.getInstance().abilityWant?.parameters;
    let tempTwo: ParametersInter | undefined = tempOne ? tempOne as ParametersInter : undefined;
    EmitterFormHandler.instance().parseWantParams(tempTwo ? tempTwo.action as ActionType : undefined, tempTwo);
    EmitterFormHandler.instance().emitterForm();
    this.emitterCollector.on({ eventId: CommonInnerEvent.DELETE_AGENDA }, this.deleteAgendaHandler);
    ServiceManager.getInstance()
      .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE)
      .then((service) => {
        this.agendaDeleteService = service;
      })
      .catch((err: BusinessError) => {
        Log.logErrorMsg(TAG, `getDeleteSerivce err:`, err);
      });
    // 内屏接续至外屏，需要判断一次回到今天按钮是否显示
    this.onDisplayDateChange();
  }

  getMonthlyAgenda() {
    // 查询日程数据
    const displayDate: CalendarDate = new CalendarDate(new Date().getTime());
    const dateInfo = new DateInfo(displayDate.getFullYear(), displayDate.getMonth() + 1);
    const curMonthlyInfo = new MonthlyInfo(dateInfo.year, dateInfo.month,
      MonthlyViewStateManager.getInstance().state.startOfWeek);

    this.getCurrentMonthAgenda(curMonthlyInfo.getLast(), 0);
    this.getCurrentMonthAgenda(curMonthlyInfo, 1);
    this.getCurrentMonthAgenda(curMonthlyInfo.getNext(), 2);
  }

  async getCurrentMonthAgenda(curMonthlyInfo: MonthlyInfo, index: number) {
    const tmpAgendaData = MonthlyViewTemporaryAgendaData.getInstance();
    tmpAgendaData.agendaList[index] = await SingleMonthAgendaManager.queryAndProcessAgendaData(curMonthlyInfo);
    tmpAgendaData.flagList[index] = true;
  }

  aboutToDisappear(): void {
    EmitterFormHandler.instance().unEmitterForm();
    this.emitterCollector.off();
  }

  private deleteEvent(data: emitter.EventData): void {
    let eventId: number | undefined = data.data?.eventId;
    let deleteTimestamp: number | undefined = data.data?.timestamp;
    let isMainAbility: boolean | undefined = data.data?.isMainAbility ?? true;
    // deleteTimestamp 用于删除重复日程的重复规则,isMainAbility判断是否在mainAbility发起
    if (eventId == undefined || deleteTimestamp == undefined || !isMainAbility) {
      return;
    }
    EventService.INSTANCE.queryEventById(eventId).then(async (event) => {
      if (event) {
        let accounts = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
        let accountMap = CommonService.INSTANCE.getAccountMap(accounts);
        let accountInfo  = accountMap.get(event.mCalendarId);
        if (!accountInfo) {
          Log.error(TAG, 'Account type not found for calendarId: ' + event.mCalendarId);
          return;
        }
        this.deleteAccountType = accountInfo.accountType;
        this.deleteAgenda = event;
        this.deleteTimestamp = deleteTimestamp||0;
        Log.info(TAG, `delete agenda ${this.deleteAgenda.mId}-${this.deleteTimestamp}-${this.deleteAccountType}`);
        if (event.isRepeatEvent() && !event.isImportantEvent()) {
          this.deleteRepeatAgendaDialogController?.open();
        } else {
          this.deleteDialogController?.open();
        }
      }
    })
  }

  getDateTitleText(): ResourceStr {
    return DateTitleUtil.formatTitle(this.displayDate, this.tabsIndex, this.language);
  }

  @Builder
  jumpToAgendaListButton() {
    ImageButton({
      image: $r('app.media.events_list'),
      flagChanged: this.buttonFlag,
      buttonBackgroundColor: $r('sys.color.comp_background_tertiary'),
      promptText: $r('app.string.show_all_agenda'),
      buttonImageType: ButtonImageType.IMAGE,
      onButtonClick: () => {
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_LIST,
          routerName: RouterName.ENTRY_HAP,
          param: {}
        })
      }
    })
      .margin({ start: LengthMetrics.vp(8) })
  }

  build() {
    Column() {
      Row() {
        DateTitle({
          dateTitleText: this.getDateTitleText(),
          tabsIndex: this.tabsIndex,
          textHeight: this.buttonLayout.menuHeight,
          needPadding: false
        })
          .accessibilityText($r('app.string.click_date_hit_text', this.getDateTitleText()));
        Blank()
        if (this.showBackToTodayButton) {
          BackToTodayToolbarButton();
        }
        if (ModeUtil.isSmallUpDownFoldMode(this.unusualMode)) {
          this.jumpToAgendaListButton();
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ start: LengthMetrics.vp(8), end: LengthMetrics.vp(16) })

      MainTabComponent();
    }
    .backgroundColor($r('sys.color.background_secondary'))
    .padding({ top: Math.max(this.windowAvoidAreaTopRectHeight - 8, 8), bottom: 0 })
    .height('100%')
  }
}