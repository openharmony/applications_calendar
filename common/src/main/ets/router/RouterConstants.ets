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

import { ModuleName } from '../constants/Module';
import { NavPathName } from '../constants/NavPathName';


interface builderInfo {
  harName : string,
  pathName : string
}

export const harBuilderConfig: ReadonlyArray<builderInfo> = [
  { pathName : NavPathName.AGENDA_LIST, harName : ModuleName.AGENDA },
  { pathName : NavPathName.AGENDA_DETAIL, harName : ModuleName.AGENDA },
  { pathName : NavPathName.ATTENDEE_LIST, harName : ModuleName.AGENDA },
  { pathName : NavPathName.FLEX_SEARCH_AGENDA, harName : ModuleName.AGENDA },
  { pathName : NavPathName.SETTINGS_TIME_ZONE, harName : ModuleName.AGENDA },
  { pathName : NavPathName.CREATE_AGENDA_SUB, harName : ModuleName.AGENDA },

  { pathName: NavPathName.SETTING_MAIN, harName: ModuleName.SETTINGS },
  { pathName: NavPathName.SETTING_ABOUT, harName: ModuleName.SETTINGS },
  { pathName: NavPathName.SETTINGS_NATIONAL_REGION_HOLIDAY, harName: ModuleName.SETTINGS },
  { pathName: NavPathName.APP_DISPLAY_RECORD_DETAIL, harName: ModuleName.SETTINGS },
  { pathName: NavPathName.SETTINGS_TIME_ZONE, harName: ModuleName.SETTINGS },

  { pathName: NavPathName.MESSAGE_CENTER_MAIN, harName: ModuleName.SHARE },
  { pathName: NavPathName.SHARE_AGENDA, harName: ModuleName.SHARE },
  { pathName: NavPathName.SHARE_ACCOUNT, harName: ModuleName.SHARE },

  { pathName : NavPathName.IMPORT_ACCOUNT, harName : ModuleName.IMPORT_EXPORT },
  { pathName : NavPathName.IMPORT_SHOW_AGENDA, harName : ModuleName.IMPORT_EXPORT },

  { pathName : NavPathName.CUSTOM_REPEAT, harName : ModuleName.REPEAT_RULE },
]

// Indicates the key of the routerMap table in the NavPageBuilderFactory.
export enum RouterName {
  ENTRY_HAP = 'EntryHap_Router',
  SETTING_HAP = 'Setting_Main_Router',
  CREATE_AGENDA_MAIN = 'Create_Agenda_Main_Router',
  SEARCH_AGENDA_MAIN = 'Search_Agenda_Main_Router',
  SYSTEM_SETTING_PRIVACY = 'SYSTEM_SETTING_PRIVACY_ROUTER',
  AGENDA_DETAIL_HAP = 'Agenda_Detail_Router',
}