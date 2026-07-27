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
import { AgendaCardInfo, FormUtils } from '@app/common/src/main/ets/card/AgendaFormCommonStruct';
import { ImportantEntity } from '../importantCard/model/ImportantEntity';
import { FormName } from './FormName';
import { maskString } from '@app/common/src/main/ets/util/SensitiveStrUtils';

const TAG: string = 'CardJumpUtils';

export const CARD_AGENDA = 'agenda_fa';

export const CARD_IMPORTANT = 'important_fa';

export const DIMENSION_2_2 = '2x2';

export const DIMENSION_2_4 = '2x4';

export const DIMENSION_4_4 = '4x4';

export const DIMENSION_6_4 = '6x4';

export function jumpToAgendaDetail(component: Object, info: AgendaCardInfo | ImportantEntity, faType: string,
                                   dimension: string, needCommerce: boolean) {
  if (!component || !info) {
    Log.error(TAG, `jumpToAgendaDetail get invalid params`);
    return;
  }
  let eventId: number = 0;
  let begin: number = 0;
  let end: number = 0;
  let calendarType : string | undefined = undefined;
  if (info instanceof AgendaCardInfo) {
    eventId = info.mEventId;
    begin = info.mBegin;
    end = info.mEnd;
    calendarType = info.mCalendarType;
    Log.info(TAG, `Jump to agenda,id: ${info.mEventId} begin: ${info.mBegin} end: ${info.mEnd}`);
  } else if (info instanceof ImportantEntity) {
    eventId = info.eventId;
    begin = info.begin;
    end = info.end;
    calendarType = info.accountType;
    Log.info(TAG, `Jump to agenda,id: ${info.eventId} begin: ${info.begin} end: ${info.end}`);
  }
  if (needCommerce) { // PC商务化跳转多实例窗口
    postCardAction(component, {
      'action': 'router',
      'bundleName': 'com.ohos.calendar',
      'abilityName': 'AgendaAbility',
      'params': {
        'action': 'CLICK_AGENDA_DETAIL',
        'eventId': eventId,
        'dimension': dimension,
        'calendarType': calendarType,
        'faType': faType,
        'instanceStartMills': `${begin}`,
        'instanceEndMills': `${end}`,
        'instanceKey': `${eventId}`
      }
    });
    return;
  }
  postCardAction(component, {
    'action': 'router',
    'bundleName': 'com.ohos.calendar',
    'abilityName': 'MainAbility',
    'params': {
      'action': 'CLICK_AGENDA_DETAIL',
      'id': eventId,
      'dimension': dimension,
      'calendarType': calendarType,
      'faType': faType,
      'instanceStartMills': `${begin}`,
      'instanceEndMills': `${end}`
    }
  });
}

/**
 * 跳转到一键服务
 */
export function jumpToServiceApp(obj: FormUtils, want: Want) {
  Log.info(TAG, 'Jump to service app');
  postCardAction(obj, {
    'action': 'router',
    'bundleName': want.bundleName ? want.bundleName : '',
    'uri': want.uri ? want.uri : '',
    'params': want.parameters
  });
}

export function jumpToMonthView(obj: Object, year: number, month: number, day: number,
                                formId: string = '', faType?: FormName) {
  Log.info(TAG, `formId: ${formId} Jump to month view, year: ${year}, month: ${month + 1}, day: ${day}`);
  try {
    postCardAction(obj, {
      'action': 'router',
      'bundleName': 'com.ohos.calendar',
      'abilityName': 'MainAbility',
      'params': {
        'action': 'CLICK_MONTH_FORM_HEADER',
        'tabIndex': '1',
        'year': year,
        'month': month,
        'day': day,
        'faType': faType
      }
    });
  } catch (err) {
    Log.error(TAG, `jumpToMonthView error: ${err?.message}`);
  }
}