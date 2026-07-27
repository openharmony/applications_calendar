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
  BackgroundId,
  EventMode,
  ImportantCardConfig,
  LayoutId
} from '@app/common/src/main/ets/card/ImportantCardConfig';
import { Log } from '@app/common';
import { layout2x2, unknownImportantCard2x2 } from '../pages/ImportantCardView2x2';
import { layout2x4, unknownImportantCard2x4 } from '../pages/ImportantCardView2x4';
import { ImportantCardComponentId } from '../../model/ImportantCardComponentId';
import lazy { ImageUtils } from '../../util/ImageUtils';
import { AreaInfo } from '../../util/ImageUtils';
import { image } from '@kit.ImageKit';
import { CardUiUtils } from '../../util/CardUiUtils';

const TAG: string = 'ImportantCardPreview';

/**
 * 卡片编辑预览组件
 */
@Component
export struct ImportantCardPreview {
  @Link @Watch('onFormConfigChange') formConfig: ImportantCardConfig;

  @Link isCard2x2: boolean;

  @Link title: Resource | string;

  @Link attachmentCount: number;

  @Prop date: number;

  @Link unit: Resource;

  @Link rrule: string;

  @Link yearOffset: number;

  @Link remainingDays: number;

  @Link type: string;

  @Link dayOffset: number;

  @Link formWidth: number;

  @Link formHeight: number;

  @Link eventCalendarType: number;

  @Prop language: string;

@State oldLayoutId: LayoutId = this.formConfig.layoutId;

private currentPixelMap: image.PixelMap | undefined;

aboutToDisappear(): void {
  this.onDestroy();
}

  onFormConfigChange() {
    // 版式变化
    if (this.oldLayoutId !== this.formConfig.layoutId) {
      this.oldLayoutId = this.formConfig.layoutId;
    }
  }

  build() {
    Column() {
      Stack() {
        Stack() {
          this.CardBg();
        }
        .width(this.formWidth)
        .height(this.formHeight)
        .borderRadius($r('sys.float.ohos_id_card_border_radius'))
        .clip(true)
        .id(ImportantCardComponentId.IMPORTANT_CARD_VIEW_BG)

        this.CardText()
      }
      .width(this.formWidth)
      .height(this.formHeight)
      .borderRadius($r('sys.float.ohos_id_card_border_radius'))
      .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
  }

  onDestroy() {
    if (this.currentPixelMap) {
      this.currentPixelMap.release();
      this.currentPixelMap = undefined;
    }
  }

  @Builder
  CardBg() {
    if (this.formConfig.backgroundId === BackgroundId.CUSTOMIZE) {
      // 自定义背景模式，预览上次设置的自定义图片效果
      Image(this.getCustomizeBackground())
        .objectFit(ImageFit.Cover)
    } else {
      // 非自定义背景模式，走原预览逻辑
      Image(CardUiUtils.getBackgroundById(this.formConfig.backgroundId, this.formConfig.texturesId, this.isCard2x2))
        .objectFit(this.formConfig.backgroundId === BackgroundId.TEXTURES ? ImageFit.None : ImageFit.Cover)
    }
  }

  @Builder
  CardText() {
    Column() {
      if (this.isCard2x2) {
        if (this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
          unknownImportantCard2x2();
        } else {
          layout2x2({
            title: this.title,
            date: this.date,
            eventCalendarType: this.eventCalendarType,
            rrule: this.rrule,
            yearOffset: this.yearOffset,
            remainingDays: this.remainingDays,
            dayOffset: this.dayOffset,
            type: this.type,
            backgroundId: this.formConfig.backgroundId,
            fontId: this.formConfig.fontId,
            color: this.formConfig.color,
            _opacity: this.formConfig.opacity,
            topBright: this.formConfig.topBright,
            bottomBright: this.formConfig.bottomBright,
            isEdit: true,
            layout: this.formConfig.layoutId,
            language: this.language,
            attachmentCount: this.attachmentCount,
          });
        }
      } else {
        if (this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
          unknownImportantCard2x4();
        } else {
          layout2x4({
            title: this.title,
            date: this.date,
            eventCalendarType: this.eventCalendarType,
            rrule: this.rrule,
            yearOffset: this.yearOffset,
            remainingDays: this.remainingDays,
            dayOffset: this.dayOffset,
            type: this.type,
            backgroundId: this.formConfig.backgroundId,
            fontId: this.formConfig.fontId,
            color: this.formConfig.color,
            _opacity: this.formConfig.opacity,
            topBright: this.formConfig.topBright,
            bottomBright: this.formConfig.bottomBright,
            isEdit: true,
            layout: this.formConfig.layoutId,
            language: this.language,
            attachmentCount: this.attachmentCount,
          });
        }
      }
    }.width(this.formWidth)
    .height(this.formHeight)
    .padding($r('sys.float.padding_level6'))
  }

  private getCustomizeBackground(): image.PixelMap | undefined {
    // 释放旧的PixelMap实例
    if (this.currentPixelMap) {
      this.currentPixelMap.release();
      this.currentPixelMap = undefined;
    }
    const path = ImageUtils.getImportantImagePath(this.formConfig.customizeImgPath);
    if (!path || path.length === 0) {
      return undefined;
    }
    const newPixelMap = ImageUtils.getPixelMapByPath(path);
    if (newPixelMap) {
      this.currentPixelMap = newPixelMap;
    }
    return newPixelMap;
  }
}