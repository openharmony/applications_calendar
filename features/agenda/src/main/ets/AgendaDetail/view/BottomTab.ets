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
  AccountUtils,
  AgendaEventInfo,
  AgendaTransitionUtil,
  behaviorEvents,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  ReportHiEventParams,
  ReportUtil,
  AgendaDeleteService,
  CalendarContract,
  CalendarService,
  CommonService,
  EventService,
  Log,
  CloudUtils,
  isSyncAbleAccount,
  ServiceManager,
  ServiceEnum,
  MIN_WINDOW_WIDTH_VP,
  CreateAgendaSheetFromPage,
} from '@app/common';
import { EditAgendaMenu } from '../../components/EditAgendaMenu';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { emitter } from '@kit.BasicServicesKit';
import { LengthUnit, PopoverOptions } from '@kit.ArkUI';
import lazy { PopoverDialog } from '@kit.ArkUI';
import { CommonTextDialog, TipsPopup } from '@app/common.components';
import { DeleteAgendaRadio, DeleteMode } from '../../components/DeleteAgendaRadio';
import { CreateAgendaPageSource } from '../../CreateAgenda/Constants';
import { CreatePopupContent } from '../../CreateAgenda/view/CreatePopupContent';

const TAG = 'BottomTab';

export enum EditAgendaType {
  ONLY_THIS = 0,
  THIS_AND_FOLLOWING = 1,
  ALL = 2,
}

@Component
export struct BottomTab {
  @Prop @Watch('infoChanged') info: AgendaEventInfo = new AgendaEventInfo();

  @Prop @Watch('displayStartMillsChanged') displayStartMills: number;

  @Prop @Watch('displayEndMillsChanged') displayEndMills: number;

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  @State agenda: AgendaEventInfo = new AgendaEventInfo();

  @State instanceStartMills: number = 0;

  @State instanceEndMills: number = 0;

  @State isFirstRepeatAgenda: boolean = false;

  @State isBirthDay: boolean = false;

  @Prop canEdit: boolean = false;

  @Prop isAcceptAgenda: boolean = false;

  //是否可分享
  @Prop canShare: boolean = false;

  @Link isEditMenuShow: boolean;

  // 多选是否启用
  @Prop selectable: boolean = false;

  // 记录选中数量改变之前的状态
  private prevSelectedCount: number = 0;

  // 多选选中的数量
  @Prop @Watch('onSelectedCountChange') selectedCount: number = 0;

  @State selectAll: boolean = false;

  @Prop showSelectAll: boolean = false;

  // 用于tips的参数
  @State shareTips: boolean = false;

  @State deleteTips: boolean = false;
  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private buttonWidth: number = this.needCommerce ? 48 : 40;

  private buttonHeight: number = this.needCommerce ? 48 : 40;

  private menuHeight: number = this.needCommerce ? 56 : 48;

  private symbolSize: number = this.needCommerce ? 24 : 20;

  private isCover: boolean = false;

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  onClickShare: () => void = (): void => {
  };

  onClickEdit: () => void = (): void => {
  };

  onClickDelete: () => void = (): void => {
  };

  @State isDeleteDialogShow: boolean = false;

  @State popoverOptions: PopoverOptions = {
    builder: () => {
      this.delContextBuilder();
    },
    placement: Placement.Bottom,
    autoCancel: false,
    width: 375,
    offset: { x: -24, y: -8 },
    popupColor: $r('sys.color.ohos_id_color_dialog_bg'),
    backgroundBlurStyle: BlurStyle.NONE
  };

  @State isNormalDialog: boolean = false;

  private agendaDeleteService: AgendaDeleteService | undefined = undefined;

  @State deleteAgenda: AgendaEventInfo | undefined = undefined; // 要删除的agenda

  private deleteTimestamp: number = -1; // 涉及删除的时间

  private deleteAccountType: string = '';

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  // 平板和折叠屏
  @State isMiddleWin: boolean = false;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  @StorageProp('themeColor') themeColor: string = '';

  @Link isEditPopupShow: boolean;

  @Link createPageData: emitter.EventData;

  // 关闭新建日程跟手弹窗时二次确认
  @State discardDialogInCreateAgendaPageFlag: boolean = false;

  @Link editTips: boolean;

  private isInDetailPop: boolean = false; // 是否处于详情子窗

  private jumpToPopEditPage: (intent: CreateAgendaPageSource) => void = (intent: CreateAgendaPageSource) => {
  }


  onWindowWidthChange() {
    // 折叠屏展开态 或者 PAD
    Log.info(TAG, `windowWidthChange: ${this.windowWidth}`);
    this.isMiddleWin = (this.windowWidth > MIN_WINDOW_WIDTH_VP) && !this.needCommerce;
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  aboutToAppear(): void {
    this.instanceStartMills = this.displayStartMills;
    this.instanceEndMills = this.displayEndMills;
    this.infoChanged();
    this.agendaTransitionUtil.showBottom = true;
    this.initService();
    this.onWindowWidthChange()
  }

  onSelectedCountChange() {
    if (this.selectedCount < this.prevSelectedCount) {
      this.selectAll = false; // 选中数目减少之后，取消全选
    }
    this.prevSelectedCount = this.selectedCount;
  }

  @Builder
  PopupComp(promptText: ResourceStr) {
    TipsPopup({ promptText: promptText })
  }

  @Builder
  shareBtn() {
    Button({ type: ButtonType.Circle }) {
      Column() {
        SymbolGlyph($r('sys.symbol.share'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(this.symbolSize))
          .fontColor([$r('sys.color.icon_primary')])
      }
    }
    .enabled(this.selectable ? this.selectedCount > 0 : true)
    .margin({ right: 4, left: 4 })
    .height(this.buttonHeight)
    .width(this.buttonWidth)
    .backgroundColor(Color.Transparent)
    .accessibilityText($r('app.string.agenda_menu_item_share'))
    .onClick(() => {
      this.onClickShare();
    })
    .onHover((isHover: boolean) => {
      this.shareTips = isHover;
    })
    .bindPopup(this.shareTips, {
      builder: this.PopupComp($r('app.string.agenda_menu_item_share')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: false
    })
    .id(CompId.ID_BT_AGENDA_DETAIL_SHARE_BOTTOM_BTN)
  }

  @Builder
  editBtn() {
    Button({ type: ButtonType.Circle }) {
      Column() {
        SymbolGlyph($r('sys.symbol.square_and_pencil'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(this.symbolSize))
          .fontColor([$r('sys.color.icon_primary')])
      }
    }
    .id(CompId.AGENDA_DETAIL_EDIT)
    .accessibilityText($r('app.string.agenda_menu_item_edit'))
    .margin({ right: 4, left: 4 })
    .height(this.buttonHeight)
    .width(this.buttonWidth)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.onClickEdit();
    })
    .bindMenu(this.isEditMenuShow, this.buildEditMenu(), {
      placement: Placement.Top,
      onDisappear: () => {
        this.isEditMenuShow = false;
      }
    })
    .onHover((isHover: boolean) => {
      this.editTips = !this.isEditMenuShow && isHover;
    })
    .bindPopup(this.editTips, {
      builder: this.PopupComp($r('app.string.agenda_menu_item_edit')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: false,
      placement: Placement.Top
    })
    .bindSheet($$this.isEditPopupShow, this.buildCreatePopup(), {
      height: SheetSize.LARGE,
      detents: [SheetSize.LARGE, 0, 0],
      dragBar: false,
      showClose: false,
      preferType: SheetType.POPUP,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      enableOutsideInteractive: false,
     // keyboardAvoidMode: SheetKeyboardAvoidMode.RESIZE_ONLY,
      maskColor: $r('sys.color.ohos_id_color_mask_thin'),
      shouldDismiss: ((sheetDismiss: SheetDismiss) => {
        this.discardDialogInCreateAgendaPageFlag = !this.discardDialogInCreateAgendaPageFlag;
      })
    })
  }

  @Builder
  buildCreatePopup() {
    Column() {
      CreatePopupContent({
        createPageData: this.createPageData,
        discardDialogInCreateAgendaPageFlag: this.discardDialogInCreateAgendaPageFlag,
        onCreatePageDismiss: () => {
          this.isEditPopupShow = false;
          this.createPageData = {
            data: {
              fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE
            }
          }
        },
        setFullWidth: true
      })
    }
    .width('100%')
    .height('100%')
  }


  // 编辑按钮菜单
  @Builder
  buildEditMenu() {
    EditAgendaMenu({
      isFirstRepeatAgenda: this.isFirstRepeatAgenda,
      editThisAgenda: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_THIS_AGENDA);
        let param: ReportHiEventParams = {
          TYPE: EditAgendaType.ONLY_THIS
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
      },
      editThisAgendaAndBeyond: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_THIS_AGENDA_AND_BEYOND);
        let param: ReportHiEventParams = {
          TYPE: EditAgendaType.THIS_AND_FOLLOWING
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
      },
      onClickEdit: () => {
        this.menuJumpToEditPage(CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE);
        let param: ReportHiEventParams = {
          TYPE: EditAgendaType.ALL
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.editRepeatedAgenda, param);
      }
    })
  }

  @Builder
  deleteBtn() {
    Button({ type: ButtonType.Circle }) {
      Column() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(this.symbolSize))
          .fontColor([$r('sys.color.icon_primary')])
      }
    }
    .id(CompId.AGENDA_DETAIL_DELETE)
    .accessibilityText($r('app.string.agenda_menu_item_delete'))
    .enabled(this.selectable ? this.selectedCount > 0 : true)
    .margin({ right: 4, left: 4 })
    .height(this.buttonHeight)
    .width(this.buttonWidth)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      if (!this.isMiddleWin) {
        this.onClickDelete();
      } else {
        this.clickDelete();
      }
    })
    .onHover((isHover: boolean) => {
      this.deleteTips = isHover;
    })
    .bindPopup(this.deleteTips, {
      builder: this.PopupComp($r('app.string.agenda_menu_item_delete')),
      popupColor: $r('sys.color.ohos_id_color_card_bg'),
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: ShadowStyle.OUTER_DEFAULT_SM,
      mask: false,
      enableArrow: false
    })
  }

  @Builder
  multiSelectButton() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        SymbolGlyph(this.selectAll ? $r('sys.symbol.checkmark_square_on_square_fill') :
                                      $r('sys.symbol.checkmark_square_on_square'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(24))
          .fontColor([this.selectAll ? this.themeColor : $r('sys.color.icon_primary')])
        Text($r('app.string.multiple_choice'))
          .margin({ top: 3 }).fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
    }
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ left: 2 })
    .layoutWeight(1)
    .backgroundColor($r('sys.color.background_secondary'))
    .stateEffect(false) // 取消按压态
    .onClick(() => {
      this.selectAll = !this.selectAll;
      if (this.selectAll) {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, { data: { 'selectAll': true } }) // 全选
      } else {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, { data: { 'selectAll': false } }) // 反全选
      }
    })
    .height('100%')
  }

  @Builder
  delContextBuilder() {
    if (!this.isNormalDialog) {
      Column() {
        DeleteAgendaRadio({
          confirm: (checkValue) => {
            if (!this.deleteAgenda) {
              return;
            }
            if (checkValue === DeleteMode.ONLY_THIS_AGENDA) {
              this.agendaDeleteService?.addExclusiveToRepeatRule(this.deleteAgenda?.mId, this.deleteTimestamp);
            } else if (checkValue === DeleteMode.THIS_AND_FUTURE_AGENDA) {
              this.agendaDeleteService?.updateEndTime(this.deleteAgenda?.mId, this.deleteTimestamp);
            } else {
              this.agendaDeleteService?.deleteEvent(this.deleteAgenda.mId);
            }
            this.isDeleteDialogShow = false;
          },
          showCloudSyncTip: isSyncAbleAccount('', this.deleteAccountType) &&
          CloudUtils.isSupportCloudSync() && CloudUtils.isCloudSyncOpened(),
          title: this.agendaDeleteService?.getDeleteAgendaDialogTitle(this.deleteAgenda?.mTitle || ''),
          isFirstRepeatAgenda: this.deleteAgenda?.mBegin === this.deleteTimestamp,
          cancel: () => {
            this.isDeleteDialogShow = false;
          }
        });
      }
      .padding({ top: 16 });
    } else {
      CommonTextDialog({
        message: this.agendaDeleteService?.getDeleteMessage(this.deleteAgenda, this.deleteAccountType),
        cancelText: $r('app.string.cancel_dialog_button'),
        confirmText: $r('app.string.delete_dialog_button'),
        isConfirmWarning: true,
        onConfirmClick: () => {
          this.isDeleteDialogShow = false;
          if (!this.deleteAgenda) {
            return;
          }
          this.agendaDeleteService?.deleteEvent(this.deleteAgenda?.mId);
        },
        onCancelClick: () => {
          Log.info(TAG, 'click cancel');
          this.isDeleteDialogShow = false;
        },
        marginStyle: { left: 0, right: 0, bottom: 0 }
      });
    }
  }

  async initService() {
    this.agendaDeleteService =
      await ServiceManager.getInstance().getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE);
  }

  clickDelete() {
    this.isDeleteDialogShow = true;
    const eventId = this.agenda.mId;
    EventService.INSTANCE.queryEventById(eventId).then(async (event) => {
      if (event) {
        let accounts = await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
        let accountMap = CommonService.INSTANCE.getAccountMap(accounts);
        this.deleteAccountType = accountMap.get(event.mCalendarId).accountType;
        this.deleteAgenda = event;
        this.deleteTimestamp = this.displayStartMills || 0;
        Log.info(TAG, `delete agenda page ${this.deleteAgenda.mId}-${this.deleteTimestamp}-${this.deleteAccountType}`);
        if (event.isRepeatEvent() && !event.isImportantEvent()) {
          this.isNormalDialog = false;
        } else {
          this.isNormalDialog = true;
        }
      }
    });
  }

  build() {
    Row() {
      if (this.info.isSupportShare()) {
        this.shareBtn();
      }

      if (this.canEdit && !this.isAcceptAgenda && !this.isBirthDay) {
        this.editBtn();
      }

      if (!this.isAcceptAgenda && !this.isBirthDay) {
        if (!this.isMiddleWin) {
          this.deleteBtn();
        } else {
          PopoverDialog({
            visible: this.isDeleteDialogShow,
            popover: this.popoverOptions,
            targetBuilder: () => {
              this.deleteBtn();
            }
          });
        }
      }

      if (this.showSelectAll) {
        this.multiSelectButton();
      }
    }
    .height(this.menuHeight)
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .shadow(ShadowStyle.OUTER_DEFAULT_XS)
    .borderRadius($r('sys.float.corner_radius_level16'))
    .flexShrink(0)
    .visibility(!this.isCover || this.agendaTransitionUtil.showBottom ? Visibility.Visible : Visibility.None)
    .position({
      start: { value: 0.5, unit: LengthUnit.PERCENT },
      bottom: { value: 16 +
        (this.needCommerce ? 0 : this.windowAvoidAreaNavigationRectHeight),
        unit: LengthUnit.VP },
    })
    .id(CompId.BOX_BOTTOM_TAB)
    .markAnchor({ start: {value: 0.5, unit: LengthUnit.PERCENT}, top: {value: 0, unit: LengthUnit.VP}})
  }

  private infoChanged() {
    this.agenda = this.info;
    this.isBirthDay = AccountUtils.isBirthDayAccountById(this.info.mCalendarId);
    this.changeFirstRepeatAgendaFlag();
  }

  private displayStartMillsChanged() {
    this.instanceStartMills = this.displayStartMills;
    this.changeFirstRepeatAgendaFlag();
  }

  private displayEndMillsChanged() {
    this.instanceEndMills = this.displayEndMills;
  }

  private changeFirstRepeatAgendaFlag() {
    if (!this.agenda.isRepeatEvent()) {
      this.isFirstRepeatAgenda = false;
      return;
    }
    if (this.agenda.mBegin === this.instanceStartMills) {
      this.isFirstRepeatAgenda = true;
      return;
    }
    this.isFirstRepeatAgenda = false;
  }

  private menuJumpToEditPage(intent: CreateAgendaPageSource) {
    if (this.isInDetailPop) {
      this.jumpToPopEditPage(intent);
      return;
    }
    this.createPageData = {
      data: {
        eventInfo: JSON.stringify(this.agenda),
        intent: intent,
        fromPage: CreateAgendaSheetFromPage.AGENDA_LIST_PAGE,
        instanceStartMills: intent === CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE ? undefined :
        this.instanceStartMills,
        instanceEndMills: intent === CreateAgendaPageSource.EDIT_CREATE_AGENDA_PAGE ? undefined : this.instanceEndMills,
      }
    };
    this.isEditPopupShow = true;
    this.isEditMenuShow = false;
  }
}