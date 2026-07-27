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

import { picker } from '@kit.CoreFileKit';
import { Log } from '../default/common/Log';
import { CustomColors } from '@kit.ArkUI';

const TAG: string = 'FilePicker'

export class FilePickerUtil {
  /**
   * 文件管理器picker,拉起文件管理器UI界面
   *
   * @param context context
   * @param maxSelectCount 可选文件的最大数量
   * @returns 返回选中文件的uri路径数组
   */
  public static async getDocumentUri(
    context: Context, maxSelectCount: number, themeColor: string): Promise<Array<string>> {
    if (!context) {
      Log.warn(TAG, `getDocumentUri context null`);
      return [];
    }
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker(context);
      documentSelectOptions.maxSelectNumber = maxSelectCount;
      const customColors: CustomColors = {
        brand: themeColor, // 输入光标和文字选中底色
        compBackgroundEmphasize: themeColor, // checkbox选中颜色
        compBackgroundTertiary: themeColor, // 普通按钮背板颜色
        backgroundEmphasize: themeColor, // 强调按钮背板颜色
        compEmphasizeSecondary: themeColor, // 边框颜色
        fontPrimary: themeColor, // 已选文字颜色
      }
      documentSelectOptions.themeColor = customColors;
      let documentResult = await documentPicker.select(documentSelectOptions);
      return documentResult;
    } catch (error) {
      Log.logErrorMsg(TAG, `getDocumentUri fail`, error);
      return [];
    }
  }
}