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

import {
  behaviorEvents,
  CalendarContract,
  CalendarDataFeature,
  CalendarDataFeatureHelper,
  DBUtils,
  EmptyUtils,
  factory,
  GlobalThis,
  InnerResultSet,
  Log,
  maskString,
  ReportHiEventParams,
  ReportUtil,
  ServiceEnum,
  SqlFaultHandle,
  statisticEvents,
  traceEvents
} from '@app/common';
import { common } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import AttachmentServiceProxy from '../idl/AttachmentServiceProxy';
import { AgendaAttachmentService } from '../interface/AgendaAttachmentService';
import { ArkTSUtils } from '@kit.ArkTS';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { dataSharePredicates, ValuesBucket } from '@kit.ArkData';
import { AttachmentColumn } from '../entity/AttachmentColumn';
import { AttachmentInfo } from '../entity/AttachmentInfo';

const TAG: string = 'AttachmentServiceImpl';

const CONNECT_SERVICE_LOCK: string = 'ConnectAttachmentServiceLock';

const ATTACHMENT_SERVICE_WANT: Want = {
  deviceId: '',
  bundleName: 'com.ohos.calendardata',
  abilityName: 'AttachmentServiceExtAbility'
}

const queryColumns: string [] = [
  AttachmentColumn.ID,
  AttachmentColumn.UUID,
  AttachmentColumn.EVENT_ID,
  AttachmentColumn.EVENT_UUID,
  AttachmentColumn.EVENT_GUID,
  AttachmentColumn.DISPLAY_NAME,
  AttachmentColumn.FILE_PATH,
  AttachmentColumn.FILE_TYPE,
  AttachmentColumn.FILE_SIZE,
  AttachmentColumn.CREATE_TIME,
  AttachmentColumn.SOURCE,
  AttachmentColumn.DIRTY,
  AttachmentColumn.SYNC_ENABLE,
  AttachmentColumn.SYNC_STATUS,
  AttachmentColumn.EXT_1,
  AttachmentColumn.EXT_2,
  AttachmentColumn.EXT_3,
]

export interface AddAttachmentResult {
  resultCode: number;
  filePath: string;
}

export interface AcquireAttachmentUriResult {
  resultCode: number;
  fileUri: string;
}

const SERVICE_AUTO_RELEASE_TIME: number = 30 * 1000;

// service端IPC通信的proxy接口
let serviceProxy: AttachmentServiceProxy | null = null;

@factory(ServiceEnum.ATTACHMENT_SERVICE)
export class AttachmentServiceImpl extends AgendaAttachmentService {
  // service连接的id
  private connectionId: number = 0;
  // 延时自动释放service的任务id
  private timeoutId: number = 0;

  constructor() {
    super(ServiceEnum.ATTACHMENT_SERVICE);
  }

  public async addAttachment(plainText: string): Promise<string> {
    Log.info(TAG, 'addAttachment plainText = ' + maskString(plainText));
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'addAttachment not support');
      return '';
    }
    this.delayAutoReleaseService();
    return new Promise<string>(async resolve => {
      if (!serviceProxy) {
        await this.connectServiceLocked();
      }
      if (serviceProxy) {
        serviceProxy.addAttachment(plainText, (code: number, result: string) => {
          let addAttachmentResult: AddAttachmentResult = {
            resultCode: code,
            filePath: result
          };
          resolve(JSON.stringify(addAttachmentResult));
        });
      } else {
        Log.warn(TAG, `decrypt no serviceProxy`);
        resolve('');
      }
    });
  }

  public async acquireAttachmentUri(plainText: string,): Promise<string> {
    Log.info(TAG, 'attachment plainText = ' + maskString(plainText));
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'attachment remote app not support');
      return '';
    }
    this.delayAutoReleaseService();
    return new Promise<string>(async resolve => {
      if (!serviceProxy) {
        await this.connectServiceLocked();
      }
      if (serviceProxy) {
        serviceProxy.acquireAttachmentUri(plainText, (code: number, result: string) => {
          let acquireResult: AcquireAttachmentUriResult = {
            resultCode: code,
            fileUri: result
          };
          resolve(JSON.stringify(acquireResult));
        });
      } else {
        Log.warn(TAG, `decrypt no serviceProxy`);
        resolve('');
      }
    });
  }

  private async connectServiceLocked(): Promise<void> {
    const lock = ArkTSUtils.locks.AsyncLock.request(CONNECT_SERVICE_LOCK);
    await lock.lockAsync(async () => {
      Log.info(TAG, `connectService begin`);
      const result: boolean = await this.connectService();
      Log.info(TAG, `connectService result=${result}`);
    });
  }

  private async connectService(): Promise<boolean> {
    return new Promise<boolean>((resolve, reject) => {
      let context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
      if (!context) {
        Log.warn(TAG, 'init get invalid context');
        resolve(false);
        return;
      }
      if (serviceProxy) {
        Log.warn(TAG, 'serviceProxy not null, no need init');
        resolve(true);
        return;
      }
      // 建立连接后返回的Id需要保存下来，在解绑服务时需要作为参数传入
      this.connectionId = context.connectServiceExtensionAbility(ATTACHMENT_SERVICE_WANT, {
        onConnect(elementName, remote: rpc.IRemoteObject): void {
          Log.info(TAG, 'onConnect callback');
          if (remote === null) {
            Log.error(TAG, `onConnect remote is null`);
            resolve(false);
            return;
          }
          serviceProxy = new AttachmentServiceProxy(remote);
          resolve(serviceProxy !== null);
        },
        onDisconnect(elementName): void {
          Log.info(TAG, 'onDisconnect callback');
          serviceProxy = null;
        },
        onFailed(code: number): void {
          Log.info(TAG, 'onFailed callback: ' + code);
          resolve(false);
        }
      });
      Log.info(TAG, `connectionId is : ${this.connectionId}`);
    });
  }

  private async disConnectService(): Promise<boolean> {
    let context: common.UIAbilityContext | null = GlobalThis.getInstance().context;
    if (!context) {
      Log.warn(TAG, 'unInit get invalid context');
      return false;
    }
    try {
      await context.disconnectServiceExtensionAbility(this.connectionId);
      this.connectionId = 0;
      serviceProxy = null;
      Log.info(TAG, 'disconnectServiceExtensionAbility success');
      return true;
    } catch (err) {
      Log.logErrorMsg(TAG, 'disconnectServiceExtensionAbility failed', err);
      return false;
    }
  }

  delayAutoReleaseService(): void {
    if (this.timeoutId > 0) {
      clearTimeout(this.timeoutId);
    }
    this.timeoutId = setTimeout(async () => {
      await this.disConnectService();
    }, SERVICE_AUTO_RELEASE_TIME);
  }

  // 批量插入附件
  async batchInsertAttachments(attachmentList: AttachmentInfo[], eventUuid: string): Promise<number> {
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'batchInsertAttachments is not support');
      return -1;
    }
    if (!attachmentList || attachmentList.length === 0) {
      Log.warn(TAG, 'batchInsertAttachments attachmentList is empty');
      return -1;
    }
    const data = new Date().getTime();
    const size: number[] = [];
    const values: ValuesBucket[] = [];
    for (let index = 0; index < attachmentList.length; index++) {
      const value: ValuesBucket = {} as ValuesBucket;
      const attachment: AttachmentInfo = attachmentList[index];
      value[AttachmentColumn.EVENT_UUID] = eventUuid;
      value[AttachmentColumn.DISPLAY_NAME] = attachment.displayName;
      value[AttachmentColumn.FILE_PATH] = attachment.filePath;
      value[AttachmentColumn.FILE_TYPE] = attachment.fileType;
      value[AttachmentColumn.FILE_SIZE] = attachment.fileSize;
      value[AttachmentColumn.CREATE_TIME] = data;
      value[AttachmentColumn.SOURCE] = attachment.source;
      values.push(value);
      size.push(attachment.fileSize);
    }
    hiTraceMeter.startTrace(traceEvents.batchInsertAttachment, 0);
    const count = await DBUtils.INSTANCE.batchInsert(DBUtils.INSTANCE.URI_EVENT_ATTACHMENTS, values, TAG);
    hiTraceMeter.finishTrace(traceEvents.batchInsertAttachment, 0);
    const params: ReportHiEventParams = {
      ATTACHMENT_COUNT: attachmentList.length,
      ATTACHMENT_SIZE: size
    };
    ReportUtil.reportStatisticEvent(statisticEvents.attachmentInfo, params);
    ReportUtil.reportBehaviorEvent(behaviorEvents.attachmentAdd);
    return count;
  }

  /**
   * 插入附件
   *
   * @param attachment 附件
   * @returns 结果
   */
  async insertAttachment(attachment: AttachmentInfo, eventUuid: string): Promise<number> {
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'insertAttachment is not support');
      return -1;
    }
    if (!attachment) {
      Log.warn(TAG, 'insertAttachment attachmentList is empty');
      return -1;
    }
    const value: ValuesBucket = {} as ValuesBucket;
    value[AttachmentColumn.EVENT_UUID] = eventUuid;
    value[AttachmentColumn.DISPLAY_NAME] = attachment.displayName;
    value[AttachmentColumn.FILE_PATH] = attachment.filePath;
    value[AttachmentColumn.FILE_TYPE] = attachment.fileType;
    value[AttachmentColumn.FILE_SIZE] = attachment.fileSize;
    value[AttachmentColumn.CREATE_TIME] = new Date().getTime();
    value[AttachmentColumn.SOURCE] = attachment.source;

    hiTraceMeter.startTrace(traceEvents.insertAttachment, 0);
    const count = await DBUtils.INSTANCE.insert(DBUtils.INSTANCE.URI_EVENT_ATTACHMENTS, value, TAG);
    hiTraceMeter.finishTrace(traceEvents.insertAttachment, 0);
    const params: ReportHiEventParams = {
      ATTACHMENT_COUNT: 1,
      ATTACHMENT_SIZE: [attachment.fileSize]
    };
    ReportUtil.reportStatisticEvent(statisticEvents.attachmentInfo, params);
    ReportUtil.reportBehaviorEvent(behaviorEvents.attachmentAdd);
    return count;
  }

  async deleteAttachment(attachmentUuids: number[]): Promise<number> {
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'deleteAttachment is not support');
      return -1;
    }
    if (!attachmentUuids || attachmentUuids.length === 0) {
      return -1;
    }
    hiTraceMeter.startTrace(traceEvents.deleteAttachment, 0);
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.in(AttachmentColumn.ID, attachmentUuids);
    const count = await DBUtils.INSTANCE.delete(DBUtils.INSTANCE.URI_EVENT_ATTACHMENTS, predicates, TAG);
    hiTraceMeter.finishTrace(traceEvents.deleteAttachment, 0);
    ReportUtil.reportBehaviorEvent(behaviorEvents.attachmentDelete);
    return count;
  }

  async queryAttachmentList(eventUuid: string): Promise<AttachmentInfo[]> {
    const list: AttachmentInfo[] = [];
    const isSupport = await CalendarDataFeatureHelper.isSupportFeature(CalendarDataFeature.EVENT_ATTACHMENT);
    if (!isSupport) {
      Log.warn(TAG, 'queryAttachmentList is not support');
      return list;
    }
    if (EmptyUtils.isNotOrEmptyString(eventUuid)) {
      Log.warn(TAG, 'queryAttachmentList isEmpty eventUuid');
      return list;
    }
    const predicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo(AttachmentColumn.EVENT_UUID, eventUuid);
    const result = await DBUtils.INSTANCE.query(CalendarContract.Tables.EVENT_ATTACHMENTS,
      predicates, queryColumns, TAG);
    return this.parseAttachments(result);
  }

  private parseAttachments(result: InnerResultSet | undefined): AttachmentInfo[] {
    const list: AttachmentInfo[] = [];
    if (!result) {
      return list;
    }
    try {
      if (result.rowCount <= 0) {
        return list;
      }
      result.goToFirstRow();
      do {
        list.push(AttachmentInfo.buildAttachmentInfo(result));
      } while (result.goToNextRow());
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseAttachments', err);
      SqlFaultHandle.querySqlFail(err?.message, TAG);
    } finally {
      result.close();
    }
    return list;
  }

  isAttachmentListChange(newList: AttachmentInfo[], oldList: AttachmentInfo[],
                         needUpdate: boolean = true, eventUuid: string): boolean {
    let newAttachmentIdList: string[] = [];
    let rawAttachmentIdList: string[] = [];
    let insertList: AttachmentInfo[] = [];
    let deleteList: number[] = [];
    newList.forEach((newAttachment: AttachmentInfo) => {
      newAttachmentIdList.push(newAttachment.hashcode());
    })
    oldList.forEach((rawAttachment: AttachmentInfo) => {
      rawAttachmentIdList.push(rawAttachment.hashcode());
      if (!newAttachmentIdList.includes(rawAttachment.hashcode())) {
        deleteList.push(rawAttachment.id);
      }
    })
    newList.forEach((newAttachment: AttachmentInfo) => {
      if (!rawAttachmentIdList.includes(newAttachment.hashcode())) {
        insertList.push(newAttachment);
      }
    })
    if (needUpdate) {
      this.updateAttachmentList(insertList, deleteList, eventUuid);
    }
    Log.info(TAG, `updateAttachmentList insertList: ${insertList.length} deleteList:${deleteList.length}`);
    return insertList.length > 0 || deleteList.length > 0;
  }

  updateAttachmentList(insertList: AttachmentInfo[], deleteList: number[], eventUuid: string) {
    if (insertList.length > 0) {
      // 插入新增附件
      this.batchInsertAttachments(insertList, eventUuid);
    }
    if (deleteList.length > 0) {
      // 删除去掉的附件
      this.deleteAttachment(deleteList);
    }
  }
}