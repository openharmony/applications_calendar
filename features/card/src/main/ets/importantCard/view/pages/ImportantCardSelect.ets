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

import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { AgendaEventInfo } from '@app/common/src/main/ets/agenda/AgendaEventInfo';
import {
  AgendaService,
  BigFontSize,
  CommonInnerEvent,
  CreateAgendaSheetFromPage,
  DateUtil,
  DeviceConfig,
  EventService,
  getAdaptImportantTime,
  GlobalThis,
  InstanceService,
  Log,
  QueryInfo,
  ServiceEnum,
  ServiceManager,
  ReportUtil,
  statisticEvents,
  CalendarDate,
  EmptyUtils,
  FontSizeScaleUtils,
  maskString
} from '@app/common';
import emitter from '@ohos.events.emitter';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { R } from '../../../utils/R';
import {
  getValidImportantList,
  loadBirthDayAccountId,
  loadChineseHolidayAccountId
} from '../components/importantCardUtils';
import { CreateAgendaRoot } from '@app/feature.agenda/src/main/ets/CreateAgenda/view/CreateAgendaRoot';
import { AgendaOffsetTitle } from '@app/feature.agenda/src/main/ets/service/AgendaServiceImpl';
import { addButtonTypeText } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { i18n } from '@kit.LocalizationKit';
import { SUPPORT_CHINESE_HOLIDAYS, SUPPORT_SOLAR_TERMS } from '../../model/ImportantCardModel';
import { EventMode, ImportantCardConfig } from '@app/common/src/main/ets/card/ImportantCardConfig';

const TAG: string = 'ImportantCardSelect';

// RTLM是镜像语言内的文字转向字符，长度为2
const RLTM_LENGTH: number = 2;

export class RouterParams {
  public mId?: number = -1;
  public config: ImportantCardConfig | undefined = undefined;
}

/**
 * 选择重要日日期
 *
 * @since 2023-10-11
 */
@Component
struct ImportantCardSelect {
  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  @Consume navPathStack: NavPathStack;

  @State importantEventList: AgendaEventInfo[] = [];

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  @State importantId: number | undefined = 0;

  // 显示新建日程的半模态
  @State isShowCreateAgenda: boolean = false;

  // 广播携带的日程信息
  @State createPageData: emitter.EventData = {};

  @Provide isAgendaAniShowFinish: boolean = false;

  // 按月份排序后的节假日列表
  @State holidayList: AgendaEventInfo[] = [];

  // 按月份排序后的节假日列表
  @State birthDayList: AgendaEventInfo[] = [];

  // 最近节假日
  @State nextHoliday: AgendaEventInfo = new AgendaEventInfo();

  @State formConfig: ImportantCardConfig = new ImportantCardConfig('');

  private navBarHeight: number = R.Dimen.important_card_nav_height;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private isWindowDecorVisible: boolean = DeviceConfig.instance().config.isWindowDecorVisible;

  // 节假日列表查询起始日期
  private holidayRangeBegin: CalendarDate = new CalendarDate();

  // 节假日列表查询终止日期
  private holidayRangeEnd: CalendarDate = new CalendarDate(
    this.holidayRangeBegin.getFullYear() + 1,
    this.holidayRangeBegin.getMonth(),
    this.holidayRangeBegin.getDate() + 60); // 预防可能出现闰月，需要延长时间查询节假日

  private formGetAgendaIdHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
    this.onCreateAgendaCallback(data);
  }

  //系统语言
  @StorageProp('language') language: string = '';

  @Builder
  customTitle() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize('24vp')
          .fontColor([Color.White])
      }
      .accessibilityText($r('app.string.navigate_up'))
      .width(40)
      .height(40)
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor(this.isWindowDecorVisible ? '#1AFFFFFF' : '#00000000')
      .onClick(() => {
        this.navPathStack.pop(undefined);
      })

      Text($r('app.string.select_date'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ left: 8, right: 8 })
        .layoutWeight(1)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)

      this.buildAddAgenda();

    }
    .height(this.navBarHeight)
    .width('100%')
    .padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .position({
      x: 0,
      y: 0
    })
    .zIndex(1)
  }

  // 日程新增按钮
  @Builder
  buildAddAgenda() {
    Column() {
      Stack() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize('24vp')
          .fontColor([Color.White])
      }
      .offset({ x: this.isWindowDecorVisible ? 0 : i18n.isRTL(i18n.getSystemLocale()) ? 132 : -132 })
      .accessibilityText(addButtonTypeText($r('app.string.peek_create_agenda')))
      .width(40)
      .height(40)
      .borderRadius(20)
      .backgroundColor(this.isWindowDecorVisible ? '#1AFFFFFF' : '#00000000')
      .bindSheet($$this.isShowCreateAgenda, this.buildCreateAgenda(this.createPageData), {
        height: SheetSize.LARGE,
        detents: [SheetSize.LARGE, 0, 0],
        dragBar: false,
        showClose: false,
        preferType: SheetType.CENTER,
        //keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
        onAppear: () => {
          this.isAgendaAniShowFinish = true;
          Log.info(TAG, 'isShowCreateAgenda BindSheet onAppear.');
        }
      })
      .onClick(() => this.onClickAddButton())
    }
  }

  // 新建页面半模态
  @Builder
  buildCreateAgenda(createPageData: emitter.EventData) {
    Column() {
      CreateAgendaRoot({
        createPageData: createPageData,
        isShowCreateAgenda: $isShowCreateAgenda,
      })
    }
    .width('100%')
    .height('100%')
  }

  onClickAddButton() {
    Log.info(TAG, 'ImportantCardSelect onclick to CreateEvent');
    ReportUtil.reportBehaviorEvent(statisticEvents.importantFaGoToCreateAgenda);
    this.createPageData = {
      data: {
        eventType: CalendarContract.EventImportantType.ANNIVERSARIES,
        fromPage: CreateAgendaSheetFromPage.IMPORTANT_CARD_SELECT,
      }
    }
    this.isShowCreateAgenda = true;
  }

  aboutToAppear() {
    const params: RouterParams[] = this.navPathStack.getParamByName(
      NavPathName.IMPORTANT_CARD_SELECT
    ) as RouterParams[];
    if (params && params.length > 0) {
      if (params[0].config) {
        //如果从编辑界面进入选择界面的卡片的模式为未知联系人，则在这里不更新，使被选中的日程为空
        if (params[0].config.eventMode !== EventMode.UNKNOWN_BIRTHDAY) {
          this.importantId = params[0].mId;
          this.formConfig = params[0].config;
        }
      }
    }
    this.loadImportantList();
    this.loadHoliday();
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
    emitter.on({ eventId: CommonInnerEvent.EVENT_FORM_GET_AGENDA_ID }, this.formGetAgendaIdHandler);
  }

  aboutToDisappear() {
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.dataChangeHandler);
    emitter.off(CommonInnerEvent.EVENT_FORM_GET_AGENDA_ID, this.formGetAgendaIdHandler);
  }

  onCreateAgendaCallback(data: emitter.EventData) {
    if (data?.data?.mId) {
      const importantType: number = data.data.mImportantEventType;
      if (importantType !== CalendarContract.EventImportantType.ANNIVERSARIES &&
        importantType !== CalendarContract.EventImportantType.COUNTDOWN) {
        Log.warn(TAG, `not important event, do nothing. type=${importantType}`);
        return;
      }
      this.importantId = data.data.mId;
      ImportantCardConfig.setFixedEventIds(this.formConfig, [data.data.mId]);
      this.formConfig.eventTitle = data.data.mTitle;
      this.formConfig.importantType = importantType;
      this.formConfig.eventMode = EventMode.FIXED_IMPORTANT;
      this.loadImportantList();
      this.loadHoliday();
    }
  }

  onSelectFixedEvent(id: number, title: string, importantType: number) {
    if (importantType === CalendarContract.EventImportantType.COUNTDOWN ||
      importantType === CalendarContract.EventImportantType.ANNIVERSARIES) {
      this.formConfig.eventMode = EventMode.FIXED_IMPORTANT;
    } else if (importantType === CalendarContract.EventImportantType.HOLIDAY) {
      this.formConfig.eventMode = EventMode.FIXED_HOLIDAY;
    } else if (this.isBirthdayEvent(id)) {
      this.formConfig.eventMode = EventMode.FIXED_BIRTHDAY;
    }
    ImportantCardConfig.setFixedEventIds(this.formConfig, [id]);
    if (importantType === CalendarContract.EventImportantType.HOLIDAY) {
      this.formConfig.eventTitle = title;
    } else {
      this.formConfig.eventTitle = '';
    }
    this.formConfig.importantType = importantType;
    this.navPathStack.pop(this.formConfig);
  }

  private isBirthdayEvent(id: number): boolean {
    if (!this.birthDayList || this.birthDayList.length === 0) {
      return false;
    }
    const index = this.birthDayList.findIndex((item: AgendaEventInfo) => item.mId === id);
    return index >= 0;
  }

  @Builder
  NextHolidayRow() {
    Row() {
      Text($r('app.string.recent_holiday'))
        .fontColor($r('sys.color.font_on_primary'))
        .fontSize($r('sys.float.Body_L'))
        .width(240)
      Radio({ value: 'nextHoliday' + this.nextHoliday.mId, group: 'importantDaySelect' })
        .radioStyle({
          checkedBackgroundColor: this.themeColor
        })
        .checked(this.formConfig.eventMode === EventMode.RECENT_HOLIDAY)
        .onClick(() => {
          this.onRecentHolidayClick();
        })
    }
    .accessibilityText($r('app.string.recent_holiday'))
    .accessibilityChecked(this.formConfig.eventMode === EventMode.RECENT_HOLIDAY)
    .accessibilityDescription(this.formConfig.eventMode === EventMode.RECENT_HOLIDAY ? ' ' : '')
    .padding({ top: 14, bottom: 14 })
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .onClick(() => {
      this.onRecentHolidayClick();
    })

    Divider()
      .color($r('sys.color.comp_divider'))
  }

  onRecentHolidayClick() {
    this.formConfig.eventMode = EventMode.RECENT_HOLIDAY;
    ImportantCardConfig.setFixedEventIds(this.formConfig, []);
    this.formConfig.eventTitle = '';
    this.formConfig.importantType = CalendarContract.EventImportantType.HOLIDAY;
    this.navPathStack.pop(this.formConfig);
  }

  @Builder
  ImportantDaysBuilder(isHoliday: boolean = false, isBirthDay: boolean = false) {
    Text(isHoliday ? $r('app.string.holidays') :
      isBirthDay ? $r('app.string.contact_birthday') : $r('app.string.important_day'))
      .fontSize(14)
      .height(20)
      .fontColor($r('sys.color.font_on_secondary'))
      .margin({
        top: 20,
        bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(GlobalThis.getInstance().fontSizeScale)
      })
      .textAlign(TextAlign.Start)
    if (isHoliday) {
      this.NextHolidayRow()
    }
    ForEach(isHoliday ? this.holidayList : isBirthDay ? this.birthDayList : this.importantEventList, (
      item: AgendaEventInfo, index: number) => {
      Row() {
        Row() {
          Text(this.getTitle(item, this.language))
            .fontColor($r('sys.color.font_on_primary'))
            .fontSize($r('sys.float.Body_L'))

          if (item.mAttachmentCount > 0) {
            SymbolGlyph($r('sys.symbol.paperclip'))
              .fontSize($r('sys.float.Body_L'))
              .fontColor([$r('sys.color.font_on_primary')])
              .width(16)
              .draggable(false)
          }
        }
        .width(240)

        Radio({ value: item.mId.toString(), group: 'importantDaySelect' })
          .radioStyle({
            checkedBackgroundColor: this.themeColor
          })
          .checked(this.importantId === item.mId && this.formConfig.eventMode !== EventMode.RECENT_HOLIDAY)
          .onClick(() => {
            this.onSelectFixedEvent(item.mId, item.mTitle, item.mImportantEventType);
          })
      }
      .accessibilityText(this.getTitle(item, this.language))
      .accessibilityChecked(this.importantId === item.mId && this.formConfig.eventMode !== EventMode.RECENT_HOLIDAY)
      .accessibilityDescription(this.importantId === item.mId && this.formConfig.eventMode !== EventMode.RECENT_HOLIDAY
        ? ' ' : '')
      .onClick(() => {
        this.onSelectFixedEvent(item.mId, item.mTitle, item.mImportantEventType);
      })
      .padding({ top: 14, bottom: 14 })
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Divider()
        .color($r('sys.color.comp_divider'))
    }, (item: AgendaEventInfo) => `${item.mId}`)
  }

  private getTitle(item: AgendaEventInfo, language?: string) {
    const tempContext = GlobalThis.getResourceStr($r('app.string.agenda_title_separate'));
    const server = ServiceManager.getInstance().getService<AgendaService>(ServiceEnum.AGENDA_SERVICE);
    let titleStr = item.mTitle;
    let instanceTime = item.mBegin;
    if (server && item.isImportantEvent()) {
      instanceTime = getAdaptImportantTime(item.mEventCalendar, item.mBegin, item.mRepeatRule,
        new CalendarDate());
      if (EmptyUtils.isEmptyString(item.mRepeatRule)) {
        const titleOffset: AgendaOffsetTitle = server.updateNormalAgendaTitle(item, new Date().setUTCHours(0, 0, 0, 0));
        titleStr = titleOffset.title;
      } else {
        titleStr = server.updateRepeatAgendaTitle(item, instanceTime);
      }
    }

    const instanceTimeStr = DateUtil.getDayOffset(instanceTime, item.mImportantEventType, undefined, language).content

    const tempContextStr = tempContext
      .replace('%1$s', instanceTimeStr)
      .replace('%2$s', titleStr)
      .trim()
      .replace(/·$/, '')
      .trim();

    //    如果是非镜像语言就正常显示“国庆节”+“•”+“10天后”
    //    如果是镜像语言（比如阿拉伯语言），处理成“10天后”+“•”+“国庆节”的形式

    if (!i18n.isRTL(i18n.getSystemLocale())) {
      return tempContextStr;
    } else {
      const tempParts = tempContextStr.split('•');
      if (tempParts.length > 2 && tempParts[0].length > RLTM_LENGTH) {
        return tempParts[1] + '•' + tempParts[0];
      } else if (tempParts.length > 2) {
        return tempParts[1];
      } else {
        return tempContextStr;
      }
    }


  }

  build() {
    NavDestination() {
      Column() {
        this.customTitle();
        Column() {
          Scroll() {
            Column() {
              if (this.holidayList.length > 0) {
                this.ImportantDaysBuilder(true);
              }
              if (this.importantEventList.length > 0) {
                this.ImportantDaysBuilder();
              }
              if (this.birthDayList.length > 0) {
                this.ImportantDaysBuilder(false, true);
              }
            }
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.Start)
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%')
        .height('100%')
        .padding({
          left: 24,
          right: 24,
          top: this.navBarHeight,
          bottom: 24
        })
      }
      .width('100%')
      .height('100%')
      .padding({ top: this.buttonTopHeight + this.windowAvoidAreaTopRectHeight })
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [[0x092a45, 0.0], [0x2c516c, 0.4], [0x667578, 1.0]]
      })
    }
    .height('100%')
    .hideTitleBar(true)
  }

  private dataChangeHandler = (data: emitter.EventData): void => this.onDataChange(data);

  // 获取按日期排序的节假日列表 -- 添加查询联系人生日列表
  private loadHoliday() {
    const queryInfo: QueryInfo = {
      startTime: this.holidayRangeBegin.getTime(),
      endTime: this.holidayRangeEnd.getTime()
    };
    InstanceService.INSTANCE.queryInstanceAsync(queryInfo).then(async (result) => {
      const birthDayAccountId = await loadBirthDayAccountId(); // 联系人生日
      const chineseHolidayCalendarId = await loadChineseHolidayAccountId();
      let tempList = result.filter(item => {
        return (item.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY &&
          item.mCalendarId === chineseHolidayCalendarId) || item.mCalendarId === birthDayAccountId;
      });
      if (tempList.length === 0) {
        Log.info(TAG, 'No holiday events!');
        return;
      }
      tempList.sort((a, b) => {
        return a.mBegin - b.mBegin;
      });
      this.nextHoliday = tempList[0];

      // 去重，只保留最近的同名节假日
      tempList = tempList.reduce((agendaList: AgendaEventInfo[], event: AgendaEventInfo) => {
        const existing = agendaList.find(holiday => holiday.mTitle.trim() === event.mTitle.trim());
        if (!existing) {
          agendaList.push(event);
        }
        return agendaList;
      }, []);
      Log.info(TAG, `holidayList length = ${tempList.length}`);
      tempList.sort((a, b) => {
        if (new CalendarDate(a.mBegin).getMonth() !== new CalendarDate(b.mBegin).getMonth()) {
          return new CalendarDate(a.mBegin).getMonth() - new CalendarDate(b.mBegin).getMonth();
        }
        return new CalendarDate(a.mBegin).getDate() - new CalendarDate(b.mBegin).getDate();
      });
      this.holidayList = this.getEventListByCalendarId(chineseHolidayCalendarId, tempList, true);
      this.birthDayList = this.getEventListByCalendarId(birthDayAccountId, tempList);
    })
  }

  // 需要显示的中国节假日，固定七个法定节日+常用的七夕重阳+节气
  private needShowChineseHoliday(event: AgendaEventInfo): boolean {
    return SUPPORT_CHINESE_HOLIDAYS.includes(event.mTitle) || SUPPORT_SOLAR_TERMS.includes(event.mTitle);
  }

  private getEventListByCalendarId(calendarId: number, eventList: AgendaEventInfo[],
                                   isChineseCalendarId: boolean = false): AgendaEventInfo[] {
    let agendaList: AgendaEventInfo[] = [];
    agendaList = eventList.reduce((agendaList: AgendaEventInfo[], event: AgendaEventInfo) => {
      const existing = agendaList.find(holiday => holiday.mTitle.trim() === event.mTitle.trim());
      if (existing) {
        return agendaList;
      }
      if (event.mCalendarId === calendarId) {
        if (isChineseCalendarId) {
          if (this.needShowChineseHoliday(event)) {
            agendaList.push(event);
          }
        } else {
          agendaList.push(event);
        }
      }
      return agendaList;
    }, []);
    return agendaList;
  }

  private onDataChange(data: emitter.EventData) {
    if (data?.data?.table !== 'Events') {
      return;
    }
    this.loadImportantList();
    this.loadHoliday();
  }

  private loadImportantList() {
    InstanceService.INSTANCE.queryImportantEventsTask().then((list: Array<AgendaEventInfo>) => {
      Log.info(TAG, `queryImportantEvents: ${list?.length}`);
      if (!list) {
        return;
      }
      let validList: AgendaEventInfo[] = getValidImportantList(list);
      this.importantEventList = validList;
      this.importantEventList.forEach((eventInfo: AgendaEventInfo) => {
        Log.info(TAG, `loadImportantList eventTitle ${maskString(eventInfo.mTitle)}, ` +
          `days: ${DateUtil.getDayOffset(eventInfo.mBegin, eventInfo.mImportantEventType).dayOffset}`);
      })
    });
  }

  private adaptImportantDateToNow(list: Array<AgendaEventInfo>) {
    if (!list) {
      return;
    }
    const toDate: CalendarDate = new CalendarDate(Date.now());
    list.forEach((item: AgendaEventInfo) => {
      if (!item) {
        return;
      }
      item.mBegin = getAdaptImportantTime(item.mEventCalendar, item.mBegin, item.mRepeatRule, toDate);
    });
  }
}

export {
  ImportantCardSelect
}