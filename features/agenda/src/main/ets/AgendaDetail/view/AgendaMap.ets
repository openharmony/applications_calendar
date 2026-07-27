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
//import { mapCommon, staticMap } from '@kit.MapKit';
import {
  AgendaEventInfo,
  AgendaUtil,
  BigFontSize,
  CompId,
  DeviceConfig,
  GlobalDataKeys,
  Log
} from '@app/common';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG: string = 'AgendaMap';

@Component
export struct AgendaMap {
  @Prop @Watch('infoChanged') info: AgendaEventInfo | undefined;

  @State image: PixelMap | undefined = undefined;

  //静态图参数
 // private staticMapOptions?: staticMap.StaticMapOptions;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //静态图宽度
  private mapWidth: number = 512;

  //静态图高度
  private mapHeight: number = 200;

  //静态图缩放级别
  private mapZoom: number = 15;

  //静态图比例
  private mapScale: number = 2;

  private mLatitude: number = -1;

  private mLongitude: number = -1;

  //private mapMarkers: Array<staticMap.StaticMapMarker> = [];

  @LocalStorageLink('uiAbilityContext') context: common.UIAbilityContext | undefined = undefined;

  // 深色模式
  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

//  private mapDayNightMode: mapCommon.DayNightMode =
//    this.isDarkMode ? mapCommon.DayNightMode.NIGHT : mapCommon.DayNightMode.DAY;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private infoChanged(): void {
    this.initInfo();
  }

  /**
   * 监听深色模式变化
   */
  private onDarkModeChange(): void {
    Log.info(TAG, 'agendaMap: dark mode has changed ' + this.isDarkMode);
    //this.mapDayNightMode = this.isDarkMode ? mapCommon.DayNightMode.NIGHT : mapCommon.DayNightMode.DAY;
    //this.getStaticMapOptions();
    this.refreshStaticMap();
  }

  private initInfo(): void {
    if (!this.info) {
      Log.info(TAG, 'info is null');
      return;
    }
    this.info.mTitle = AgendaUtil.filterEmLabel(this.info.mTitle);
    this.info.mLocation = AgendaUtil.filterEmLabel(this.info.mLocation);
    this.mLatitude = this.info.mLatitude;
    this.mLongitude = this.info.mLongitude;
    this.initMarker();
    this.checkZoom(this.mapZoom);
    this.checkScale(this.mapScale);
    //this.getStaticMapOptions();
    this.refreshStaticMap();
  }

  private initMarker(): void {
//    this.mapMarkers = [];
//    this.mapMarkers.push({
//      location: {
//        latitude: this.mLatitude,
//        longitude: this.mLongitude
//      },
//      defaultIconSize: staticMap.IconSize.SMALL,
//    })
  }

  private checkZoom(zoom: number): void {
    if (zoom < 2 || zoom > 17) {
      Log.error(TAG, 'zoom parameter is invalid');
      this.mapZoom = 15;
      return;
    } else {
      this.mapZoom = Math.floor(zoom);
    }
  }

  private checkScale(scale: number): void {
    if (scale !== 1 && scale !== 2) {
      Log.error(TAG, 'scale parameter is invalid');
      this.mapScale = 2;
    }
  }

//  private getStaticMapOptions(): staticMap.StaticMapOptions {
//    let position: mapCommon.LatLng = {
//      latitude: this.mLatitude,
//      longitude: this.mLongitude
//    };
//    this.staticMapOptions = {
//      location: position,
//      zoom: this.mapZoom,
//      imageWidth: this.mapWidth,
//      imageHeight: this.mapHeight,
//      scale: this.mapScale,
//      markers: this.mapMarkers,
//     // dayNightMode: this.mapDayNightMode,
//    };
//    return this.staticMapOptions;
//  }

  private async refreshStaticMap(): Promise<void> {
    try {
      //this.image = await staticMap.getMapImage(this.staticMapOptions);
      Log.info(TAG, `agenda map getStaticMap success`);
    } catch (err) {
      Log.logErrorMsg(TAG, 'refreshStaticMap', err);
    }
  }

  aboutToAppear(): void {
    Log.info(TAG, 'agendaMap about to appear');
    this.initInfo();
  }

  aboutToDisappear(): void {
    Log.info(TAG, 'agendaMap about to disappear');
    //释放PixelMap对象
    if (this.image !== undefined) {
      this.image?.release().then(() => {
        Log.info(TAG, 'succeeded in releasing pixelMap');
      }).catch((error: BusinessError) => {
        Log.error(TAG, `failed to release pixelMap,errCode:${error.code},message is ${error.message}`);
      })
    }
  }

  @Builder
  buildStaticMap() {
    Row() {
      Image(this.image)
        .height(this.mapHeight)
        .width('100%')
        .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
        .accessibilityText(AgendaUtil.getLocation(this.info!.mLocation))
    }
  }

  build() {
    Column() {
      this.buildStaticMap();
    }
    .id(CompId.AGENDA_MAP)
    .padding({
      left: 0,
      right: 0,
      top: 0,
      bottom: 0
    })
    .width('100%')
    .margin({ bottom: 12 })
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
    .shadow({ radius: 20, color: '#0d000000' })
    .onClick(() => {
      AgendaUtil.jumpMapLocationInfoPage(this.info!.mLocation, this.mLatitude, this.mLongitude, this.context);
    })
    .onAppear(() => {
      Log.info(TAG, `agenda map appear`);
    })
  }
}
