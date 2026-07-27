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

import {
  BigFontSize, CalendarContract,
  DeviceConfig,
  deviceType
} from '@app/common';
import { AccountRadioListDialog, AccountRadioListDialogOption} from '@app/common.components';
/**
 * 帐户弹窗
 */
@CustomDialog
export struct AccountDialog {
  // 选中的帐户 ID
  @Link checkedAccId: number;

  // 设备类型
  @StorageLink('deviceType') deviceType: number = deviceType.PHONE;

  // 帐户列表
  private accountList: CalendarContract.Accounts[] = [];

  // 弹窗控制器
  private controller: CustomDialogController = new CustomDialogController({ builder: null });

  // 单选框的所属群组名称
  private readonly RADIO_GROUP = 'AccountDialog';

  // 最大弹框高度 PHONE
  private maxPhoneHeight: number = 592;

  // 最大弹框高度 PC
  private maxPcHeight: number = 640;

  // 单个帐户元素高度
  private itemHeight: number = 48;

  private titleHeight: number = 56;

  private listMarginBottom: number = 8;

  private buttonHeight: number = 40;

  private buttonMarginBottom = $r('sys.float.ohos_id_dialog_button_padding_bottom');

  private strokeWidth: number = px2vp(1.5);

  // 弹窗其他信息高度
  private otherElementHeight: number = this.titleHeight + this.listMarginBottom +
  this.buttonHeight + getContext(this).resourceManager.getNumber(this.buttonMarginBottom);

  // 弹窗大小
  private dialogSize: ConstraintSizeOptions = {
    minWidth: 300,
    maxWidth: 400,
    maxHeight: -1,
  };

  // 帐户选项
  private accountOptions: AccountRadioListDialogOption[] = [];

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  @StorageLink('fontSizeScale') @Watch('onFontSizeScale')fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 大字体下单个帐户元素高度
  private bigSizeItemHeight: number = this.titleHeight + this.listMarginBottom

  aboutToAppear() {
    this.getAccountOptions();
    this.calculateDialogMaxHeight()
  }

  onFontSizeScale() {
    this.calculateDialogMaxHeight()
  }
  /**
   * 关闭弹窗
   */
  cancelDialog() {
    if (this.controller) {
      this.controller.close();
    }
  }

  /**
   * 获取弹窗选项信息
   */
  getAccountOptions() {
    this.accountList.forEach((account: CalendarContract.Accounts) => {
      this.accountOptions.push({
        color: account.calendarColor,
        label: account.calendarDisplayName,
        value: account.id
      })
    });
  }

  /**
   * 计算弹窗的最大高度
   */
  calculateDialogMaxHeight() {
    let height = this.accountOptions.length * this.itemHeight + this.otherElementHeight +
      ((this.accountOptions.length - 1) > 0 ? this.accountOptions.length - 1 : 0) * this.strokeWidth;
    if (this.accountOptions.length === 1 && 
    this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SPECIAL) { //单个账户大四档及以上倍数时弹窗高度
      height = this.accountOptions.length * this.itemHeight * this.fontSizeScale +
        (this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_SCALE_2X ? this.bigSizeItemHeight : this.otherElementHeight);
    }
    if (this.deviceType == deviceType.PHONE) {
      this.dialogSize.maxHeight = Math.min(
        this.maxPhoneHeight,
        height
      ) + 8; // ux规范要求按钮与选项距离增加8，顾整体弹窗高度增加8，避免内容隔断
    } else {
      this.dialogSize.maxHeight = Math.min(
        this.maxPcHeight,
        height
      ) + 8;
    }
  }

  build() {
    Column() {
      AccountRadioListDialog({
        title: $r('app.string.calendar'),
        options: this.accountOptions,
        radioGroup: this.RADIO_GROUP,
        cancel: (): void => this.cancelDialog(),
        checkValue: $checkedAccId,
        titleHeight: this.titleHeight,
        listMarginBottom: this.listMarginBottom,
        buttonHeight: this.buttonHeight,
        buttonMarginBottom: this.buttonMarginBottom,
        onChange: (value: number) => {
          this.changeCheckedAccValue(value);
        }
      })
    }
    .margin({ left: 16, right: 16 })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg'))
    .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level8') : $r('sys.float.corner_radius_level16'))
    .height('90%')
    .constraintSize(this.dialogSize)
  }

  // 子组件向父组件传值
  private changeCheckedAccValue: (value: number) => void = (value: number): void => {
  };
}