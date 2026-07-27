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
  behaviorEvents,
  BigFontSize,
  CalendarDate,
  CloudUtils,
  CommonInnerEvent,
  CornerType,
  DateUtil,
  DeviceConfig,
  DialogControllerOptions,
  EmptyUtils,
  FoldScreenType,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  isChineseCalendar,
  Log,
  LunarDateUtil,
  maskString,
  ModeUtil,
  NavPathManager,
  PreviewFromType,
  ReportUtil,
  RouterName,
  statisticEvents,
  TabType,
  ThrottleFunction,
  UnusualMode,
  VibrationType,
  VibratorUtils,
} from '@app/common';
import lazy { buildUDC } from '@app/common/src/main/ets/default/util/ShareUtils';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import inputMethod from '@ohos.inputMethod';
import { emitter } from '@kit.BasicServicesKit';
import { PreviewMenu } from '../AgendaPreview/view/PreviewMenu';
import { PreviewContent } from '../AgendaPreview/view/PreviewContent';
import { CACHE_SYNC_SWITCH_STATUS } from '@app/common/src/main/ets/dao/CloudUtils';
import { LengthMetrics } from '@kit.ArkUI';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { AgendaListItemContent } from '../AgendaDetail/view/AgendaListItemContent';
import { AgendaDetailSource } from '../common/AgendaEnum';
import { addSelectStatusText, broadcastSelectStatus,
  focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'AgendaItem';

const ONE_DAY_MILL: number = 86400000;

const DELAY = 200;

const SWITCH_ON: number = 1;

/**
 * 日程list 的item样式
 *
 * @since 2022-09-20
 */
@Component
export struct AgendaItem {
  @Consume navPathStack: NavPathStack;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @Prop isChecked: boolean = false;

  @ObjectLink info: AgendaListItemViewModel;

  // 长按预览入口
  @Prop previewFromType: PreviewFromType;

  @Link selectable: boolean;

  radius: number = 16;

  @StorageProp('themeColor') themeColor: string = '';

  @StorageLink('language') @Watch('getDateTime') language: string = '';

  // 搜索文字
  @Link searchText: string;

  // 其它历法
  @StorageProp('subscriptionCalendar') subscriptionCalendar: number = -1;

  // 选中id
  @StorageLink('checkEventId') checkEventId: number = -1;

  // 窗口类型
  @Consume inSmallWindow: boolean;

  @StorageProp(GlobalDataKeys.CURRENT_DATE) currentDate: number = 0;

  // 日程组件所在的视图类型
  viewType: number = -1;

  @State isToday: boolean = false;

  @Prop showEventId: number = -1;

  onItemClick: () => void = (): void => {
  };

  @StorageLink(CACHE_SYNC_SWITCH_STATUS) syncSwitchStatus: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  // 是否是特殊模式
  @StorageProp(GlobalDataKeys.FOLD_SCREEN_TYPE) foldType: FoldScreenType | undefined =
    AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE);

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  private index: number = -1;

  // 日程组件所在的视图
  private sourceType: number = AgendaDetailSource.UNKNOWN;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @State geometry: string = '';

  @State transitionOption: GeometryTransitionOptions = {};

  private leftClickCount: number = 0;

  private onAniStart: () => void = () => {
    this.geometry = this.getGeometryId();
    this.transitionOption = AgendaTransitionUtil.option;
  }

  private onAniEnd: () => void = () => {
    this.geometry = '';
    this.transitionOption = {};
  }

  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    autoCancel: false,
    customStyle: true
  };

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

  getGeometryId(): string {
    const extraId = // 跨天重复日程需要额外的mBegin用于区分同一天的不同日程
      (EmptyUtils.isEmptyString(this.info.mRepeatRule) && this.info.mStartDay !== this.info.mEndDay ? 0 :
        this.info.mBegin);
    return '' + this.info.mId + '-' + this.info.mDay + '-' + extraId;
  }

  getDateTime(time: number) {
    if (this.info.mDay !== 0) {
      const jDate = DateUtil.julianDay2Date(this.info.mDay);
      const nowDate: CalendarDate = new CalendarDate(this.currentDate);
      const today: number = new CalendarDate(nowDate.getFullYear(), nowDate.getMonth(), nowDate.getDate()).getTime();

      const gapTime = Math.floor((jDate.getTime() - today) / ONE_DAY_MILL);
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

  @Builder
  ItemContentBuilder() {
    Column() {
      AgendaListItemContent({
        searchText: this.searchText,
        viewType: this.viewType,
        info: this.info,
        selectable: this.selectable,
        showEventId: this.showEventId,
        isChecked: this.isChecked,
        isSmallWindow: this.inSmallWindow,
      })
    }
    .padding({
      top: this.getHotspotPaddingTop(),
      bottom: this.getHotspotPaddingBottom()
    })
    .width('100%')
    .borderRadius($r('sys.float.corner_radius_level8'))
    .accessibilityLevel('yes')
    .accessibilityText(this.info?.getAccessibilityText())
    .accessibilityDescription(this.getAccessibilityDescription())
    .accessibilityChecked(this.isAccessibilityChecked() ? this.info?.isSelected : undefined)
    .accessibilityGroup(true)
    .onDragStart((event: DragEvent) => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.agendaDragOut);
      buildUDC(event, this.info);
      //触发震动
      VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
    })
    .draggable(ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) || this.selectable ? false : true)
    .bindContextMenu(ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode) || this.selectable
      ? undefined : this.PreviewMenuBuilder(this.info),
      ResponseType.LongPress,
      {
        preview: this.PreviewContentBuilder(this.info),
        placement: Placement.BottomLeft,
        previewAnimationOptions: {
          scale: [0.95, 1.0],
          hoverScale: [1.0, 0.95]
        },
        aboutToAppear:()=>{
          //触发震动
          VibratorUtils.startPresetVibration(VibrationType.LONG_PRESS_LIGHT);
        },
      })
    .onClick(() => {
      if (!this.selectable) {
        ThrottleFunction.instance().debounceInstant(TAG, () => {
          this.onClickEvent();
        }, DELAY)
      } else {
        if (!this.info.isHoliday() && !this.info.isContactBirthday()) { // 节假日或联系人生日日程不能被选中
          this.info.isSelected = !this.info.isSelected;
          emitter.emit({eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED});
          focusComponentById(this.info.getEditAblePropStr(), 200);
        }
      }
    })
    .onMouse((ev?) => this.onMouseHotspotArea(ev))
    .geometryTransition(this.geometry, this.transitionOption)
    .id(this.info.getEditAblePropStr())
    .focusBox({ margin: LengthMetrics.vp(-2) })
  }

  isAccessibilityChecked() {
    return this.selectable && !this.info.isHoliday() && !this.info.isContactBirthday();
  }

  getAccessibilityText() {
    if (this.isAccessibilityChecked()) {
      return addSelectStatusText(this.info?.getAccessibilityText(), this.info?.isSelected);
    }
    return this.info?.getAccessibilityText();
  }

  getAccessibilityDescription() {
    if (this.selectable && !this.isAccessibilityChecked()) {
      return ' ';
    }
    return GlobalThis.getResourceStr($r('app.string.double_click_finger_execute'));
  }

  @Builder
  PreviewMenuBuilder(info: AgendaEventInfo) {
    if (info.isSupportShare()) {
      PreviewMenu({
        info,
        showMultiSelect: this.previewFromType !== PreviewFromType.MONTH_VIEW && !info.isContactBirthday(),
        onDeleteSuccess: () => {
          this.onDeleteSuccess();
        },
        onMultiSelectClick: () => {
          this.info.isSelected = true;
          this.selectable = true;
        }
      })
    }
  }

  @Builder
  PreviewContentBuilder(info: AgendaEventInfo) {
    PreviewContent({
      info,
      searchText: this.searchText,
      previewFromType: this.previewFromType,
      displayStartMills: info?.mBegin,
      displayEndMills: info?.mEnd
    }).borderRadius($r('sys.float.corner_radius_level12'))
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  @Builder
  dateTimeBuilder() {
    Text() {
      Span(this.getDateTime(this.info.mBegin))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
        .opacity(this.isToday ? 1 : $r('sys.float.alpha_primary'))
        .padding({ end: LengthMetrics.vp(8) })
        .flexShrink(1)
        .margin({ left: this.isChangeLayout() ? 0 : 13 })
      Span(`  ${this.getWeekTime(this.info.mBegin)}  `)
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_primary'))
        .opacity(this.isToday ? 1 : $r('sys.float.alpha_primary'))
        .flexShrink(1)
      if (isChineseCalendar(this.subscriptionCalendar)) {
        Span(this.getLunarTime(this.info.mBegin))
          .fontWeight(FontWeight.Regular)
          .fontColor(this.isToday ? this.themeColor : $r('sys.color.font_tertiary'))
          .fontSize($r('sys.float.Body_S'))
          .margin({
            top: LengthMetrics.vp(3), end: LengthMetrics.vp(5),
            start: LengthMetrics.vp(8)
          })
          .flexShrink(1)
      }
    }.maxLines(2)
    .textOverflow({ overflow: TextOverflow.Ellipsis })
    .accessibilityLevel('yes')
    .accessibilityGroup(true)
    .textAlign(TextAlign.Start)
    .width('100%')
    .margin({
      top: this.getDateTimeMargin(this.fontSizeScale, this.foldType),
      bottom: this.getDateTimeMargin(this.fontSizeScale, this.foldType)
    })
    .padding({ right: 12, left: 12 })
  }

  build() {
    Column() {
      if (this.info.mIsSetDayHead) {
        this.dateTimeBuilder();
      }
      this.ItemContentBuilder();
    }
    .width('100%')
  }

  getDateTimeMargin(fontSizeScale: number, foldType: FoldScreenType | undefined): Length {
    const isVerde = foldType === FoldScreenType.SMALL_UP_DOWN_FOLD;
    const defaultMargin = isVerde ? 4 : 12;
    return FontSizeScaleUtils.getNormalBigFontSizeInterval(fontSizeScale, defaultMargin);
  }

  /**
   * 改变选中日程
   *
   * @param checkEventId 选中日程id值
   */
  changeCheckEventId(checkEventId: number): void {
    GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, checkEventId);
  }

  async toEventDetail(info: AgendaEventInfo) {
    // 小窗场景或者在子窗场景使用
    if (this.inSmallWindow || this.isInPop) {
      let isBirthdayAccount = await AccountUtils.isBirthDayAccountByIdAsync(this.info.mCalendarId);
      if (isBirthdayAccount) {
        return;
      }
      if (this.needCommerce) { // 跳转多窗详情
        AgendaAbilityManager.getInstance()
          .startAbilityByEventId(this.info.mId, this.info.mBegin, this.info.mEnd, this.info.mIsHoliday,
            this.info.mTitle);
        return;
      }
      if (this.isInPop || ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)) {
        const param: Record<string, number | boolean> = {};
        param.id = info?.mId;
        param.instanceStartMills = info?.mBegin;
        param.instanceEndMills = info?.mEnd;
        param.isInPop = this.isInPop;
        NavPathManager.getInstance().pushPath({
          builderName: NavPathName.AGENDA_DETAIL,
          routerName: ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode)
            ? RouterName.ENTRY_HAP : RouterName.SEARCH_AGENDA_MAIN,
          param: param
        });
      } else {
        this.agendaTransitionUtil.buildEventDetail(this.info)
        this.agendaTransitionUtil.onCardClicked(this.getGeometryId(), true, this.onAniStart, this.onAniEnd);
      }
    } else {
      // 分栏场景通知右侧详情刷新
      let eventData: emitter.EventData = {
        data: {
          'eventId': info.mId,
          'displayStartMills': info.mBegin,
          'displayEndMills': info.mEnd,
          'sourceType': this.sourceType,
        }
      };
      emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_AGENDA_DETAIL }, eventData);
    }
  }

  getHotspotPaddingTop(): number {
    if ((this.info.mCornerType === CornerType.CORNER_NONE) || (this.info.mCornerType === CornerType.CORNER_DOWN)) {
      return 0;
    }
    return 4;
  }

  getHotspotPaddingBottom(): number {
    if ((this.info.mCornerType === CornerType.CORNER_NONE) || (this.info.mCornerType === CornerType.CORNER_UP)) {
      return 0;
    }
    return 4;
  }

  aboutToAppear() {
    Log.info(TAG, `agenda title in AgendaItem = ${maskString(this.info.mTitle)}`);
    if (this.agendaTransitionUtil.formerId === this.getGeometryId()) {
      this.onAniStart();
    }
  }

  aboutToDisappear(): void {
    this.shareSwitchDialogController = null;
  }

  private onDeleteSuccess: () => void = (): void => {
  };

  onMouseHotspotArea(ev?: MouseEvent): void {
    if (!ev) {
      return;
    }
     if (ev.button === MouseButton.Left && ev.action === MouseAction.Press) {
      this.leftClickCount++;
      ThrottleFunction.instance().debounce(TAG + 'clickTwice', () => {
        this.leftClickCount = 0;
      }, 300);
      if (this.leftClickCount > 1) {
        if (!this.info) {
          return;
        }
        AgendaAbilityManager.getInstance()
          .startAbilityByEventId(this.info.mId, this.info.mBegin, this.info.mEnd, this.info.mIsHoliday,
            this.info.mTitle);
      }
    }
  }

  private onClickEvent() {
    setTimeout(() => {
      inputMethod.getController().hideTextInput();
    }, 200)
    this.onItemClick();
    this.changeCheckEventId(this.info.mId);
    this.toEventDetail(this.info);
    const clickAgendaEvent: string = this.viewType === TabType.AGENDA ?
    statisticEvents.agendaClickAgenda : statisticEvents.searchClickAgenda
    ReportUtil.reportStatisticEvent(clickAgendaEvent);
  }
}