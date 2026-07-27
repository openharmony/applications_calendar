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


import { Driver } from '@ohos.UiTest';
import { expect, MockKit } from '@ohos/hypium';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { BusinessError } from '@ohos.base';
import { GlobalThis, Log } from '@app/common';

const delegator = AbilityDelegatorRegistry.getAbilityDelegator()
const bundleName = AbilityDelegatorRegistry.getArguments().bundleName;
const TAG = 'TestUtil';

let abilityStartFlag = false;

export class TestUtil {
  static sleep(time: number) {
    return new Promise<void>((resolve: Function) => setTimeout(resolve, time));
  }

  static async clickToMainPage(driver: Driver, testButton: boolean = true): Promise<void> {
    if (abilityStartFlag) {
      Log.info(TAG, "MainAbility already start");
      return;
    }
    let cmd = 'aa start -b ' + bundleName + ' -a MainAbility'
    await delegator.executeShellCommand(cmd)
      .then((data) => {
        Log.info(TAG, 'executeShellCommand succeed');
        abilityStartFlag = true;
      }).catch((err: BusinessError) => {
        Log.info(TAG, `executeShellCommand failed:${JSON.stringify(err)}`);
        expect(err).assertEqual(null);
      })
  }

  static ExpectResourceColor(color1: ResourceColor, color2: ResourceColor) {
    const typeofColor1 = typeof color1;
    const typeofColor2 = typeof color2;
    expect(typeofColor1).assertEqual(typeofColor2);
    if (typeofColor1 === "string") {
      const value1 = color1 as string;
      const value2 = color2 as string;
      expect(value1).assertEqual(value2);
    } else if (typeofColor1 === "object") {
      const value1 = color1 as Resource;
      const value2 = color2 as Resource;
      expect(GlobalThis.getResourceStr(value1)).assertEqual(GlobalThis.getResourceStr(value2));
    }
  }

  // 测试私有函数
  static getPrivateFunction(obj: object, functionName: string): Function | null {
    const func: Function = obj[functionName];
    if (func) {
      return func.bind(obj);
    } else {
      return null;
    }
  }

  // 获取私有属性
  static getPrivateAttribute<T>(obj: object, attributeName: string): T {
    return obj[attributeName];
  }

  // 设置私有属性
  static setPrivateAttribute(obj: object, attributeName: string,
                             para: object | number | boolean | string | undefined | null): void {
    obj[attributeName] = para;
  }

  // 返回私有方法mock对象
  static getPrivateMockFunction(mocker: MockKit, obj: object, functionName: string): Function {
    return mocker.mockFunc(obj, obj[functionName]);
  }
}
