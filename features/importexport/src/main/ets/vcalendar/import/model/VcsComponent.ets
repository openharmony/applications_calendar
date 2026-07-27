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

import { Property } from './Property';
import { EmptyUtils, Log } from '@app/common';
import { collections } from '@kit.ArkTS';

/**
 * v calendar
 */
export const VCALENDAR = "VCALENDAR";

/**
 * vevent
 */
export const VEVENT = "VEVENT";

/**
 * vtodo
 */
export const VTODO = "VTODO";

/**
 * vjournal
 */
export const VJOURNAL = "VJOURNAL";

/**
 * v freebusy
 */
export const VFREEBUSY = "VFREEBUSY";

/**
 * v timezone
 */
export const VTIMEZONE = "VTIMEZONE";

/**
 * v alarm
 */
export const VALARM = "VALARM";

// components
export const BEGIN = "BEGIN";

export const END = "END";

const LINE_FEED = "\n";
const NEWLINE = LINE_FEED;

// 共享模块
'use shared'

/*
 * 导入的vcs文件解析的组件
 * A component within an iCalendar (VEVENT, VTODO, VJOURNAL, VFEEBUSY,VTIMEZONE, VALARM).
 */
@Sendable
export class VcsComponent {
  private tag: string = 'Component';
  private mName: string = '';
  // mParent 为 undefined 代表这个是顶级组件
  private mParent: VcsComponent | undefined; // see if we can get rid of this
  private mChildren: collections.Array<VcsComponent> = new collections.Array();
  private mPropsMap: collections.Map<string, collections.Array<Property>> =
    new collections.Map<string, collections.Array<Property>>();

  /**
   * Creates a new component with the provided name.
   *
   * @param name The name of the component.
   */
  public constructor(name: string, parent: VcsComponent | undefined) {
    this.mName = name;
    this.mParent = parent;
  }

  /**
   * Returns the name of the component.
   *
   * @return The name of the component.
   */
  public getName(): string {
    return this.mName;
  }

  public setParent(parent: VcsComponent | undefined) {
    this.mParent = parent;
  }

  /**
   * Returns the parent of this component.
   *
   * @return The parent of this component.
   */
  public getParent(): VcsComponent | undefined {
    return this.mParent;
  }


  /**
   * Adds a child component to this component.
   *
   * @param child The child component.
   */
  public addChild(child: VcsComponent) {
    this.mChildren.push(child);
  }

  /**
   * Returns a list of the Component children of this component.  May be
   * null, if there are no children.
   *
   * @return A list of the children.
   */
  public getComponents() {
    return this.mChildren;
  }

  public addProperty(property: Property) {
    const name: string = property.getName();
    let list = this.mPropsMap.get(name);
    if (!list) {
      list = new collections.Array<Property>();
      this.mPropsMap.set(name, list);
    }
    list.push(property)
  }

  /**
   * Returns a set of the property names within this component.
   *
   * @return A set of property names within this component.
   */
  public getPropertyNames(): Set<string> {
    return new Set(this.mPropsMap.keys());
  }

  /**
   * Returns a list of properties with the specified name.  Returns null
   * if there are no such properties.
   *
   * @param name The name of the property that should be returned.
   * @return A list of properties with the requested name.
   */
  public getProperties(name: string) {
    return this.mPropsMap.get(name);
  }


  public getAllProperties() {
    const allProperties: Array<Property> = new Array<Property>();
    if (EmptyUtils.isEmptyArray(this.mPropsMap)) {
      Log.warn(this.tag, `getAllProperties mPropsMap is  empty`);
      return allProperties;
    }
    for (let propertyName of this.getPropertyNames()) {
      let properties = this.mPropsMap.get(propertyName);
      if (!properties || EmptyUtils.isEmptyArray(properties)) {
        Log.warn(this.tag, `getAllProperties propertyName is ${propertyName} properties is empty`);
        properties = new collections.Array();
      }
      allProperties.push(...properties);
    }
    return allProperties;
  }

  /**
   * Returns the first property with the specified name. Returns null
   * if there is no such property.
   *
   * @param name The name of the property that should be returned.
   * @return The first property with the specified name.
   */
  public getFirstProperty(name: string): Property | undefined {
    const props = this.mPropsMap.get(name);
    if (!props || EmptyUtils.isEmptyArray(props)) {
      Log.warn(this.tag, `getFirstProperty name is ${name} property is null`);
      return;
    }
    return props[0];
  }

  public getChildComponentByName(name: string): VcsComponent | undefined {
    for (let mChildrenElement of this.mChildren) {
      if (mChildrenElement.mName === name) {
        return mChildrenElement;
      }
    }
    return undefined;
  }

  public isEventComponent(): boolean {
    return this.mName === VEVENT;
  }

  public isCalendarComponent(): boolean {
    return this.mName === VCALENDAR;
  }
}
