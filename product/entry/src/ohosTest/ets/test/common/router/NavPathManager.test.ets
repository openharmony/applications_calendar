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

import { ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { ModuleName, NavPathManager, NavPathName, RouterModel, RouterName } from '@app/common';

export default function NavPathManagerTest() {
  describe('NavPathManagerTest', () => {
    let manager: NavPathManager
    beforeEach(() => {
      manager = new NavPathManager();
    });

    it('createRouter_01', 0, () => {
      let ret = manager.createRouter('home', new NavPathStack());
      expect(ret).assertTrue();
    });

    it('createRouter_already_create', 0, () => {
      let ret = manager.createRouter('home', new NavPathStack());
      expect(ret).assertTrue();
      ret = manager.createRouter('home', new NavPathStack());
      expect(ret).assertFalse();
    });

    it('getRouter', 0, () => {
      let router = manager.getRouter('home');
      expect(router).assertUndefined();
      let ret = manager.createRouter('home', new NavPathStack());
      expect(ret).assertTrue();
      router = manager.getRouter('home');
      expect(router).not().assertUndefined();
    });

    it('getHarName_builderName_is_empty', 0, () => {
      let result = manager.getHarName('');
      expect(result).assertEqual(undefined);
    });

    it('getHarName_builderName_matches_pathName', 0, () => {
      let result = manager.getHarName(NavPathName.AGENDA_LIST);
      expect(result).assertEqual(ModuleName.AGENDA);
    });

    it('getHarName_builderName_not_matches_pathName', 0, () => {
      let result = manager.getHarName('unkown');
      expect(result).assertEqual(undefined);
    });

    it('dynamicBuild', 0, async (done: Function) => {
      let result = await manager.dynamicBuild('');
      expect(result).assertEqual(false);
      done();
    });

    it('pushPath', 0, async (done: Function) => {
      let result = await manager.pushPath({
        builderName : 'xxx',
        routerName : 'x',
        param : {}
      });
      expect(result).assertEqual(false);
      done();
    });

    it('clear', 0, () => {
      let result = manager.clear(RouterName.ENTRY_HAP);
      expect(result).assertEqual(false);
    });

    it('removeByName', 0, () => {
      let result = manager.removeByName(RouterName.ENTRY_HAP, '');
      expect(result).assertEqual(-1);
    });

    it('discard', 0, () => {
      let result = manager.discard(RouterName.ENTRY_HAP);
      expect(result).assertEqual(false);
    });

    it('pushPathByName', 0, () => {
      let result = manager.pushPathByName(RouterName.ENTRY_HAP, '', {});
      expect(result).assertEqual(false);
    });

    it('replacePath', 0, () => {
      let result = manager.replacePath(RouterName.ENTRY_HAP, {});
      expect(result).assertEqual(false);
    });

    it('replacePathByName_when_getRouter_returns_undefined', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc1: Function = mocker.mockFunc(manager, manager.dynamicBuild);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(Promise.resolve(true));
      let mockfunc2: Function = mocker.mockFunc(manager, manager.getRouter);
      when(mockfunc2)(ArgumentMatchers.anyString).afterReturn(undefined);
      let result = await manager.replacePathByName({
        builderName : 'xxx',
        routerName : 'x',
        param : {}
      });
      expect(result).assertEqual(false);
      mocker.ignoreMock(manager, manager.dynamicBuild);
      mocker.ignoreMock(manager, manager.getRouter);
      done();
    });

    it('replacePathByName_when_is_called_successfull', 0, async (done: Function) => {
      let mocker: MockKit = new MockKit();
      let mockfunc1: Function = mocker.mockFunc(manager, manager.dynamicBuild);
      when(mockfunc1)(ArgumentMatchers.anyString).afterReturn(Promise.resolve(true));
      let mockfunc2: Function = mocker.mockFunc(manager, manager.getRouter);
      let mockRouterStack: NavPathStack = new NavPathStack();
      when(mockfunc2)(ArgumentMatchers.anyString).afterReturn(mockRouterStack);
      let result = await manager.replacePathByName({
        builderName : 'xxx',
        routerName : 'x',
        param : {}
      });
      expect(result).assertEqual(true);
      mocker.ignoreMock(manager, manager.dynamicBuild);
      mocker.ignoreMock(manager, manager.getRouter);
      done();
    });

  })
}