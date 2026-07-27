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

/**
 * 自定义接口，用来保存某个页面相关的转场动画回调和参数
 */

export type AniActionCallback = (operation: boolean, isExit: boolean) => void | undefined

export type InteractiveCallback = (operation: NavigationOperation) => void | undefined

// 自定义接口，用来保存某个页面相关的转场动画回调和参数
export interface AnimateCallback {
  finish?: AniActionCallback;
  start?: AniActionCallback;
  onFinish?: AniActionCallback;
  interactive?: InteractiveCallback;
  timeout?: number;
}

const customTransitionMap: Map<string, AnimateCallback> = new Map();

export class CustomTransition {
  public static delegate = new CustomTransition();
  public interactive: boolean = false;
  public proxy: NavigationTransitionProxy | undefined = undefined;
  private animationId: number = 0;
  public operation: NavigationOperation = NavigationOperation.PUSH

  static getInstance() {
    return CustomTransition.delegate;
  }

  /* 注册某个页面的动画回调
   * name: 注册页面的唯一id
   * startCallback：用来设置动画开始时页面的状态
   * endCallback：用来设置动画结束时页面的状态
   * onFinish：用来执行动画结束后页面的其他操作
   * interactiveCallback: 注册的可交互转场的动效
   * timeout：转场结束的超时时间
   */
  public registerNavParam(name: string,
                          startCallback: AniActionCallback,
                          endCallback: AniActionCallback,
                          onFinish: AniActionCallback,
                          interactiveCallback: InteractiveCallback,
                          timeout: number): AnimateCallback {
    if (customTransitionMap.has(name)) {
      const param = customTransitionMap.get(name) as AnimateCallback;
      if (param != undefined) {
        param.start = startCallback;
        param.finish = endCallback;
        param.timeout = timeout;
        param.onFinish = onFinish;
        param.interactive = interactiveCallback;
        return param;
      }
    }
    const params: AnimateCallback = {
      timeout: timeout,
      start: startCallback,
      finish: endCallback,
      onFinish: onFinish,
      interactive: interactiveCallback
    };
    customTransitionMap.set(name, params);
    return params;
  }

  public getAnimationId(): number {
    return Date.now();
  }

  public unRegisterNavParam(name: string): void {
    customTransitionMap.delete(name);
  }

  public fireInteractiveAnimation(id: string, operation: NavigationOperation) {
    let animation = customTransitionMap.get(id)?.interactive;
    if (!animation) {
      return;
    }
    animation(operation);
  }

  public updateProgress(progress: number) {
    if (!this.proxy?.updateTransition) {
      return;
    }
    progress = this.operation == NavigationOperation.PUSH ? 1 - progress : progress;
    this.proxy?.updateTransition(progress);
  }

  public cancelTransition() {
    if (this.proxy?.cancelTransition) {
      this.proxy.cancelTransition();
    }
  }

  public recoverState() {
    if (!this.proxy?.from.navDestinationId || !this.proxy?.to.navDestinationId) {
      return;
    }
    let fromParam = customTransitionMap.get(this.proxy.from.navDestinationId);
    if (fromParam?.onFinish) {
      fromParam.onFinish(false, false);
    }
    let toParam = customTransitionMap.get(this.proxy?.to.navDestinationId);
    if (toParam?.onFinish) {
      toParam.onFinish(true, true);
    }
  }

  public finishTransition() {
    this.proxy?.finishTransition();
  }

  public finishInteractiveAnimation(rate: number) {
    if (this.operation == NavigationOperation.PUSH) {
      if (rate > 0.5) {
        if (this.proxy?.cancelTransition) {
          this.proxy.cancelTransition();
        }
      } else {
        this.proxy?.finishTransition();
      }
    } else {
      if (rate > 0.5) {
        this.proxy?.finishTransition();
      } else {
        if (this.proxy?.cancelTransition) {
          this.proxy.cancelTransition();
        }
      }
    }
  }

  public getAnimateParam(name: string): AnimateCallback {
    const animateParam = customTransitionMap.get(name);
    const result: AnimateCallback = {
      start: animateParam?.start,
      finish: animateParam?.finish,
      timeout: animateParam?.timeout,
      onFinish: animateParam?.onFinish,
      interactive: animateParam?.interactive,
    };
    return result;
  }
}