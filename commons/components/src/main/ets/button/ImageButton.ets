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
  ButtonImageType,
  ButtonLayoutParam,
  CalendarLayoutManager,
  CompId,
  GlobalDataKeys,
  GlobalThis,
  Log,
  ThrottleFunction,
  TIPS_HOVER_DELAY
} from '@app/common';
import { LongPressConfig, LongPressTipsDialog } from '../LongPressTipsDialog';

const TAG: string = 'ImageButton';

@Component
export struct ImageButton {
  @Link flagChanged: boolean;

  @State showPopup: boolean = false;

  @Prop image: Resource = {} as Resource;

  @Prop buttonType: ButtonType = ButtonType.Circle;

  @Prop compId: string = '';

  private buttonImageType: ButtonImageType = ButtonImageType.SYMBOL;

  private buttonBackgroundColor: ResourceColor = $r('sys.color.comp_background_tertiary');

  private promptText: Resource | string = ''

  private popUpColor: ResourceStr = $r('sys.color.ohos_id_color_card_bg');

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  @State buttonLayout: ButtonLayoutParam = CalendarLayoutManager.getInstance().buttonLayout;

  @Prop @Watch('buttonEnabledChange') buttonEnabled: boolean = true;

  private tipsDialogController: CustomDialogController = new CustomDialogController({
    builder: LongPressTipsDialog({
      tipsText: this.promptText,
      tipsImage: this.image,
      buttonImageType: this.buttonImageType
    }),
    customStyle: true,
    isModal: false,
  });

  onButtonClick: () => void = (): void => {
  };

  getShadow() {
    return this.isDarkMode ?
      { radius: 2, color: '#66ffffff', offsetX: 0, offsetY: 0, } as ShadowOptions :
      ShadowStyle.OUTER_DEFAULT_SM
  }

  build() {
    Button({ type: this.buttonType }) {
      if (this.buttonImageType === ButtonImageType.TEXT) {
        Text(this.image)
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontSize($r('sys.float.Body_L'))
          .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
      } else if (this.buttonImageType === ButtonImageType.IMAGE) {
        Image(this.image)
          .width(this.buttonLayout.imageSize)
          .height(this.buttonLayout.imageSize)
          .draggable(false)
          .interpolation(ImageInterpolation.High)
          .fillColor($r('sys.color.icon_primary'))
      } else {
        SymbolGlyph(this.image)
          .fontSize(this.buttonLayout.symbolSize)
          .fontColor([$r('sys.color.icon_primary')])
          .opacity($r('sys.float.alpha_primary'))
          .fontWeight(this.buttonLayout.symbolWeight)
      }
    }
    .id(this.compId)
    .enabled(this.buttonEnabled)
    .height(this.buttonLayout.buttonHeight)
    .width(this.buttonLayout.buttonHeight)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .accessibilityText(this.getAccessibilityText())
    .accessibilityDescription(this.getAccessibilityDescriptionText())
    .onClick(() => {
      GlobalThis.getInstance().shareAnchorViewId = CompId.ID_BT_AGENDA_DETAIL_SHARE;
      if (this.buttonEnabled) {
        this.flagChanged = !this.flagChanged;
        this.onButtonClick();
      }
    })
    .onHover((isHover: boolean) => {
      if (isHover) {
        ThrottleFunction.instance().debounce(TAG + this.compId + 'tips', () => {
          this.showPopup = true;
        }, TIPS_HOVER_DELAY);
      } else {
        // 因无法保证TAG唯一故在hover取消时先关闭tips再对防抖进行注销
        this.showPopup = false;
        ThrottleFunction.instance().debounce(TAG + this.compId + 'tips', () => {
        }, 0);
      }
    })
    .backgroundColor(this.buttonBackgroundColor)
    .bindPopup(this.showPopup, {
      builder: this.PopupComp(),
      popupColor: this.popUpColor,
      backgroundBlurStyle: BlurStyle.NONE,
      shadow: this.getShadow(),
      mask: false,
      enableArrow: false
    })
    .gesture(
      LongPressGesture({ duration: LongPressConfig.TIPS_DIALOG_PRESS_TIME })
        .onAction((event: GestureEvent) => {
          if (this.fontSizeScale >= LongPressConfig.TIPS_SHOW_SCALE) {
            this.tipsDialogController.open();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          this.tipsDialogController.close();
        })
    )
  }

  @Builder
  PopupComp() {
    Row() {
      Text(this.promptText)
        .fontSize($r('sys.float.Body_M'))
        .padding({
          left: 16,
          right: 16,
          top: 8,
          bottom: 8
        })
        .fontColor($r('sys.color.font_primary'))
    }
    .borderRadius($r('sys.float.corner_radius_level10'))
  }

  getAccessibilityText(): string {
    if (typeof this.promptText === 'string') {
      return this.promptText;
    }
    return GlobalThis.getResourceStr(this.promptText);
  }

  aboutToAppear(): void {
    this.getAccessibilityDescriptionText();
  }

  buttonEnabledChange() {
    this.getAccessibilityDescriptionText();
  }

  getAccessibilityDescriptionText(): string {
    const notAvailableText: string = GlobalThis.getResourceStr($r('app.string.unavailable_text'));
    const executeText: string = GlobalThis.getResourceStr($r('app.string.double_click_finger_execute'));
    const accessibilityDescription = this.buttonEnabled ? `${executeText}` : `${notAvailableText}`;
    return accessibilityDescription;
  }

}
