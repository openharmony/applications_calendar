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

import connection from '@ohos.net.connection';
import { Log } from '@app/common/index';
import { retryUtil } from '@app/common/src/main/ets/util/CommonUtils';
const TAG = 'NetConnectionUtil';

/**
 * 系统网络连接类
 *
 * @since 2023-02-13
 */

export enum NetState {
  NET_UNKNOWN = 0,
  NET_AVAILABLE = 1,
  NET_UN_AVAILABLE = 2,
}

export class NetConnectionUtil {
  private static netCon: connection.NetConnection | undefined;
  private static sFunctions: Map<string, Function> = new Map();
  private static lastNetState: NetState = NetState.NET_UNKNOWN;

  static subscribe(funcModel: string, func: Function) {
    Log.info(TAG, `subscribe`)
    if (!NetConnectionUtil.netCon) {
      NetConnectionUtil.netCon = connection.createNetConnection();
      NetConnectionUtil.netCon.register((err, data) => {
        Log.logErrorMsg(TAG, 'subscribe->register', err);
      });
      NetConnectionUtil.netCon.on('netAvailable', async (data) => {
        const isNetAvailable = await retryUtil(NetConnectionUtil.isNetAvailable, 3, 300,
          (isNetAvailable): boolean => {
            return !!isNetAvailable;
          });
        Log.log(TAG, `subscribe is available, netId is ${data.netId}, isNetAvailable = ${isNetAvailable}`);
        if (!isNetAvailable) {
          Log.warn(TAG, 'network is unavailable')
          return;
        }
        if (NetConnectionUtil.lastNetState === NetState.NET_AVAILABLE) {
          Log.warn(TAG, `lastNetState is ${NetConnectionUtil.lastNetState} no change no need update`)
          return;
        }
        NetConnectionUtil.lastNetState = NetState.NET_AVAILABLE;
        Log.log(TAG, `net is available, notifyNetStateChanged lastNetState is ${NetConnectionUtil.lastNetState}`);
        NetConnectionUtil.notifyNetStateChanged();
      });
      // 断开wifi的时候没有回调
      NetConnectionUtil.netCon.on('netUnavailable', () => {
        Log.log(TAG, 'subscribe is netUnavailable');
        if (NetConnectionUtil.lastNetState == NetState.NET_UN_AVAILABLE) {
          Log.warn(TAG, `lastNetState is ${NetConnectionUtil.lastNetState} no change no need update`)
          return;
        }
        NetConnectionUtil.lastNetState = NetState.NET_UN_AVAILABLE;
        Log.log(TAG, `net is Unavailable, notifyNetStateChanged lastNetState is ${NetConnectionUtil.lastNetState}`);
        NetConnectionUtil.notifyNetStateChanged();
      });

      NetConnectionUtil.netCon.on('netLost', () => {
        Log.log(TAG, 'subscribe is netLost');
        if (NetConnectionUtil.lastNetState == NetState.NET_UN_AVAILABLE) {
          Log.warn(TAG, `lastNetState is ${NetConnectionUtil.lastNetState} no change no need update`)
          return;
        }
        NetConnectionUtil.lastNetState = NetState.NET_UN_AVAILABLE;
        Log.log(TAG, `net is netLost, notifyNetStateChanged lastNetState is ${NetConnectionUtil.lastNetState}`);
        NetConnectionUtil.notifyNetStateChanged();
      });
    }

    NetConnectionUtil.sFunctions.set(funcModel, func);
    if (NetConnectionUtil.lastNetState != NetState.NET_UNKNOWN) {
      if (typeof func === 'function') {
        func(NetConnectionUtil.lastNetState);
      }
    }
  }

  /**
   * 检查当前网络是否可以正常上网
   * res === 0: 设备无网络
   * res === 12: 获取网络状态成功，但网络无宽带，无法上网
   * res === 31: 当前正在检查网络，可以直接通知状态为未连接
   * res === 16: 获取网络状态成功，且有宽带，可以上网
   */
  static async isNetAvailable(): Promise<boolean> {
    Log.info(TAG, `isNetAvailable start`);
    let res: number = connection.NetCap.NET_CAPABILITY_MMS;
    try {
      let defaultNet = await connection.getDefaultNet();
      let netCap = await connection.getNetCapabilities(defaultNet);
      if (netCap) {
        let itemNumber: Set<number> = new Set(netCap.networkCap);
        let dataNumber = Array.from(itemNumber.values());
        if (dataNumber.includes(connection.NetCap.NET_CAPABILITY_INTERNET)) {
          if (dataNumber.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
            // networkCap中，如果包含31，则说明当前网络正在检查
            res = connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY;
          } else {
            res = dataNumber.includes(connection.NetCap.NET_CAPABILITY_VALIDATED) ?
            connection.NetCap.NET_CAPABILITY_VALIDATED :
            connection.NetCap.NET_CAPABILITY_INTERNET;
          }
        }
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'isNetAvailable', err);
    } finally {
      Log.info(TAG, `isNetAvailable finish, res: ${res}`);
    }

    if (res === connection.NetCap.NET_CAPABILITY_VALIDATED) {
      return true;
    }
    return false;
  }

  static notifyNetStateChanged() {
    Log.info(TAG, `notifyNetStateChanged, sFunctions length is ${NetConnectionUtil.sFunctions.size}, lastNetState: ${NetConnectionUtil.lastNetState}`);
    for (const func of NetConnectionUtil.sFunctions.values()) {
      if (typeof func === 'function') {
        func(NetConnectionUtil.lastNetState);
      }
    }
  }

  static unSubscribe() {
    try {
      NetConnectionUtil.sFunctions.clear();
      if (!NetConnectionUtil.netCon) {
        Log.error(TAG, 'unSubscribeNet: NO VALID NET CONNECTION!');
        return;
      }
      NetConnectionUtil.netCon.unregister((err, data) => {
        if (err) {
          Log.logErrorMsg(TAG, 'unSubscribe->unregister', err);
        } else {
          Log.info(TAG, `unSubscribe success.`);
        }
      })
    } catch (err) {
      Log.warn(TAG, `dsHelper error: ${err?.message}`);
    } finally {
      NetConnectionUtil.netCon = undefined;
    }
  }

  static unSubscribeFun(funcModel: string) {
    if (NetConnectionUtil.sFunctions.has(funcModel)) {
      NetConnectionUtil.sFunctions.delete(funcModel);
      return;
    }
    Log.warn(TAG, `unSubscribeFun sFunctions no ${funcModel}`);
  }
}

