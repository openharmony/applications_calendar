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

import HashMap from '@ohos.util.HashMap';
import ArrayList from '@ohos.util.ArrayList';
import { Parameter } from './Parameter';
import { EmptyUtils } from '@app/common';
import { collections } from '@kit.ArkTS';

/**
 * dt start
 */
const DTSTART = "DTSTART";

/**
 * dtend
 */
const DTEND = "DTEND";

/**
 * duratton
 */
const DURATION = "DURATION";

/**
 * rrule
 */
const RRULE = "RRULE";

/*
 * 导入vcs文件 解析生成的属性
 * DTSTART:20231224T100000 这种就是,DTSTART 是name value 是 20231224T100000
 *
 * DESCRIPTION;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=E8=AE=B8=E5=93=88=E5=93=88=E5=93=88
 *
 * 这种就是,DESCRIPTION 是name value 是 =E8=AE=B8=E5=93=88=E5=93=88=E5=93=88
 * CHARSET=UTF-8 是对应的Parameter
 * ENCODING=QUOTED-PRINTABLE 是对应的Parameter
 * ROLE=REQ-PARTICIPANT 和 PARTSTAT=ACCEPTED 是对应的Parameters
 */
@Sendable
export class Property {
  private mParamsMap: collections.Map<string, collections.Array<Parameter>> = new collections.Map();
  private mValue: string = '';
  private mName: string = '';

  /**
   * Creates a new property with the provided name and value.
   *
   * @param name The property's name.
   * @param value The property's value.
   */
  public constructor(name: string, value?: string) {
    this.mName = name;
    if (value) {
      this.mValue = value;
    }
  }


  /**
   * Set the value of this property.
   *
   * @param value The desired value for this property.
   */
  public setValue(value: string) {
    this.mValue = value;
  }

  /**
   * Get the value of this property.
   *
   * @return The value of this property.
   */
  public getValue(): string {
    return this.mValue;
  }

  /**
   * Get the name of the property.
   *
   * @return The name of the property.
   */
  public getName(): string {
    return this.mName;
  }

  /**
   * Adds a {@link Parameter} to this property. If params is null, create new one.
   *
   * @param param The parameter that should be added.
   */
  public addParameter(param: Parameter) {
    let paramLists = this.mParamsMap.get(param.name)
    if (!paramLists) {
      paramLists = new collections.Array();
      this.mParamsMap.set(param.name, paramLists);
    }
    paramLists.push(param);
  }

  /**
   * Returns the list of parameters with the specified name.May return null if there are no such parameters.
   *
   * @param paramName The name of the parameters that should be returned.
   * @return The list of parameters with the specified name.
   */
  public getParameters(paramName: string): collections.Array<Parameter> {
    let expectedList = this.mParamsMap.get(paramName);
    if (expectedList) {
      return expectedList;
    } else {
      return new collections.Array();
    }
  }

  /**
   * Returns the first parameter with the specified name.May return null if there is no such parameter.
   *
   * @param paramName The name of the parameter that should be returned.
   * @return The first parameter with the specified name or null.
   */
  public getFirstParameter(paramName: string): Parameter | undefined {
    const params = this.mParamsMap.get(paramName);
    if (!params || EmptyUtils.isEmptyArray(params)) {
      return undefined;
    }
    return params[0];
  }

  /**
   * Returns the set of parameter names for this property.
   *
   * @return The set of parameter names for this property.
   */
  public getParameterNames(): Set<string> {
    return new Set(this.mParamsMap.keys());
  }

  toString() {
    return `Property mName is ${this.mName} mValue is ${this.mValue} ` + '\r\n' + this.getParametersString();
  }

  getChildParas(arg0: collections.Array<Parameter> | undefined) {
    if (!arg0) {
      return;
    }
    let ParametersString: string = '';
    for (let arg0Element of arg0) {
      ParametersString = ParametersString + arg0Element.toString() + '\r\n ';
    }
    return ParametersString;
  }

  private getParametersString(): string {
    let ParametersString: string = '';
    for (let keysElement of this.mParamsMap.keys()) {
      ParametersString + `Parameter name is ${keysElement} values is ${this.getChildParas(this.mParamsMap.get(keysElement))}`;
    }
    return ParametersString;
  }
}