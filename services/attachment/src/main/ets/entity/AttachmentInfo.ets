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
import { InnerResultSet, Log, DataShareResultUtil } from '@app/common';
import { AttachmentColumn } from './AttachmentColumn';

const TAG: string = 'AttachmentInfo';

/**
 * 附件信息
 */
export class AttachmentInfo {
  public id: number = 0;
  public uuid: string = ''; // 唯一标识
  public eventId: number = 0;
  public eventUuid: string = '';
  public eventGuid: string = '';
  public displayName: string = ''; // 附件名称
  public filePath: string = ''; // 附件uri
  public fileType: string = ''; // 附件类型
  public fileSize: number = 0; // 附件大小，KB
  public source: string = 'com.openharmony.calendar';
  public syncEnable: number = 0;
  public syncStatus: number = 0;
  public createTime: number = 0; // 创建时间
  public dirty: number = 0;
  public ext_1: string = '';
  public ext_2: string = '';
  public ext_3: string = '';

  constructor(sourceData?: AttachmentInfo) {
    if (sourceData == null) {
      return;
    }
    this.id = sourceData.id;
    this.uuid = sourceData.uuid;
    this.eventId = sourceData.eventId;
    this.eventUuid = sourceData.eventUuid;
    this.eventGuid = sourceData.eventGuid;
    this.displayName = sourceData.displayName;
    this.filePath = sourceData.filePath;
    this.fileType = sourceData.fileType;
    this.fileSize = sourceData.fileSize;
    this.source = sourceData.source;
    this.syncEnable = sourceData.syncEnable;
    this.syncStatus = sourceData.syncStatus;
    this.createTime = sourceData.createTime;
    this.dirty = sourceData.dirty;
    this.ext_1 = sourceData.ext_1;
    this.ext_2 = sourceData.ext_2;
    this.ext_3 = sourceData.ext_3;
  }

  public static buildAttachmentInfo(ds: InnerResultSet): AttachmentInfo {
    try {
      const attachment: AttachmentInfo = new AttachmentInfo();
      attachment.id = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.ID, 0);
      attachment.uuid = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.UUID, '');
      attachment.eventId = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.EVENT_ID, 0);
      attachment.eventUuid = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.EVENT_UUID, '');
      attachment.eventGuid = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.EVENT_GUID, '');
      attachment.displayName = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.DISPLAY_NAME, '');
      attachment.filePath = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.FILE_PATH, '');
      attachment.fileType = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.FILE_TYPE, '');
      attachment.fileSize = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.FILE_SIZE, 0);
      attachment.source = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.SOURCE, '');
      attachment.syncEnable = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.SYNC_ENABLE, 0);
      attachment.syncStatus = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.SYNC_STATUS, 0);
      attachment.createTime = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.CREATE_TIME, 0);
      attachment.dirty = DataShareResultUtil.getColumnLongData(ds, AttachmentColumn.DIRTY, 0);
      attachment.ext_1 = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.EXT_1, '');
      attachment.ext_2 = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.EXT_2, '');
      attachment.ext_3 = DataShareResultUtil.getColumnStringData(ds, AttachmentColumn.EXT_3, '');
      return attachment;
    } catch (error) {
      Log.logErrorMsg(TAG, `buildAttachmentInfo`, error);
      throw new Error('buildAttachmentInfo error');
    }
  }

  public hashcode(): string {
    return `${this.createTime}:${this.displayName}:${this.fileSize}:${this.fileType}:${this.filePath}`;
  }
}