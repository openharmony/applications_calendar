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
import { HOURS_PER_DAY, TabType } from '@app/common';

@Observed
export class NewGanttBlockViewModel {
  public readonly BLOCK_BORDER_RADIUS: number = 2;
  public readonly BLOCK_BORDER_WIDTH: number = 0.5;
  public readonly ADD_IMAGE_SIZE: ConstraintSizeOptions = { maxWidth: 16, maxHeight: 16 }
  public isAddShow: boolean = false;
  public positionX: number = 0;
  public positionY: number = 0;
  public height: number = 20;
  public width: number = 20;
  // 用于移动时记录
  public originalX: number = 0;
  public originalY: number = 0;
  public originalHeight: number = 20;
  public heightStart: number = 1; // 当前新建日程块开始小时数
  public heightCount: number = 1; // 当前新建日程块所占小时数
  public widthCount: number = 1; // 当前新建日程块所属天位置
  public gridCellHeight: number = 20; // 记录当前甘特图元素高度
  public ganttCellWidth: number = 20; // 记录当前甘特图元素宽度
  public ganttStartTime: number = 0; // 记录当前甘特图元素的起始时间
  public tabType: TabType = TabType.DAY;
  private readonly TIME_ACCURACY: number = 4; // 时间精度,一小时分割的数量
  private readonly MIN_HOUR_COUNT: number = 0.5; // 最小小时数
  private oldGridCellHeight: number = 1; // 记录原甘特图元素高度

  updatePosition() {
    const nowHeightStart = Math.floor(this.positionY / this.gridCellHeight * this.TIME_ACCURACY) / this.TIME_ACCURACY;
    const finalHeightStart = Math.max(0, Math.min(nowHeightStart, HOURS_PER_DAY - this.heightCount));
    const maxWidthCount = this.tabType === TabType.DAY ? 0 : 6;
    const widthCount = Math.round(this.positionX / this.ganttCellWidth);
    const finalWidthCount = Math.max(Math.min(widthCount, maxWidthCount), 0);

    this.widthCount = finalWidthCount;
    this.heightStart = finalHeightStart;
    this.positionX = finalWidthCount * this.ganttCellWidth;
    this.positionY = finalHeightStart * this.gridCellHeight;
    this.originalX = this.positionX;
    this.originalY = this.positionY;
  }

  updateUpHeight() {
    const nowHeightStart = Math.floor(this.positionY / this.gridCellHeight * this.TIME_ACCURACY) / this.TIME_ACCURACY;
    const finalHeightStart = Math.max(0, Math.min(nowHeightStart, HOURS_PER_DAY - this.heightCount));
    this.heightCount = Math.max(this.MIN_HOUR_COUNT, this.heightStart - finalHeightStart + this.heightCount);
    this.height = this.heightCount * this.gridCellHeight;
    this.heightStart = finalHeightStart;
    this.positionY = finalHeightStart * this.gridCellHeight;

    this.originalY = this.positionY;
    this.originalHeight = this.height;

  }

  updateDownHeight() {
    const nowHeightCount = Math.floor(this.height / this.gridCellHeight * this.TIME_ACCURACY) / this.TIME_ACCURACY;

    this.heightCount = Math.min(HOURS_PER_DAY - this.heightStart, Math.max(0.5, nowHeightCount));
    this.height = this.heightCount * this.gridCellHeight;

    this.originalHeight = this.height;
  }

  updateNewAgendaHeight(offsetY: number, isUp: boolean) {
    this.height = Math.max(this.gridCellHeight * this.MIN_HOUR_COUNT, this.originalHeight - offsetY);
    if (isUp) {
      const finalOffsetY = this.originalHeight - this.height;
      this.positionY = this.originalY + finalOffsetY;
    }
  }

  updateGanttViewScale(scale: number) {
    this.positionY = this.originalY * scale;
    this.height = this.originalHeight * scale;
    this.gridCellHeight = this.oldGridCellHeight * scale;
  }

  setOriginalGanttViewScale() {
    this.originalY = this.positionY;
    this.originalHeight = this.height;
    this.oldGridCellHeight = this.gridCellHeight;
  }
}