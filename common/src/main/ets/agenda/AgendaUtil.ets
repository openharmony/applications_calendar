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

import { CompId } from '../constants/CompId';
import { GlobalThis } from '../data/GlobalThis';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { Log } from '../default/common/Log';
import { AgendaEventInfo } from './AgendaEventInfo';
import { AgendaListItemViewModel } from './AgendaListDataSource';
import { common } from '@kit.AbilityKit';
import { maskString } from '../util/SensitiveStrUtils';

const TAG = 'AgendaUtil';

export const NEWLINE_SYMBOL: string = '\n';

export interface IRichText {
  isHighLight: boolean;
  text: string | Resource;
}
;



export enum MapNavigationType {
  Navigation = 1,
  Search = 3,
}
export class AgendaUtil {
  /**
   * 获取显示的标题信息
   *
   * @param agendaTitle: 日程标题
   * @param searchText: 搜索文本
   */
  public static transTitleMessage(agendaTitle: string, searchText: string): IRichText[] {
    let titleSpanStrList: IRichText[] = [];

    if (agendaTitle.length === 0) {
      titleSpanStrList.push({ isHighLight: false, text: $r('app.string.no_title_label') });
      return titleSpanStrList;
    }

    if (searchText && searchText.length !== 0) {
      titleSpanStrList = AgendaUtil.getIRichTextArray(agendaTitle, searchText);
      return titleSpanStrList;
    }

    titleSpanStrList.push({ isHighLight: false, text: agendaTitle });
    return titleSpanStrList;
  }

  /**
   * 根据关键字获取包含是否高亮信息的数组
   *
   * @param text: 原始文本
   * @param keyWord: 关键字
   */
  public static getIRichTextArray(text: string, keyWord: string): IRichText[] {
    try {
      const reText: string = AgendaUtil.filterEmLabel(text);
      const keyWordRep = keyWord.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const splitArr = reText.split(new RegExp(`(${keyWordRep})`, 'i')); // 添加不区分大小写的标志 ‘i’
      const filterArr = splitArr.filter(item => {
        return item.length > 0;
      });
      const resultTitleObj = filterArr.map(text => {
        let temp: IRichText = {
          isHighLight: text.toLowerCase() === keyWord.toLowerCase(), // 转换为小写进行比较
          text
        };
        return temp;
      });
      return resultTitleObj;
    } catch (err) {
      Log.logErrorMsg(TAG, 'failed to getIRichTextArray', err);
      return [];
    }
  }

  /**
   * 获取过滤掉<em>标签后的文本
   *
   * @param text: 原始文本
   */
  public static filterEmLabel(text: string): string {
    const FILTER_EMPHASE_REG_EXP_LEFT: RegExp = new RegExp('<em>', 'g'); // 过滤 <em> 标签
    const FILTER_EMPHASE_REG_EXP_RIGHT: RegExp = new RegExp('</em>', 'g'); // 过滤 </em> 标签
    const FILTER_EMPHASE_OTHER: RegExp = new RegExp('&#x2f;', 'g');
    const FILTER_EMPHASE_POS: string = ''; // em 标签内容位置
    const FILTER_EMPHASE_LABEL: string = '/';
    if (text?.length === 0) {
      return '';
    }
    return text.replace(FILTER_EMPHASE_REG_EXP_LEFT, FILTER_EMPHASE_POS)
      .replace(FILTER_EMPHASE_REG_EXP_RIGHT, FILTER_EMPHASE_POS)
      .replace(FILTER_EMPHASE_OTHER, FILTER_EMPHASE_LABEL);
  }

  /**
   * 找到数组里面的冲突日程
   */
  public static async findConflictAgenda(events: AgendaEventInfo[]): Promise<void> {
    return new Promise<void>((resolve, reject)=>{
      if (events.length <= 1) {
        return;
      }
      let dummyEvent = new AgendaEventInfo();
      dummyEvent.mEnd = -1;
      events = events.sort((a, b) => a.mBegin - b.mBegin);
      let last = dummyEvent;
      for (let i = 0; i < events.length; i++) {
        if (events[i].isHoliday() || events[i].mIsAllDay) {
          continue;
        }
        if (events[i].mBegin < last.mEnd) {
          events[i].isConflict = true;
          last.isConflict = true;
        }
        if (events[i].mEnd >= last.mEnd) {
          last = events[i];
        }
      }
      return;
    })
  }

  public static filterDupByEventId(events: AgendaListItemViewModel[],
                                   filterHoliday: boolean = true): AgendaListItemViewModel[] {
    let filtered = events.filter((item, i, arr) => {
      if (filterHoliday && item.isHoliday()) {
        return false;
      }
      return !item.isContactBirthday();
    })
    return filtered;
  }

  // 打印日程相关信息
  public static logAgenda(event: AgendaEventInfo) {
    Log.info(TAG, `logAgenda id: ${event.mId}, title: ${maskString(event.mTitle)}, ` +
      `begin: ${event.mBegin}, end: ${event.mEnd}, creator: ${event.mCreator}`);
  }

  public static isMeetingService(event: AgendaEventInfo) {
    if (!event.mHwextServiceVerified) {
      return false;
    }
    return event.mHwextServiceType === CalendarContract.HwExtServiceType.Meeting;
  }
  /**
   * 查询默认地址
   *
   * @param location: 地址数据
   * @return 查询默认地址
   */
  public static getLocation(location: string): string {
    let locationInfo = location.split(NEWLINE_SYMBOL);
    return locationInfo[0];
  }

  /**
   * 查询地址副标题
   *
   * @param location: 地址数据
   * @return 如果有副标题，则返回副标题，否则返回''
   */
  public static getFormatLocation(location: string): string {
    let locationInfo = location.split(NEWLINE_SYMBOL);
    if (locationInfo.length < 2) {
      return '';
    }
    return locationInfo[1];
  }

  /**
   * 检验agendaEventInfo 经纬度有效返回true 无效返回false
   *
   * @param latitude:纬度 longitude:经度
   * @return 经纬度有效返回true 无效返回false
   */
  public static isLocationValid(latitude: number, longitude: number): boolean {
    return !((latitude === -1 && longitude === -1) ||
      (latitude === 0 && longitude === 0) || (latitude === 0 && longitude === -1));
  }

  /**
   * 封装副标题
   *
   * @param administrativeArea: 省级地址
   * @param locality: 市级地址
   * @param subLocality: 区级地址
   * @param roadName: 街道地址
   * @return 地址副标题
   */
  public static getFormatAddress(administrativeArea: string, locality: string,
    subLocality: string, roadName:string):string {
    let formatAddress = '';
    if (administrativeArea === locality) {
      formatAddress = locality + subLocality + roadName;
    } else {
      formatAddress = administrativeArea + locality + subLocality + roadName;
    }
    return formatAddress;
  }

  public static getShareIdByIndexAndInfo(info: AgendaEventInfo, index: number = -1) {
    return `${CompId.NORMAL_AGENDA_LIST_ITEM}-${index}-${info.mId}-${info.mBegin}`;
  }

  public static jumpMapLocationInfoPage(location: string, latitude: number,
    longitude: number, context?: common.UIAbilityContext) {
    if (!context) {
      Log.warn(TAG, 'jumpMapLocationInfoPage context is null');
      return;
    }
    let wantParam: Record<string, Object> = {};
    if (AgendaUtil.isLocationValid(latitude, longitude)) {
      wantParam = {
        'sceneType': MapNavigationType.Navigation,
        'destinationLatitude': latitude,
        'destinationLongitude': longitude,
        'destinationName': location,
        'vehicleType': 0
      };
    } else {
      wantParam = {
        'sceneType': MapNavigationType.Search,
        'destinationName': location
      };
    }
    let abilityStartCallback: common.AbilityStartCallback = {
      onError: (code: number, name: string, message: string) => {
        Log.error(TAG, `onError code ${code} name: ${name} message: ${message}`);
      },
      onResult: (result)=>{
        Log.info(TAG, `onResult result: ${result.resultCode}`);
      }
    }
    context.startAbilityByType('navigation', wantParam, abilityStartCallback,
      (err) => {
        if (err) {
          Log.error(TAG, `startAbilityByType fail, err: ${err.message}`);
        } else {
          Log.info(TAG, `startAbilityByType success`);
        }
      });
  }

}