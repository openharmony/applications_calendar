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

import { Permissions } from '@ohos.abilityAccessCtrl';
import {
  AccountColor,
  AgendaTransitionUtil,
  behaviorEvents,
  checkIsPermissionsGranted,
  CommonInnerEvent,
  EmitterCollector,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  NavPageBuilderFactory,
  NavPathManager,
  NotificationTriggerHelper,
  PermissionState,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ServiceManager,
  TriggerSource,
  ViewProxy,
  CommonEventAction,
  registerSubscriber,
  unSubscriber,
  BroadcastHandler,
  ServiceEnum,
  ServiceGlobalEnv,
  ServiceEnvEvent,
  FeatureType,
  FoldScreenType,
  UnusualMode,
  ModeUtil,
  CompId,
  DateManager,
  NotificationHelper,
  AppContinueManager,
  NavPathName,
  CalendarDate,
  CalendarLayoutManager,
  GlobalEnvEnum,
  GlobalEnv,
  DeviceConfig,
  MIN_WINDOW_SHEET_BOTTOM,
  MIN_WINDOW_WIDTH_VP,
  PreferencesFiles,
  PreferencesUtil,
  StartOfWeekUtils,
  StatementStateKeys,
  SafeUtil
} from '@app/common';
import lazy { MainPage } from './MainPage';
import { EntryPageProxy } from './EntryPageProxy';
import { WindowManager } from '../pages/StatusBarManager';
import mediaquery from '@ohos.mediaquery';
import {
  ExportVcsCallBack,
  ImportData,
  ImportExportService,
  ImportPage,
  ImportType,
  PlaceholderComponent,
  SimpleAccount
} from '@app/feature.importexport';
import emitter from '@ohos.events.emitter';
import { requestPermissionsFromUser } from '@app/common/src/main/ets/util/PermissionUtil';
import common from '@ohos.app.ability.common';
import { NetWorkManger } from '@app/service.network/src/main/ets/impl/NetWorkManger';
import { HiEventParamsConfirm } from '@app/common/src/main/ets/default/util/ReportUtil';
import { display } from '@kit.ArkUI';
import lazy { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { commonEventManager, settings } from '@kit.BasicServicesKit';
import { JSON } from '@kit.ArkTS';
import { SettingStore } from '@app/feature.settings';
import { accessibility } from '@kit.AccessibilityKit';

const TAG: string = 'EntryPage';
let storage = LocalStorage.getShared();
const ACCESSIBILITY_SCREENREADER_ENABLED = 'accessibility_screenreader_enabled';
// 一周开始日是否写入过setting data
const IS_SET_SETTINGS_DATA_START_OF_WEEK = 'is_set_settings_data_start_of_week';

const DEFAULT_WEEK_START_DAY: number = -1;

/**
 *
 * @since 2022-03-01
 */
@Entry(storage)
@Component
struct EntryPage {
  @Provide navPathStack: NavPathStack = new NavPathStack();

  @Provide agendaTransitionUtil: AgendaTransitionUtil = new AgendaTransitionUtil();

  viewProxy: ViewProxy = new EntryPageProxy(TAG);

  @State isPermissionGranted: boolean | null = null;

  @State isShowImportPage: boolean = false;

  @State importData: ImportData | undefined = undefined;

  @Provide hideNavBarFlag: boolean = false;

  listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(dark-mode: true)');

  private importType: ImportType = ImportType.ACCOUNT_IMPORT;

  @State sheetHeight: number = 333;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  //是否支持指导页显示
  private readonly isSupportGuidePage: boolean = DeviceConfig.instance().isSupport(FeatureType.GUIDE_PAGE);

  private checkedAccId: number | undefined = 0;

  private accountColor: number | undefined = AccountColor.RED;

  // 应用是否拉入后台
  private isHidePage: boolean = false;

  private subscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;

  private checkPrivacyTimeout: number = -1;

  // 隐私协议变更是否检查完成
  @State @Watch('requestNoticeDialog') isPrivChecked: boolean = false;

  // 是否是HiCar模式
  @StorageProp('unusualMode') @Watch('unusualModeOnChange') unusualMode: UnusualMode | undefined =
    AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  private unusualModeOnChange() {
    const isSmallUp = ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode);
    if (isSmallUp) {
      this.initHiCarMainPageLoader().then(() => {
        this.isHiCarMode = isSmallUp;
      });
    } else {
      this.isHiCarMode = isSmallUp;
    }

    // 内外屏接续逻辑
    this.navPathStack.getAllPathName();
    let pathNames = this.navPathStack.getAllPathName();
    if (pathNames.length !== 0) {
      let topPathName = pathNames[pathNames.length - 1]
      // 如果是栈顶是AGENDA_DETAIL或AGENDA_LIST则不进行清空
      if (topPathName !== NavPathName.AGENDA_DETAIL && topPathName !== NavPathName.AGENDA_LIST) {
        this.navPathStack.clear();
      }
    }

    // 小屏在模态日程详情时需要做跳转操作
    const needAgendaDetail = this.agendaTransitionUtil.isEditPageShow || this.agendaTransitionUtil.modeChange;
    if (isSmallUp && needAgendaDetail) {
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.AGENDA_DETAIL,
        routerName: RouterName.ENTRY_HAP,
        param: this.agendaTransitionUtil.param,
        animated: false
      });
    }
    this.agendaTransitionUtil.clearAniEnd();
    this.agendaTransitionUtil.modeChange = false;
    this.agendaTransitionUtil.isEditPageShow = false;
  }

  @BuilderParam hiCarMainPageLoader: () => void = this.initItemFunc;
  private initHiCarMainPageLoader: () => Promise<void> = async () => {
    Log.info(TAG, `initHiCarMainPageLoader start`);
    let pageObj = await import('./HiCarMainPage');
    this.hiCarMainPageLoader = pageObj.hiCarMainPageLoader;
    Log.info(TAG, `initHiCarMainPageLoader end`);
  }

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private vcsShowPageHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
  };

  private vcsAccountChangeHandler: (data: emitter.EventData) => void = (data: emitter.EventData): void => {
  };

  private vcsShareAccountHandler: (eventData?: emitter.EventData) => void = async (eventData?: emitter.EventData): Promise<void> => {
  };

  // 是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 窗口宽度
  @LocalStorageLink('windowWidth') windowWidth: number = 0;

  @State isHiCarMode: boolean = ModeUtil.isHiCarOrSmallUpDownFoldMode(this.unusualMode);

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  /**
   * 窗口尺寸判断
   */
  getOffsetHeight(): number {
    // 底部显示
    if (this.windowWidth < MIN_WINDOW_SHEET_BOTTOM) {
      return this.windowAvoidAreaNavigationRectHeight;
    }
    return 0;
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  @Builder
  initItemFunc() {
  };
  build() {
    Navigation(this.navPathStack) {
      // 开源版本直接显示主页面
      if (this.isHiCarMode) {
        this.hiCarMainPageLoader();
      } else {
        this.buildMainPage();
      }
      // 新增全屏的黑色蒙板
      if (this.agendaTransitionUtil.isMaskEnabled) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .opacity(this.agendaTransitionUtil.maskAlpha)
          .enabled(false)
          .focusable(false)
          .zIndex(999)
          .position({ x: 0, y: 0 })
      }
      PlaceholderComponent().width(0).height(0).visibility(Visibility.Hidden)
    }
    .id(CompId.ENTRY_PAGE_NAVIGATION)
    .bindSheet($$this.isShowImportPage, this.buildPage(), {
      height: this.sheetHeight,
      detents: [this.sheetHeight, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.CENTER,
      backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
      maskColor: $r('sys.color.ohos_id_color_mask_thin'),
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
      onAppear: () => {
        Log.debug(TAG, 'BindSheet onAppear.');
      },
      onDisappear: () => {
        Log.debug(TAG, 'BindSheet onDisappear.');
      }
    })
    .hideTitleBar(true)
    // 设置为true，隐藏路由，侧滑返回逻辑返回桌面，设置为false，开启路由，侧滑返回逻辑返回到上级
    .hideNavBar(this.hideNavBarFlag)
    .mode(NavigationMode.Stack)
    .navDestination(this.navRoute)
    .titleMode(NavigationTitleMode.Mini)
    .onAreaChange(() => {
      this.initByFoldScreenType();
    })
  }

  @Builder
  buildPage() {
    Column() {
      ImportPage({
        importData: this.importData,
        isShowImportPage: this.isShowImportPage,
        checkedAccId: this.checkedAccId,
        accountColor: this.accountColor
      });
    }
    .height('100%')
  }

  @Builder
  buildMainPage() {
    MainPage();
  }

  choseSheetHeight() {
    switch (this.importType) {
      case ImportType.ACCOUNT_IMPORT:
        if (!this.inSmallWindow) {
          this.sheetHeight = 500
        } else {
          if (this.importData && this.importData?.mEventsCount >= 3) {
            this.sheetHeight = 642;
          } else if (this.importData && this.importData?.mEventsCount === 2) {
            this.sheetHeight = 558;
          } else if (this.importData && this.importData?.mEventsCount === 1) {
            this.sheetHeight = 474;
          } else {
            this.sheetHeight = 516;
          }
        }
        break;
      case ImportType.EVENTS_IMPORT:
        if (!this.inSmallWindow) {
          this.sheetHeight = 500
        } else {
          if (this.importData && this.importData?.mEventsCount >= 3) {
            this.sheetHeight = 524;
          } else {
            this.sheetHeight = 439;
          }
        }
        break;
      default:
        this.sheetHeight = (this.inSmallWindow ? 327 : 500) + this.getOffsetHeight();
        break;
    }
    Log.info(TAG, `choseSheetHeight sheetHeight: ${this.sheetHeight}`);
  }

  private listenerHandler: (mediaQueryResult: mediaquery.MediaQueryResult) => void =
    (mediaQueryResult: mediaquery.MediaQueryResult) => {
      this.onDarkMode(mediaQueryResult)
    };

  /**
   * aboutToAppear 会在 build之前执行,但是aboutToAppear里的异步方法并不会阻塞
   */
  async aboutToAppear() {
    this.listener.on('change', this.listenerHandler);

    NavPathManager.getInstance().createRouter(RouterName.ENTRY_HAP, this.navPathStack);

    // 维测用,用于判断是否创建了两个不同的页面
   // const uniqueId = this.getUniqueId();
   // Log.info(TAG, `aboutToAppear check ${uniqueId}`);

    this.viewProxy.aboutToAppear();
    this.requestPermissionsMaybe();
    // 开源版本默认同意隐私协议，启用接续
    this.isPermissionGranted = true;
    AppContinueManager.getInstance().setAppContinueState(true, getContext() as common.UIAbilityContext);
    NetWorkManger.getInstance().updateUserNetWorkState(PermissionState.CONFIRMED);
    await this.emitterFrom();
    this.initByFoldScreenType();
    if (this.unusualMode === UnusualMode.HICAR || this.unusualMode === UnusualMode.SMALL_UP_DOWN_FOLD) {
      await this.initHiCarMainPageLoader();
    }
    ServiceGlobalEnv.onEnvChange(ServiceEnvEvent.MAIN_WINDOW_SHOWN);
    this.registerSubscriber();

    this.setStartOfWeek();
    this.refreshSettingSpCache();
    accessibility.on('accessibilityStateChange', this.queryAccessibilityScreenReaderEnabled);
  }

  /**
   * 检查隐私协议是否变更
   */
  async checkPrivacyVersionChange() {
    // 开源版本无需检查隐私协议变更
    this.isPrivChecked = true;
  }

  private refreshSettingSpCache() {
      try {
        const removeSettingCacheResult = PreferencesUtil.removePreferencesFromCacheSync(PreferencesFiles.SETTINGS);
        Log.info(TAG, `remove setting sp cache result:${removeSettingCacheResult}`);
        SettingStore.INSTANCE.reInit();
      } catch (err) {
        Log.logErrorMsg(TAG, 'refreshSettingSpCache', err);
      }
  }

  private async registerSubscriber() {
    const event = CommonEventAction.MIGRATE_START;
    const publisherBundleName = GlobalThis.getInstance().getBundleInfoSync()?.name ?? '';
    let dateSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [event],
      publisherBundleName: publisherBundleName
    };
    const broadcastHandler: BroadcastHandler = {
      handleError: (error: ESObject): void => {
        Log.logErrorMsg(TAG, `registerSubscriber`, error);
      },
      handleEventData: (eventData: commonEventManager.CommonEventData): void => {
        Log.info(TAG, `handleEventData receiver MIGRATE_START event`);
        this.refreshSettingSpCache();
      },
      enableHandleEvent: (eventData: commonEventManager.CommonEventData): boolean => {
        return event === eventData.event;
      }
    }
    const registerSubscriberResult = await registerSubscriber(dateSubscribeInfo, broadcastHandler);
    if (!registerSubscriberResult.isSuccess()) {
      Log.error(TAG, `registerSubscriber fail ${registerSubscriberResult.toString()}`);
    } else {
      Log.info(TAG, `registerSubscriber success`);
      this.subscriber = registerSubscriberResult.data!;
    }
  }

  async emitterFrom() {
    this.emitterShowPage();
    this.emitterAccountChange();
    this.emitterShareAccount();
  }

  emitterShowPage(): void {
    this.vcsShowPageHandler = (eventData?: emitter.EventData): void => {
      if (eventData?.data?.data) {
        this.importData = JSON.parse(eventData?.data?.data) as ImportData;
        this.importType = this.importData.importType;
      } else {
        Log.error(TAG, 'ImportPage ')
      }
      this.choseSheetHeight();
      // 日历分享给日程给日历，分享面板关闭会影响导入界面不显示
      SafeUtil.setTimeout(() => {
        this.isShowImportPage = true;
      }, 200);
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_SHOW_PAGE }, this.vcsShowPageHandler);
  }

  emitterAccountChange(): void {
    this.vcsAccountChangeHandler = (data: emitter.EventData): void => {
      this.checkedAccId = data?.data?.checkedAccId;
      this.accountColor = data?.data?.accountColor;
      this.isShowImportPage = true;
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_ACCOUNT_CHANGE }, this.vcsAccountChangeHandler);
  }

  emitterShareAccount(): void {
    this.vcsShareAccountHandler = async (eventData?: emitter.EventData): Promise<void> => {
      if (eventData?.data?.accountId) {
        let service = await ServiceManager.getInstance()
          .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
        service?.exportVcsByCalendarAccount(new SimpleAccount(eventData.data.accountId as number,
          eventData.data.calendarDisplayName as string,
          eventData.data.calendarColor as number), new ExportVcsCallBack());
      } else {
        Log.error(TAG, 'exportAccount not accountId ');
      }
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.VCS_SHARE_ACCOUNT }, this.vcsShareAccountHandler);
  }

  onDarkMode(mediaQueryResult: mediaquery.MediaQueryResult) {
    WindowManager.getInstance().setSystemBarProperties(mediaQueryResult.matches);
    if (GlobalData.instance().get(GlobalDataKeys.IS_DARKMODE) !== mediaQueryResult.matches) {
      let params: ReportHiEventParams = {
        IS_DARK_MODE: mediaQueryResult.matches ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE,
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.darkMode, params);
    }

    Log.info(TAG, `is dark mode: ${mediaQueryResult.matches}`);
    AppStorage.setOrCreate(GlobalDataKeys.IS_DARKMODE, mediaQueryResult.matches);
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    clearTimeout(this.checkPrivacyTimeout);
    NavPathManager.getInstance().discard(RouterName.ENTRY_HAP);
    if (this.subscriber) {
      unSubscriber(this.subscriber);
    }
    this.emitterCollector.off();
    this.requestNoticePermissionController = null;
    const context = GlobalThis.getInstance().context;
    if (!context) {
      return;
    }
    try {
      settings.unregisterKeyObserver(context, ACCESSIBILITY_SCREENREADER_ENABLED, settings.domainName.DEVICE_SHARED);
    } catch (e) {
      Log.logErrorMsg(TAG, 'settings.unregisterKeyObserver', e)
    }
    this.listener.off('change', this.listenerHandler);
    accessibility.off('accessibilityStateChange', this.queryAccessibilityScreenReaderEnabled);
  }

  onPageHide() {
    this.viewProxy.onPageHide();
    this.isHidePage = true;
    DateManager.getInstance().updateCurrentDate(new CalendarDate());
  }

  onPageShow() {
    this.viewProxy.onPageShow();
    this.pageShowGetData();
    this.queryAccessibilityScreenReaderEnabled();
    this.queryNotificationGranted();
    this.changeWindowVpSize();
    this.initByFoldScreenType();
  }

  // 因当前无监听显示大小变更的方法,故在onPageShow时添加方法用于更新当前显示大小变更
  changeWindowVpSize() {
    // 显示大小变更不会改变px值
    const widthPx = storage.get<number>(GlobalDataKeys.WINDOW_WIDTH_IN_PX) ?? 0;
    const heightPx = storage.get<number>(GlobalDataKeys.WINDOW_HEIGHT_IN_PX) ?? 0;
    // 显示大小改变px2vp的比例,因此需要重新计算当前窗口大小vp值
    const width = Math.round(px2vp(widthPx));
    const height = Math.round(px2vp(heightPx));
    storage.setOrCreate('windowWidth', width);
    storage.setOrCreate('windowHeight', height);
    AppStorage.setOrCreate('windowWidth', width);
    AppStorage.setOrCreate('windowHeight', height);

    GlobalEnv.setOrCreate(GlobalEnvEnum.WINDOW_SIZE, {
      width: width, height: height
    });
  }

  private queryAccessibilityScreenReaderEnabled() {
    const context: Context =  getContext(this);
    if (!context) {
      Log.warn(TAG, 'queryAccessibilityScreenReaderEnabled context is null.');
      return;
    }
    settings.getValue(context, ACCESSIBILITY_SCREENREADER_ENABLED, settings.domainName.DEVICE_SHARED).then((value) => {
      Log.info(TAG, `accessibility_screenreader_enabled: ${value}`);
      GlobalData.instance().set(GlobalDataKeys.IS_OPEN_ACCESSIBILITY_SCREEN_READER, value === '1');
    });
  }

  private queryNotificationGranted() {
    NotificationHelper.getInstance().queryNotificationGranted().then((data) => {
      GlobalData.instance().set(GlobalDataKeys.IS_NOTIFICATION_GRANTED, data);
    })
  }

  onBackPress(): boolean {
    return this.viewProxy.onBackPressed();
  }

  // 页面重新拉起时发送数据变更广播重新刷新视图
  pageShowGetData() {
    if (!this.isHidePage) {
      return;
    }

    const params: Record<string, number | boolean | string> = {};
    params['isFromSync'] = false;
    params['moduleName'] = '';
    params['operation'] = 'unknown';
    params['table'] = 'Calendars';
    params['isEmitFromEntryPage'] = true; // 是否从EntryPage手动触发
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, { data: params });

    // 应用后台跨天时热起需要更新选中日期
    if (DateManager.getInstance().isCurDateNeedRefresh()) {
      Log.log(TAG, 'hidePage update displayDate');
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, Date.now());
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    }
  }

  /**
   * 条件成立下请求日历权限
   * 日历已经预授权calendardate的读写权限,而且配置的是不能在setting中关闭
   * 删除hap包后再安装,这个权限需要api动态申请,目前使用这个api申请权限
   * 1 即使拒绝,也可以访问calendardate
   * 2 权限框弹出一次,并且用户确认或拒绝后,再调用不会再弹出权限框,没有类似双框架的不再询问操作。
   */
  private requestPermissionsMaybe() {
    const permissions: Permissions[] = ['ohos.permission.READ_WHOLE_CALENDAR', 'ohos.permission.WRITE_WHOLE_CALENDAR'];
    checkIsPermissionsGranted(permissions)
      .then((isAllPerGranted: boolean): Promise<boolean> => {
        if (!isAllPerGranted) {
          Log.warn(TAG, `checkIsPermissionsGranted isAllPerGranted false`);
          return this.requestPermissionsFromUser();
        }
        return new Promise((resolve) => {
          resolve(true)
        });
      })
      .catch((err: Error): Promise<boolean> => {
        Log.logErrorMsg(TAG, `queryPermissionsState`, err);
        return this.requestPermissionsFromUser();
      })
      .then((finalResult: boolean | void) => {
        Log.info(TAG, `requestPermissionsFromUser finalResult is ${finalResult}`);
      })
      .catch((err: Error) => {
        Log.logErrorMsg(TAG, `requestPermissionsFromUser`, err);
      });
  }

  /**
   * 请求日历权限弹窗
   */
  private async requestPermissionsFromUser(): Promise<boolean> {
    const context = GlobalThis.getInstance().context;
    if (!context) {
      Log.warn(TAG, `requestPermissionsFromUser context is null`);
      return false;
    }
    const permissions: Permissions[] = ['ohos.permission.READ_WHOLE_CALENDAR', 'ohos.permission.WRITE_WHOLE_CALENDAR'];
    return requestPermissionsFromUser(permissions, context);
  }

  private async queryPermissionState() {
    // 开源版本默认已同意隐私协议
    this.isPermissionGranted = true;
    this.requestNoticeDialog();
  }

  /**
   * 请求通知弹框
   */
  private async requestNoticeDialog() {
    if (this.isPermissionGranted && this.isPrivChecked) {
      let notificationTriggerHelper = NotificationTriggerHelper.getInstance();
      notificationTriggerHelper.requestNotification(TriggerSource.BROWSE_APP,
        (notificationGranted: boolean) => {
          if (!notificationGranted && notificationTriggerHelper.isAboutToOpenDialog()) {
            this.requestNoticePermissionController?.open();
          }
        });
    }
  }

  // 跳转设置开启通知权限弹框
  private requestNoticePermissionController: CustomDialogController | null = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.label_permission_notification_title'),
      contentBuilder: () => {
        this.buildNoticeContent($r('app.string.label_permission_notification_description'));
      },
      buttons: [{
        value: $r('app.string.cancel'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          Log.info(TAG, `The user cancels the operation permission setting.`);
        }
      },
        {
          value: $r('app.string.go_to_setting'), buttonStyle: ButtonStyleMode.TEXTUAL, action: () => {
          this.redirectSettings();
        }
        }],
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    cornerRadius: '32vp',
    customStyle: false
  })

  @Builder
  buildNoticeContent(context: ResourceStr): void {
    Column() {
      Text(context)
    }
  }

  private redirectSettings() {
    let context = getContext(this) as common.UIAbilityContext;
    let want: Want = {
      bundleName: 'com.openharmony.settings',
      abilityName: 'com.openharmony.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: 'com.openharmony.calendar'
      }
    };
    context.startAbility(want).then(() => {
      Log.info(TAG, 'startAbility Successfully pulled up');
    }).catch((err: Error) => {
      Log.error(TAG, `Failed to startAbility. error: ${err.message}`);
    });
  }

  private async initByFoldScreenType() {
    if (AppStorage.get(GlobalDataKeys.UNUSUAL_MODE) === UnusualMode.HICAR ||
      AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE) === FoldScreenType.UNKNOWN) {
      return;
    }
    try {
      const foldStatus = display.getFoldStatus();
      Log.info(TAG, `current fold status = ${foldStatus}`);
      if (foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED &&
        AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE) === FoldScreenType.SMALL_UP_DOWN_FOLD) {
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.SMALL_UP_DOWN_FOLD);
      } else {
        AppStorage.setOrCreate(GlobalDataKeys.UNUSUAL_MODE, UnusualMode.DEFAULT);
      }

      CalendarLayoutManager.getInstance().changeLayout();
    } catch (err) {
      Log.logErrorMsg(TAG, `initByFoldScreenType failed, error code:${err.code}, error message:${err.message}.`);
    }
  }

  private async setStartOfWeek() {
    try {
      const startOfWeek = (GlobalData.instance().get(GlobalDataKeys.START_OF_WEEK) || DEFAULT_WEEK_START_DAY) as number;
      const isSetSettingDataStartOfWeek: boolean =
        await PreferencesUtil.getBooleanValue(PreferencesFiles.SETTINGS, IS_SET_SETTINGS_DATA_START_OF_WEEK, false);
      Log.info(TAG, `setStartOfWeek isSetSettingDataStartOfWeek: ${isSetSettingDataStartOfWeek} startOfWeek:${startOfWeek}`);
      if (isSetSettingDataStartOfWeek) {
        return;
      }
      StartOfWeekUtils.setSettingsStartOfWeek(startOfWeek);
      PreferencesUtil.putBooleanValueSync(PreferencesFiles.SETTINGS, IS_SET_SETTINGS_DATA_START_OF_WEEK, true);
    } catch (err) {
      Log.logErrorMsg(TAG, 'setStartOfWeek', err);
    }
  }
}

