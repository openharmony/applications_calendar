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
import { DividerLine } from '../../CreateAgenda/view/DividerLine';
import {
  AccountUtils,
  AgendaDeleteService,
  AgendaEventInfo,
  behaviorEvents,
  BigFontSize,
  CalendarContract,
  CalendarService,
  CardService,
  CommonInnerEvent,
  CommonService,
  DialogControllerOptions,
  EventService,
  FontSizeScaleUtils,
  GlobalThis,
  HolidayUtil,
  Log,
  ServiceEnum,
  ServiceManager
} from '@app/common';
import { FromType, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { AgendaOperateHelper } from '../../helpers/AgendaOperateHelper';
import { HashMap } from '@kit.ArkTS';
import { AddFormMenuItem, prompt, window } from '@kit.ArkUI';
import { formBindingData } from '@kit.FormKit';
import { EventMode, ImportantCardConfig } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { FormConfigManager } from '@app/common/src/main/ets/card/FormConfigManager';
import { common } from '@kit.AbilityKit';
import { AgendaEditMenuOpt } from '../../AgendaDetail/view/AgendaMenu';
import emitter from '@ohos.events.emitter';

const TAG = 'PreviewMenu';

// 长按预览菜单选项
enum PreviewMenuType {
  MULTIPLE_SELECT = 0,
  SHARE = 1,
  DELETE = 2
}


/**
 *长按预览视图组件
 */
@Component
export struct PreviewMenu {
  @Prop info: AgendaEventInfo;

  // 弹窗控制选择器选项
  @StorageLink('dialogControllerOptions') dialogControllerOptions: DialogControllerOptions = {};

  // WeLink日程定制，屏蔽分享按钮
  @State isWeLinkAgenda: boolean = false;

  private showMultiSelect: boolean = false;

  private fromType: number = FromType.UNKNOWN;

  // 分享的viewId
  private shareAnchorViewId: string = '';

  // 根据instance实例查询的event记录
  private eventInfo: AgendaEventInfo = new AgendaEventInfo();

  private mAgendaOperateHelper: AgendaOperateHelper = new AgendaOperateHelper();

  @Prop compId: string = '';

  private menuEditOpts: Array<AgendaEditMenuOpt> = [];

  @StorageLink('windowStage') windowStage: window.WindowStage | undefined = undefined;

  editMenuText: Array<ResourceStr> = [
    $r('app.string.all_agendas'),
    $r('app.string.this_agenda'),
    $r('app.string.this_and_future_agenda'),
  ];

  // 卡片加桌时延
  private addToHomeDelayTime: number = 1200;

  // 当前只实现2x2的重要日卡片加桌 编辑卡片时的规格需和加桌的规格保持一致，所以这里需要把formName进行赋值
  private defaultFormName: string = 'ImportantCardView2x2';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  showDeleteDialog() {
    ServiceManager.getInstance()
      .getDynamicService<AgendaDeleteService>(ServiceEnum.AGENDA_DELETE_SERVICE).then((service) => {
      service?.notifyDeleteEvent(this.info?.mId, this.info?.mBegin, true);
    });
  }

  aboutToAppear(): void {
    this.identityWeLinkAgenda();
    this.initShareAnchorViewId();
    this.putEditMenuOpt();
  }

  async putEditMenuOpt() {
    this.eventInfo = await EventService.INSTANCE.queryEventById(this.info.mId);
    // 清空数组，避免多次put
    this.menuEditOpts = [];
    this.menuEditOpts.push(AgendaEditMenuOpt.ONLY_THIS_AGENDA);
    // 重复日程的第一条不需要显示“此日程和将来的日程”
    if (!(this.info.isRepeatEvent() && this.info.mBegin === this.eventInfo.mBegin)) {
      this.menuEditOpts.push(AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA);
    }
    this.menuEditOpts.push(AgendaEditMenuOpt.ALL_AGENDA);
  }

  aboutToDisappear(): void {
  }

  build() {
    Menu() {
      if (!this.info.isHoliday()) {
        MenuItem({ content: $r('app.string.copy') })
          .onClick(() => {
            emitter.emit({ eventId: CommonInnerEvent.COPY_AGENDA }, { data: { 'eventId': this.info?.mId } });
          })
        DividerLine()
          .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
          .visibility(this.info.isContactBirthday()  ? Visibility.None : Visibility.Visible)
      }
      MenuItem({ content: $r('app.string.agenda_menu_item_share') })
        .onClick(() => {
          let params: ReportHiEventParams = {
            TYPE: PreviewMenuType.SHARE
          };
          ReportUtil.reportBehaviorEvent(behaviorEvents.previewMenuType, params);
          this.onShareClick();
        })
      DividerLine()
        .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
        .visibility(this.info.isContactBirthday() ? Visibility.None : Visibility.Visible)
      if (this.showMultiSelect) {
        MenuItem({ content: $r('app.string.multiple_choice') })
          .onClick(() => {
            this.onMultiSelectClick();
          })
        DividerLine()
          .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
          .visibility(this.info.isContactBirthday() ? Visibility.None : Visibility.Visible)
      }
      // 屏蔽非重要日长按加桌按钮
      if (this.info.mImportantEventType !== CalendarContract.EventImportantType.NORMAL &&
        this.info.mImportantEventType !== CalendarContract.EventImportantType.HOLIDAY) {
        // 添加卡片到桌面
        AddFormMenuItem({
          bundleName: 'com.ohos.calendar', // 包名
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
                Log.info(TAG, ` callback info：error = ${error?.code} message = ${error?.message}, formId = ${formId}`);
                return;
              }
              let formConfig: ImportantCardConfig = FormConfigManager.getImportantCardConfig(formId, true);
              ImportantCardConfig.setFixedEventIds(formConfig, [this.info.mId]);
              if (this.info.isImportantEvent()) {
                formConfig.eventMode = EventMode.FIXED_IMPORTANT;
              } else if (this.info.isHoliday()) {
                if (await HolidayUtil.isRecentChineseHoliday(this.info.mId)) {
                  formConfig.eventMode = EventMode.RECENT_HOLIDAY;
                } else {
                  formConfig.eventMode = EventMode.FIXED_HOLIDAY;
                }
              }
              formConfig.formName = this.defaultFormName;
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
              if (!this.windowStage) {
                const context = getContext(this) as common.UIAbilityContext
                setTimeout(() => {
                  context.terminateSelf()
                }, this.addToHomeDelayTime)
              } else {
                const windowClass:window.Window = this.windowStage?.getMainWindowSync()
                setTimeout(() => {
                  windowClass.minimize()
                }, 100)
              }
            },
            style: {
              options: {content: $r('app.string.add_important_day_fa_to_desktop_title')}
            }
          })
        DividerLine()
          .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
          .visibility(AccountUtils.isBirthDayAccountById(this.info.mCalendarId) ? Visibility.None : Visibility.Visible)
      }
      if (!this.info.isHoliday()) {
        // 重复日程编辑选项需要展示展开选项
        if (this.info.isRepeatEvent() && !this.info.isImportantEvent()) {
          MenuItem({
            content: $r('app.string.edit_label'),
            builder: (): void => this.SubEditMenu()
          })
        } else {
          MenuItem({ content: $r('app.string.edit_label') })
            .onClick(() => {
              const timer = setTimeout(() => {
                this.mAgendaOperateHelper.editAgenda(this.eventInfo);
                clearTimeout(timer);
              }, 300)
            })
        }
        DividerLine()
          .padding({ left: $r('sys.float.padding_level6'), right: $r('sys.float.padding_level6') })
          .visibility(this.info.isContactBirthday() ? Visibility.None : Visibility.Visible)
      }
      MenuItem({ content: $r('app.string.agenda_menu_item_delete') })
        .onClick(() => {
          let params: ReportHiEventParams = {
            TYPE: PreviewMenuType.DELETE
          };
          ReportUtil.reportBehaviorEvent(behaviorEvents.previewMenuType, params);
          const timer = setTimeout(() => {
            this.showDeleteDialog();
            clearTimeout(timer);
          }, 300) // 增加延时，等待预览弹窗收起动画播放完成后再执行操作，避免动效冲突
        })
        .visibility(AccountUtils.isBirthDayAccountById(this.info.mCalendarId) ? Visibility.None : Visibility.Visible)
    }
    .width(224)
    .font({
      weight: FontWeight.Medium,
      size: FontSizeScaleUtils.getLimitFontSizeVp(
        this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE_2X,
        16)
    })
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
  }

  @Builder
  SubEditMenu() {
    Menu() {
      ForEach(this.menuEditOpts, (opt: AgendaEditMenuOpt) => {
        DividerLine()
          .visibility(opt === AgendaEditMenuOpt.ONLY_THIS_AGENDA ? Visibility.Visible: Visibility.None);
        MenuItem({ content: this.editMenuText[opt] })
          .onClick(() => {
            const timer = setTimeout(async () => {
              this.onEditHandle(opt);
              clearTimeout(timer);
            }, 300)
          })
        DividerLine()
          .padding({ left: $r('sys.float.padding_level4'), right: $r('sys.float.padding_level4') })
          .visibility(opt === AgendaEditMenuOpt.ALL_AGENDA ? Visibility.None : Visibility.Visible);
      })
    }
    .width(224)
  }

  async onEditHandle(opt: AgendaEditMenuOpt) {
    const instanceStartMills = this.info.mBegin;
    const instanceEndMills = this.info.mEnd;
    switch (opt) {
      case AgendaEditMenuOpt.ALL_AGENDA: {
        this.mAgendaOperateHelper.editAgenda(this.eventInfo);
        break;
      }
      case AgendaEditMenuOpt.ONLY_THIS_AGENDA: {
        this.mAgendaOperateHelper.editThisAgenda(this.info, instanceStartMills, instanceEndMills);
        break;
      }
      case AgendaEditMenuOpt.THIS_AND_FEATURE_AGENDA: {
        this.mAgendaOperateHelper.editThisAgendaAndBeyond(this.info, instanceStartMills, instanceEndMills);
        break;
      }
    }
  }

  private onDeleteSuccess: () => void = (): void => {
  };

  private onMultiSelectClick: () => void = (): void => {
  };

  private onShareClick() {
    this.mAgendaOperateHelper.shareAgenda(this.info, this.fromType, this.shareAnchorViewId);
  }

  /**
   * 根据帐户 ID 获取帐户信息，识别是否是WeLink日程
   *
   */
  private async identityWeLinkAgenda() {
    let accounts: CalendarContract.Accounts[] =
      await CalendarService.INSTANCE.queryCalendarList() as CalendarContract.Accounts[];
    const accountMap: HashMap<number, CalendarContract.Accounts> = CommonService.INSTANCE.getAccountMap(accounts);
    const accountDisplayName = accountMap.get(this.info.mCalendarId)?.calendarDisplayName;
    this.isWeLinkAgenda = (accountDisplayName.length !== 0) && accountDisplayName.startsWith('WeLink', 0);
  }

  private initShareAnchorViewId() {
    if (this.shareAnchorViewId !== '') {
      return;
    }
    this.shareAnchorViewId = this.info.getEditAblePropStr();
  }
}