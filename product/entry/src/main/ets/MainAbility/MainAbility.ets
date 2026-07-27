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

import Ability from '@ohos.app.ability.UIAbility';
import rpc from '@ohos.rpc';
import emitter from '@ohos.events.emitter';
import {
  AbilityStateHelper,
  AppContinueManager,
  BackGroundTaskUtil,
  behaviorEvents,
  BigFontSize,
  CalendarService,
  CloudUtils,
  CommonInnerEvent,
  ContinueParam,
  ContinueType,
  DateManager,
  DeviceConfig,
  deviceType,
  EmptyUtils,
  EventService,
  FoldScreenType,
  GlobalData,
  GlobalDataKeys,
  GlobalEnv,
  GlobalEnvEnum,
  GlobalThis,
  I18nUtil,
  InitializeHelper,
  Log,
  NavPathManager,
  NavPathName,
  NotificationHelper,
  PageParam,
  PreferencesFiles,
  PreferencesUtil,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceEnvEvent,
  ServiceGlobalEnv,
  statisticEvents,
  SubscriptionCalendar,
  TabType,
  ThrottleFunction,
  traceEvents,
  UnusualMode,
  WindowSizeManager
} from '@app/common';
import window from '@ohos.window';
import data_preferences from '@ohos.data.preferences';
import Want from '@ohos.app.ability.Want';
import { BusinessError } from '@ohos.base';
import { SettingStore } from '@app/feature.settings';
import { HAGHelper } from '@app/service.network/src/main/ets/onelink/HAGHelper';
import { WindowManager } from '../pages/StatusBarManager';
import hiTraceMeter from '@ohos.hiTraceMeter';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import { Configuration } from '@ohos.app.ability.Configuration';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { display } from '@kit.ArkUI';
import lazy { promptAction } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { NetConnectionUtil, NetState } from '@app/service.network';
import { FestivalAbbreviationMap } from '@app/common/src/main/ets/date/FestivalAbbreviationMap';
import { CommonStatusHelper } from '@app/common/src/main/ets/dao/helper/CommonStatusHelper';
import { PaletteCache } from '@app/common/src/main/ets/graphic/PaletteCache';
// import lazy { systemShare } from '@kit.ShareKit'; // ShareKit 注释
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';

const TAG: string = 'MainAbility';

export default class MainAbility extends Ability {
  private storage: LocalStorage = new LocalStorage();
  private isLoadContent: boolean = true; // 是否为初始化加载
  private readonly cutNeedAvoidHeight: number = 16; // 刘海屏避让高度 PCE特有
  private readonly toolBarHeight: number = 56; // 挖孔所在位置需要避让的toolbar高度
  private cutAvoidHeight: number = 0; // 刘海屏高度
  private topHeight: number = 0; // 系统规避区高度
  private oldWindowStatusType: number = 0; // 窗口类型
  private delayTaskId: number = 0;
  private prepareContinueState: boolean = false; // 预备接续
  private displayId: number | undefined = undefined; // 当前context对应的displayId

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hiTraceMeter.startTrace(traceEvents.mainAbilityCreate, 0);
    AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('paf.currentColorMode', this.context.config.colorMode)
    AppContinueManager.getInstance().setAppContinueState(false, this.context); // 启动应用时默认禁用接续
    GlobalThis.getInstance().abilityWant = want;
    GlobalThis.getInstance().fileDir = this.context.filesDir;
    GlobalThis.getInstance().context = this.context;
    this.storage.setOrCreate('uiAbilityContext', this.context);
    GlobalThis.getInstance().mainAbilityContext = this.context;
  //  GlobalData.instance().initLanguageAndDate();
    DateManager.getInstance().init();
    this.handleInitialize();
    HAGHelper.instance().init();
    // 应用热启特性,应用退出冷启后，进程号不会变，static变量需要初始化
    CommonStatusHelper.INSTANCE.setIsFirstCheckExceptionAccount(true);
    this.initByDisplayId(GlobalThis.getInstance().context?.config.displayId);
    if (DeviceConfig.instance().config.supportsWarmStart) {
      let applicationContext = this.context.getApplicationContext();
      try {
        applicationContext.setSupportedProcessCache(true);
      } catch (error) {
        Log.error(TAG, `ability setSupported returns code ${error?.code}, returns msg ${error?.message}`);
      }
    }
    GlobalThis.getInstance().tokenId = rpc.IPCSkeleton.getCallingTokenId();
    ReportUtil.reportStatisticEvent(statisticEvents.openClickDeskIcon);
    NetConnectionUtil.subscribe(TAG, (netState: NetState) => {
      GlobalData.instance().set(GlobalDataKeys.IS_NETWORK_AVAILABLE, netState == NetState.NET_AVAILABLE);
      if (netState == NetState.NET_AVAILABLE) {
        Log.log(TAG, 'onCreate netConnection success');
        emitter.emit({
          eventId: CommonInnerEvent.UPDATE_RECESS
        });
      }
    });
    // 判断如果是从卡片点击进入月视图 或 从日程预览模块跳入，将tab标签设置为月
    if (want.parameters?.action === 'CLICK_MONTH_FORM_HEADER' || want.parameters?.action === 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW') {
      PreferencesUtil.putNumberValueSync('tabIndex', 'tabIndex', TabType.MONTH);
    }
    Log.info(TAG, `launchParam.launchReason ${launchParam.launchReason}`);
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.continueTabIndex(want);
      this.continueAgenda(want);
      // 触发页面恢复并关闭原端应用
      this.context.restoreWindowStage(this.storage);
    }
    if (launchParam.launchReason === AbilityConstant.LaunchReason.PREPARE_CONTINUATION) {
      this.prepareContinueState = true;
      PreferencesUtil.putBooleanValueSync('tabIndex', 'prepareContinueState', true);
    }
    AbilityStateHelper.getInstance()
      .addAbilityForegroundCall(this.context, NotificationHelper.getInstance().mainAbilityForegroundChangedCall);
    CloudUtils.subscribedSyncSwitchStatus();
    GlobalThis.getInstance().fontSizeScale =
      this.context.config.fontSizeScale ?? BigFontSize.BIG_FONT_SIZE_STANDARD; // 获取系统字体放大倍数
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.MAIN_ABILITY_CREATE);
    hiTraceMeter.finishTrace(traceEvents.mainAbilityCreate, 0);
  }

  async onConfigurationUpdate(newConfig: Configuration): Promise<void> {
    try {
      Log.info(TAG, `Configuration is Updated Now! language = ${newConfig.language}`);
      if (newConfig.language && AppStorage.get<string>('language') !== newConfig.language) {
        FestivalAbbreviationMap.freshFestivalAbbreviationMap(newConfig.language);
        AppStorage.setOrCreate('language', newConfig.language);
      }

      Log.info(TAG, 'Configuration is Updated Now! fontSizeScale = ' + newConfig.fontSizeScale);
      if (this.displayId !== newConfig.displayId) {
        this.initByDisplayId(newConfig.displayId);
      }
      if (newConfig.fontSizeScale &&
        GlobalData.instance().get(GlobalDataKeys.FONT_SIZE_SCALE) !== newConfig.fontSizeScale
      ) {
        AppStorage.setOrCreate('fontSizeScale', newConfig.fontSizeScale);
      }

      if (newConfig.fontSizeScale && GlobalThis.getInstance().fontSizeScale !== newConfig.fontSizeScale) {
        GlobalThis.getInstance().fontSizeScale = newConfig.fontSizeScale;
      }

      this.refreshConfig();
      // SystemUI 控制中心切换深色模式时，应用不会触发 onBackground/onForeground，
      // onConfigurationUpdate 是唯一可靠的回调入口。
      // context.config.colorMode 在此回调中不可靠（实测值未更新），
      // 但 mediaquery 会在 ~30ms 后正确更新 AppStorage('isDarkMode')。
      // 延迟后调用与 onForeground 相同的 refreshDarkMode()，确保走完全一致的刷新路径。
      setTimeout(() => {
        this.refreshDarkMode();
      }, 100);
    } catch (err) {
      Log.logErrorMsg(TAG, 'Configuration Update fail, err is:', err);
    }
  }

  // 提供接续内容
  async continueAgenda(want: Want) {
    let wantParam = want.parameters;
    if (wantParam == undefined) {
      Log.error(TAG, `continueAgenda wantParam undefined`);
      return;
    }
    let continuePageName = wantParam[ContinueParam.continuePageName] as string;
    let uuid = wantParam[ContinueParam.continueEventUUID] as string;
    if (uuid === undefined || EmptyUtils.isEmptyString(uuid)) {
      Log.error(TAG, `continueAgenda uuid empty`);
      return;
    }
    if (continuePageName === undefined || EmptyUtils.isEmptyString(continuePageName)) {
      Log.error(TAG, `continueAgenda continuePageName empty`);
      return;
    }
    Log.info(TAG, `onContinue page from remote ${continuePageName}`);
    if (continuePageName !== NavPathName.AGENDA_DETAIL && continuePageName !== NavPathName.AGENDA_LIST) {
      Log.error(TAG, `continueAgenda continuePageName invalid:${continuePageName}}`);
      return;
    }
    const event = await EventService.INSTANCE.queryEventByUUID(uuid);
    Log.info(TAG, `continueAgenda uuid:${uuid}, mId:${event?.mId}`);
    if (!event || event.mId === -1) {
      Log.warn(TAG, `continueAgenda event not found`);
      promptAction.showToast({
        message: '当前日程不参与云同步，无法跨设备查看'
      }); // 待提翻
      return;
    }
    let calendar = await CalendarService.INSTANCE.queryCalendarById(event?.mCalendarId);
    // 添加continuePage，作为恢复端
    await AppContinueManager.getInstance().addContinuePage({
      pageName: continuePageName!,
      event: event,
      calendarType: calendar?.accountType || ''
    }, ContinueType.RECEIVE)
    // 通知 mainPage 接续
    emitter.emit({
      eventId: CommonInnerEvent.APP_CONTINUE
    });
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam) {
    Log.info(TAG, `onNewWant action is ${want.parameters?.action} | ${this.isLoadContent}`);
    GlobalThis.getInstance().abilityWant = want;
    // ShareKit 注释 - start
    // if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
    //   systemShare.getSharedData(want).then((data: systemShare.SharedData) => {
    //     GlobalThis.getInstance().shareData = data;
    //   }).catch((error: BusinessError) => {
    //     Log.error(TAG, `getSharedData failed: ${error.message}`);
    //   });
    // }
    // ShareKit 注释 - end
    GlobalThis.getInstance().context = this.context;
    this.storage.setOrCreate('uiAbilityContext', this.context);
    if (this.displayId !== this.context.config.displayId) {
      this.initByDisplayId(this.context.config.displayId)
    }
    Log.info(TAG, `onNewWant launchReason: ${launchParam.launchReason}`);
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.continueTabIndex(want);
      this.continueAgenda(want);
      // 触发页面恢复并关闭原端应用
      this.context.restoreWindowStage(this.storage);
      this.prepareContinueState = false; // 结束预备接续
      return;
    }
    this.emitterEvent();
  }

  onDestroy() {
    Log.info(TAG, `onDestroy start`);
    hiTraceMeter.startTrace(traceEvents.mainAbilityDestroy, 0);
    CloudUtils.unSubscribedSyncSwitchStatus();
    DateManager.getInstance().unInit();
    ReportUtil.reportStatisticEvent(statisticEvents.exitCalendar);
    GlobalThis.getInstance().mainAbilityContext = null;
    AbilityStateHelper.getInstance().clearAbility(this.context);
    hiTraceMeter.finishTrace(traceEvents.mainAbilityDestroy, 0);
    if (this.delayTaskId > 0) {
      clearInterval(this.delayTaskId);
    }
    Log.info(TAG, `onDestroy end`);
  }

  async onWindowStageCreate(windowStage: window.WindowStage) {
    Log.info(TAG, `onWindowStageCreate start`);
    // 默认初始化时获焦
    AppStorage.setOrCreate('windowFocused', true);
    this.loadWindowStage(windowStage);
  }

  onWindowStageRestore(windowStage: window.WindowStage) {
    Log.info(TAG, `onWindowStageRestore ${this.isLoadContent}`);
    if (this.isLoadContent) {
      this.loadWindowStage(windowStage);
    }
  }

  loadWindowStage(windowStage: window.WindowStage) {
    hiTraceMeter.startTrace(traceEvents.mainAbilityWindowStage, 0);
    WindowManager.getInstance().registerWindowStage(windowStage);
    this.isLoadContent = false; // 加载完成
    this.loadDataAndPages(windowStage);
    hiTraceMeter.finishTrace(traceEvents.mainAbilityWindowStage, 0);
  }

  continueTabIndex(want: Want) {
    // 将上述保存的数据从want.parameters中取出恢复
    let continueInput = TabType.MONTH;
    if (want.parameters?.hiCarDeviceType === 'Car') {
      GlobalData.instance().set(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.HICAR);
      return;
    } else {
      GlobalData.instance().set(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.DEFAULT);
    }
    if (want.parameters?.continueTabIndex !== undefined) {
      NavPathManager.getInstance().clear(RouterName.ENTRY_HAP);
      continueInput = want.parameters.continueTabIndex as number;
      Log.info(TAG, `continue input ${continueInput} nowState ${this.isLoadContent}`);
      // 通知接续
      PreferencesUtil.putNumberValue('tabIndex', 'tabIndex', continueInput);
      Log.info(TAG, `continueTabIndex set tabIndex ${continueInput}`);
      let eventData: emitter.EventData = {
        data: {
          'tabIndex': continueInput,
        }
      };
      // 发送tab切换广播
      emitter.emit({
        eventId: CommonInnerEvent.SWITCH_MAIN_PAGE_TAB
      }, eventData);
      // 发送卡片用的关闭所有弹窗页面的广播
      emitter.emit({
        eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH
      })
    }
    // 接续选中日期
    if (want.parameters?.continueDisplayDate !== undefined) {
      const displayDate = want.parameters.continueDisplayDate as number;
      Log.info(TAG, `continue displayDate ${displayDate} nowState ${this.isLoadContent}`);
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, displayDate);
      if (!this.isLoadContent) {
        // 页面处于已加载则需要发送变更广播
        emitter.emit({
          eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE
        });
      }
    }
    this.prepareContinueState = false;
  }

  async loadDataAndPages(windowStage: window.WindowStage) {
    await this.loadPreferences();
    await this.loadServiceType();
    // 放在  windowStage.getMainWindow().then 方法内,页面空白,放在this.loadPage(windowStage)代码后，windowAvoidAreaTopRectHeight 不稳定
    this.loadPage(windowStage);
  }

  async loadPreferences() {
    try {
      const dataPreferences: data_preferences.Preferences = await data_preferences.getPreferences(this.context, 'tabIndex');
      AppStorage.SetOrCreate('tabIndexPreferences', dataPreferences);
      let tabIndex: number = TabType.MONTH;
      if (dataPreferences) {
        tabIndex = Number(dataPreferences.getSync('tabIndex', TabType.MONTH));
        Log.info(TAG, `loadPreferences tabIndex ${tabIndex}`);
      }
      AppStorage.SetOrCreate('tabIndex', tabIndex);
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      Log.logErrorMsg(TAG, 'Failed to get preferences', e);
    }
  }

  async loadServiceType() {
    try {
      GlobalThis.getInstance().serviceType = PreferencesUtil.getStringArrayValueSync(PreferencesFiles.HAG, 'serviceType', ['Meeting']);
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      Log.logErrorMsg(TAG, 'Failed to get HAG preferences', e);
    }
  }

  // 沉浸式设置
  setImmersiveWindow(windowObj: window.Window) {
    windowObj.setWindowLayoutFullScreen(true);
    const systemBarProperties: window.SystemBarProperties = {
      statusBarColor: '#00000000',
      isStatusBarLightIcon: false,
      statusBarContentColor: '#ff000000',
      navigationBarColor: '#00000000',
      navigationBarContentColor: '#ff000000',
    };
    windowObj.setWindowSystemBarProperties(systemBarProperties);
  }

  loadPage(windowStage: window.WindowStage) {
    // Main window is created, set main page for this ability
    try {
      const windowObj: window.Window = windowStage.getMainWindowSync();

      this.storage.setAndRef('mainWindow', windowObj);

      this.initWindowsFocusChange(windowStage);

      windowStage.loadContent('pages/EntryPage', this.storage, async (err, data) => {
        if (err.code) {
          Log.logErrorMsg(TAG, 'Failed to load the content. Cause: ', err);
          return;
        }
        ReportUtil.reportPageDrawn();
        Log.info(TAG, 'Succeeded in loading the content. ');
        if (DeviceConfig.instance().deviceType !== deviceType.PC) {
          this.setImmersiveWindow(windowObj);
        }

        this.initWindowsSize(windowObj);

        this.initAvoidArea(windowObj);

        this.initWindowsModeChange(windowObj);

        if (DeviceConfig.instance().config.needCommerce) {
          Log.log(TAG, 'start init TitleArea');
          windowObj.setWindowDecorVisible(false);
          windowObj.setWindowDecorHeight(70); // 该值是文档示例
          this.initTitleArea(windowObj);
          windowObj.setDecorButtonStyle({ buttonBackgroundSize: 40 });
        }

        await SettingStore.INSTANCE.init();
        let windowClass = windowStage.getMainWindowSync();
        AppStorage.setOrCreate('uiContext', windowClass.getUIContext());
        AppStorage.setOrCreate<window.Window>('windowClass', windowClass);
        WindowSizeManager.getInstance().init();
      });

    } catch (err) {
      Log.logErrorMsg(TAG, 'windowObj get error', err);
    }
  }

  /**
   * 对窗口尺寸进行初始化设置及监听
   * @param windowObj
   */
  initWindowsSize(windowObj: window.Window) {
    try {
      const needAutoRotationWidth = DeviceConfig.instance().config.needAutoRotationWidth;
      let properties: window.WindowProperties = windowObj.getWindowProperties();
      Log.log(TAG, 'getWindowProperties:' + JSON.stringify(properties));
      this.updateWindowSize(properties.windowRect.width, properties.windowRect.height);

      if (needAutoRotationWidth >= 0) {
        // 设置自动旋转开关
        const windowWidth = px2vp(properties.windowRect.width);
        const windowHeight = px2vp(properties.windowRect.height);
        //判断逻辑,窗口宽高都需要大于指定长度才能打开旋屏开关
        const isOpen = windowWidth >= needAutoRotationWidth && windowHeight >= needAutoRotationWidth;
        this.onDisplayOrientationChange(windowObj, isOpen, true);
      }

      windowObj.on('windowSizeChange', (data) => {
        Log.log(TAG, 'windowSizeChange' + JSON.stringify(data));
        this.updateWindowSize(data.width, data.height);
        if (needAutoRotationWidth > 0) {
          //监听屏幕尺寸变化设置自动旋转开关,无需判断等于0
          const windowWidth = px2vp(data.width);
          const windowHeight = px2vp(data.height);
          //判断逻辑,窗口宽高都需要大于指定长度才能打开旋屏开关
          const isOpen = windowWidth >= needAutoRotationWidth && windowHeight >= needAutoRotationWidth;
          this.onDisplayOrientationChange(windowObj, isOpen);
        }
      });

      // 显示大小变化监听,因显示大小变化不会变更px值导致不会触发windowSizeChange
      windowObj.on('systemDensityChange', (scale) => {
        // 因px2vp的变更存在延时,需要添加延时以防止px2vp更新异常
        ThrottleFunction.instance().debounce(TAG + 'scale', () => {
          const widthPx = this.storage.get<number>(GlobalDataKeys.WINDOW_WIDTH_IN_PX) ?? 0;
          const heightPx = this.storage.get<number>(GlobalDataKeys.WINDOW_HEIGHT_IN_PX) ?? 0;
          this.updateWindowSize(widthPx, heightPx);
          const windowWidthNew = px2vp(widthPx);
          const windowHeightNew = px2vp(heightPx);
          Log.info(TAG, `systemDensityChange window:${widthPx} ${heightPx} ${windowWidthNew}|${windowHeightNew},scale: ${scale}`);
          if (needAutoRotationWidth > 0) {
            //判断逻辑,窗口宽高都需要大于指定长度才能打开旋屏开关
            const isOpen = windowWidthNew >= needAutoRotationWidth && windowHeightNew >= needAutoRotationWidth;
            this.onDisplayOrientationChange(windowObj, isOpen);
          }
        }, 300);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'window properties get error', err);
    }
  }

  /**
   * 对应用窗口规避区的初始化及监听
   * @param windowObj
   */
  initAvoidArea(windowObj: window.Window) {
    // 顶部及底部导航栏规避判断
    const needChangeAreaHeight = DeviceConfig.instance().config.needChangeAreaHeight;

    try {
      let avoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      Log.debug(TAG, 'avoidArea:' + JSON.stringify(avoidArea));
      let cutAvoidArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
      this.cutAvoidHeight = this.getFinalCutAvoidHeight(cutAvoidArea);
      Log.debug(TAG, 'cutAvoidArea:' + JSON.stringify(cutAvoidArea));

      this.updateWindowAvoidAreaHeight(avoidArea.topRect.height + avoidArea.bottomRect.height);

      if (needChangeAreaHeight) {
        // 顶部导航栏
        this.topHeight = Math.floor(px2vp(avoidArea.topRect.height));
        const avoidHeight = this.topHeight > 0 ? this.topHeight : this.cutAvoidHeight;

        AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', avoidHeight);
        AppStorage.setOrCreate<number>(GlobalDataKeys.WINDOW_TOP_AVOID_HEIGHT_IN_PX, avoidArea.topRect.height);
        Log.info(TAG, `windowAvoidAreaTopRectHeight: ${this.topHeight} ${cutAvoidArea.topRect.height}`);

        // 底部导航栏
        let navigationArea = windowObj.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        const navigationHeight = Math.floor(px2vp(navigationArea.bottomRect.height));
        AppStorage.setOrCreate<number>('windowAvoidAreaNavigationRectHeight', navigationHeight);
        Log.info(TAG, 'windowAvoidAreaNavigationRectHeight:' + navigationHeight);
      }
    } catch (exception) {
      Log.error(TAG, 'Failed to obtain the area. Cause:' + exception?.message);
    }
    this.initAvoidAreaListener(windowObj, needChangeAreaHeight);
  }

  initAvoidAreaListener(windowObj: window.Window, needChangeAreaHeight: boolean) {
    try {
      // 小键盘规避
      windowObj.on('keyboardHeightChange', (data) => {
        const keyBoardHeightVp = px2vp(data);
        AppStorage.setOrCreate<number>('keyBoardHeight', keyBoardHeightVp);
      });
      // 规避区监听
      windowObj.on('avoidAreaChange', (data) => {
        if (window.AvoidAreaType.TYPE_SYSTEM === data.type) { // 系统规避区
          this.updateWindowAvoidAreaHeight(data.area.topRect.height + data.area.bottomRect.height);
          this.topHeight = Math.floor(px2vp(data.area.topRect.height));
          if (needChangeAreaHeight) {
            const topHeight = this.topHeight > 0 ? this.topHeight : this.cutAvoidHeight; // 优先系统规避
            AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', topHeight);
            AppStorage.setOrCreate<number>(GlobalDataKeys.WINDOW_TOP_AVOID_HEIGHT_IN_PX, data.area.topRect.height);
          }
          Log.info(TAG, `windowAvoidAreaTopRectHeight change: ${this.topHeight}`);
        } else if (window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR === data.type) { // 导航栏规避区
          if (needChangeAreaHeight) {
            const navigationHeight = Math.floor(px2vp(data.area.bottomRect.height));
            AppStorage.setOrCreate<number>('windowAvoidAreaNavigationRectHeight', navigationHeight);
            Log.info(TAG, 'windowAvoidAreaNavigationRectHeight change:' + navigationHeight);
          }
        } else if (window.AvoidAreaType.TYPE_CUTOUT === data.type) { // 刘海规避区
          this.cutAvoidHeight = this.getFinalCutAvoidHeight(data.area);
          const avoidFinal = this.topHeight > 0 ? this.topHeight : this.cutAvoidHeight;
          AppStorage.setOrCreate<number>('windowAvoidAreaTopRectHeight', avoidFinal);
        }
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed to initAvoidAreaListener', err);
    }
  }

  // 获取刘海规避的最终高度
  private getFinalCutAvoidHeight(area: window.AvoidArea): number {
    const cutAvoidTopHeight = Math.floor(px2vp(area.topRect.height)); // 上刘海规避
    const cutAvoidTop = cutAvoidTopHeight > 0 ? this.cutNeedAvoidHeight : 0; // 上刘海当前写死16
    const cutAvoidLeftTop = Math.floor(px2vp(area.leftRect.top)); // 左刘海规避
    const cutAvoidLeft = // 左刘海是否阻拦工具栏
      cutAvoidLeftTop < this.toolBarHeight ? Math.floor(px2vp(area.leftRect.height)) + cutAvoidLeftTop : 0;
    const cutAvoidRightTop = Math.floor(px2vp(area.rightRect.top)); // 右刘海规避
    const cutAvoidRight = // 右刘海是否阻拦工具栏
      cutAvoidRightTop < this.toolBarHeight ? Math.floor(px2vp(area.rightRect.height)) + cutAvoidRightTop : 0;
    Log.info(TAG,
      `cutAvoidArea get: ${this.topHeight} ${cutAvoidTopHeight} ${cutAvoidLeft} ${cutAvoidRight}`);
    return Math.max(cutAvoidLeft, cutAvoidRight, cutAvoidTop);
  }

  // 初始化窗口状态变更监听
  initWindowsModeChange(windowObj: window.Window): void {
    try {
      const initWindowState = windowObj.getWindowStatus();
      const isMaxWindow = this.checkIsFullScreen(initWindowState);
      this.storage.setOrCreate<boolean>('isFullScreen', isMaxWindow);
      windowObj.on('windowStatusChange', (windowStatusType) => {
        AppStorage.setOrCreate('windowStatusType', windowStatusType);
        const width: number = this.storage.get<number>(GlobalDataKeys.WINDOW_WIDTH_IN_PX) ?? 0;
        const height: number = this.storage.get<number>(GlobalDataKeys.WINDOW_HEIGHT_IN_PX) ?? 0;
        this.updateFloatingWindowState(width, height);
        Log.info(TAG, `windowStatusChange: ${windowStatusType}`);
        let params: ReportHiEventParams = {
          WINDOW_MODE: windowStatusType
        }
        ReportUtil.reportBehaviorEvent(behaviorEvents.changeWindowMode, params);
        let isMaximizeRecovery: boolean = false; // 窗口最大化恢复

        if (windowStatusType === this.oldWindowStatusType) {
          return;
        }
        if (windowStatusType !== this.oldWindowStatusType &&
          this.oldWindowStatusType === window.WindowStatusType.FULL_SCREEN) {
          isMaximizeRecovery = true;
        } else {
          isMaximizeRecovery = false;
        }
        const isMaxWindow = this.checkIsFullScreen(windowStatusType);
        this.storage.setOrCreate<boolean>('isFullScreen', isMaxWindow);

        let eventData: emitter.EventData = {
          data: {
            'isMaximizeRecovery': isMaximizeRecovery
          }
        };
        emitter.emit({
          eventId: CommonInnerEvent.EVENT_MAXIMIZE_RECOVERY
        }, eventData);

        this.oldWindowStatusType = windowStatusType;
      });
      windowObj.on('windowHighlightChange', (isHighlight: boolean) => {
        Log.info(TAG, `window highlight change ${isHighlight}`);
        AppStorage.setOrCreate('windowFocused', isHighlight);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed to enable the listener for window status changes', err);
    }
  }

  private checkIsFullScreen(windowState: window.WindowStatusType): boolean {
    return windowState === window.WindowStatusType.FULL_SCREEN ||
      windowState === window.WindowStatusType.MAXIMIZE;
  }

  // 对应用窗口焦点状态进行监听
  initWindowsFocusChange(windowStage: window.WindowStage) {
    // 当前只有PC商务化需要此改造
    if (!DeviceConfig.instance().config.needCommerce) {
      return;
    }

    try {
      windowStage.on('windowStageEvent', (type: window.WindowStageEventType) => {
        Log.info(TAG, `windowType:${type}`);
      });
    } catch (err) {
      Log.logErrorMsg(TAG, `windowStageEvent bind failed, error code: ${err.code}.`);
    }
  }

  initTitleArea(windowObj: window.Window) {
    AppStorage.setOrCreate('titleButtonWidth', 160); // 当前无法通过windowAPI获取右上按钮宽度,暂时写死
  }

  updateWindowSize(width: number, height: number): void {
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_WIDTH_IN_PX, width);
    this.storage.setOrCreate(GlobalDataKeys.WINDOW_HEIGHT_IN_PX, height);
    this.updateFloatingWindowState(width, height);
    width = Math.round(px2vp(width));
    height = Math.round(px2vp(height));
    this.storage.setOrCreate('windowWidth', width);
    this.storage.setOrCreate('windowHeight', height);
    AppStorage.setOrCreate('windowWidth', width);
    AppStorage.setOrCreate('windowHeight', height);

    GlobalEnv.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, {
      width: width, height: height
    });
  }

  private updateFloatingWindowState(width: number, height: number): void {
    try {
      const defaultDisplay = display.getDefaultDisplaySync();
      const windowStatusType = AppStorage.get('windowStatusType') as number | undefined;
      const isSplitScreen: boolean = windowStatusType === window.WindowStatusType.SPLIT_SCREEN;
      const isFloatingWindow: boolean = !isSplitScreen &&
        (width < defaultDisplay.width || height < defaultDisplay.height);
      AppStorage.setOrCreate('isFloatingWindow', isFloatingWindow);
    } catch (err) {
      AppStorage.setOrCreate('isFloatingWindow', false);
      Log.logErrorMsg(TAG, 'get default display failed', err);
    }
  }

  updateWindowAvoidAreaHeight(height: number): void {
    height = px2vp(height);
    AppStorage.setOrCreate('windowAvoidAreaHeight', height);
  }

  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.WINDOW_STAGE_DESTROY);
  }

  /**
   * 刷新地域等配置信息
   */
  private refreshConfig(){
    try {
      I18nUtil.setSystemRegion();
      const systemRegion: string = I18nUtil.getSystemRegion();
      const is24HourClock = I18nUtil.is24HourClock();
      if (GlobalData.instance().get(GlobalDataKeys.SYSTEM_REGION) === systemRegion && GlobalData.instance()
        .get(GlobalDataKeys.IS_24_HOUR_CLOCK) === is24HourClock) {
        return;
      }
      Log.info(TAG, `refreshConfig systemRegion:${systemRegion} is24HourClock:${is24HourClock}`);
      GlobalData.instance().set(GlobalDataKeys.SYSTEM_REGION, systemRegion);
      GlobalData.instance().set(GlobalDataKeys.IS_24_HOUR_CLOCK, is24HourClock);
      systemRegion === 'CN' ? GlobalData.instance().removeHiddenItem('IS_RECESS_TOGGLE_ON') : GlobalData.instance().addHiddenItem('IS_RECESS_TOGGLE_ON');
      this.onRegionChange();
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      Log.logErrorMsg(TAG, 'refreshConfig Failed', e);
    }
  }

  /**
   * 应用从后台返回前台时，检查系统深色模式是否已变更
   * 实测发现 @StorageProp @Watch 对 AppStorage.setOrCreate 的程序化变更不触发回调，
   * 因此改用 emitter 事件广播 DARK_MODE_REFRESH 通知各视图直接刷新。
   */
  private refreshDarkMode(): void {
    try {
      const isDarkMode = AppStorage.get<boolean>(GlobalDataKeys.IS_DARKMODE) ?? false;
      PaletteCache.instance().setDarkMode(isDarkMode);
      AppStorage.setOrCreate(GlobalDataKeys.IS_DARKMODE, isDarkMode);
      // 通过 emitter 广播通知所有视图直接刷新深色模式，绕过 @Watch 不触发的问题
      emitter.emit({ eventId: CommonInnerEvent.DARK_MODE_REFRESH });
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      Log.logErrorMsg(TAG, 'refreshDarkMode Failed', e);
    }
  }

  onForeground() {
    // Ability has brought to foreground
    Log.info(TAG, 'onForeground Begin Time = ' + Date.now());

    // 应用回到前台时，始终同步 CURRENT_DATE 为当前时间，确保 isToday 标记正确
    // @Watch 在 onForeground 场景下不触发，需额外 emit SYSTEM_TIME_CHANGED 事件绕过
    const nowTime = new Date().getTime();
    GlobalData.instance().set(GlobalDataKeys.CURRENT_DATE, nowTime);
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED });

    // 检查是否跨天，如果跨天则同时更新 DISPLAY_DATE 确保选中状态与今日同步
    const currentDisplayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    const nowDate = new Date(nowTime);
    const displayDate = currentDisplayDate ? new Date(currentDisplayDate) : null;
    const isCrossDay = !displayDate ||
      nowDate.getFullYear() !== displayDate.getFullYear() ||
      nowDate.getMonth() !== displayDate.getMonth() ||
      nowDate.getDate() !== displayDate.getDate();
    if (isCrossDay) {
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, nowTime);
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    }

    //侧滑返回桌面，再进入日历，回到今天，底部上滑回到桌面，再进入日历，不用回到今天
    if (GlobalData.instance().get(GlobalDataKeys.IS_SLIDE_SLIP_BACK)) {
      //返回到前台日期切回到今天，同时更新 DISPLAY_DATE
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, nowTime);
      emitter.emit({
        eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE
      });
      GlobalData.instance().set(GlobalDataKeys.IS_SLIDE_SLIP_BACK, false);
    }

    BackGroundTaskUtil.cancelTask(); // 取消保活任务
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.FOREGROUND);
    AbilityStateHelper.getInstance().updateAbilityForeground(this.context, true);
    this.refreshConfig();
    this.refreshDarkMode();
    Log.debug(TAG, 'onForeground End Time = ' + Date.now());
  }

  onBackground() {
    Log.info(TAG, 'onBackground Begin Time = ' + Date.now());
    // Ability has back to background
    BackGroundTaskUtil.startTask(); // 开启保活任务
    AbilityStateHelper.getInstance().updateAbilityForeground(this.context, false);
    this.onDisplayOrientationInit();// 将窗口旋屏状态设置为跟随桌面
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.BACKGROUND);
  }

  unSubCallBack(err: BusinessError, data: Object) {
    if (err?.code) {
      Log.logErrorMsg(TAG, 'unsubscribe failed', err);
    } else {
      Log.log(TAG, 'unsubscribe success');
    }
  }

  /**
   * 发布事件
   */
  emitterEvent() {
    const innerEvent: emitter.InnerEvent = {
      eventId: CommonInnerEvent.EVENT_FORM,
      priority: emitter.EventPriority.HIGH
    };
    emitter.emit(innerEvent, {} as emitter.EventData);

    const innerEventTwo: emitter.InnerEvent = {
      eventId: CommonInnerEvent.EVENT_FORM_DETAIL,
      priority: emitter.EventPriority.HIGH
    };
    emitter.emit(innerEventTwo, {} as emitter.EventData);

    const parameters = GlobalThis.getInstance().abilityWant?.parameters;
    if (!parameters || parameters.params === '') {
      return;
    }
    // 通知各个页面关闭各种模态窗
    if (parameters.action === 'CLICK_MONTH_FORM_HEADER' || parameters.action === 'CLICK_AGENDA_DETAIL' ||
      parameters.action === 'JUMP_TO_VIEW_BY_AGENDA_PREVIEW') {
      emitter.emit({
        eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH
      })
    }
  }

  /**
   * 地区改变时，历法未选中时
   */
  onRegionChange() {
    if (!GlobalData.instance().get(GlobalDataKeys.IS_CHOOSE_SUBSCRIPTION_CALENDAR)) {
      const isChineseRegion: boolean = I18nUtil.isChineseRegion();
      GlobalData.instance().set(GlobalDataKeys.SUBSCRIPTION_CALENDAR,
        isChineseRegion ? SubscriptionCalendar.CHINESE_CALENDAR : SubscriptionCalendar.NO_CALENDAR);
    }
  }

  /**
   * 设置屏幕是否可以旋转
   * @param nowWindow 当前窗口
   * @param needAutoRotationWidth  判断用长度
   * @param windowWidth  窗口宽度
   * @param windowHeight  窗口高度
   */
  onDisplayOrientationChange(nowWindow: window.Window, isOpen: boolean, isInit: boolean = false) {

    //用于防止重复触发改变的逻辑
    if (!isInit && GlobalThis.getInstance().isAutoRotation === isOpen) {
      return;
    }
    GlobalThis.getInstance().isAutoRotation = isOpen;

    //设置窗口方向为跟随传感器自动旋转，受控制中心的旋转开关控制，且可旋转方向受系统判定/固定为竖屏模式
    let orientation = isOpen ? window.Orientation.AUTO_ROTATION_UNSPECIFIED : window.Orientation.PORTRAIT;
    try {
      nowWindow.setPreferredOrientation(orientation, (err) => {
        if (err?.code) {
          Log.error(TAG, `Failed to set window orientation. Cause: ${err?.code} : ${err?.message}`);
          return;
        }
        Log.info(TAG, 'Succeeded in setting window orientation.');
      });
    } catch (exception) {
      Log.error(TAG, `Failed to set window orientation. Cause: ${exception?.message}`);
    }
  }

  /**
   * 初始化屏幕到跟随桌面
   */
  onDisplayOrientationInit() {
    //设置为跟随桌面,用于折叠机展开后旋转后的跟随模式
    const orientation = window.Orientation.FOLLOW_DESKTOP;
    try {
      this.context.windowStage.getMainWindowSync().setPreferredOrientation(orientation, (err) => {
        if (err?.code) {
          Log.error(TAG, `Failed to set window orientation. Cause: ${err?.code} : ${err?.message}`);
          return;
        }
        Log.info(TAG, 'Succeeded in setting window orientation.');
      });
    } catch (exception) {
      Log.error(TAG, `Failed to set window orientation. Cause: ${exception?.message}`);
    }
  }

  /**
   * 用于跨端迁移的数据传递接口
   * @param wantParam
   * @returns
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    let version = wantParam.version;
    let targetDevice = wantParam.targetDevice;

    let nowNavPathLength = 0;
    const pathStack = NavPathManager.getInstance().getRouter(RouterName.ENTRY_HAP);
    if (pathStack) {
      nowNavPathLength = pathStack.size();
    }
    const nowTabIndex = AppStorage.get('tabIndex') as number;

    // 将要迁移的数据保存在wantParam的自定义字段（例如data）中
    const tabIndex = nowNavPathLength > 0 ? TabType.MONTH : nowTabIndex;
    const displayDate = GlobalData.instance().get(GlobalDataKeys.DISPLAY_DATE) as number;
    const continuePage: PageParam | undefined = AppContinueManager.getInstance().getContinuePage();
    Log.info(TAG,
      `onContinue Vs: ${version}, target: ${targetDevice} length ${nowNavPathLength},tab: ${tabIndex}`);

    wantParam['continueTabIndex'] = tabIndex; // 当前tab页,二级页面统一跳转月视图
    wantParam['continueDisplayDate'] = displayDate; // 当前展示日期
    wantParam[ContinueParam.continuePageName] = continuePage?.pageName || ''; // 接续页面
    wantParam['ohos.extra.param.key.supportContinuePageStack'] = false;
    if (continuePage?.pageName === NavPathName.AGENDA_DETAIL ||
      // 在这里不要REJECT, 在对端处理后自行决定是否接续，否则会弹默认拒绝Toast
      continuePage?.pageName === NavPathName.AGENDA_LIST) {
      Log.info(TAG, `onContinue inAgendaDetail`);
      wantParam[ContinueParam.continueEventUUID] = continuePage.event?.uuid || '';
      wantParam[ContinueParam.continueAccountSync] = CloudUtils.isCloudSyncOpened();
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  private handleInitialize() {
    InitializeHelper.getInstance().initModules();
  }

  private async initByDisplayId(currentDisplayId: number | undefined) {
    this.displayId = currentDisplayId;
    try {
      const foldScreenType: string = systemParameterEnhance.getSync('const.window.foldscreen.type', '0,0,0,0');
      Log.info(TAG, `foldScreenType = ${foldScreenType} nowDisplayId ${currentDisplayId}`);
      AppStorage.setOrCreate(GlobalDataKeys.FOLD_SCREEN_TYPE, foldScreenType);
    } catch (err) {
      Log.logErrorMsg(TAG, 'get const.window.foldscreen.type has error', err);
    }
    try {
      const allDisplays = await display.getAllDisplays();
      if (EmptyUtils.isUndefinedOrNull(currentDisplayId)) {
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.DEFAULT);
        return;
      }

      const currentDisplay = allDisplays.find(display => {
        return display.id === currentDisplayId;
      });
      if (currentDisplay && currentDisplay.name === 'SuperLauncher') {
        // 超级桌面总是处于默认状态
        AppStorage.setOrCreate(GlobalDataKeys.FOLD_SCREEN_TYPE, FoldScreenType.UNKNOWN);
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.DEFAULT);
      } else if (currentDisplay && currentDisplay.name === 'HiCar') {
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.HICAR);
      } else {
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.DEFAULT);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, `initByDisplayId failed, error code:${err.code}, error message:${err.message}.`);
    }
  }
}
