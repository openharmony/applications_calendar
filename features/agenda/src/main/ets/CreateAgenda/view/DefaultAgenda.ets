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
  BigFontSize,
  CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  CalendarDate,
  CompId,
  DeviceConfig,
  FeatureType,
  GlobalDataKeys,
  Log,
  PreferencesFiles,
  PreferencesUtil,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  SettingPreferencesKeys,
  SourceTypeEnum,
  statisticEvents
} from '@app/common';

import { AgendaBasicInfo } from './AgendaBasicInfo';
import { AgendaReminderInfo } from './AgendaReminderInfo';
import { AccountInfo } from './AccountInfo';
import { AgendaOtherInfo } from './AgendaOtherInfo';
import { inputMethod } from '@kit.IMEKit';
import { LengthMetrics } from '@kit.ArkUI';
import { AgendaAbbreviation } from './AgendaAbbreviation';
import { AttachmentViewModel } from '../../AgendaAttachment/viewmodel/AttachmentViewModel';
import { AttachmentList } from '../../AgendaAttachment/view/AttachmentList';

const TAG: string = 'DefaultAgenda';

@Component
export struct DefaultAgenda {
  // 日程信息
  @Link defaultEventInfo: AgendaEventInfo;

  // 选中的帐户 id 值
  @Link accountId: number;

  // 用户进页面时默认的帐户 id 值
  @Link oldAccountId: number;

  // 日程的默认开始时间戳
  @Prop defaultStartTime: number;

  // 日程的默认开始时间戳
  @Prop defaultEndTime: number;

  // 是否是编辑页面
  @Prop isEditMode: boolean = false;

  // 是否是农历日程
  @State mEventCalendar: number = CalendarContract.AgendaCalendarType.SOLAR;

  // 是否重要日卡片选择页面跳转过来
  @Prop fromImportantSelect: boolean = false;

  // 选中的value集合
  @Link checkValuesArray: CalendarContract.Reminders[];

  // 重要提醒开关
  @Link isImportantAlert: boolean;

  // 当前页
  @Prop currentIndex: number;

  // 日程时区
  @Prop agendaTimeZone: string;

  // 系统时区或者锁定时区
  @Prop secondTimeZone: string;

  // 标题以及规避区高度
  @Prop titleHeight: number = 0;

  // 气泡开关
  @StorageLink(GlobalDataKeys.SHARE_SCHEDULE_POPUPS) shareSchedulePopups: boolean = true;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 附件相关信息
  @Link attachmentViewModel: AttachmentViewModel;

  @StorageProp(GlobalDataKeys.IS_NOTIFICATION_GRANTED) isNotificationGranted: boolean = false;

  @Consume isAgendaAniShowFinish: boolean;

  @State isSupportEventAttachment: boolean = false;

  private scrollerForList: Scroller = new Scroller();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //是否支持日程智能创建
  private readonly isSupportAgendaIntelligentCreate: boolean = DeviceConfig.instance()
    .isSupport(FeatureType.INTELLIGENT_CREATE);

  //是否支持日程共享
  private readonly isSupportAgendaShare: boolean = DeviceConfig.instance().isSupport(FeatureType.AGENDA_SHARE);

  //是否支持日程附件管理
  private readonly isSupportAttachment: boolean = DeviceConfig.instance().isSupport(FeatureType.ATTACHMENT);

  private isQuickCreate: boolean = false;

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  // 改变弹窗内容是否编辑过的状态
  private changeEditedFlag: () => void = () => {};

  // 入口是否支持智能创建
  private oneSentenceCreate: boolean = false;

  private timeStampKey: number = Date.now(); // 用于拉起键盘防止id重复的key

  /**
   * 智能创建是否可见
   * @returns 返回true即可见 返回false即不可见
   */
  private isAbbreviationVisible(): boolean {
    if (this.isSupportAgendaIntelligentCreate) {
      return !(this.isEditMode || this.isQuickCreate || !this.oneSentenceCreate);
    } else {
      return false;
    }
  }

  @Builder
  popupBuilder() {
    Row() {
      Text($r('app.string.confirme_shared_schedule'))
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
    }
    .constraintSize({ maxWidth: 312 })
    .margin({
      left: 16,
      right: 16,
      top: 8,
      bottom: 8
    })
  }

  async aboutToAppear() {
    this.checkValuesArray = this.defaultEventInfo.checkValuesArray;
    this.isSupportEventAttachment =
      await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
  }

  @State importantType: CalendarContract.EventImportantType = 0;

  @Builder
  AgendaAbbreviation() {
    ListItem() {
      AgendaAbbreviation({
        eventInfo: $defaultEventInfo,
        startTimeStamp: this.defaultStartTime,
      })
    }
    .width('100%')
    .visibility(this.isAbbreviationVisible() ? Visibility.Visible : Visibility.None); //屏蔽编辑态
  }

  @Builder
  AgendaBasicInfo() {
    ListItem() {
      AgendaBasicInfo(
        {
          eventInfo: $defaultEventInfo,
          mTitle: this.defaultEventInfo.mTitle,
          mLocation: this.defaultEventInfo.mLocation,
          mLatitude: this.defaultEventInfo.mLatitude,
          mLongitude: this.defaultEventInfo.mLongitude,
          startTimeStamp: this.defaultEventInfo.mBegin ? this.defaultEventInfo.mBegin : this.defaultStartTime,
          endTimeStamp: this.defaultEventInfo.mEnd ? this.defaultEventInfo.mEnd : this.defaultEndTime,
          isToggleOn: this.defaultEventInfo.mIsAllDay,
          isEditMode: this.isEditMode,
          eventCalendarType: this.defaultEventInfo.mEventCalendar,
          titlePlaceholder: this.isQuickCreate ? $r('app.string.peek_create_agenda') : $r('app.string.edit_event_title_label'),
          fromImportantSelect: this.fromImportantSelect,
          isQuickCreate: this.isQuickCreate,
          changeEditedFlag: this.changeEditedFlag,
          timeStampKey: this.timeStampKey,
          agendaTimeZone: this.agendaTimeZone,
          secondTimeZone: this.secondTimeZone
        });
    }
    .width('100%')
  }

  @Builder
  AgendaReminderAndAccount() {
    ListItem() {
      AgendaReminderInfo({
        eventInfo: $defaultEventInfo,
        mIsAllDay: this.defaultEventInfo.mIsAllDay,
        checkValuesArray: $checkValuesArray,
        isInDetailPage: false,
        isEditMode: this.isEditMode,
        routerName: this.routerName,
        fromImportantSelect: this.fromImportantSelect,
        isImportantAlert: $isImportantAlert,
        marginTop: this.isNotificationGranted ? 12 : 28,
      })
    }
    .width('100%')
    .renderGroup(true)

    ListItem() {
      AccountInfo({
        isEditMode: this.isEditMode,
        eventInfo: $defaultEventInfo,
        checkedAccId: $accountId,
        oldCheckedAccId: $oldAccountId,
        marginTop: 12
      })
    }
    .width('100%')
    .renderGroup(true)
  }

  build() {
    Row() {
      List({ scroller: this.scrollerForList }) {
        ListItem().height(this.titleHeight)

        this.AgendaAbbreviation();

        this.AgendaBasicInfo();

        if (!this.isQuickCreate) {
          this.AgendaReminderAndAccount();

          if (this.isSupportAttachment) {
            this.AttachmentListBuilder();
          }

          ListItem() {
            AgendaOtherInfo({
              eventInfo: $defaultEventInfo,
              mDescription: this.defaultEventInfo.mDescription,
              scrollerForList: this.scrollerForList,
              currentIndex: this.currentIndex,
              agendaTimeZone: this.agendaTimeZone
            })
          }.width('100%');
        }
      }
      .id(CompId.DEFAULT_AGENDA_LIST)
      .onScrollStart(() => {
        this.stopInputSession();
      })
      .scrollBar(BarState.Off) // 需要根据产品形态设置滚动条状态
      .margin(this.isQuickCreate ? null : { start: LengthMetrics.vp(16), top: 8 })
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
      .layoutWeight(this.isQuickCreate ? 0 : 1)
      .width(this.isQuickCreate ? '100%' : 'calc(100% - 32vp)')
      .height('100%')
      .backgroundColor(Color.Transparent)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })

      if (!this.isQuickCreate) {
        ScrollBar({ scroller: this.scrollerForList, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
          .width(16)
          .margin({ top: 8 + this.titleHeight, bottom: 28 })
      }
    }
    .onTouch((event) => {
      this.shareSchedulePopups = false;
    })
    .layoutWeight(this.isQuickCreate ? 0 : 1)
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
        eventUuid: this.defaultEventInfo.uuid,
      })
    }
    .renderGroup(true)
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
}
