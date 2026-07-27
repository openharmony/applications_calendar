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

import pasteboard from '@ohos.pasteboard';
import { AgendaEventInfo } from '../../agenda/AgendaEventInfo';
import { DateUtil, MILLS_PER_HOUR } from '../../util/DateUtil';
import { Log } from '../common/Log';
import { GlobalThis } from '../../data/GlobalThis';
import componentUtils from '@ohos.arkui.componentUtils';
// import lazy { systemShare } from '@kit.ShareKit'; // ShareKit 注释
import { EmptyUtils } from '../../util/EmptyUtils';
import lazy UDC from '@ohos.data.unifiedDataChannel';
import { AgendaUtil } from '../../agenda/AgendaUtil';
import uniformTypeDescriptor from '@ohos.data.uniformTypeDescriptor';
import { CalendarDate } from '../../date/CalendarDate';
import { DeviceConfig } from '../../data/DeviceConfig';
import { SingleInstanceHelper } from '../../templates/SingleInstanceHelper';
import { maskString } from '../../util/SensitiveStrUtils';
import { uniformDataStruct } from '@kit.ArkData';

// 日程分享，涉及三方接口调用及窗口拉起，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG: string = 'ShareUtils';
const DEFAULT_NLU_START_TIME: number = -1;

export enum AnchorType {

  // viewId 锚点
  ID,

  // view rect 锚点
  ANCHOR

}

export enum ShareConfig {
  // 最大拖拽文本长度
  MAX_DRAG_STR_LENGTH = 256
}

/**
 * 处理日程拖出的拖拽事件
 * @param event 拖拽事件
 * @param agendaEventInfo 传入的 EventInfo 对象
 * @returns
 */
export function buildUDC(event: DragEvent, agendaEventInfo: AgendaEventInfo): boolean {
  try {
    let data: UDC.PlainText = new UDC.PlainText();
    const item: AgendaEventInfo = agendaEventInfo;
    data.abstract = item.mTitle;
    data.textContent = parseEventInfo2String(item);
    event.setData(new UDC.UnifiedData(data));
    return true;
  } catch (err) {
    Log.error(TAG, `fail to build UDC ,error ${err?.message}`);
    return false;
  }
}

/**
 * 将传入的 EventInfo 对象解析成文本信息
 *
 * @param agendaEventInfo 传入的 EventInfo 对象
 * @return contents 解析成文本信息
 */
export function parseEventInfo2String(agendaEventInfo: AgendaEventInfo): string {
  let contents: string = getResourceStr($r('app.string.edit_event_title_label')) +
    '：' + AgendaUtil.filterEmLabel(agendaEventInfo.mTitle) + '\n';
  if (agendaEventInfo.mIsAllDay) {
    contents += getResourceStr($r('app.string.all_day')) + '：' +
      DateUtil.dateFormat(new CalendarDate(agendaEventInfo.mBegin), 'YYYY-MM-dd');
  } else {
    contents += getResourceStr($r('app.string.start_date')) + '：' +
      DateUtil.dateFormat(new CalendarDate(agendaEventInfo.mBegin), 'YYYY-MM-dd HH:mm') +
      '\n' + getResourceStr($r('app.string.end_date')) + '：' +
      DateUtil.dateFormat(new CalendarDate(agendaEventInfo.mEnd), 'YYYY-MM-dd HH:mm');
  }
  return contents;
}

// ShareKit 注释 - start
// export function createSharedData(record: systemShare.SharedRecord, ...records: systemShare.SharedRecord[]): systemShare.SharedData {
//   let data: systemShare.SharedData = new systemShare.SharedData(record);
//   if (EmptyUtils.isEmptyArray(records)) {
//     return data;
//   }
//   for (let recordsElement of records) {
//     data.addRecord(recordsElement);
//   }
//   return data;
// }

// export function createRecord(utd: string): systemShare.SharedRecord {
//   return {
//     utd: utd
//   };
// }

// /**
//  * 拉起分析面板
//  * @param data
//  * @param albumInfo
//  */
// export function showSharePanel(data: systemShare.SharedData, anchorType: AnchorType, viewId: string): void {
//   Log.info(TAG, `showSharePanel anchorType ${anchorType} viewId ${maskString(viewId)}`)
//   if (EmptyUtils.isEmptyString(viewId)) {
//     Log.warn(TAG, `showSharePanel viewId is empty`);
//     return;
//   }
//   let controller: systemShare.ShareController | undefined = undefined;
//   try {
//     controller = new systemShare.ShareController(data);
//   } catch (err) {
//     Log.error(TAG, `showSharePanel new ShareController error ${err?.message}`);
//     return;
//   }
//   if (!controller) {
//     Log.error(TAG, `showSharePanel controller is undefined`);
//     return;
//   }
//   // 用于多窗,优先取可能存在的多窗context
//   let context = GlobalThis.getInstance().shareAbilityContext;
//   if (!context) {
//     context = GlobalThis.getInstance().mainAbilityContext;
//   }
//   if (!context) {
//     Log.warn(TAG, `showSharePanel mainAbilityContext is null`);
//     return;
//   }
//   // 方法内的局部controller 不要调用 controller.on('dismiss') 内存泄漏导致的各种异常崩溃
//   Log.info(TAG, 'showSharePanel show start');
//   try {
//     controller
//       .show(context, {
//         selectionMode: systemShare.SelectionMode.SINGLE,
//         previewMode: systemShare.SharePreviewMode.DEFAULT,
//         anchor: getPanelAnchor(anchorType, viewId)
//       });
//   } catch (err) {
//     Log.error(TAG, `showSharePanel error: ${err?.message}`);
//   }
//   // 在获取完多窗context后将其置为空防止阻塞正常context获取
//   GlobalThis.getInstance().shareAbilityContext = null;
//   Log.info(TAG, 'showSharePanel show end');
//   return;
// }

// function getPanelAnchor(anchorType: AnchorType, viewId: string): systemShare.ShareControllerAnchor | string {
//   if (AnchorType.ID == anchorType) {
//     return viewId;
//   } else {
//     const anchor = getAnchor(viewId);
//     if (anchor) {
//       return anchor;
//     }
//     const componentInfo: componentUtils.ComponentInfo = componentUtils.getRectangleById(viewId);
//     Log.info(TAG, `getPanelAnchor componentInfo is : windowOffset: ${componentInfo?.windowOffset}, size: ${componentInfo?.size}`)
//     return {
//       windowOffset: componentInfo.windowOffset, size: componentInfo.size
//     }
//   }
// }

// function getAnchor(viewId: string): systemShare.ShareControllerAnchor | undefined {
//   const inspector: string = getInspectorByKey(viewId);
//   const obj = JSON.parse(inspector) as object;
//   const points = JSON.parse(`[${obj['$rect'] as string}]`) as Array<Array<number>>;
//   const leftTop = points[0];
//   const rightBottom = points[1];
//   try {
//     //日程块（canvas）的分享pop弹窗位置独立计算
//     const agendaBlockShareParam = MonthViewAgendaBlockShareParam.getInstance();
//     if (agendaBlockShareParam.comeFormAgendaBlock) {
//       agendaBlockShareParam.comeFormAgendaBlock = false;
//       return {
//         windowOffset: {
//           x: agendaBlockShareParam.shareAnchorX + leftTop[0],
//           y: agendaBlockShareParam.shareAnchorY + leftTop[1]
//         },
//         size: {
//           width: agendaBlockShareParam.agendaBlockWidth,
//           height: vp2px(DeviceConfig.instance().config.monthAgendaBlockHeight)
//         }
//       };
//     }
//     return {
//       windowOffset: {
//         x: leftTop[0],
//         y: leftTop[1]
//       },
//       size: {
//         width: Math.abs((rightBottom[0] - leftTop[0])),
//         height: Math.abs(rightBottom[1] - leftTop[1])
//       }
//     };
//   } catch (err) {
//     Log.error(TAG, `getAnchor failed for viewId ${viewId} err ${err.message}`);
//     return undefined;
//   }
// }
// ShareKit 注释 - end

/**
 * 将传入的资源对象解析成文本信息
 *
 * @param resource 传入的 Resource 对象
 * @return string 从资源解析出的文本信息
 */
function getResourceStr(resource: Resource): string {
  return GlobalThis.getResourceStr(resource);
}

/**
 * 将用户拖入文本转化为待新建的日程对象，若未成功识别则将拖拽的文本内容作为标题返回
 * @param dragEvent 拖拽事件
 * @returns 待新建的日程对象
 */
export async function parseDataFromUdmf(dragEvent: DragEvent): Promise<AgendaEventInfo> {
  const records: UDC.UnifiedRecord[] = dragEvent.getData().getRecords();
  if (records === undefined) {
    Log.error(TAG, `NO VALID DRAG EVENT!`);
    return new AgendaEventInfo();
  }


  let plainTexts = '';
  records.forEach(record => {
    if (record.getType() === uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) {
      const plainText: UDC.PlainText = record as UDC.PlainText;
      plainTexts += plainText.textContent;
    } else if (record.getType() === uniformTypeDescriptor.UniformDataType.HTML) {
      let plainText = record.getEntry(uniformTypeDescriptor.UniformDataType.PLAIN_TEXT) as uniformDataStruct.PlainText;
      if (plainText && EmptyUtils.isNotEmptyString(plainText.textContent)) {
        plainTexts += plainText.textContent;
      } else {
        const plainHtml: UDC.HTML = record as UDC.HTML;
        plainTexts += plainHtml.htmlContent;
      }
    }
  })
  const textContent: string = plainTexts.slice(0, ShareConfig.MAX_DRAG_STR_LENGTH);

  const eventInfo: AgendaEventInfo = new AgendaEventInfo();
  eventInfo.mTitle = textContent;
  const defaultBegin = DateUtil.getStartDateByCombine(Date.now(), 0).getTime();
  eventInfo.mBegin = defaultBegin;
  eventInfo.mEnd = defaultBegin + MILLS_PER_HOUR;
  return eventInfo;
}

/**
 * 从剪贴板中获取日程信息
 * @param oriText 剪贴板内的文本信息
 * @returns 日程信息:AgendaEventInfo
 */
export async function parseDataFromPasteString(oriText: string, startTimeStamp: number): Promise<AgendaEventInfo> {
  if (oriText === undefined || oriText === null || oriText.length === 0) {
    Log.error(TAG, 'no valid text data here');
    return new AgendaEventInfo();
  }
  let text: string = oriText.slice(0, pasteboard.MAX_RECORD_NUM);
  let mEventInfo: AgendaEventInfo = new AgendaEventInfo();
  mEventInfo.mTitle = text;
  mEventInfo.mBegin = startTimeStamp;
  mEventInfo.mEnd = startTimeStamp + MILLS_PER_HOUR;
  return mEventInfo;
}

/**
 * 校验拖入参数是否合法
 * @param event 拖入的数据参数
 * @returns
 */
export function verifyDataFromUdmf(event: DragEvent): boolean {
  try {
    let data: UnifiedData = event.getData();
    if (!data) {
      return false;
    }
    let records: UDC.UnifiedRecord[] = data.getRecords();
    if (!records || records.length <= 0) {
      return false;
    }
    return true;
  } catch (err) {
    Log.error(TAG, `getData failed, code = ${err?.code}, message = ${err?.message}`);
    return false;
  }
}

// ShareKit 注释 - start
// export class MonthViewAgendaBlockShareParam {
//   constructor() {
//   }
//
//   static getInstance(): MonthViewAgendaBlockShareParam {
//     return SingleInstanceHelper.createOrGet(MonthViewAgendaBlockShareParam, 'MonthViewAgendaBlockShareParam');
//   }
//
//   private _shareAnchorX: number = 0; //月视图日程块分享pop弹出的x坐标，月视图日程块用canvas绘制，无compId，需要计算坐标
//
//   private _shareAnchorY: number = 0; //月视图日程块分享pop弹出的y坐标
//
//   private _comeFormAgendaBlock: boolean = false; //标识分享日程块是否来源于月视图日程块
//
//   private _agendaBlockWidth: number = 0; //月视图日程块宽度
//
//   get shareAnchorX(): number {
//     return this._shareAnchorX;
//   }
//
//   set shareAnchorX(shareAnchorX: number) {
//     this._shareAnchorX = shareAnchorX;
//   }
//
//   get shareAnchorY(): number {
//     return this._shareAnchorY;
//   }
//
//   set shareAnchorY(shareAnchorY: number) {
//     this._shareAnchorY = shareAnchorY;
//   }
//
//   get comeFormAgendaBlock(): boolean {
//     return this._comeFormAgendaBlock;
//   }
//
//   set comeFormAgendaBlock(comeFormAgendaBlock: boolean) {
//     this._comeFormAgendaBlock = comeFormAgendaBlock;
//   }
//
//   get agendaBlockWidth(): number {
//     return this._agendaBlockWidth;
//   }
//
//   set agendaBlockWidth(blockWidth: number) {
//     this._agendaBlockWidth = blockWidth;
//   }
// }
// ShareKit 注释 - end


