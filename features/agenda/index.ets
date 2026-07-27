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

export { AgendaDetailSource } from './src/main/ets/common/AgendaEnum';

export { FlexAgendaList } from './src/main/ets/components/FlexAgendaList';

export { AgendaDetail } from './src/main/ets/AgendaDetail/view/AgendaDetail';

export { AgendaDetailCover } from './src/main/ets/AgendaDetail/view/AgendaDetailCover';

export { AgendaDetailPopup } from './src/main/ets/AgendaDetail/view/AgendaDetailPopup';

export { CreateAgenda } from './src/main/ets/CreateAgenda/view/CreateAgenda';

export { PreviewContent } from './src/main/ets/AgendaPreview/view/PreviewContent';

export { DeleteToolBar } from './src/main/ets/components/DeleteToolBar';

export { FlexSearchAgenda } from './src/main/ets/components/FlexSearchAgenda';

export { AgendaType } from './src/main/ets/CreateAgenda/Constants';

export { SaveTimeType } from './src/main/ets/CreateAgenda/Constants';

export { CreateAgendaPageSource } from './src/main/ets/CreateAgenda/Constants';

export { ImportantAgendaItem } from './src/main/ets/components/ImportantAgendaItem';

export { EditAgendaMenu } from './src/main/ets/components/EditAgendaMenu';

export { AgendaListDataModel, AutoQueryResult } from './src/main/ets/AgendaList/model/AgendaListDataModel';

export { DeleteAgendaRadio, DeleteMode } from './src/main/ets/components/DeleteAgendaRadio';

export { CopyHelper } from './src/main/ets/helpers/CopyHelper';

export { CreatePopupContent, getPopOffsetY } from './src/main/ets/CreateAgenda/view/CreatePopupContent';

export { CreateAgendaRoot } from './src/main/ets/CreateAgenda/view/CreateAgendaRoot';

export { PasteHelper } from '@app/common/src/main/ets/util/PasteHelper';

export { AgendaOperateHelper } from './src/main/ets/helpers/AgendaOperateHelper';

export {
  AgendaPopupContent, generateAgendaOption
} from './src/main/ets/AgendaDetail/view/AgendaPopupContent';

export {
  AgendaEditMenuOpt,
  AgendaMenuOpt,
  DEFAULT_AGENDA_MENU_OPTS,
  generateAgendaEditOption,
} from './src/main/ets/AgendaDetail/view/AgendaMenu';

export { AgendaMenu } from './src/main/ets/AgendaDetail/view/AgendaMenu';

export { AgendaListItemContent } from './src/main/ets/AgendaDetail/view/AgendaListItemContent';

export { CreateAgendaSubRoot } from './src/main/ets/CreateAgenda/view/CreateAgendaSubRoot';

// Har包初始化函数
export function harInit(builderName: NavPathName): boolean {
  Log.info('agenda', `harInit ${builderName}`)
  switch (builderName) {
    case NavPathName.ATTENDEE_LIST:
      import('./src/main/ets/components/AttendeeList');
      break;
    case NavPathName.AGENDA_LIST:
      import('./src/main/ets/components/AgendaListPage');
      break;
    case NavPathName.AGENDA_DETAIL:
      import('./src/main/ets/AgendaDetail/view/AgendaDetailRoot');
      break;
    case NavPathName.MULTI_DELETE:
      import('./src/main/ets/components/DeleteList');
      break;
    case NavPathName.FLEX_SEARCH_AGENDA:
      import('./src/main/ets/components/FlexSearchAgendaRoot');
      break;
    case NavPathName.CREATE_AGENDA_SUB:
      import('./src/main/ets/CreateAgenda/view/CreateAgendaSubRoot');
      break;
    default:
      return false;
  }
  return true;
}

// Service初始化
export async function serviceInit(service: string): Promise<boolean> {
  Log.info(ModuleName.AGENDA, `serviceInit ${service}`)
  switch (service) {
    case ServiceEnum.AGENDA_DELETE_SERVICE:
      await import('./src/main/ets/service/agendaDeleteServiceImpl');
      break;
    case ServiceEnum.AGENDA_SERVICE:
      await import('./src/main/ets/service/AgendaServiceImpl');
      break;
    default:
      return false;
  }
  return true;
}