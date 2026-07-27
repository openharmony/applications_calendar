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
import { GlobalDataKeys, Log } from '@app/common';
import { MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';

// 涉及动效，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG: string = 'ListEdgeController';
const CARD_BOTTOM_GAP = 20; // 叠卡底部露出的部分
const MAX_CARD_Z_OFFSET = 200; // 叠卡背景卡最远Z轴偏移

/**
 * 月视图下日程列表 Item 的背板样式
 * V1.0 版本： 收编已存在的入场动效，实现日程列表边缘的的通用属性 主要用于列表边缘的计算
 */
class ListItemModifier implements AttributeModifier<ColumnAttribute> {
  // 通用属性
  /** 台历模式 */
  public isWallpaperMode: boolean = false;

  // 私有属性
  /** item 类型 */
  private itemType: ListItemType;

  /** item 索引值 */
  private index: number;

  constructor(itemType: ListItemType, index: number, isWallpaperMode?: boolean) {
    this.itemType = itemType;
    this.index = index;
    if (isWallpaperMode !== undefined) {
      this.isWallpaperMode = isWallpaperMode;
    }
  }

  applyNormalAttribute(instance: ColumnAttribute): void {
    if (this.isWallpaperMode) {
    } else {
    }
  }
}

/**
 * 月视图列表的边缘效果处理器
 * 同时处理叠卡 边缘渐隐等效果
 * 本类仅处理
 * 滑动叠卡原理：1、向z轴和y轴平移；2、延x轴向内旋转一定角度；通过 opacity、rotate、translate （itemType，index） 提供能力
 * 边缘渐隐原理：使用 linearGradientBlur 通过调节 listFadingOpacity 透明度实现
 */
@Observed
export class ListEdgeController {
  // 通用常量
  /** 功能使能 */
  public static LIST_EDGE_ENABLE: boolean = true;
  /** 台历模式 */
  private isWallpaperMode: boolean = false;
  /** 使能 边缘渐隐 模式 */
  private listEdgeMode: ListEdgeMode = ListEdgeMode.CARD_STACK;
  // 可变动效及参数
  /**列表的滑动控制器**/
  private scroller: Scroller | undefined;
  // 实时计算值
  /** 列表底部item 高度 */
  private endItemHeight: number = 0;
  /** 列表底部item上边距离容器底边的距离 */
  private endDistance: number = 0;
  /** 列表 叠卡动效固定item 的索引值 */
  private endFixIndex: number = 0;
  /** 列表 endFixIndex 对应的 item 在叠卡状态下 的离底边距 */
  private endDummyDistance: number = 0;
  /** 列表底部item的索引值 */
  private endIndex: number = 0;
  /** 列表顶部item的索引值 */
  private topIndex: number = 0;
  /** 列表高度 */
  private listHeight: number = 0;
  /** 顶部的Item */
  private listItems: ListItemParams[] = [
    { type: ListItemType.EMOTION_HOLIDAY, cnt: 0 },
    { type: ListItemType.NORMAL_AGENDA, cnt: 0 },
    { type: ListItemType.TASK_TODO, cnt: 0 },
    { type: ListItemType.IMPORTANT, cnt: 0 },
    { type: ListItemType.SCHEDULE, cnt: 0 },
    { type: ListItemType.SUBSCRIPTION_ITEM, cnt: 0 },
    { type: ListItemType.SUBSCRIPTION_RECOMMEND, cnt: 0 }
  ];
  /** 列表是否正在滚动(可能为用户操作的滑动，也可能为本类操作的滑动) */
  private isScrolling = false;
  /** 正在执行回弹动作(本类的操作，用于区分isScrolling的状态) */
  private isBouncing = false;
  /** 列表是否处于折叠态 ListEdgeMode.CARD_STACK 模式下才处理 用户输入 */
  public isListFold = false;
  /** 本类实例化时间 用于调试 **/
  private creatTag: string = '';
  // 对外暴露的动效参数
  /** 列表底端的渐出动效 */
  public listFadingOpacity: number = 0; // 此参数无法下沉到更深的VM内 否则动效会不跟手

  constructor() {
    this.creatTag = `_` + Date.now().toString();
    Log.info(TAG, `constructor this.creatTag = ${this.creatTag}`);
    // 切换台历模式后 本类会被重新实例化 因此每次需要从sp内取值
    this.isWallpaperMode = AppStorage.get<boolean>(GlobalDataKeys.IS_WALLPAPER_MODE) === true;
  }

  /**
   * 初始化各类参数设置
   * @param scroller 滚动控制器
   */
  public init(scroller?: Scroller) {
    // 初始化各类参数设置
    this.scroller = scroller;
  }

  /**
   * 更新列表顶部卡片内容
   * @param listItems
   */
  public refreshTopItems(listItems: ListItemParams[]) {
    Log.debug(TAG, `refreshTopItems ${this.creatTag} , Item Cnt:${listItems.map(item => `${item.type}:${item.cnt}`)
      .join(', ')}`);
    this.listItems = listItems;
  }

  /**
   * 是否禁用叠卡效果
   * 功能使能 && 台历模式 && 边缘处于叠卡模式 && 强制折叠 才能使用叠卡
   * @returns
   */
  private isCardStackDisable(): boolean {
    return !ListEdgeController.LIST_EDGE_ENABLE ||
      !this.isWallpaperMode || !this.isListFold ||
      this.listEdgeMode !== ListEdgeMode.CARD_STACK;
  }

  /**
   * 获取转场平移效果对象
   * @param index
   * @returns
   */
  translate(index: number): TranslateOptions {
    // 默认无动效
    let option: TranslateOptions = { x: 0, y: 0, z: 0 };
    if (this.isCardStackDisable()) {
      return option;
    }
    // 当为当前显示的第一个卡片时，有y轴向下的动效抵消向上的效果。z轴会使卡片缩小
    if (this.endFixIndex === index && this.endDistance >= 0 && this.endDummyDistance > 0) {
      option = {
        x: 0,
        y: (CARD_BOTTOM_GAP - this.endItemHeight) / this.endDummyDistance * this.endDistance,
        z: Math.min(this.endDistance / 2, MAX_CARD_Z_OFFSET),
      }
    }
    Log.info(TAG, `translate topIndex = ${this.topIndex}, endIndex = ${this.endIndex}, ` +
      `endDistance = ${this.endDistance}, endItemHeight = ${this.endItemHeight}` +
      `endDummyDistance = ${this.endDummyDistance}`);
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
    if (this.isCardStackDisable()) {
      return option;
    }
    // 当为当前显示的第一个卡片时，有向后的旋转效果
    if (this.endIndex === index && this.endDistance >= 0) {
      option = {
        x: 1,
        angle: this.endDistance / 15,
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
    if (this.isCardStackDisable()) {
      return opacity;
    }
    // 当为当前显示的第一个卡片时，有从0.8开始递减的透明效果
    if (this.endIndex === index && this.endDistance >= 0) {
      // Op = 1 - D/(H - 20) TODO 台历模式 待实现
      opacity = 1
    }
    return opacity;
  }

  /**
   * 获取 Item 在整个列表索引值
   * @param type Item的类型
   * @param index Item在整个 list 的索引值
   * @returns ListIndex
   */
  getListIndex(type: ListItemType, index: number): number {
    const typeIndex = ALL_CARD_ITEM.indexOf(type);
    let listIndex = index;
    if (typeIndex >= this.listItems.length) {
      Log.logErrorMsg(TAG, `getListIndex out of listItems bound,  typeIndex:${typeIndex}, len${this.listItems.length}`);
      return -1;
    }
    for (let i = 0; i < typeIndex; i++) {
      listIndex += this.listItems[i]?.cnt ?? 0;
    }
    return listIndex;
  }

  /**
   * List的onScrollIndex事件触发时，应同步调用本方法。
   * 该事件触发方式：
   * 有子组件划入或划出List显示区域时触发。计算索引值时，ListItemGroup作为一个整体占一个索引值，不计算ListItemGroup内部ListItem的索引值。
   * List的边缘效果为弹簧效果时，在List划动到边缘继续划动和松手回弹过程不会触发onScrollIndex事件。==>这里会导致边缘弹簧效果时无法触发叠卡动效
   * 触发该事件的条件：列表初始化时会触发一次，List显示区域内第一个子组件的索引值或最后一个子组件的索引值有变化时会触发。
   * start:List显示区域内第一个子组件的索引值;
   * end:List显示区域内最后一个子组件的索引值;
   * center:List显示区域内中间位置子组件的索引值。
   */
  public onScrollIndex(start: number, end: number, center: number) {
    if (!ListEdgeController.LIST_EDGE_ENABLE) {
      return;
    }
    this.topIndex = start;
    this.endIndex = end;
    if (this.endFixIndex === 0 || this.endDummyDistance === 0) {
      this.endFixIndex = end; // 若不为初值就赋值一次，避免首张卡出现叠卡效果
      try {
        if (!this.scroller) {
          return;
        }
        Log.info(TAG, `onScrollIndex, topIndex = ${this.topIndex},` +
          ` endIndex = ${this.endIndex}, endFixIndex = ${this.endFixIndex}`);
        const endRectResult: RectResult = this.scroller.getItemRect(this.endFixIndex);
        this.endDummyDistance = endRectResult.y + endRectResult.height - this.listHeight;
      } catch (err) {
        Log.logErrorMsg(TAG, 'onScrollIndex', err);
      }
    }
    Log.debug(TAG, `onScrollIndex  start = ${start}, end = ${end}`);
  }

  /**
   * List的onDidScroll事件触发时，应同步调用本方法，以实时获取到偏移量。
   * 该事件触发方式：
   * 列表滑动时触发。
   * 返回当前帧滚动的偏移量和当前滚动状态。
   */
  public onDidScroll(scrollOffset?: number, scrollState?: ScrollState) {
    if (!ListEdgeController.LIST_EDGE_ENABLE) {
      return;
    }
    try {
      if (!this.scroller) {
        return;
      }
      const endRectResult: RectResult = this.scroller.getItemRect(this.endIndex);
      if (endRectResult &&
        endRectResult.y !== undefined && endRectResult.y > 0 &&
        endRectResult.height !== undefined && endRectResult.height > 0) {
        this.endItemHeight = endRectResult.height;
        this.endDistance = endRectResult.y + endRectResult.height - this.listHeight;
      } else {
        Log.logErrorMsg(TAG, 'onDidScroll endRectResult illegal');
      }
      Log.debug(TAG, `onDidScroll  endIndex = ${this.endIndex},` +
        `${endRectResult.y} + ${endRectResult.height} - ${this.listHeight} endDistance = ${this.endDistance},` +
        `creatTime = ${this.creatTag}`);
    } catch (err) {
      Log.logErrorMsg(TAG, 'onDidScroll', err);
    }
  }

  /**
   * List的onReachEnd事件触发时，应同步调用本方法，以实现到底回弹。
   * 该事件触发方式：列表滑动到底部时触发。List边缘效果为弹簧效果时，划动经过末尾位置时触发一次，回弹回末尾位置时再触发一次。
   */
  public onReachEnd() {
    if (!ListEdgeController.LIST_EDGE_ENABLE) {
      return;
    }
    Log.info(TAG, 'onReachEnd is trigger');
    if (!this.scroller) {
      return;
    }
  }

  public onScrollStop() {
    if (!ListEdgeController.LIST_EDGE_ENABLE) {
      return;
    }
    Log.info(TAG, `onScrollStop is trigger, isBouncing:${this.isBouncing}`);
    this.isScrolling = false;
  }

  public onScrollStart() {
    if (!ListEdgeController.LIST_EDGE_ENABLE) {
      return;
    }
    Log.info(TAG, `onScrollStart is trigger, isBouncing:${this.isBouncing}`);
    this.isScrolling = true;
  }

  /**
   * 滚动到首张卡片
   */
  private scrollToFirstCardSmoothly(rectResult: RectResult ){
    Log.info(TAG, `scrollToTop, rectResult.y = ${rectResult.y}`);
    if (rectResult.y < 0 || this.topIndex !== 0) {
      // 首张卡片如果未处于列表开头
      animateToImmediately({
        duration: 300,
        curve: Curve.Smooth,
        onFinish: () => {
        }
      }, () => {
        if (!this.scroller) {
          return;
        }
        this.scroller?.scrollToIndex(0)
      })
    }
  }

  /**
   * 处理因 list 高度导致的叠卡动效
   */
  public processCardStackBySizeChange(listHeight: number) {
    if (this.listFadingOpacity !== 1) {
      this.listFadingOpacity = 1;
      Log.info(TAG, `processCardStackBySizeChange, listFadingOpacity set To ${this.listFadingOpacity}`);
    }
    /**
     * 滚动到首张卡片
     */
    try {
      if (!this.scroller) {
        Log.info(TAG, `processCardStackBySizeChange, scroller illegel`);
        return;
      }

      let rectResult: RectResult = this.scroller.getItemRect(0); // 首张卡片的索引值
      this.scrollToFirstCardSmoothly(rectResult);
    } catch (err) {
      Log.logErrorMsg(TAG, 'processCardStackBySizeChange', err);
    }


    /**
     * 设置列表高度 触发叠卡动效
     */
    animateToImmediately({
      duration: 100,
      curve: Curve.Smooth,
      onFinish: () => {
      }
    }, () => {
      try {
        this.listHeight = listHeight;
        Log.info(TAG, `processCardStackBySizeChange, endFixIndex = ${this.endFixIndex}`);
        if (!this.scroller) {
          return;
        }
        const endRectResult: RectResult = this.scroller.getItemRect(this.endFixIndex);
        this.endItemHeight = endRectResult.height;
        this.endDistance = endRectResult.y + endRectResult.height - this.listHeight;
      } catch (err) {
        Log.logErrorMsg(TAG, 'processEdgeFadingBySizeChange', err);
      }
    })
  }

  /**
   * 从月视图的状态变更触发 列表的折叠或展开
   * @param nowWeekShow
   */
  refreshListFold(nowWeekShow: boolean) {
    Log.info(TAG, `nowWeekShow:${nowWeekShow}`)
    animateToImmediately({
      duration: 300,
      curve: Curve.Smooth,
      onFinish: () => {
        if (this.isListFold) {
          this.endFixIndex = this.endIndex;
          try {
            if (!this.scroller) {
              return;
            }
            Log.info(TAG, `refreshListFold, endFixIndex = ${this.endFixIndex}`);
            const endRectResult: RectResult = this.scroller.getItemRect(this.endFixIndex);
            this.endDummyDistance = endRectResult.y + endRectResult.height - this.listHeight;
          } catch (err) {
            Log.logErrorMsg(TAG, 'refreshListFold', err);
          }
        }
      }
    }, () => {
      this.isListFold = !nowWeekShow;
    })
  }

  /**
   * 处理因 list 高度导致的边缘透明度动效
   */
  public processEdgeFadingBySizeChange(listHeight: number) {
    try {
      this.isListFold = false; // 取消折叠
      if (!this.scroller) {
        return;
      }
      let rectResult: RectResult = this.scroller.getItemRect(0); // 首张卡片的索引值
      this.scrollToFirstCardSmoothly(rectResult);
      const rectH = rectResult.height; // 第一个Item的高度
      if (listHeight > rectH) {
        this.listFadingOpacity = 0;
        Log.info(TAG, `listFadingOpacity set To ${this.listFadingOpacity}, topIndex ${this.topIndex}, ` +
          ` listHeight:${listHeight}, rectH:${rectH}`)
        return;
      }
      const maxOp = 80; // 最大的透明度
      const maxDeltaH = 50; // 达到 maxOP时 边缘移动的最大高度
      if (listHeight < rectH - maxDeltaH) {
        this.listFadingOpacity = maxOp;
        Log.info(TAG, `listFadingOpacity set To ${this.listFadingOpacity}, topIndex ${this.topIndex}, ` +
          ` listHeight:${listHeight}, rectH:${rectH}`)
        return;
      }
      const factor = maxOp / maxDeltaH; // 参数越大 此处的
      this.listFadingOpacity = factor * (rectH - listHeight);
      Log.info(TAG, `listFadingOpacity set To ${this.listFadingOpacity}, topIndex ${this.topIndex}, ` +
        ` listHeight:${listHeight}, rectH:${rectH}`)
    } catch (err) {
      Log.logErrorMsg(TAG, 'processEdgeFadingBySizeChange', err);
    }
  }

  /**
   * 设置列表的边缘模式
   * TODO 台历模式 此处需要在内容数据变动、日期变动时响应
   * @param listEdgeMode
   */
  public setEdgeMode(listEdgeMode: ListEdgeMode) {
    this.listEdgeMode = listEdgeMode;
  }

  /**
   * 设置列表高度
   */
  public setListHeight(listHeight: number) {
    this.listHeight = listHeight;
    Log.debug(TAG, `setListHeight ${this.listHeight}, creatTime = ${this.creatTag}`);
  }

  /**
   * 处理 List 高度变更
   * @param newValue
   */
  public handleSizeChange(newValue: SizeOptions) {
    const topItem: ListItemParams = this.getTopItem(this.listItems);
    Log.debug(TAG + this.creatTag, `onSizeChange, width: ${newValue.width}, height: ${newValue.height},` +
      ` topItem${JSON.stringify(topItem)} isWeekShow: ${MonthlyViewStateManager.getInstance()
        .weekState
        .isWeekShow}`);
    const listHeight: number = Number(newValue.height);
    this.setListHeight(listHeight);
    if (!topItem || topItem?.type === ListItemType.NONE) {
      // 当前无日程
      return;
    }
    if (BIG_CARD_ITEM.includes(topItem.type)) {
      // 若为大卡》渐隐方案
      // 第二个Item出现的时候 取消渐隐 onIndex(SecondIndex) o = MaxOpacity * (H_now / Max_H)
      Log.info(TAG, 'Process big card');
      this.setEdgeMode(ListEdgeMode.EDGE_FADING);
      this.processEdgeFadingBySizeChange(listHeight);
    } else {
      // 若为小卡》叠卡方案
      // 当前高度<前两张卡高度和 》 初始叠卡状态 H = firstHeight + Affine (secondHeight) + blankHeight
      // 叠卡根据高度过渡 》 过渡叠卡状态 H’ = firstHeight + Affine (secondHeight)-> SecondHeight + blankHeight -> 0
      // 当前高度>=前两张卡高度和 》 完全展开 不做叠卡 H’' = FirstHeight + SecondHeight + ...
      Log.info(TAG, 'Process small card');
      this.setEdgeMode(ListEdgeMode.CARD_STACK);
      this.processCardStackBySizeChange(listHeight);
    }
  }

  /**
   * 从当前的列表类型中 找到首张卡的类型
   * @param itemTypes
   * @returns
   */
  private getTopItem(itemTypes: ListItemParams[]): ListItemParams {
    const topTypes: ListItemParams[] = [];
    let remainingSlots = 1;

    for (const item of itemTypes) {
      if (item.cnt > 0) {
        topTypes.push(item);
        remainingSlots -= 1;
        if (remainingSlots <= 0) {
          break;
        }
      }
    }

    if (remainingSlots === 1) {
      return { type: ListItemType.NONE, cnt: 0 };
    }
    return topTypes[0];
  }

  /**
   * 点击 Item 空白位置，展开列表
   * @param index
   */
  public onClickItem(index: number) {
    if (this.endFixIndex !== index) {
      return;
    }
    animateToImmediately({
      duration: 300,
      curve: Curve.Smooth,
      onFinish: () => {
      }
    }, () => {
      this.isListFold = false;
    })
  }
}

/**
 * 月视图列表内容物的类型枚举值
 */
export enum ListItemType {
  EMOTION_HOLIDAY = 'emotion_holiday',
  NORMAL_AGENDA = 'normal_agenda',
  TASK_TODO = 'task_todo',
  IMPORTANT = 'important',

  SCHEDULE = 'schedule',
  SUBSCRIPTION_ITEM = 'subscription_item',
  SUBSCRIPTION_RECOMMEND = 'subscription_recommend',

  NONE = 'none' // 没有日程
}


/**
 * 月视图列表边缘效果 枚举值
 */
export enum ListEdgeMode {
  EDGE_FADING = 'edge_fading', // 边缘渐隐
  CARD_STACK = 'card_stack', // 叠卡模式
  NONE = 'none', // 不处理边缘效果
}

// 大卡类型
export const BIG_CARD_ITEM = [ListItemType.SCHEDULE, ListItemType.SUBSCRIPTION_ITEM,
  ListItemType.SUBSCRIPTION_RECOMMEND];


// 所有卡片的类型
export const ALL_CARD_ITEM = [
  ListItemType.EMOTION_HOLIDAY,
  ListItemType.NORMAL_AGENDA,
  ListItemType.TASK_TODO,
  ListItemType.IMPORTANT,
  ListItemType.SCHEDULE,
  ListItemType.SUBSCRIPTION_ITEM,
  ListItemType.SUBSCRIPTION_RECOMMEND
];

// List 所有item的种类和数目
export interface ListItemParams {
  type: ListItemType,
  cnt: number
}

// 单个列表 Item 的索引值
export interface ListItemIndex{
  type: ListItemType,
  itemIndex: number
}