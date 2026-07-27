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

import data_rdb from '@ohos.data.relationalStore';
import ohosDataRdb from '@ohos.data.relationalStore';
import { PushMessage } from '../../database/pushmessagedb/pushmessage/PushMessage';
import { PushMessageColumns } from '../../database/pushmessagedb/pushmessage/PushMessageColumns';
import { dataSharePredicates } from '@kit.ArkData';
import { PushMessageRepository } from '../repo/PushMessageRepository';
import { Result } from '../../templates/Result';
import { Log } from '../../default/common/Log';
import { EmptyUtils } from '../../util/EmptyUtils';
import { ErrorCode } from '../../commoncapability/error/ErrorCode';

// 涉消息通知，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG = 'PushMessageService';

export class PushMessageService {
  public static readonly INSTANCE: PushMessageService = new PushMessageService();
  public dao: PushMessageRepository;

  private constructor() {
    this.dao = new PushMessageRepository();
  }

  async queryPushMessage(pushType: string): Promise<Result<PushMessage[]>> {
    if (EmptyUtils.isEmptyString(pushType, true)) {
      Log.warn(TAG, `queryPushMessage is empty`);
      return new Result(ErrorCode.ILLEGAL_CODE, 'dirty pushType', []);
    }
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(PushMessageColumns.PUSH_TYPE, pushType);
    const resultSet: Result<ohosDataRdb.ResultSet | undefined> = await
    //this.dao.queryPushMessage(pushType);
    if (!resultSet.isSuccess()) {
      return Result.copyResult(resultSet, []);
    }
    const pushMessageList: PushMessage[] = this.parseResultSetToPush(resultSet.data!);
    if (EmptyUtils.isEmptyArray(pushMessageList)) {
      Log.warn(TAG, `queryPushMessage pushType is ${pushType} result is null`);
      return Result.buildSuccessResult([]);
    }
    return Result.buildSuccessResult(pushMessageList);
  }

  private parseResultSetToPush(resultSet: ohosDataRdb.ResultSet): PushMessage[] {
    let pushMessages: PushMessage[] = [];
    try {
      if (resultSet.rowCount <= 0) {
        Log.info(TAG, 'resultSet rowCount is 0');
        return pushMessages;
      }
      if (!resultSet.goToFirstRow()) {
        Log.error(TAG, 'parseResultSetToPush ResultSet go To first row failed');
        return pushMessages;
      }
      do {
        const pushMessage = this.parsePushMessage(resultSet);
        pushMessages.push(pushMessage);
      } while (resultSet.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseResultSetToPush', err);
    } finally {
      resultSet?.close();
    }
    return pushMessages;
  }

  private parsePushMessage(resultSet: data_rdb.ResultSet): PushMessage {
    const pushMessage: PushMessage = new PushMessage();
    let index = resultSet.getColumnIndex(PushMessageColumns.ID);
    if (index >= 0) {
      pushMessage.id = resultSet.getLong(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.MESSAGE_ID);
    if (index >= 0) {
      pushMessage.messageId = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.PUSH_TYPE);
    if (index >= 0) {
      pushMessage.pushType = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.MESSAGE_ACTION);
    if (index >= 0) {
      pushMessage.messageAction = resultSet.getLong(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.MESSAGE);
    if (index >= 0) {
      pushMessage.message = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.FIELD1);
    if (index >= 0) {
      pushMessage.field1 = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.FIELD2);
    if (index >= 0) {
      pushMessage.field2 = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.FIELD3);
    if (index >= 0) {
      pushMessage.field3 = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.FIELD4);
    if (index >= 0) {
      pushMessage.field4 = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.FIELD5);
    if (index >= 0) {
      pushMessage.field5 = resultSet.getString(index);
    }
    index = resultSet.getColumnIndex(PushMessageColumns.CREATE_TIME);
    if (index >= 0) {
      pushMessage.createTime = resultSet.getLong(index);
    }
    return pushMessage;
  }
}