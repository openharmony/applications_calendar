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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import {
  BackgroundId,
  BackgroundPanelId,
  LayoutId,
  TextureId
} from '@app/common/src/main/ets/card/ImportantCardConfig';
import { addImageText } from '@app/common/src/main/ets/util/AccessibilityUtil';
import { ImportantEntity } from '../model/ImportantEntity';
import { DateUtil, MILLS_PER_DAY } from '@app/common/src/main/ets/util/DateUtil';
import { LunarDate } from '@app/common/src/main/ets/date/LunarDate';
import { CalendarContract } from '@app/common/src/main/ets/default/calendar/CalendarContract';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { I18nUtil } from '@app/common/src/main/ets/util/I18nUtil';
import { display } from '@kit.ArkUI';

const TAG: string = 'CardUiUtils';

/** 仅标题以中文生日结尾时需要显示周岁，生日两个字不需要翻译 */
const BIRTHDAY_STR: string = '生日';

/** 仅中文下显示周岁，周岁两个字不需要翻译（同双框架） 注意空格 */
const CHINESE_ANNIVERSARY: string = ' 周岁';

export class CardUiUtils {
  public static getTextureById(id: string): Resource {
    switch (id) {
      case TextureId.MOIRE:
        return $r('app.media.texture_moire');
      case TextureId.CONCENTRIC_CIRCLE:
        return $r('app.media.texture_concentric_circle');
      case TextureId.ARCHES:
        return $r('app.media.texture_arches');
      case TextureId.RIPPLES:
        return $r('app.media.texture_ripples');
      case TextureId.SQUARES:
        return $r('app.media.texture_squares');
      case TextureId.CURVES:
        return $r('app.media.texture_curves');
      default:
        return $r('app.media.texture_moire');
    }
  }

  public static getTextureAccessibilityTextById(id: TextureId): string {
    let text: ResourceStr = '';
    switch (id) {
      case TextureId.MOIRE:
        text = $r('app.string.accessibility_image_moire');
        break;
      case TextureId.CONCENTRIC_CIRCLE:
        text = $r('app.string.accessibility_image_concentric_circle');
        break;
      case TextureId.ARCHES:
        text = $r('app.string.accessibility_image_arches');
        break;
      case TextureId.RIPPLES:
        text = $r('app.string.accessibility_image_ripples');
        break;
      case TextureId.SQUARES:
        text = $r('app.string.accessibility_image_squares');
        break;
      case TextureId.CURVES:
        text = $r('app.string.accessibility_image_curves');
        break;
      default:
        text = $r('app.string.accessibility_image_moire');
        break;
    }
    return addImageText(text);
  }

  public static getBackgroundById(
    id: string,
    texturesId: TextureId,
    isCard2x2: boolean
  ): Resource {
    try {
      switch (id) {
        case BackgroundId.TEXTURES:
          return CardUiUtils.getTextureById(texturesId);
        case BackgroundId.IMG_PAPER_PLANE:
          return isCard2x2 ? $r('app.media.paper_plane_2_2') : $r('app.media.paper_plane_2_4');
        case BackgroundId.IMG_LOVE_BALLOONS:
          return isCard2x2 ? $r('app.media.love_balloons_2_2') : $r('app.media.love_balloons_2_4');
        case BackgroundId.IMG_GIFT_BOX:
          return isCard2x2 ? $r('app.media.gift_box_2_2') : $r('app.media.gift_box_2_4');
        case BackgroundPanelId.PANEL_DREAMS:
          return isCard2x2 ? $r('app.media.panel_dreams_2_2') : $r('app.media.panel_dreams_2_4');
        case BackgroundPanelId.PANEL_GRAFFITI:
          return isCard2x2 ? $r('app.media.panel_graffiti_2_2') : $r('app.media.panel_graffiti_2_4');
        case BackgroundPanelId.PANEL_SIMPLICITY:
          return isCard2x2 ? $r('app.media.panel_simplicity_2_2') : $r('app.media.panel_simplicity_2_4');
        default:
          return CardUiUtils.getTextureById(texturesId);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'getBackgroundById', err);
      return CardUiUtils.getTextureById(texturesId);
    }
  }

  static getBackgroundAccessibilityById(id: string, texturesId: TextureId): string {
    switch (id) {
      case BackgroundId.TEXTURES:
        return CardUiUtils.getTextureAccessibilityTextById(texturesId);
      case BackgroundId.IMG_PAPER_PLANE:
        return addImageText($r('app.string.accessibility_image_paper_plane'));
      case BackgroundId.IMG_LOVE_BALLOONS:
        return addImageText($r('app.string.accessibility_image_love_balloons'));
      case BackgroundId.IMG_GIFT_BOX:
        return addImageText($r('app.string.accessibility_image_gift_box'));
      case BackgroundId.CUSTOMIZE:
        return addImageText($r('app.string.customize_card_setting'));
      case BackgroundPanelId.NO_PANEL:
        return addImageText($r('app.string.original_image'));
      case BackgroundPanelId.PANEL_DREAMS:
        return addImageText($r('app.string.customize_background_dreams'));
      case BackgroundPanelId.PANEL_GRAFFITI:
        return addImageText($r('app.string.customize_background_graffiti'));
      case BackgroundPanelId.PANEL_SIMPLICITY:
        return addImageText($r('app.string.customize_background_simplicity'));
      default:
        return CardUiUtils.getTextureAccessibilityTextById(texturesId);
    }
  }

  static getBackgroundTextById(id: string): ResourceStr {
    switch (id) {
      case BackgroundId.TEXTURES:
        return $r('app.string.event_texture');
      case BackgroundId.CUSTOMIZE:
        return $r('app.string.customize_card_setting');
      case BackgroundId.IMG_PAPER_PLANE:
        return $r('app.string.card_background_dreams_fly');
      case BackgroundId.IMG_LOVE_BALLOONS:
        return $r('app.string.card_background_sweet_summer');
      case BackgroundId.IMG_GIFT_BOX:
        return $r('app.string.card_background_birthday_cake');
      case BackgroundPanelId.NO_PANEL:
        return $r('app.string.original_image');
      case BackgroundPanelId.PANEL_DREAMS:
        return $r('app.string.customize_background_dreams');
      case BackgroundPanelId.PANEL_GRAFFITI:
        return $r('app.string.customize_background_graffiti');
      case BackgroundPanelId.PANEL_SIMPLICITY:
        return $r('app.string.customize_background_simplicity');
      default:
        return '';
    }
  }

  static getLayoutById(layoutId: LayoutId, isSquare: boolean): Resource {
    switch (layoutId) {
      case LayoutId.LEFT:
        return isSquare ? $r('app.media.layoutLeft2x2') : $r('app.media.layoutLeft2x4');
      case LayoutId.RIGHT:
        return isSquare ? $r('app.media.layoutRight2x2') : $r('app.media.layoutRight2x4');
      case LayoutId.CENTER:
        return $r('app.media.layoutCenter2x2');
      case LayoutId.LEFT_1:
        return $r('app.media.layoutLeftTextImg2x2');
      case LayoutId.RIGHT_1:
        return $r('app.media.layoutRightTextImg2x2');
      case LayoutId.CENTER_1:
        return $r('app.media.layoutCenterTextImg2x2');
      default:
        return isSquare ? $r('app.media.layoutLeft2x2') : $r('app.media.layoutLeft2x4');
    }
  }

  static getLayoutTextById(layoutId: LayoutId, isSquare: boolean): Resource {
    switch (layoutId) {
      case LayoutId.LEFT:
      case LayoutId.LEFT_1:
        return isSquare ? $r('app.string.accessibility_image_align_left')
          : $r('app.string.accessibility_image_time_left');
      case LayoutId.RIGHT:
      case LayoutId.RIGHT_1:
        return isSquare ? $r('app.string.accessibility_image_align_right')
          : $r('app.string.accessibility_image_time_right');
      case LayoutId.CENTER:
      case LayoutId.CENTER_1:
        return $r('app.string.accessibility_image_align_center');
      default:
        return isSquare ? $r('app.string.accessibility_image_align_left')
          : $r('app.string.accessibility_image_time_left');
    }
  }

  public static getPrimaryColor(backgroundId: string, bright: number, isToday = false) {
    switch (backgroundId) {
      case BackgroundId.TEXTURES:
        return isToday ? $r('app.color.red_common') : $r('sys.color.font_primary');
      case BackgroundId.CUSTOMIZE:
        return bright > 0.5 ? '#000000' : '#ffffff';
      default:
        return isToday ? $r('app.color.red_common') : '#000000';
    }
  }

  public static getSecondaryColor(backgroundId: string, bright: number) {
    switch (backgroundId) {
      case BackgroundId.TEXTURES:
        return $r('sys.color.font_secondary');
      case BackgroundId.CUSTOMIZE:
        return bright > 0.5 ? '#992D2D2D' : '#DCDCDC';
      default:
        return '#992D2D2D';
    }
  }

  public static isShowDayLaterLabel(type: string, dayOffset: number) {
    // 倒数日
    return type === 'days_later' && dayOffset > 0;
  }

  public static isToday(dayOffset: number) {
    return dayOffset === 0;
  }

  public static isNoOffsetStyle(yearOffset: number, dayOffset: number) {
    return yearOffset === 0 && dayOffset === 0;
  }

  /**
   * 判断日程是否需要按生日日程风格展示：
   * 判断重要日标题是否以生日结尾，以生日结尾则某些场景下周年要显示成周岁
   *
   * @param title 重要日标题
   * @returns 是否按生日日程的风格展示
   */
  public static isNeedShowAsBirthday(title: string | Resource): boolean {
    if (!title) {
      return false;
    }
    if (typeof title !== 'string') {
      return false;
    }
    if (title.length === 0) {
      return false;
    }
    return title.endsWith('生日');
  }

  /**
   * 不透明度转alpha
   * 0 ->00; 1 ->ff
   *
   * @param opacity 不透明度
   * @returns alpha argb
   */
  public static opacity2alpha(opacity = 1) {
    let _opacity = opacity;
    if (opacity > 1) {
      _opacity = 1;
    } else if (opacity < 0) {
      _opacity = 0;
    }

    return ('00' + Math.round(_opacity * 255).toString(16)).slice(-2);
  }

  /**
   * 颜色增加不透明度
   * #ff0000 ->#00ff0000
   *
   * @param color   颜色值 #ff0000
   * @param opacity 不透明度 0-1
   * @returns argb  argb色值 #00ff0000
   */
  public static rgb2argb(color: string, opacity = 1) {
    if (!color?.startsWith('#') || color?.length !== 7) {
      Log.error(TAG, 'color is invalid' + color);
      return '#000000';
    }

    const rgb = color.slice(-6);
    const alpha = CardUiUtils.opacity2alpha(opacity);
    return '#' + alpha + rgb;
  }

  /**
   * 获取目标日期与当前日期年数和天数差值
   *
   * @param instanceTime 目标日期时间戳
   * @param type 倒数日-2 正数日-1
   * @param title 重要日标题，用于判断显示周岁或者周年
   * @returns 返回目标日期与当前日期年数和天数差值
   */
  public static getYearDayOffset(important: ImportantEntity, language?: string, title?: string): YearDayContentType {
    const timeNow = new Date().getTime();
    const dayInfo = DateUtil.getDayOffset(important.begin, important.importantEventType, timeNow, language);
    let yearDayOffset: YearDayOffset = {} as YearDayOffset;
    if (important.importantEventType === CalendarContract.EventImportantType.COUNTDOWN) {
      // 计算原始时间到实例时间的年数
      if (important.rrule?.includes('FREQ=YEARLY')) {
        yearDayOffset.yearOffset = CardUiUtils.getYearOffset(important.originalBegin, important.begin,
          important.eventCalendarType);
      } else {
        yearDayOffset.yearOffset = 0;
      }
      // 计算实例时间到当前时间的天数
      yearDayOffset.remainingDays = CardUiUtils.getDayOffset(timeNow, important.begin);
    } else {
      // 纪念日，无实例时间的说法，直接计算日程时间到当前时间的年数和天数
      yearDayOffset = CardUiUtils.dateDiff2YearDayOffset(important.begin, timeNow, important.eventCalendarType);
    }

    let isCurrentYear = yearDayOffset.yearOffset === 0;
    let isCurrentDay = dayInfo.dayOffset === 0;
    let content = '';
    // 不直接调用isSystemChineseLanguage, 防止耗时
    let isChineseLanguage = language ? I18nUtil.isChineseLanguage(language) : I18nUtil.isSystemChineseLanguage();
    // 自建的以生日结尾的重要日
    let isNormalBirthDay = title && title.endsWith(BIRTHDAY_STR) && isChineseLanguage;
    let anniversariesStr = GlobalThis.getPluralStr($r('app.plural.in_anniversarys'), yearDayOffset.yearOffset, language);

    Log.info(TAG, `getYearDayOffset: ${new Date(important.begin).toLocaleString()}, ` +
      `dayOffset= ${dayInfo.dayOffset}, yearOffset= ${yearDayOffset.yearOffset}, ` +
      `remainingDays= ${yearDayOffset.remainingDays}, isNormalBirthDay= ${isNormalBirthDay}`);

    if (isCurrentYear && isCurrentDay) {
      // 本年当天
      content = '';
    } else if (isCurrentYear) {
      // 本年非当天
      content = dayInfo.content;
    } else if (isCurrentDay) {
      // 非本年当天 如果以生日结尾,则显示周岁
      content = isNormalBirthDay ? yearDayOffset.yearOffset + CHINESE_ANNIVERSARY : anniversariesStr;
    } else {
      // 非本年非当天
      content = dayInfo.content;
    }
    return {
      type: dayInfo.type,
      dayOffset: dayInfo.dayOffset,
      content: content,
      yearOffset: yearDayOffset.yearOffset,
      remainingDays: yearDayOffset.remainingDays,
    }
  }

  /**
   * 获取年数差值
   *
   * @param startTime 开始时间
   * @param endTime 结束时间
   * @param calendarType 是否农历
   * @returns 年份差
   */
  static getYearOffset(startTime: number, endTime: number, calendarType: number): number {
    startTime = new Date(startTime).setHours(0, 0, 0, 0);
    endTime = new Date(endTime).setHours(0, 0, 0, 0);
    let yearOffset: number = 0;
    if (calendarType === CalendarContract.AgendaCalendarType.LUNAR) {
      const startDate = new LunarDate();
      startDate.setTime(startTime);
      const endDate = new LunarDate();
      endDate.setTime(endTime);
      yearOffset = endDate.getFullYear() - startDate.getFullYear();
    } else {
      const startDate = new Date(startTime);
      const endDate = new Date(endTime);
      yearOffset = endDate.getFullYear() - startDate.getFullYear();
    }
    if (yearOffset < 0) {
      yearOffset = 0;
    }
    return yearOffset;
  }

  /**
   * 获取天数差值，隔了好几年的，也只会返回绝对天数差，而不是一年内的天数差
   *
   * @param startTime 开始时间
   * @param endTime 结束时间
   * @returns 天数差
   */
  static getDayOffset(startTime: number, endTime: number): number {
    startTime = new Date(startTime).setHours(0, 0, 0, 0);
    endTime = new Date(endTime).setHours(0, 0, 0, 0);
    return Math.ceil((endTime - startTime) / MILLS_PER_DAY);
  }

  /**
   * 将天数差值转化为几年加几天，其中remainingDays是减去整年后的剩余天数
   *
   * @param startTime 开始时间
   * @param endTime 结束时间
   * @param calendarType 是否农历
   * @returns 返回目标日期与当前日期年数差值和剩余天数
   */
  static dateDiff2YearDayOffset(startTime: number, endTime: number, calendarType: number): YearDayOffset {
    startTime = new Date(startTime).setHours(0, 0, 0, 0);
    endTime = new Date(endTime).setHours(0, 0, 0, 0);
    let yearOffset: number = 0;
    let remainingDays: number = 0;
    if (calendarType === CalendarContract.AgendaCalendarType.LUNAR) {
      const startDate = new LunarDate();
      startDate.setTime(startTime);
      const endDate = new LunarDate();
      endDate.setTime(endTime);
      if (startDate.getMonth() < endDate.getMonth() ||
        (startDate.getMonth() === endDate.getMonth() && startDate.getDate() <= endDate.getDate())) {
        yearOffset = endDate.getFullYear() - startDate.getFullYear();
      } else {
        yearOffset = endDate.getFullYear() - startDate.getFullYear() - 1;
      }
      startDate.addYear(yearOffset);
      remainingDays = Math.ceil((endDate.getTimeInMills() - startDate.getTimeInMills()) / MILLS_PER_DAY);
    } else {
      const startDate = new Date(startTime);
      const endDate = new Date(endTime);
      yearOffset = endDate.getFullYear() - startDate.getFullYear();
      if (startDate.getMonth() < endDate.getMonth() ||
        (startDate.getMonth() === endDate.getMonth() && startDate.getDate() <= endDate.getDate())) {
        yearOffset = endDate.getFullYear() - startDate.getFullYear();
        startDate.setFullYear(endDate.getFullYear());
      } else {
        yearOffset = endDate.getFullYear() - startDate.getFullYear() - 1;
        startDate.setFullYear(endDate.getFullYear() - 1);
      }
      remainingDays = Math.ceil((endDate.getTime() - startDate.getTime()) / MILLS_PER_DAY);
    }
    if (yearOffset < 0) {
      yearOffset = 0;
    }
    if (remainingDays < 0) {
      remainingDays = 0;
    }
    return {
      yearOffset: yearOffset,
      remainingDays: remainingDays
    }
  }

  static getSizeRateFromDisplay(): Promise<number> {
    return display.getAllDisplays().then(data => {
      if (data.length === 0) {
        Log.warn(TAG, `display data is null`);
        return 1;
      }

      let isFoldable = false;
      try {
        isFoldable = display.isFoldable();
      } catch (err) {
        Log.logErrorMsg(TAG, `isFoldable`, err);
      }

      let foldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
      try {
        foldStatus = display.getFoldStatus();
      } catch (err) {
        Log.logErrorMsg(TAG, `foldStatus`, err);
      }
      const isExpanded = foldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED;

      const orientation = data[0].orientation;
      const isLandscape = [display.Orientation.LANDSCAPE, display.Orientation.LANDSCAPE_INVERTED].includes(orientation);

      const height = data[0].height;
      // 双折叠横屏高度
      const defaultHeight = 2224;
      // 上下扩展高度
      const expandHeight = 500;
      // 双折叠
      const isDoubleFlex = height >= defaultHeight - expandHeight && height <= defaultHeight + expandHeight

      Log.info(TAG, `display: ${isFoldable}, ${isExpanded}, ${isLandscape}, ${isDoubleFlex}`);

      // 折叠屏，展开态，横屏，双折叠
      if (isFoldable && isExpanded && isLandscape && isDoubleFlex) {
        // 初始化横屏时，字体缩放0.7倍，适配中文【天后】一行显示，否则存在截断问题
        return 0.7;
      } else {
        return 1;
      }
    }).catch(() => {
      return 1;
    })
  }

  static getSizeRateFromSize(height: number): number {
    // 竖屏116，刚好排满
    // 横屏96，排版截断
    const defaultHeight = 116;
    if (height > 0 && height < defaultHeight) {
      // 横竖屏切换至横屏时，字体缩放0.7倍，适配中文【天后】一行显示，否则存在截断问题
      return 0.7;
    } else {
      return 1;
    }
  }
}

export interface YearDayOffset {
  yearOffset: number;

  remainingDays: number;
}

class YearDayContentType {
  // 天数差值
  public dayOffset: number = 0;

  // 年数差值
  public yearOffset: number = 0;

  // 年数整除后剩余天数
  public remainingDays: number = 0;

  // 类型 in_days | days_later
  public type: string = '';

  public content: string = '';
}