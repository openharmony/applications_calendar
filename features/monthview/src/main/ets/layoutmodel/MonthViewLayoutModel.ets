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
import { Env, I18nUtil, LayoutModelTree, LayoutProp, Log, SingleInstanceHelper } from '@app/common/index';
import { WeekTitleLayout, WeekTitleLayoutRule } from './WeekTitleLayoutRule';
import { FrameLayout, FrameLayoutRule, MonthStaticLayout } from './FrameLayoutRule';
import { DayCellLayout, DayCellLayoutRule } from './DayCellLayoutRule';
import { WeekNumLayout, WeekNumLayoutRule } from './WeekNumLayoutRule';
import { MonthViewLayoutEnv } from './MonthViewLayoutEnv';

const TAG = '[MonthlyView][Layout][LayoutModel]';

export class MonthViewLayoutModel {
  public frameProp: LayoutProp<FrameLayout> = new LayoutProp('FrameProp', new FrameLayout());
  public weekTitleProp: LayoutProp<WeekTitleLayout> = new LayoutProp('weekTitleProp', new WeekTitleLayout());
  public dayLayout: LayoutProp<DayCellLayout> = new LayoutProp('DayCellLayout', new DayCellLayout());
  public weekNumProp: LayoutProp<WeekNumLayout> = new LayoutProp('weekNumProp', new WeekNumLayout());
  public compSizeEnv: Env;
  private ruleTree: LayoutModelTree;
  public modeEnv: Env;

  private divideOldDateWidth: number = 0; // 隐形拖动用,拖动开始时的日期区域宽度
  private divideOldAgendaWidth: number = 0; // 隐形拖动用,拖动开始时的日程区域宽度
  private divideOldMonthWidth: number = 0; // 隐形拖动用,拖动开始时的整体宽度
  private divideMaxRatio: number = 0; // 隐形拖动用,拖动开始时的日程最大比例限制
  private divideMinRatio: number = 0; // 隐形拖动用,拖动开始时的日程最小比例限制
  private isMirror: boolean = false; // 隐形拖动用,是否处于镜像状态

  constructor() {
    const frameLayoutRule = new FrameLayoutRule(this.frameProp);
    this.ruleTree = new LayoutModelTree(frameLayoutRule);
    let rootNode = this.ruleTree.rootNode;
    rootNode.addChild(new DayCellLayoutRule(this.frameProp, this.dayLayout));
    rootNode.addChild(new WeekTitleLayoutRule(this.frameProp, this.weekTitleProp));
    rootNode.addChild(new WeekNumLayoutRule(this.frameProp, this.weekNumProp));
    this.compSizeEnv = new Env(MonthViewLayoutEnv.COMPONENT_SIZE);
    this.modeEnv = new Env(MonthViewLayoutEnv.MODE);
  }

  static getInstance(): MonthViewLayoutModel {
    return SingleInstanceHelper.createOrGet(MonthViewLayoutModel, 'MonthViewLayoutModel');
  }

  onSizeChange(width: number, height: number) {
    Log.info(TAG, `onSizeChange width:${width}  height:${height}`)
    this.compSizeEnv.data.set('width', width);
    this.compSizeEnv.data.set('height', height);
    this.ruleTree.callback(this.compSizeEnv);
  }

  onModeChange() {
    this.ruleTree.callback(this.modeEnv);
  }

  onSizeRefresh() {
    this.ruleTree.callback(this.compSizeEnv);
  }

  // 隐形拖动初始化
  onDivideInit(hideAgendaWindow: boolean, language: string = '') {
    Log.info(TAG, `start Invisibility divide`);
    const agendaListRatio = hideAgendaWindow ? 0 : this.frameProp.value.agendaListRatio;
    this.divideOldMonthWidth = this.frameProp.value.monthDateWidth + this.frameProp.value.agendaListViewWidth;
    this.divideOldDateWidth = Math.floor(this.divideOldMonthWidth / (1 + agendaListRatio));
    this.divideOldAgendaWidth = this.divideOldMonthWidth - this.divideOldDateWidth;
    this.divideMaxRatio = // 根据最小日期区域宽度计算当前最大比例
      (this.divideOldMonthWidth - MonthStaticLayout.minMonthWidth) / MonthStaticLayout.minMonthWidth;
    this.divideMinRatio = // 根据最小日程区域宽度计算当前最小比例
      MonthStaticLayout.minAgendaListWidth / (this.divideOldMonthWidth - MonthStaticLayout.minAgendaListWidth);
    this.isMirror = I18nUtil.isUyghurLanguage(language);
  }

  // 隐形拖动跟手变更比例
  onDivideChange(offsetX: number, needAnimate: boolean = true): boolean {
    offsetX = this.isMirror ? -offsetX : offsetX;
    const nowDateWidth = this.divideOldDateWidth + offsetX;
    const nowAgendaWidth = this.divideOldAgendaWidth - offsetX;
    const nowDivider = nowAgendaWidth / nowDateWidth;
    const needHide = nowDivider < (this.divideMinRatio / 2);
    const agendaListRatio = Math.min(Math.max(nowDivider, this.divideMinRatio), this.divideMaxRatio);

    if (this.frameProp.value.agendaListRatio !== agendaListRatio) {
      this.frameProp.value.agendaListRatio = agendaListRatio;
      this.ruleTree.callback(this.compSizeEnv);
    }
    return needHide;
  }

  // 隐形拖动结束
  onDivideEnd(offsetX: number): void {
    Log.info(TAG, `end Invisibility divide final X ${offsetX} ${this.frameProp.value.agendaListRatio}`);
  }
}