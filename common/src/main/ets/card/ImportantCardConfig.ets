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

import { CalendarContract } from '../default/calendar/CalendarContract';
import { FormBaseInfo } from './FormBaseInfo';

/**
 * 重要日卡片配置数据实体
 */
class ImportantCardConfig extends FormBaseInfo {
  public eventMode: EventMode = EventMode.DEFAULT;

  // 卡片固定的eventId(兼容历史版本)
  public eventIds: number[] = [];

  // 卡片固定的eventId
  public fixedEventIds: number[] = [];

  public holidayIds: number[] = [];

  public eventTitle: string = '';

  public importantType: number = CalendarContract.EventImportantType.NORMAL;

  public backgroundId: string = BackgroundId.TEXTURES;

  public panelId: string = BackgroundPanelId.PANEL_DREAMS;

  public customizeImgPath: string = '';

  public fontId: FontId = FontId.DEFAULT;

  public color: string = Color.DEFAULT;

  public opacity: number = 1;

  public topBright: number = 1;

  public bottomBright: number = 1;

  public texturesId: TextureId = TextureId.MOIRE;

  public layoutId: LayoutId = LayoutId.CENTER;

  // 重要日卡片支持的纹理ID
  public supportTextureIds: TextureId[] = [
    TextureId.MOIRE,
    TextureId.CONCENTRIC_CIRCLE,
    TextureId.ARCHES,
    TextureId.RIPPLES,
    TextureId.SQUARES,
    TextureId.CURVES
  ];

  // 重要日卡片支持的布局风格
  public supportLayoutIds: LayoutId[] = [];

  constructor(formId: string) {
    super(formId);
  }

  public static setFixedEventIds(config: ImportantCardConfig, ids: number[]): void {
    if (config) {
      config.fixedEventIds = ids;
      config.eventIds = ids;
    }
  }

  isHasFixedImportant(): boolean {
    return this.eventMode == EventMode.FIXED_IMPORTANT && this.fixedEventIds.length > 0;
  }
}

/**
 * 重要日卡片2x2配置数据实体
 */
class ImportantCardConfig2x2 extends ImportantCardConfig {
  public layoutId: LayoutId = LayoutId.CENTER;

  // 重要日卡片支持的布局风格
  public supportLayoutIds: LayoutId[] = [
    LayoutId.LEFT,
    LayoutId.CENTER,
    LayoutId.RIGHT,
    LayoutId.LEFT_1,
    LayoutId.CENTER_1,
    LayoutId.RIGHT_1,
  ];

  constructor(formId: string) {
    super(formId);
  }
}

/**
 * 重要日卡片2x4配置数据实体
 */
class ImportantCardConfig2x4 extends ImportantCardConfig {
  public layoutId: LayoutId = LayoutId.LEFT;

  // 重要日卡片支持的布局风格
  public supportLayoutIds: LayoutId[] = [
    LayoutId.LEFT,
    LayoutId.RIGHT,
  ];

  constructor(formId: string) {
    super(formId);
  }
}

/**
 * 重要日卡片事件类型
 */
enum EventMode {
  // 重要日卡片事件类型-默认
  DEFAULT = 'default',
  // 重要日卡片事件类型-固定重要日
  FIXED_IMPORTANT = 'fixed_important',
  // 重要日卡片事件类型-近期重要日
  RECENT_IMPORTANT = 'recent_important',
  // 重要日卡片事件类型-固定生日
  FIXED_BIRTHDAY = 'fixed_birthday',
  // 重要日卡片事件类型-近期生日
  RECENT_BIRTHDAY = 'recent_birthday',
  // 重要日卡片事件类型-固定节日
  FIXED_HOLIDAY = 'fixed_holiday',
  // 重要日卡片事件类型-近期节日
  RECENT_HOLIDAY = 'recent_holiday',
  // 重要日卡片事件类型-未知的迁移后联系人生日卡片
  UNKNOWN_BIRTHDAY = 'unknown_birthday'
}

/**
 * 重要日卡片背景ID
 */
enum BackgroundId {
  // 重要日卡片背景-自定义背景
  CUSTOMIZE = 'customize',
  // 重要日卡片背景-纹理样式
  TEXTURES = 'textures',
  // 重要日卡片背景-纸飞机
  IMG_PAPER_PLANE = 'img_paper_plane',
  // 重要日卡片背景-爱心气球
  IMG_LOVE_BALLOONS = 'img_love_balloons',
  // 重要日卡片背景-礼盒
  IMG_GIFT_BOX = 'img_gift_box'
}

/**
 * 重要日卡片自定义背景图片之AI抠图的底板ID
 */
enum BackgroundPanelId {
  // 重要日卡片自定义背景的底板-无底板，即原图
  NO_PANEL = '',
  // 重要日卡片自定义背景的底板-梦幻
  PANEL_DREAMS = 'customize_bg_dreams',
  // 重要日卡片自定义背景的底板-涂鸦
  PANEL_GRAFFITI = 'customize_bg_graffiti',
  // 重要日卡片自定义背景的底板-简约
  PANEL_SIMPLICITY = 'customize_bg_simplicity'
}

/**
 * 重要日卡片纹理ID
 */
enum TextureId {
  // 重要日卡片纹理ID-云纹
  MOIRE = 'moire',
  // 重要日卡片纹理ID-同心圆
  CONCENTRIC_CIRCLE = 'concentric_circle',
  // 重要日卡片纹理ID-拱门
  ARCHES = 'arches',
  // 重要日卡片纹理ID-波纹
  RIPPLES = 'ripples',
  // 重要日卡片纹理ID-正方形矩阵
  SQUARES = 'squares',
  // 重要日卡片纹理ID-曲线魔纹
  CURVES = 'curves'
}

/**
 * 重要日卡片版式
 */
enum LayoutId {
  // 重要日卡片版式居左
  LEFT = 'left',
  // 重要日卡片版式居中
  CENTER = 'center',
  // 重要日卡片版式居右
  RIGHT = 'right',
  // 重要日卡片版式居左_上文下图
  LEFT_1 = 'left1',
  // 重要日卡片版式居中_上文下图
  CENTER_1 = 'center1',
  // 重要日卡片版式居右_上文下图
  RIGHT_1 = 'right1',
}

/**
 * 重要日卡片版式类型
 */
enum LayoutIdType {
  // 重要日卡片版式, 默认类型
  DEFAULT = 'text_img_text',
  // 重要日卡片版式默认类型，图文混排
  TEXT_IMG_TEXT = 'text_img_text',
  // 重要日卡片版式默认类型，上文下图
  TEXT_IMG = 'text_img'
}

enum FontId {
  DEFAULT = 'default',
  FONT_1 = 'font1',
  FONT_2 = 'font2',
  FONT_3 = 'font3',
  FONT_4 = 'font4',
  FONT_5 = 'font5',
  FONT_6 = 'font6',
  FONT_7 = 'font7',
  FONT_8 = 'font8'
}

enum Color {
  DEFAULT = '#F76045',
  BLACK = '#000000',
  WHITE = '#ffffff',
  RED = '#F76045',
  ORANGE = '#FD8A42',
  YELLOW = '#ECBF00',
  GREEN = '#7EC470',
  CYAN = '#13B7C8',
  BLUE = '#1D98FF',
  VIOLET = '#7A6FEB'
}

export {
  ImportantCardConfig, ImportantCardConfig2x2, ImportantCardConfig2x4, EventMode, BackgroundId, TextureId, LayoutId,
  LayoutIdType,
  FontId,
  Color,
  BackgroundPanelId
}