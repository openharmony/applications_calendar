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
import { DFXContext } from '../DFXContext';

/**
 * 卡片DFX状态机的接口
 */
export interface DFXState {
  handleError(context: DFXContext): void;

  /**
   * 处理交互时间
   * @param context
   */
  handleAction(context: DFXContext): void;

  /**
   * 处理数据刷新
   * @param context
   */
  handleDataRefresh(context: DFXContext): void;

  /**
   * 处理 Normal
   * @param context
   */
  handleNormalEvent(context: DFXContext): void;
}