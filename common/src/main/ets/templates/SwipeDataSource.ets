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

/*
* Swipe 组件在默认情况下初始索引为0
* 当前 年月周视图 为避免单页组件重新创建, 默认开启循环播放
* 以 3个Swipe 为例 [] 标识当前页
* 初始状态:  2  [0]  1
* 滑动一次:  2   0  [1] 此时 当前索引为 1, [滑动方向]上下一页[2]数据需要准备
* 再次滑动: [2]  0   1  此时 当前索引为 2, [滑动方向]上下一页[0]数据需要准备
* 再次滑动:  2  [0]  1  此时 当前索引为 0, [滑动方向]上下一页[1]数据需要准备
* 反向滑动: [2]  0   1  此时 当前索引为 2, [滑动方向]上下一页[1]数据需要准备
*
* 以 5 个SWIPE为例 []标识当前页
* 初始状态:  3  4 [0]  1   2
* 滑动一次:  3  4  0  [1]  2
* 再次滑动:  3  4  0   1  [2]
* 再次滑动: [3] 4  0   1   2
*/

/*
 * 页面信息, 抽象递增递减接口
 */
export abstract class SwipeInfo {
  // 获取递增后的信息
  public abstract increase() : SwipeInfo;
  // 获取递减后的信息
  public abstract decrease() : SwipeInfo;
}

/*
 * 单个SwiperViewModel抽象类
 */
export abstract class SingleSwipeViewModel {
  // 对应的index初始化后保持不变,变化的是数据
  public readonly index: number = -1;
  public info: SwipeInfo;
  constructor(index: number, info : SwipeInfo) {
    this.index = index;
    this.info = info;
  }

  // 初始化接口
  init() {
    this.update(this.info);
  }

  // 前向指针
  private _previous: SingleSwipeViewModel | undefined;
  public getPrevious() : SingleSwipeViewModel | undefined {
    return this._previous;
  }
  public setPrevious(data : SingleSwipeViewModel) {
    this._previous = data;
  }

  // 后向指针
  private _next: SingleSwipeViewModel | undefined;
  public getNext() : SingleSwipeViewModel | undefined {
    return this._next;
  }
  public setNext(data : SingleSwipeViewModel) {
    this._next = data;
  }

  // ShowNext回调
  public onShowNext() {
    // 根据上一个页面的数据来递增本页面数据
    let previousData = this.getPrevious();
    if (previousData) {
      const info = previousData.info;
      this.info = info.increase();
    }
    // 触发私有ShowNext回调
    this.innerOnShowNext(this.info);
  }

  // ShowPrevious回调
  public onShowPrevious() {
    let nextData = this.getNext();
    if (nextData) {
      const info = nextData.info;
      this.info = info.decrease();
    }
    // 触发私有ShowPrevious回调
    this.innerOnShowPrevious(this.info);
  }

  // 根据指定SwipeInfo刷新
  public update(info : SwipeInfo) {
    this.info = info;
    this.innerUpdate(info);
  }

  public abstract innerUpdate(info : SwipeInfo) : void;
  public abstract innerOnShowNext(info : SwipeInfo): void;
  public abstract innerOnShowPrevious(info : SwipeInfo): void;
}

export class SwipeDataSource {
  private dataLength: number = 0;
  public singleVMs: SingleSwipeViewModel[] = [];
  public curData : SingleSwipeViewModel | null = null;
  public getData(index: number): SingleSwipeViewModel | null {
    return index >= 0 && index < this.dataLength ? this.singleVMs[index] : null;
  }
  /*
  * curIndex 当前索引值
  * */
  constructor(curIndex: number) {
    this._curIndex = curIndex;
  }

  initData(singleVMs: SingleSwipeViewModel[]) {
    this.singleVMs = singleVMs;
    this.dataLength = singleVMs.length;
    this.curData = this.singleVMs[this._curIndex];
    // 互相连接 构建双端循环链表
    for (let i = 0; i < this.dataLength - 1; i++) {
      this.singleVMs[i].setNext(this.singleVMs[i + 1]);
    }
    for (let i = this.dataLength - 1; i > 0; i--) {
      this.singleVMs[i].setPrevious(this.singleVMs[i - 1])
    }
    this.singleVMs[0].setPrevious(this.singleVMs[this.dataLength - 1]);
    this.singleVMs[this.dataLength - 1].setNext(this.singleVMs[0]);
  }

  private _curIndex: number = 0;

  get curIndex(): number {
    return this._curIndex;
  }

  private getNextIndex() : number {
    if (this.curIndex === this.dataLength - 1) {
      // [2]  0   1  =>  2  [0]  1
      return 0;
    } else {
      //  2  [0]  1  =>  2   0  [1]
      return this.curIndex + 1;
    }
  }

  private getPreviousIndex() : number {
    if (this.curIndex === 0) {
      //  2  [0]  1  =>  [2]   0  1
      return this.dataLength - 1;
    } else {
      // [2]  0   1  =>  2  0  [1]
      return this._curIndex - 1;
    }
  }
  // 向前滑动
  onShowNext() {
    // 1. 刷新当前索引到下一个
    this._curIndex = this.getNextIndex();
    this.curData = this.singleVMs[this._curIndex];
    // 2. 通知下一个页面刷新数据
    this.curData.getNext()?.onShowNext();
  }

  // 向后滑动, 需要更新上一个的上一个数据
  onShowPrevious() {
    // 1. 当前索引刷新到上一个页面
    this._curIndex = this.getPreviousIndex();
    this.curData = this.singleVMs[this._curIndex];
    // 2. 通知上一个页面准备数据
    this.curData.getPrevious()?.onShowPrevious();
  }

  // 根据指定信息刷新
  public updateByInfo(curIndexInfo: SwipeInfo) {
    let curData = this.singleVMs[this.curIndex];
    // 1. 当前索引刷新
    curData.update(curIndexInfo);
    // 2. Next页面使用递增后数据刷新
    curData.getNext()?.update(curIndexInfo.increase());
    // 2. Previous页面使用递减后数据刷新
    curData.getPrevious()?.update(curIndexInfo.decrease());
  }
}