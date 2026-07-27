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
import { beforeEach, describe, expect, it } from '@ohos/hypium'
import { factory, publicApi, Service, ServiceFactory } from '@app/common'
import { ServiceErrCode } from '@app/common/src/main/ets/service/framework/ServiceConsts'
import { ServiceApi } from '@app/common/src/main/ets/service/framework/ServiceApi'

export default function ServiceApiTest() {
  describe('ServiceApiTest', () => {
    beforeEach(() => {
      ServiceApi.clear();
    })
    it('registerApi_invalid_name_1', 0, () => {
      const ret = ServiceApi.registerApi('', '');
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NAME_INVALID);
    })

    it('registerApi_invalid_name_2', 0, () => {
      const ret = ServiceApi.registerApi(' ', '');
      expect(ret).assertEqual(ServiceErrCode.SERVICE_NAME_INVALID);
    })

    it('registerApi_invalid_api_1', 0, () => {
      const ret = ServiceApi.registerApi('Test', '');
      expect(ret).assertEqual(ServiceErrCode.API_NAME_INVALID);
    })

    it('registerApi_invalid_api_2', 0, () => {
      const ret = ServiceApi.registerApi('Test', ' ');
      expect(ret).assertEqual(ServiceErrCode.API_NAME_INVALID);
    })

    it('registerApi', 0, () => {
      const ret = ServiceApi.registerApi('TestService', 'TestApi');
      expect(ret).assertEqual(ServiceErrCode.SUCCESS);
    })

    it('register_duplicate_api', 0, () => {
      let ret = ServiceApi.registerApi('TestService', 'TestApi');
      expect(ret).assertEqual(ServiceErrCode.SUCCESS);
      ret = ServiceApi.registerApi('TestService', 'TestApi');
      expect(ret).assertEqual(ServiceErrCode.API_ALREADY_REGISTERED);
    })
  })
}