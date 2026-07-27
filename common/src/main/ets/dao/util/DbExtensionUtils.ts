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

import relationalStore from '@ohos.data.relationalStore';
import { Log } from '../../default/common/Log';
import { InnerResultSet } from './InnerResultSet';

const TAG: string = 'DbExtensionUtils';

export function closeResultSet(resultSet: relationalStore.ResultSet): void {
  try {
    resultSet?.close();
  } catch (error) {
    Log.logErrorMsg(TAG, 'closerResultSet', error);
  }
}

export function closeDataShareResultSet(resultSet: InnerResultSet): void {
  try {
    resultSet?.close();
  } catch (error) {
    Log.logErrorMsg(TAG, 'closeDataShareResultSet', error);
  }
}