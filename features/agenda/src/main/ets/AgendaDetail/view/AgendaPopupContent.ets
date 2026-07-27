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

/**
 * 公用日程弹窗内容
 *
 * @since: 2023/5/12
 */

import intl from '@ohos.intl';
import lazy { promptAction } from '@kit.ArkUI';
import emitter from '@ohos.events.emitter';
import {
  AgendaEventInfo,
  DateUtil,
  AgendaDataSource,
  DialogControllerOptions, TabType,
  statisticEvents,
  HiEventParamsConfirm, ReportHiEventParams, ReportUtil,
  CommonInnerEvent,
  GlobalThis,
  CalendarContract,
  NavPathName,
  EventService,
  ReminderService,
  Log,
  LunarDateUtil,
  DeviceConfig,
  NavPathManager,
  RouterName,
  ServiceManager,
  ServiceEnum,
  AgendaListItemViewModel,
  AgendaDeleteService,
  CalendarService,
  CommonService,
  CalendarAccountType,
  EmitterCollector,
  AccountUtils,
  ThrottleFunction,
  AgendaAbilityManager,
  CalendarDate
} from '@app/common';
import { CommonTextDialog } from '@app/common.components/src/main/ets/CommonTextDialog';
import { AgendaListItemContent } from './AgendaListItemContent'
import lazy { KeyCode } from '@ohos.multimodalInput.keyCode';
import lazy { accessibility } from '@kit.AccessibilityKit';
import { HashMap } from '@kit.ArkTS';
import { LengthMetrics } from '@kit.ArkUI';
import { i18n } from '@kit.LocalizationKit';

const TAG: string = 'AgendaPopup';

const PHONE_WIDTH: number = 306;
const PC_WIDTH: number = 400;
const PC_MULTI_MAX_HEIGHT: number = 265;
const PHONE_MULTI_MAX_HEIGHT: number = 182;

/**
 * 获取时间串
 *
 * @param stamp 时间戳
 * @return 国际化后的时间串
 */
function getTimeStr(stamp: number): string {
  const opt: intl.DateTimeOptions = { hour: 'numeric', minute: '2-digit', hour12: !AppStorage.get<boolean>('is24HourClock') };
  return DateUtil.intlDateFormatChineseStyle(new CalendarDate(stamp), opt);
}

/**
 * 获取国际化日期串
 *
 * @param stamp 时间戳
 * @return 国际化后的日期串
 */
function getDateStr(stamp: number): string {
  const opt: intl.DateTimeOptions = { month: 'long', day: 'numeric', weekday: 'long' };
  return DateUtil.intlDateFormatChineseStyle(new CalendarDate(stamp), opt);
}

/**
 * 获取资源串
 *
 * @param resource 资源
 * @return 资源文本
 */
function getResourceStr(resource: Resource, language?: string): string {
  return GlobalThis.getResourceStr(resource, language);
}

interface MenuContent {
  content: ResourceStr;
  hint: ResourceStr;
};

@Extend(Menu)
function menuCommerceStyle(needCommerce: boolean) {
  .radius(needCommerce ? 8 : undefined)
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}

/**
 * 单个日程弹窗内容
 */
@Component
struct SingleAgendaContent {
  info: AgendaEventInfo = new AgendaEventInfo();

  @State infoModel: AgendaListItemViewModel | undefined = undefined;

  date: number = 0;

  isSmallWindow: boolean = false;

  titleText: string = '';

  locationText: string = '';

  agendaMaxWidth: number = 0;

  isMultiAgenda: boolean = false;

  singleAgendaMargin: Margin = {};

  agendaMargin: Margin = {};

  isWeekView: boolean = false;

  //卡片弹窗是否有边框 true:无边框
  borderless: boolean = false;

  // 是否折叠弹窗
  private isFold: boolean = false;

  @State agendaWidth: number = 0;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  private emitterCollector : EmitterCollector = new EmitterCollector();

  private needStack: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //删除窗口
  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.string.delete_this_event_title'),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        this.deleteEventById();
        this.reportPopupStatistic(this.info?.mImportantEventType || 0, HiEventParamsConfirm.TRUE)
      },
      onCancelClick: () => {
        this.reportPopupStatistic(this.info?.mImportantEventType || 0, HiEventParamsConfirm.FALSE)
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  private onClickContent: () => void = () => {
  };

  private cardToMonthHandler: () => void = () => {
  };

  private closeDialog: () => void = () => {
  };

  aboutToAppear() {
    this.infoModel = new AgendaListItemViewModel(this.info);
    if (this.isFold) {
      const nowDay = DateUtil.getJulianDay(this.date);
      this.infoModel.setFlag(nowDay);
    }
    this.infoModel.mIsAllDay = this.infoModel.mIsAllDay || this.infoModel.isHoliday();
    this.titleText = this.info.mTitle;
    this.locationText = this.info.mLocation ? this.info.mLocation : '';

    this.calculateAgendaWidth();
    this.subscribeEvents();

    if (!this.isMultiAgenda) {
      setTimeout(() => {
        let eventInfo: accessibility.EventInfo = ({
          type: 'requestFocusForAccessibility',
          bundleName: 'com.openharmony.calendar',
          triggerAction: 'common',
          customId: 'single_agenda_title' + this.info?.mId || this.titleText
        });

        accessibility.sendAccessibilityEvent(eventInfo);
      }, 100);
    }
  }

  //计算日程块宽度
  calculateAgendaWidth(): void {
    const singleAgendaMarginLeft: number = Number(this.singleAgendaMargin?.left); //单个日程左边距
    const agendaMargin: number = Number(this.agendaMargin?.left); //+n日程块边距
    const singleAgendaMarginRight: number = Number(this.singleAgendaMargin?.right); //单个日程右边距

    const popMaxWidth = this.isSmallWindow ? PHONE_WIDTH : PC_WIDTH;
    const padding = 16;
    this.agendaWidth = popMaxWidth - 16;
  }

  async subscribeEvents() {
    this.cardToMonthHandler = () => {
      this.deleteDialogController?.close();
    };
    this.closeDialog = () => {
      this.deleteDialogController?.close();
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closeDialog);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
    this.deleteDialogController = null;
  }

  async toEventDetail() {
    let isBirthday = await AccountUtils.isBirthDayAccountByIdAsync(this.info.mCalendarId);
    if (isBirthday) {
      return;
    }
    if (this.needCommerce) {
      AgendaAbilityManager.getInstance()
        .startAbilityByEventId(this.info.mId, this.info.mBegin, this.info.mEnd, this.info.mIsHoliday,
          this.info.mTitle);
      return;
    }
    const param: Record<string, number | string | boolean | AgendaEventInfo> = {};
    param.id = this.info.mId;
    param.holidayInfo = this.info;
    param.instanceStartMills = this.info?.mBegin;
    param.instanceEndMills = this.info?.mEnd;
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: RouterName.ENTRY_HAP,
      param: param
    })
    ReportUtil.reportStatisticEvent(statisticEvents.weekPopupViewAgendaDetail);
  }

  reportPopupStatistic(type: number, isSave: number) {
    let params: ReportHiEventParams = {
      TYPE: type,
      IS_SAVE: isSave
    }
    ReportUtil.reportStatisticEvent(statisticEvents.deleteAgendaSavePopup, params);
  }

  async deleteEventById() {
    if (this.info?.mId) {
      const rowsDeleted = await EventService.INSTANCE.deleteEventById(this.info?.mId) as number;
      if (rowsDeleted > 0) {
        Log.info(TAG, `delete by id success ${this.info?.mId}`);
      } else {
        Log.warn(TAG, 'delete by id fail');
      }
    }
  }

  build() {
    Stack() {
      AgendaListItemContent({
        viewType: this.isWeekView ? TabType.WEEK : TabType.MONTH,
        info: this.infoModel,
        needShowConflict: false,
        singleAgendaMargin: this.singleAgendaMargin,
        isPopup: true,
        borderless: this.borderless,
      })
      if (this.needStack) {
        Column()
          .borderRadius($r('sys.float.corner_radius_level10'))
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .width('90%')
          .height(58)
          .markAnchor({ y: -10 })
          .zIndex(1)
          .opacity(0.6)
      }
    }.align(Alignment.Bottom)
    .id('single_agenda_title' + this.info?.mId || this.titleText)
    .width(this.isMultiAgenda ? '100%' : this.agendaWidth)
    .constraintSize({ minHeight: 40 })
    .accessibilityGroup(true)
    .padding({ bottom: this.needStack ? 10 : 0 })
    .onClick(() => {
      this.toEventDetail();
      if (this.onClickContent) {
        this.onClickContent();
      }
    })
    .onKeyEvent((event: KeyEvent) => { // 焦点按键触发事件
      if (event.type === KeyType.Up) {
        if (event.keyCode === KeyCode.KEYCODE_FORWARD_DEL) { //删除
          if (this.info?.mId != -1) {
            this.deleteDialogController?.open();
          } else {
            promptAction.showToast({
              message: $r('app.string.agenda_can_not_delete')
            })
          }
        }
        if (this.onClickContent) {
          this.onClickContent();
        }
      }
    })
  }
}

/**
 * 多个日程弹窗内容
 */
@Component
struct MultiAgendaContent {
  @State agendaMargin: Margin = { left: 8, right: 8 }

  @State solarDateStr: string = '';

  @State solarWeekStr: string = '';

  @State lunarDateStr: string = '';

  // 窗口大小
  @LocalStorageProp('windowHeight') windowHeight: number = 0;

  infoList: Array<AgendaEventInfo> = [];

  date: number = 0;

  isSmallWindow: boolean = false;

  dataSource: AgendaDataSource = new AgendaDataSource([]);

  isWeekView: boolean = false;

  //卡片弹窗是否有边框 true:无边框
  borderless: boolean = false;

  @StorageLink('language') @Watch('onLanguageChanges') language: string = '';

  private mScroller = new Scroller();

  private isPreview: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onClickContent: () => void = () => {
  };

  private onHoverHandler: (isHover: boolean) => void = (isHover: boolean) => {
  };

  aboutToAppear() {
    const opt: intl.DateTimeOptions = { month: 'long', day: 'numeric' };
    const optWeek: intl.DateTimeOptions = { weekday: 'long' };
    this.solarDateStr = DateUtil.intlDateFormatChineseStyle(new CalendarDate(this.date), opt);
    this.solarWeekStr = DateUtil.intlDateFormatChineseStyle(new CalendarDate(this.date), optWeek);
    this.lunarDateStr = LunarDateUtil.toLunarDateString(new CalendarDate(this.date));
    this.dataSource = new AgendaDataSource(this.infoList);

    setTimeout(() => {
      let eventInfo: accessibility.EventInfo = ({
        type: 'requestFocusForAccessibility',
        bundleName: 'com.openharmony.calendar',
        triggerAction: 'common',
        customId: 'MultiAgendaContentTitle'
      });

      accessibility.sendAccessibilityEvent(eventInfo);
    }, 100);
  }

  onLanguageChanges() {
    const opt: intl.DateTimeOptions = { month: 'long', day: 'numeric' };
    const optWeek: intl.DateTimeOptions = { weekday: 'long' };
    this.solarDateStr = DateUtil.intlDateFormatChineseStyle(new CalendarDate(this.date), opt);
    this.solarWeekStr = DateUtil.intlDateFormatChineseStyle(new CalendarDate(this.date), optWeek);
  }

  //是否为跨天日程
  isInterDay(info: AgendaEventInfo): boolean {
    return info.mStartDay !== info.mEndDay;
  }

  build() {
    Column() {
      this.buildTitle();
      if (this.isPreview) {
        this.buildPreview();
      } else {
        this.buildList();
      }
    }
    .onHover((isHover) => {
      this.onHoverHandler(isHover);
    })
    .width(this.isSmallWindow ? PHONE_WIDTH : PC_WIDTH)
    .margin({
      start: LengthMetrics.vp(12),
      end: LengthMetrics.vp(0),
      top: LengthMetrics.vp(4),
      bottom: LengthMetrics.vp(10)
    })
  }

  @Builder
  buildList() {
    Row() {
      List({ scroller: this.mScroller, space: 8 }) {
        LazyForEach(this.dataSource, (info: AgendaEventInfo) => {
          ListItem() {
            SingleAgendaContent({
              info,
              date: this.date,
              isFold: true,
              isSmallWindow: this.isSmallWindow,
              onClickContent: this.onClickContent,
              isMultiAgenda: true,
              agendaMargin: this.agendaMargin,
              isWeekView: this.isWeekView,
              borderless: this.isInterDay(info)
            })
          }
          .width('100%')
        })
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
      .width('calc(100% - 12vp)')
      .constraintSize({ maxHeight: this.needCommerce ? PC_MULTI_MAX_HEIGHT : PHONE_MULTI_MAX_HEIGHT })
      .align(Alignment.Start)
      .scrollBar(BarState.Off)

      ScrollBar({ scroller: this.mScroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .width(12)
        .height(this.dataSource.totalCount() * 72)
        .constraintSize({ maxHeight: this.needCommerce ? PC_MULTI_MAX_HEIGHT : PHONE_MULTI_MAX_HEIGHT })
    }
    .margin({ top: 10 })
  }

  @Builder
  buildPreview() {
    Row() {
      List({ scroller: this.mScroller, space: 8 }) {
        ForEach(this.infoList, (info: AgendaEventInfo, index: number) => {
          if (index < 3) {
            ListItem() {
              SingleAgendaContent({
                info,
                date: this.date,
                isFold: true,
                isSmallWindow: this.isSmallWindow,
                onClickContent: this.onClickContent,
                isMultiAgenda: true,
                agendaMargin: this.agendaMargin,
                isWeekView: this.isWeekView,
                needStack: index === 2 && this.infoList.length > 3,
              })
            }
            .width('100%')
          }
        })
      }
      .borderRadius($r('sys.float.corner_radius_level10'))
      .width('calc(100% - 12vp)')
      .align(Alignment.Start)
      .scrollBar(BarState.Off)
    }
    .margin({ top: LengthMetrics.vp(12), end: LengthMetrics.vp(12) })
  }

  @Builder
  buildTitle() {
    Flex({ wrap: FlexWrap.Wrap, alignItems: ItemAlign.Center }) {
      Text(this.solarDateStr)
        .textAlign(TextAlign.Start)
        .align(Alignment.Bottom)
        .constraintSize({ minHeight: 26 })
        .fontSize($r('sys.float.Body_L'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary'))
        .fontFamily('HarmonyHeiTi')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.solarWeekStr)
        .textAlign(TextAlign.Start)
        .align(Alignment.Bottom)
        .constraintSize({ minHeight: 26 })
        .fontSize($r('sys.float.Caption_L'))
        .fontWeight(FontWeight.Regular)
        .fontColor($r('sys.color.font_tertiary'))
        .fontFamily('HarmonyHeiTi')
        .margin({ start: LengthMetrics.vp(6) })
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(this.lunarDateStr)
        .width('100%')
        .textAlign(i18n.isRTL(i18n.getSystemLocale()) ? TextAlign.End : TextAlign.Start)
        .align(Alignment.Center)
        .fontSize($r('sys.float.Caption_L'))
        .fontColor($r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
    }
    .accessibilityGroup(true)
    .id('MultiAgendaContentTitle')
  }
}

export enum AgendaMenuOpt {
  VIEW, // 查看
  COPY, // 复制
  SHARE, // 分享
  PASTE, // 粘贴
  EDIT, // 编辑
  DELETE, // 删除
  CREATE, // 创建
  MULTISELECT, // 多选
}

export const DEFAULT_AGENDA_MENU_OPTS: Array<AgendaMenuOpt> = [
  AgendaMenuOpt.VIEW,
  AgendaMenuOpt.COPY,
  AgendaMenuOpt.SHARE,
  AgendaMenuOpt.PASTE,
  AgendaMenuOpt.EDIT,
  AgendaMenuOpt.DELETE,
  AgendaMenuOpt.CREATE,
  AgendaMenuOpt.MULTISELECT,
];

@Component
struct AgendaMenuContent {
  @Consume navPathStack: NavPathStack;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 日程信息 单个日程或者日程数组
  info: AgendaEventInfo | undefined = undefined;

  // 是否手机端
  isSmallWindow: boolean = false;

  // 弹窗当前指向的时间戳
  date: number = 0;

  // 菜单选项
  @Prop menuOpts: AgendaMenuOpt[] = DEFAULT_AGENDA_MENU_OPTS;

  //是否需要保留传入时分
  needSaveTime: number = 0;

  // 新建编辑弹窗为pop,不需要跳转逻辑
  showPop: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  menuText: Array<MenuContent> = [
    { content: $r('app.string.agenda_menu_item_view'), hint: '' },
    { content: $r('app.string.copy'), hint: '' },
    { content: $r('app.string.agenda_menu_item_share'), hint: ''},
    { content: $r('app.string.paste'), hint: '' },
    { content: $r('app.string.agenda_menu_item_edit'), hint: '' },
    { content: $r('app.string.agenda_menu_item_delete'), hint: '' },
    { content: $r('app.string.agenda_menu_item_create'), hint: ''},
    { content: $r('app.string.multiple_choice'), hint: ''}
  ];

  onPasteHandle: () => void = (): void => {
  };

  onShareHandle: () => void = (): void => {
  };

  // 菜单选择回调
  onMenuChosen: (op: AgendaMenuOpt, id: number) => void = (op: AgendaMenuOpt, id: number) => {
  };


  handler: Array<() => void> = [
    () => { // AgendaMenuOpt.VIEW
      if (!this.info) {
        return;
      }

      if (this.needCommerce) {
        AgendaAbilityManager.getInstance()
          .startAbilityByEventId(this.info.mId, this.info?.mBegin, this.info?.mEnd, this.info?.mIsHoliday,
            this.info?.mTitle);
        return;
      }

      const param: Record<string, number | AgendaEventInfo> = {};
      param.id = this.info.mId;
      param.holidayInfo = this.info;
      param.instanceStartMills = this.info?.mBegin;
      param.instanceEndMills = this.info?.mEnd;
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.AGENDA_DETAIL,
        routerName: RouterName.ENTRY_HAP,
        param: param
      })
    },
    () => { // AgendaMenuOpt.COPY
      this.copyShareDialog();
    },
    async () => { // AgendaMenuOpt.SHARE
      this.onShareHandle();
    },
    () => { // AgendaMenuOpt.PASTE
      this.onPasteHandle();
    },
    async () => { // AgendaMenuOpt.EDIT
      if (!this.info || this.showPop) {
        return;
      }
      this.info.checkValuesArray = await ReminderService.INSTANCE.queryReminderInfo(this.info.mId) as Array<CalendarContract.Reminders>;
      let eventData: emitter.EventData = {
        data: {
          intent: 'edit',
          eventInfo: JSON.stringify(this.info),
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    },
    () => {
      this.showDeleteDialog();
    },
    () => { // AgendaMenuOpt.CREATE
      if (this.showPop) {
        return;
      }
      let eventData: emitter.EventData = {
        data: {
          agendaDateParam: this.date,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.CLICK_MAIN_PAGE_CREATE_AGENDA }, eventData);
    }
  ];

  copyShareDialog() {
    Log.info(TAG, 'copy eventId:' + this.info?.mId);
    emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': this.info?.mId } });
  }

  async showDeleteDialog() {
    if (!this.info) {
      return;
    }
    const agendaDeleteService = await ServiceManager.getInstance()
      .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE);
    agendaDeleteService?.notifyDeleteEvent(this.info?.mId, this.info?.mBegin, true);
  }

  @Builder
  buildMenuOpt(opt: AgendaMenuOpt, text: string | Resource) {
    Text(text)
      .width('100%')
      .height(48)
      .fontFamily('HarmonyHeiTi')
      .fontWeight('Regular')
      .lineHeight(22)
      .fontSize($r('sys.float.Subtitle_M'))
      .align(Alignment.Center)
      .textAlign(TextAlign.Start)
      .onClick(() => {
        this.handler[opt]();

        if (this.onMenuChosen) {
          this.onMenuChosen(opt, this.info ? this.info.mId : -1);
        }
      })
  }

  aboutToAppear() {
  }

  aboutToDisappear(): void {
  }

  build() {
    Menu() {
      ForEach(this.menuOpts, (opt: AgendaMenuOpt) => {
        if (opt !== AgendaMenuOpt.CREATE && this.menuOpts.length > 1) {
          MenuItem({ content: this.menuText[opt].content, labelInfo: this.menuText[opt].hint })
            .onClick(() => {
              this.handler[opt]();

              if (this.onMenuChosen) {
                this.onMenuChosen(opt, this.info ? this.info.mId : -1);
              }
            })
            .menuItemCommerceStyle(this.needCommerce)
        }


        if (opt === AgendaMenuOpt.CREATE) {
          MenuItemGroup() {
            MenuItem({ content: this.menuText[opt].content, labelInfo: this.menuText[opt].hint })
              .onClick(() => {
                this.handler[opt]();

                if (this.onMenuChosen) {
                  this.onMenuChosen(opt, this.info ? this.info.mId : -1);
                }
              })
              .menuItemCommerceStyle(this.needCommerce)
          }
        }
      })
    }
    .menuCommerceStyle(this.needCommerce)
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
  }
}

/**
 * 日程弹窗内容组件
 */
@Component
export struct AgendaPopupContent {
  private singleAgendaMargin: Margin = {
    left: 12,
    right: 12,
    top: 12,
    bottom: 12
  }

  // 日程信息 单个日程或者日程数组
  info: AgendaEventInfo[] = [];

  // 是否窄屏
  isSmallWindow: boolean = false;

  // 弹窗当前指向的时间戳
  date: number = 0;

  // 是否菜单弹窗
  isMenu: boolean = false;

  // 是否折叠弹窗
  private isFold: boolean = false;

  //是否周日视图
  isWeekView: boolean = false;

  //气泡弹窗最大宽度
  agendaMaxWidth: number = 0;

  //是否需要保留传入时分
  needSaveTime: number = 0;

  //卡片弹窗是否有边框 true:无边框
  borderless: boolean = false;

  private isPreview: boolean = false;

  // 菜单选项
  @Prop menuOpts: AgendaMenuOpt[] = [];

  // 新建日程弹窗是否跟手
  private isCreateAgendaPopup: boolean = DeviceConfig.instance().config.isCreateAgendaPopup;

  // 菜单选择回调
  onMenuChosen: (op: AgendaMenuOpt, id: number) => void = (op: AgendaMenuOpt, id: number) => {
  };

  // 点击日程弹窗回调 (导航不切换页面需要在回调改变弹窗的显示状态)
  onClickContent: () => void = () => {
  };

  // 菜单粘贴回调
  onPasteHandle: () => void = (): void => {
  };

  // 菜单分享回调
  onShareHandle: () => void = (): void => {
  };

  private onHoverHandler: (isHover: boolean) => void = (isHover: boolean) => {
  };

  build() {
    if (!this.isMenu) {
      if (this.info.length > 1) {
        MultiAgendaContent({
          infoList: this.info,
          date: this.date,
          isSmallWindow: this.isSmallWindow,
          onClickContent: this.onClickContent,
          onHoverHandler: this.onHoverHandler,
          isWeekView: this.isWeekView,
          isPreview: this.isPreview,
          borderless: this.borderless,
        })
      } else if (this.info.length === 1) {
        SingleAgendaContent({
          info: this.info[0],
          date: this.date,
          isFold: this.isFold,
          isSmallWindow: this.isSmallWindow,
          onClickContent: this.onClickContent,
          singleAgendaMargin: this.singleAgendaMargin,
          isWeekView: this.isWeekView,
          agendaMaxWidth: this.agendaMaxWidth,
          borderless: this.borderless,
        })
      }
    } else {
      AgendaMenuContent({
        info: this.info[0],
        date: this.date,
        isSmallWindow: this.isSmallWindow,
        menuOpts: this.menuOpts,
        showPop: this.isCreateAgendaPopup,
        onMenuChosen: this.onMenuChosen,
        onPasteHandle: this.onPasteHandle,
        onShareHandle: this.onShareHandle,
        needSaveTime: this.needSaveTime,
      })
    }
  }
}

export async function generateAgendaOption(event: AgendaEventInfo | undefined): Promise<AgendaMenuOpt[]> {
  if (!event) {
    return [];
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

  // 不是服务日程和节假日可编辑
  if (!event.mHwextServiceType && !event.isHoliday() && isCanEdit(accountType)) {
    menuOpt.push(AgendaMenuOpt.EDIT);
  }
  // 不是节假日可删除
  if (!event.isHoliday()) {
    menuOpt.push(AgendaMenuOpt.DELETE);
  }
  // 不是服务日程和节假日可可多选
  if (!event.mHwextServiceType && !event.isHoliday() && accountType !== CalendarAccountType.EMAIL_ACCOUNT_TYPE) {
    menuOpt.push(AgendaMenuOpt.MULTISELECT);
  }
  return menuOpt;
}

function isCanEdit(accountType: string): boolean {
  return (accountType === CalendarAccountType.LOCAL_ACCOUNT_TYPE || accountType === CalendarAccountType.CUSTOM_ACCOUNT_TYPE)
}
