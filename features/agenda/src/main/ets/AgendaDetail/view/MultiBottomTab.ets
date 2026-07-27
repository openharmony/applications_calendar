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
  CommonInnerEvent,
  CompId,
  FontSizeScaleUtils,
  CloudUtils,
  ReportHiEventParams,
  ReportUtil,
  HiEventParamsConfirm,
  behaviorEvents,
  Log,
  MIN_WINDOW_WIDTH_VP,
  DeviceConfig
} from '@app/common';
import { emitter } from '@kit.BasicServicesKit';
import { PopoverDialog, PopoverOptions } from '@kit.ArkUI';
import { CommonTextDialog } from '@app/common.components';
import { AgendaListLocation } from '@app/common/src/main/ets/default/util/ReportUtil';
import { broadcastSelectStatus } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG = 'MultiBottomTab';

export enum EditAgendaType {
  ONLY_THIS = 0,
  THIS_AND_FOLLOWING = 1,
  ALL = 2,
}

@Component
export struct MultiBottomTab {
  @Prop isAcceptAgenda: boolean = false;

  //是否可分享
  @Prop canShare: boolean = false;

  // 多选是否启用
  @Prop selectable: boolean = false;

  // 记录选中数量改变之前的状态
  private prevSelectedCount: number = 0;

  // 是否需要外边距
  private isNeedMargin: boolean = false;

  // 多选选中的数量
  @Prop @Watch('onSelectedCountChange') selectedCount: number = 0;

  @State selectAll: boolean = false;

  @Prop showSelectAll: boolean = false;

  @Prop allAgendaCount: number = 0;

  // 分享的viewId
  private shareAnchorViewId: string = 'multi_bottom_tab_share_btn';

  onClickShare: () => void = (): void => {
  };

  onClickDelete: () => void = (): void => {
  };

  confirmMutiDel: () => void = (): void => {
  };

  @State isDeleteDialogShow: boolean = false;

  @State popoverOptions: PopoverOptions = {
    builder: () => {
      if (this.selectedCount <= 0) {
        return;
      }
      this.delContextBuilder();
    },
    placement: Placement.Bottom,
    autoCancel: false,
    width: 375,
    offset: { x: 24, y: -8 },
    popupColor: $r('sys.color.ohos_id_color_dialog_bg'),
    backgroundBlurStyle: BlurStyle.NONE
  };

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 平板和折叠屏
  @State isMiddleWin: boolean = false;

  @Prop selectAllButtonAvailable: boolean = false;

  @StorageProp('themeColor') themeColor: string = '';

  onWindowWidthChange() {
    // 折叠屏展开态 或者 PAD
    Log.info(TAG, `windowWidthChange: ${this.windowWidth}`);
    this.isMiddleWin = (this.windowWidth > MIN_WINDOW_WIDTH_VP) && !this.needCommerce;
  }

  aboutToAppear(): void {
    this.onWindowWidthChange();
  }

  onSelectedCountChange() {
    if (this.selectedCount < this.prevSelectedCount) {
      this.selectAll = false; // 选中数目减少之后，取消全选
    }
    if (this.selectedCount === this.allAgendaCount && this.allAgendaCount > 0) {
      this.selectAll = true; // 查询过全部日程，并且选中的日程数目等于全部日程数目时，全选被点亮
    }
    this.prevSelectedCount = this.selectedCount;
  }

  @Builder
  shareBtn() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        SymbolGlyph($r('sys.symbol.share'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(24))
          .fontColor([$r('sys.color.icon_primary')])
        Text($r('app.string.agenda_menu_item_share'))
          .margin({ top: 2 })
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
    }
    .id(CompId.AGENDA_DETAIL_MULTI_SHARE)
    .enabled(this.selectedCount > 0 && this.canShare)
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ right: 2 })
    .layoutWeight(1)
    .backgroundColor(Color.Transparent)
    .stateEffect(false) // 取消按压态
    .onClick(() => {
      this.onClickShare();
    })
    .id(this.shareAnchorViewId)
    .margin({ top: 12, bottom: 4})
  }

  @Builder
  deleteBtn() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(24))
          .fontColor([$r('sys.color.icon_primary')])
        Text($r('app.string.delete_label'))
          .margin({ top: 2 }).fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
    }
    .id(CompId.AGENDA_DETAIL_MULTI_DELETE)
    .enabled(this.selectable ? this.selectedCount > 0 : true)
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ left: 2 })
    .layoutWeight(1)
    .backgroundColor(Color.Transparent)
    .stateEffect(false) // 取消按压态
    .onClick(() => {
      if (!this.isMiddleWin) {
        this.onClickDelete();
      } else {
        this.clickDelete();
      }
    })
    .margin({ top: 12, bottom: 4})
  }

  @Builder
  multiSelectButton() {
    Button({ type: ButtonType.Normal }) {
      Column() {
        SymbolGlyph(this.selectAll ? $r('sys.symbol.checkmark_square_on_square_fill') :
        $r('sys.symbol.checkmark_square_on_square'))
          .fontSize(FontSizeScaleUtils.fontSizeNumToVp(24))
          .fontColor([this.selectAll ? this.themeColor : $r('sys.color.icon_primary')])
        Text($r('app.string.select_all'))
          .margin({ top: 2 }).fontSize(FontSizeScaleUtils.fontSizeNumToVp(10))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
    }
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ left: 2 })
    .layoutWeight(1)
    .backgroundColor(Color.Transparent)
    .stateEffect(false) // 取消按压态
    .onClick(() => {
      this.selectAll = !this.selectAll;
      if (this.selectAll) {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, { data: { 'selectAll': true } }) // 全选
      } else {
        emitter.emit({ eventId: CommonInnerEvent.EVENT_UPDATE_MULTI_SELECTED }, { data: { 'selectAll': false } }) // 反全选
      }
      broadcastSelectStatus(this.selectAll);
    })
    .margin({ top: 12, bottom: 4})
    .id(CompId.AGENDA_MUTI_SELECT_BTN)
    .enabled(this.selectAllButtonAvailable)
    .accessibilityText(!this.selectAll ? $r('app.string.select_all') : $r('app.string.deselect_all'))
  }

  @Builder
  delContextBuilder() {
    CommonTextDialog({
      title: CloudUtils.isCloudSyncOpened() ? $r('app.plural.delete_multiple_selected_count_msg',
        this.selectedCount, this.selectedCount) : '',
      message: CloudUtils.isCloudSyncOpened() ? $r('app.string.delete_with_cloudDevices') :
      $r('app.plural.delete_multiple_selected_count_msg', this.selectedCount, this.selectedCount),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: (): void => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.AgendaListView,
          ACTION: HiEventParamsConfirm.TRUE
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        this.confirmMutiDel();
        this.isDeleteDialogShow = false;
      },
      onCancelClick: () => {
        let params: ReportHiEventParams = {
          FROM_TYPE: AgendaListLocation.AgendaListView,
          ACTION: HiEventParamsConfirm.FALSE
        };
        ReportUtil.reportBehaviorEvent(behaviorEvents.agendaMultiDelete, params);
        this.isDeleteDialogShow = false;
        Log.info(TAG, 'click cancel');
      },
      marginStyle: { left: 0, right: 0, bottom: 0 }
    });
  }

  clickDelete() {
    this.isDeleteDialogShow = true;
  }

  build() {
    Row() {
      this.shareBtn();

      if (!this.isAcceptAgenda) {
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
    .height(52)
    .padding({ left: 24, right: 24 })
    .margin({ bottom: this.isNeedMargin ? 28 : 0 })
  }
}