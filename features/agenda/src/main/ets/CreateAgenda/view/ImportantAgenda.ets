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
  CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  CalendarDate,
  DateUtil,
  DeviceConfig,
  FeatureType,
  GlobalDataKeys,
  Log,
  RouterName,
} from '@app/common';
import { AgendaBasicInfo } from './AgendaBasicInfo';
import { AgendaReminderInfo } from './AgendaReminderInfo';
import { AgendaOtherInfo } from './AgendaOtherInfo';
import { inputMethod } from '@kit.IMEKit';
import { LengthMetrics } from '@kit.ArkUI';
import { AttachmentViewModel } from '../../AgendaAttachment/viewmodel/AttachmentViewModel';
import { AttachmentList } from '../../AgendaAttachment/view/AttachmentList';

const TAG: string = 'ImportantAgenda';
const DEFAULT_REMINDER_HOURS: number[] = [0, 1440, 10080];

@Component
export struct ImportantAgenda {
  @Link @Watch('eventInfoChange') importantEventInfo: AgendaEventInfo;

  // 日程的默认开始时间
  @Prop defaultStartTimeStamp: number;

  // 日程的默认结束时间
  @Prop defaultEndTimeStamp: number;

  // 是否是编辑页面
  @Prop isEditMode: boolean = false;

  // 选中的value集合
  @State checkValuesArray: CalendarContract.Reminders[] = [];

  // 全天事件默认提醒时间
  @StorageLink('allDayEventsDefaultRemindTime') allDayPresetReminderTime: number = 0;

  // 重要提醒开关
  @Prop isImportantAlert: boolean;

  // 是否重要日卡片选择页面跳转过来
  @Prop fromImportantSelect: boolean = false;

  // 标题以及规避区高度
  @Prop titleHeight: number = 0;

  // 附件相关信息
  @Link attachmentViewModel: AttachmentViewModel;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp(GlobalDataKeys.IS_NOTIFICATION_GRANTED) @Watch('eventInfoChange') isNotificationGranted: boolean = false;

  @State reminderMarginTop: number = 12;

  @State isSupportEventAttachment: boolean = false;

  private scrollerForList: Scroller = new Scroller();

  private timeStampKey: number = Date.now(); // 用于拉起键盘防止id重复的key

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  //是否支持日程附件管理
  private readonly isSupportAttachment: boolean = DeviceConfig.instance().isSupport(FeatureType.ATTACHMENT);

  async aboutToAppear() {
    this.checkValuesArray = this.importantEventInfo.checkValuesArray;
    if (this.checkValuesArray && this.checkValuesArray.length === 0 && !this.isEditMode) {
      this.presetAllDayReminders();
    }
    if (!this.importantEventInfo.mBegin) {
      this.importantEventInfo.mBegin = this.defaultStartTimeStamp;
    }
    this.eventInfoChange();
    this.isSupportEventAttachment =
      await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
  }

  private presetAllDayReminders() {
    for (let elem of DEFAULT_REMINDER_HOURS) {
      let reminder: CalendarContract.Reminders = new CalendarContract.Reminders();
      reminder.eventId = this.importantEventInfo.mId;
      reminder.remindMinutes = elem;
      reminder.remindType = CalendarContract.RemindersRemindType.TYPE_ALERT;
      this.checkValuesArray.push(reminder);
    }
  }

  @Builder
  agendaBasicBuilder() {
    ListItem() {
      AgendaBasicInfo({
        eventInfo: $importantEventInfo,
        mTitle: this.importantEventInfo.mTitle,
        mLocation: this.importantEventInfo.mLocation,
        startTimeStamp: this.importantEventInfo.mBegin ?? this.defaultStartTimeStamp,
        endTimeStamp: this.importantEventInfo.mEnd ?? this.defaultEndTimeStamp,
        importantTimeStamp: this.importantEventInfo.mBegin ?? this.defaultStartTimeStamp,
        timeStampKey: this.timeStampKey,
        isToggleOn: this.importantEventInfo.mIsAllDay,
        isEditMode: this.isEditMode,
        titlePlaceholder: $r('app.string.reciprocal_title_label'),
        fromImportantSelect: this.fromImportantSelect,
        onImportantDateChanged: () => {
          this.updateImportantType();
        }
      });
    }.width('100%')
  }

  @Builder
  agendaReminderBuilder() {
    ListItem() {
      AgendaReminderInfo({
        eventInfo: $importantEventInfo,
        mIsAllDay: this.importantEventInfo.mIsAllDay,
        checkValuesArray: $checkValuesArray,
        isInDetailPage: false,
        isEditMode: this.isEditMode,
        routerName: this.routerName,
        fromImportantSelect: this.fromImportantSelect,
        isImportantAlert: $isImportantAlert,
        marginTop: this.reminderMarginTop,
        onRepeatChanged: () => {
          this.updateImportantType();
        }
      });
    }.width('100%')
  }

  @Builder
  AttachmentListBuilder() {
    if (this.isSupportEventAttachment) {
      this.BuildAttachmentListContent();
    }
  }

  @Builder
  BuildAttachmentListContent() {
    ListItem() {
      AttachmentList({
        attachmentViewModel: this.attachmentViewModel,
        isEditMode: this.isEditMode,
        eventUuid: this.importantEventInfo.uuid,
      })
    }
    .renderGroup(true)
  }

  build() {
    Row() {
      List({ scroller: this.scrollerForList }) {
        ListItem().height(this.titleHeight)

        this.agendaBasicBuilder()

        this.agendaReminderBuilder()

        if (this.isSupportAttachment) {
          this.AttachmentListBuilder();
        }

        ListItem() {
          AgendaOtherInfo({
            eventInfo: $importantEventInfo, mDescription: this.importantEventInfo.mDescription,
            scrollerForList: this.scrollerForList
          })
            .margin({
              bottom: this.windowAvoidAreaNavigationRectHeight === 0 ? 8 : this.windowAvoidAreaNavigationRectHeight
            })
        }.width('100%')
      }
      .onScrollStart(() => {
        this.stopInputSession();
      })
      .scrollBar(BarState.Off) // 需要根据产品形态设置滚动条状态
      .height('100%')
      .margin({ start: LengthMetrics.vp(16), top: 8 })
      .borderRadius($r('sys.float.corner_radius_level10'))
      .layoutWeight(1)
      .width('calc(100% - 16vp)')
      .backgroundColor(Color.Transparent)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

      ScrollBar({ scroller: this.scrollerForList, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
        .width(16)
        .margin({ top: 8 + this.titleHeight, bottom: 28 })
    }
    .layoutWeight(1)
  }

  /**
   * 滑动页面收起键盘
   */
  private stopInputSession() {
    inputMethod?.getController()?.stopInputSession().then((result) => {
      if (result) {
        Log.info(TAG, 'stopInput success!');
      } else {
        Log.info(TAG, 'stopInput error!');
      }
    })
  }

  private updateImportantType(): void {
    const endOfToday = DateUtil.getEndMillsOfDate(new CalendarDate());
    if (this.importantEventInfo.mBegin < endOfToday && !this.importantEventInfo.isRepeatEvent()) {
      this.importantEventInfo.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
    } else {
      this.importantEventInfo.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
    }
  }

  private eventInfoChange() {
    if (!this.canShowReminder()) {
      this.reminderMarginTop = 12;
      return
    }
    this.reminderMarginTop = this.isNotificationGranted ? 12 : 28;
  }

  private canShowReminder(): boolean {
    return this.importantEventInfo.mImportantEventType === CalendarContract.EventImportantType.NORMAL ||
      this.importantEventInfo.mImportantEventType === CalendarContract.EventImportantType.COUNTDOWN;
  }
}