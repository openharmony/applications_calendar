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
  BigFontSize,
  CalendarDate,
  CommonInnerEvent,
  CompId,
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalThis,
  Log,
  NavPageBuilderFactory,
  NavPathManager,
  NavPathName,
  RouterName,
  ViewProxy
} from '@app/common';
import { RepeatTypeCollapse } from './RepeatTypeCollapse';
import { Recurrence, Frequency, CustomTime} from '@app/feature.repeatrule';
import { Callback } from '@ohos.base';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';

const TAG: string = 'CustomRepeatSetPage';

export interface customPageNavParam {
  inPopUp: boolean;
  recurrenceString: string;
  routerName?: string;
};

@Builder
function harBuilder(navParams: object) {
  CustomRepeatSetPage({
    navParams: navParams
  });
}

const builderName = NavPathName.CUSTOM_REPEAT;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

/**
 * 自定义重复半模态页面
 *
 * @since 2024-02-20
 */
@Component
export struct CustomRepeatSetPage {
  @LocalStorageLink('windowHeight') windowHeight: number = 0;

  @State maxPopContentHeight: number = 504;

  // 日程原始Recurrence数据，外部传入，保存前不修改它，点保存按钮后将暂存数据拷贝到此数据中
  @State eventRecurrence: Recurrence = new Recurrence();

  @StorageLink('initSelectedStartDate') initSelectedStartDate: CalendarDate = new CalendarDate();

  // 日程开始时间类
  @Provide initCustomTime: CustomTime = new CustomTime();

  // 绑定bindSheet控制半模态是否显示的变量，因为需要在左上角点×时主动隐藏半模态窗口
  @State isShowing: boolean = true;

  // 自定义重复界面的暂存数据，保存后才刷新到外面的Recurrence，另外根据recurrence和originalRecurrence对比，刷新右上角保存按钮状态
  @Provide @Watch('updateSaveButtonStates') tempRecurrence: Recurrence = new Recurrence();

  // 此state变量，用于控制右上角保存按钮状态
  @State saveButtonEnable: boolean = false;

  // 性能打点，日志打印
  private reportProxy: ViewProxy = new ViewProxy(TAG);

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private inPopUp: boolean = true;

  // 滑动 scroller
  private scroller: Scroller = new Scroller();

  private navParams: object = JSON.parse('{}');

  private customRepeatPopContentHeight: boolean = DeviceConfig.instance().config.customRepeatPopContentHeight;

  private routerName: string = RouterName.CREATE_AGENDA_MAIN;

  // 点击保存后，回调到外面的组件，以便外面做数据处理
  saveCallback: Callback<void> = () => {
  };

  initMaxPopContentHeight() {
    // 窗口高度630，刚好展示完全
    const limitWindowHeight = 630;
    if (this.windowHeight < limitWindowHeight) {
      const diff = limitWindowHeight - this.windowHeight;
      Log.info(TAG, `initMaxPopContentHeight ${diff}`);
      this.maxPopContentHeight -= diff;
    }
  }

  aboutToAppear() {
    const params = this.navParams as customPageNavParam;

    Log.info(TAG, `navParams ${params.inPopUp}`);

    if (params.recurrenceString.length > 0) {
      this.eventRecurrence = Recurrence.parse(params.recurrenceString);
    }

    if (params.routerName) {
      this.routerName = params.routerName;
    }

    this.initCustomTime.setTime(this.initSelectedStartDate.getTime());

    this.reportProxy.aboutToAppear();

    this.tempRecurrence.deepCopyFrom(this.eventRecurrence);

    if (this.tempRecurrence.freq === Frequency.NONE) {
      this.tempRecurrence.freq = Frequency.WEEKLY;
      this.tempRecurrence.byWeekDay = [this.initCustomTime.getDayOfWeek()];
    }
    if (this.tempRecurrence.interval < 1) {
      this.tempRecurrence.interval = 1;
    }
    this.updateSaveButtonStates();

    this.initMaxPopContentHeight();
  }

  @Builder
  customTitle() {
    Row() {
      this.builderBackPress();
      Text($r('app.string.custom_repeat'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD,
          px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
        ))
        .constraintSize({ maxWidth: '70%' })
        .minFontSize(8)
        .fontWeight(FontWeight.Bold)
        .margin({ start: LengthMetrics.resource($r('sys.float.padding_level4')) })
        .id(CompId.CUSTOM_REPEAT)
      Blank()
      this.builderConfirm()
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ top: 8 })
    .alignItems(VerticalAlign.Center)
  }

  build() {
    NavDestination() {
      this.buildContent();
    }
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .hideTitleBar(false)
    .hideBackButton(true)
    .title(this.inPopUp ? this.customTitle : this.NaviTitle)
  }

  aboutToDisappear() {
    this.reportProxy.aboutToDisappear();
  }

  @Builder
  buildContent() {
    Column() {
      List({ scroller: this.scroller }) {
        ListItem() {
          RepeatTypeCollapse();
        }
        .id(CompId.REPEATING_SCHEDULE_EXPAND_COLLAPSE)
        .borderRadius(this.needCommerce ? $r('sys.float.corner_radius_level4') : $r('sys.float.corner_radius_level8'))
        .backgroundColor($r('sys.color.comp_background_list_card'))
      }
      .scrollBar(BarState.Off)
      .margin({
        top: $r('sys.float.padding_level4'),
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8')
      })
      .width('calc(100% - 32vp)')
      .backgroundColor(Color.Transparent)
      .borderRadius($r('sys.float.corner_radius_level8'))
    }
    .layoutWeight(1)
    .constraintSize({ maxHeight: this.customRepeatPopContentHeight ? this.maxPopContentHeight : '100%' })
    .expandSafeArea([SafeAreaType.KEYBOARD], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .padding({ bottom: 24 })
  }

  /**
   * 左上角叉按钮
   */
  @Builder
  builderFork() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize('24vp')
          .fontColor([$r('sys.color.icon_primary')])
          .opacity($r('sys.float.alpha_primary'))
      }
      .accessibilityText(GlobalThis.getResourceStr($r('app.string.cancel_dialog_button')))
      .width(40)
      .height(40)
      .borderRadius($r('sys.float.corner_radius_level4'))
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .onClick(() => {
        this.isShowing = false;
      })
      .id(CompId.CANCEL)
    }
    .height(56)
  }

  /**
   * 自定义重复右上角勾选按钮
   */
  @Builder
  builderBackPress() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_primary'))
    }
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.cancel')))
    .width(40)
    .height(40)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick(() => {
      NavPathManager.getInstance().popRouter(RouterName.CREATE_AGENDA_MAIN);
    })
    .backgroundColor(this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary'))
  }

  /**
   * 自定义重复右上角勾选按钮
   */
  @Builder
  builderConfirm() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.checkmark'))
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')])
        .opacity($r('sys.float.alpha_primary'))
    }
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.account_details_complete_button')))
    .width(40)
    .height(40)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .enabled(this.saveButtonEnable)
    .onClick(() => {
      this.eventRecurrence.updateBy(this.tempRecurrence);
      this.isShowing = false;
      emitter.emit({ eventId: CommonInnerEvent.RECURRENCE_SET }, { data: { 'recurrence' : this.eventRecurrence.format() }});
      NavPathManager.getInstance().popRouter(RouterName.CREATE_AGENDA_MAIN);
    })
    .backgroundColor(this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary'))
    .id(CompId.CONFIRMS)
  }

  /**
   * 自定义重复标题栏
   */
  @Builder
  NaviTitle() {
    Row() {
      this.builderFork()
      Text($r('app.string.custom_repeat'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxFontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_STANDARD,
          px2vp(getContext().resourceManager.getNumber($r('sys.float.Title_S').id))
        ))
        .minFontSize(8)
        .fontWeight(FontWeight.Bold)
        .margin({ start: LengthMetrics.resource($r('sys.float.padding_level4')) })
        .id(CompId.CUSTOM_REPEAT)
      Blank()
      this.builderConfirm()
    }
    .padding({
      top: $r('sys.float.padding_level4'),
      left: $r('sys.float.padding_level8'),
      right: $r('sys.float.padding_level8')
    })
    .alignItems(VerticalAlign.Center)
    .height(56)
    .width('100%')
  }

  private updateSaveButtonStates(): void {
    this.saveButtonEnable = this.canSave();
    Log.info(TAG, `updateSaveButtonStates: ${this.saveButtonEnable},
    event=${this.eventRecurrence?.format()}, temp=${this.tempRecurrence.format()}`);
  }

  private canSave(): boolean {
    if (!this.tempRecurrence.isValidRecurrence()) {
      return false;
    }
    if (this.eventRecurrence?.format() === this.tempRecurrence.format()) {
      return false;
    }
    if (this.tempRecurrence.until !== '' && this.initSelectedStartDate.getTime() > this.tempRecurrence.getUntilMills()) {
      return false;
    }
    return true;
  }
}