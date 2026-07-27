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
  AgendaAbilityManager,
  AgendaDeleteService,
  AgendaEventInfo,
  AgendaListItemViewModel,
  AgendaTransitionUtil,
  AgendaUtil,
  AGENDA_SUB_DETAIL_WIDTH,
  behaviorEvents,
  BigFontSize,
  CalendarDate,
  CommonInnerEvent,
  DateUtil,
  DeviceConfig,
  GlobalDataKeys,
  isChineseCalendar,
  Log,
  LunarDateUtil,
  MILLS_PER_DAY,
  ModeUtil,
  NavPathManager,
  NavPathName,
  PreviewFromType,
  ReportUtil,
  RouterModel,
  RouterName,
  ServiceEnum,
  ServiceManager,
  ThrottleFunction,
  UnusualMode,
  VibrationType,
  VibratorUtils,
} from '@app/common';
import { FromType } from '@app/common/src/main/ets/default/util/ReportUtil';
import lazy { PreviewMenu } from '../AgendaPreview/view/PreviewMenu';
import lazy { PreviewContent } from '../AgendaPreview/view/PreviewContent';
import { emitter } from '@kit.BasicServicesKit';
import { ImportantAgendaItemContent } from './ImportantAgendaItemContent';
import { LengthMetrics } from '@kit.ArkUI';
import { AgendaEditMenuOpt, AgendaMenu, AgendaMenuOpt,
  generateAgendaEditOption } from '../AgendaDetail/view/AgendaMenu';
import { AgendaDetailSource } from '../common/AgendaEnum';
import lazy { buildUDC } from '@app/common/src/main/ets/default/util/ShareUtils';
import { AgendaOperateHelper } from '../helpers/AgendaOperateHelper';

const TAG = 'ImportantAgendaItem';
const DELAY = 200;

/**
 * 搜索日程list重要日的item样式
 */
@Component
export struct ImportantAgendaItem {
  @StorageProp('themeColor') themeColor: string = '';

  // 小屏判断
  @Consume inSmallWindow: boolean;

  // 是否允许拖拽释放目标拉起新建日程半模态
  @Consume isOnDropAllowed: boolean;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @StorageProp(GlobalDataKeys.CURRENT_DATE) currentDate: number = 0;

  // 其它历法
  @StorageProp('subscriptionCalendar') subscriptionCalendar: number = -1;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  @ObjectLink info: AgendaListItemViewModel;

  @Prop fromType: FromType = FromType.UNKNOWN;

  // 长按预览来源入口
  @Prop previewFromType: PreviewFromType;

  // 分栏场景是否选中
  @Prop isChecked: boolean = false;

  @State isToday: boolean = false;

  // 是否存在于子窗中
  private isInPop: boolean = false;

  private isSmall: boolean = true;

  // 日程组件所在的视图类型
  private sourceType: number = AgendaDetailSource.UNKNOWN;

  // 搜索文字
  @Link searchText: string;

  @Link selectable: boolean;

  private onItemClick: () => void = (): void => {
  };

  private onDeleteSuccess: () => void = (): void => {
  };

  private isRightClickToDeleteAllowed: boolean = DeviceConfig.instance().config.isRightClickToDeleteAllowed;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //详情子窗打开状态存储
  @StorageLink(GlobalDataKeys.IS_SUB_WINDOW_DETAIL) isSubWindowDetail: boolean = DeviceConfig.instance().config.isDefaultSubDetail;

  // 窗口大小
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  private isSubDetailCheck: boolean = DeviceConfig.instance().config.isSubDetailCheck;

  @Prop isScrolling: boolean = false;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  @Builder
  existMenu() {
    if (this.isRightClickToDeleteAllowed) {
      AgendaMenu({
        isSmallWindow: false,
        info: this.info,
        compId: this.getItemStrId(),
        menuEditOpts: generateAgendaEditOption(this.info),
        menuOpts: [AgendaMenuOpt.VIEW, AgendaMenuOpt.COPY, AgendaMenuOpt.SHARE, AgendaMenuOpt.EDIT, AgendaMenuOpt.DELETE],
        onCopyHandle: () => {
          emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': this.info?.mId } });
        },
        onDeleteHandle: () => {
          ServiceManager.getInstance()
            .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
            service?.notifyDeleteEvent(this.info?.mId, this.info?.mBegin, true);
          });
        },
        onShareHandle: () => {
          emitter.emit({ eventId: CommonInnerEvent.SHARE_AGENDA }, {
            data: {
              compId: AgendaUtil.getShareIdByIndexAndInfo(this.info, this.index),
              eventIds: [this.info?.mId]
            }
          })
        },
        onViewHandle: () => {
          this.toEventDetail();
        },
        onEditHandle: (editType: number) => {
          this.onEditHandle(editType);
        },
      })
    }
  }


  async onEditHandle(opt: AgendaEditMenuOpt) {
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

  // 对应的vm序号
  private index: number = -1;

  @State geometry: string = '';

  @State transitionOption: GeometryTransitionOptions = {};

  private onAniStart: () => void = () => {
    this.geometry = this.getGeometryId();
    this.transitionOption = AgendaTransitionUtil.option;
  }

  private onAniEnd: () => void = () => {
    this.geometry = '';
    this.transitionOption = {};
  }

  aboutToAppear() {
    if (this.agendaTransitionUtil.formerId === this.getGeometryId()) {
      this.onAniStart();
    }
  }

  getGeometryId(): string {
    return '' + this.info.mId + '-' + this.index;
  }

  getDateTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      const nowDate: CalendarDate = new CalendarDate(this.currentDate);
      const today: number = new CalendarDate(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate()).getTime();

      const gapTime = Math.floor((jDate.getTime() - today) / MILLS_PER_DAY);
      this.isToday = (gapTime === 0);

      let dateString: string | Resource;
      const year = jDate.getFullYear();
      if (year !== nowDate.getFullYear()) {
        dateString = DateUtil.intlDateFormatChineseStyle(jDate, {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
      } else {
        dateString = DateUtil.intlDateFormatChineseStyle(jDate, { month: 'long', day: 'numeric' });
      }

      return dateString;
    }
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, { month: 'long', day: 'numeric' });
  }

  getWeekTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      return DateUtil.intlDateFormatChineseStyle(jDate, { weekday: 'long' });
    }
    const dateTime = new CalendarDate(time);
    return DateUtil.intlDateFormatChineseStyle(dateTime, { weekday: 'long' });
  }

  getLunarTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      return LunarDateUtil.toLunarDateString(jDate);
    }
    const dateTime = new CalendarDate(time);
    return LunarDateUtil.toLunarDateString(dateTime);
  }

  toEventDetail() {
    if (ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
      this.jumpEventNavPath();
    } else if (this.inSmallWindow && this.fromType !== FromType.MONTH_VIEW) {
      this.agendaTransitionUtil.buildEventDetail(this.info, this.fromType);
      this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), true, this.onAniStart, this.onAniEnd);
    } else if (this.fromType === FromType.MONTH_VIEW || this.isInPop) {
      if (this.needCommerce) { // 商务化跳转多实例窗口
        AgendaAbilityManager.getInstance().startAbilityByEventId(this.info.mId, this.info.mBegin, this.info.mEnd);
        return;
      }
      if (this.fromType === FromType.MONTH_VIEW) {
        this.jumpToMonthAgendaPop();
        return;
      }
      this.jumpEventNavPath();
    } else {
      // 分栏场景通知右侧详情刷新
      let eventData: emitter.EventData = {
        data: {
          'eventId': this.info.mId,
          'displayStartMills': this.info.mBegin,
          'displayEndMills': this.info.mEnd,
          'sourceType': this.sourceType,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
    }
  }

  jumpEventNavPath() {
    const param: Record<string, string | number | boolean> = {};
    param.id = this.info.mId;
    param.instanceStartMills = this.info.mBegin;
    param.instanceEndMills = this.info.mEnd;
    param.isInPop = this.isInPop;
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.AGENDA_DETAIL,
      routerName: this.isInPop ? RouterName.SEARCH_AGENDA_MAIN : RouterName.ENTRY_HAP,
      param: param
    });
  }

  jumpToMonthAgendaPop() {
    // 需要打开详情子窗,且不需要校验宽度(平板)或者宽度校验通过(三折叠),则打开详情子窗
    const canOpenDetailPop = !this.isSubDetailCheck || this.windowWidth >= AGENDA_SUB_DETAIL_WIDTH;
    if (this.isSubWindowDetail && canOpenDetailPop) {
      this.jumpToPopDetail();
    } else {
      this.agendaTransitionUtil.buildEventDetail(this.info, FromType.MONTH_VIEW, canOpenDetailPop);
      this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), true, this.onAniStart, this.onAniEnd);
    }
  }

  jumpToPopDetail() {
    const param: Record<string, number | string | boolean | AgendaEventInfo> = {};
    param.id = this.info.mId;
    if (this.info.isHoliday()) {
      param.holidayInfo = this.info;
    }
    param.instanceStartMills = this.info.mBegin;
    param.instanceEndMills = this.info.mEnd;
    param.fromType = FromType.MONTH_VIEW;
    param.source = 'CLICK_MONTH_SHARE_AGENDA';
    param.isMessageResource = this.info.isMessageResource;
    param.isPopShrink = false;
    param.isHoliday = false;
    param.holidayTitle = '';
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
  getItemStrId(): string {
    return this.info.getEditAblePropStr() + '-' + this.index;
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  dateTimeBuilder() {
    Text(this.getDateTime(this.info.mBegin))
      .fontSize($r('sys.float.Subtitle_M'))
      .fontWeight(FontWeight.Bold)
      .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
      .opacity(this.isToday ? 1 : $r('sys.float.alpha_primary'))
      .padding({ right: 8 })
    Text(this.getWeekTime(this.info.mBegin))
      .fontSize($r('sys.float.Body_S'))
      .fontWeight(FontWeight.Bold)
      .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
      .opacity(this.isToday ? 1 : $r('sys.float.alpha_secondary'))
      .margin({ top: 4 })

    if (isChineseCalendar(this.subscriptionCalendar)) {
      Text(this.getLunarTime(this.info.mBegin))
        .fontWeight(FontWeight.Normal)
        .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_S'))
        .opacity(this.isToday ? 1 : $r('sys.float.alpha_secondary'))
        .margin({
          top: 4, right: 5,
          left: 8
        })
    }
  }

  @Builder
  dateTimeBigFontBuilder() {
    Text() {
      Span(this.getDateTime(this.info.mBegin))
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
        .opacity(this.isToday ? 1 : $r('sys.float.alpha_primary'))
        .padding({ right: 8 })
      Span(`  ${this.getWeekTime(this.info.mBegin)}  `)
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
        .opacity(this.isToday ? 1 : $r('sys.float.alpha_secondary'))
        .margin({ top: 4 })

      if (isChineseCalendar(this.subscriptionCalendar)) {
        Span(this.getLunarTime(this.info.mBegin))
          .fontWeight(FontWeight.Normal)
          .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
          .fontSize($r('sys.float.Body_S'))
          .opacity(this.isToday ? 1 : $r('sys.float.alpha_secondary'))
          .margin({
            top: 4, right: 5,
            left: 8
          })
      }
    }.maxLines(2)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
  }

  @Builder
  buildDayHead() {
    if (this.info.mIsSetDayHead) {
      Row() {
        this.dateTimeBigFontBuilder();
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .constraintSize({ minHeight: 40 })
      .margin({ top: 16, bottom: 16 })
      .padding({ right: 12, left: 12 })
      .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None) // 大字体适配布局

      Row() {
        this.dateTimeBuilder();
      }
      .alignItems(VerticalAlign.Center)
      .width('100%')
      .constraintSize({ minHeight: 40 })
      .margin({ top: 8, bottom: 8 })
      .padding({ left: 12, right: 12 })
      .visibility(this.isChangeLayout() ? Visibility.None : Visibility.Visible) // 水平布局
    }
  }

  @Builder
  PreviewMenuBuilder(item: AgendaEventInfo, compId: string) {
    PreviewMenu({
      compId,
      info: item,
      showMultiSelect: this.previewFromType !== PreviewFromType.MONTH_VIEW,
      shareAnchorViewId: AgendaUtil.getShareIdByIndexAndInfo(this.info, this.index),
      onDeleteSuccess: () => {
        this.onDeleteSuccess();
      },
      onMultiSelectClick: () => {
        this.selectable = true;
        this.info.isSelected = true;
        emitter.emit({eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED});
      }
    })
  }

  @Builder
  PreviewContentBuilder(item: AgendaEventInfo) {
    PreviewContent({
      info: item,
      previewFromType: this.previewFromType,
      displayStartMills: item?.mBegin,
      displayEndMills: item?.mEnd,
      onPreviewClick: () => {
        ContextMenu.close();
        setTimeout(() => {
          ThrottleFunction.instance().debounceInstant(TAG, () => {
            Log.info(TAG, `on click id = ${this.info.mId}`);
            this.onItemClick();
            this.toEventDetail();
            ReportUtil.reportStatisticEvent(behaviorEvents.monthClickImportantCard);
          }, DELAY)
        }, 300)
      }
    }).borderRadius($r('sys.float.corner_radius_level12'))
  }

  @Builder
  ImportantPressItem(compId: string) {
    Column() {
      ImportantAgendaItemContent({
        info: this.info,
        searchText: this.searchText,
        fromType: FromType.MONTH_VIEW,
        isChecked: this.isChecked,
        isScrolling:this.isScrolling
      })
    }
    .borderRadius(16)
    .geometryTransition(this.geometry, this.transitionOption)
    .onClick(() => {
      ThrottleFunction.instance().debounceInstant(TAG, () => {
        Log.info(TAG, `on click id = ${this.info.mId}`);
        this.onItemClick();
        this.toEventDetail();
        ReportUtil.reportStatisticEvent(behaviorEvents.monthClickImportantCard);
      }, DELAY)
    })
    .bindContextMenu(ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)
      ? null
      : this.PreviewMenuBuilder(this.info, compId), ResponseType.LongPress,
      {
        preview: this.PreviewContentBuilder(this.info),
        placement: this.isSmall ? Placement.BottomLeft : Placement.Left,
        previewAnimationOptions: {
          scale: [0.95, 1.0],
          hoverScale: [1.0, 0.95]
        },
        aboutToAppear:()=>{
          //触发震动
          VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
        },
      })
    .bindContextMenu(
      this.isRightClickToDeleteAllowed ? this.existMenu() : undefined,
      ResponseType.RightClick
    )
    .focusBox({ margin: LengthMetrics.vp(-2) })
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
  }

  build() {
    Column() {
      this.buildDayHead()
      this.ImportantPressItem(this.getItemStrId())
    }
    .width('100%')
    .id(this.getItemStrId())
  }
}