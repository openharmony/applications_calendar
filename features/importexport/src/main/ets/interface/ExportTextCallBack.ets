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

// ShareKit 注释 - start
// import lazy { AnchorType, createRecord, createSharedData, showSharePanel } from '@app/common/src/main/ets/default/util/ShareUtils';
// ShareKit 注释 - end
import { ExportCallBack } from './ExportCallBack';
import { ShareEventTextBean } from './ShareEventTextBean';
import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { showToast } from '@app/common/src/main/ets/util/PromptActionUtils';

/**
 * 导出回调 <T> 导出数据
 */
export class ExportTextCallBack implements ExportCallBack<ShareEventTextBean> {
  private jobId: number | undefined;

  onExportTaskBuild(jobId: number): void {
    this.jobId = jobId;
  }

  onExportStarted(): void {

  }

  onExportProgressChanged(totalEventCount: number, processedEventCount: number): void {
  }

  onExportFailed(errorCode: number): void {
    showToast(GlobalThis.getResourceStr($r('app.string.export_failed')))
  }

  onExportFinished(shareEventTextBean: ShareEventTextBean): void {
    this.shareText(shareEventTextBean);
  }

  // ShareKit 注释 - start
  // private shareText(shareEventTextBean: ShareEventTextBean) {
  //   let record = createRecord(uniformTypeDescriptor.UniformDataType.TEXT);
  //   record.content = shareEventTextBean.text;
  //   record.title = shareEventTextBean.event.mTitle;
  //   let data = createSharedData(record);
  //   showSharePanel(data, AnchorType.ANCHOR, GlobalThis.getInstance().shareAnchorViewId);
  // }
  // ShareKit 注释 - end
  private shareText(shareEventTextBean: ShareEventTextBean) {
    // ShareKit disabled - no-op
  }
}