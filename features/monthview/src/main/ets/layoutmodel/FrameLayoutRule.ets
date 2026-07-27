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
  AccountColor,
  AccountUtils,
  DeviceConfig,
  Env,
  GlobalDataKeys,
  GlobalEnvEnum,
  LayoutProp,
  LayoutRule,
  Log
} from '@app/common/index';
import { MonthlyViewStateManager } from '../viewmodel/MonthlyViewState';
import { MonthViewLayoutEnv } from './MonthViewLayoutEnv';
import { display } from '@kit.ArkUI'

const TAG = '[MonthlyView][Layout][FrameLayout]';

export class WeekAgendaLayout {
  public static readonly agendaRowHeight: number =
    DeviceConfig.instance().config.monthAgendaBlockHeight + 2; // 单个日程块的高度
  public static readonly agendaRowPaddingTop: number = 2; // 日程区域的上边距
  public static readonly agendaMaxRow: number = 8; // 最多显示日程块数量
  public static readonly dayTextWeight: number = 500; // 日期的字重medium

  public static readonly notInCurMonthOpacity: number = 0.6; // 非当月日程颜色透明度系数
  public static readonly smallDarkOpacityAdd: number = 25; // 小屏因无月视图底部故深色模式增加10%透明度

  public static readonly fontOpacity: number = 255; // 日程文字默认不透明度 100%
  public static readonly fontOpacityExpired: number = 153; // 日程文字过期不透明度 60%
  public static readonly fontTextMaxDarkOpacity: number = 170; // 日程深色模式文字最大不透明度 67%

  public static readonly rectOpacity: number = 15; // 日程背板默认不透明度 6%
  public static readonly rectFocusOpacity: number = 51; // 日程焦点背板默认不透明度 20%

  public static readonly rectDarkOpacity: number = 38; // 日程深色背板默认不透明度 15%
  public static readonly rectDarkFocusOpacity: number = 115; // 日程深色焦点背板默认不透明度 45%

  public static readonly agendaLineOpacity: number = 179; //日程左竖线默认不透明度 70%
  public static readonly agendaLineOpacityExpired: number = 102; //过期日程左竖线默认不透明度 40%

  public static readonly fixContentTextColorBlack: string = '#000000'; // 固定日程字体的默认颜色 黑色
  public static readonly fixContentTextColorWhite: string = '#FFFFFF'; // 固定日程字体的默认颜色 白色
  public static readonly fixContentRectColor: string = '#808080'; // 固定日程圆角矩形的默认颜色

  public static readonly agendaContentTextColor: string = '#00AAEE'; // 日程字体的默认颜色
  public static readonly agendaContentRectColor: string = '#00AAEE'; // 日程圆角矩形的默认颜色

  public static readonly abbreviationTextColor: string = '#' + AccountUtils.HexColor(AccountColor.RED); // 缩略文字的默认颜色
  public static readonly abbreviationRectColor: string = '#' + AccountUtils.HexColor(AccountColor.RED); // 缩略背板的默认颜色

  public static readonly holidayColor: string = '#000000'; // 节假日的默认颜色
  public static readonly holidayDarkColor: string = '#FFFFFF'; // 节假日的深色颜色
  public static readonly holidayFontOpacity: number = 153; // 节假日文字默认不透明度 60%
  public static readonly holidayLineOpacity: number = 128; // 节假日竖线不透明度 50%
}

export class MonthStaticLayout {
  public static readonly monthPaddingTop: number = 12; // 月视图的默认总上边距
  public static readonly weekTitleHeight: number = 16; // 周视图默认高度
  public static readonly weekTitlePaddingBottom: number = 6; // 周视图的下边距
  public static readonly singleMonthPadding: number = 24; // 大屏月视图的上下边距
  public static readonly monthAvoidPadding: number = 12; // 月视图规避导航栏的高度
  public static readonly minMonthWidth: number = 480; // 月视图最小宽度
  public static readonly minAgendaListWidth: number = 240; // 日程列表最小宽度
  public static readonly needPanDivide: boolean = DeviceConfig.instance().config.needPanDivide; // 是否需要隐形拖动
}

// 布局框架属性
@Observed
export class FrameLayout {
  public isVerticalCell: boolean = true; // 月视图的宫格是否是垂直布局
  public isSmall: boolean = true; // 是否为小屏幕
  public isWeekAgendaList: boolean = false; // 是否显示单周的日程列表
  public agendaListViewWidth: number = 420;
  public weekRowHeight: number = 54; // 单周高度
  public monthDateWidth: number = 0; // 月视图日期区域宽度
  public agendaListRatio: number = DeviceConfig.instance().config.detailRatio; // 月视图和日程列表的默认比例
  public isGrid: boolean = false; // 是否为宫格化
  public monthPaddingTop: number = MonthStaticLayout.monthPaddingTop;
}

interface breakPoint {
  value: number,
  name: string,
}

/**
 * 月视图框架布局规则，用于控制月视图整体布局
 */
export class FrameLayoutRule extends LayoutRule {
  public bp: string = '';
  private frameProp: LayoutProp<FrameLayout>;
  private breakPoints: breakPoint[] = [
    { value: 0, name: 'xs' },
    { value: 360, name: 'sm' },
    { value: 600, name: 'md' },
    { value: 840, name: 'lg' },
    { value: 1080, name: 'xl' },
    { value: 1320, name: 'xxl' },
    { value: 99999, name: 'max' },
  ];
  private ratioSmall = false;
  private readonly smallRatio: number = 1.35; // 高宽比到达多少isSmall需要设置为true
  private readonly needCheckRatio: boolean = DeviceConfig.instance().config.needCheckRatio;

  constructor(frameProp: LayoutProp<FrameLayout>) {
    super('FrameLayoutRule', [
      MonthViewLayoutEnv.COMPONENT_SIZE, // 自身组件大小
      GlobalEnvEnum.WINDOW_SIZE// 窗口尺寸大小
    ]);
    // 建立引用
    this.frameProp = frameProp;
  }

  onChange(env: Env): boolean {
    Log.info(TAG, 'onChange');
    if (env.name === MonthViewLayoutEnv.COMPONENT_SIZE) {
      let width = env.data.get('width');
      let height = env.data.get('height');
      if (typeof width === 'number' && typeof height === 'number') {
        this.reCalLayout(width, height);
        return true;
      }
    } else if (env.name === GlobalEnvEnum.WINDOW_SIZE) {
      let width = env.data.get('width') as number;
      let height = env.data.get('height') as number;
    }
    return false;
  }

  // 组件宽度，高度
  reCalLayout(newComponentWidth: number, newComponentHeight: number) {
    // 再触发内部布局变化
    Log.info(TAG, `reCalLayout width:${newComponentWidth} height: ${newComponentHeight}`);
    // 先触发顶层布局
    this.onBreakpointChange(newComponentWidth, newComponentHeight);
    // 再重新计算日程列表宽度
    this.setAgendaRadio(newComponentWidth, MonthStaticLayout.needPanDivide);

    Log.info(TAG, `layout ${this.frameProp.value.isSmall}`);
  }

  setAgendaRadio(newComponentWidth: number, needPanDivide: boolean) {
    // 因尺寸改变会同步变化最大比例和最小比例,需要对当前最大比例和最小比例进行限制
    const checkWidth = Math.max(MonthStaticLayout.minMonthWidth, MonthStaticLayout.minAgendaListWidth);
    // 在适配并修改比例时需要校验当前宽度是否符合标准,因初始化时组件宽度可能会存在异常
    if (needPanDivide && newComponentWidth > checkWidth) {
      const defaultRatio = DeviceConfig.instance().config.detailRatio;
      const maxRatio =
        Math.max((newComponentWidth - MonthStaticLayout.minMonthWidth) / MonthStaticLayout.minMonthWidth, defaultRatio);
      const minRatio =
        Math.max(MonthStaticLayout.minAgendaListWidth / (newComponentWidth - MonthStaticLayout.minAgendaListWidth), 0);
      this.frameProp.value.agendaListRatio =
        Math.min(Math.max(this.frameProp.value.agendaListRatio, minRatio), maxRatio);
    }
    let divideNum = this.frameProp.value.agendaListRatio / (1 + this.frameProp.value.agendaListRatio);
    if (this.frameProp.value.isSmall) {
      divideNum = 1; // 小屏状态为上下布局,日程宽度为屏幕宽度
    }
    this.frameProp.value.agendaListViewWidth = Math.round(newComponentWidth * divideNum); // 日程区域
    AppStorage.setOrCreate(GlobalDataKeys.AGENDA_LIST_WIDTH, this.frameProp.value.agendaListViewWidth);
    try {
      let scale = display.getDefaultDisplaySync().scaledDensity;
      Log.info(TAG,
        `agendaListViewWidth: ${this.frameProp.value.agendaListViewWidth} scale: ${scale} divideNum ${divideNum}`);
    } catch (err) {
      Log.logErrorMsg(TAG, 'get scale error', err);
    }
    const isAgendaHide = MonthlyViewStateManager.getInstance().state.hideAgendaWindow;
    this.frameProp.value.monthDateWidth = newComponentWidth - (this.frameProp.value.isSmall || isAgendaHide ?
      0 : this.frameProp.value.agendaListViewWidth)
      // 判断此时是否需要宫格化布局
    this.frameProp.value.isGrid = !this.frameProp.value.isSmall &&
      (newComponentWidth - (isAgendaHide ? 0 : this.frameProp.value.agendaListViewWidth)) >=
      MonthStaticLayout.minMonthWidth;
  }

  onBreakpointChange(width: number, height: number) {
    let tempBp: string = '';
    for (let i = 0; i < this.breakPoints.length - 1; ++i) {
      if (width >= this.breakPoints[i].value && width < this.breakPoints[i + 1].value) {
        tempBp = this.breakPoints[i].name;
        break;
      }
    }
    let nowRatioSmall = false;
    if (this.needCheckRatio) {
      nowRatioSmall = (height / width) >= this.smallRatio;
    }
    if (this.bp === tempBp && nowRatioSmall === this.ratioSmall) {
      Log.warn(TAG, `No Need To Change Layout In The Same Screen!`);
      return;
    }
    this.ratioSmall = nowRatioSmall;
    if (nowRatioSmall) {
      this.setLayoutSmall();
      return;
    }
    this.setLayoutByBp(tempBp);
  }

  // 用于平板竖屏状态下高宽比过大显示不平衡修改
  setLayoutSmall() {
    this.frameProp.value.isSmall = true;
    this.frameProp.value.isWeekAgendaList = false;
    this.frameProp.value.isGrid = false;
  }

  setLayoutByBp(tempBp: string) {
    this.bp = tempBp;
    if (this.bp === 'xs' || this.bp === 'sm') { // 最小宽度类型设备 折叠屏的窄屏 345vp 手机 竖屏 384vp <600
      // 布局
      this.frameProp.value.isSmall = true;

      this.frameProp.value.isWeekAgendaList = false;
    } else if (this.bp === 'md') { //  竖屏 PC最小窗口 600-840
      // 布局
      this.frameProp.value.isSmall = false; // 大屏
      // 大屏设备常驻显示每周的日程详情列表
      this.frameProp.value.isWeekAgendaList = true;
    } else if (this.bp === 'lg') { // 平板 横屏 840 - 1080
      // 布局
      this.frameProp.value.isSmall = false; // 大屏
      // 大屏设备常驻显示每周的日程详情列表
      this.frameProp.value.isWeekAgendaList = true;
    } else if (this.bp === 'xl') { // PC默认窗口 1080-1320
      // 布局
      this.frameProp.value.isSmall = false; // 大屏
      // 大屏设备常驻显示每周的日程详情列表
      this.frameProp.value.isWeekAgendaList = true;
    } else if (this.bp === 'xxl') { //  PC 最大化 1320+
      // 布局
      this.frameProp.value.isSmall = false; // 大屏
      // 大屏设备常驻显示每周的日程详情列表
      this.frameProp.value.isWeekAgendaList = true;
    }
  }
}
