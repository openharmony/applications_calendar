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
import { SingleInstanceHelper } from '@app/common';
import { AgendaBlockInfo } from './WeekAgendaBlockModel';

const TAG = 'WeekAgendaState';

@Observed
export class WeekAgendaState {
  private _showPopup: boolean = false;

  public agendaBlockState: AgendaBlockStateManagement = new AgendaBlockStateManagement();

  static getInstance(): WeekAgendaState {
    return SingleInstanceHelper.createOrGet(WeekAgendaState, 'WeekAgendaState');
  }

  set showPopup(showPopup: boolean) {
    this._showPopup = showPopup;
  }

  get showPopup(): boolean {
    return this._showPopup;
  }
}

@Observed
export class AgendaBlockStateManagement {
  private _curFocusWeekIndex: number = 0; // 当前获焦周的index

  private _preFocusWeekIndex: number = 0; // 上个获焦周的index

  private _focusedAgendaX: number = -1; // 当前获焦的日程块x坐标

  private _focusedAgendaY: number = -1; // 当前获焦的日程块y坐标

  private _hoverBlock: AgendaBlockInfo | undefined = undefined; // hover的日程块

  private _hoverFlag: boolean = false; // 是否可以弹出hover pop

  private _timer: number = 0; // 定时器

  private _hoverWeekIndex: number = -1; // 鼠标hover态所在周的index

  private _clickAgendaShow: boolean = false; //true：单击(鼠标右键或者手指单击)日程块的菜单栏展示（单击日程块pop和hover pop只能展示一个）

  private _duringSwiperAnimation: boolean = false; //月视图滑动期间不执行hover逻辑

  private _shareAnchorX: number = 0; //月视图日程块分享pop弹出的x坐标，月视图日程块用canvas绘制，无compId，需要计算坐标

  private _shareAnchorY: number = 0; //月视图日程块分享pop弹出的y坐标

  private _comeFormAgendaBlock: boolean = false; //标识分享日程块是否来源于月视图日程块

  private _closeHoverPopTimer: number = 0; // 关闭hover用Pop弹窗计时器
  private _openNewHoverPopTimer: number = 0; // 打开新hover用Pop弹窗计时器
  private _closePopOnPopHoverTimer: number = 0; // 从pop弹窗移出时关闭pop弹窗用逻辑

  public set closeHoverPopTimer(value: number) {
    this._closeHoverPopTimer = value;
  }

  public get closeHoverPopTimer(): number {
    return this._closeHoverPopTimer;
  }

  public set openNewHoverPopTimer(value: number) {
    this._openNewHoverPopTimer = value;
  }

  public get openNewHoverPopTimer(): number {
    return this._openNewHoverPopTimer;
  }

  public set closePopOnPopHoverTimer(value: number) {
    this._closePopOnPopHoverTimer = value;
  }

  public get closePopOnPopHoverTimer(): number {
    return this._closePopOnPopHoverTimer;
  }
  /**
   * 当鼠标移动到日程块区域之外 或
   * 移动到一个新的日程块 或
   * 当前不能展示hover pop，重置hover相关标志位
   */
  public resetAgendaHoverFlag() {
    this._hoverFlag = false;
    this._hoverBlock = undefined;
    clearTimeout(this._timer)
  }

  set curFocusWeekIndex(curFocusWeekIndex: number) {
    this._curFocusWeekIndex = curFocusWeekIndex;
  }

  get curFocusWeekIndex(): number {
    return this._curFocusWeekIndex;
  }

  set preFocusWeekIndex(preFocusWeekIndex: number) {
    this._preFocusWeekIndex = preFocusWeekIndex;
  }

  get preFocusWeekIndex(): number {
    return this._preFocusWeekIndex;
  }

  set focusedAgendaX(focusedAgendaX: number) {
    this._focusedAgendaX = focusedAgendaX;
  }

  get focusedAgendaX(): number {
    return this._focusedAgendaX;
  }

  set focusedAgendaY(focusedAgendaY: number) {
    this._focusedAgendaY = focusedAgendaY;
  }

  get focusedAgendaY(): number {
    return this._focusedAgendaY;
  }

  set hoverBlock(hoverBlock: AgendaBlockInfo | undefined) {
    this._hoverBlock = hoverBlock;
  }

  get hoverBlock(): AgendaBlockInfo | undefined {
    return this._hoverBlock;
  }

  set hoverFlag(hoverFlag: boolean) {
    this._hoverFlag = hoverFlag;
  }

  get hoverFlag(): boolean {
    return this._hoverFlag;
  }

  set timer(timer: number) {
    this._timer = timer;
  }

  get timer(): number {
    return this._timer;
  }

  set hoverWeekIndex(hoverWeekIndex: number) {
    this._hoverWeekIndex = hoverWeekIndex;
  }

  get hoverWeekIndex(): number {
    return this._hoverWeekIndex;
  }

  set clickAgendaShow(clickAgendaShow: boolean) {
    this._clickAgendaShow = clickAgendaShow;
  }

  get clickAgendaShow(): boolean {
    return this._clickAgendaShow;
  }

  set duringSwiperAnimation(duringSwiperAnimation: boolean) {
    this._duringSwiperAnimation = duringSwiperAnimation;
  }

  get duringSwiperAnimation(): boolean {
    return this._duringSwiperAnimation;
  }

  get shareAnchorX(): number {
    return this._shareAnchorX;
  }

  set shareAnchorX(shareAnchorX: number) {
    this._shareAnchorX = shareAnchorX;
  }

  get shareAnchorY(): number {
    return this._shareAnchorY;
  }

  set shareAnchorY(shareAnchorY: number) {
    this._shareAnchorY = shareAnchorY;
  }

  get comeFormAgendaBlock(): boolean {
    return this._comeFormAgendaBlock;
  }

  set comeFormAgendaBlock(comeFormAgendaBlock: boolean) {
    this._comeFormAgendaBlock = comeFormAgendaBlock;
  }
}