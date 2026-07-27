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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import Want from '@ohos.app.ability.Want';
import UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { EmptyUtils, GlobalData, Log } from '@app/common';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { Configuration } from '@ohos.app.ability.Configuration';

const TAG = 'CalendarPrivacyAbility';

export const PRIVACY_ABILITY_SESSION = 'PRIVACY_ABILITY_SESSION';

/**
 * privacy management of Ability.
 */
export default class CalendarPrivacyAbility extends UIExtensionAbility {
  private storage: LocalStorage = new LocalStorage();
  private session: UIExtensionContentSession | undefined = undefined;
  private currentColorMode: ConfigurationConstant.ColorMode | undefined = undefined;
  /* instrument ignore file */
  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    // Main window is created, set main page for this ability
    Log.info(TAG, 'CalendarPrivacyAbility onSessionCreate.');
    this.storage.setOrCreate<UIExtensionContentSession>(PRIVACY_ABILITY_SESSION, session);
    this.session = session;
    GlobalData.instance().init();
    this.currentColorMode = this.context.config.colorMode;
    this.setColorMode();
    this.session?.loadContent('pages/CalendarPrivacyPage', this.storage);
  }

  private setColorMode(): void {
    if (EmptyUtils.isUndefinedOrNull(this.currentColorMode)) {
      Log.warn(TAG, `setColorMode currentColorMode isUndefinedOrNull`);
      return;
    }
    AppStorage.setOrCreate<ConfigurationConstant.ColorMode>('paf.currentColorMode', this.currentColorMode);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    if (newConfig.colorMode === this.currentColorMode) {
      return;
    }
    this.currentColorMode = newConfig.colorMode;
    this.setColorMode();
  }

  onDestroy(): void {
    Log.info(TAG, 'onDestroy');
    this.storage.clear();
    this.session = undefined;
  }
}