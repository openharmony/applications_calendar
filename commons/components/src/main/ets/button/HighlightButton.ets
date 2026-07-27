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

/**
 * 商务化弹框按钮组件
 */
@Component
export struct HighlightButton {
  @StorageLink('themeColor') themeColor: string = '';

  @Prop label: ResourceStr;

  private compId: string = '';

  private isWarning: boolean = false;

  private isFocus: boolean = false;

  build() {
    Button(this.label)
      .type(ButtonType.Normal)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .fontSize($r('sys.float.Body_L'))
      .fontColor(this.isWarning ? $r('sys.color.ohos_id_color_warning') : this.themeColor)
      .layoutWeight(1)
      .onClick(() => {
        this.onButtonClick();
      })
      .defaultFocus(this.isFocus)
      .id(this.compId)
  }

  private onButtonClick: () => void = () => {
  };
}