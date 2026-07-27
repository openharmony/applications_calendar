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
import { CalendarInfo } from '../../CalendarInfo';
import { VcsComponent } from '../model/VcsComponent';
import { CustomTime, FormatTime } from '@app/feature.repeatrule';
import { AgendaEventInfo, EmptyUtils, Log, Pair } from '@app/common';
import { HashMap } from '@kit.ArkTS';

/**
 * 日程的开始时间字段
 */
export const DTSTART = 'DTSTART';

/**
 * 日程的结束时间字段
 */
export const DTEND = 'DTEND';

/**
 * 是否已完成字段
 */
export const COMPLETED = 'COMPLETED';

/**
 * 重复规则字段
 */
export const RRULE = 'RRULE';


/**
 * 被删除的日程
 */
export const EX_DATE = 'EX_DATE';


/**
 * 通知
 */
export const TRIGGER = 'TRIGGER';


/**
 * 通知M
 */
export const M = 'M';


/**
 * 通知H
 */
export const H = 'H';

/**
 * 通知D
 */
export const D = 'D';


/**
 * 通知P
 */
export const P = 'P';


/**
 * 邀请人状态字段
 */
export const STATUS = 'STATUS';

/**
 * 日程持续时间字段
 */
export const DUE = 'DUE';

/**
 * 日程持续时间字段
 */
export const DURATION = 'DURATION';

/**
 * 地点字段
 */
export const LOCATION = 'LOCATION';

/**
 * 描述字段
 */
export const DESCRIPTION = 'DESCRIPTION';

export const SERVICEDESCRIPTION = 'SERVICEDESCRIPTION';

export const SERVICEVERIFIED = 'SERVICEVERIFIED';

export const SERVICETYPE = 'SERVICETYPE';

export const SERVICEURI = 'SERVICEURI';

export const PREFERRED_LANGUAGE = 'PREFERRED_LANGUAGE';

/**
 * 详细信息字段
 */
export const SUMMARY = 'SUMMARY';

/**
 * 缩写字段
 */
export const ABBREVIATION = 'ABBREVIATION';

/**
 * 详细信息多语言配置字段
 */
export const RESOURCES = 'RESOURCES';

/**
 * 提醒字段
 */
export const AALARM = 'AALARM';

/**
 * 日程性质字段
 */
export const CLASS = 'CLASS';

/**
 * 日程农历公历字段
 */
export const EVENTCALENDARTYPE = 'EVENTCALENDARTYPE';

/**
 * 普通日程类型字段
 */
export const NORMALEVENTTYPE = 'NORMALEVENTTYPE';

/**
 * 正数重要日程类型字段
 */
export const UPIMPORTANTEVENTTYPE = 'UPIMPORTANTEVENTTYPE';

/**
 * 倒数重要日程类型字段
 */
export const DOWNIMPORTANTEVENTTYPE = 'DOWNIMPORTANTEVENTTYPE';

/**
 * 日程类型字段
 */
export const EVENTTYPEEXT = 'EVENTTYPEEXT';

/**
 * 日程类型字段
 */
export const SOLAR = 'SOLAR';

/**
 * 日程类型字段
 */
export const LUNAR = 'LUNAR';

/**
 * 图片类型字段
 */
export const EVENTIMAGETYPE = 'EVENTIMAGETYPE';

/**
 * 待定字段
 */
export const TENTATIVE = 'TENTATIVE';

/**
 * 参加活动字段
 */
export const CONFIRMED = 'CONFIRMED';

/**
 * 取消字段
 */
export const CANCELLED = 'CANCELLED';

/**
 * 过期字段
 */
export const DECLINED = 'DECLINED';

/**
 * 私有字段
 */
export const PRIVATE = 'PRIVATE';

/**
 * 不在线字段
 */
export const CONFIDENTIAL = 'CONFIDENTIAL';

/**
 * 日程提醒类型字段
 */
export const EVENTALERTTYPE = 'EVENTALERTTYPE';

/**
 * 普通提醒
 */
export const NORMALALERT = 'NORMALALERT';

export const IMPORTANTALERT = 'IMPORTANTALERT';

/**
 * 解析的结果
 */
export enum ParseResult {
  // 解析严重错误,不能忽略
  FATAL_ERROR,
  // 解析错误,可以忽略
  ERROR,
  // 解析被处理
  PARSE_HANDLED,
  // 解析未处理
  PARSE_NOT_HANDLE
}

const TAG = 'CalendarParser';

/**
 * vcs文件解析为VcsComponent后,CalendarParser将VcsComponent解析为对应的Event,Account
 */
export abstract class CalendarParser {
  /**
   * 解析分享的日程文件
   *
   * @param component 数据源
   * @param eventInfo 日程对象
   * @param calendarInfo 辅助解析对象
   * @return 是否解析成功
   * @throws FormatException 类型转换异常
   */
  abstract parseEvent(component: VcsComponent, eventInfo: AgendaEventInfo,
    holidayAbbreviationArray: string[]): Promise<boolean>;

  /**
   * 解析夏令时RRULE
   *
   * @param component 数据源
   * @param calendarInfo 辅助解析对象
   */
  parseDayLight(component: VcsComponent, calendarInfo: CalendarInfo) {

  }

  /**
   * 如果是这种格式的"\\d{8}[T]\\d{6}[Z]" 转化为UTC时间 这种格式的表示localDate
   *
   * @param timeString
   * @param time
   * @param eventTimeZone
   * @returns Pair<boolean, CustomTime> 是否解析成功
   */
  parseStartAndEndTime(timeString: string, time: CustomTime, eventTimeZone: string): Pair<boolean, CustomTime> {
    Log.info(TAG, `parseStartAndEndTime timeString is ${timeString} eventTimeZone is ${eventTimeZone}`);
    if (EmptyUtils.isEmptyString(timeString)) {
      Log.warn(TAG, `parseStartAndEndTime timeString is empty`);
      return new Pair(false, time);
    }
    time.setTimeZone(eventTimeZone);
    if (!new FormatTime().parseByTimeString(timeString, time)) {
      Log.warn(TAG, `parseStartAndEndTime parseResult is false`);
      return new Pair(false, time);
    }
    return new Pair(true, time);
  }

  /**
   * 解析完一个event后,对event做最终的检查
   * @param eventInfo
   * @returns
   */
  protected finalCheck(eventInfo: AgendaEventInfo): boolean {
    if (eventInfo.mBegin <= 0) {
      Log.warn(TAG, `finalCheck false mBegin is ${eventInfo.mBegin} illegal`);
      return false;
    }
    if (EmptyUtils.isNotEmptyString(eventInfo.duration)) {
      return true;
    }
    // 纪念日 和倒数日 mEnd可能和mStart一样
    if (eventInfo.isImportantAnniversaries() || eventInfo.isImportantCountDown()) {
      return true;
    }
    const checkResult: boolean = eventInfo.mEnd >= eventInfo.mBegin;
    if (!checkResult) {
      Log.warn(TAG, `finalCheck false mEnd is ${eventInfo.mEnd} mBegin is ${eventInfo.mBegin}`);
    }
    return checkResult;
  }

  protected unfoldContentLineFolding(value: string): string {
    let unfoldedValue: string = '';
    unfoldedValue = value.replaceAll('\r\n ', '').replaceAll('\r\n\t', '');
    return unfoldedValue;
  }
}
