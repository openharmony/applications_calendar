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
import { CalendarContract, CardService, GlobalThis, HolidayUtil, Log, ServiceEnum, ServiceManager } from '@app/common';
import { AgendaEventInfo } from '@app/common/src/main/ets/agenda/AgendaEventInfo';
import { FormConfigManager } from '@app/common/src/main/ets/card/FormConfigManager';
import { EventMode, ImportantCardConfig } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { DeviceConfig } from '@app/common/src/main/ets/data/DeviceConfig';
import { DialogControllerOptions } from '@app/common/src/main/ets/default/common/declare';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import lazy { AddFormMenuItem, prompt, window } from '@kit.ArkUI';
import { formBindingData } from '@kit.FormKit';
import { common } from '@kit.AbilityKit';

export enum AgendaMenuOpt {
  VIEW, // 查看
  COPY, // 复制
  SHARE, // 分享
  PASTE, // 粘贴
  EDIT, // 编辑
  DELETE, // 删除
  CREATE, // 创建
  MULTISELECT, // 多选
}

export const DEFAULT_AGENDA_MENU_OPTS: AgendaMenuOpt[] = [
  AgendaMenuOpt.VIEW,
  AgendaMenuOpt.COPY,
  AgendaMenuOpt.SHARE,
  AgendaMenuOpt.PASTE,
  AgendaMenuOpt.EDIT,
  AgendaMenuOpt.DELETE,
  AgendaMenuOpt.CREATE,
  AgendaMenuOpt.MULTISELECT
];

export enum AgendaEditMenuOpt {
  ALL_AGENDA, // 编辑非重复日程或者所有重复日程
  ONLY_THIS_AGENDA, // 编辑单个重复日程
  THIS_AND_FEATURE_AGENDA, // 编辑单个重复日程及以后的日程
}

const TAG = 'AgendaMenu';

// 日程菜单归一组件，用于如右键弹出的菜单场景
@Component
export struct AgendaMenu {
  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  @StorageLink('windowStage') windowStage: window.WindowStage | undefined = undefined;

  // 日程信息 单个日程或者日程数组
  info: AgendaEventInfo | undefined = undefined;

  // 是否手机端
  isSmallWindow: boolean = false;

  // 弹窗当前指向的时间戳
  date: number = 0;

  @Prop compId: string = '';

  // 菜单选项
  menuOpts: Array<AgendaMenuOpt> = DEFAULT_AGENDA_MENU_OPTS;

  // 编辑菜单选项
  menuEditOpts: Array<AgendaEditMenuOpt> = [];

  //是否需要保留传入时分
  needSaveTime: number = 0;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  // 当前只实现2x2的重要日卡片加桌 编辑卡片时的规格需和加桌的规格保持一致，所以这里需要把formName进行赋值
  private defaultFormName: string = 'ImportantCardView2x2';

  private arrowIconModifier: SymbolGlyphModifier =
    new SymbolGlyphModifier($r('sys.symbol.chevron_right')).fontColor([$r('sys.color.font_primary')]);

  menuText: Array<ResourceStr> = [
    $r('app.string.agenda_menu_item_view'),
    $r('app.string.copy'),
    $r('app.string.agenda_menu_item_share'),
    $r('app.string.paste'),
    $r('app.string.agenda_menu_item_edit'),
    $r('app.string.agenda_menu_item_delete'),
    $r('app.string.agenda_menu_item_create'),
    $r('app.string.multiple_choice'),
  ];

  editMenuText: Array<ResourceStr> = [
    $r('app.string.all_agendas'),
    $r('app.string.only_this_agenda'),
    $r('app.string.this_and_future_agenda'),
  ];

  onViewHandle: () => void = (): void => {
  };

  onCopyHandle: () => void = (): void => {
  };

  onShareHandle: () => void = (): void => {
  };

  onPasteHandle: () => void = (): void => {
  };

  onEditHandle: (editType: number) => void = (editType: number = 0): void => {
  };

  onDeleteHandle: () => void = (): void => {
  };

  onCreateHandle: () => void = (): void => {
  };

  onMultiselectHandle: () => void = (): void => {
  };

  // 菜单选择回调
  onMenuChosen: (op: AgendaMenuOpt, id: number) => void = (op: AgendaMenuOpt, id: number) => {
  };

  handler: Array<() => void> = [
    () => {
    // 查看
      this.onViewHandle();
    },
    () => {
    // 复制
      this.onCopyHandle();
    },
    () => {
    // 分享
      this.onShareHandle();
    },
    () => {
    // 粘贴
      this.onPasteHandle();
    },
    (editType: number = 0) => {
    // 编辑
      this.onEditHandle(editType);
    },
    () => {
    // 删除
      this.onDeleteHandle();
    },
    () => {
    // 创建
      this.onCreateHandle();
    },
    () => {
      // 多选
      this.onMultiselectHandle();
    }
  ];

  aboutToAppear() {

  }

  aboutToDisappear(): void {

  }

  @Builder
  buildEditRepeatMenu() {
    Menu() {
      ForEach(this.menuEditOpts, (opt: AgendaEditMenuOpt) => {
        MenuItem({ content: this.editMenuText[opt] })
          .onClick(() => {
            this.onEditHandle(opt);
          })
      })
    }
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
  }

  build() {
    Menu() {
      ForEach(this.menuOpts, (opt: AgendaMenuOpt) => {
        if (opt !== AgendaMenuOpt.CREATE) {
          if (opt === AgendaMenuOpt.EDIT && this.menuEditOpts.length !== 0) {
            MenuItem({
              content: this.menuText[opt],
              builder: this.buildEditRepeatMenu(),
              symbolEndIcon: this.arrowIconModifier
            })
          } else {
            MenuItem({ content: this.menuText[opt] })
              .onClick(() => {
                this.handler[opt]();
              })
          }
        } else {
          MenuItemGroup() {
            MenuItem({ content: this.menuText[opt] })
              .onClick(() => {
                this.handler[opt]();
              })
          }
        }
      })
      this.buildAddToHome();
    }
    .font({ size: $r('sys.float.Body_L'), weight: FontWeight.Regular })
    .fontColor($r('sys.color.font_primary'))
    .width(224)
  }

  @Builder
  buildAddToHome() {
    if (this.info && this.info.mImportantEventType !== CalendarContract.EventImportantType.NORMAL &&
      this.info.mImportantEventType !== CalendarContract.EventImportantType.HOLIDAY) {
      // 添加卡片到桌面
      AddFormMenuItem({
        bundleName: 'com.openharmony.calendar', // 包名
        abilityName: 'AllFormAbility', // 模块ability名称
        parameters: {
          'ohos.extra.param.key.form_dimension': 2,
          'ohos.extra.param.key.form_name': 'ImportantCard2x2',
          'ohos.extra.param.key.module_name': 'phone',
        },
      },
        this.compId,
        {
          formBindingData: formBindingData.createFormBindingData({}),
          callback: async (error, formId) => {
            if (error?.code !== 0) {
              prompt.showToast({
                message: GlobalThis.getResourceStr($r('app.string.add_fa_card_failed'))
              })
              Log.error(TAG, ` callback info：error = ${error?.code} message = ${error?.message}, formId = ${formId}`);
              return;
            }
            this.processAddToHome(formId);
          },
          style: {
            options: { content: $r('app.string.add_important_day_fa_to_desktop_title') }
          }
        })
    }
  }

  private async processAddToHome(formId: string) {
    Log.info(TAG, 'processAddToHome formId : ' + formId);
    if (!this.info || this.info === undefined) {
      Log.error(TAG, ' info is undefined or null formId : ' + formId);
      return;
    }
    let formConfig: ImportantCardConfig = FormConfigManager.getImportantCardConfig(formId, true);
    ImportantCardConfig.setFixedEventIds(formConfig, [this.info.mId]);
    if (this.info.isImportantEvent()) {
      formConfig.eventMode = EventMode.FIXED_IMPORTANT;
    } else if (this.info.isHoliday()) {
      const isRecentChineseHoliday = await HolidayUtil.isRecentChineseHoliday(this.info.mId)
      if (isRecentChineseHoliday) {
        formConfig.eventMode = EventMode.RECENT_HOLIDAY;
      } else {
        formConfig.eventMode = EventMode.FIXED_HOLIDAY;
      }
    }
    formConfig.formName = this.defaultFormName;
    try {
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      let context = GlobalThis.getInstance().getFromContext();
      if (context !== null) {
        const cardService = await ServiceManager.getInstance()
          .getDynamicService<CardService>(ServiceEnum.CARD_SERVICE);
        if (cardService) {
          cardService.refreshImportantCard(context, formId, true, formConfig);
        }
      }
      Log.info(TAG, ` formId: ${formId}. add success. mId= ${this.info.mId}`)
      prompt.showToast({
        message: GlobalThis.getResourceStr($r('app.string.add_fa_card_success'))
      })
      const addToHomeDelayTime: number = 1200;
      if (!this.windowStage) {
        const context = getContext(this) as common.UIAbilityContext
        setTimeout(() => {
          context.terminateSelf()
        }, addToHomeDelayTime)
      } else {
        const windowClass: window.Window = this.windowStage?.getMainWindowSync()
        setTimeout(() => {
          windowClass.minimize()
        }, 100)
      }
    } catch (err) {
      Log.error(TAG, ' err by processAddToHome  err : ' + err);
    }
  }

}


export function generateAgendaEditOption(event: AgendaEventInfo | undefined): AgendaEditMenuOpt[] {
  if (!event) {
    return [];
  }
  if (!event.isRepeatEvent() || event.isImportantEvent()) {
    return [];
  }
  let menuOpt: AgendaEditMenuOpt[] = [];

  menuOpt.push(AgendaEditMenuOpt.ALL_AGENDA);
  menuOpt.push(AgendaEditMenuOpt.ONLY_THIS_AGENDA);
  if (!event.isFirstRepeatAgenda()) {
    menuOpt.push(AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA);
  }
  return menuOpt;
}