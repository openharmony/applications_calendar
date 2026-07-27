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

import { pasteboard } from '@kit.BasicServicesKit';
import { GlobalThis } from '../data/GlobalThis';
import { Log } from '../default/common/Log';
import { PreferencesFiles } from '../default/util/preferences_util/PreferencesFiles';
import { PreferencesUtil } from '../default/util/preferences_util/PreferencesUtil';

const TAG: string = 'PasteHelper';

const CURRENT_PASTE_STRING: string = 'current_paste_string';
const CURRENT_PASTE_DATA_TIMESTAMP: string = 'current_paste_data_timestamp';

export class PasteHelper {
  private static _instance: PasteHelper = new PasteHelper();
  private tempString: string = '';

  static getInstance(): PasteHelper {
    return PasteHelper._instance;
  }

  /**
   * 判断系统剪贴板是否有内容
   * 调用SystemPasteboard的接口前，需要先通过getSystemPasteboard获取系统剪贴板
   */
  askSystemPaste(): boolean {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    if (systemPasteboard === undefined || systemPasteboard === null) {
      Log.error(TAG, 'pasteHelper: system pasteboard not valid');
      return false;
    }
    let checked: boolean = false;
    try {
      checked = systemPasteboard.hasDataSync();
      Log.info(TAG, 'pasteHelper: check system pasteboard result is:' + checked);
      return checked;
    } catch (err) {
      Log.logErrorMsg(TAG, 'pasteHelper: check system pasteboard error', err);
      return checked;
    }
  }

  /**
   * 清空系统剪贴板中的内容
   */
  clearSystemBoard(): void {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    if (systemPasteboard === undefined || systemPasteboard === null) {
      Log.error(TAG, 'pasteHelper: system pasteboard not valid');
      return;
    }
    try {
      systemPasteboard.clearDataSync();
      Log.info(TAG, 'pasteHelper: succeeded in clearing the pasteboard');
    } catch (err) {
      Log.logErrorMsg(TAG, 'pasteHelper: failed to clear the pasteboard', err);
    }
  }

  /**
   * 给剪贴板中添加指定文本内容
   */
  setSystemBoard(content: string): void {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    if (!systemPasteboard) {
      Log.error(TAG, 'pasteHelper: system pasteboard not valid');
      return;
    }

    try {
      let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      const appInfo = GlobalThis.getInstance().getBundleInfoSync()?.appInfo;
      if (appInfo) {
        let property = pasteData.getProperty();
        property.additions = {'originInfo' : {'originTokenId' : appInfo.accessTokenId}};
        pasteData.setProperty(property);
      }
      systemPasteboard.setDataSync(pasteData);
      Log.info(TAG, 'pasteHelper: succeeded in setting the pasteboard with content');
    } catch (err) {
      Log.logErrorMsg(TAG, 'pasteHelper: failed to set the pasteboard', err);
    }
  }

  /**
   * 复制剪贴板内容到临时存储位置 需要弹窗申请权限
   */
  getSystemPaste(): string {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    if (systemPasteboard === undefined || systemPasteboard === null) {
      Log.error(TAG, 'pasteHelper: system pasteboard not valid');
      return '';
    }
    try {
      let result: pasteboard.PasteData = systemPasteboard.getDataSync();
      if (!result) {
        Log.error(TAG, 'pasteHelper: get paste result is null or undefined');
      }
      //判断一下剪贴板内容中首个条目的数据类型是否为纯文本
      let type: string = result.getPrimaryMimeType();
      Log.info(TAG, 'pasteHelper: pasteData type is:' + type);
      //是否控制只识别纯文本类型的数据
      this.tempString = result.getPrimaryText();
      PreferencesUtil.putStringValue(PreferencesFiles.PASTE_BOARD,
        CURRENT_PASTE_STRING, this.tempString);
      return this.tempString;
    } catch (err) {
      Log.logErrorMsg(TAG, 'pasteHelper: Failed to get PasteData, error:', err);
      return 'error';
    }
  }

  /**
   * 获取剪贴板中内容的写入时间戳
   */
  getWriteTimestamp(): number {
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    let timestamp: number = -1;
    if (systemPasteboard === undefined || systemPasteboard === null) {
      Log.error(TAG, 'pasteHelper: system pasteboard not valid');
      return timestamp;
    }
    try {
      let result: pasteboard.PasteData = systemPasteboard.getDataSync();
      if (!result) {
        Log.error(TAG, 'pasteHelper: get paste result is null or undefined');
      }
      timestamp = result.getProperty().timestamp;
      Log.info(TAG, 'pasteHelper: get timestamp is:' + timestamp);
      PreferencesUtil.putNumberValue(PreferencesFiles.PASTE_BOARD,
        CURRENT_PASTE_DATA_TIMESTAMP, timestamp);
      return timestamp;
    } catch (err) {
      Log.logErrorMsg(TAG, 'pasteHelper: Failed to get PasteData, error:', err);
      return -1;
    }
  }
}