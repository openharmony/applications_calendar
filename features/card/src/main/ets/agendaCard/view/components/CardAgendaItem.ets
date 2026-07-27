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
import { DeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { CARD_AGENDA, jumpToAgendaDetail, jumpToServiceApp } from '../../../utils/CardJumpUtils';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { getAccountColor } from '../../../utils/CardUtils';
import { getTimeStr } from '../../../utils/TimeUtils';
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';
import { TimeStrViewModel } from '../../viewModel/TimeStrViewModel';

const TAG: string = 'CardAgendaItem';

const TIME_WIDTH_24_HOUR: number = 34;
const TIME_WIDTH_12_HOUR: number = 60;

@Extend(Text)
function blackTextStyle(isExpired: boolean) {
  .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
  .minFontSize('4vp')
  .maxFontScale(1)
  .fontColor(isExpired ? $r('sys.color.font_tertiary') : $r('sys.color.font_primary'))
  .fontWeight(FontWeight.Medium)
  .opacity($r('sys.float.alpha_primary'))
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}

@Extend(Text)
function lightTextStyle(isExpired: boolean) {
  .opacity(0.7)
  .fontColor(isExpired ? $r('sys.color.font_tertiary') : $r('sys.color.font_primary'))
  .maxFontSize($r('sys.float.ohos_id_text_size_body3'))
  .minFontSize('4vp')
  .maxFontScale(1)
  .fontWeight(FontWeight.Regular)
  .maxLines(1)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}


/**
 * 单个日程组件
 */
@Component
export struct CardAgendaItem {
  // @State 不支持直接使用 ResourceStr，使用数组规避
  @State timeTextStrList: Array<ResourceStr> = [];

  // @State 不支持直接使用 ResourceStr，使用数组规避
  @State titleStrList: Array<ResourceStr> = [];

  @LocalStorageProp('needCommerce') needCommerce: boolean = false;

  // 日程实例
  @Prop agenda: AgendaCardInfo = new AgendaCardInfo();

  @Prop deviceLayout: DeviceLayout;

  @Prop isRTL: boolean;

  @State accountColor: number = this.agenda.mDisplayColor;

  @Prop formId: string = '';

  @Prop isFinal: boolean = false;

  private newLine: string = '\n';

  private dimension: string = '';

  @State timeWidth: number = TIME_WIDTH_24_HOUR;

  // 使能是否过期
  @Prop isExpired: boolean = false; // 卡片Item在大多数场景下 不需要计算是否过期 因此从外部传入更合理

  @Prop @Watch('onTimeZoneChange') timeZone: string;

  @State timeStrViewModel: TimeStrViewModel = new TimeStrViewModel();

  @Prop @Watch('on24HChange') is24HourClock: boolean = false;

  aboutToAppear() {
    Log.info(TAG, `formId = ${this.formId}, is24HourClock: ${this.is24HourClock}, timeZone= ${this.timeZone}`);
    this.transTitleMessage();
    this.accountColor = getAccountColor(this.agenda.mDisplayColor);
    this.timeWidth = this.is24HourClock ? TIME_WIDTH_24_HOUR : TIME_WIDTH_12_HOUR;
    this.timeStrViewModel = new TimeStrViewModel(this.agenda);
  }

  @Builder
  DividerUp() {
    Column()
      .width(1)
      .height(6)
      .backgroundColor($r('sys.color.icon_fourth'))
      .opacity(0.9)
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 2, bottom: 2 })
  }

  @Builder
  DividerDown() {
    Column()
      .width(1)
      .height(6)
      .backgroundColor($r('sys.color.icon_fourth'))
      .opacity(0.6)
      .borderRadius(1.5)
      .alignSelf(ItemAlign.Center)
      .margin({ top: 2, bottom: 2 })
  }

  @Builder
  AccountCircle() {
    Circle()
      .width(7)
      .height(7)
      .alignSelf(ItemAlign.Center)
      .stroke(this.accountColor)
      .fillOpacity(0)
      .strokeWidth(1.8)
      .margin({ bottom: this.agenda.mIsAllDay ? 2 : 0 })
  }

  /**
   * 日程标题组件
   */
  @Builder
  AgendaTitle() {
    Row() {
      Text(this.titleStrList[0])
        .fontColor(this.isExpired ? $r('sys.color.font_tertiary') : $r('sys.color.font_primary'))
        .opacity($r('sys.float.alpha_primary'))
        .fontFeature('\"ss08\" 1')
        .fontSize($r('sys.float.Body_M'))
        .maxFontScale(1)
        .fontWeight(FontWeight.Medium)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: this.agenda?.mAttachmentCount > 0 ? 'calc(100% - 16vp)' : '100%' })

      if (this.agenda?.mAttachmentCount > 0) {
        SymbolGlyph($r('sys.symbol.paperclip'))
          .fontSize($r('sys.float.Body_M'))
          .fontColor([$r('sys.color.font_primary')])
          .width(16)
          .draggable(false)
      }
    }
    .layoutWeight(1)
  }

  /**
   * 日程地点组件
   */
  @Builder
  AgendaLocation() {
    Text(this.agenda.mLocation.split(this.newLine)[0] ?? '')
      .fontColor($r('sys.color.font_secondary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize($r('sys.float.ohos_id_text_size_body3'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .textAlign(this.isRTL ? TextAlign.End : TextAlign.Start)
  }

  @Builder
  buildLabel() {
    Column() {
      if (this.agenda.mIsAllDay) {
        this.AccountCircle();
        Blank().height(2)
        Text(this.timeStrViewModel?.timeStrStart).blackTextStyle(this.isExpired)
      } else if (this.agenda.mIsMultiDayEvent && this.agenda.mFlag === AgendaCardInfo.FLAG_MID) {
        this.DividerUp();
        this.AccountCircle();
        Blank().height(7)
        Text(this.timeStrViewModel?.timeStrStart).blackTextStyle(this.isExpired)
        Blank().height(5)
        this.DividerDown();
      } else if (this.agenda.mIsMultiDayEvent) {
        if (this.agenda.mFlag === AgendaCardInfo.FLAG_END) {
          this.DividerUp();
          this.AccountCircle();
          Blank().height(9)
        }
        Text(this.timeStrViewModel?.timeStrStart).blackTextStyle(this.isExpired)
        Text(this.timeStrViewModel?.timeStrEnd).blackTextStyle(this.isExpired)
        if (this.agenda.mFlag === AgendaCardInfo.FLAG_START) {
          Blank().height(9)
          this.AccountCircle();
          this.DividerDown();
        }
      } else {
        Text(this.timeStrViewModel?.timeStrStart).blackTextStyle(this.isExpired)
        // 线加圆圈
        this.DividerUp();
        this.AccountCircle();
        this.DividerDown();
        Text(this.timeStrViewModel?.timeStrEnd).lightTextStyle(this.isExpired)
      }
    }
    .width(this.timeWidth)
    .alignSelf(ItemAlign.Center)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 12, right: 12 })
  }

  @Builder
  buildAgendaDetail() {
    Column() {
      //  日程头
      Row() {
        this.AgendaTitle()
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')

      // 非频繁切换场景 使用条件语句控制组件, 减少组件创建
      if (this.agenda?.mLocation || this.agenda.isOnlineMeeting()) {
        Row() {
          if (this.agenda?.mLocation) {
            this.AgendaLocation();
          } else if (this.agenda.isOnlineMeeting()) {
            OneKeyServicePlaceholder({
              info: this.agenda,
              deviceLayout: this.deviceLayout
            }).layoutWeight(1)
          }
          if (this.agenda.canShowOneKeyService(this.formId)) {
            OneKeyServiceButton({ info: this.agenda })
          }
        }
        .justifyContent(FlexAlign.Start)
        .width('100%')
        .padding({ top: 7 })
      }
    }
    .margin({ left: this.isRTL ? 12 : undefined, right: this.isRTL ? undefined : 12 })
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  build() {
    Row() {
      this.buildLabel();
      this.buildAgendaDetail();
    }
    .margin({ bottom: this.isFinal ? 0 : 8 })
    .height(78)
    .alignItems(VerticalAlign.Center)
    .borderRadius(12)
    .onClick(() => {
      Log.info(TAG, `formId: ${this.formId} click agendaTitle: ${maskString(this.agenda.mTitle)}, ` +
        `startTime: ${this.agenda.mBegin}, endTime = ${this.agenda.mEnd}, eventUuid: ${maskString(this.agenda.mEventUuid)}`);
      jumpToAgendaDetail(this, this.agenda, CARD_AGENDA, this.dimension, this.needCommerce);
    })
    .stateStyles({
      pressed: {
        .backgroundColor('#1a000000')
      },
      normal: {
        .backgroundColor($r('sys.color.comp_background_list_card'))
      }
    })
  }

  /**
   * 获取显示的标题信息
   */
  private transTitleMessage() {
    this.titleStrList = [];
    this.titleStrList.push(this.agenda.getTitle());
    Log.info(TAG, `transTitleMessage agendaTitle: ${maskString(this.agenda.mTitle)}, beginTime: ${this.agenda.mBegin}, ` +
      `startDay: ${this.agenda.mDay}, currentJulianDay: ${FormUtils.getCurrentJulianDay()}`);
  }

  onTimeZoneChange() {
    Log.info(TAG, `onTimeZoneChange timeZone= ${this.timeZone}`);
    this.timeStrViewModel.parseTimeStr();
  }

  on24HChange() {
    Log.info(TAG, `on24HChange is24HourClock: ${this.is24HourClock}`);
    this.timeWidth = this.is24HourClock ? TIME_WIDTH_24_HOUR : TIME_WIDTH_12_HOUR;
    this.timeStrViewModel = new TimeStrViewModel(this.agenda);
  }
}

/**
 * 一键服务：线上会议占位组件
 */
@Component
export struct OneKeyServicePlaceholder {
  private textStr: ResourceStr = {} as ResourceStr;

  @Link info: AgendaCardInfo;

  @Prop deviceLayout: DeviceLayout;

  @Prop agendaCardType: string;

  aboutToAppear() {
    if (this.info.isOnlineMeeting()) {
      this.textStr = $r('app.string.online_meeting');
    }
  }

  build() {
    Text(this.textStr)
      .fontColor($r('sys.color.font_secondary'))
      .opacity($r('sys.float.alpha_secondary'))
      .fontSize(this.agendaCardType === CardType.AGENDA_CARD_2X2
        ? this.deviceLayout.cardAgendaLocationFontSize
        : $r('sys.float.ohos_id_text_size_body3'))
      .maxFontScale(1)
      .fontWeight(FontWeight.Regular)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .layoutWeight(1)
      .textAlign(TextAlign.Start)
  }
}

/**
 * 一键服务按钮
 * 当前仅给2X4,4x4,4x6日程卡片使用
 */
@Component
export struct OneKeyServiceButton {
  @Link info: AgendaCardInfo;

  onBtnClick() {
    Log.info(TAG, `OneKeyServiceButton onBtnClick mHwextServiceUri.length:${this.info?.mHwextServiceUri?.length}`);
    if (!this.info.mHwextServiceUri) {
      Log.error(TAG, 'onBtnClick mHwextServiceUri is false');
      return;
    }
    let want: Want = { uri: this.info.mHwextServiceUri };
    jumpToServiceApp(this, want);
  }

  build() {
    Text(this.info.getOneKeyServiceBtnStr())
      .fontColor('#F76045')
      .fontWeight(FontWeight.Medium)
      .fontSize(12)
      .maxFontScale(1)
      .onClick(() => this.onBtnClick())
      .responseRegion({
        x: '-10%',
        y: '-50%',
        width: '120%',
        height: '200%'
      })
  }
}

export enum CardType {
  /** 线上会议字段归一,所以区分卡片类型,2x2日程卡片单独适配 */
  AGENDA_CARD_2X2 = 'agendaCard2x2',
}
