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
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalThis,
  ViewProxy,
  CompId,
  BigFontSize,
  ThrottleFunction,
  CommonInnerEvent,
  Log,
  ServiceManager,
  ServiceEnum,
  UnusualMode,
  GlobalDataKeys,
  ReportUtil,
  behaviorEvents
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { ImportExportService } from '../interface/ImportExportService';
import { ImportVcsCallBack } from '../interface/ImportVcsCallBack';
import { ListItemSampleContent } from '@app/common.components';

const TAG: string = 'ImportAgenda';

@Component
export struct ImportAgenda {

  @Link showPage: boolean;

  @Prop @Watch('showDiscardDialog') discardFlag: boolean;

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  // 是否是特殊模式
  @StorageProp('unusualMode') unusualMode: UnusualMode | undefined = AppStorage.get(GlobalDataKeys.UNUSUAL_MODE);

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  @State dummyFlag: boolean = false; // 无用flag

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @State isNotExit: boolean = true;

  //是否需要商务化
  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  private navParams: object = JSON.parse('{}');

  private columnColor: ResourceColor = this.needCommerce ? Color.Transparent : $r('sys.color.comp_background_tertiary');

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  showDiscardDialog(changedPropertyName: string) {
    this.onBackPress();
  }

  aboutToAppear(): void {
    Log.info(TAG, 'aboutToAppear');
  }

  aboutToDisappear(): void {
    Log.info(TAG, 'about to disappear');
  }

  // 定义在组件内的@Styles封装的样式
  @Styles
  listItemCommon() {
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .padding($r('sys.float.padding_level2'))
    .borderRadius($r('sys.float.corner_radius_level8'));
  }
  /**
   * 侧滑返回
   * this.navPathStack.pop() 不会回调 onBackPress
   * @returns
   */
  onBackPress(): boolean {
    Log.info(TAG, `onBackPress`)
    this.viewProxy.onBackPressed();
    this.showPage = false;
    return false;
  }

  build() {
    NavDestination() {
      Column() {
        this.buildTitleBar()
        this.buildContent()
      }
      .padding({
        left: $r('sys.float.padding_level8'),
        right: $r('sys.float.padding_level8'),
      })
      .height('100%')
    }
    .onBackPressed(() => {
      return this.onBackPress();
    })
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .hideTitleBar(true)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  buildContent() {
    List({ space: 12 }) {
      ListItem() {
        ListItemSampleContent({
          label: $r('app.string.import_from_file'),
          compId: CompId.ADD_AGENDA_SELECTED_TIMEZONE,
          onClickCallback: () => {
            ThrottleFunction.instance().throttle(TAG, (): void => {
              ReportUtil.reportBehaviorEvent(behaviorEvents.importAgendaFromFile);
              this.ImportFromFileOnClick();
              this.showPage = false;
            });
          }
        });
      }.listItemCommon();
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }

  @Builder
  buildTitleBar() {
    Row() {
      this.buildBackButton();
      Text($r('app.string.import_agenda'))
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
          GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE_SCALE,
          20
        ))
        .minFontSize(10)
        .fontWeight(FontWeight.Bold)
        .padding({ start: LengthMetrics.vp(8) });
    }
    .width('100%')
    .margin({ top: $r('sys.float.padding_level4'), bottom: $r('sys.float.padding_level4') })
    .height(56)
  }

  public static async getDocumentUri(context: Context): Promise<string> {
    try {
      let documentSelectOptions = new picker.DocumentSelectOptions();
      let documentPicker = new picker.DocumentViewPicker(context);
      //跳转后只有'.ics'和'.vcs'文件可选
      documentSelectOptions.fileSuffixFilters = ['.ics', '.vcs'];
      documentSelectOptions.maxSelectNumber = 1;
      let documentResult = await documentPicker.select(documentSelectOptions);
      return documentResult[0];
    } catch (error) {
      Log.logErrorMsg(TAG, `getDocumentUri fail`, error);
      return '';
    }
  }

  private async ImportFromFileOnClick() {
    await this.itemOnClick(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  public async itemOnClick(context: Context): Promise<void> {
    let data: string = await ImportAgenda.getDocumentUri(context);
    // 检查data是否为空或空白字符串
    if (!data || data.trim() === '') {
      Log.warn(TAG, 'Document URI is empty or invalid.');
      this.showPage = true;
      return; // 退出函数，不进行后续操作
    }
    let service = await ServiceManager.getInstance()
      .getDynamicService<ImportExportService>(ServiceEnum.IMPORT_EXPORT_SERVICE);
    // 检查service和import方法是否存在
    if (!service || !service.import) {
      Log.warn(TAG, 'Service or import method is not available.');
      return; // 退出函数，不进行后续操作
    }
    service?.import(data, ImportVcsCallBack.getInstance())
  }

  @Builder
  BuildImportFromFileText() {
    Text($r('app.string.import_from_file'))
      .fontColor($r('sys.color.font_primary'))
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .margin({ start: LengthMetrics.vp(12), end: LengthMetrics.vp(8) })
  }

  /**
   * 左上角叉按钮
   */
  @Builder
  buildBackButton() {
    Button({ type: this.needCommerce ? ButtonType.Normal : ButtonType.Circle }) {
      SymbolGlyph($r('sys.symbol.chevron_backward'))
        .focusable(true)
        .fontSize('24vp')
        .fontColor([$r('sys.color.icon_primary')]);
    }
    .focusable(true)
    .height(40)
    .width(40)
    .backgroundColor(this.columnColor)
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onClick(() => {
      ThrottleFunction.instance().throttle(TAG,
        (): void => {
          this.showPage = false;
        },
        300);
    })
    .accessibilityText(GlobalThis.getResourceStr($r('app.string.navigate_up')));
  }

}