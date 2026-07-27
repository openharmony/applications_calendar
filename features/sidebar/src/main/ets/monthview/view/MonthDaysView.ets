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

import { DAY_PER_WEEK, GlobalDataKeys, Log } from '@app/common';
import { SingleDayViewModel } from '../model/SingleDayViewModel';
import { SingleMonthViewModel } from '../model/SingleMonthViewModel';
import { SideBarMonthViewLayout } from '../model/SideBarMonthViewLayout';

const TAG = "[SideBar][MonthDaysView]";
const MINI_MONTH_BLACK: string = "#000000";
const MINI_MONTH_WHITE: string = "#FFFFFF";

// 采用Canvas组件绘制单月视图中的天，避免组件数过多
@Component
export struct MonthDaysView {
  // The way to respond to size changes needs to be optimized.
  @State layout: SideBarMonthViewLayout = SideBarMonthViewLayout.getInstance();

  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  // Canvas无法直接在布局中绑定ViewModel层变化,需要中间转换一次
  @ObjectLink @Watch('onViewModelChange') monthViewModel: SingleMonthViewModel;

  @StorageProp('themeColor') themeColor: string = "";

  private settings: RenderingContextSettings = new RenderingContextSettings(true);

  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 实际数据
  private dayViewModels: SingleDayViewModel[] = [];

  private weekTitles: string[] = [];

  // 保存绘制天的坐标中心点
  private positions: Position[] = [];

  private canvasHeight: number = -1;

  private canvasWidth: number = -1;

  private rectHeight: number = -1;

  private dateTextWidth: number = -1;

  private dateTextHeight: number = -1;

  private readonly colNum = DAY_PER_WEEK; // 列数, 一周七天

  // 画布是否准备就绪
  private isReady: boolean = false;

  dateSelected: Function = (displayMonth: number) => {
  };

  onDarkModeChange(): void {
    this.renderCanvas();
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.isReady = true;
        this.renderCanvas();
      })
      .onHover((isHover: boolean | undefined) => {
      })
      .layoutWeight(1)
  }

  aboutToAppear() {
    Log.debug(TAG, `aboutToAppear ${this.monthViewModel.year}:${this.monthViewModel.month}`);
    this.weekTitles = this.monthViewModel.weekTitles as string[];
    this.dayViewModels = this.monthViewModel.dayViewModels as SingleDayViewModel[];
  }

  aboutToDisappear() {
    Log.debug(TAG, `aboutToDisappear ${this.monthViewModel.year}:${this.monthViewModel.month}`);
    this.isReady = false;
  }

  onViewModelChange(): void {
    Log.debug(TAG, `onViewModelChange ${this.monthViewModel.year}:${this.monthViewModel.month}`);
    this.weekTitles = this.monthViewModel.weekTitles as string[];
    this.dayViewModels = this.monthViewModel.dayViewModels as SingleDayViewModel[];
    this.renderCanvas();
  }

  renderCanvas(): void {
    this.onCanvasLayout();
    this.prepareDraw();
    this.doDraw();
  }

  // 计算单天的区域中心位置, 实现SpaceBetween效果
  private onCanvasLayout(): void {
    this.positions = [];
    this.canvasHeight = Math.floor(this.context.height);
    this.canvasWidth = Math.floor(this.context.width);
    this.rectHeight = Math.floor(this.canvasHeight / (this.monthViewModel.weekNum + 1)); // 包括星期标题栏
    // 首列X坐标
    const dx = this.layout.selectCircle * 0.5 + 1;
    const leftPosX = dx; // 进行偏移, 保证圆圈能够显示出来
    const leftPosY = dx; // 进行偏移,保证圆圈能够显示出来
    const rightPosX = this.canvasWidth - dx;
    const rightPosY = this.canvasHeight - dx;

    const spaceX = (rightPosX - leftPosX) / (this.colNum - 1);
    const spaceY = (rightPosY - leftPosY) / (this.monthViewModel.weekNum);
    for (let i = 0; i < this.dayViewModels.length + this.weekTitles.length; i++) {
      // 划分矩形
      let centerX = leftPosX + spaceX * (i % this.colNum);
      let centerY = leftPosY + (Math.floor(i / this.colNum)) * spaceY;
      this.positions.push(new Position(centerX, centerY));
    }
  }

  private doDraw(): void {
    if (this.isReady) {
      this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    }
    this.drawWeekTitleArea();
    this.drawDateArea();
  }

  private drawWeekTitleArea(): void {
    if (this.positions.length === 0) {
      return;
    }
    const colorBlack: string = this.isDarkMode ? MINI_MONTH_WHITE : MINI_MONTH_BLACK;
    this.context.font = `${vp2px(this.layout.dayFontSize)}px sans-serif normal 450`;
    this.context.fillStyle = colorBlack; // default black
    this.weekTitles.forEach((item, index) => {
      let centerX = this.positions[index].x;
      let centerY = this.positions[index].y;
      this.context.globalAlpha = this.monthViewModel.weekends.includes((index + this.monthViewModel.startOfWeek) % 7) ? 0.4 : 1; //判断是否属于周末
      this.context.fillText(item, centerX, centerY);
    })
    this.context.globalAlpha = 1; //重置透明度
  }

  private drawDateArea(): void {
    if (this.positions.length === 0) {
      return;
    }
    const colorBlack: string = this.isDarkMode ? MINI_MONTH_WHITE : MINI_MONTH_BLACK;
    this.context.font = `${vp2px(this.layout.dayFontSize)}px sans-serif normal 500`;
    this.context.fillStyle = colorBlack; // default black
    const indexOffSet = this.colNum; // 前面的是周标题的pos, 需要偏移
    this.dayViewModels.forEach((item, index) => {
      let centerX = this.positions[index + indexOffSet].x;
      let centerY = this.positions[index + indexOffSet].y;
      this.drawDateText(centerX, centerY, item);
    })
  }

  private prepareDraw(): void {
    const ratio = fp2px(1);
    if (!this.isReady) {
      return;
    }
    this.context.font = `${fp2px(this.layout.dayFontSize)}px sans-serif normal 500`;
    this.context.textAlign = 'center';
    this.context.textBaseline = 'middle';
    const NORMAL_TEXT = "30";
    this.dateTextWidth = this.context.measureText(NORMAL_TEXT).width;
    this.dateTextHeight = this.context.measureText(NORMAL_TEXT).height / ratio;
  }

  private drawDateText(centerX: number, centerY: number, dayViewModel: SingleDayViewModel): void {
    if (dayViewModel.day === -1) {
      return;
    }
    if (dayViewModel.isSelect) {
      if (dayViewModel.isToday) {
        this.drawTodayCircle(centerX, centerY);
      } else {
        this.drawSelectCircle(centerX, centerY);
      }
    }
    this.context.fillStyle = this.getDateColor(dayViewModel);
    this.context.globalAlpha = dayViewModel.isOffDay && !dayViewModel.isToday ? dayViewModel.opacity : 1;
    this.context.fillText(dayViewModel.day.toString(), centerX, centerY);

    this.context.globalAlpha = 1; //需要在文本绘制完成后重置一下
  }

  private getDateColor(dayViewModel: SingleDayViewModel): string | number {
    if (dayViewModel.isToday) {
      return dayViewModel.isSelect ? MINI_MONTH_WHITE : this.themeColor;
    }
    if (this.isDarkMode) {
      return MINI_MONTH_WHITE;
    }
    return MINI_MONTH_BLACK;
  }

  private drawTodayCircle(centerX: number, centerY: number): void {
    const circleArc: number = 6.25;
    const colorWhite: string = '#FFFFFF';
    this.context.lineWidth = 2;
    this.context.beginPath();
    this.context.arc(centerX, centerY, this.layout.selectCircle / 2, 0, circleArc);
    this.context.closePath();
    this.context.fillStyle = this.themeColor;
    this.context.fill();
    this.context.fillStyle = colorWhite;
  }

  private drawSelectCircle(centerX: number, centerY: number): void {
    const circleArc: number = 6.25;
    this.context.beginPath();
    this.context.arc(centerX, centerY, this.layout.selectCircle / 2, 0, circleArc);
    this.context.closePath();
    this.context.strokeStyle = this.themeColor;
    this.context.lineWidth = 1;
    this.context.stroke();
  }
}

class Position {
  x: number;

  y: number;

  constructor(x: number, y: number) {
    this.x = x;
    this.y = y;
  }
}