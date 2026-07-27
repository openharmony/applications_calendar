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
import { Env, LayoutModel, LayoutProp, SingleInstanceHelper } from '@app/common/index';
import { GridProp } from './YearViewLayoutProp';
import { YearGridLayoutRule } from './YearGridLayoutRule';
import { DayLayout, SingleDayLayoutRule } from './SingleDayLayoutRule';
import { MonthLayout, SingleMonthLayoutRule } from './SingleMonthLayoutRule';
import { YearViewLayoutEnv } from './YearViewLayoutEnv';

const TAG: string = 'YearViewLayoutModel';

@Observed
export class YearViewLayoutModel extends LayoutModel {
  public gridProp: LayoutProp<GridProp> = new LayoutProp('GridProp', new GridProp());
  public dayLayout: LayoutProp<DayLayout> = new LayoutProp('dayLayout', new DayLayout());
  public monthLayout: LayoutProp<MonthLayout> = new LayoutProp('monthLayout', new MonthLayout());
  public compSizeEnv: Env;

  constructor() {
    super();
    this.compSizeEnv = new Env(YearViewLayoutEnv.COMPONENT_SIZE);
  }

  public static instance(): YearViewLayoutModel {
    return SingleInstanceHelper.createOrGet(YearViewLayoutModel, TAG);
  }

  init() {
    super.addRule(new YearGridLayoutRule(this.gridProp, this.dayLayout)); // 绑定回调
    super.addRule(new SingleDayLayoutRule(this.dayLayout)); // 绑定回调
    super.addRule(new SingleMonthLayoutRule(this.monthLayout)); // 绑定回调
  }

  onSizeChange(width: number, height: number) {
    this.compSizeEnv.data.set('width', width);
    this.compSizeEnv.data.set('height', height);
    this.compSizeEnv.data.set('fontSizeScale', AppStorage.get<number>('fontSizeScale'));
    this.callback(this.compSizeEnv);
  }

  onFontSizeChange(fontSizeScale: number) {
    this.compSizeEnv.data.set('fontSizeScale', fontSizeScale);
    this.callback(this.compSizeEnv);
  }
}