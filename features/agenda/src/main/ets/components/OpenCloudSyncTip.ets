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
  CloudUtils,
  CompId,
  DAY_PER_WEEK,
  FoldScreenType,
  GlobalDataKeys,
  Log,
  MILLS_PER_DAY,
  PreferencesFiles,
  PreferencesUtil
} from '@app/common';
import { addButtonTypeText } from '@app/common/src/main/ets/util/AccessibilityUtil';

const TAG: string = 'OpenCloudSyncTip';

const KEY_LAST_IGNORE_SYNC_TIP: string = 'lastIgnoreSyncTipTime';

// 记录用户点击不提醒的次数
const KEY_IGNORE_COUNT: string = 'ignoreSyncTipCount';

// 用户点击不提醒超过3次后，每2周提醒一次，低于3次时每一周提醒一次
const IGNORE_COUNT_THRESHOLD: number = 3;

const SHOW_TIP_GAP_ONE_WEEK: number = DAY_PER_WEEK * MILLS_PER_DAY;

const SHOW_TIP_GAP_TWO_WEEK: number = 2 * DAY_PER_WEEK * MILLS_PER_DAY;

/**
 * 云同步开关开启提示tip
 */
@Component
export struct OpenCloudSyncTip {
  @StorageProp('themeColor') themeColor: string = '';

  @State canShowTip: boolean = false;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private isUpFoldScreen: boolean =
    AppStorage.get(GlobalDataKeys.FOLD_SCREEN_TYPE) === FoldScreenType.SMALL_UP_DOWN_FOLD;

  aboutToAppear() {
    this.calculateCanShowTip();
  }

  @Builder
  TextButton() {
    Text($r('app.string.open_ignore'))
      .fontSize($r('sys.float.Body_M'))
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
      .fontColor(this.themeColor)
      .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
      .margin({
        left: $r('sys.float.ohos_id_dialog_muti_button_padding_start'),
        right: $r('sys.float.ohos_id_dialog_muti_button_padding_end')
      })
      .stateStyles({
        normal: {.backgroundColor(null)
        },
        pressed: {.backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .accessibilityText(addButtonTypeText($r('app.string.open_ignore')))
      .onClick(this.onIgnoreClick);

    Text($r('app.string.open_agree'))
      .fontSize($r('sys.float.Body_M'))
      .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
      .fontColor(this.themeColor)
      .fontFamily($r('sys.string.ohos_id_text_font_family_medium'))
      .margin({
        left: $r('sys.float.ohos_id_dialog_muti_button_padding_start'),
        right: $r('sys.float.ohos_id_dialog_muti_button_padding_end')
      })
      .stateStyles({
        normal: {.backgroundColor(null)
        },
        pressed: {.backgroundColor($r('sys.color.interactive_click'))
        }
      })
      .accessibilityText(addButtonTypeText($r('app.string.open_agree')))
      .onClick(this.onOpenSyncClick);
  }

  build() {
    if (this.canShowTip) {
      Column() {
        Text($r('app.string.sync_tip_title'))
          .width('100%')
          .fontSize($r('sys.float.Body_M'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
          .fontColor($r('sys.color.font_primary'))
          .opacity($r('sys.float.alpha_primary'))
          .fontFamily($r('sys.string.ohos_id_text_font_family_medium'));

        Text($r('app.string.sync_tip_content'))
          .width('100%')
          .fontSize($r('sys.float.Body_M'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE)
          .fontColor($r('sys.color.font_secondary'))
          .opacity($r('sys.float.alpha_secondary'))
          .fontFamily($r('sys.string.ohos_id_text_font_family_regular'))
          .margin({ top: $r('sys.float.padding_level4') })
          .maxLines(4)
          Row() {
            this.TextButton();
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .margin({ top: $r('sys.float.padding_level4') });
      }
      .id(CompId.OPEN_CLOUD_SYNC_TIP)
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .borderRadius($r('sys.float.corner_radius_level10'))
      .margin({
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
        bottom: this.isUpFoldScreen ? $r('sys.float.padding_level4') : $r('sys.float.ohos_id_dialog_margin_bottom')
      })
      .padding({
        left: $r('sys.float.padding_level6'),
        right: $r('sys.float.padding_level6'),
        top: $r('sys.float.padding_level8'),
        bottom: $r('sys.float.padding_level8')
      });
    }
  }

  private onIgnoreClick = () => {
    this.canShowTip = false;
    this.recordIgnoreTip();
  };

  private onOpenSyncClick = () => {
    CloudUtils.jumpCloudDrivePage();
  };

  private calculateCanShowTip() {
    // 计算当前不提醒计算下的提醒间隔毫秒数
    let gapMills: number = SHOW_TIP_GAP_ONE_WEEK;
    const count = PreferencesUtil.getNumberValueSync(PreferencesFiles.DEFAULT, KEY_IGNORE_COUNT, 0);
    if (count >= IGNORE_COUNT_THRESHOLD) {
      gapMills = SHOW_TIP_GAP_TWO_WEEK;
    }
    // 与上次点击不提醒的时间点进行对比，超过间隔则显示提醒
    const lastIgnoreTime: number = PreferencesUtil.getNumberValueSync(PreferencesFiles.DEFAULT,
      KEY_LAST_IGNORE_SYNC_TIP, 0);
    this.canShowTip = Math.abs(Date.now() - lastIgnoreTime) > gapMills;
    Log.info(TAG, `canShowTip=${this.canShowTip}, lastTime=${lastIgnoreTime}, count=${count}`);
  }

  private recordIgnoreTip() {
    // 刷新上次点击不提醒的时间点
    PreferencesUtil.putNumberValueSync(PreferencesFiles.DEFAULT, KEY_LAST_IGNORE_SYNC_TIP, Date.now());
    // 点击不提醒累计计数，达到阈值后则无需再记录
    const count = PreferencesUtil.getNumberValueSync(PreferencesFiles.DEFAULT, KEY_IGNORE_COUNT, 0);
    if (count <= IGNORE_COUNT_THRESHOLD) {
      PreferencesUtil.putNumberValueSync(PreferencesFiles.DEFAULT, KEY_IGNORE_COUNT, count + 1);
    }
  }
}