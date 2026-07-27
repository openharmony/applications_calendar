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

export type BackPressInterceptor = () => boolean;

export type OnHidden = () => void;

export type OnShown = () => void;


export class ViewCallInterceptorHolder {
  static sInstance: ViewCallInterceptorHolder = new ViewCallInterceptorHolder();
  private mInterceptors: ArrayList<BackPressInterceptor> = new ArrayList();
  private mOnHiddenList: ArrayList<OnHidden> = new ArrayList();
  private mOnShownList: ArrayList<OnShown> = new ArrayList();

  static getInstance() {
    return ViewCallInterceptorHolder.sInstance;
  }

  addViewCallBacks(handleBackPress: BackPressInterceptor, onHidden: OnHidden, onShown: OnShown) {
    this.mInterceptors.add(handleBackPress);
    this.mOnHiddenList.add(onHidden);
    this.mOnShownList.add(onShown);
  }

  removeViewCallBacks(handleBackPress: BackPressInterceptor, onHidden: OnHidden, onShown: OnShown) {
    this.mInterceptors.remove(handleBackPress);
    this.mOnHiddenList.remove(onHidden);
    this.mOnShownList.remove(onShown);
  }

  addBackPressInterceptor(handleBackPress: BackPressInterceptor) {
    this.mInterceptors.add(handleBackPress);
  }

  removeBackPressInterceptor(handleBackPress: BackPressInterceptor) {
    this.mInterceptors.remove(handleBackPress);
  }

  hookBackPress(): boolean {
    for (let i = 0; i < this.mInterceptors.length; i++) {
      const interceptor: BackPressInterceptor = this.mInterceptors[i];
      if (interceptor()) {
        return true;
      }
    }
    return false;
  }

  dispatchOnHidden(): void {
    for (let i = 0; i < this.mOnHiddenList.length; i++) {
      const onHidden: OnHidden = this.mOnHiddenList[i];
      onHidden();
    }
  }

  dispatchOnShow(): void {
    for (let i = 0; i < this.mOnShownList.length; i++) {
      const onShown: OnShown = this.mOnShownList[i];
      onShown();
    }
  }
}