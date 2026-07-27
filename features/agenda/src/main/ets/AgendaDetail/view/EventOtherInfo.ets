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
import { DeviceConfig, Log } from '@app/common';
import { DEFAULT_NUM, DEFAULT_STR } from '../../CreateAgenda/Constants';
import { Account } from './Account';
import { LengthMetrics } from '@kit.ArkUI';

const TAG = 'EventOtherInfo';

/**
 * 日程其他信息：帐户和说明
 */
@Component
export struct EventOtherInfo {
  // 帐户颜色
  @Prop accountColor: number = 0;

  // 帐户展示名
  @Prop accountDisName: ResourceStr = '';

  // 帐户描述
  @Prop description: string;

  @Prop mImportantEventType: number;

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  touchStart: Array<number> = [];

  private longPressGestureHandler(evt: TouchEvent) {
    if (evt.touches.length === 0) {
      return;
    }

    if (!evt.touches[0].displayX || !evt.touches[0].displayY) {
      return;
    }

    switch (evt.type) {
      case TouchType.Down:
        Log.info(TAG, `onTouch, Down`);
        AppStorage.setOrCreate('isInCopy', false);
        this.touchStart = [Date.now(), evt.touches[0].displayX, evt.touches[0].displayY];
        break;
      case TouchType.Move:
        const now = Date.now();
        const displayX = evt.touches[0].displayX;
        const displayY = evt.touches[0].displayY;

        const deltaTs = now - this.touchStart[0];
        const deltaX = Math.abs(displayX - this.touchStart[1]);
        const deltaY = Math.abs(displayY - this.touchStart[2]);

        // 模拟长按，同一个地方按压500ms
        if (deltaTs > 500 && deltaX < 5 && deltaY < 5) {
          Log.info(TAG, `onTouch, is LongPressGesture`);
          AppStorage.setOrCreate('isInCopy', true);
        }
        break;
      case TouchType.Up:
        Log.info(TAG, `onTouch, Up`);
        this.touchStart = [];
    }
  }

  build() {
    Column() {
      if (this.accountColor !== DEFAULT_NUM && this.accountDisName !== DEFAULT_STR && this.mImportantEventType === 0) {
        Account({
          accountColor: this.accountColor,
          accountDisName: this.accountDisName
        })
          .accessibilityLevel('yes')
          .accessibilityGroup(true)
      }

      if (this.description.length > 0) {
        Divider()
          .height(1)
          .padding({ left: 40 })
          .strokeWidth('1px')
          .opacity(0.6)
          .color($r('sys.color.comp_divider'))
          .width('100%')
          .visibility(this.mImportantEventType !== 0 ? Visibility.None : Visibility.Visible)
        Row() {
          SymbolGlyph($r('sys.symbol.doc_plaintext'))
            .fontSize(24)
            .margin({ end: LengthMetrics.vp(16) })
            .fontColor([$r('sys.color.icon_primary')])
            .opacity($r('sys.float.alpha_secondary'))
          Text(this.description)
            .fontSize($r('sys.float.Subtitle_M'))
            .lineHeight(22)
            .fontColor($r('sys.color.font_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .enableDataDetector(true)
            .copyOption(CopyOptions.LocalDevice)
        }
        .padding({ top: 16, bottom: 16 })
      }
    }
    .padding({
      left: 12,
      right: 12,
      top: 4,
      bottom: 4
    })
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('sys.float.corner_radius_level6'))
    .margin({ bottom: 12 })
    .onTouch((evt) => {
      // 触摸过程中已识别为长按，无需额外处理
      if (AppStorage.get('isInCopy') && evt.type === TouchType.Move) {
        Log.info(TAG, 'onTouch isInCopy and isMoving');
        return;
      }

      this.longPressGestureHandler(evt);
    })
  }
}