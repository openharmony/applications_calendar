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

import { BigFontSize, CompId, GlobalThis, Log } from '@app/common';
import { focusComponentById } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import { AttachmentInfo } from '@app/service.attachment/src/main/ets/entity/AttachmentInfo';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'AttachmentItemView'

//图片的通用属性
@Extend(Image)
function commonProperties() {
  .draggable(false)
}

@Component
export struct AttachmentItemView {
  @Prop attachmentInfo: AttachmentInfo;

  @Prop attachmentTotal: number;

  // 是否在编辑态
  @Prop isEditMode: boolean;

  // 是否在详情界面
  @Prop isInDetailPage: boolean;

  onDelete: () => void = (): void => {
  };

  onPreview: () => void = (): void => {
  };

  @Builder
  buildAttachment() {
    if (!this.isInDetailPage) {
      Row() {
        Button({ type: ButtonType.Normal, stateEffect: false }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize('16vp')
            .fontColor([$r('sys.color.ohos_fa_icon_fourth')])
            .margin({ start: LengthMetrics.vp(4) })
        }
        .accessibilityLevel('yes')
        .accessibilityText(GlobalThis.getResourceStr($r('app.string.delete_dialog_button')))
        .width(40)
        .height(40)
        .hitTestBehavior(HitTestMode.Block)
        .borderRadius($r('sys.float.corner_radius_level4'))
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.onDelete()
          // 只剩一个附件删除后，就聚焦到添加附件按钮
          if (this.attachmentTotal === 1) {
            focusComponentById(CompId.ADD_AGENDA_ATTACHMENT, 150);
          } else {
            focusComponentById(CompId.ADD_AGENDA_ATTACHMENT_ITEM, 150);
          }
        })
      }
    }
  }

  @Builder
  buildAvatar() {
    Row() {
      Image(FileUtils.getThumbnailByFileInfo(this.attachmentInfo?.displayName))
        .height(40)
        .width(40)
        .commonProperties()
        .margin({ end: LengthMetrics.vp(16) })

      Column() {
        Text(this.attachmentInfo.displayName)
          .textAlign(TextAlign.Start)
          .alignSelf(ItemAlign.Start)
          .fontSize($r('sys.float.Subtitle_M'))
          .fontColor($r('sys.color.font_primary'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(FileUtils.sizeConversion(this.attachmentInfo?.fileSize))
          .textAlign(TextAlign.Start)
          .alignSelf(ItemAlign.Start)
          .fontSize($r('sys.float.Subtitle_S'))
          .fontColor($r('sys.color.font_secondary'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
          .fontWeight(FontWeight.Regular)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
    }.layoutWeight(1)
  }

  build() {
    Column() {
      Row() {
        this.buildContent()
      }
      .hoverEffect(HoverEffect.Highlight)
      .borderRadius($r('sys.float.corner_radius_level8'))
      .stateStyles({
        pressed: {
          .backgroundColor($r('sys.color.interactive_click'))
        },
        normal: {
          .backgroundColor(Color.Transparent)
        }
      })
      .constraintSize({ minHeight: 56 })
      .onClick(() => {
        this.onPreview();
      })
      .accessibilityGroup(true)
      .accessibilityDescription(GlobalThis.getResourceStr($r('app.string.double_click_finger_execute')))
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .padding({ start: LengthMetrics.vp(8) })
    }
  }

  @Builder
  buildContent() {
    Row() {
      this.buildAvatar();
      this.buildAttachment();
    }
    .constraintSize({ minHeight: 64 })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .id(CompId.ADD_AGENDA_ATTACHMENT_ITEM)
  }
}