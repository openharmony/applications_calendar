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
import { AccountColor, ALL_ACCOUNT_COLOR, oldAccountColorList } from '@app/common/src/main/ets/account/AccountColor';
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { CardAction } from '../common/CardAction';
import {
  CardSingleDayViewModel,
  CompressedDayData,
  CompressedDayDataIndex
} from '../monthCard/viewModel/components/CardSingleDayViewModel';
import { CardDeduplicateProcessor } from '../agendaCard/common/CardDeduplicateProcessor';

const TAG: string = 'CardUtils';

// 压缩月视图卡片的数据
export function compressData(dayData: CardSingleDayViewModel): CompressedDayData {
  return [
    dayData.year,
    dayData.month,
    dayData.day,
    dayData.isToday ? 1 : 0,
    dayData.mark,
    dayData.isCurrentMonth ? 1 : 0,
    dayData.isWeekends ? 1 : 0,
    dayData.showTagText ? 1 : 0,
    dayData.tagText,
    dayData.showRecessData ? 1 : 0,
    dayData.showLunarLine ? 1 : 0,
    dayData.hasFestivals ? 1 : 0,
    dayData.subscriptionCalendar ? 1 : 0,
    dayData.showChineseFestival ? 1 : 0,
    dayData.showChineseHolidayState
  ]
}

// 解压缩月视图卡片的数据
export function decompressData(compressedData: CompressedDayData): CardSingleDayViewModel {
  return new CardSingleDayViewModel(
    compressedData[CompressedDayDataIndex.Year],
    compressedData[CompressedDayDataIndex.Month],
    compressedData[CompressedDayDataIndex.Day],
    compressedData[CompressedDayDataIndex.IsToday] === 1,
    compressedData[CompressedDayDataIndex.Mark],
    compressedData[CompressedDayDataIndex.IsCurrentMonth] === 1,
    compressedData[CompressedDayDataIndex.IsWeekends] === 1,
    compressedData[CompressedDayDataIndex.ShowTagText] === 1,
    compressedData[CompressedDayDataIndex.TagText],
    compressedData[CompressedDayDataIndex.ShowRecessData] === 1,
    compressedData[CompressedDayDataIndex.ShowLunarLine] === 1,
    compressedData[CompressedDayDataIndex.HasFestivals] === 1,
    compressedData[CompressedDayDataIndex.SubscriptionCalendar],
    compressedData[CompressedDayDataIndex.ShowChineseFestival] === 1,
    compressedData[CompressedDayDataIndex.ShowChineseHolidayState]
  )
}

// 获取账户颜色的映射
export function getAccountColor(nowAccountColor: number): number {
  for (const oldAccountColor of oldAccountColorList) {
    if (nowAccountColor === oldAccountColor.oldAccountColor ||
      nowAccountColor === (oldAccountColor.oldAccountColor & 0xFFFFFF)) {
      return oldAccountColor.nowAccountColor;
    }
  }
  return ALL_ACCOUNT_COLOR.includes(nowAccountColor) ? nowAccountColor : AccountColor.RED;
}

/**
 * 对文本字段做长度限制，这里分别限制为300,200，各提供100字符的冗余
 * 经测试，pc手机最小字体能展示44个汉字，93个英文字母，78个数字,188个i字符
 * 经测试，pc手机最小字体能展示26个汉字，54个英文字母，46个数字，112个i字符
 */
export const TITLE_LIMIT_LENGTH: number = 300;

export const EVENTLOCATION_LIMIT_LENGTH: number = 200;

/**
 * 卡片恢复等场景，卡片框架的跨天刷新事件可能丢失，此处针对该场景进行校验并重试刷新
 *
 * @param component 组件实例
 * @param curJulianDay 当前的儒略日
 */
export function crossDayExceptionCheckAndRetry(component: Object, curJulianDay: number) {
  const newJulianDayOfNow = FormUtils.getCurrentJulianDay();
  if (newJulianDayOfNow === curJulianDay) {
    Log.warn(TAG, `crossDayExceptionCheckAndRetry The julianDay is the same. Do not refresh_retry.`)
    return;
  }
  Log.warn(TAG, `crossDayExceptionCheckAndRetry oldJulainDay= ${curJulianDay}, newJulainDay= ${newJulianDayOfNow}`);
  postCardAction(component, {
    action: 'message',
    params: {
      message: CardAction.REFRESH_MONTH_VIEW
    }
  });
}

/**
 * 将数据代理查询的Object数组转化为类数组
 * @param agendaObjList 查询数据库返回的数据
 * @param 卡片ID
 * @returns 转化后的 AgendaCardInfo 数组
 */
export function parseObjToAgendaArray(agendaObjList: Array<AgendaCardInfo>, formId: string): Array<AgendaCardInfo> {
  Log.info(TAG, `formId: ${formId} parseObjToAgendaArray start.`);
  let agendaList: AgendaCardInfo[] = [];
  agendaObjList.forEach((agendaObj: object) => {
    let agenda: AgendaCardInfo = new AgendaCardInfo();
    agenda.parseFromObj(agendaObj);
    agendaList.push(agenda);
  })
  const newAgendaList = CardDeduplicateProcessor.INSTANCE.reduceAgendaCardInfos(agendaList);
  Log.info(TAG, `formId: ${formId} parseObjToAgendaArray oldListLength: ${agendaList?.length}, newListLength: ${newAgendaList?.length}`);
  return newAgendaList;
}