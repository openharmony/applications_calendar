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
  DeviceConfig,
  DialogControllerOptions,
  EventService,
  GlobalData,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ReportUtil,
  ServiceEnum,
  ServiceManager,
  statisticEvents
} from '@app/common';
import { CommonTextDialog } from '@app/common.components';
import { DeleteEventProcessor } from '../agenda/DeleteEventProcessor';
import { SelectEventInfo } from '../agenda/SelectEventInfo';
import { HiEventParamsConfirm, ReportHiEventParams } from '@app/common/src/main/ets/default/util/ReportUtil';
import { ExportVcsCallBack, ImportExportService } from '@app/feature.importexport';

const TAG: string = 'DeleteToolBar';

//日程通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

/**
 * 删除列表 toolbar
 *
 * @since 2022-09-28
 */
@Component
export struct DeleteToolBar {
  // 选中日程id值
  @StorageLink('checkEventId') checkEventId: number = -1;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @Link @Watch('onListDataChange') datas: SelectEventInfo[];

  dataProcessor: DeleteEventProcessor = new DeleteEventProcessor();

  @State allSelect: boolean = false;

  @State selectEventCount: number = 0;

  // 删除样式hover态颜色值
  @State deleteHoverColor: Resource = $r('app.color.default_background');

  // 多选样式增加hover态颜色值
  @State AllSelectHoverColor: Resource = $r('app.color.default_background');

  @State ShareAgendaColor: Resource = $r('app.color.default_background');

  deleteDialogController: CustomDialogController | null = new CustomDialogController({
    builder: CommonTextDialog({
      message: $r('app.plural.delete_multiple_selected_count_msg',
        this.getSelectEventCount(), this.getSelectEventCount()),
      cancelText: $r('app.string.cancel_dialog_button'),
      confirmText: $r('app.string.delete_dialog_button'),
      isConfirmWarning: true,
      onConfirmClick: () => {
        this.deleteSelectEvent();
      },
      onCancelClick: () => {
        Log.info(TAG, 'no delete');
      }
    }),
    alignment: this.dialogControllerOptions.alignment,
    offset: this.dialogControllerOptions.offset,
    autoCancel: this.dialogControllerOptions.autoCancel,
    customStyle: this.dialogControllerOptions.customStyle
  });

  private shareAnchorViewId: string = 'iv_delete_share';

  onDeleteSuccess: () => void = (): void => {
  };

  onClickAllSelect: (isAllSelect: boolean) => void = (isAllSelect: boolean): void => {
  };

  aboutToDisappear(): void {
    this.deleteDialogController = null;
  }

  onListDataChange() {
    this.selectEventCount = this.dataProcessor.getSelectedEvents().size;
    this.allSelect = this.selectEventCount === this.dataProcessor.getEventContentSize();
  }

  build() {
    Row() {
      Column() {
        ShareAgendaItem()
      }
      .borderRadius(8)
      .layoutWeight(1)
      .backgroundColor(this.ShareAgendaColor)
      .enabled(this.selectEventCount != 0)
      .onHover((isHover: boolean | undefined) => {
        this.ShareAgendaColor = isHover ? $r('app.color.hover_background') : $r('app.color.default_background');
      })
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .id(this.shareAnchorViewId)
      .opacity(this.selectEventCount === 0 ? 0.4 : 1)
      .onClick(() => {
        this.shareEventVcs(Array.from(this.dataProcessor.getSelectedEvents()));
        GlobalThis.getInstance().shareAnchorViewId = this.shareAnchorViewId;
      })

      Column() {
        ToolbarItem({ imageRes: $r('sys.symbol.trash'), itemText: $r('app.string.delete_label') })
      }
      .borderRadius(8)
      .layoutWeight(1)
      .enabled(this.selectEventCount != 0)
      .backgroundColor(this.deleteHoverColor)
      .onHover((isHover: boolean | undefined) => {
        this.deleteHoverColor = isHover ? $r('app.color.hover_background') : $r('app.color.default_background');
      })
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .opacity(this.selectEventCount === 0 ? 0.4 : 1)
      .onClick(() => {
        this.showDeleteDialog();
        ReportUtil.reportStatisticEvent(statisticEvents.agendaPressClickDelete);
      })

      Column() {
        SelectMenuItem({ selectAll: this.allSelect })
      }
      .backgroundColor(this.AllSelectHoverColor)
      .onHover((isHover: boolean | undefined) => {
        this.AllSelectHoverColor = isHover ? $r('app.color.hover_background') : $r('app.color.default_background');
      })
      .onClick(() => {
        this.allSelect = !this.allSelect;
        Log.info(TAG, `this.allSelect = ${this.allSelect}`);
        this.onClickAllSelect(this.allSelect);
        let params: ReportHiEventParams = {
          IS_ON: this.allSelect ? HiEventParamsConfirm.TRUE : HiEventParamsConfirm.FALSE
        }
        ReportUtil.reportStatisticEvent(statisticEvents.agendaPressSelectAll);
      })
      .borderRadius(8)
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .layoutWeight(1)
    }
    .height(56)
    .padding({ left: 24, right: 24 })
  }

  async deleteSelectEvent() {
    Log.info(TAG, 'to do deleteSelectEvent');
    let selectEvents: Set<number> = this.dataProcessor.getSelectedEvents();
    const rowsDeleted: number = await EventService.INSTANCE.deleteEvents(selectEvents) as number;
    if (rowsDeleted > 0) {
      if (selectEvents.has(this.checkEventId)) {
        GlobalData.instance().set(GlobalDataKeys.CHECK_EVENT_ID, -1);
      }
      this.dataProcessor.getSelectedEvents().clear();
      this.onDeleteSuccess();
    } else {
      Log.warn(TAG, 'deleteEvent fail');
    }
  }

  getSelectEventCount(): number {
    return this.dataProcessor.getSelectedEvents().size;
  }

  showDeleteDialog() {
    this.deleteDialogController?.open();
  }

  // VCS格式分享
  private async shareEventVcs(eventIds: number[]) {
    let service = await ServiceManager.getInstance()
      .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
    service?.exportVcsByEvents(eventIds, new ExportVcsCallBack(), true);
  }
}

@Component
struct ShareAgendaItem {
  imageRes: Resource = $r('sys.symbol.share');

  itemText: ResourceStr = $r('app.string.agenda_menu_item_share');

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  build() {
    Column() {
      SymbolGlyph(this.imageRes)
        .fontSize(24)
      Text(this.itemText as ResourceStr).fontSize(10).fontWeight(FontWeight.Medium)
    }
  }
}

@Component
struct ToolbarItem {
  imageRes: Resource | null = null;

  itemText: ResourceStr | null = null;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  build() {
    Column() {
      SymbolGlyph(this.imageRes)
        .fontSize(24)
      Text(this.itemText as ResourceStr).fontSize(10).fontWeight(FontWeight.Medium)
    }
  }
}

@Component
struct SelectMenuItem {
  @Watch('changeIconText') @Prop selectAll: boolean | null = null;

  @State imageRes: Resource = $r('sys.symbol.checkmark_square_on_square');

  @State itemText: Resource = $r('app.string.select_all');

  @State textColor: string = '#000000';

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  build() {
    Column() {
      SymbolGlyph(this.imageRes)
        .fontSize(24)
        .fontColor([this.textColor])
      Text(this.itemText).fontSize(10).fontWeight(FontWeight.Medium).fontColor(this.textColor);
    }
  }

  changeIconText() {
    Log.info(TAG, `change Icon text: ${this.selectAll}`);
    if (this.selectAll) {
      this.imageRes = $r('sys.symbol.checkmark_square_on_square_fill');
      this.itemText = $r('app.string.deselect_all');
      this.textColor = '#0a59f7';
    } else {
      this.imageRes = $r('sys.symbol.checkmark_square_on_square');
      this.itemText = $r('app.string.select_all');
      this.textColor = '#000000';
    }
  }
}