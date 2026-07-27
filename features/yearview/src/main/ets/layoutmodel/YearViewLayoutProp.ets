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

export enum GridTemplate {
  NONE,
  LAYOUT_4_3,
  LAYOUT_3_4,
  LAYOUT_6_2,
  LAYOUT_2_6,
}

@Observed
export class GridProp {
  public template: GridTemplate = GridTemplate.LAYOUT_3_4;
  public colsTemplateStr: string = '1fr 1fr 1fr';
  public rowsTemplateStr: string = '1fr 1fr 1fr 1fr';
  public rowsHeight: string = '22%';
  public colCount: number = 3;
  public paddingBottom: number = 24; // Grid 底部内边距 Note : padding 百分比是使用width为基准
  public minHeight: number = 120; // 单月最小高度
  public minWidth: number = 100; // 单元最小宽度
}

@Observed
export class CommonProp {
  // common prop
  public themeColor: string = ''; // 主题色
  public lunarLineHeight: number = 2;
  public hasRecess: boolean = false;
}