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

import lazy { bundleManager } from '@kit.AbilityKit';
import { Log } from '../default/common/Log';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { DBUtils } from '../dao/DBUtils';

const TAG: string = 'CalendarDataFeatureHelper';

const CALENDAR_DATA_BUNDLE_NAME: string = 'com.ohos.calendardata';

/**
 * CalendarData的新增特性枚举
 */
export enum CalendarDataFeature {
  // 数据库支持静默查询
  DB_PROXY = 'db_proxy',
  // 数据库支持会议纪要需求
  MEETING_INFO = 'meeting_info',
  // 数据库支持时区需求
  TIME_ZONE = 'time_zone',
  // 数据库支持课程表需求
  SCHEDULE = 'schedule',
  // 日历存储支持经纬度加密
  LOCATION_ENCRYPT = 'hmos.calendardata.locationEncrypt',
  // 日历存储支持附件
  EVENT_ATTACHMENT = 'hmos.calendardata.eventAttachment',
  // 日历存储支持日程多语言
  EVENT_LANGUAGE_RESOURCES = 'hmos.calendardata.languageResources',
}

const FEATURE_VERSION_MAP: Map<CalendarDataFeature, number> = new Map<CalendarDataFeature, number>();

// 日历存储（CalendarData）0903分支的第一个版本号 15.0.9.330，此版本开始支持数据库静默查询
FEATURE_VERSION_MAP.set(CalendarDataFeature.DB_PROXY, 150009330);

// 特性开关meta-data的配置Map，key为meta-data的枚举值，value为合法值数组，实际值在数组中的就认为功能是开启状态
const FEATURE_METADATA_MAP: Map<CalendarDataFeature, string[]> = new Map<CalendarDataFeature, string[]>();
FEATURE_METADATA_MAP.set(CalendarDataFeature.LOCATION_ENCRYPT, ['true']);
FEATURE_METADATA_MAP.set(CalendarDataFeature.EVENT_ATTACHMENT, ['true']);
FEATURE_METADATA_MAP.set(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES, ['true']);

// 附件特性新增的表字段
const EVENT_ATTACHMENT: Map<CalendarContract.Tables, string[]> = new Map<CalendarContract.Tables, string[]>();
EVENT_ATTACHMENT.set(CalendarContract.Tables.EVENTS, [CalendarContract.EventsColumns.ATTACHMENT_COUNT]);

// 节假日多语言特性新增的表字段
const EVENT_LANGUAGE_RESOURCES: Map<CalendarContract.Tables, string[]> = new Map<CalendarContract.Tables, string[]>();
EVENT_LANGUAGE_RESOURCES.set(CalendarContract.Tables.EVENTS, [CalendarContract.EventsColumns.LANGUAGE_RESOURCES]);

// 特性新增的数据库字段集合
const FEATURE_TABLES_COLUMN_MAP: Map<CalendarDataFeature, Map<CalendarContract.Tables, string[]>> =
  new Map<CalendarDataFeature, Map<CalendarContract.Tables, string[]>>();
FEATURE_TABLES_COLUMN_MAP.set(CalendarDataFeature.EVENT_ATTACHMENT, EVENT_ATTACHMENT);
FEATURE_TABLES_COLUMN_MAP.set(CalendarDataFeature.EVENT_LANGUAGE_RESOURCES, EVENT_LANGUAGE_RESOURCES);

/**
 * 根据CalendarData的应用版本号，来判断CalendarData是否是否支持某些特性，以做上层入口屏蔽或差分
 */
export class CalendarDataFeatureHelper {
  private static calendarDataVersion: number = 0;

  private static featureSwitchCache: Map<string, string> = new Map<string, string>();

  private static queryCalendarDataBundleInfo(): void {
    try {
      const bundleFlags: number = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION |
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_METADATA;
      const bundleInfo = bundleManager.getBundleInfoSync(CALENDAR_DATA_BUNDLE_NAME, bundleFlags);
      CalendarDataFeatureHelper.calendarDataVersion = bundleInfo?.versionCode ?? 0;
      Log.info(TAG, `calendarDataVersion=${CalendarDataFeatureHelper.calendarDataVersion}`);

      CalendarDataFeatureHelper.initMetaDataCache(bundleInfo);
    } catch (err) {
      Log.logErrorMsg(TAG, 'getCalendarDataVersion', err);
      CalendarDataFeatureHelper.calendarDataVersion = 0;
    }
  }

  private static initMetaDataCache(bundleInfo: bundleManager.BundleInfo): void {
    if (!bundleInfo || !bundleInfo.appInfo || !bundleInfo.appInfo.metadataArray) {
      Log.warn(TAG, 'initMetaDataCache get invalid app info');
      return;
    }
    bundleInfo.appInfo.metadataArray.forEach((module) => {
      if (!module || !module.metadata) {
        Log.warn(TAG, 'initMetaDataCache get invalid module info');
        return;
      }
      module.metadata.forEach((metadata) => {
        if (!metadata) {
          Log.warn(TAG, 'initMetaDataCache get invalid metadata info');
          return;
        }
        if (metadata.name && metadata.value) {
          CalendarDataFeatureHelper.featureSwitchCache.set(metadata.name, metadata.value);
        }
      });
    });
  }

  private static isMetaDataSupportFeature(feature: CalendarDataFeature): boolean {
    if (CalendarDataFeatureHelper.calendarDataVersion === 0) {
      // 未获取过日历存储包信息，则获取一次
      CalendarDataFeatureHelper.queryCalendarDataBundleInfo();
    }

    // 先判断metadata开关项是否符合要求
    const allowValues: string[] | undefined = FEATURE_METADATA_MAP.get(feature);
    if (allowValues && allowValues.length > 0) {
      const metaDataValue: string = CalendarDataFeatureHelper.featureSwitchCache.get(feature) ?? '';
      return allowValues.includes(metaDataValue);
    }

    // 无metadata开关配置或匹配不上时，走版本号判断
    if (CalendarDataFeatureHelper.calendarDataVersion === 0) {
      // 如果未查询到日历存储版本号，默认当做不支持
      return false;
    }
    const minSupportVersion = FEATURE_VERSION_MAP.get(feature) ?? 0;
    return CalendarDataFeatureHelper.calendarDataVersion >= minSupportVersion;
  }

  public static async isSupportFeature(feature: CalendarDataFeature): Promise<boolean> {
    const isMetaDataSupportFeature = CalendarDataFeatureHelper.isMetaDataSupportFeature(feature);
    const tablesColumnMap: Map<CalendarContract.Tables, string[]> | undefined = FEATURE_TABLES_COLUMN_MAP.get(feature);
    if (!tablesColumnMap || tablesColumnMap.size <= 0) {
      return isMetaDataSupportFeature;
    }

    let isColumnNameExist = false;
    for (let table of tablesColumnMap.keys()) {
      const columnNames = tablesColumnMap.get(table);
      if (!columnNames || columnNames.length <= 0) {
        break;
      }
      isColumnNameExist = await DBUtils.INSTANCE.isColumnNameExist(table, columnNames);
      if (!isColumnNameExist) {
        break;
      }
    }
    return isMetaDataSupportFeature && isColumnNameExist;
  }
}