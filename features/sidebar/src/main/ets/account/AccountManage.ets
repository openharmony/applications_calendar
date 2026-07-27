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

import { AccountGroupList } from './AccountGroupList';
import {
  behaviorEvents,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  EmitterCollector,
  FeatureType,
  FontSizeScaleUtils,
  Log,
  ReportUtil,
  GlobalDataKeys,
  PreferencesFiles,
  PreferencesUtil
} from '@app/common';
import lazy { AccountDetail } from '@app/feature.account';
import { emitter } from '@kit.BasicServicesKit';
import { AccountAddMenu } from './AccountAddMenu';
import { LengthMetrics } from '@kit.ArkUI';
import lazy { KeyCode } from '@kit.InputKit';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { ImportAgenda } from '@app/feature.importexport';
import { AccountMenu, AccountMenuOpt } from './AccountMenu';
import { TipsPopup } from '@app/common.components';

const TAG: string = 'SideBarAccountManage';

@Builder
export function pageBuilder() {
  AccountManage();
}

/**
 * 帐户管理组件
 */
@Component
export struct AccountManage {
  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 侧边栏是否为悬浮态
  @Consume sideBarOverlay: boolean;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  onFontSizeScaleChange(num: number) {
    Log.info(TAG, `SideAccountManage font size:${this.fontSizeScale}`);
    return FontSizeScaleUtils.getLimitFontSizeVp(
      this.fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_SCALE_2X,
      num
    );
  }

  // 帐户管理界面标题栏
  @Builder
  AccountManageTitle() {
    Row() {
      Text($r('app.string.sidebar_account_calendar'))
        .fontSize(this.onFontSizeScaleChange(18))
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Start)
        .fontFamily('HarmonyHeiTi')
        .id(CompId.SIDEBAR_ACCOUNT_CALENDAR)
        .layoutWeight(1)
      Blank()
      this.NavigationMenus()
    }
    .width('100%')
    .constraintSize({ minHeight: this.needCommerce ? 48 : 56 })
    .alignItems(VerticalAlign.Center)
    .padding({
      start: LengthMetrics.vp(8),
      end: LengthMetrics.vp(3),
      top: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? LengthMetrics.vp(10) : LengthMetrics.vp(0),
      bottom: this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD ? LengthMetrics.vp(10) : LengthMetrics.vp(8)
    })
  }

  //添加账户按钮
  @Builder
  NavigationMenus() {
    NaviMenus({ themeColor: this.themeColor })
  }

  @Builder
  existMenu() {
    AccountMenu({
      menuOpts: [AccountMenuOpt.CREATE],
    })
  }

  build() {
    Column() {
      this.AccountManageTitle()

      AccountGroupList({
        themeColor: this.themeColor,
        sideBarOverlay: this.sideBarOverlay
      })
    }
    .bindContextMenu(this.existMenu(), ResponseType.RightClick)
  }

  aboutToAppear(): void {
    Log.info(TAG, 'aboutToAppear')
  }
}

@Component
struct NaviMenus {
  @Consume navPathStack: NavPathStack;

  // hover态颜色
  @State hoverColor: Resource = $r('app.color.default_background');

  // 主题颜色
  @State themeColor: string = '';

  @State @Watch('onIsShowCreateAccountDetailPage') isShowCreateAccountPage: boolean = false;

  @State accountPageName: string = '';

  // 模态窗动画结束标识
  @Provide isAccountAniShowFinish: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private cardToMonthHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowCreateAccountPage = false;
  };

  private importAgendaHandler: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.accountPageName = AccountPageName.IMPORT_AGENDA_PAGE;
    this.isShowCreateAccountPage = true;
  };

  @State disCardFlag: boolean = false;

  private nowSpringAction: SpringBackAction | undefined = undefined;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  private closePage: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.isShowCreateAccountPage = false;
  };

  private onDialogCancel: () => void = () => {
    if (this.nowSpringAction) {
      // 弹窗直接取消的情况下要回弹新建日程弹窗并将action设为空以防止出错
      this.nowSpringAction.springBack();
      this.nowSpringAction = undefined;
    }
  };

  onFontSizeScaleChange() {
    return FontSizeScaleUtils.getLimitFontSizeVp(
      this.fontSizeScale,
      BigFontSize.BIG_FONT_SIZE_SCALE_2X,
      14
    );
  }

  @Builder
  buildCreateAccountPage() {
    Column() {
      if (this.accountPageName === AccountPageName.DEFAULT_CREATE_ACCOUNT_PAGE) {
        AccountDetail({
          isShowAccountDetailPage: $isShowCreateAccountPage,
          discardFlag: this.disCardFlag,
          onDialogCancel: this.onDialogCancel
        })
      }
      if (this.accountPageName === AccountPageName.IMPORT_AGENDA_PAGE) {
        ImportAgenda({
          showPage: $isShowCreateAccountPage,
          discardFlag: this.disCardFlag,
        });
      }
    }
    .height('100%')
    .width('100%')
  }

  onIsShowCreateAccountDetailPage() {
    Log.info(TAG, 'Try to Create Account, and isShowCreateAccountPage = ' + this.isShowCreateAccountPage)
  }

  @Builder
  MoreMenu() {
    Column() {
      AccountAddMenu();
    }
  }

  aboutToAppear(): void {
    this.openDefaultAccountHandle = () => {
      this.accountPageName = AccountPageName.DEFAULT_CREATE_ACCOUNT_PAGE;
      this.isShowCreateAccountPage = true;
    };
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_ACCOUNT_DEFAULT_PAGE_OPEN }
      , this.openDefaultAccountHandle);

    // 卡片点击进入月视图，关闭半模态
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_FROM_CARD_TO_MONTH }, this.cardToMonthHandler);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_COMMON_CLOSE_PAGE_DIALOG }, this.closePage);
    this.emitterCollector.on({ eventId: CommonInnerEvent.EVENT_IMPORT_AGENDA_PAGE_OPEN }, this.importAgendaHandler);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  build() {
    Button({ type: ButtonType.Normal }) {
      Text($r('app.string.calandar_add'))
        .fontSize(14)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
        .fontColor(this.themeColor)
        .align(Alignment.Center)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .constraintSize({ minWidth: 32, minHeight: 18 })
        .margin(4)
    }
    .responseRegion({
      x: -7,
      y: -13,
      width: 52,
      height: 52
    })
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick((event => {
      ReportUtil.reportBehaviorEvent(behaviorEvents.accountClickGoToCreate);
    }))
    .hoverEffect(HoverEffect.Highlight)
    .bindMenu(this.MoreMenu(), {
      offset: { x: -7, y: 0 },
      placement: Placement.BottomLeft,
      showInSubWindow: false
    })
    .backgroundColor(this.hoverColor)
    .id(CompId.ADD_ACCOUNT)
    .bindSheet($$this.isShowCreateAccountPage, this.buildCreateAccountPage(), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.CENTER,
      backgroundColor: $r('sys.color.ohos_id_blur_style_background_ultra_thick_color'),
      maskColor: $r('sys.color.ohos_id_color_mask_thin'),
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
      //keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
        Log.info(TAG, 'shouldDismiss');
        this.disCardFlag = !this.disCardFlag;
      }),
      onWillSpringBackWhenDismiss: ((springBackAction: SpringBackAction) => {
        this.nowSpringAction = springBackAction;
        // 没有注册springBackAction.springBack(), 下拉半模态页面无回弹行为
      }),
      onAppear: () => {
        this.isAccountAniShowFinish = true;
        Log.debug(TAG, 'BindSheet onAppear.');
      },
      onDisappear: () => {
        Log.debug(TAG, 'BindSheet onDisappear.');
      }
    })
    .onKeyEvent((event) => {
      if (event.keyCode === KeyCode.KEYCODE_DPAD_UP || event.keyCode === KeyCode.KEYCODE_DPAD_DOWN ||
        event.keyCode === KeyCode.KEYCODE_DPAD_LEFT || event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
        event.stopPropagation()
      }
    })
    .onAppear(() => {
    })
    .onDisAppear(() => {
    })
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText });
  }

  private openDefaultAccountHandle: () => void = (): void => {
  };
}

enum AccountPageName {
  DEFAULT_CREATE_ACCOUNT_PAGE = 'Default',
  IMPORT_AGENDA_PAGE = 'Import',
}