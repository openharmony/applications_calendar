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
import { Log, ThrottleFunction } from '@app/common';

// 涉及动效，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG: string = 'SlidingStackHelper';

/**
 * 滑动叠卡处理器
 * 滑动叠卡原理：1、向z轴和y轴平移；2、延x轴向内旋转一定角度；
 */
@Observed
export class SlidingStackHelper {
  // 通用常量
  /** 叠卡功能使能 */
  public static readonly SLIDING_STACK_ENABLE: boolean = false;
  /** 叠卡顶部偏移量 */
  public static readonly CONTENT_START_OFFSET: number = 15;
  /** 摩擦系数 越大阻力越强 */
  public static readonly FRICTION: number = 1;
  // 可变动效及参数
  /** 列表项滚动结束对齐效果 */
  public scrollSnapAlign: ScrollSnapAlign = ScrollSnapAlign.NONE;
  /** 列表的滑动控制器 */
  private scroller: Scroller | undefined;
  // 实时计算值
  /** 列表顶部item上边距离容器上边的距离 */
  public topDistance: number = 0;
  /** 列表滑动时顶部item的索引值 */
  public topIndex: number = 0;
  /** 已过期的卡片数量，过期卡片在初始化时自动堆叠 */
  private expiredCardNums: number = 0;
  /** 各模块数量，用于判断分割线显示，不分块时此值无效。用于分片处理，多块之前有分割线,当前逻辑仅支持两片 */
  public partNums: number[] = [];
  /** 总item数量 */
  public totalNums: number = 0;
  /** 列表是否正在滚动(可能为用户操作的滑动，也可能为本类操作的滑动) */
  private isScrolling = false;
  /** 正在执行回弹动作(本类的操作，用于区分isScrolling的状态) */
  private isBouncing = false;
  /** 滑动到底时的topIndex,用户判断滑动结束时是否到底 */
  private reachEndTopIndex: number = -1;
  /** 最少可显示的item数量，直板机正常页面能显示5张卡片，若未过期日程小于5,则使其滑到能显示5张卡片 */
  private leastShowNum: number = 5;

  /**
   * 初始化各类参数设置
   * @param scroller 滚动控制器
   * @param scrollSnapAlign 滚动对齐效果类型
   * @param leastShowNum 列表满屏最少展示的item数量
   */
  public init(scroller?: Scroller, scrollSnapAlign: ScrollSnapAlign = ScrollSnapAlign.NONE, leastShowNum: number = 5) {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    // 初始化各类参数设置
    this.scroller = scroller;
    this.scrollSnapAlign = scrollSnapAlign;
    this.leastShowNum = leastShowNum;
  }

  /**
   * 更新卡片分片数量
   * @param expiredCardNums
   */
  public refreshNums(partNums: number[]) {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    Log.info(TAG, `refreshNums，before:${this.partNums},after:${partNums}`)
    this.partNums = partNums;
    let totalNums = 0;
    for (let num of this.partNums) {
      totalNums += num;
    }
    this.totalNums = totalNums;
    if (totalNums > 0) {
      // 避免初始化时未加载完数据的触底记录了触底索引reachEndTopIndex，导致其值错乱
      this.reachEndTopIndex = this.totalNums
    }
    Log.info(TAG, `totalNums:${this.totalNums}`);
  }

  /**
   * 更新过期卡片数量
   * @param expiredCardNums
   */
  public changeExpiredNums(expiredCardNums: number) {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    Log.info(TAG, `expiredCardNums change，before:${this.expiredCardNums},after:${expiredCardNums}`)
    this.expiredCardNums = expiredCardNums;
  }

  /**
   * 是否有分割线，判断两个分片间是否应该有分割线
   * @param part1
   * @param part2
   * @returns
   */
  private hasDivider(index: number, part1Index: number = 0, part2Index: number = 1) {
    if (!this.isPartLast(index)) {
      return false;
    }
    // 如果有一个长度为0则不展示
    if (this.partNums[part1Index] <= 0 || this.partNums[part2Index] <= 0) {
      return false;
    }
    return true;
  }

  /**
   * 是否part的最后一个
   * @param index
   * @param part1
   * @returns
   */
  private isPartLast(index: number, part1: number = 0): boolean {
    return index == this.partNums[part1] - 1;
  }

  /**
   * 滑动到过期卡片位置
   */
  public scrollToExpired() {
    if (!this.scroller) {
      return;
    }
    Log.info(TAG, 'scrollToExpired,expiredCardNums:' + this.expiredCardNums);
    // 不足一屏，不叠卡，直接置顶
    if (this.totalNums <= this.leastShowNum) {
      this.scrollToTop();
      return;
    }
    let scrollIndex = 0;
    // 若去除过期日程后不足一屏，则叠到刚好展示一屏为止。若足够展示，则过期日程全部叠起
    if (this.totalNums - this.expiredCardNums < this.leastShowNum) {
      // 当有7个日程时，要滑到第3个才能展示后5个，第3个的指针为2，2=7-5
      scrollIndex = this.totalNums - this.leastShowNum;
    } else {
      // 当过期日程为3个时，应滑动到第4个，其指针为3 ，故滑动下标等于过期item数量。
      scrollIndex = this.expiredCardNums;
    }
    // 滑动到第4个时，顶部item其实为第3个，即被滑动盖住漏了头的那张卡，故首指针下标为滑动下标-1
    this.topIndex = scrollIndex - 1;
    this.scrollToIndex(scrollIndex, false);
  }

  /**
   * 滑动到顶部
   */
  public scrollToTop() {
    this.topIndex = 0;
    this.scrollToIndex(this.topIndex, false);
    Log.info(TAG, `scrollToTop topIndex:${this.topIndex}`);
  }

  /**
   * 滑动到指定index，增加防抖，避免多处重复调用
   * @param value
   * @param smooth
   */
  private scrollToIndex(value: number, smooth?: boolean) {
      Log.info(TAG, `do scrollToIndex start value:${value} smooth:${smooth}`);
      this.scroller?.scrollToIndex(value, smooth);
      Log.info(TAG, `do scrollToIndex end value:${value} smooth:${smooth}`);
  }

  /**
   * 获取转场平移效果对象
   * @param index
   * @returns
   */
  translate(index: number): TranslateOptions {
    // 默认无动效
    let option: TranslateOptions = { x: 0, y: 0, z: 0 };
    // 当为当前显示的第一个卡片时，有y轴向下的动效抵消向上的效果。z轴会使卡片缩小
    if (this.topIndex === index && this.topDistance <= 0) {
      option = {
        x: 0,
        y: -this.topDistance,
        z: -this.topDistance / 2,
      }
    }
    return option;
  }

  /**
   * 获取旋转效果对象
   * @param index
   * @returns
   */
  rotate(index: number): RotateOptions {
    // 默认无动效
    let option: RotateOptions = { x: 1, angle: 0 };
    // 当为当前显示的第一个卡片时，有向后的旋转效果
    if (this.topIndex === index && this.topDistance <= 0) {
      option = {
        x: 1,
        angle: -this.topDistance / 15,
      }
    }
    return option;
  }

  /**
   * 获取不透明度
   * @param index
   * @returns
   */
  opacity(index: number) {
    let opacity: number = 1;
    // 当为当前显示的第一个卡片时，有从0.8开始递减的透明效果
    if (this.topIndex === index && this.topDistance <= 0) {
      const temp = this.topDistance < -80 ? (2.25 + 2.25 * this.topDistance / 100) :
        (0.8 + 0.35 * this.topDistance / 80)
      opacity = temp < 0 ? 0 : temp; // 调整退场是间距与透明度的 分段关系 0->0.8 -78->0.45 -110->0
    }
    return opacity;
  }

  /**
   * List的onScrollIndex事件触发时，应同步调用本方法。
   * 该事件触发方式：
   * 有子组件划入或划出List显示区域时触发。计算索引值时，ListItemGroup作为一个整体占一个索引值，不计算ListItemGroup内部ListItem的索引值。
   * List的边缘效果为弹簧效果时，在List划动到边缘继续划动和松手回弹过程不会触发onScrollIndex事件。==>这里会导致边缘弹簧效果时无法触发叠卡动效
   * 触发该事件的条件：列表初始化时会触发一次，List显示区域内第一个子组件的索引值或最后一个子组件的索引值有变化时会触发。
   * start:List显示区域内第一个子组件的索引值;end:List显示区域内最后一个子组件的索引值; center:List显示区域内中间位置子组件的索引值。
   */
  public onScrollIndex(start: number, end: number, center: number) {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    this.topIndex = start;
  }

  /**
   * List的onDidScroll事件触发时，应同步调用本方法，以实时获取到偏移量。
   * 该事件触发方式：
   * 列表滑动时触发。
   * 返回当前帧滚动的偏移量和当前滚动状态。
   */
  public onDidScroll(scrollOffset?: number, scrollState?: ScrollState) {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    try {
      if (!this.scroller) {
        return;
      }
      let rectResult: RectResult = this.scroller.getItemRect(this.topIndex);
      if (rectResult) {
        this.topDistance = rectResult.y;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'onDidScroll', err);
    }
  }

  /**
   * List的onReachEnd事件触发时，应同步调用本方法，以实现到底回弹。
   * 该事件触发方式：列表滑动到底部时触发。List边缘效果为弹簧效果时，划动经过末尾位置时触发一次，回弹回末尾位置时再触发一次。
   */
  public onReachEnd() {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    Log.info(TAG, 'onReachEnd is trigger');
    if (!this.scroller) {
      return;
    }
    // item数量小于最小可展示数量时，不触发触底滑动
    if (this.totalNums <= 1) {
      Log.info(TAG, `totalNums:${this.totalNums} donothing`);
      return;
    }
    this.reachEndTopIndex = this.topIndex;
    Log.info(TAG, `reachEnd,reachEndTopIndex：${this.reachEndTopIndex}`);
    this.scrollSnapAlign = ScrollSnapAlign.START
  }

  public onScrollStop() {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    Log.info(TAG, `onScrollStop is trigger, isBouncing:${this.isBouncing}`);
    this.isScrolling = false;
    // 初始化时还没有item，不触发滑动。
    if (this.totalNums <= 0) {
      Log.info(TAG, 'no item donothing');
      return;
    }
  }

  public onScrollStart() {
    if (!SlidingStackHelper.SLIDING_STACK_ENABLE) {
      return;
    }
    Log.info(TAG, `onScrollStart is trigger, isBouncing:${this.isBouncing}`);
    this.isScrolling = true;
  }
}