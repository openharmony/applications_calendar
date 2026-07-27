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

import deviceInfo from '@ohos.deviceInfo';
import util from '@ohos.util';
import { AppListBean, OneLinkData, OneLinkSrvListBean } from './OneLinkData';
import { GlobalThis } from '@app/common/src/main/ets/data/GlobalThis';
import { Log } from '@app/common/src/main/ets/default/common/Log';
import { PermissionState } from '@app/common/src/main/ets/default/common/declare';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import bundleManager from '@ohos.bundle.bundleManager';
import { OneLinkService } from '@app/common/src/main/ets/dao/service/OneLinkService';
import hiTraceMeter from '@ohos.hiTraceMeter';
import { traceEvents } from '@app/common/src/main/ets/default/common/TraceEvents';
import { HOURS_PER_DAY, MILLS_PER_HOUR } from '@app/common/src/main/ets/util/DateUtil';
import { EmptyUtils } from '@app/common/src/main/ets/util/EmptyUtils';
import { PreferencesUtil } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesUtil';
import { PreferencesFiles } from '@app/common/src/main/ets/default/util/preferences_util/PreferencesFiles';
import { HttpRequestOptions, HttpResponseAdapter } from '../net/HttpClient';
import { HttpMethod, RequestHeaders } from '../net/HttpConfig';
import { GlobalNetService } from '../interface/GlobalNetService';
import { ServiceManager } from '@app/common/src/main/ets/service/framework/ServiceManager';
import { ServiceEnum } from '@app/common/src/main/ets/service/framework/ServiceEnum';

// 涉网络接口请求，屏蔽DT覆盖率校验
/* instrument ignore file */

const TAG: string = 'HAGHelper';

const IS_ALLOW_NETWORK: string = 'IS_ALLOW_NETWORK';
const HAG_TIMEOUT: number[] = [3000, 6000, 9000];

const TRACE_ID_BEGIN: number = 0;
const TRACE_ID_END: number = 32;

const DOWNLOAD_HAG_DELAY: number = 1000;

const S_PKG_NAME: string = 'com.openharmony.calendar';

export class HAGHelper {
  private static _instance: HAGHelper = new HAGHelper();
  private sPhoneType: string = '';
  private sSystemVersion: string = '';
  private sVersionName: string = '';
  private sPkgName: string = '';
  private sTraceId: string = '';
  private sUdid: string = '';
  private versionName: string = '';
  private sOneLinkData: OneLinkData = new OneLinkData();
  private timeOutId: number = -1;

  static instance(): HAGHelper {
    return HAGHelper._instance;
  }

  async init(): Promise<void> {
    try {
      if (await this.isOutDate()) {
        this.doInBackground();
      } else {
        Log.warn(TAG, `HAGHelper Frequent visits, No Need To Update HAG!`);
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'HAGHelper', err);
    }
  }

  // 批量插入数据库
  private async batchInsertDb(dataArr: Array<ValuesBucket>) {
    if (dataArr) {
      const isSucceed: boolean = await OneLinkService.INSTANCE.insertOneLinkDataArray(dataArr) as boolean;
      if (isSucceed) {
        PreferencesUtil.putNumberValueSync(PreferencesFiles.HAG, 'date', new Date().getTime());
        PreferencesUtil.putStringArrayValueSync(PreferencesFiles.HAG, 'serviceType', GlobalThis.getInstance()
          .serviceType);
        Log.info(TAG, 'Insert HAG success');
      } else {
        Log.error(TAG, 'Insert HAG error');
      }
    }
  }

  //初始化请求包体
  private async initHaGRequestBody(): Promise<HAGRequestBody> {
    let hagRequestBody: HAGRequestBody = new HAGRequestBody();
    let getInfo: TerminalInfo = hagRequestBody.getTerminalInfo();
    let lastChangeTime: string = JSON.stringify(
      PreferencesUtil.getStringValueSync(PreferencesFiles.HAG, 'lastChangeTime', ''));
    getInfo.setPhoneType(this.sPhoneType);
    getInfo.setPrdVer(this.sVersionName);
    getInfo.setSysVer(this.sSystemVersion);
    if (lastChangeTime.length === 0) {
      Log.info(TAG, `lastChangeTime is Not Null, lastChangeTime = ${lastChangeTime}}`);
      hagRequestBody.setLastChangeTime(lastChangeTime);
    }
    Log.info(TAG, `initHAGRequestBody lastChangeTime: ${lastChangeTime}`);
    return hagRequestBody;
  }

  // 发送http请求
  async getDataFromHAG() {
    const globalNetService = ServiceManager.getInstance().getService<GlobalNetService>(ServiceEnum.GLOBAL_NET_SERVICE);
    if (!globalNetService) {
      Log.error(TAG, `getDataFromHAG globalNetService is null`);
      return;
    }
    //初始化uri路径
    const url: string = GlobalThis.getResourceStr($r('app.string.ONE_LINK_URL'));
    //初始化机器信息
    await this.initMachineInfo();
    //初始化请求体
    let hagRequestBody: HAGRequestBody = await this.initHaGRequestBody();
    let jsonContent: string = JSON.stringify(hagRequestBody);
    const requestHeaders: RequestHeaders = {
      'x-prd-pkg-name': this.sPkgName,
      'x-client-version': this.sPkgName + '_' + this.sVersionName,
      'x-access-key': '1',
      'Content-Type': 'application/json',
      'x-hag-trace-id': this.sTraceId + '-' + (new Date().getTime()),
      'x-udid': this.sUdid,
      'x-device-id': this.sUdid
    }
    let count: number = 0;
    const REQUEST_COUNT = 3;
    let responseBody: string | null = '';
    while (count < REQUEST_COUNT) {
      count++;
      const requestOptions: HttpRequestOptions = {
        url: url,
        method: HttpMethod.POST,
        headers: requestHeaders,
        body: jsonContent
      };
      hiTraceMeter.startTrace(traceEvents.hagDownload, 0);
      try {
        const response: HttpResponseAdapter = await globalNetService.getRequestHelper().fetch(requestOptions);
        responseBody = response.toString();
        break;
      } catch (error) {
        Log.logErrorMsg(TAG, `getDataFromHAG`, error);
      }
      if (count === REQUEST_COUNT) {
        Log.error(TAG, 'http response error');
        break;
      }
    }
    hiTraceMeter.finishTrace(traceEvents.hagDownload, 0);
    if (EmptyUtils.isNotOrEmptyString(responseBody)) {
      Log.warn(TAG, `hag response body is empty`);
    } else {
      this.parseDataFromHAG(responseBody!);
    }
    clearTimeout(this.timeOutId);
  }

  // download HAG
  async doInBackground(): Promise<boolean> {
    Log.info(TAG, 'doInBackground called');
    // 每次启动短时间会脉冲式打印日志，导致本功能的日志无法打出，后续版本稳定后考虑删除延时
    this.timeOutId = setTimeout(() => {
      this.getDataFromHAG();
    }, DOWNLOAD_HAG_DELAY)
    return true;
  }

  // 判断当前设备是否联网
  async getNetPermission(): Promise<number> {
    return PreferencesUtil.getNumberValueSync(PreferencesFiles.SETTINGS, IS_ALLOW_NETWORK, PermissionState.UNCONFIRMED);
  }

  /**
   * 判断上次全量访问的数据是否过期
   * @returns
   */
  private async isOutDate(): Promise<boolean> {
    let date: number = PreferencesUtil.getNumberValueSync(PreferencesFiles.HAG, 'date', 0);
    const now: number = new Date().getTime();
    const total = (now - date) / MILLS_PER_HOUR;
    return date === 0 || total > HOURS_PER_DAY;
  }

  //获取版本号
  private async getsVersion() {
    try {
      const bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      this.versionName = bundleInfo.versionName;

    } catch (error) {
      Log.logErrorMsg(TAG, 'getsVersion', error);
    }
  }

  //初始化机器信息
  private async initMachineInfo() {
    if (EmptyUtils.isEmptyString(this.sVersionName, true)) {
      await this.getsVersion();
      this.sVersionName = this.versionName;
    }
    if (EmptyUtils.isEmptyString(this.sPkgName, true)) {
      this.sPkgName = S_PKG_NAME;
    }
    if (EmptyUtils.isEmptyString(this.sPhoneType, true)) {
      this.sPhoneType = deviceInfo.productModel;
    }
    if (EmptyUtils.isEmptyString(this.sSystemVersion, true)) {
      this.sSystemVersion = deviceInfo.osFullName;
    }
    if (EmptyUtils.isEmptyString(this.sUdid, true) || EmptyUtils.isEmptyString(this.sTraceId, true)) {
      const reg1 = new RegExp('-', 'gm');
      this.sUdid = util.generateRandomUUID(true).toString().replace(reg1, '') + util.generateRandomUUID(true)
        .toString()
        .replace(reg1, '');
      this.sTraceId = this.sUdid.substring(TRACE_ID_BEGIN, TRACE_ID_END);
    }
  }

  // 将hag转换成Object
  private async parseDataFromHAG(jsonData: string) {
    try {
      this.sOneLinkData = JSON.parse(jsonData);
      Log.info(TAG, `sOneLinkData = lastChangeTime: ${this.sOneLinkData?.lastChangeTime},oneLinkSrvList length: ${this.sOneLinkData?.oneLinkSrvList?.length}`);
      if (this.sOneLinkData === null || this.sOneLinkData?.lastChangeTime === undefined) {
        Log.warn(TAG, 'No Valid OneLinkData!');
        return;
      }
      PreferencesUtil.putStringValueSync(PreferencesFiles.HAG, 'lastChangeTime', this.sOneLinkData.lastChangeTime);
      this.parseServiceDataList();
    } catch (err) {
      Log.logErrorMsg(TAG, 'parseDataFromHAG get exception err', err);
    }
  }

  //封装结果为数组
  private parseServiceDataList(): void {
    if (this.sOneLinkData === null || this.sOneLinkData.oneLinkSrvList === null) {
      return;
    }
    let dataArr: ValuesBucket[] = [];
    Object.values(this.sOneLinkData.oneLinkSrvList).forEach((datas: OneLinkSrvListBean) => {
      if (!EmptyUtils.isEmptyString(datas.serviceId)) {
        GlobalThis.getInstance().serviceType.push(datas.serviceId);
        Object.values(datas.appList).forEach((data: AppListBean) => {
          const value = this.formatValuesBucket(datas.serviceId, datas.serviceMeta, data);
          dataArr.push(value);
        })
      }
    })
    this.batchInsertDb(dataArr);
    return;
  }

  /**
   * 将查询到的服务端数据转化为数据库
   * @param serviceId
   * @param serviceMeta
   * @param data
   * @returns
   */
  private formatValuesBucket(serviceId: string, serviceMeta: Object, data: AppListBean): ValuesBucket {
    const value: ValuesBucket = {
      'service_id': serviceId,
      'service_meta': JSON.stringify(serviceMeta),
      'app_pkg': data.appPkg,
      'ability_id': data.abilityId,
      'web_url': data.serviceLink === null ? 'null' : JSON.stringify(data.serviceLink.webURL),
      'fa_link': data.serviceLink === null ? 'null' : JSON.stringify(data.serviceLink.faLink),
      'url': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.url,
      'app_name': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.appName,
      'app_package': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.appPackage,
      'min_version': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.minVersion,
      'min_api_level': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.minOpenHarmonyAPILevel,
      'min_hos_api_version': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : data.serviceLink.deepLink.minOsSingleFrameHapApiVersion,
      'back_up_app_package_list': ((data.serviceLink === null) || (data.serviceLink.deepLink === null)) ? 'null' : JSON.stringify(data.serviceLink.deepLink.backUpAppPackageList),
      'service_unlink': JSON.stringify(data.serviceUnLink)
    }
    return value;
  }
}

/**
 * HAG包体
 */
class HAGRequestBody {
  private terminalInfo: TerminalInfo = new TerminalInfo();

  private lastChangeTime: string | undefined;

  setTerminalInfo(terminalInfo: TerminalInfo): void {
    this.terminalInfo = terminalInfo;
  }

  getTerminalInfo(): TerminalInfo {
    return this.terminalInfo;
  }

  setLastChangeTime(lastChangeTime: string): void {
    this.lastChangeTime = lastChangeTime;
  }

  getLastChangeTime(): string | undefined {
    return this.lastChangeTime;
  }
}

class TerminalInfo {
  private language: string = '';

  private prdVer: string = '';

  private phoneType: string = '';

  private sysVer: string = '';

  setPrdVer(prdVer: string): void {
    this.prdVer = prdVer;
  }

  getPrdVer(): string {
    return this.prdVer;
  }

  setLanguage(language: string): void {
    this.language = language;
  }

  getLanguage(): string {
    return this.language;
  }

  setPhoneType(phoneType: string): void {
    this.phoneType = phoneType;
  }

  gePhoneType(): string {
    return this.phoneType;
  }

  setSysVer(sysVer: string): void {
    this.sysVer = sysVer;
  }

  geSysVer(): string {
    return this.sysVer;
  }
}

