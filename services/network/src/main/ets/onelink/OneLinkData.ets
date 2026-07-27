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
import ArrayList from '@ohos.util.ArrayList';

export class OneLinkData {
  public oneLinkSrvList: ArrayList<OneLinkSrvListBean> = new ArrayList<OneLinkSrvListBean>();
  public lastChangeTime: string = '';
}

export class OneLinkSrvListBean {
  public serviceId: string = '';
  public serviceMeta: ServiceMetaBean = new ServiceMetaBean();
  public appList: ArrayList<AppListBean> = new ArrayList();
}

class ServiceMetaBean {
  public bussinessType: string = '';
}

export class AppListBean {
  public abilityId: string = '';
  public appPkg: string = '';
  public serviceLink: ServiceLinkBean = new ServiceLinkBean();
  public serviceUnLink: ServiceUnLinkBean = new ServiceUnLinkBean();
}

export class ServiceLinkBean {
  public webURL: string = '';
  public deepLink: DeepLinkBean = new DeepLinkBean();
  public faLink: FaLinkBean = new FaLinkBean();
}

export class ServiceUnLinkBean {
  public webURL: string = '';
  public deepLink: DeepLinkBean = new DeepLinkBean();
  public faLink: FaLinkBean = new FaLinkBean();
}

export class DeepLinkBean {
  public url: string = '';
  public appName: string = '';
  public appPackage: string = '';
  public minVersion: number = 0;
  public minOpenHarmonyAPILevel: number = 0;
  public minOsSingleFrameHapApiVersion: number = 0;
  public backUpAppPackageList: Object = new Object();
}

export class FaLinkBean {
  public packageName: string = '';
  public serviceName: string = '';
  public moduleName: string = '';
  public faParam: string = ''
}