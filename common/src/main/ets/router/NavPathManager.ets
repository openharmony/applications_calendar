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

import { Log } from '../default/common/Log';

import { SingleInstanceHelper } from '../templates/SingleInstanceHelper';
import { EmptyUtils } from '../util/EmptyUtils';
import { TypeUtils } from '../util/TypeUtils';
import { NavPageBuilderFactory } from './NavPageBuilderFactory';
import { harBuilderConfig, RouterName } from './RouterConstants';
import { RouterModel } from './RouterModel';

const TAG: string = 'NavPathManager';

export class NavPathManager {
  private routerMap: Map<string, NavPathStack> = new Map<string, NavPathStack>();

  static getInstance(): NavPathManager {
    return SingleInstanceHelper.createOrGet(NavPathManager, TAG);
  }

  // Registering a router by name.
  public createRouter(routerName: string, router: NavPathStack): boolean {
    if (this.routerMap.has(routerName)) {
      Log.warn(TAG, `Router ${routerName} has already been created`);
      return false;
    }
    this.routerMap.set(routerName, router);
    return true;
  }

  // Get router by name.
  public getRouter(routerName: string): NavPathStack | undefined {
    if (!this.routerMap.has(routerName)) {
      Log.warn(TAG, `Router ${routerName} has not been created`);
      return undefined;
    }
    return this.routerMap.get(routerName);
  }

  // Pop router by name.
  public popRouter(routerName: string, animated: boolean = true): NavPathInfo | undefined {
    if (!this.routerMap.has(routerName)) {
      Log.warn(TAG, `Router ${routerName} has not been created`);
      return undefined;
    }
    return this.routerMap.get(routerName)!.pop(animated);
  }

  public getHarName(builderName: string): string | undefined {
    if (builderName === '') {
      Log.warn(TAG, 'builderName empty');
      return undefined;
    }
    for (let value of harBuilderConfig) {
      if (value.pathName === builderName) {
        return value.harName;
      }
    }
    return undefined;
  }

  public async dynamicBuild(builderName: string): Promise<boolean> {
    if (NavPageBuilderFactory.getBuilder(builderName)) {
      return true;
    }
    Log.info(TAG, `dynamicBuild import dynamic:${builderName}`);
    const harName = this.getHarName(builderName);
    if (!harName) {
      Log.error(TAG, 'dynamicBuild get harName failed');
      return false;
    }
    const importResult = await import(harName)
      .then((ns: ESObject): boolean => {
        if (EmptyUtils.isUndefinedOrNull(ns)) {
          Log.error(TAG, `dynamicBuild harName ${harName} ns is null`);
          return false;
        }
        const harInit: Function = ns.harInit;
        if (!harInit) {
          Log.warn(TAG, `dynamicBuild builderName: ${builderName} no harInit Property`);
          return false;
        }
        if (!TypeUtils.isFunction(harInit)) {
          Log.warn(TAG, `dynamicBuild builderName: ${builderName} harInit not function`);
          return false;
        }
        return harInit(builderName);
      })
      .catch((error: ESObject) => {
        Log.logErrorMsg(TAG, `dynamicBuild error`, error);
        return false;
      });
    if (!importResult) {
      Log.warn(TAG, `dynamicBuild builderName: ${builderName} dynamicBuild result is ${importResult}`);
      return false;
    }
    return true;
  }

  // Jumping to a Specified Page by Obtaining the Page Stack.
  public async pushPath(routerData: RouterModel): Promise<boolean> {
    if (!await this.dynamicBuild(routerData.builderName)) {
      return false;
    }
    const router = this.getRouter(routerData.routerName);
    if (router) {
      router.pushPathByName(routerData.builderName, routerData.param, routerData.animated);
    } else {
      Log.warn(TAG, `push router ${routerData.routerName} not exist`);
      return false;
    }
    return true;
  }

  // try to clear navStack
  public clear(routerName: RouterName): boolean {
    const router = this.getRouter(routerName);
    if (!router) {
      Log.warn(TAG, `push router ${routerName} not exist`);
      return false;
    }
    router.clear();
    return true;
  }

  public removeByName(routerName: RouterName, name: string): number {
    const router = this.getRouter(routerName);
    if (router) {
      return router.removeByName(name);
    }
    Log.warn(TAG, `removeByName ${routerName} not exist`);
    return -1;
  }

  // try to discard navStack named by routerName, and this navStack will cleared in Memory
  public discard(routerName: RouterName): boolean {
    const router = this.getRouter(routerName);
    if (!router) {
      Log.warn(TAG, `push router ${routerName} not exist when discarding it`);
      return false;
    }
    this.routerMap.delete(routerName);
    return true;
  }


  public pushPathByName(routerName: RouterName, name: string, param: ESObject, animated?: boolean): boolean {
    const router = this.getRouter(routerName);
    if (router) {
      router.pushPathByName(name, param, animated);
      return true;
    } else {
      Log.warn(TAG, `push router ${routerName} not exist`);
    }
    return false;
  }

  public replacePath(routerName: RouterName, info: ESObject, animated?: boolean): boolean {
    const router = this.getRouter(routerName);
    if (router) {
      router.replacePath(info, animated);
      return true;
    } else {
      Log.warn(TAG, `replacePath ${routerName} not exist`);
    }
    return false;
  }

  public async replacePathByName(routerData: RouterModel, animated?: boolean): Promise<boolean> {
    if (!await this.dynamicBuild(routerData.builderName)) {
      return false;
    }
    const router = this.getRouter(routerData.routerName);
    if (router) {
      router.replacePathByName(routerData.builderName, routerData.param, animated);
    } else {
      Log.warn(TAG, `push router ${routerData.routerName} not exist`);
      return false;
    }
    return true;
  }

  public getParamByName<T>(name: string, routerName: string): T[] {
    const router = this.getRouter(routerName);
    if (router) {
      return router.getParamByName(name) as T[];
    } else {
      Log.warn(TAG, `getParamByName ${routerName} not exist`);
      return [];
    }
  }
}