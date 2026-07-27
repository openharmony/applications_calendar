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

import { AgendaDataSource, EventService, Log, NavPageBuilderFactory } from '@app/common';
import { DeleteEventProcessor } from '../agenda/DeleteEventProcessor';
import { DeleteToolBar } from './DeleteToolBar';
import { EventContentItem, HeaderItem } from './DeleteItem';
import { SelectEventInfo } from '../agenda/SelectEventInfo';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';

const TAG: string = "DeleteList";

interface PageParam {
  accountId: number;
}

@Builder
function harBuilder(value: object) {
  DeleteList();
}

const builderName = NavPathName.MULTI_DELETE;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

/**
 * 日程删除列表
 *
 * @since 2022-09-28
 */
@Component
export struct DeleteList {
  @Consume navPathStack: NavPathStack;

  mScroller = new Scroller();

  @State @Watch('onDatasChange') datas: SelectEventInfo[] = [];

  @State dataSources: AgendaDataSource = new AgendaDataSource(this.datas);

  processor: DeleteEventProcessor = new DeleteEventProcessor();

  private accountId: number = 0;

  onSelectCountChange: (count: number) => void = (count: number) => {
  };

  onDeleteSuccess: () => void = (): void => {
  };

  /**
   * 监听 Datas 改变，触发 dataSources 改变，引起视图刷新
   */
  onDatasChange() {
    Log.info(TAG, `Delete list data length = ${this.datas?.length}`);
    this.dataSources.setData(this.datas);
    this.dataSources.notifyDataReload();
  }

  @Builder
  buildContent() {
    Column() {
      List({
        space: 0,
        initialIndex: 0,
        scroller: this.mScroller
      }) {
        LazyForEach(this.dataSources, (item: SelectEventInfo) => {
          ListItem() {
            if (item.getSelectEventType() === 1) {
              HeaderItem({ begin: item.mBegin });
            } else {
              EventContentItem({
                title: item.mTitle ? item.mTitle : $r('app.string.no_title_label'),
                color: item.mDisplayColor,
                begin: item.mBegin,
                end: item.mEnd,
                cornerType: item.mCornerType,
                location: item.mLocation,
                eventId: item.mId,
                isAllDay: item.mIsAllDay,
                eventProcessor: this.processor,
                checked: item.getSelected(),
                onCheckChanged: (eventId: number, val: boolean): void => this.onItemCheckChanged(eventId, val)
              })
            }
          }
        }, (item: SelectEventInfo) => JSON.stringify(item))
      }
      .borderRadius(16)
      .scrollBar(BarState.Off)
      .layoutWeight(1)

      DeleteToolBar({
        datas: $datas,
        dataProcessor: this.processor,
        onClickAllSelect: ($datas: boolean): void => this.onClickAllSelect($datas),
        onDeleteSuccess: (): void => this.onDeleteSuccess()
      });
    }
    .padding({ left: 12, right: 12 })
    .height("100%")
  }

  build() {
    NavDestination() {
      this.buildContent()
    }
  }

  onItemCheckChanged(eventId: number, check: boolean) {
    if (check) {
      this.processor.getSelectedEvents().add(eventId);
    } else {
      this.processor.getSelectedEvents().delete(eventId);
    }
    this.onSelectCountChange(this.processor.getSelectedEvents().size)
    this.datas.find((eventItem) => {
      return eventItem.mId === eventId;
    })?.setSelected(check);
    this.datas = this.datas.slice(0)
  }

  onClickAllSelect(isAllSelect: boolean) {
    if (!isAllSelect) {
      this.processor.getSelectedEvents().clear();
    }
    this.datas = [...this.datas.map(it => {
      if (it.mType === 0) {
        it.setSelected(isAllSelect);
        if (isAllSelect) {
          this.processor.getSelectedEvents().add(it.mId);
        }
      }
      return it;
    })];
    this.onSelectCountChange(this.processor.getSelectedEvents().size);
  }

  aboutToAppear() {
    this.datas = [];
    this.dataSources = new AgendaDataSource(this.datas);

    const params: PageParam[] = this.navPathStack.getParamByName(NavPathName.MULTI_DELETE) as PageParam[];
    if (!params[0]) {
      this.queryEventList();
      return;
    }
    const param: PageParam = params[0];
    this.accountId = param.accountId;
    this.queryEventList(this.accountId);
  }

  async queryEventList(accountId?: number) {
    let resultSet = await EventService.INSTANCE.queryEvents();
    if (!resultSet) {
      Log.error(TAG, 'query event list error');
      return;
    }
    let result: SelectEventInfo[] = await this.processor.getEventsList(resultSet);
    this.datas.push(...result);
  }
}