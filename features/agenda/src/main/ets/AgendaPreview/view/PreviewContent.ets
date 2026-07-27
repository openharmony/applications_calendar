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
  AttendeeService,
  behaviorEvents,
  CalendarAccountType,
  CalendarContract,
  CalendarService,
  CommonService,
  DeviceConfig,
  EmptyUtils,
  EventService,
  GlobalThis,
  Log,
  maskString,
  NavPathManager,
  NavPathName,
  PreviewFromType,
  ReminderService,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ThrottleFunction
} from '@app/common';
import { AgendaTitle } from '../../AgendaDetail/view/AgendaTitle';
import { AttendeeRow } from '../../components/AttendeeRow';
import { ReminderRow } from './ReminderRow';
import { DividerLine } from '../../CreateAgenda/view/DividerLine';
import { RepeatRuleRow } from '@app/commons.repeatruleview';
import { ImportantAlertRow } from '../../AgendaDetail/view/ImportantAlertRow';
import { HashMap } from '@kit.ArkTS';
import { DEFAULT_NUM, DEFAULT_STR } from '../../CreateAgenda/Constants';
import { OtherAgendaInfo } from '../../AgendaDetail/view/OtherAgendaInfo';
import { CONTACT_BIRTHDAY_BUNDLE_NAME, CONTACT_BIRTHDAY_BUNDLE_NAME_2 } from '../../AgendaDetail/view/AgendaDetail';

const TAG = 'PreviewContent';

@Component
export struct PreviewContent {
  @Prop info: AgendaEventInfo;

  @Prop displayStartMills: number;

  @Prop displayEndMills: number;

  @Prop searchText: string = '';

  // 长按预览入口
  @Prop previewFromType: PreviewFromType;

  // 与会人列表
  @State attendeeList: Array<CalendarContract.Attendees> = [];

  // 提醒时间列表
  @State checkValuesArray: CalendarContract.Reminders[] = [];

  // 帐户颜色
  @State accountColor: number = DEFAULT_NUM;

  // 帐户展示名
  @State accountDisName: ResourceStr = DEFAULT_STR;

  @State account: CalendarContract.Accounts = new CalendarContract.Accounts();

  @State isAgendaCollapse: boolean = false;

  private scroller: Scroller = new Scroller();

  private isHoverShow: boolean = false;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private needShowImportantAler: boolean = false;

  private onHoverHandler: (isHover: boolean) => void = (isHover: boolean) => {
  };

  private onClickHandler: () => void = () => {
  };

  public onPreviewClick?: () => void;

  aboutToAppear(): void {
    this.queryPreviewContentFromDb();
    this.initAttendeeList();
    this.initCheckValuesArray();
    this.reportPreviewEvent();
    this.needShowImportantAler = this.info.mImportantEventType !== CalendarContract.EventImportantType.ANNIVERSARIES &&
      this.info.mImportantEventType !== CalendarContract.EventImportantType.HOLIDAY;
  }

  build() {
    Column() {
      if (this.isHoverShow) {
        this.previewBuilder()
      } else {
        this.ScrollBuilder()
      }
    }
    .onClick(() => {
      this.onPreviewClick?.();
    })
    .width(this.isHoverShow ? 340 : undefined)
    .constraintSize({ maxHeight: 490 })
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .backgroundBlurStyle(BlurStyle.NONE)
    .shadow(ShadowStyle.OUTER_DEFAULT_SM)
    .onHover((isHover) => {
      this.onHoverHandler(isHover);
    })
  }

  @Builder
  ScrollBuilder() {
    Scroll(this.scroller) {
      Column() {
        AgendaTitle({
          info: this.info,
          displayStartMills: this.info.isRepeatEvent() ? this.displayStartMills : this.info?.mBegin,
          displayEndMills: this.info.isRepeatEvent() ? this.displayEndMills : this.info?.mEnd,
          disabled: true,
          disableCopy: true,
          isLongClickPreview : true,
          isPreview: true,
          searchText: this.searchText,
          isFromMonthView: this.previewFromType === PreviewFromType.MONTH_VIEW,
          marginBottom: this.isAgendaCollapse ? 8 : 12,
          onClickHandler: () => {
            this.onPreviewClick?.();
          }
        })
          .accessibilityGroup(true)
          .accessibilityLevel('yes')

        if (this.attendeeList.length > 0 && !this.isAgendaCollapse) {
          AttendeeRow({
            attendeeList: this.attendeeList,
            eventId: this.info.mId,
            disabled: true
          })
            .margin({ bottom: $r('sys.float.padding_level6') })
        }

        if (!this.isAgendaCollapse) {
          this.ReminderInfoBuilder();
        }

        OtherAgendaInfo({
          info: this.info,
          accountColor: this.accountColor,
          accountDisName: this.accountDisName,
          isAgendaCollapse: this.isAgendaCollapse
        })
      }
    }
    .borderRadius($r('sys.float.corner_radius_level8'))
    .padding({
      left: 12,
      right: 12,
      top: 12,
      bottom: 12,
    })
    .constraintSize({
      minHeight: this.getMinHeight(),
      maxHeight: this.info.isHoliday() ? 100 : undefined
    })
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .flexShrink(2)
    .borderWidth(this.needCommerce ? 1 : 0)
    .borderColor($r('sys.color.gray_04'))
    .edgeEffect(EdgeEffect.Spring)
  }

  private getMinHeight(): number | undefined {
    if (this.info.isHoliday()) {
      return undefined;
    }
    if (this.attendeeList.length > 0 && !this.isAgendaCollapse) {
      return undefined;
    }
    let minHeight = this.info.isImportantEvent() ? 96 : this.info.mIsAllDay ? 120 : 112;
    if (!this.isAgendaCollapse) {
      minHeight += 32;
      if (this.needShowImportantAler) {
        minHeight += 98;
      }
      if (this.info.mRepeatRule !== '') {
        minHeight += 98;
      }
      if (minHeight >= 226) {
        return minHeight;
      }
    }
    return undefined;
  }

  @Builder
  previewBuilder() {
    Column() {
      AgendaTitle({
        info: this.info,
        displayStartMills: this.info.isRepeatEvent() ? this.displayStartMills : this.info?.mBegin,
        displayEndMills: this.info.isRepeatEvent() ? this.displayEndMills : this.info?.mEnd,
        disabled: true,
        disableCopy: true,
        isLongClickPreview : true,
        searchText: this.searchText,
        isPreview: true,
        isFromMonthView: this.previewFromType === PreviewFromType.MONTH_VIEW,
        onClickHandler: () => {
          this.onClickHandler();
        }
      })
    }
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({
      left: 12,
      right: 12,
      top: 12,
    })
    .align(Alignment.Top)
    .flexShrink(2)
  }

  @Builder
  ReminderInfoBuilder() {
    Column() {
      if (this.checkValuesArray.length > 0) {
        ReminderRow({
          checkValuesArray: this.checkValuesArray,
          mIsAllDay: this.info.mIsAllDay,
          needShowImportantAler: this.needShowImportantAler
        })
      }

      if (this.needShowImportantAler) {
        ImportantAlertRow({
          isImportantAlert: this.info.alertType === CalendarContract.AgendaAlertType.IMPORTANT,
          toggleEnabled: false
        })
      }

      if (this.info.mRepeatRule !== '') {
        DividerLine()
          .padding({
            left: $r('sys.float.padding_level5'),
            right: $r('sys.float.padding_level5')
          })
        RepeatRuleRow({
          mEventInfo: this.info,
          rrule: this.info.mRepeatRule,
          disabled: true,
          toggleEnabled: false,
          onClickHandler: () => {
            this.onPreviewClick?.();
          }
        });
      }
    }
    .padding($r('sys.float.padding_level2'))
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ bottom: $r('sys.float.padding_level6') })
  }

  private async initAttendeeList() {
    this.attendeeList =
      await AttendeeService.INSTANCE.queryAttendeeInfoByEventId(this.info.mId) as Array<CalendarContract.Attendees>;
  }

  private async initCheckValuesArray() {
    let checkValuesArrays =
      await ReminderService.INSTANCE.queryReminderInfo(this.info.mId) as Array<CalendarContract.Reminders>;
    this.checkValuesArray = checkValuesArrays.sort((a, b) => {
      return a.remindMinutes - b.remindMinutes;
    });
  }

  /**
   * 根据帐户 ID 获取帐户信息
   * @param 帐户 ID
   */
  private async initAccountInfo(id: number, calendarUuid: string) {
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
    this.accountColor = this.account?.calendarColor;
    this.accountDisName = AccountUtils.getAccountResourceStr(this.account);
    const accountName = this.account?.accountName
    const accountType = this.account?.accountType
    if ((accountName === CONTACT_BIRTHDAY_BUNDLE_NAME || accountName === CONTACT_BIRTHDAY_BUNDLE_NAME_2) &&
      accountType === CalendarAccountType.BIRTHDAY_ACCOUNT_CORE_TYPE) {
      this.accountDisName = GlobalThis.getResourceStr($r('app.string.contact_birthday'))
    }
  }

  private async queryPreviewContentFromDb() {
    if (this.info.mIsHoliday) {
      return;
    }
    this.info = await EventService.INSTANCE.queryEventById(this.info.mId);
    this.initAccountInfo(this.info.mCalendarId, this.info.mCalendarUuid);
  }

  private reportPreviewEvent() {
    let params: ReportHiEventParams = {
      FROM_TYPE: this.previewFromType,
      TYPE: this.info.mImportantEventType
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.longPressToPreview, params);
  }


  /**
   * 日程详情跳转
   * @param eventId
   */
  toEventDetail() {
    try {
      if (this.needCommerce) {
        AgendaAbilityManager.getInstance()
          .startAbilityByEventId(this.info.mId, this.info.mBegin, this.info.mEnd, this.info.mIsHoliday,
            this.info.mTitle);
      } else {
        ThrottleFunction.instance().throttle(TAG, (): void => {
          const agendaInfo = this.info;
          const param: Record<string, number | AgendaEventInfo> = {};
          param.id = agendaInfo.mId;
          param.holidayInfo = agendaInfo;
          param.instanceStartMills = agendaInfo.mBegin;
          param.instanceEndMills = agendaInfo.mEnd;
          NavPathManager.getInstance().pushPath({
            builderName: NavPathName.AGENDA_DETAIL,
            routerName: RouterName.ENTRY_HAP,
            param: param
          });
        }, 200)
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'toEventDetail', err);
    }
  }
}