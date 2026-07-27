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
  BigFontSize,
  CompId,
  DeviceConfig,
  EmptyUtils,
  FontSizeScaleUtils,
  GlobalThis,
  Log,
  ViewProxy
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AttachmentViewModel } from '../viewmodel/AttachmentViewModel';
import { AttachmentItemView } from './AttachmentItemView';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { i18n } from '@kit.LocalizationKit';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';
import { AttachmentErrorCode } from '../viewmodel/FileObj';
import { uniformTypeDescriptor } from '@kit.ArkData';

const TAG = 'AttachmentList';
const MAX_COUNT: number = 10;
const MAX_EXPAND_COUNT: number = 3;

@Component
export struct AttachmentList {
  //主题色
  @StorageProp('themeColor') themeColor: string = '';

  // 日程的uuid
  @Prop eventUuid: string;

  // 附件相关信息
  @Link attachmentViewModel: AttachmentViewModel;

  @State isShowAddAttachmentPage: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否在编辑态
  private isEditMode: boolean = false;

  // 是否在详情界面
  private isInDetailPage: boolean = false;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private canEdit: boolean = false;

  @Builder
  buildContent(context: ResourceStr): void {
    Column() {
      Text(context)
    }
  }

  @Builder
  buildAddButton() {
    Row() {
      Text($r('app.string.add_attachment'))
        .width('100%')
        .fontSize($r('sys.float.Subtitle_M'))
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColor)
        .textAlign(TextAlign.Start)
        .margin({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0),
          bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 0)
        })
    }
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .constraintSize({ minHeight: 48 })
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level6') : $r('sys.float.corner_radius_level8'))
    .id(CompId.ADD_AGENDA_ATTACHMENT)
    .onClick(async () => {
      this.addAttachment(this.themeColor);
    })
    .padding({ start: this.isChangeLayout() ? LengthMetrics.vp(12) : LengthMetrics.vp(8) })
  }

  getAttachmentMembers() {
    return GlobalThis.getPluralStr($r('app.plural.attachment_count'), this.attachmentViewModel?.attachmentCount,
      i18n.System.getSystemLanguage());
  }

  @Builder
  buildAttachmentListArrow() {
    Row() {
      Text(this.getAttachmentMembers())
        .align(Alignment.Start)
        .fontSize($r('sys.float.Body_M'))
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SPECIAL)
        .fontWeight(FontWeight.Medium)
        .margin({ end: LengthMetrics.vp(4) })

      SymbolGlyph($r('sys.symbol.chevron_right'))
        .rotate({ angle: this.attachmentViewModel?.attExpand ? -90 : 90 })
        .focusable(true)
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
        .borderRadius(22)
    }
    .visibility(this.attachmentViewModel?.attachmentCount > MAX_EXPAND_COUNT ? Visibility.Visible : Visibility.None)
  }

  @Builder
  buildAttachmentMemberRow() {
    Row() {
      Text($r('app.string.attachment_detail'))
        .align(Alignment.Start)
        .fontSize($r('sys.float.Body_M'))
        .id(CompId.ATTACHMENT_MEMBER)
      Blank()
      this.buildAttachmentListArrow();
    }
    .accessibilityLevel(this.attachmentViewModel?.attachmentCount > MAX_EXPAND_COUNT ? 'auto' : 'no')
    .accessibilityGroup(this.attachmentViewModel?.attachmentCount > MAX_EXPAND_COUNT)
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .opacity(0.6)
    .padding({
      left: $r('sys.float.padding_level6'),
      right: $r('sys.float.padding_level6'),
      top: this.needCommerce ? $r('sys.float.padding_level6') : 28,
      bottom: $r('sys.float.padding_level4')
    })
    .width('100%')
    .onClick(() => {
      if (this.attachmentViewModel?.attachmentCount > MAX_EXPAND_COUNT) {
        this.attachmentViewModel.attExpand = !this.attachmentViewModel.attExpand;
      }
    })
    .tabIndex(-1)
  }

  build() {
    Column() {
      this.buildAttachmentMemberRow();

      // 附件列表
      Stack({ alignContent: Alignment.TopStart }) {
        Column() {
          Column() {
            LazyForEach(this.attachmentViewModel?.dataSource, (item: AttachmentInfo, index: number) => {
              ListItem() {
                Column() {
                  AttachmentItemView({
                    attachmentTotal: this.attachmentViewModel?.attachmentCount ?? 0,
                    attachmentInfo: item,
                    isEditMode: this.isEditMode,
                    isInDetailPage: this.isInDetailPage,
                    onDelete: (): void => {
                      this.attachmentViewModel?.deleteAttachmentByIndex(index);
                    },
                    onPreview: (): void => {
                      this.previewAttachment(item);
                    }
                  })
                  // 列表项间的分割线，最后一个不展示
                  if (this.attachmentViewModel?.attachmentCount - 1 !== index) {
                    DividerLine()
                      .padding({ start: LengthMetrics.vp(56), end: LengthMetrics.vp(12) })
                  }
                }
              }
            }, (item: AttachmentInfo, index: number) => `${item.id}_${item.uuid}_${index}_${item.hashcode()}`);
          }
          .visibility(this.attachmentViewModel?.attExpand ? Visibility.Visible : Visibility.None)

          // 新增按钮与列表的分割线及按钮，仅编辑页展示
          if (this.canEdit) {
            // 收起或无附件时也不展示分割线
            DividerLine()
              .visibility(this.attachmentViewModel?.attachmentCount === 0 ||
                !this.attachmentViewModel?.attExpand ? Visibility.None : Visibility.Visible)
              .padding({ start: LengthMetrics.vp(10), end: LengthMetrics.vp(12) })
            this.buildAddButton();
          }
        }
      }
      .padding({
        left: 4,
        right: 4,
        top: 4,
        bottom: 4
      })
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level10'))
      // 不可编辑时，若收起列表，在这里控制展开收起。可编辑时因要展示新增按钮在内部控制
      .visibility((this.canEdit || this.attachmentViewModel?.attExpand) ? Visibility.Visible : Visibility.None)
    }
    .allowDrop((this.canEdit && this.attachmentViewModel?.attachmentCount < MAX_COUNT) ?
      [uniformTypeDescriptor.UniformDataType.FILE, uniformTypeDescriptor.UniformDataType.COMPOSITE_OBJECT,
        uniformTypeDescriptor.UniformDataType.MEDIA, uniformTypeDescriptor.UniformDataType.ARCHIVE] : null)
    .onDrop((dragEvent: DragEvent, extraParams?: string) => {
      this.fileOnDrop(dragEvent, extraParams);
    })
    .id(CompId.ATTACHMENT_LIST)
    // 详情页(即不可编辑时)，若附件列表为空，则不展示包含小标题在内的所有内容
    .visibility((!this.canEdit &&
      (this.attachmentViewModel?.attachmentCount === 0)) ? Visibility.None : Visibility.Visible)
  }

  async fileOnDrop(dragEvent: DragEvent, extraParams?: string) {
    const code = await this.attachmentViewModel?.fileOnDrop(dragEvent, extraParams);
    this.showToast(code);
  }

  async getAttachmentList() {
    if (this.attachmentViewModel?.attachmentCount > 0) {
      Log.info(TAG, `getAttachmentList count > 0  ${this.attachmentViewModel?.attachmentCount}`);
      return;
    }
    if (!(this.isInDetailPage || this.isEditMode)) {
      Log.info(TAG, `getAttachmentList not InDetailPage`);
      return;
    }
    if (EmptyUtils.isNotOrEmptyString(this.eventUuid)) {
      Log.info(TAG, `getAttachmentList isNotOrEmptyString eventUuid`);
      return;
    }
    await this.attachmentViewModel?.init(this.eventUuid);
    Log.info(TAG, `getAttachmentList size is ${this.attachmentViewModel?.attachmentCount}`);
  }

  async aboutToAppear() {
    this.viewProxy.aboutToAppear();
    this.getAttachmentList();
    this.canEdit = !this.isInDetailPage;
  }

  aboutToDisappear() {
    this.viewProxy.aboutToDisappear();
  }

  isChangeLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  private async previewAttachment(attachment: AttachmentInfo) {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const code = await this.attachmentViewModel?.previewAttachment(context, attachment);
    this.showToast(code);
  }

  private async addAttachment(themeColor: string) {
    const code =
      await this.attachmentViewModel?.addAttachment(
        this.getUIContext().getHostContext() as common.UIAbilityContext, themeColor);
    this.showToast(code);
  }

  private showToast(errCode: number) {
    if (errCode === AttachmentErrorCode.SUCCESS) {
      Log.info(TAG, 'is success no need showToast');
      return;
    }
    switch (errCode) {
      case AttachmentErrorCode.FAILED:
      case AttachmentErrorCode.PARAMS_ERROR:
      case AttachmentErrorCode.CREATE_DIR_FAILED:
      case AttachmentErrorCode.NO_PERMISSION:
      case AttachmentErrorCode.IO_EXCEPTION:
        showToast($r('app.string.file_save_failed'));
        break;
      case AttachmentErrorCode.STORAGE_FULL:
        showToast($r('app.string.memory_full_toast'));
        break;
      case AttachmentErrorCode.SIZE_OVER_LOAD:
        showToast($r('app.string.attachment_size_exceed', '100 MB'));
        break;
      case AttachmentErrorCode.ATTACHMENT_NOT_EXIST:
        showToast($r('app.string.attachment_not_exist'));
        break;
      case AttachmentErrorCode.MAX_COUNT:
        showToast($r('app.string.attachment_total_num_exceed', MAX_COUNT));
        break;
      case AttachmentErrorCode.MAX_SIZE:
        showToast($r('app.string.attachment_total_size_exceed', '1 G'));
        break;
      default:
        showToast($r('app.string.file_save_failed'));
        break;
    }
  }
}

export interface AddAttachmentInfo {
  resultCode: number;
  fileSize: number;
  fileName: string;
  filePath: string;
}

@Component
export struct DividerLine {
  build() {
    Divider()
      .height(1)
      .strokeWidth('1px')
      .color($r('sys.color.comp_divider'))
      .width('100%')
  }
}