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
  CommonInnerEvent,
  Log,
  ThrottleFunction,
  AgendaListDataSource,
  SlideActionType
} from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';
import Curves from '@ohos.curves';


const TAG = 'AgendaListBaseModel';

// 滚动速度: 贝塞尔曲线
const SLIDE_SELECT_SPEED_CURVE = Curves.cubicBezierCurve(0.33, 0, 0.67, 1);

// 滑动多选时，滚动条滚动的方向
export enum ListScrollDir {
  NONE = 'NONE',
  TOP = 'TOP',
  BOTTOM = 'BOTTOM'
}

/**
 * 用于抽出全部日程列表和搜索日程列表中公用函数及方法的model
 */
@Observed
export class AgendaListBaseModel {
  // 列表滚动控制器
  public mScroller: Scroller = new Scroller();
  // 懒加载日程数据源
  @Track public dataSources: AgendaListDataSource = new AgendaListDataSource([]);

  // 以下是滑动多选的参数
  public readonly CHECK_BOX_WIDTH: number = 48; // 列表形式下滚动区域的宽度
  private slideChecked: boolean = false; // 本次滑动多选的选中状态
  private startIndex: number = -1; // 滑动的初始点位
  private updateIndex: number = -1; // 滑动的实时点位
  private lastUpdateIndex: number = -1; // 滑动的最后变更点位
  private scrollStartIndex: number = 0; // 记录文件的开始下标
  private scrollEndIndex: number = 0;
  private scrollDirection: ListScrollDir = ListScrollDir.NONE;
  private canSlideSelect: boolean = true; // 用于标识初始滑动是否落在可多选的item上
  private isAutoScroll: boolean = false; // 是否处于滑动多选自动滚动状态
  private contentHeight: number = 0; // 当前List的高度
  private oldCheckList: boolean[] = []; // 每次滑动时，当前选中的点
  private _nowSelectCount: number = 0; // 当前已选中的日程数量,用于页面上总选中数量的变更

  // 热区
  private readonly HOT_AREA_LENGTH: number;
  // 滚动速度: 最大速度
  private readonly AUTO_SPEED_MAX: number;

  constructor() {
    try {
      // 通过display获取屏幕密度和dpi比率以确定触发滑动的热区以及滑动的最大速率
      const defaultDisplay = display.getDefaultDisplaySync();
      this.HOT_AREA_LENGTH = Math.round(defaultDisplay.densityDPI * 10 / 25.4 / defaultDisplay.densityPixels);
      this.AUTO_SPEED_MAX = Math.round(2400 / defaultDisplay.densityPixels);
    } catch (err) {
      //获取失败,给定一个默认值
      Log.logErrorMsg(TAG, `getDefaultDisplay err`, err);
      this.HOT_AREA_LENGTH = 60;
      this.AUTO_SPEED_MAX = 700;
    }
  }

  /**
   * 滑动多选操作
   * @param type 0：start,1:update,2:end
   * @param event
   */
  panGestureAction(type: SlideActionType, finger: FingerInfo): void {
    // 当前操作的文件index
    const index = this.getIndex(finger);
    switch (type) {
      case SlideActionType.START: {
        this.slideActionStart(index);
        break;
      }
      case SlideActionType.UPDATE: {
        this.slideActionUpdate(index);
        this.autoScroll(finger);
        break;
      }
      case SlideActionType.END: {
        this.slideActionEnd();
        break;
      }
      default: {
        Log.info(TAG, `no slide action type ${type}`);
      }
    }
  }

  /**
   * 获取当前点位
   * @param finger
   * @returns
   */
  getIndex(finger: FingerInfo): number {
    // 初始化数据
    let index = -1;
    if (this.scrollStartIndex > this.scrollEndIndex) {
      Log.error(TAG, `getScrollIndex err scrollIndex ${this.scrollStartIndex} to ${this.scrollEndIndex}`);
      return index;
    }
    try {
      if (this.mScroller.getItemIndex) { // 兼容性操作,防止某些版本api不存在此方法导致闪退
        index = this.mScroller.getItemIndex(finger.localX, finger.localY);
      }
      if (index === -1) {
        for (let i = this.scrollStartIndex; i <= this.scrollEndIndex; i++) {
          const item = this.mScroller.getItemRect(i);
          if (finger.localY < item.y ||
            finger.localY >= item.y && finger.localY <= item.y + item.height && finger.localX < item.x) {
            break;
          }
          index = i;
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `getScrollIndex err`, err);
      return index;
    }
    // 滚动条向上滑动时，
    if (index === -1 && this.scrollDirection === ListScrollDir.TOP) {
      index = this.scrollStartIndex;
    }
    // 此处是用于去掉抬头标识以确定日程数据的index,当前日程列表存在抬头listItem且始终占位
    index = index - 1;

    return Math.max(index, 0);
  }

  /**
   * 自动滚动
   * @param finger
   */
  public autoScroll(finger: FingerInfo): void {
    // 不可多选
    if (!this.canSlideSelect) {
      Log.info(TAG, `can not slide select`);
      return;
    }
    let pointY = finger.localY;
    if (pointY <= this.HOT_AREA_LENGTH) { // 当前的Y坐标小于上方热区,向上滚动
      if (this.isAutoScroll && pointY <= 0) { // 处于自动滚动状态且超出组件则停止滚动
        return;
      }
      const speedFlag = pointY > 0 ? SLIDE_SELECT_SPEED_CURVE
        .interpolate(1 - pointY / this.HOT_AREA_LENGTH) : 1; // 滚动速度标识
      this.mScroller.scrollEdge(Edge.Top, {
        velocity: speedFlag * this.AUTO_SPEED_MAX
      });
      this.scrollDirection = ListScrollDir.TOP; // 标识当前滚动方向
      this.isAutoScroll = true;
    } else if (pointY > this.contentHeight - this.HOT_AREA_LENGTH) { // 当前的Y坐标处于下方热区,向下滚动
      if (this.isAutoScroll && pointY >= this.contentHeight) { // 处于自动滚动状态且超出组件则停止滚动
        return;
      }
      const speedFlag = pointY < this.contentHeight ? SLIDE_SELECT_SPEED_CURVE
        .interpolate(1 - (this.contentHeight - pointY) / this.HOT_AREA_LENGTH) : 1; // 滚动速度标识
      this.mScroller.scrollEdge(Edge.Bottom, {
        velocity: speedFlag * this.AUTO_SPEED_MAX
      })
      this.scrollDirection = ListScrollDir.BOTTOM; // 标识当前滚动方向
      this.isAutoScroll = true;
    } else {
      if (this.isAutoScroll) { // 处于自动滚动状态
        this.mScroller.scrollBy(0, 0); // 停止滚动
        this.scrollDirection = ListScrollDir.NONE; // 标识当前滚动方向
        this.isAutoScroll = false;
      }
    }
  }

  /**
   * 开始滑动多选-配置滑动过程中的初始数据
   * @param index
   */
  slideActionStart(index: number): void {
    if (index < 0) { // 日程数据下标获取异常
      Log.info(TAG, `slideAction start get index err -1`);
      return;
    }
    const list = this.dataSources.getDataList();
    if (index >= list.length) { // 日程数据下标获取异常
      Log.info(TAG, `slideAction start get index err -1`);
      return;
    }
    this.oldCheckList = list.map(it => it.isSelected); // 记录当前选中状态
    const targetAgenda = list[index]; // 获取初始选中的日程
    if (!targetAgenda) { // index异常
      Log.error(TAG, `slideAction start get index item err ${index}`);
      return;
    }
    // 当初始接触时不可滑动多选时，直接返回。
    if (!targetAgenda.canMultiSelect()) {
      this.updateCanSlideSelect(false);
      return;
    }
    // 初始日程选中状态已更新,需要更新选中日程数量
    this.nowSelectCount = this.nowSelectCount + (targetAgenda.isSelected ? -1 : 1);
    this.slideChecked = !targetAgenda.isSelected;
    this.startIndex = index;
    targetAgenda.isSelected = this.slideChecked;
    this.updateIndex = index;
    Log.info(TAG, `pageGesture start: ${this.startIndex},${index}`);
  }

  /**
   * 滑动多选中
   * @param index
   */
  slideActionUpdate(index: number): void {
    if (!this.canSlideSelect) {
      Log.info(TAG, `can not slide select`);
      return;
    }
    if (this.startIndex === -1) {
      //（初始接触点在空隙）时，重新配置滑动的初始数据
      this.slideActionStart(index);
      return;
    }
    if (index === -1) {
      Log.info(TAG, `no slide on agendaInfo`);
      return;
    }
    // 1.滑动选择的项没有发生变化。2、滚动条向下滚动时，滑动选择的项应该依次递增。3、滚动条向上滚动时，滑动选择的项应该依次递减
    if (this.updateIndex === index ||
      (this.scrollDirection === ListScrollDir.BOTTOM && index < this.updateIndex) ||
      (this.scrollDirection === ListScrollDir.TOP && index > this.updateIndex)) {
      return;
    }
    this.lastUpdateIndex = this.updateIndex;
    this.setAgendaListSourceChecked(index);
    this.updateIndex = index;
  }

  /**
   * 重置列表数据中的选中项
   */
  setAgendaListSourceChecked(index: number): void {
    const beginIndex = this.lastUpdateIndex === -1 ? this.startIndex : this.lastUpdateIndex;
    const agendaLength = this.dataSources.totalCount();
    const start = Math.min(beginIndex, index, agendaLength - 1);
    const end = Math.max(beginIndex, index, 0);
    // 滑动多选经过的item选中状态变更
    for (let i = start; i < end + 1; i++) {
      const item = this.dataSources.getDataList()[i];
      if (!item) {
        continue;
      }
      if (item.canMultiSelect()) {
        const isChecked = this.getCheckedByIndex(index, i); // 获取滑动过程中选中的日程状态变更
        if (item.isSelected !== isChecked) { // 选中状态更新时刷新总选中数量
          this.nowSelectCount = this.nowSelectCount + (isChecked ? 1 : -1);
        }
        item.isSelected = isChecked;
      } else {
        item.isSelected = false;
      }
    }
  }

  /**
   * 获取targetIndex处的item的选中状态
   * @param currentIndex
   * @param targetIndex
   * @returns
   */
  getCheckedByIndex(currentIndex: number, targetIndex: number): boolean {
    const lastIndex = this.lastUpdateIndex === -1 ? this.startIndex : this.lastUpdateIndex;
    if (currentIndex >= lastIndex && lastIndex >= this.startIndex ||
      currentIndex <= lastIndex && lastIndex <= this.startIndex) {
      // 上次的点位在起始点和当前点位之间（上次点位和此次点位之间的数据都为初始点位的选中状态）
      return this.slideChecked;
    } else {
      // 起始点在中间（起始点位到当前点位之间的数据的选中状态和其实点位保持一致，起始点位和上次选中点位的状态复原）
      return targetIndex >= this.startIndex && targetIndex <= currentIndex ||
        targetIndex <= this.startIndex && targetIndex >= currentIndex ? this.slideChecked :
      this.oldCheckList[targetIndex]; // 重置为滑动多选之前的状态
    }
  }

  /**
   * 滑动结束,情况参数
   */
  slideActionEnd(): void {
    this.startIndex = -1;
    this.oldCheckList = [];
    this.updateIndex = -1;
    this.updateCanSlideSelect(true);
    this.mScroller.scrollBy(0, 0);
    this.isAutoScroll = false;
    this.scrollDirection = ListScrollDir.NONE;
    // 在结束后再发送通知,整体变更当前选中状态
    ThrottleFunction.instance().debounceInstant(TAG, () => {
      emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED });
    })

    Log.info(TAG, `slide action end`);
  }

  /**
   * 更新当前list高度
   * @param height
   */
  public updateListHeight(height: number) {
    this.contentHeight = height;
  }

  /**
   * 更新当前list展示的index范围
   * @param start
   * @param end
   */
  public updateScrollStartIndex(start: number, end: number) {
    this.scrollStartIndex = start;
    this.scrollEndIndex = end;
  }

  /**
   * 更新当前可多选滚动状态
   * @param height
   */
  public updateCanSlideSelect(canSlideSelect: boolean) {
    this.canSlideSelect = canSlideSelect;
  }


  /**
   * 更新当前已选中的日程,此处为初始化时调用用于滑动过程中的选中计算
   * @param selectCount
   */
  public set nowSelectCount(selectCount: number) {
    this._nowSelectCount = selectCount;
  }

  public get nowSelectCount(): number {
    return this._nowSelectCount;
  }
}