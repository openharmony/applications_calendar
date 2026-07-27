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

export namespace Geometry {
  // 位置
  export interface GPosition {
    x: number;
    y: number;
  }

  // 尺寸
  export interface GSize {
    width: number;
    height: number;
  }

  // 矩形区域
  export interface GRect {
    position: GPosition;
    size: GSize;
  }

  /**
   * 判断点(position)是否在矩形(rect)内
   *
   * @param rect
   * @param position
   *
   * @returns boolean 点是否在矩形内
   */
  export function isPositionInRect(rect: GRect, position: GPosition): boolean {
    const x1 = rect.position.x;
    const y1 = rect.position.y;
    const width = rect.size.width;
    const height = rect.size.height;
    const x2 = position.x;
    const y2 = position.y;

    return x2 >= x1 && x2 <= x1 + width && y2 >= y1 && y2 <= y1 + height;
  }

  /**
   * 判断两个矩形是否相交
   *
   * @param rect1
   * @param rect2
   *
   * @returns boolean 是否相交
   */
  export function rectIntersect(rect1: GRect, rect2: GRect): boolean {
    const x1 = rect1.position.x;
    const y1 = rect1.position.y;
    const w1 = rect1.size.width;
    const h1 = rect1.size.height;

    const x2 = rect2.position.x;
    const y2 = rect2.position.y;
    const w2 = rect2.size.width;
    const h2 = rect2.size.height;
    const cp1: GPosition = { x: x1 + w1 / 2, y: y1 + h1 / 2 }; // 矩形1的中心点
    const cp2: GPosition = { x: x2 + w2 / 2, y: y2 + h2 / 2 }; // 矩形2的中心点

    return Math.abs(cp1.x - cp2.x) < ((w1 + w2) / 2) && Math.abs(cp1.y - cp2.y) < ((h1 + h2) / 2);
  }
}