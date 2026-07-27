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

import emitter from '@ohos.events.emitter';
import {
  AttendeeService,
  BigFontSize,
  CalendarContract,
  CommonInnerEvent,
  DataSourceTemplate, FontSizeScaleUtils, GlobalThis,
  ViewProxy
} from '@app/common';

type Attendee = CalendarContract.Attendees;

const TAG: string = 'AttendeeListSheet';

class AttendeeListDataSource extends DataSourceTemplate<Attendee> {
}

@Component
export struct AttendeeListSheet {
  @Link isShowAttendeeList: boolean;
  private list: Attendee[] = [];
  private eventId: number = -1;
  private dataSource: AttendeeListDataSource = new AttendeeListDataSource(this.list);
  private viewProxy: ViewProxy = new ViewProxy(TAG);
  private mScroller = new Scroller();
  private dataChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.dataSource = new AttendeeListDataSource(this.list);
    this.dataChangeHandler = (data: emitter.EventData) => {
      this.onDataChange(data)
    };
    emitter.on({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, this.dataChangeHandler);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    emitter.off(CommonInnerEvent.SYSTEM_DATA_CHANGED, this.dataChangeHandler);
  }

  async onDataChange(data: emitter.EventData) {
    this.list =
      await AttendeeService.INSTANCE.queryAttendeeInfoByEventId(this.eventId) as Array<CalendarContract.Attendees>;
    this.dataSource.setData(this.list);
  }

  @Builder
  buildItem(name: string, email: string) {
    Row() {
      SymbolGlyph($r('sys.symbol.person_crop_circle_fill_1'))
        .fontSize('48vp')
        .margin({ right: 16 })
        .fontColor([$r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_fourth'))
      Column() {
        Text(name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(email)
          .fontSize(14)
          .fontWeight(FontWeight.Regular)
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ top: 14, bottom: 14 })
      .layoutWeight(1)
    }
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (item: Attendee) => {
        this.buildItem(item.attendeeName, item.attendeeEmail)
      }, (item: Attendee, index: number) => {
        return `${Date.now()}-${index}`;
      })
    }
    .alignSelf(ItemAlign.Start)
    .divider({ strokeWidth: '1px', startMargin: 60, color: $r('sys.color.comp_divider') })
    .borderRadius(16)
    .padding({
      left: 8,
      right: 8,
      top: 4,
      bottom: 4
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }
}