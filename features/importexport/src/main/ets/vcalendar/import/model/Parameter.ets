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

/*
 * 导入vcs文件 解析生成的参数
 */
@Sendable
export class Parameter {
  /**
   * name
   */
  public name: string = '';
  /**
   * value
   */
  public value: string = '';

  /**
   * Creates a new parameter with the specified name and value.
   *
   * @param name The name of the parameter.
   * @param value The value of the parameter.
   */
  public constructor(name?: string, value?: string) {
    this.name = name ? name : '';
    this.value = value ? value : '';
  }

  toString() {
    return `mName is ${this.name} mValue is ${this.value}`;
  }
}

