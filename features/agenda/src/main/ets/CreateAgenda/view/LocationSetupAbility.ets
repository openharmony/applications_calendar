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
  AgendaUtil,
  GlobalDataKeys,
  GlobalThis,
  BigFontSize,
  FontSizeScaleUtils,
  Log,
  PreferencesUtil,
  ThrottleFunction,
  maskString,
  SafeUtil
} from '@app/common';
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';
import { BusinessError } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { NEWLINE_SYMBOL } from '@app/common/src/main/ets/agenda/AgendaUtil';
import { NetConnectionUtil, NetState } from '@app/service.network';
import { GcmUtil } from '@app/common/src/main/ets/util/GcmUtil';
import { sendAccessibilityEvent } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'LocationSetupAbility';

const LOCATION_PERMISSIONS: Permissions[] = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];

export const RECENT_LOCATION: string = 'recent_location';

@Component
export struct LocationSetupAbility {

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageLink('themeColor') themeColor: string = '';

  // 深色模式
  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @StorageLink('language') @Watch('onLanguageChanges') language: string = '';

  @Link isLocationAbility: boolean;

  @Link mLocation: string;

  @Link mLatitude: number;

  @Link mLongitude: number;

  @State isSearchLocation: string = '';

  @State locationSearchList: LocationSearchResult[] = [];

  @State locationRecentList: LocationInfo[] = [];

  @State isLocatingCurrent: boolean = false;

  @State xMirror: boolean = false; // x镜像

  private isNet: boolean = false;

  private isFirstLoad: boolean = true;

  private currentLocation: string = '';

  private currentLatitude: number = -1;

  private currentLongitude: number = -1;

  // 搜索控制器
  private controller: SearchController = new SearchController();

  onLanguageChanges() {
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
  }

  aboutToAppear() {
    this.xMirror = i18n.isRTL(i18n.getSystemLocale());
    NetConnectionUtil.subscribe(TAG, (netState: NetState) => {
      if (netState == NetState.NET_AVAILABLE) {
        this.isNet = true;
      } else {
        this.isNet = false;
      }
      Log.info(TAG, 'aboutToAppear isNet = ' + this.isNet);
    });
    this.isSearchLocation = this.mLocation;
    this.loadRecentLocationList();
  }

  private async loadRecentLocationList() {
    const allLocationInfoResult = PreferencesUtil.getAllValueSync(RECENT_LOCATION);
    const allLocationInfoObject = allLocationInfoResult.data;
    if (allLocationInfoObject !== null && allLocationInfoObject !== undefined) {
      const keys = Object.keys(allLocationInfoObject);
      for (let key of keys) {
        let locationInfoValue = PreferencesUtil.getStringValueSync(RECENT_LOCATION, key, '');
        if (locationInfoValue === null || locationInfoValue === undefined) {
          continue;
        }
        try {
          let locationInfo: LocationInfo = JSON.parse(locationInfoValue);
          if (locationInfo.latitudeStr && locationInfo.latitudeStr.length > 0) {
            locationInfo.latitude = await this.decryptAndParseNumber(locationInfo.latitudeStr);
          }
          if (locationInfo.longitudeStr && locationInfo.longitudeStr.length > 0) {
            locationInfo.longitude = await this.decryptAndParseNumber(locationInfo.longitudeStr);
          }
          this.locationRecentList.push(locationInfo);
        } catch (error) {
          Log.logErrorMsg(TAG, `locationInfo parse error`, error);
        }
      }
    }
  }

  private async decryptAndParseNumber(cipherText: string): Promise<number> {
    const invalidLocation: number = -1;
    try {
      const plainText = await GcmUtil.decryptString(GcmUtil.KEY_ALIAS_LOCATION, cipherText);
      let locationNum: number = Number(plainText);
      return isNaN(locationNum) ? invalidLocation : locationNum;
    } catch (err) {
      Log.logErrorMsg(TAG, 'decryptAndParseNumber', err);
    }
    return invalidLocation;
  }

  build() {
    NavDestination() {
      this.buildSearchView();
      //输入结果显示区域
      this.buildSearchResultView();
      //当前位置区域
      this.buildLocalButton();
      this.buildLocationPrompt();
      this.buildLocationList();
      this.buildRecentLocationList();
    }
    .padding({
      top: $r('sys.float.padding_level4'),
      bottom: this.windowAvoidAreaNavigationRectHeight
    })
    .backgroundColor(Color.Transparent)
    .hideTitleBar(false)
  }

  @Builder
  buildSearchView() {
    //搜索框
    Row() {
      this.buildBackTrackButton();
      Stack({ alignContent: Alignment.End }) {
        Search({
          value: this.isSearchLocation,
          placeholder: GlobalThis.getResourceStr($r('app.string.calendar_search_location_hint'),
            i18n.System.getSystemLanguage()),
          controller: this.controller
        })
          .backgroundColor($r('sys.color.comp_background_tertiary'))
          .placeholderColor($r('sys.color.font_secondary'))
          .selectedBackgroundColor(this.themeColor)
          .textFont({ size: $r('sys.float.Body_L') })
          .placeholderFont({
            size: FontSizeScaleUtils.getLimitFontSizeVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 16)
          , family: 'serif', style: FontStyle.Normal
          })
          .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 16))
          .minFontSize('16vp')
          .enableKeyboardOnFocus(true)
          .caretStyle({
            color: this.themeColor
          })
          .onChange(async (value: string) => {
            this.isSearchLocation = value;
            ThrottleFunction.instance().debounce(TAG, async () => {
              this.searchChange();
            }, 300)
            Log.info(TAG, 'Search onChange value = ' + maskString(value));
          })
          .id('search_location')
          .onAppear(() => {
            SafeUtil.setTimeout(() => {
              focusControl.requestFocus('search_location');
              sendAccessibilityEvent('__SearchField__search_location');
            }, 50);
          })
      }
      .padding({
        left: this.xMirror ? 16 : $r('sys.float.padding_level4'),
        right: this.xMirror ? $r('sys.float.padding_level4') : 16
      })
      .layoutWeight(1)
    }
    .height(FontSizeScaleUtils.getLimitHeightVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 56))
  }

  @Builder
  buildBackTrackButton() {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .focusable(true)
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
    }
    .focusable(true)
    .height(40)
    .width(40)
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick(() => {
      this.isLocationAbility = false;
    })
    .margin({ left : this.xMirror ? 0 : 16, right :  this.xMirror ? 16 : 0 })
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')))
  }

  @Builder
  buildSearchResultView() {
    Row() {
      SymbolGlyph($r('sys.symbol.local'))
        .fontWeight(FontWeight.Normal)
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .align(Alignment.Center)

      Text(AgendaUtil.getLocation(this.isSearchLocation))
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)
        .fontWeight(FontWeight.Normal)
        .padding({ left : this.xMirror ? 0 : 16, right :  this.xMirror ? 16 : 0 })
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
    }
    .padding({ left: this.xMirror ? 32 : 16, right: this.xMirror ? 16 : 32 })
    .width('100%')
    .onClick(()=>{
      this.mLocation = this.isSearchLocation;
      this.mLatitude = -1;
      this.mLongitude = -1;
      this.isLocationAbility = false;
    })
    .margin({ top: 20 })
    .visibility(this.isLocationVisibility() ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildLocalButton() {
    Row() {
      Image($r('app.media.ic_current_location'))
        .width(24)
        .height(24)
        .margin({ left : this.xMirror ? 0 : 16, right :  this.xMirror ? 16 : 0 })
        .objectFit(ImageFit.Contain)
        .fillColor($r('sys.color.icon_primary'))

      Text(this.isLocatingCurrent ?
        GlobalThis.getResourceStr($r('app.string.calendar_current_map_position'), i18n.System.getSystemLanguage()) :
        GlobalThis.getResourceStr($r('app.string.calendar_current_position'), i18n.System.getSystemLanguage()))
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Normal)
        .margin({ left : this.xMirror ? 0 : 16, right :  this.xMirror ? 16 : 0 })
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
    }
    .onClick(async () => {
      this.locationClick();
    })
    .height(FontSizeScaleUtils.getLimitHeightVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 56))
    .width('100%')
    .padding({ top: 20 })
  }

  @Builder
  buildLocationPrompt() {
    Row() {
      Text((this.locationSearchList.length === 0 && this.locationRecentList.length !== 0) ?
        GlobalThis.getResourceStr($r('app.string.calendar_recent_location'), i18n.System.getSystemLanguage()) :
        GlobalThis.getResourceStr($r('app.string.calendar_more_location'), i18n.System.getSystemLanguage()))
        .fontColor($r('sys.color.font_tertiary'))
        .fontWeight(FontWeight.Normal)
        .textAlign(TextAlign.Start)
        .padding({ left: this.xMirror ? 0 : 16, right: this.xMirror ? 16 : 0, bottom: 8 })
        .height(FontSizeScaleUtils.getLimitHeightVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 56))
        .baselineOffset(-20)
        .layoutWeight(1)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)

      Text(GlobalThis.getResourceStr($r('app.string.location_clear'), i18n.System.getSystemLanguage()))
        .fontColor(this.themeColor)
        .fontWeight(FontWeight.Normal)
        .textAlign(TextAlign.End)
        .padding({ bottom: 8 })
        .margin({ left : this.xMirror ? 16 : 0, right :  this.xMirror ? 0 : 16 })
        .height(FontSizeScaleUtils.getLimitHeightVp(this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL, 56))
        .baselineOffset(-20)
        .visibility(this.locationSearchList.length === 0 && this.locationRecentList.length !== 0 ?
          Visibility.Visible : Visibility.None)
        .layoutWeight(1)
        .onClick(() => {
          PreferencesUtil.clearValueSync(RECENT_LOCATION);
          this.locationRecentList = [];
        })
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
    }
    .visibility(this.locationSearchList.length === 0 && this.locationRecentList.length === 0 ?
      Visibility.None : Visibility.Visible)
    .width('100%')
  }

  @Builder
  buildLocationList() {
    List({ space: 5 }) {
      ForEach(this.locationSearchList, (data: LocationSearchResult, index: number) => {
        ListItem() {
          Column() {
            this.todoLocationSearchItem(data);
          }
          .constraintSize({ minHeight:  64})
        }
        .clip(false)
        .onClick(async () => {
          this.mLocation = data.name + NEWLINE_SYMBOL + data.formatAddress;
          this.mLongitude = data.longitude;
          this.mLatitude = data.latitude;
          this.isLocationAbility = false;
        })
      }, (item: LocationSearchResult, index: number) => item.name + index)
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .divider({
      strokeWidth: '1px',
      startMargin: 58,
      color: $r('sys.color.ohos_id_color_list_separator')
    })
    .padding({bottom : 16, left : this.xMirror ? 16 : 0, right :  this.xMirror ? 0 : 16})
    .visibility(this.locationSearchList.length === 0 ? Visibility.None : Visibility.Visible)
  }

  @Builder
  buildRecentLocationList() {
    List({ space: 5 }) {
      ForEach(this.locationRecentList, (locationInfo: LocationInfo, index: number) => {
        ListItem() {
          Column() {
            this.todoLocationRecentItem(locationInfo.location as string);
          }
          .constraintSize({ minHeight:  64})
        }
        .clip(false)
        .onClick(async () => {
            this.mLocation = locationInfo.location as string;
            this.mLongitude = locationInfo.longitude as number;
            this.mLatitude = locationInfo.latitude as number;
            this.isLocationAbility = false;
        })
      }, (item: LocationInfo, index: number) => item.location ?? '' + index)
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .listDirection(Axis.Vertical)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .divider({
      strokeWidth: '1px',
      startMargin: 58,
      color: $r('sys.color.ohos_id_color_list_separator')
    })
    .padding({bottom : 16, left : this.xMirror ? 16 : 0, right :  this.xMirror ? 0 : 16})
    .visibility(this.locationSearchList.length !== 0 ? Visibility.None : Visibility.Visible)
  }

  @Builder
  todoLocationRecentItem(locationInfo: string) {
    Row() {
      SymbolGlyph($r('sys.symbol.local'))
        .fontWeight(FontWeight.Normal)
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .margin({ right: 16, left : 16 })
        .align(Alignment.Center)

      Column({ space: 5 }) {
        Text(AgendaUtil.getLocation(locationInfo))
          .textAlign(TextAlign.Start)
          .align(Alignment.Center)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ right: this.xMirror ? 0 : 56, left: this.xMirror ? 56 : 0 })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)

        Text(AgendaUtil.getFormatLocation(locationInfo))
          .textAlign(TextAlign.Start)
          .align(Alignment.Center)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ right: this.xMirror ? 0 : 56, left: this.xMirror ? 56 : 0 })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
    }
    .constraintSize({ minHeight: 64 })
  }

  @Builder
  todoLocationSearchItem(data: LocationSearchResult) {
    Row() {
      SymbolGlyph($r('sys.symbol.local'))
        .fontWeight(FontWeight.Normal)
        .fontSize($r('sys.float.ohos_id_text_size_headline7'))
        .fontColor([$r('sys.color.ohos_id_color_primary')])
        .margin({ right: 16, left : 16 })
        .align(Alignment.Center)

      Column({ space: 5 }) {
        Text(data.name)
          .textAlign(TextAlign.Start)
          .align(Alignment.Center)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ right: this.xMirror ? 0 : 56, left: this.xMirror ? 56 : 0 })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)

        Text(data.formatAddress)
          .textAlign(TextAlign.Start)
          .align(Alignment.Center)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(FontWeight.Normal)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ right: this.xMirror ? 0 : 56, left: this.xMirror ? 56 : 0 })
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)
    }
    .constraintSize({ minHeight: 64 })
  }

  private isLocationVisibility(): boolean {
    if (this.isSearchLocation === '') {
      return false;
    }
    return true;
  }

  //搜索
  async searchChange() {
    const permissions: boolean = await this.checkFencePermissions();
    Log.info(TAG, 'searchChange location permissions = ' + permissions);
    if (!permissions) {
      return
    }
    if (this.isSearchLocation !== '') {
      this.locationSearchList = await this.queryAddrByLocationName(this.isSearchLocation);
    } else {
      this.locationSearchList = [];
    }
  }

  /**
   * 根据location名称查询位置信息（使用LocationKit替代MapKit的site API）
   * @param locationName location名称
   * @returns 当前查询位置集合
   */
  private async queryAddrByLocationName(locationName: string): Promise<LocationSearchResult[]> {
    let queryRequest: geoLocationManager.GeoCodeRequest = {
      description: locationName,
      maxItems: 10
    };
    let addrArr: LocationSearchResult[] = [];
    try {
      const data = await geoLocationManager.getAddressesFromLocationName(queryRequest);
      if (data) {
        for (let addr of data) {
          const administrativeArea = addr.administrativeArea ?? '';
          const locality = addr.locality ?? '';
          const subLocality = addr.subLocality ?? '';
          const roadName = addr.roadName ?? '';
          const formatAddress = AgendaUtil.getFormatAddress(administrativeArea, locality, subLocality, roadName);
          addrArr.push({
            name: addr.placeName ?? '',
            formatAddress: formatAddress,
            latitude: addr.latitude ?? -1,
            longitude: addr.longitude ?? -1
          });
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryAddrByLocationName', err);
    }
    return addrArr;
  }

  /**
   * 点击当前位置后，判断网络及权限，再触发查询
   */
  private async locationClick() {
    Log.info(TAG, 'locationClick start')
    if (!this.isNet) {
      Log.info(TAG, 'locationClick No network')
      showToast(GlobalThis.getResourceStr($r('app.string.connect_network_to_use'), i18n.System.getSystemLanguage()));
      return;
    }
    let permissions: boolean = await this.checkFencePermissions();
    Log.info(TAG, 'locationClick location permissions = ' + permissions);
    if (!permissions) {
      let openLocationSettingDialog = await this.locationSettingDialog();
      let isAllowLocationPermissions = await this.requestFencePermissions(openLocationSettingDialog);
      if (!isAllowLocationPermissions) {
        return;
      }
    }
    // 位置服务开关状态
    let isLocationEnabled = geoLocationManager.isLocationEnabled();
    if (!isLocationEnabled) {
      let openLocationEnableDialog = this.initLocationEnableDialog();
      openLocationEnableDialog.open();
      return;
    }
    this.isLocatingCurrent = true;
    const locationWGS84Info = await this.initCurrentLocation();
    this.currentLatitude = locationWGS84Info.latitude as number;
    this.currentLongitude = locationWGS84Info.longitude as number;
    this.queryLocation(locationWGS84Info.latitude as number, locationWGS84Info.longitude as number);
  }

  /**
   * 查询位置信息
   * @param latitude latitude信息
   * @param longitude longitude信息
   */
  private queryLocation(latitude: number, longitude: number): void {
    let reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
      'latitude': latitude,
      'longitude': longitude,
      'maxItems': 8
    };
    try {
      geoLocationManager.getAddressesFromLocation(reverseRequest, async (err, data) => {
        if (err) {
          Log.error(TAG, `queryLocation: err:${err?.message}`);
        }
        Log.info(TAG, 'queryLocation: data size =  ' + data.length);
        if (data && data.length > 0) {
          let addr: geoLocationManager.GeoAddress = data[0];
          const address = addr.placeName ?? '';
          const administrativeArea = addr.administrativeArea ?? '';
          const locality = addr.locality ?? '';
          const subLocality = addr.subLocality ?? '';
          const roadName = addr.roadName ?? ''
          const formatAddress = AgendaUtil.getFormatAddress(administrativeArea, locality, subLocality, roadName);
          this.currentLocation = address + NEWLINE_SYMBOL + formatAddress;
          this.mLocation = this.currentLocation;
          this.mLongitude = this.currentLongitude;
          this.mLatitude = this.currentLatitude;
          this.isLocationAbility = false;
        }
      });
    } catch (err) {
      Log.logErrorMsg(TAG, 'queryLocation', err);
    }
  }

  /**
   * 查询位置权限
   * @returns 是否已经授权
   */
  private async checkFencePermissions(): Promise<boolean> {
    let locationPermissions: boolean = await this.checkLocationPermissions();
    Log.info(TAG, 'checkFencePermissions locationPermissions = ' + locationPermissions);
    if (!locationPermissions) {
      return false;
    }
    return true;
  }

  /**
   * 请求权限的弹框（包括系统弹框和禁用后引导用户授权弹框）
   * @param locationPermissionDialog
   */
  private async requestFencePermissions(locationPermissionDialog: CustomDialogController): Promise<boolean> {
    const LOCATION_FILE_NAME = 'location';
    const FIRST_LOCATION_POPUP_KEY = 'first_location_popup';
    const hasLocationPermission: boolean = await this.requestLocationPermissions();
    Log.info(TAG, `requestFencePermissions hasLocationPermission:  ${hasLocationPermission}`);
    if (!hasLocationPermission) {
      // 首次系统定位弹窗禁止后，不自动弹前往设置弹窗
      let isFirstRequest = PreferencesUtil.getBooleanValueSync(LOCATION_FILE_NAME, FIRST_LOCATION_POPUP_KEY, true);
      Log.info(TAG, `requestFencePermissions:  ${isFirstRequest}`);
      if (!isFirstRequest) {
        locationPermissionDialog?.open();
      }
    }
    PreferencesUtil.putBooleanValueSync(LOCATION_FILE_NAME, FIRST_LOCATION_POPUP_KEY, false);
    return hasLocationPermission;
  }

  /**
   * 请求位置权限
   */
  private async requestLocationPermissions(): Promise<boolean> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const context = getContext() as common.UIAbilityContext;
    let requestResult = await atManager.requestPermissionsFromUser(context, LOCATION_PERMISSIONS)
      .catch((err: BusinessError) => {
        Log.error(TAG, `Failed to request permissions Code is ${err.code}, message is ${err.message}`);
      })
    Log.error(TAG, 'requestLocationPermissions: requestResult = ' + requestResult);
    if (!requestResult) {
      return false;
    }
    if (!requestResult.authResults || requestResult.authResults.length < 2) {
      Log.error(TAG, 'requestLocationPermissions: requestResult.authResults is error');
      return false;
    }
    if (requestResult.authResults[0] === -1 || requestResult.authResults[1] === -1) {
      Log.error(TAG, 'requestLocationPermissions: PERMISSION_DENIED');
      return false;
    }
    return true;
  }

  /**
   * 校验应用是否被授予定位权限
   * @returns true:已授权，false:未授权
   */
  private async checkLocationPermissions(): Promise<boolean> {
    let exactLocation: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(LOCATION_PERMISSIONS[0]);
    let location: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(LOCATION_PERMISSIONS[1]);
    return location === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED &&
      exactLocation === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
  }

  /**
   * 应用位置权限状态
   * @returns true 位置开启，精确位置没开  false 位置和精确位置都没开
   */
  private async checkLocationGrantStatus(): Promise<boolean> {
    if (LOCATION_PERMISSIONS.length < 2) { // 位置和精确位置权限
      return false;
    }
    let exactLocation: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(LOCATION_PERMISSIONS[0]);
    let location: abilityAccessCtrl.GrantStatus = await this.checkAccessToken(LOCATION_PERMISSIONS[1]);
    return exactLocation === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED &&
      location === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
  }

  private async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let tokenId: number = 0;
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    Log.info(TAG, 'checkAccessToken Succeeded in getting Bundle.');
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    Log.info(TAG, 'checkAccessToken Succeeded in checking access token.');
    return grantStatus;
  }

  //跳转设置弹窗
  private async locationSettingDialog(): Promise<CustomDialogController> {
    let locationGrantStatus = await this.checkLocationGrantStatus();
    const locationDialog: CustomDialogController = new CustomDialogController({
      builder: AlertDialog({
        primaryTitle: locationGrantStatus ?
        GlobalThis.getResourceStr($r('app.string.location_services_dialog_title'), i18n.System.getSystemLanguage()) :
        GlobalThis.getResourceStr($r('app.string.location_services_dialog_title_default'),
          i18n.System.getSystemLanguage()),
        content: GlobalThis.getResourceStr($r('app.string.location_services_dialog_content'),
          i18n.System.getSystemLanguage()),
        primaryButton: {
          value: GlobalThis.getResourceStr($r('app.string.cancel_dialog_button'), i18n.System.getSystemLanguage()),
          action: () => {
            Log.info(TAG, 'click dialog cancel');
            locationDialog.close()
          },
          fontColor: this.themeColor
        },
        secondaryButton: {
          value: GlobalThis.getResourceStr($r('app.string.go_to_setting'), i18n.System.getSystemLanguage()),
          action: () => {
            Log.info(TAG, 'click dialog go to Settings');
            locationDialog.close();
            this.gotoOpenLocationServices();
          },
          fontColor: this.themeColor
        },
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    return locationDialog;
  }

  private initLocationEnableDialog(): CustomDialogController {
    const locationEnableDialog: CustomDialogController = new CustomDialogController({
      builder: AlertDialog({
        primaryTitle: GlobalThis.getResourceStr($r('app.string.location_enable_dialog_title'),
          i18n.System.getSystemLanguage()),
        content: GlobalThis.getResourceStr($r('app.string.location_services_dialog_content'),
          i18n.System.getSystemLanguage()),
        primaryButton: {
          value: GlobalThis.getResourceStr($r('app.string.cancel_dialog_button'), i18n.System.getSystemLanguage()),
          action: () => {
            Log.info(TAG, 'click locationEnable dialog cancel');
            locationEnableDialog.close();
          },
          fontColor: this.themeColor
        },
        secondaryButton: {
          value: GlobalThis.getResourceStr($r('app.string.go_to_setting'), i18n.System.getSystemLanguage()),
          action: async () => {
            Log.info(TAG, 'click locationEnable dialog go to Settings');
            locationEnableDialog.close();
            this.requestLocationGlobalSwitch();
          },
          fontColor: this.themeColor
        },
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    return locationEnableDialog;
  }

  private gotoOpenLocationServices(): void {
    Log.info(TAG, 'gotoOpenLocationServices');
    try {
      let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      atManager.requestPermissionOnSetting(getContext() as common.UIAbilityContext, LOCATION_PERMISSIONS)
        .then((data: Array<abilityAccessCtrl.GrantStatus>) => {
          this.locationPermissionOnSettingCallback(data);
        })
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed gotoOpenLocationServices', err);
    }
  }

  private locationPermissionOnSettingCallback(data: Array<abilityAccessCtrl.GrantStatus>) {
    if (!data) {
      Log.warn(TAG, 'locationPermissionOnSettingCallback data undefined.');
      return;
    }
    for (let i = 0; i < data.length; i++) {
      if (data[i] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        Log.warn(TAG, 'requestPermissionOnSetting Failed locationPermission.');
        return;
      }
      Log.info(TAG, 'requestPermissionOnSetting locationPermission success.');
    }
  }

  //获取当前地点信息
  private async initCurrentLocation(): Promise<LocationInfo> {
    let requestInfo: geoLocationManager.CurrentLocationRequest = {
      'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
      'scenario': geoLocationManager.LocationRequestScenario.UNSET,
      'maxAccuracy': 0,
    };
    let locationInfo: LocationInfo = {};
    try {
      const location = await geoLocationManager.getCurrentLocation(requestInfo);
      locationInfo = {
        latitude: location.latitude,
        longitude: location.longitude
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'initCurrentLocation', err);
    }
    return locationInfo;
  }

  private async requestLocationGlobalSwitch(): Promise<boolean> {
    let isLocationEnable: boolean = false;
    try {
      let atManager = abilityAccessCtrl.createAtManager();
      isLocationEnable = await atManager.requestGlobalSwitch(getContext() as common.UIAbilityContext,
        abilityAccessCtrl.SwitchType.LOCATION);
    } catch (err) {
      Log.logErrorMsg(TAG, 'Failed requestLocationGlobalSwitch', err);
    }
    return isLocationEnable;
  }
}

/**
 * 位置搜索结果接口（替代MapKit的site.Site）
 */
export interface LocationSearchResult {
  name: string;
  formatAddress: string;
  latitude: number;
  longitude: number;
}

export interface LocationInfo {
  location?: string;
  latitude?: number;
  latitudeStr?: string;
  longitude?: number;
  longitudeStr?: string;
}
