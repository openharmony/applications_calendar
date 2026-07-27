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
  behaviorEvents,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  DialogControllerOptions,
  GlobalThis,
  NavPathManager,
  NavPathName,
  ReportUtil,
  RouterModel,
  RouterName,
  statisticEvents,
  ThrottleFunction
} from '@app/common';
import { MenuDividerLine } from '@app/common.components/src/main/ets/MenuDividerLine';
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'ConfigMenu'

@Extend(Menu)
function menuCommerceStyle(needCommerce: boolean) {
  .radius(needCommerce ? 8 : undefined)
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}

/**
 * 选项配置菜单
 */
@Component
export struct ConfigMenu {
  @Consume navPathStack: NavPathStack;

  @Consume isShowSettingPage: boolean;
  //显示搜索日程页面
  @Prop showSearch: boolean = false;

  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // 节流函数触发的最小时间间隔
  private readonly DELAY: number = 300;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onChanged: (showSearch: boolean) => void = () => {
  };

  showJumpToSomedayDialog: () => void = () => {
  }

  build() {
    Menu() {
      MenuItem({ content: $r('app.string.jump_to_someday') })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          ThrottleFunction.instance().throttle(TAG, (): void => {
            this.showJumpToSomedayDialog();
          }, this.DELAY)
        }).id(CompId.MENU_JUMP_SPECIFIED_DATE)
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.jump_to_someday')));
      MenuDividerLine();
      MenuItem({ content: $r('app.string.show_all_agenda') })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          ReportUtil.reportBehaviorEvent(behaviorEvents.clickAllAgenda);
          ThrottleFunction.instance().throttle(TAG, (): void => {
            NavPathManager.getInstance().pushPath({
              builderName: NavPathName.AGENDA_LIST,
              routerName: RouterName.ENTRY_HAP,
              param: {}
            });
          }, this.DELAY)
        }).id(CompId.MENU_SHOW_ALL_AGENDA)
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.show_all_agenda')));
      MenuDividerLine();
      MenuItem({ content: $r('app.string.search_for_events') })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          const param: Record<string, number> = {};
          const routerData: RouterModel = {
            builderName: NavPathName.FLEX_SEARCH_AGENDA,
            routerName: RouterName.ENTRY_HAP,
            param: param
          }
          if (this.tryToShowPop(routerData)) {
            return;
          }
          ThrottleFunction.instance().throttle(TAG, (): void => {
            console.info(" search icon onclick");
            this.showSearch = true;
            this.onChanged(this.showSearch);
            ReportUtil.reportStatisticEvent(statisticEvents.search);
          }, this.DELAY)
        }).id(CompId.SEARCH_AGENDA)
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.search_for_events')));
      MenuDividerLine();
      MenuItem({ content: $r('app.string.menu_preferences') })
        .menuItemCommerceStyle(this.needCommerce)
        .onClick(() => {
          const param: Record<string, number> = {};
          const routerData: RouterModel = {
            builderName: NavPathName.SETTING_MAIN,
            routerName: RouterName.ENTRY_HAP,
            param: param
          }
          if (this.tryToShowPop(routerData)) {
            return;
          }
          ThrottleFunction.instance().throttle(TAG, (): void => {
            ReportUtil.reportStatisticEvent(statisticEvents.goToSettings);
            this.isShowSettingPage = true;
          }, this.DELAY);
        }).id(CompId.MENU_PREFERENCES)
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.menu_preferences')));
    }
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Medium })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
    .menuCommerceStyle(this.needCommerce);
  }

  aboutToAppear() {
    ReportUtil.reportStatisticEvent(statisticEvents.clickMore);
  }

  /**
   * 跳转到弹窗页面
   *
   * @param routerData 需要跳转的目标路由信息
   * @returns 是否跳转成功
   */
  tryToShowPop(routerData: RouterModel): boolean {
    if (DeviceConfig.instance().config.showMorePagePopUp) {
      const eventData: emitter.EventData = {
        data: routerData
      };
      emitter.emit({ eventId: CommonInnerEvent.MORE_PAGE_TO_POPUP }, eventData);
      return true;
    }
    return false;
  }
}