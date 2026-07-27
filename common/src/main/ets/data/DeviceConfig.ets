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

import deviceInfo from '@ohos.deviceInfo';
import { deviceType, DialogParams } from '../default/common/declare';
import { Log } from '../default/common/Log';
import { BigDeviceLayout, DeviceLayout, MediumDeviceLayout, SmallDeviceLayout } from './DeviceLayout';
import { WelinKInfoDisplayParams } from './WelinKInfoDisplayParams';
import { systemParameterEnhance } from '@kit.BasicServicesKit';

const TAG: string = 'GlobalProp';

// 功能枚举
export enum FeatureType {
  SUBSCRIPTION, //订阅服务
  MAP_SELECTION_POINT, // 日程地图选点
  INTELLIGENT_CREATE, // 日程智能创建
  AGENDA_SHARE, // 日程共享
  CALENDAR_SHARE, // 日历共享
  ATTACHMENT, // 日程附件管理
  GUIDE_PAGE, //指导页
  IMPORTANT_DAY_CARD_CUSTOM_BACKGROUND, //重要日卡片自定义背景
  EMOTIONAL_HOLIDAY, //情感化节假日
  SCHEDULE // 课程表操作
}

export interface Config {
  // 是否显示悬浮按钮 [回到今天 新建日程]
  showFloatButton: boolean;
  isShowLeftBar: boolean; //侧边栏是否显示

  showBackInDivide: boolean; //暂用,左右分屏是否在月视图右侧显示回到今天按钮,目前只有折叠机

  isShowMiniMonth: boolean; //是否显示迷你月视图

  isShowBottom: boolean; //是否显示底边按钮 [日程详情界面新增删除分享]

  deviceLayout: DeviceLayout; //用于区分卡片在不同设备上的ux变化

  welinKInfoDisplayParams: WelinKInfoDisplayParams; //用于区分webwiew上welink在不同设备上的ux变化

  swiperCacheCount: number; // swiper缓存数量，默认值为1，PC上因为整机50窗负载问题，暂时切换为0

  needChangeAreaHeight: boolean; //用于判断是否需要感知系统规避高度的变化,pc暂不需要感知

  antialiasingNumber: number; //用于svg图像模糊效果的数值,目前只有pc需要模糊化处理

  needAutoRotationWidth: number; //开启旋屏配置的宽度,-1表示永不开启

  needAreaTopForShare: boolean; // 用于判断共享联系人界面是否需要对顶部状态栏进行规避

  isShowBtBackGround: boolean; // 底部单按钮的dialog 是否显示底部按钮的背景 pc是,pc否

  needAutoFocus: boolean; // 用于区分新建日程切换Tab时，是否需要自动获焦

  needCommerce: boolean; //商务化改造适配参数

  needPreview: boolean; // 是否需要点击显示日程详情

  needCheckRatio: boolean; //用于平板宽高达到指定比例时转换为上下布局

  showAboutInSetting: boolean; // 用于区分设置页面显示关于的样式

  showStatusBarInPermission: boolean; // 用于区分状态栏是否显示

  showStartPageBackground: boolean; // 用于区分启屏页深色模式背景

  needKeyBoardFocus: boolean; // 是否需要默认获焦拉起键盘

  needShowUpperRightButton: boolean; // 是否需要显示账户详情右上按钮

  agendaBlockFontSize: number; // 日程块字体大小

  agendaItemMainFontSize: Resource; // 日程卡片主标题字体大小

  agendaItemSubFontSize: Resource; //  日程卡片父标题字体大小

  monthAgendaBlockHeight: number; // 月视图日程块高度

  isRightClickToDeleteAllowed: boolean; // 是否支持日程卡右键删除

  cardBorderRadiusOnPC: boolean; //用于区分PC卡片圆角大小 PC16 手机20

  supportsWarmStart: boolean; // 热启动特性，当前PC需要开启

  ganttNeedAdapt: boolean; // 周日视图是否需要计算布局参数

  deviceRadius: number; // 设备圆角

  detailRatio: number; // 月日视图分栏状态下的比例

  needPanDivide: boolean; // 是否需要隐形拖动

  showMorePagePopUp: boolean; // 更多按钮通过 popUp 显示，当前仅PC需要开启

  agendaDetailShowBottomTab: boolean; // 日程详情是否显示下方详情

  dialogParam: DialogParams; // 弹窗样式

  rowMinHeight: number; // 用于区分商务化列表高度

  agendaListTotalMargin: number; // 月视图日程列表左右间距和

  popUpItemMargin: number; // 弹出框选项左右边距

  popUpItemBorderRadius: number; // 弹出框选项圆角半径

  isWindowDecorVisible: boolean; // 窗口标题栏是否可见

  isCreateAgendaPopup: boolean; // 新建日程弹窗是否跟手

  isDefaultSubDetail: boolean; //是否默认详情子窗打开

  isSubDetailCheck: boolean; //详情子窗是否需要校验宽度,用于折叠机的子窗切换场景

  bottomAvoidAreaHeight: number;
  bindSheetWindowHeight: number | string;
  showAgendaAbbreviation: boolean; // 是否显示智能创建

  monthViewOpenSplitFrames: boolean; // 月视图是否分帧送显

  weekendSettingDivider: number; //设置-周末-样式分割线距离

  customRepeatPopContentHeight: boolean; //新建日程自定义界面是否限制最大弹出高度

  agendaTitleToLocationHeight:number; //日程列表标题到地址的间距

  isSettingRootNeedScrollBar: boolean; //日历设置是否需要滚动条

  emptyAgendaListAvoid: boolean; //搜索日程空白界面是否需要规避软键盘

  showGridBackgroundDate: boolean; //是否显示宫格底纹日期

  keyboardSwitchingDate: boolean; // 是否支持键盘切换日期

  isScheduleBindSheetPopup: boolean; // 课程表半模态是否跟手

  isNeedShowGuidePage: boolean; // 是否需要显示引导页

  isWideScreenGuidePage: boolean; // 是否显示宽屏的引导页

  supportAICutout: boolean; // 是否支持抠图

  featureMap: Map<FeatureType, boolean>;

  scheduleShowAllCourse: boolean // 月视图课表卡片是否显示全部课程
}

export class PhoneConfig implements Config {
  showFloatButton: boolean = true;
  isShowLeftBar: boolean = false;
  public showBackInDivide: boolean = true;
  isShowMiniMonth: boolean = false;
  isShowBottom: boolean = true;
  deviceLayout: DeviceLayout = new SmallDeviceLayout();
  swiperCacheCount: number = 1;
  needChangeAreaHeight: boolean = true;
  antialiasingNumber: number = 0;
  public needAutoRotationWidth: number = 600;
  needAreaTopForShare: boolean = false;
  isShowBtBackGround: boolean = false;
  public needAutoFocus: boolean = false;
  public needCommerce: boolean = false;
  public needPreview: boolean = false;
  public needCheckRatio: boolean = false;
  public showAboutInSetting: boolean = false;
  public showStatusBarInPermission: boolean = true;
  public showStartPageBackground: boolean = true;
  public needKeyBoardFocus: boolean = false;
  public needShowUpperRightButton: boolean = true;
  public agendaBlockFontSize: number = 12;
  public agendaItemMainFontSize: Resource = $r('sys.float.Subtitle_M');
  public agendaItemSubFontSize: Resource = $r('sys.float.Body_M');
  public monthAgendaBlockHeight: number = 16;
  public isRightClickToDeleteAllowed: boolean = false;
  public cardBorderRadiusOnPC: boolean = false;
  public supportsWarmStart: boolean = true;
  public ganttNeedAdapt: boolean = false;
  public deviceRadius: number = 20;
  public detailRatio: number = 1;
  public needPanDivide: boolean = false;
  public showMorePagePopUp: boolean = false;
  public agendaDetailShowBottomTab = true;
  public dialogParam: DialogParams = new DialogParams(360, true, '#00ffffff', 8, 16);
  public rowMinHeight: number = 48;
  public agendaListTotalMargin: number = 32;
  public popUpItemMargin: number = 8;
  public popUpItemBorderRadius: number = 16;
  public welinKInfoDisplayParams: WelinKInfoDisplayParams = new WelinKInfoDisplayParams(true, true);
  public isWindowDecorVisible: boolean = true;
  public isCreateAgendaPopup: boolean = false;
  public isDefaultSubDetail: boolean = false;
  public isSubDetailCheck: boolean = true;
  public bottomAvoidAreaHeight: number = 28;
  public bindSheetWindowHeight = '100%';
  public showAgendaAbbreviation: boolean = true;
  public monthViewOpenSplitFrames: boolean = false;
  public weekendSettingDivider: number = 18;
  public customRepeatPopContentHeight: boolean = false;
  public agendaTitleToLocationHeight: number = 6;
  public isSettingRootNeedScrollBar: boolean = true;
  public emptyAgendaListAvoid: boolean = true;
  public showGridBackgroundDate: boolean = false;
  public keyboardSwitchingDate: boolean = false;
  public isScheduleBindSheetPopup: boolean = false;
  public isNeedShowGuidePage: boolean = true;
  public isWideScreenGuidePage: boolean = false;
  public supportAICutout: boolean = true;
  public featureMap: Map<FeatureType, boolean> = new Map();
  public scheduleShowAllCourse: boolean = false;
}

export class TabletConfig implements Config {
  showFloatButton: boolean = true;
  isShowLeftBar: boolean = true;
  public showBackInDivide: boolean = false;
  isShowMiniMonth: boolean = false;
  isShowBottom: boolean = false;
  deviceLayout: DeviceLayout = new MediumDeviceLayout();
  swiperCacheCount: number = 0;
  needChangeAreaHeight: boolean = true;
  antialiasingNumber: number = 0.34;
  public needAutoRotationWidth: number = 0;
  needAreaTopForShare: boolean = true;
  isShowBtBackGround: boolean = false;
  public needAutoFocus: boolean = false;
  public needCommerce: boolean = false;
  public needPreview: boolean = true;
  public needCheckRatio: boolean = true;
  public showAboutInSetting: boolean = true;
  public showStatusBarInPermission: boolean = true;
  public showStartPageBackground: boolean = false;
  public needKeyBoardFocus: boolean = false;
  public needShowUpperRightButton: boolean = true;
  public agendaBlockFontSize: number = 14;
  public agendaItemMainFontSize: Resource = $r('sys.float.Subtitle_M');
  public agendaItemSubFontSize: Resource = $r('sys.float.Body_M');
  public monthAgendaBlockHeight: number = 20;
  public isRightClickToDeleteAllowed: boolean = true;
  public cardBorderRadiusOnPC: boolean = true;
  public supportsWarmStart: boolean = false;
  public ganttNeedAdapt: boolean = true;
  public deviceRadius: number = 20;
  public detailRatio: number = 0.618;
  public needPanDivide: boolean = true;
  public showMorePagePopUp: boolean = true;
  public agendaDetailShowBottomTab = false;
  public dialogParam: DialogParams = new DialogParams(360, true, '#00ffffff', 8, 16);
  public rowMinHeight: number = 48;
  public agendaListTotalMargin: number = 30;
  public popUpItemMargin: number = 8;
  public popUpItemBorderRadius: number = 16;
  public welinKInfoDisplayParams: WelinKInfoDisplayParams = new WelinKInfoDisplayParams(true, false);
  public isWindowDecorVisible: boolean = true;
  public isCreateAgendaPopup: boolean = true;
  public isDefaultSubDetail: boolean = true;
  public isSubDetailCheck: boolean = false;
  public bottomAvoidAreaHeight: number = 28;
  public bindSheetWindowHeight = '100%';
  public showAgendaAbbreviation: boolean = true;
  public monthViewOpenSplitFrames: boolean = false;
  public weekendSettingDivider: number = 18;
  public customRepeatPopContentHeight: boolean = true;
  public agendaTitleToLocationHeight:number = 6;
  public isSettingRootNeedScrollBar: boolean = false;
  public emptyAgendaListAvoid: boolean = false;
  public showGridBackgroundDate: boolean = true;
  public keyboardSwitchingDate: boolean = true;
  public isScheduleBindSheetPopup: boolean = true;
  public isNeedShowGuidePage: boolean = true;
  public isWideScreenGuidePage: boolean = true;
  public supportAICutout: boolean = true;
  public featureMap: Map<FeatureType, boolean> = new Map();
  public scheduleShowAllCourse: boolean = true;
}

export class PcConfig implements Config {
  showFloatButton: boolean = false;
  isShowLeftBar: boolean = true;
  public showBackInDivide: boolean = false;
  isShowMiniMonth: boolean = true;
  isShowBottom: boolean = false;
  deviceLayout: DeviceLayout = new BigDeviceLayout();
  swiperCacheCount: number = 0;
  needChangeAreaHeight: boolean = false;
  antialiasingNumber: number = 0.34;
  public needAutoRotationWidth: number = -1;
  needAreaTopForShare: boolean = false;
  isShowBtBackGround: boolean = true;
  public needAutoFocus: boolean = true;
  public needCommerce: boolean = true;
  public needPreview: boolean = true;
  public needCheckRatio: boolean = false;
  public showAboutInSetting: boolean = true;
  public showStatusBarInPermission: boolean = false;
  public showStartPageBackground: boolean = false;
  public needKeyBoardFocus: boolean = true;
  public needShowUpperRightButton: boolean = false;
  public agendaBlockFontSize: number = 14;
  public agendaItemMainFontSize: Resource = $r('sys.float.Subtitle_S');
  public agendaItemSubFontSize: Resource = $r('sys.float.ohos_id_text_size_body3');
  public monthAgendaBlockHeight: number = 20;
  public isRightClickToDeleteAllowed: boolean = true;
  public cardBorderRadiusOnPC: boolean = true;
  public supportsWarmStart: boolean = true;
  public ganttNeedAdapt: boolean = true;
  public deviceRadius: number = 16;
  public detailRatio: number = 0.618;
  public needPanDivide: boolean = true;
  public showMorePagePopUp: boolean = true;
  public agendaDetailShowBottomTab = false;
  public dialogParam: DialogParams = new DialogParams(394, false, $r('sys.color.comp_background_tertiary'), 16, 24);
  public rowMinHeight: number = 40;
  public agendaListTotalMargin: number = 28;
  public popUpItemMargin: number = 12;
  public popUpItemBorderRadius: number = 8;
  public welinKInfoDisplayParams: WelinKInfoDisplayParams = new WelinKInfoDisplayParams(false, false);
  public isWindowDecorVisible: boolean = false;
  public isCreateAgendaPopup: boolean = true;
  public isDefaultSubDetail: boolean = false;
  public isSubDetailCheck: boolean = false;
  public bottomAvoidAreaHeight: number = 0;
  public bindSheetWindowHeight = '560vp';
  public showAgendaAbbreviation: boolean = true;
  public monthViewOpenSplitFrames: boolean = true;
  public weekendSettingDivider: number = 28;
  public customRepeatPopContentHeight: boolean = true;
  public agendaTitleToLocationHeight:number = 9;
  public isSettingRootNeedScrollBar: boolean = false;
  public emptyAgendaListAvoid: boolean = false;
  public showGridBackgroundDate: boolean = true;
  public keyboardSwitchingDate: boolean = true;
  public isScheduleBindSheetPopup: boolean = true;
  public isNeedShowGuidePage: boolean = false;
  public isWideScreenGuidePage: boolean = false;
  public supportAICutout: boolean = true;
  public featureMap: Map<FeatureType, boolean> = new Map();
  public scheduleShowAllCourse: boolean = true;
}

// 设备配置管理,根据设备类型管理相关配置
export class DeviceConfig {
  private static _instance: DeviceConfig = new DeviceConfig();

  constructor() {
    this._config = new PhoneConfig();
  }

  private _deviceType: deviceType = deviceType.PHONE;

  public get deviceType(): deviceType {
    return this._deviceType;
  }

  private _config: Config;

  public get config(): Config {
    return this._config;
  }

  private _isHarmonyShareAvailable: boolean = false;

  public get isHarmonyShareAvailable(): boolean {
    return this._isHarmonyShareAvailable;
  }

  static instance(): DeviceConfig {
    return DeviceConfig._instance;
  }

  static devTypeStr2Enum(str: string): deviceType {
    if (str === 'phone') {
      return deviceType.PHONE;
    } else if (str === 'tablet') {
      return deviceType.TABLET;
    } else if (str === '2in1') {
      return deviceType.PC;
    } else if (str === 'pc') {
      return deviceType.PC;
    }
    return deviceType.PHONE;
  }

  // 是否为7315L芯片
  is7315L(): boolean {
    const romVersion = deviceInfo?.displayVersion?.toUpperCase();
    if (!romVersion) {
      Log.warn(TAG, `is7315L, romVersion is null`);
      return false;
    }

    Log.info(TAG, `is7315L, romVersion: ${romVersion}`);
    const romVersionList = ['MIS', 'BLK', 'PSD', 'TLR', 'ADA', 'BTKR', 'BJS5', 'BLKS', 'BRES'];
    return romVersionList.some(vers => romVersion.startsWith(vers));
  }

  // 判断设备是否支持PC模式
  private isSupportWindowPcModeSwitch(): boolean {
    try {
      const isSupportWindowPcMode: boolean = systemParameterEnhance.getSync('const.window.support_window_pcmode_switch', 'false') === 'true';
      Log.info(TAG, `isSupportWindowPcModeSwitch isSupportWindowPcMode:${isSupportWindowPcMode}`);
      return isSupportWindowPcMode;
    } catch (err) {
      Log.hilogError(TAG, 'Get switch supportWindowPcModeSwitch failed', err);
      return false;
    }
  }

  // 判断当前是否PC模式
  private getPcModeSwitch(): boolean {
    try {
      const isPcMode: boolean = systemParameterEnhance.getSync('persist.sceneboard.ispcmode', 'false') === 'true';
      return isPcMode;
    } catch (err) {
      Log.hilogError(TAG, 'Get pc mode switch failed', err);
      return false;
    }
  }

  isEmulator(): boolean {
    const productModelInfo: string = deviceInfo.productModel; //productModelInfo == 'emulator'
    Log.info(TAG, `the value of the deviceinfo productModel is :${productModelInfo}`);
    return productModelInfo === 'emulator';
  }

  public init() {
    Log.info(TAG, 'deviceInfo.deviceType:' + deviceInfo.deviceType)
    this._deviceType = DeviceConfig.devTypeStr2Enum(deviceInfo.deviceType);
    this.initConfig();
    this.featureMapInit();

    if (this.is7315L()) {
      this._config.supportAICutout = false;
    }

    if (this.isEmulator()) {
      this.setFeature(FeatureType.SUBSCRIPTION,false);
      this.setFeature(FeatureType.MAP_SELECTION_POINT,false);
      this.setFeature(FeatureType.INTELLIGENT_CREATE,false);
      this.setFeature(FeatureType.AGENDA_SHARE,false);
      this.setFeature(FeatureType.CALENDAR_SHARE,false);
      this.setFeature(FeatureType.ATTACHMENT,false);
      this.setFeature(FeatureType.EMOTIONAL_HOLIDAY,false);
      this.setFeature(FeatureType.GUIDE_PAGE, false);
      this.setFeature(FeatureType.IMPORTANT_DAY_CARD_CUSTOM_BACKGROUND, false);
    }

    if (canIUse('SystemCapability.Collaboration.HarmonyShare')) {
      this._isHarmonyShareAvailable = true;
    }

    if (this.isSupportWindowPcModeSwitch() && this.getPcModeSwitch()) {
      this._config.supportsWarmStart = true;
    }
  }

  private initConfig() {
    if (this.deviceType === deviceType.PHONE) {
      this._config = new PhoneConfig()
    } else if (this.deviceType === deviceType.TABLET) {
      this._config = new TabletConfig()
    } else if (this.deviceType === deviceType.PC) {
      this._config = new PcConfig()
    }
  }

  public isSupport(supportId: FeatureType): boolean {
    return this._config.featureMap[supportId] ?? false;
  }

  public setFeature(supportId: FeatureType, value: boolean): void {
    this._config.featureMap[supportId] = value;
  }

  //初始化featureMap
  private featureMapInit(){
    for(let feature of Object.keys(FeatureType)){
      this._config.featureMap[feature] = true;
    }
  }
}