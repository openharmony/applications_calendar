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

import hiSysEvent from '@ohos.hiSysEvent';
import { Log } from '../common/Log';
import type { BusinessError } from '@ohos.base';
import { faultEvents } from '../common/HiEvents';
import { GlobalThis } from '../../data/GlobalThis';
import lazy bundleManager from '@ohos.bundle.bundleManager';
import deviceInfo from '@ohos.deviceInfo';
import { PreferencesUtil } from './preferences_util/PreferencesUtil';
import { PreferencesFiles } from './preferences_util/PreferencesFiles';
import { SettingPreferencesKeys } from './preferences_util/SettingPreferencesKeys';

const TAG: string = 'ReportUtil';
const DOMAIN_UE: string = 'CALENDAR_UE'; // UE行为打点
const DOMAIN_DFT: string = 'CALENDAR'; // DFT故障打点
const WATCH_DOMAIN_UE: string = 'WATCH_CAL_UE'; // 手表UE行为打点

// 设备类型
const enum DeviceType {
  PC = 0,
  PHONE = 1,
  TABLET = 2,
  WATCH = 3
}

/**
 * Global ReportUtil class
 *
 * @since 2022-06-16
 */
export class ReportUtil {
  static async sortParams(eventParams: ReportHiEventParams): Promise<ReportHiEventParams> {
    let bundleInfo: bundleManager.BundleInfo | null = await GlobalThis.getInstance().getBundleInfo();
    let params: ReportHiEventParams = {};
    params.PNAMEID = '';
    params.PVERSIONID = '';
    if (bundleInfo) {
      params.PNAMEID = bundleInfo.name;
      params.PVERSIONID = bundleInfo.versionName;
    }
    params.DEVICE_TYPE = this.devTypeStr2Enum(deviceInfo.deviceType);
    Object.keys(eventParams).forEach(key => {
      params[key] = eventParams[key];
    });
    return params;
  }

  /**
   * 统计数据打点
   *
   * @param eventName 事件名
   * @param eventParams 事件参数
   */
  static reportStatisticEvent(eventName: string, eventParams?: ReportHiEventParams): void {
    ReportUtil.reportHiEvent(DOMAIN_UE, hiSysEvent.EventType.STATISTIC, eventName, eventParams || {});
  }

  /**
   * 统计手表数据打点
   *
   * @param eventName 事件名
   * @param eventParams 事件参数
   */
  static reportWatchStatisticEvent(eventName: string, eventParams?: ReportHiEventParams): void {
    ReportUtil.reportHiEvent(WATCH_DOMAIN_UE, hiSysEvent.EventType.STATISTIC, eventName, eventParams || {});
  }

  /**
   * 行为数据打点
   *
   * @param eventName 事件名
   * @param eventParams 事件参数
   */
  static reportBehaviorEvent(eventName: string, eventParams?: object): void {
    ReportUtil.reportHiEvent(DOMAIN_UE, hiSysEvent.EventType.BEHAVIOR, eventName, eventParams || {});
  }

  /**
   * 手表行为数据打点
   *
   * @param eventName 事件名
   * @param eventParams 事件参数
   */
  static reportWatchBehaviorEvent(eventName: string, eventParams?: object): void {
    ReportUtil.reportHiEvent(WATCH_DOMAIN_UE, hiSysEvent.EventType.BEHAVIOR, eventName, eventParams || {});
  }

  /**
   * 故障事件打点
   *
   * @param eventName 事件名
   * @param eventParams 事件参数
   */
  static reportFaultEvent(eventName: string, eventParams?: object): void {
    ReportUtil.reportHiEvent(DOMAIN_DFT, hiSysEvent.EventType.FAULT, eventName, eventParams || {});
  }

  static devTypeStr2Enum(str: string): DeviceType {
    if (str === 'phone') {
      return DeviceType.PHONE;
    } else if (str === 'tablet') {
      return DeviceType.TABLET;
    } else if (str === '2in1') {
      return DeviceType.PC;
    } else if (str === 'pc') {
      return DeviceType.PC;
    } else if (str === 'wearable') {
      return DeviceType.WATCH;
    }
    return DeviceType.PHONE;
  }

  /**
   * 页面加载完成时的打点功能
   */
  public static reportPageDrawn(): void {
    const context = GlobalThis.getInstance().context;
    if (!context) {
      Log.error(TAG, `reportPageDrawn context undefined`);
      return;
    }
    try {
      context.reportDrawnCompleted((err) => {
        if (err.code) {
          // 处理业务逻辑错误
          Log.error(TAG, `reportDrawnCompleted failed, code is ${err.code}. message is: ${err.message}`);
          return;
        }
        // 正常执行业务
        Log.info(TAG, 'reportDrawnCompleted succeed');
      });
    } catch (err) {
      // 捕获同步的参数错误
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      Log.error(TAG, `reportDrawnCompleted failed, code is ${code}. message is: ${message}`);
    }
  }

  private static isUserAgreeNetWork(): boolean {
    return PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS,
      SettingPreferencesKeys.IS_ALLOW_NETWORK, 0) === 1;
  }

  /**
   * 数据打点
   *
   * @param eventDomain 事件所在域
   * @param eventType 事件类型
   * @param eventName 事件名称
   * @param eventParams 事件参数
   */
  private static async reportHiEvent(eventDomain: string, eventType: number, eventName: string, eventParams: ReportHiEventParams): Promise<void> {
    let type = this.devTypeStr2Enum(deviceInfo.deviceType);
    if (!ReportUtil.isUserAgreeNetWork() && type !== DeviceType.WATCH) {
      return;
    }
    let params: ReportHiEventParams = await this.sortParams(eventParams);
    hiSysEvent.write({
      domain: eventDomain,
      name: eventName,
      eventType: eventType,
      params: params
    }
    ).then(() => {
      Log.info(TAG, `Report write ${eventName} success code: ${eventName}`);
    }).catch((err: BusinessError) => {
      Log.error(TAG, `Report write ${eventName} failed by error: ${err.message}`);
    });
  }
}

export const enum HiEventParamsConfirm {
  FALSE = 0,
  TRUE
}

/**
 * 键盘的按键类型
 */
export const enum KeyboardType {
  ENTER = 0,
  DELETE,
  UP_AND_LEFT,
  DOWN_AND_RIGHT,
  COPY,
  PASTE
}

/**
 * 日程列表位置
 */
export const enum AgendaListLocation {
  monthlyView = 0,
  AgendaListView,
  SearchAgendaView
}

/**
 * 卡片类型
 */
export const enum CardType {
  AGENDA_CARD_2X2 = 0,
  AGENDA_CARD_2X4,
  AGENDA_CARD_4X4,
  AGENDA_CARD_4X6,
  IMPORTANT_CARD_2X2,
  IMPORTANT_CARD_2X4,
  MONTH_CARD_2X2,
  MONTH_CARD_4X4,
  AGENDA_CARD_2X3,
}

export interface ReportHiEventParams {
  // 包名称
  PNAMEID?: string,

  // 应用版本
  PVERSIONID?: string,

  // 设备类型
  DEVICE_TYPE?: number | undefined,

  // 目标页
  TARGET_PAGE?: number,

  // 来源页面
  SOURCE_PAGE?: number,

  // 日程是否有位置信息
  HAS_LOCATION?: number,

  // 日程提醒时间组
  REMINDER_MINUTES?: number[],

  // 是否全天日程
  IS_ALLDAY?: number,

  // 是否默认账户
  CHANGE_ACCOUNT?: number,

  // 日程是否有备注信息
  HAS_DESCRIPTION?: number,

  // 日程类型
  TYPE?: number,

  // 日程提醒时间
  REMINDER_MINUTE?: number,

  // 操作-增删改查
  ACTION?: number,

  // 弹窗-是否保存/取消
  IS_SAVE?: number,

  // 按钮-开/关
  IS_ON?: number,

  // 颜色值
  COLOR?: number,

  // 是否显示
  IS_SHOW?: number,

  // 卡片规格
  FA_DIMENSION?: number,

  // 重要日背景
  BACKGROUND?: string,

  // 重要日纹理
  TEXTURE?: string,

  // 重要日版式
  LAYOUT?: string,

  // 一周起始日
  WEEK_DAY?: number,

  // 周末
  WEEK_DAYS?: number[],

  // 日历显示格式-农历等
  DISPLAY_NAME?: number,

  // 接口调用成功与否
  IS_SUCCESS?: number,

  // 失败信息
  ERROR_MESSAGE?: string | undefined,

  // 所属模块
  MODULE?: string | undefined,

  // 一键入会日程前/中/后
  ONE_KEY_TIME?: number,

  // 是否是账户分享
  IS_ACCOUNT?: number,

  // 分享的日程数量
  SHARE_AGENDAS?: number,

  // 账户个数
  ACCOUNT_COUNTS?: number,

  // 普通日程个数
  NORMAL_AGENDA_COUNTS?: number,

  // 重要日日程个数
  IMPORTANT_AGENDA_COUNTS?: number,

  // 入口
  FROM_TYPE?: number,

  // 账户类型 0-phone 1-非phone账户
  ACCOUNT_TYPE?: number,

  // 删除类型
  DELETE_TYPE?: number,

  // 重复日程类型
  REPEAT_TYPE?: number,

  // 开始时间/结束时间
  TIME_POINT?: number,

  // 新建/修改
  CHANGE_FLAG?: number,

  // 有效日期
  EFFECTIVE_DATE?: number,

  // 深色模式
  IS_DARK_MODE?: number,

  // 卡片id
  FORM_ID?: string,

  // 卡片name
  FORM_NAME?: string,

  // 应用窗口状态
  WINDOW_MODE?: number,

  // 设置项-其他历法
  SETTINGS_SUBSCRIPTION_CALENDAR?: number,

  // 设置项-国家（地区）节日
  SETTINGS_NATIONAL_REGION_HOLIDAY?: number[],

  // 设置项-重要日
  SETTINGS_IMPORTANT_DAY?: number,

  // 设置项-显示节假班休信息
  SETTINGS_SHOW_HOLIDAY?: number,

  // 设置项-显示周数
  SETTINGS_SHOW_WEEKS?: number,

  // 设置项-一周开始日
  SETTINGS_START_OF_WEEK?: number,

  // 设置项-周末
  SETTINGS_WEEKEND?: number[],

  // 设置项-锁定时区
  SETTINGS_LOCK_TIME_ZONE?: number,

  // 设置项-接收共享日历
  SETTINGS_RECEIVE_SHARED_CALENDARS?: number,

  // 设置项-默认提醒时间
  SETTINGS_DEFAULT_REMINDER_TIME?: number,

  // 设置项-全天事件默认提醒时间
  SETTINGS_ALL_DAY_REMINDER_TIME?: number,

  // 是否为共享账号
  IS_SHARE_ACCOUNT?: number,

  // 导入日程类型
  IMPORT_AGENDA_TYPE?: number,

  // 跳转的外部应用包名
  OUTER_PNAME?: string,

  // 一键服务日程类型
  EVENT_TYPE?: string,

  // 共享成员个数
  SHARE_ACCOUNT_NUMBER?: number,

  // 消息中心点击类型
  MESSAGE_CENTER_CLICK_TYPE?: number,

  //课程表提醒方式
  COURSE_REMINDER_TYPE?: number,

  //课程表次日提醒时间类型
  COURSE_NEXTDAY_REMINDER_TYPE?: string,

  //课程表时间计数
  TIME_COUNT?: number,

  //按钮确认或取消
  CONFIRM?: number,

  //订阅服务类型
  SUBSCRIPTION_TYPE?: string,

  //用户总日程数
  TOTAL_AGENDA_NUMBER?: number,

  //记录时间
  CUR_TIME?: number,

  //课表总数
  SCHEDULE_COUNT?: number,

  //附件数量
  ATTACHMENT_COUNT?: number,

  //单个附件大小
  ATTACHMENT_SIZE?: number[],

  //节假日grs错误码
  HOLIDAY_GRS_ERROR_CODE?: number,

  //课表导入失败错误信息
  ERROR_CODE?: number,

  //同步待办完成状态
  COMPLETE_STATE?: number,

  //卡片清脏个数
  DELETE_DIRTY_CARD_COUNT?: number
}

export const enum HiEventAction {
  CREATE = 0,
  EDIT,
  DELETE
}


export const enum FromType {
  UNKNOWN = -1, // 未知
  IMPORTANT_FA = 0, // 桌面重要日卡片
  MONTH_VIEW = 1 // 月视图重要日
}

export const enum ImportAgendaType {
  WELINK = 1
}

export class SqlFaultHandle {
  static initSqlFail(message: string | undefined, module: string): void {
    let params: ReportHiEventParams = {
      ERROR_MESSAGE: message,
      MODULE: module
    };
    ReportUtil.reportFaultEvent(faultEvents.sqlInitFail, params);
  }

  static querySqlFail(message: string | undefined, module: string): void {
    let params: ReportHiEventParams = {
      ERROR_MESSAGE: message,
      MODULE: module
    };
    ReportUtil.reportFaultEvent(faultEvents.sqlQueryFail, params);
  }

  static insertSqlFail(message: string | undefined, module: string): void {
    let params: ReportHiEventParams = {
      ERROR_MESSAGE: message,
      MODULE: module
    };
    ReportUtil.reportFaultEvent(faultEvents.sqlInsertFail, params);
  }

  static updateSqlFail(message: string | undefined, module: string): void {
    let params: ReportHiEventParams = {
      ERROR_MESSAGE: message,
      MODULE: module
    };
    ReportUtil.reportFaultEvent(faultEvents.sqlUpdateFail, params);
  }

  static deleteSqlFail(message: string | undefined, module: string): void {
    let params: ReportHiEventParams = {
      ERROR_MESSAGE: message,
      MODULE: module
    };
    ReportUtil.reportFaultEvent(faultEvents.sqlDeleteFail, params);
  }
}