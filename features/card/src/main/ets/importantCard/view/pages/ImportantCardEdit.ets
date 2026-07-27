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
  BackgroundId,
  BackgroundPanelId,
  EventMode,
  ImportantCardConfig
} from '@app/common/src/main/ets/card/ImportantCardConfig';
import {
  BigFontSize,
  CalendarContract,
  DateUtil,
  DeviceConfig,
  EmptyUtils,
  getAdaptImportantTime,
  MILLS_PER_DAY,
  Log,
  RefreshConfig,
  statisticEvents,
  CalendarDate
} from '@app/common';
import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import lazy { ImportantCardController } from '../../controller/ImportantCardController';
import { ImportantEntity } from '../../model/ImportantEntity';
import { FormConfigManager } from '@app/common/src/main/ets/card/FormConfigManager';
import common from '@ohos.app.ability.common';
import { CardSetLayout } from '../components/importantCardUtils';
import { ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { EventIdFinder } from '../../EventIdFinder';
import mediaquery from '@ohos.mediaquery';
import lazy { ImportantCardPreview } from '../components/ImportantCardPreview';
import lazy { ImageUtils } from '../../util/ImageUtils';
import { ImportantCardEditModel } from '../../model/ImportantCardEditModel';
import { CardUiUtils } from '../../util/CardUiUtils';
import { ImportantCardComponentId } from '../../model/ImportantCardComponentId';
import { FormInfoManager } from '@app/common/src/main/ets/card/FormInfoManager';
import { MonthCardHandler } from '../../../monthCard/controller/MonthCardHandler';

const TAG: string = 'ImportantCardEdit';

const cardWidth: Record<string, number> = {
  'isCard2x2': 150,
  'isCard2x4': 300,
}

/**
 * 编辑重要日卡片
 *
 * @since 2023-10-11
 */
@Component
struct ImportantCardEdit {
  @StorageProp('editing_formId') @Watch('OnFormIdChange') formId: string = '';

  @StorageProp('editing_refreshId') @Watch('OnRefreshIdChange') refreshId: string = '';

  @StorageProp('language') @Watch('onLanguageChange') language: string | undefined = AppStorage.get('language');

  @Consume navPathStack: NavPathStack;

  //系统状态栏规避区
  @StorageProp('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  @State isCard2x2: boolean = true;

  @State title: Resource | string = '';

  @State attachmentCount: number = 0;

  @State unit: Resource = $r('app.plural.in_days');

  @State type: string = 'in_days';

  @State rrule: string = '';

  @State yearOffset: number = 0;

  @State remainingDays: number = 0;

  @State content: string = '';

  @State dayOffset: number = 0;

  @Provide fontPreviewText: string = '';

  @State date: CalendarDate = new CalendarDate();

  @State eventCalendarType: number = CalendarContract.AgendaCalendarType.SOLAR;

  @State @Watch('formConfigChange') formConfig: ImportantCardConfig = FormConfigManager.getImportantCardConfig(this.formId);

  @State importantEventInfo: ImportantEntity | undefined = undefined;

  @State backgroundImg: Resource = this.getBgImg();

  @State formWidth: number = this.isCard2x2 ? cardWidth.isCard2x2 : cardWidth.isCard2x4;

@State formHeight: number = cardWidth.isCard2x2;

@State gridMargin: number = 0

  @State gridColumns: number = 12

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  private cardEditBreakpoints: Array<string> = DeviceConfig.instance().config.deviceLayout.cardEditBreakpoints;

  @State cardEditGridColOptions: GridColOptions = DeviceConfig.instance().config.deviceLayout.cardEditGridColOptions;

  private cardEditGutter: number = 24;

  private isWindowDecorVisible: boolean = DeviceConfig.instance().config.isWindowDecorVisible;

  listener: mediaquery.MediaQueryListener = mediaquery.matchMediaSync('(orientation: landscape)');

  private editModel: ImportantCardEditModel = new ImportantCardEditModel();

  /** 判断数据是否已加载完成 */
  @State loadReady: boolean = false;

  @Builder
  customTitle() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.chevron_backward'))
          .fontSize('24vp')
          .fontColor([Color.White])
      }
      .accessibilityText($r('app.string.navigate_up'))
      .width(40)
      .height(40)
      .borderRadius($r('sys.float.corner_radius_level10'))
      .backgroundColor(this.isWindowDecorVisible ? '#1AFFFFFF' : '#00000000')
      .onClick(() => {
        const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
        context.terminateSelf();
      })

      Text($r('app.string.important_day'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ left: 8, right: 8 })
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_STANDARD)
    }
    .height(56)
    .width('100%')
    .padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    .zIndex(9)
  }

@Builder
  importantCardImg() {
    // 展示通用重要日样式
    ImportantCardPreview({
      formConfig: this.formConfig,
      language: this.language,
      isCard2x2: this.isCard2x2,
      title: this.title,
      date: this.date.getTime(),
      unit: this.unit,
      rrule: this.rrule,
      yearOffset: this.yearOffset,
      remainingDays: this.remainingDays,
      type: this.type,
      dayOffset: this.dayOffset,
      formWidth: this.formWidth,
      formHeight: this.formHeight,
      eventCalendarType: this.eventCalendarType,
      attachmentCount: this.attachmentCount,
    });
  }

  isImportantCard2x2() {
    if (this.formConfig?.formName) {
      Log.info(TAG, `isImportantCard2x2 formConfig: ${this.formConfig.formName}`);
      return this.formConfig.formName === 'ImportantCardView2x2';
    } else {
      const cardInfos = FormInfoManager.getAllFormInfo();
      const cardInfo = cardInfos.find(v => v.formId === this.formId);
      Log.info(TAG, `isImportantCard2x2 cardInfo: ${cardInfo?.formName}`);
      return cardInfo?.formName === 'ImportantCard2x2';
    }
  }

  async OnFormIdChange() {
    Log.info(TAG, 'OnFormIdChange start');
    try {
      if (!this.formId) {
        Log.info(TAG, 'OnFormIdChange formId is null');
        return
      }

      // 2x2切换到2x4编辑页面，更新配置项
      this.isCard2x2 = this.isImportantCard2x2();
      const singleFormId = BigInt.asIntN(32, BigInt(this.formId)).toString();
      this.formConfig = FormConfigManager.getImportantCardConfig(singleFormId, this.isCard2x2);
      this.editModel.setFormConfig(this.formConfig);
      Log.info(TAG, `OnFormIdChange getFormInfo done, ${singleFormId}/${this.formConfig?.formName}`);
      Log.info(TAG, `OnFormIdChange eventId: ${this.formConfig.fixedEventIds}`);

      this.formWidth = this.isCard2x2 ? cardWidth.isCard2x2 : cardWidth.isCard2x4;
      await this.editModel.loadData();
    } catch (err) {
      Log.logErrorMsg(TAG, 'OnFormIdChange', err);
    }
  }

  OnRefreshIdChange() {
    Log.info(TAG, `OnRefreshIdChange start`);
    // 手动刷新eventId,并重新加载页面
    this.OnFormIdChange();
  }

  onLanguageChange() {
    Log.info(TAG, `onLanguageChange ${this.language}`);

    // 更新content语言
    if (this.importantEventInfo) {
      const yearDayOffsetInfo = CardUiUtils.getYearDayOffset(this.importantEventInfo, this.language, this.importantEventInfo.title);
      this.content = yearDayOffsetInfo.content;
    }
  }

  formConfigChange() {
    this.backgroundImg = this.getBgImg();
  }

  getBgImg(): Resource {
    if (this.formConfig.backgroundId === BackgroundId.TEXTURES) {
      return CardUiUtils.getTextureById(this.formConfig.texturesId);
    } else {
      return CardUiUtils.getBackgroundById(
        this.formConfig.backgroundId,
        this.formConfig.texturesId,
        this.isCard2x2
      );
    }
  }

  onLandscape(mediaQueryResult: mediaquery.MediaQueryResult) {
    const deviceLayout = DeviceConfig.instance().config.deviceLayout;
    if (mediaQueryResult.matches) {
      // 横屏
      this.cardEditGridColOptions = deviceLayout.cardEditGridColOptions;
    } else {
      // 竖屏
      this.cardEditGridColOptions = deviceLayout.cardEditVGridColOptions;
    }
  }

  async aboutToAppear() {
    //获取双框架卡片ID对应的单框架卡片数据
    this.isCard2x2 = this.isImportantCard2x2();
    const singleFormId = BigInt.asIntN(32, BigInt(this.formId)).toString();
    this.formConfig = FormConfigManager.getImportantCardConfig(singleFormId, this.isCard2x2);
    Log.info(TAG, `aboutToAppear, ${singleFormId} config=${this.formConfig.eventMode}/${this.formConfig.fixedEventIds}`);
    this.formWidth = this.isCard2x2 ? cardWidth.isCard2x2 : cardWidth.isCard2x4;

    this.editModel.init();
    this.editModel.setFormConfig(this.formConfig);
    this.editModel.listenImportantChange((entity: ImportantEntity | undefined) => {
      this.showEvent(entity);
    });
    if (this.formId === this.formConfig.formId) {
      await this.editModel.loadData();
    } else {
      await this.OnFormIdChange();
    }

    // 直接this.onLandscape， this 丢失
    this.listener.on('change', (mediaQueryResult) => this.onLandscape(mediaQueryResult));
    // 判断数据已加载完成
    this.loadReady = true;
  }

  aboutToDisappear(): void {
    this.editModel.unInit();

    this.listener.off('change');
  }

  build() {
    Column() {
      this.customTitle()

      Column() {
        this.importantCardImg()

        Column() {
          GridRow({
            breakpoints: {
              value: this.cardEditBreakpoints,
              reference: BreakpointsReference.WindowSize
            },
            columns: this.gridColumns,
            gutter: this.cardEditGutter
          }) {
            GridCol(this.cardEditGridColOptions) {
              CardSetLayout({
                formConfig: this.formConfig,
                title: this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY ? $r('app.string.contact_info_changed') : this.title,
                importantEventInfo: this.importantEventInfo,
                isCard2x2: this.isCard2x2,
                formWidth: this.formWidth,
                formHeight: this.formHeight,
                content: this.formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY ? '' : this.content,
                hideSettingBar: false,
                dayOffset: this.dayOffset,
                onSelectChange: (config: ImportantCardConfig) => {
                  this.editModel.updateSelectFromConfig(config);
                },
                onConfirm: async () => {
                  Log.info(TAG, `onConfirm, eventId: ${this.formConfig.fixedEventIds}`);

                  const singleFormId = BigInt.asIntN(32, BigInt(this.formId)).toString();
                  const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
                  try {
                    this.clearPanelId(this.formConfig);
                    FormConfigManager.saveImportantCardConfig(singleFormId, this.formConfig);
                    notifyImportantCardRefresh(getContext(this), this.formId, this.isCard2x2, this.formConfig);
                    context.terminateSelf();
                    Log.info(TAG, `terminateSelf`);
                  } catch (err) {
                    Log.error(TAG, `apply getErr: ${err?.code}, ${err?.message}}`);
                  }
                }
              })
            }
          }.onBreakpointChange((currentBreakpoint: string) => {
            const offset = this.cardEditGridColOptions?.offset as Record<string, number>;
            const span = this.cardEditGridColOptions?.span as Record<string, number>;
            // 4占4(手机竖屏)，铺满全屏，边距为0
            // 8占8(平板竖屏)，铺满全屏，留有边距
            if (currentBreakpoint === 'xs' && offset.xs === 0) {
              this.gridMargin = 0;
            } else {
              this.gridMargin = this.cardEditGutter;
            }
            // 总的栅格数 = 边距 * 2 + 所占栅格数
            // 例如8占6， 8 = 1 * 2 + 6
            this.gridColumns = offset[currentBreakpoint] * 2 + span[currentBreakpoint];
          })
        }
        .margin({
          left: this.gridMargin,
          right: this.gridMargin
        })
      }
      .height('100%')
      .justifyContent(FlexAlign.End)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .visibility(this.loadReady ? Visibility.Visible : Visibility.Hidden)
    .padding({ top: this.buttonTopHeight + this.windowAvoidAreaTopRectHeight })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[0x092a45, 0.0], [0x2c516c, 0.4], [0x667578, 1.0]]
    })
  }

  private showEvent(important: ImportantEntity | undefined) {
    this.importantEventInfo = important;

    if (!this.importantEventInfo) {
      this.showDefaultCard();
      return;
    }
    this.importantEventInfo.begin = getAdaptImportantTime(this.importantEventInfo.eventCalendarType,
      this.importantEventInfo.begin, this.importantEventInfo.rrule, new CalendarDate());
    this.title = this.importantEventInfo.title;
    this.attachmentCount = this.importantEventInfo.mAttachmentCount;
    this.date = new CalendarDate(this.importantEventInfo.begin);
    this.eventCalendarType = this.importantEventInfo.eventCalendarType;
    this.rrule = this.importantEventInfo.rrule;

    const yearDayOffsetInfo = CardUiUtils.getYearDayOffset(this.importantEventInfo, this.language, this.title);
    this.yearOffset = yearDayOffsetInfo.yearOffset;
    this.remainingDays = yearDayOffsetInfo.remainingDays;
    this.content = yearDayOffsetInfo.content;
    this.dayOffset = yearDayOffsetInfo.dayOffset;
    this.type = yearDayOffsetInfo.type;
    this.refreshFontPreviewText();

    Log.info(TAG, `showEvent, eventId: ${this.formConfig.fixedEventIds}, date: ${this.date}, ` +
      `title: ${(this.title || '').slice(0, 1)}**${(this.title || '').slice(-1)}`);
  }

  private showDefaultCard() {
    this.title = $r('app.string.default_important_agenda');
    const currentDate = new CalendarDate();
    const targetDate = new CalendarDate(Date.UTC(currentDate.getFullYear(), 11, 31, 0, 0, 0)).getTime();
    this.date = new CalendarDate(targetDate);
    this.eventCalendarType = CalendarContract.AgendaCalendarType.SOLAR;

    this.yearOffset = 0;
    const dayOffset = Math.ceil((targetDate - Date.now()) / MILLS_PER_DAY);
    this.remainingDays = dayOffset;
    this.content = '';
    this.dayOffset = dayOffset;
    this.type = 'days_later';
    this.refreshFontPreviewText();
  }

/**
    * 字体预览的内容逻辑，同 ${CardYearDayOffset#build()}，卡片预览规格变更后，字体预览应联动变动
    */
  private refreshFontPreviewText(): void {
    if (this.type === 'days_later') {
      // 每年重复
      if (this.rrule?.includes('FREQ=YEARLY') && this.yearOffset > 0 && this.remainingDays === 0) {
        // 显示整年
        this.fontPreviewText = `${this.yearOffset}`;
      } else {
        // 显示剩余天
        this.fontPreviewText = `${this.dayOffset}`;
      }
    } else {
      if (this.yearOffset === 0) {
        // 显示剩余天
        this.fontPreviewText = `${this.dayOffset}`;
      } else if (this.remainingDays === 0) {
        // 显示整年
        this.fontPreviewText = `${this.yearOffset}`;
      } else {
        // 显示剩余年和天，预览数字显示天
        this.fontPreviewText = `${this.remainingDays}`;
      }
    }
  }

  private clearPanelId(formConfig: ImportantCardConfig) {
    // 保存后，需清除panelId
    // 自定义图片再次进入，无需回选
    // 再次自定义，需回选第一个预制图片
    if (formConfig.backgroundId === BackgroundId.CUSTOMIZE) {
      this.formConfig.panelId = BackgroundPanelId.NO_PANEL;
    }
  }
}

export {
  ImportantCardEdit, notifyImportantCardRefresh
}

/**
 * 通知重要日卡片刷新
 * @param context
 * @param formId 卡片id
 * @param config 重要日卡片配置信息
 * @param refreshConfig 区分克隆和双升单场景
 */
function notifyImportantCardRefresh(
  context: Context,
  formId: string,
  isCard2x2?: boolean | undefined,
  config?: ImportantCardConfig,
  refreshConfig?: RefreshConfig,
) {
  const singleFormId = BigInt.asIntN(32, BigInt(formId)).toString();
  let formConfig: ImportantCardConfig = config ? config :
    FormConfigManager.getImportantCardConfig(singleFormId, isCard2x2);
  const isAgreeStatement = MonthCardHandler.instance().getAgreeStatement();
  const isDoubleUpSingleAgreeStatement = MonthCardHandler.instance().getDoubleUpSingleAgreeStatement(formId);
  if (refreshConfig && refreshConfig.refreshTriggerType) {
    const singleFormId = BigInt.asIntN(32, BigInt(formId)).toString();
    Log.info(TAG, `notifyImportantCardRefresh formId = ${formId}, singleFormId = ${singleFormId}`);
    const eventId = new EventIdFinder().findEventId(refreshConfig.refreshTriggerType, singleFormId);
    if (EmptyUtils.isUndefinedOrNull(eventId)) {
      Log.warn(TAG, `notifyImportantCardRefresh eventId is undefined`);
    } else {
      formConfig.fixedEventIds[0] = eventId as number;
    }
  }

  const formData: Record<string, Object> = {};
  ImportantCardController.initCardUIConfig(formData, formConfig);
  formData['isAgreeStatement'] = isAgreeStatement;
  formData['isDoubleUpSingleAgreeStatement'] = isDoubleUpSingleAgreeStatement;
  let formBinding: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
  ImportantCardController.reSetDataProxy(context, formId, formBinding, formConfig);

  let params: ReportHiEventParams = {
    BACKGROUND: formConfig.backgroundId,
    TEXTURE: formConfig.texturesId,
    LAYOUT: formConfig.layoutId,
    FA_DIMENSION: isCard2x2 ? FormDimension.Dimension_2_2 : FormDimension.Dimension_2_4
  }
  ReportUtil.reportStatisticEvent(statisticEvents.editImportantFa, params)

  Log.info(TAG, `notifyImportantCardRefresh: ${formId}, ${formConfig.eventMode}, ${formConfig.fixedEventIds}`);
  formProvider.updateForm(formId, formBinding).then((data) => {
    console.log(`Important FormExtensionAbility context updateForm, data: ${data}`);
  }).catch(() => {
    console.error('Important Operation updateForm failed.');
  });
}