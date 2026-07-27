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

import { AgendaEventInfo, CalendarContract, Log, TimeZoneUtil, UTC } from '@app/common';
import { CalendarInfo } from '../../CalendarInfo';
import HashMap from '@ohos.util.HashMap';
import { DateFormatPara } from './DateFormatPara';
import { TimeFormatType } from '@app/feature.repeatrule/src/main/ets/time/FormatTime';
import { ExportProgressListener } from '../../../ExportProgressListener';

const TAG = 'CalendarBuilder';

/**
 * 导出日程,账户构建者
 *
 */
export abstract class CalendarBuilder {
  protected calendarInfo: CalendarInfo;
  protected outputFilePath: string = '';
  /**
   * ISO 8601 格式,如果calendarInfo时区非法,设置为UTC,转化的时间格式为UTC格式
   */
  protected iso8601FormatPara: DateFormatPara;
  /**
   * 全天事件格式,获取的时区是当前的默认时区
   */
  protected mAllDayEventFormatPara: DateFormatPara;

  // todo 兼容 yyyyMMdd'T'HHmmss'Z' 时区
  constructor(calendarInfo: CalendarInfo) {
    this.calendarInfo = calendarInfo;
    let timeZoneId: string = '';
    let timeFormat: TimeFormatType = TimeFormatType.UTC;
    if (!calendarInfo || !TimeZoneUtil.isValidTimezone(calendarInfo.getTimezone())) {
      timeZoneId = UTC;
      timeFormat = TimeFormatType.UTC;
    } else {
      timeZoneId = calendarInfo.getTimezone();
      timeFormat = TimeFormatType.ISO8601;
    }
    this.iso8601FormatPara = new DateFormatPara(timeZoneId, timeFormat);
    this.mAllDayEventFormatPara = new DateFormatPara(TimeZoneUtil.getCurrentTimeZone(), TimeFormatType.YYYY_MM_DD);
  }

  abstract buildExportFile(account: CalendarContract.Accounts | undefined,
                           events: Array<AgendaEventInfo>,
                           remindersMap: HashMap<number, CalendarContract.Reminders[]>): Promise<boolean>

  /**
   * 设置保存的文件路径
   *
   * @param outputStream 输出流
   */
  public abstract setOutputFilePath(outputFilePath: string);

  public abstract getVersion(): string;

  /**
   * 折叠字符串
   *
   * @param str 输入字符串
   * @return 去掉换行后的字符串
   */
  protected foldString(str: string): string {
    return str.replaceAll('\r\n', '\\n').replaceAll('\n', '\\n');
  }

  protected unfoldContentLineFolding(value: string): string {
    let unfoldedValue: string = '';
    unfoldedValue = value.replaceAll('\r\n ', '').replaceAll('\r\n\t', '');
    return unfoldedValue;
  }

  /**
   * 移除换行符
   *
   * @param value 输入字符串
   * @return 去掉换行后的字符串
   */
  protected removeLinebreaks(value: string): string {
    return value.replaceAll('\n', '').replaceAll('\r', '');
  }

  cancel(): void {
  }
}

