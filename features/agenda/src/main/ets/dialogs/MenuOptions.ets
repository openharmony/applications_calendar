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
 * 日程列表长按或者右键弹窗
 *
 * @since 2023-03-20
 */
@Component
export struct MenuOptions {
  @Prop private text: Resource;

  build() {
    Button({ type: ButtonType.Normal }) {
      Text(this.text)
        .margin({ left: 4, right: 4 })
        .fontSize(16)
        .fontWeight(FontWeight.Regular)
    }
    .onClick(() => {
      this.callback();
    })
    .align(Alignment.Start)
    .backgroundColor($r('app.color.default_background'))
    .width(119)
    .height(48)
    .borderRadius($r('sys.float.corner_radius_level7'))
  }

  private callback: () => void = (): void => {
  };
}