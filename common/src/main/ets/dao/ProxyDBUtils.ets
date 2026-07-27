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

import { dataShare, dataSharePredicates } from '@kit.ArkData';
import { BaseInitialize } from '../commoncapability/init/BaseInitialize';
import { SqlFaultHandle } from '../default/util/ReportUtil';
import { GlobalThis } from '../data/GlobalThis';
import { CalendarContract } from '../default/calendar/CalendarContract';
import { Log } from '../default/common/Log';
import { InnerResultSet, ResultSetLeakTracker } from './util/InnerResultSet';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';

const TAG = 'ProxyDBUtils';

export class ProxyDBUtils extends BaseInitialize {
  public static readonly INSTANCE: ProxyDBUtils = new ProxyDBUtils();
  private readonly dseUri: string = 'datashareproxy:///com.ohos.calendardata';
  //异步等待初始化的Resolve,初始化完毕后,通知唤醒
  private waitInitOverResolves: Function[] = [];
  private dsHelper: dataShare.DataShareHelper | null = null;

  async doInit(): Promise<boolean> {
    this.dsHelper = await this.initDsHelper();
    return this.dsHelper ? true : false;
  };

  private async initDsHelper(): Promise<dataShare.DataShareHelper | null> {
    if (this.dsHelper) {
      return this.dsHelper;
    }
    try {
      const dbContext = GlobalThis.getInstance().getDbContext() as Context;
      if (!dbContext) {
        Log.warn(TAG, 'initDsHelper context is null.');
        return this.dsHelper;
      }
      this.dsHelper = await dataShare.createDataShareHelper(dbContext, this.dseUri,
        { isProxy: true, waitTime: GlobalThis.getInstance().timeoutInterval });
      this.notifyAll();
    } catch (err) {
      Log.warn(TAG, `initDsHelper error code: ${err?.code}, message: ${err?.message}`);
      SqlFaultHandle.initSqlFail(err?.message, TAG);
    }
    Log.info(TAG, 'initDsHelper successes');
    return this.dsHelper;
  }

  /**
   * 通知等待数据库初始化的异步callBack
   */
  private notifyAll() {
    Log.info(this.getTag(), `notifyAll waitInitOverResolve count is ${this.waitInitOverResolves.length}`);
    for (let i = 0; i < this.waitInitOverResolves.length; i++) {
      const func: Function = this.waitInitOverResolves[i];
      func(this.dsHelper);
    }

    this.waitInitOverResolves = [];
  }

  /**
   *
   * @returns
   */
  async getDsHelper(): Promise<dataShare.DataShareHelper | null> {
    if (this.dsHelper) {
      return this.dsHelper;
    }
    if (this.isInitializing) {
      Log.info(this.getTag(), 'getDsHelper isInitializing please wait');
      return new Promise<dataShare.DataShareHelper>((resolve) => {
        this.waitInitOverResolves.push(resolve);
      });
    }
    if (!await this.isCanInit()) {
      Log.warn(this.getTag(), 'getDsHelper isCanInit false');
      return this.dsHelper;
    }
    await this.init();
    return this.dsHelper;
  }

  /**
   * dataShareHelper queryByTable
   * @param { CalendarContract.Tables } table.
   * @param { dataSharePredicates.DataSharePredicates } predicates - Indicates filter criteria.
   * @param { Array<string> } columns - Indicates the columns to query.
   * @param { string } tag - LOG TAG
   * @returns { Promise<InnerResultSet | undefined> } {InnerResultSet}: the query result.
   */
  async query(table: CalendarContract.Tables, predicates: dataSharePredicates.DataSharePredicates,
                     columns: string[], tag: string): Promise<InnerResultSet | undefined> {
    const dsHelper = await ProxyDBUtils.INSTANCE.getDsHelper();
    if (!dsHelper) {
      return undefined;
    }
    Log.hilogInfo(TAG, `query %{public}s %{private}s`, tag, table);
    try {
      const uri = this.dseUri + '/' + table; // Indicates the path of data to query.
      hiTraceMeter.startTrace(tag, 0);
      const oriResultSet = await dsHelper.query(uri, predicates, columns);
      hiTraceMeter.finishTrace(tag, 0);
      if (oriResultSet) {
        return new InnerResultSet(oriResultSet, tag);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'query catch', err);
      SqlFaultHandle.querySqlFail(err?.message, `proxyQuery_${tag}`);
      if (err.code === 1061) { // 因为ResultSet未释放导致查询失败
        ResultSetLeakTracker.dumpResultList();
      }
    }
    return undefined;
  }
}