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


export interface DeviceLayout {

  cardOneKeyServiceFontSize: number; // 卡片一键入会字体大小
  cardAgendaTitleFontSize: number; // 卡片日程标题字体大小
  cardAgendaLocationFontSize: number | Resource; // 卡片日程地点字体大小
  cardAgendaTimeFontSize: number | Resource; // 卡片日程时间字体大小
  cardAgendaTimeFontFixedSize: string; // 2x2卡片日程时间字体固定大小(不随适老化变化)
  cardAgendaTimeWidth: number; // 卡片日程时间条宽度

  noCardAgendaCircleSize: number; // 无日程卡片日期红圈大小
  noCardAgendaFontSize: number; // 无日程卡片字体大小
  noCardAgendaFontSize4x4: number; // 无日程卡片字体大小4x4
  noAgendaCardWeekTitleFontSize: number; // 无日程卡片右侧星期标题字体大小4x4
  noAgendaCardMonthViewTopOffset: Dimension;
  monthCard4x4FontSize: number; // 月视图卡片4x4字体大小

  buttonTopHeight: number; // 按钮距离顶部的额外高度
  sidebarWidth: number; // 侧边栏宽度
  sidebarBackgroundColor: string | Resource; // 侧边栏背景色
  sidebarBackgroundColorOverlay: string | Resource; // 侧边栏背景色-悬浮态
  sidebarAccountBC: string | Resource; // 侧边栏账户卡片背景色
  sidebarAccountBCOverlay: string | Resource; // 侧边栏账户卡片背景色-悬浮态
  searchBackgroundColor: Color | Resource; // 搜索栏的背景色
  cancelButtonBackgroundColor: Color | Resource; // 搜索栏的背景色
  searchBackgroundBlur: BlurStyle;
  transparentCardSpaceTop: number; //透明卡片顶部距离；
  transparentCardSpaceOne: number; // 透明卡片第一行到第二行得底边距
  transparentCardSpaceOTwo: number; //透明卡片第二行到第三行得底边距
  transparentCardCircleDiameter: number; //透明卡片圆环得直径
  transparentCardImageIconWidth: number; //透明卡片图片图标尺寸宽
  transparentCardImageIconHeight: number; //透明卡片图片图标尺寸长
  transparentCardAgendaMaxFontSize: number; //透明卡片日程大小最大值
  transparentCardAgendaMinFontSize: number; //透明卡片日程大小最小值
  transparentCardDateFontSize: number; //透明卡片日期大小
  transparentCardWeekTitleSize: number; //透明卡片周日期大小
  transparentCardPadding: number | Resource; // 透明卡左右间距
  transparentCardLineHeight: number | Resource; // 透明卡时间和日程之间的竖线高度
  cardCircleSize: number; // 月视图2x2圆大小

  conflictingAgendaPopUpWidth: number; // 冲突日程的气泡弹窗宽度

  transparentCardAgendaUpPartHeight: number; // 透明卡片上半部分高度
  transparentCardAgendaUpPartPercent: number; // 透明卡片上半部分高度
  transparentCardAgendaDownPartPercent: number; // 透明卡片下半部分高度
  cardAgendaTitleMaxLines: number;
  cardEditBreakpoints: Array<string> // 卡片编辑断点
  cardEditGridColOptions: GridColOptions // 卡片编辑栅格
  cardEditVGridColOptions: GridColOptions // 卡片编辑竖屏栅格，只有平板需区分横竖屏
  cardLineHeightTypeZero2X2: number // 2X2卡片type0日程对应线的长度
  cardLineHeightTypeOne2X2: number // 2X2卡片type1日程对应线的长度
  cardLineHeightTypeTwo2X2: number // 2X2卡片type2日程对应线的长度
  cardLineHeightTypeThree2X2: number // 2X2卡片type3日程对应线的长度

  agendaDot: number; // 4x6周视图卡片的日程点大小
}

export class SmallDeviceLayout implements DeviceLayout {
  public cardOneKeyServiceFontSize: number = 12; // 卡片一键入会字体大小
  public cardAgendaTitleFontSize: number = 14; // 卡片日程标题字体大小
  public cardAgendaLocationFontSize = $r('sys.float.Caption_M') // 卡片日程地点字体大小
  public cardAgendaTimeFontSize = $r('sys.float.Caption_M'); // 卡片日程时间字体大小
  public cardAgendaTimeFontFixedSize = '10vp'; // 2x2卡片日程时间字体固定大小(不随适老化变化)
  public cardAgendaTimeWidth: number = 60; // 卡片日程时间条宽度

  public noCardAgendaCircleSize: number = 18; // 无日程卡片日期红圈大小
  public noCardAgendaFontSize: number = 12; // 无日程卡片字体大小
  public noCardAgendaFontSize4x4: number = 14; // 无日程卡片字体大小4x4
  public noAgendaCardWeekTitleFontSize: number = 10; // 无日程卡片右侧星期标题字体大小4x4
  public noAgendaCardMonthViewTopOffset: Dimension = '3%';

  public cardCircleSize: number = 15; // 月视图2x2圆大小
  public monthCard4x4FontSize: number = 15; // 月视图4x4字体大小


  public buttonTopHeight: number = 0; // 按钮距离顶部的额外高度
  public sidebarWidth: number = 304; // 侧边栏宽度
  public sidebarBackgroundColor = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景
  public sidebarBackgroundColorOverlay = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景-悬浮态
  public sidebarAccountBC = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景
  public sidebarAccountBCOverlay = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景-悬浮态
  public searchBackgroundColor = Color.Transparent; // 搜索栏的背景色
  public searchBackgroundBlur = BlurStyle.COMPONENT_ULTRA_THICK; // 搜索栏的模糊效果
  public cancelButtonBackgroundColor = Color.Transparent; // 取消按钮的背景色
  public transparentCardSpaceTop: number = 22; // 透明卡片顶部距离；
  public transparentCardSpaceOne: number = 12; // 透明卡片第一行到第二行得底边距
  public transparentCardSpaceOTwo: number = 14; // 透明卡片第二行到第三行得底边距
  public transparentCardCircleDiameter: number = 36; // 透明卡片圆环得直径
  public transparentCardImageIconWidth: number = 12; // 透明卡片图片图标尺寸
  public transparentCardImageIconHeight: number = 13; // 透明卡片图片图标尺寸
  public cardAgendaFontSize = 12; // 透明卡片日程大小
  public transparentCardAgendaMaxFontSize: number = 13; //透明卡片日程大小最大值
  public transparentCardAgendaMinFontSize: number = 9; //透明卡片日程大小最小值
  public transparentCardDateFontSize = 18; //透明卡片日期大小
  public transparentCardWeekTitleSize = 16; //透明卡片周日期大小
  public transparentCardPadding = 6; // 透明卡左右间距
  public transparentCardLineHeight = 12; // 透明卡时间和日程之间的竖线高度

  public conflictingAgendaPopUpWidth: number = 320; // 冲突日程的气泡弹窗宽度

  public transparentCardAgendaUpPartHeight: number = 67; // 透明卡片上半部分高度
  public transparentCardAgendaUpPartPercent: number = 18; // 透明卡片上半部分高度
  public transparentCardAgendaDownPartPercent: number = 10; // 透明卡片下半部分高度
  public cardAgendaTitleMaxLines: number = 2;

  public cardLineHeightTypeZero2X2: number = 16; // 2X2卡片type0日程对应线的长度
  public cardLineHeightTypeOne2X2: number = 31; // 2X2卡片type1日程对应线的长度
  public cardLineHeightTypeTwo2X2: number = 32; // 2X2卡片type2日程对应线的长度
  public cardLineHeightTypeThree2X2: number = 47; // 2X2卡片type3日程对应线的长度

  public cardEditBreakpoints: Array<string> = ['600vp'] // 卡片编辑断点
  public cardEditGridColOptions: GridColOptions = {
    // 卡片编辑栅格
    offset: {
      xs: 0,
      sm: 0,
      xxl: 0
    },
    span: {
      xs: 4, // 小设备，4/4。
      sm: 8, // 中设备，8/8。
      xxl: 8, // vde阔折叠横屏，8/8。
    }
  }
  public cardEditVGridColOptions: GridColOptions = this.cardEditGridColOptions

  public agendaDot: number = 3;
}

export class MediumDeviceLayout implements DeviceLayout {
  public cardOneKeyServiceFontSize: number = 12; // 卡片一键入会字体大小
  public cardAgendaTitleFontSize: number = 16; // 卡片日程标题字体大小
  public cardAgendaLocationFontSize = $r('sys.float.ohos_id_text_size_body3'); // 卡片日程地点字体大小
  public cardAgendaTimeFontSize = $r('sys.float.Body_S'); // 卡片日程时间字体大小
  public cardAgendaTimeFontFixedSize = '12vp'; // 2x2卡片日程时间字体固定大小(不随适老化变化)
  public cardAgendaTimeWidth: number = 60; // 卡片日程时间条宽度

  public noCardAgendaCircleSize: number = 20; // 无日程卡片日期红圈大小
  public noCardAgendaFontSize: number = 14; // 无日程卡片字体大小
  public noCardAgendaFontSize4x4: number = 16; // 无日程卡片字体大小4x4
  public noAgendaCardWeekTitleFontSize: number = 12; // 无日程卡片右侧星期标题字体大小4x4
  public noAgendaCardMonthViewTopOffset: Dimension = '4%';
  public cardCircleSize: number = 15; // 月视图2x2圆大小
  public monthCard4x4FontSize: number = 17; // 月视图4x4字体大小

  public buttonTopHeight: number = 0; // 按钮距离顶部的额外高度
  public sidebarWidth: number = 240; // 侧边栏宽度
  public sidebarBackgroundColor = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景
  public sidebarBackgroundColorOverlay = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景-悬浮态
  public sidebarAccountBC = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景
  public sidebarAccountBCOverlay = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景-悬浮态
  public searchBackgroundColor = Color.Transparent; // 搜索栏的背景色
  public searchBackgroundBlur = BlurStyle.COMPONENT_ULTRA_THICK; // 搜索栏的模糊效果
  public cancelButtonBackgroundColor = Color.Transparent; // 取消按钮的背景色
  public transparentCardSpaceTop: number = 20; // 透明卡片顶部距离；
  public transparentCardSpaceOne: number = 11; // 透明卡片第一行到第二行得底边距
  public transparentCardSpaceOTwo: number = 17; // 透明卡片第二行到第三行得底边距
  public transparentCardCircleDiameter: number = 40; // 透明卡片圆环得直径
  public transparentCardImageIconWidth: number = 18; // 透明卡片图片图标尺寸
  public transparentCardImageIconHeight: number = 18; // 透明卡片图片图标尺寸
  public transparentCardAgendaMaxFontSize: number = 20; //透明卡片日程大小最大值
  public transparentCardAgendaMinFontSize: number = 12; //透明卡片日程大小最小值
  public transparentCardDateFontSize = 20; // 透明卡片日期大小
  public transparentCardWeekTitleSize = 16; // 透明卡片周日期大小
  public transparentCardPadding = 26; // 透明卡左右间距
  public transparentCardLineHeight = 16; // 透明卡时间和日程之间的竖线高度

  public conflictingAgendaPopUpWidth: number = 340; // 冲突日程的气泡弹窗宽度

  public transparentCardAgendaUpPartHeight: number = 67; // 透明卡片上半部分高度
  public transparentCardAgendaUpPartPercent: number = 26; // 透明卡片上半部分高度
  public transparentCardAgendaDownPartPercent: number = 20; // 透明卡片下半部分高
  public cardAgendaTitleMaxLines: number = 2;

  public cardLineHeightTypeZero2X2: number = 18; // 2X2卡片type0日程对应线的长度
  public cardLineHeightTypeOne2X2: number = 33; // 2X2卡片type1日程对应线的长度
  public cardLineHeightTypeTwo2X2: number = 34; // 2X2卡片type2日程对应线的长度
  public cardLineHeightTypeThree2X2: number = 50; // 2X2卡片type3日程对应线的长度

  public cardEditBreakpoints: Array<string> = ['600vp', '860vp'] // 卡片编辑断点
  public cardEditGridColOptions: GridColOptions = {
    // 卡片编辑栅格
    offset: {
      xs: 0,
      sm: 1,
      md: 2,
    },
    span: {
      xs: 4,
      sm: 6, // 小设备，6/8。
      md: 8, // 中设备，8/12。
    }
  }
  public cardEditVGridColOptions: GridColOptions = {
    // 卡片编辑栅格
    offset: {
      xs: 0,
      sm: 0,
      md: 1,
    },
    span: {
      xs: 4,
      sm: 8, // 小设备，8/8。
      md: 10, // 中设备，10/12。
    }
  }

  public agendaDot: number = 3;
}

export class BigDeviceLayout implements DeviceLayout {
  public cardOneKeyServiceFontSize: number = 14; // 卡片一键入会字体大小
  public cardAgendaTitleFontSize: number = 16; // 卡片日程标题字体大小
  public cardAgendaLocationFontSize = $r('sys.float.ohos_id_text_size_body3'); // 卡片日程地点字体大小
  public cardAgendaTimeFontSize = $r('sys.float.Caption_M'); // 卡片日程时间字体大小
  public cardAgendaTimeFontFixedSize = '12vp'; // 2x2卡片日程时间字体固定大小(不随适老化变化)
  public cardAgendaTimeWidth: number = 67; // 卡片日程时间条宽度

  public noCardAgendaCircleSize: number = 22; // 无日程卡片日期红圈大小
  public noCardAgendaFontSize: number = 12; // 无日程卡片字体大小
  public noCardAgendaFontSize4x4: number = 16; // 无日程卡片字体大小4x4
  public noAgendaCardWeekTitleFontSize: number = 10; // 无日程卡片右侧星期标题字体大小4x4
  public noAgendaCardMonthViewTopOffset: Dimension = '4%';
  public cardCircleSize: number = 18; // 月视图2x2圆大小
  public monthCard4x4FontSize: number = 17; // 月视图4x4字体大小

  public buttonTopHeight: number = 8; // 按钮距离顶部的额外高度
  public sidebarWidth: number = 240; // 侧边栏宽度
  public sidebarBackgroundColor = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景
  public sidebarBackgroundColorOverlay = $r('sys.color.ohos_id_color_panel_bg'); // 侧边栏背景=悬浮态
  public sidebarAccountBC = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景
  public sidebarAccountBCOverlay = $r('sys.color.comp_background_list_card'); // 侧边栏账户卡片背景-悬浮态
  public searchBackgroundColor = $r('sys.color.background_secondary'); // 搜索栏的背景色
  public searchBackgroundBlur = BlurStyle.NONE; // 搜索栏的模糊效果
  public cancelButtonBackgroundColor = $r('sys.color.comp_background_tertiary'); // 取消按钮的背景色
  public transparentCardSpaceTop: number = 24; // 透明卡片顶部距离；
  public transparentCardSpaceOne: number = 16; // 透明卡片第一行到第二行得底边距
  public transparentCardSpaceOTwo: number = 18; // 透明卡片第二行到第三行得底边距
  public transparentCardCircleDiameter: number = 40; // 透明卡片圆环得直径
  public transparentCardImageIconWidth: number = 18; // 透明卡片图片图标尺寸
  public transparentCardImageIconHeight: number = 18; // 透明卡片图片图标尺寸
  public transparentCardAgendaMaxFontSize: number = 20; //透明卡片日程大小最大值
  public transparentCardAgendaMinFontSize: number = 12; //透明卡片日程大小最小值
  public transparentCardDateFontSize = 20; // 透明卡片日期大小
  public transparentCardWeekTitleSize = 16; // 透明卡片周日期大小
  public transparentCardPadding = 12; // 透明卡左右间距
  public transparentCardLineHeight = 16; // 透明卡时间和日程之间的竖线高度

  public conflictingAgendaPopUpWidth: number = 322; // 冲突日程的气泡弹窗宽度

  public transparentCardAgendaUpPartHeight: number = 67; // 透明卡片上半部分高度
  public transparentCardAgendaUpPartPercent: number = 21; // 透明卡片上半部分高度
  public transparentCardAgendaDownPartPercent: number = 13; // 透明卡片下半部分高度
  public cardAgendaTitleMaxLines: number = 2;

  public cardLineHeightTypeZero2X2: number = 18; // 2X2卡片type0日程对应线的长度
  public cardLineHeightTypeOne2X2: number = 33; // 2X2卡片type1日程对应线的长度
  public cardLineHeightTypeTwo2X2: number = 34; // 2X2卡片type2日程对应线的长度
  public cardLineHeightTypeThree2X2: number = 50; // 2X2卡片type3日程对应线的长度

  public cardEditBreakpoints: Array<string> = ['600vp', '840vp', '1440vp'] // 卡片编辑断点
  public cardEditGridColOptions: GridColOptions = {
    // 卡片编辑栅格
    offset: {
      xs: 0,
      sm: 0,
      md: 2,
      lg: 1,
    },
    span: {
      xs: 4, // 小设备，4/4。
      sm: 8, // 中设备，8/8。
      md: 8, // 大设备，8/12。
      lg: 10, // 大设备，10/12。
    }
  }
  public cardEditVGridColOptions: GridColOptions = this.cardEditGridColOptions

  public agendaDot: number = 2;
}
