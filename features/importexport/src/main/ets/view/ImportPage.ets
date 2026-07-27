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
  AgendaEventInfo,
  behaviorEvents,
  BigFontSize,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MIN_WINDOW_WIDTH_VP,
  NavPathManager,
  NavPathName,
  ReportHiEventParams,
  ReportUtil,
  RouterName,
  ViewProxy
} from '@app/common/index';
import lazy { ImportAgendaAccount } from './account/ImportAccount';
import { ImportAgendaList } from './agenda/ImportAgendaList';
import { ImportAccountColor } from './account/ImportAccountColor';
import { ImportData } from '../interface/ImportData';
import { SimpleAccount } from '../interface/SimpleAccount';
import { ImportType } from '../interface/BusinessConstant';
import { ImportVcsCallBack } from '../interface/ImportVcsCallBack';
import { ImportAccountInform } from './account/ImportAccountInform';
import { emitter } from '@kit.BasicServicesKit';
import { LengthMetrics } from '@kit.ArkUI';

const TAG: string = 'ImportPage';

const SHOW_ALL_EVENT_LIMIT: number = 3;

interface PageParam {
  importData: ImportData
}

/**
 * 分享导入页
 */
@Component
export struct ImportPage {
  @Consume navPathStack: NavPathStack;

  @StorageLink('themeColor') themeColor: string = '';

  @StorageLink('bgThemeColor') bgThemeColor: string = '';

  // 显示新建日程的半模态
  @Link isShowImportPage: boolean;

  // 是否从这跳转到了选择账户页或查看日程列表页
  @State isJumpToOtherPage: boolean = false;

  @State checkedAccId: number = 0;

  @State viewProxy: ViewProxy = new ViewProxy(TAG);

  @State simpleAccount: SimpleAccount = new SimpleAccount(0, '', 0, false);

  @State importType: ImportType = ImportType.ACCOUNT_IMPORT;

  @State mEventsCount: number = 0;

  @State mHeadEvents: AgendaEventInfo[] = [];

  @State mAllEvents: AgendaEventInfo[] = [];

  @State accountColor: number = AccountColor.RED;

  @Link importData: ImportData;

  @State isInform: boolean = true;

  @State allEventsAreImportant : boolean = false;

  private calendarDisplayName: string = '';

  // 是否已经处理过用户的保存动作
  private isHandleUserSaveAction: boolean = false;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 窗口大小
  @StorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  private scroller: Scroller = new Scroller();

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  /**
   * bindSheet 没有此回调,无法拦截返回
   *
   */
  onBackPress() {
    Log.info(TAG, `onBackPress`);
    return this.viewProxy.onBackPressed();
  }

  aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.isHandleUserSaveAction = false;
    this.isJumpToOtherPage = false;
    this.simpleAccount = this.importData?.simpleAccount;
    this.importType = this.importData?.importType;
    this.mEventsCount = this.importData?.mEventsCount;
    this.mHeadEvents = this.importData?.mHeadEvents;
    this.mAllEvents = this.importData?.mAllEvents;
    if (this.mEventsCount === 0 && this.mAllEvents) {
      this.mEventsCount = this.mAllEvents.length;
    }
    this.calendarDisplayName = this.simpleAccount.mAccountDisplayName;
    this.allEventsAreImportant = this.mAllEvents?.every(event => new AgendaEventInfo(event).isImportantEvent())
    if (this.importType === ImportType.ACCOUNT_IMPORT) {
      this.accountColor = this.accountColor != AccountColor.RED ? this.accountColor : this.simpleAccount.mAccountColor;
    }
  }

  /**
   * 侧滑或下滑消失半膜态会走这个回调,跳转到选择账户页也会回调
   */
  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
    this.trySaveImportData(false);
  }

  build() {
    Column() {
      Row() {
        List({ scroller: this.scroller }) {
          // 展示标题
          this.importAgendaTitle();
          this.agendaTitleVerticalLayout();

          // 展示日程
          this.showAgenda();
          // 展示帐户
          this.showAccount();
        }
        .scrollBar(BarState.Off)
        .borderRadius($r('sys.float.corner_radius_level10'))

        ScrollBar({ scroller: this.scroller, direction: ScrollBarDirection.Vertical, state: BarState.Auto })
          .width(16)
      }
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      // 接收取消按钮
      this.importButton();
    }
    .padding({ left: 16, right: 16 })
    .width('100%')
    .id(CompId.IMPORT_PAGE_CONTAINER)
  }

  // 日程标题
  @Builder
  importAgendaTitle() {
    Row() {
      Text($r('app.string.schedule_preview'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .opacity(0.6)
        .align(Alignment.Start)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .margin({ start: LengthMetrics.vp(14), top: LengthMetrics.vp(24) })

      Row() {
        Text(this.mEventsCount ? this.mEventsCount.toString() : '0')
          .fontColor(this.themeColor)
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            10
          ))
          .margin({ left: 6, right: 6 })
      }
      .constraintSize({ minWidth: 16 })
      .align(Alignment.Center)
      .backgroundColor(this.bgThemeColor)
      .margin({ start: LengthMetrics.vp(8), top: LengthMetrics.vp(24) })
      .borderRadius(8)
      .visibility((this.mAllEvents && this.mAllEvents.length > 1) ? Visibility.Visible : Visibility.Hidden)

      Blank()

      Text($r('app.string.show_all'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .fontColor(this.themeColor)
        .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
        .textAlign(TextAlign.End)
        .margin({ top: 23 })
        .onClick(() => {
          this.showAgendaList();
        })
        .visibility((this.mAllEvents && this.mAllEvents.length > SHOW_ALL_EVENT_LIMIT) ? Visibility.Visible : Visibility.Hidden)
    }
    .visibility(!this.isChangeLayout() ? Visibility.Visible : Visibility.None)
    .constraintSize({ minHeight: 56 })
    .width('100%')
  }

  @Builder
  agendaTitleVerticalLayout() {
    Column() {
      Row() {
        Text($r('app.string.schedule_preview'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
            14
          ))
          .opacity(0.6)
          .align(Alignment.Start)
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .margin({ start: LengthMetrics.vp(14), top: LengthMetrics.vp(24) })

        Row() {
          Text(this.mEventsCount ? this.mEventsCount.toString() : '0')
            .fontColor(this.themeColor)
            .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
            .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
              this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
              10
            ))
            .margin({ left: 6, right: 6 })
        }
        .constraintSize({ minWidth: 16 })
        .align(Alignment.Center)
        .backgroundColor(this.bgThemeColor)
        .margin({ start: LengthMetrics.vp(8), top: LengthMetrics.vp(24) })
        .borderRadius(8)
        .visibility((this.mAllEvents && this.mAllEvents.length > 1) ? Visibility.Visible : Visibility.Hidden)
      }

      Text($r('app.string.show_all'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .fontColor(this.themeColor)
        .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
        .textAlign(TextAlign.End)
        .margin({ start: LengthMetrics.vp(14) })
        .onClick(() => {
          this.showAgendaList();
        })
        .visibility((this.mAllEvents && this.mAllEvents.length > SHOW_ALL_EVENT_LIMIT) ? Visibility.Visible : Visibility.Hidden)
    }
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ minHeight: 56 })
    .width('100%')
    .visibility(this.isChangeLayout() ? Visibility.Visible : Visibility.None)
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SCALE_2X;
  }

  private async showAgendaList() {
    const param: Record<string, AgendaEventInfo[] | number> = {};
    param.datas = this.mAllEvents;
    param.checkedAccId = this.checkedAccId
    param.accountColor = this.accountColor;
    const jumpResult = await NavPathManager.getInstance().pushPath({
      builderName: NavPathName.IMPORT_SHOW_AGENDA,
      routerName: RouterName.ENTRY_HAP,
      param: param
    });
    if (!jumpResult) {
      Log.warn(TAG, `showAgendaList jumpResult false`);
      return;
    }
    this.isJumpToOtherPage = true;
    this.isShowImportPage = false;
  }

  // 日程展示
  @Builder
  showAgenda() {
    Row() {
      ImportAgendaList({
        agendaList: this.mAllEvents,
        mHeadEvents: this.mHeadEvents,
        accountColor: this.accountColor
      })
    }
    .width('100%')
  }

  // 账户展示
  @Builder
  showAccount() {
    if (this.importType !== ImportType.ACCOUNT_IMPORT) {
      this.showLocalAccount();
    } else {
      this.importAccount();
      ImportAccountColor({
        calendarColor: this.accountColor
      })
    }
  }

  // 本地账户展示
  @Builder
  showLocalAccount() {
    Row() {
      Text($r('app.string.Import_account'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .opacity(0.6)
        .align(Alignment.Start)
        .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
        .margin({ start: LengthMetrics.vp(14), top: LengthMetrics.vp(16) })
    }
    .constraintSize({ minHeight: 56 })
    .width(328)

    // 展示帐户
    Row() {
      ImportAgendaAccount({
        checkedAccId: this.checkedAccId,
        isShowImportPage: this.isShowImportPage,
        isJumpToAccount: this.isJumpToOtherPage,
        allEventsAreImportant: this.allEventsAreImportant
      })
    }
    .constraintSize({ minHeight: 56, minWidth: 328 })
  }

  @Builder
  importAccount() {
    Row() {
      Text($r('app.string.custom_account_name_title'))
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
          14
        ))
        .opacity(0.6)
        .align(Alignment.Start)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .margin({ start: LengthMetrics.vp(12), top: LengthMetrics.vp(16) })
    }
    .constraintSize({ minHeight: 56 })
    .width('100%')

    // 展示帐户
    Row() {
      Row() {
        Column() {
          TextInput({ text: this.calendarDisplayName })
            .placeholderColor($r('sys.color.font_secondary'))
            .caretColor(this.themeColor)
            .selectedBackgroundColor(this.themeColor)
            .placeholderFont({ size: $r('sys.float.Body_L'), weight: FontWeight.Medium })
            .fontSize($r('sys.float.Body_L'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor(Color.Transparent)
            .maxLength(64)
            .onChange((value: string) => {
              this.calendarDisplayName = value;
            })
            .padding({ left: 0 })
        }
        .width('100%')
      }
      .constraintSize({ minHeight: 56 })
      .width('100%')
      .padding({
        left: 12,
        right: 12,
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(20)
    }
  }

  // 接收取消按钮
  @Builder
  importButton() {
    Row() {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text($r('app.string.cancel_dialog_button'))
          .fontSize(16)
          .fontColor(this.themeColor)
          .lineHeight(21)
      }
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level10'))
      .width('calc(50% - 6px)')
      .constraintSize({ minHeight: 40 })
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        normal: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .onClick(() => {
        this.trySaveImportData(false);
      })

      Button({ type: ButtonType.Normal, stateEffect: true }) {
        Text($r('app.string.received'))
          .fontSize(16)
          .fontColor('#FFFFFF')
          .lineHeight(21)
      }
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level10'))
      .width('calc(50% - 6px)')
      .constraintSize({ minHeight: 40 })
      .hoverEffect(HoverEffect.Highlight)
      .stateStyles({
        normal: {
          .backgroundColor($r('app.color.red_common'))
        }
      })
      .onClick(() => {
        this.trySaveImportData(true);
      })
    }
    .margin({ top: 16, bottom: 16 + (this.inSmallWindow ? this.windowAvoidAreaNavigationRectHeight : 0) })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
  }

  private trySaveImportData(isSave: boolean) {
    Log.info(TAG, `saveImportData isSave ${isSave}`);
    if (this.isJumpToOtherPage) {
      Log.info(TAG, `saveImportData isJumpToOtherPage true`);
      return;
    }
    if (this.isHandleUserSaveAction) {
      Log.info(TAG, `saveImportData isHandleUserSaveAction true`);
      return;
    }
    this.isHandleUserSaveAction = true;
    this.isShowImportPage = false;
    if (!isSave) {
      ImportVcsCallBack.getInstance().save(false);
      let params: ReportHiEventParams = {
        IS_ACCOUNT: this.importData?.importType === ImportType.ACCOUNT_IMPORT ? 1 : 0
      }
      ReportUtil.reportBehaviorEvent(behaviorEvents.refuseShareAgendaOrAccount, params);
      return;
    }
    if (this.importData?.importType !== ImportType.ACCOUNT_IMPORT) {
      let simpleAccount: SimpleAccount = new SimpleAccount(this.checkedAccId);
      ImportVcsCallBack.getInstance().save(true, simpleAccount);
    } else {
      let simpleAccount: SimpleAccount = new SimpleAccount(this.simpleAccount.mAccountId,
        this.calendarDisplayName, this.accountColor, this.isInform);
      ImportVcsCallBack.getInstance().save(true, simpleAccount);
    }
    // 添加导入成功后跳转到最早日程的日期
    if (this.mHeadEvents && this.mHeadEvents.length > 0) {
      const beginTime2: number = Math.min(...this.mHeadEvents.map((item: AgendaEventInfo) => item.mBegin));
      GlobalData.instance().set(GlobalDataKeys.DISPLAY_DATE, beginTime2);
      emitter.emit({ eventId: CommonInnerEvent.DISPLAY_DATE_CHANGE });
    }
    this.isShowImportPage = false;
  }
}