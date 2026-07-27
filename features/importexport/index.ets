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

/* instrument ignore file */

import { Log, ModuleName, NavPathName, ServiceEnum } from '@app/common';

export { QuotedPrintableHelper } from './src/main/ets/vcalendar/QuotedPrintableHelper';

export { ImportPage } from './src/main/ets/view/ImportPage';

export { ImportExportService } from './src/main/ets/interface/ImportExportService';

export { ImportCallBack } from './src/main/ets/interface/ImportCallBack';

export { ExportCallBack } from './src/main/ets/interface/ExportCallBack';

export { ExportVcsCallBack } from './src/main/ets/interface/ExportVcsCallBack';

export { ImportHolidayCallBack } from './src/main/ets/interface/ImportHolidayCallBack';

export { SimpleAccount } from './src/main/ets/interface/SimpleAccount';

export { ShareEventTextBean } from './src/main/ets/interface/ShareEventTextBean';

export { ImportData } from './src/main/ets/interface/ImportData';

export { ImportVcsCallBack } from './src/main/ets/interface/ImportVcsCallBack';

export { ShareEventVcsBean } from './src/main/ets/interface/ShareEventVcsBean';

export { PlaceholderComponent } from './src/main/ets/view/PlaceholderComponent';

export { ImportAgenda } from './src/main/ets/view/ImportAgenda';

export { BEGIN_V_CALENDAR, NEW_LINE, END_V_CALENDAR, V_SPLIT,
  BEGIN_V_EVENT, END_VEVENT } from './src/main/ets/vcalendar/VCalendarConstants';

export { VcsComponent } from './src/main/ets/vcalendar/import/model/VcsComponent';

export { ExportType,
  ImportType,
  ImportExportErrorCode,
  ShareType, ShareFileFormat } from './src/main/ets/interface/BusinessConstant';

export function harInit(builderName: NavPathName): boolean {
  Log.info(ModuleName.IMPORT_EXPORT, `harInit ${builderName}`);
  switch (builderName) {
    case NavPathName.IMPORT_ACCOUNT:
      import('./src/main/ets/view/account/ImportAccountRoot');
      break;
    case NavPathName.IMPORT_SHOW_AGENDA:
      import('./src/main/ets/view/agenda/ImportAllAgendaList');
      break;
    default:
      return false;
  }
  return true;
}

// Har包初始化函数
export function serviceInit(service: string): void {
  Log.info(ModuleName.IMPORT_EXPORT, `serviceInit ${service}`)
  switch (service) {
    case ServiceEnum.IMPORT_EXPORT_SERVICE:
      import('./src/main/ets/core/ImportExportService');
      break;
    default:
      break;
  }
  return;
}