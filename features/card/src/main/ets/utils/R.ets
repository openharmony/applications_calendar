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
 * Resource Information
 *
 * @since 2022-03-01
 */
export namespace R {
  export class Dimen {
    static default_tiny_padding = 4;
    static default_small_padding = 8;
    static default_padding = 16;
    static default_large_padding = 24;
    static tab_padding_top = 12;
    static tab_padding_left = 88;
    static tab_padding_right = 88;
    static drop_down_list_offset = 24;
    static icon_default_height = 24;
    static icon_default_width = 24;
    static icon_large_width = 32;
    static icon_large_height = 32;
    static text_size_over_line = 14;
    static text_size_head_line_7 = 24;
    static text_size_body_3 = 12;
    static text_size_body_1 = 16;
    static menu_icon_width = 24;
    static menu_icon_height = 24;
    static banner_corner_radius = 16;
    static icon_focus_width = 40;
    static icon_focus_height = 40;
    static status_bar_height = 48;
    static navigation_bar_height = 42;
    static important_card_nav_height = 56;
  }

  export class Color {
    static main_background: Resource = $r('app.color.main_background');
    static sub_background: Resource = $r('app.color.sub_background');
  }
}
