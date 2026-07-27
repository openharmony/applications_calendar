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

import { behaviorEvents,
  BigFontSize,
  CalendarContract,
  FontSizeScaleUtils,
  GlobalThis, Log, NavPathManager, ReportUtil, RouterName } from '@app/common';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import { AttendeeListSheet } from './AttendeeListSheet';
import { LengthMetrics } from '@kit.ArkUI';
import measure from '@ohos.measure';

type Attendee = CalendarContract.Attendees;

@Component
export struct AttendeeRow {
  @Consume navPathStack: NavPathStack;

  @Link @Watch('update') attendeeList: Array<Attendee>;

  eventId: number = 0;

  @State AttendeeNames: string = '';

  @State participantsDesc: ResourceStr = '';

  @State isShowAttendeeList: boolean = false;

  @State needArrow: boolean = false;

  // 是否禁用
  private disabled: boolean = false;

  // 是否为全模态页面
  private isCover: boolean = false;

  // 是否收起折叠面板
  @State isArrowDown: boolean = false;

  // 用于判断与会人列表是否需要展开的文本长度
  private attendeeTextLength: number = 0;
  private attendeeRowLength: number = 0;

  @State isHover: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  getResourceString(resource: Resource): string {
    return GlobalThis.getResourceStr(resource);
  }

  aboutToAppear() {
    this.update();
  }

  update(): void {
    this.AttendeeNames = this.attendeeList.map((item: Attendee) => item.attendeeName).join(', ');
    this.participantsDesc = $r('app.string.participant_num', this.attendeeList.length);
    let attendeeText = measure.measureTextSize({
      textContent: this.AttendeeNames,
      fontSize: 14,
      fontWeight: FontWeight.Normal
    });
    this.attendeeTextLength = px2vp(Number(attendeeText?.width)) + 16;
    this.needArrow = this.attendeeRowLength <= this.attendeeTextLength;
  }

  clickEvent() {
    if (this.disabled) {
      return;
    }
    if (this.isCover) { // 全模态页面无法做navPath跳转,改为半模态跳转
      this.isShowAttendeeList = true;
      return;
    }
    const param: Record<string, Attendee[] | number> = {};
    param.list = this.attendeeList;
    param.eventId = this.eventId;
    NavPathManager.getInstance().pushPath({
      builderName: NavPathName.ATTENDEE_LIST,
      routerName: RouterName.ENTRY_HAP,
      param: param
    })
  }

  @Builder
  buildListSheet() {
    Column() {
      AttendeeListSheet({
        isShowAttendeeList: this.isShowAttendeeList,
        list: this.attendeeList,
        eventId: this.eventId,
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildArrowRight() {
    SymbolGlyph($r('sys.symbol.chevron_right'))
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
        24
      ))
      .fontColor([$r('sys.color.icon_fourth')])
      .margin({ end: LengthMetrics.vp(4) })
      .align(Alignment.Center)
      .rotate({ angle: this.isArrowDown ? -90 : 90 })
  }

  @Builder
  buildAttendeeText() {
    Column() {
      Row() {
        Text(this.participantsDesc)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .layoutWeight(1)
          .align(Alignment.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        if (!this.disabled && this.needArrow) {
          this.buildArrowRight()
        }
      }
      .width('100%')

      Text(this.AttendeeNames)
        .fontSize($r('sys.float.Body_M'))
        .lineHeight(24)
        .width('100%')
        .maxLines(this.isArrowDown ? undefined : 1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontColor($r('sys.color.font_secondary'))
        .padding({ end: LengthMetrics.vp(16) })
        .onSizeChange((oldValue, newValue) => {
          this.attendeeRowLength = Number(newValue.width);
          this.needArrow = this.attendeeRowLength <= this.attendeeTextLength;
        })
    }
    .layoutWeight(1)
  }

  @Builder
  buildAttendRow() {
    Row() {
      Row() {
        this.buildAttendeeText()
      }
      .padding(8)
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .backgroundColor($r('sys.color.interactive_hover'))
      .stateStyles({
        pressed: {
          .backgroundColor(this.disabled ? '' : $r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(this.isHover ? $r('sys.color.interactive_hover') : $r('app.color.default_background'))
        }
      })
      .onHover((isHover) => {
        this.isHover = !this.disabled && isHover;
      })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        if (this.disabled) {
          return;
        }
        this.isArrowDown = !this.isArrowDown;
      })
    }
    .width('100%')
    .padding(4)
    .borderRadius($r('sys.float.corner_radius_level10'))
  }

  build() {
    Column() {
      this.buildAttendRow()
    }.backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level8'))
  }
}