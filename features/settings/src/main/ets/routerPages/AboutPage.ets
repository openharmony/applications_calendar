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
  DeviceConfig,
  FontSizeScaleUtils,
  GlobalDataKeys,
  GlobalThis,
  Log,
  MIN_WINDOW_WIDTH_VP,
  NavPageBuilderFactory,
  NavPathManager,
  NavPathName,
  RouterName,
  ViewProxy
} from '@app/common';
import { call } from '@kit.TelephonyKit';
import { VersionInfo } from './VersionInfo';
import { PopPageParam } from '../SettingRoot';
import { LengthMetrics } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { JumpUtils } from '../utils/JumpUtil';

/**
 * 设置-关于
 */

const TAG: string = 'AboutPage';

@Extend(Image)
function commonProperties() {
  .draggable(false)
}

type startAbleContext = common.UIAbilityContext | common.ServiceExtensionContext;

@Builder
function harBuilder(value: object) {
  AboutPage();
}

const builderName = NavPathName.SETTING_ABOUT;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct AboutPage {
  // 顶端状态栏预留高度, 沉浸式保证颜色一致, 整体下移避免遮挡
  @StorageLink('windowAvoidAreaTopRectHeight') windowAvoidAreaTopRectHeight: number = 0;

  //系统导航栏规避区
  @StorageProp('windowAvoidAreaNavigationRectHeight') windowAvoidAreaNavigationRectHeight: number = 0;

  @StorageProp('isDarkMode') isDarkMode: boolean | undefined = AppStorage.get(GlobalDataKeys.IS_DARKMODE);

  @StorageLink('themeColor') themeColor: string = '';

  @StorageLink('language') language: string = '';

  private viewProxy: ViewProxy = new ViewProxy(TAG);

  //svg模糊度
  private antialiasingNumber: number = DeviceConfig.instance().config.antialiasingNumber;

  private buttonTopHeight: number = DeviceConfig.instance().config.deviceLayout.buttonTopHeight;

  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowWidthChange') windowWidth: number = 0;
  // 小屏判断
  @State inSmallWindow: boolean = this.windowWidth < MIN_WINDOW_WIDTH_VP;

  private description: string = '950800';

  private isInPop: boolean = false;

  @State icpBackgroundColor: ResourceColor = Color.Transparent;

  /**
   * 窗口尺寸判断
   */
  onWindowWidthChange() {
    this.inSmallWindow = this.windowWidth < MIN_WINDOW_WIDTH_VP;
  }

  aboutToAppear(): void {
    Log.info(TAG, 'aboutToAppear')
    const params = NavPathManager.getInstance().getParamByName<PopPageParam>(NavPathName.SETTING_ABOUT,
      RouterName.SETTING_HAP);
    if (!params[0]) {
      return;
    }
    const paramsInter = params[0] as PopPageParam;
    this.isInPop = paramsInter.isInPop;
  }

  @Builder
  buildAppDisplayRecord() {
    Column() {
      Scroll() {
        Column() {
          this.calendarImage()
          this.recordDetail()
          this.deviceInformation()
        }.constraintSize({ minHeight: 300 })
        .height('100%')
      }
      .padding({ top: 16, bottom: 16 })
      .layoutWeight(1)
    }
  }

  @Builder
  calendarImage() {
    Image($r('app.media.calendar_about'))
      .width(72)
      .height(72)
      .fillColor($r('sys.color.ohos_fa_icon_fourth'))
      .edgeAntialiasing(this.antialiasingNumber)
      .commonProperties()
      .margin({ left: 4, right: 6, bottom: 8 })
      .borderRadius(18)
    Text($r('app.string.calendar'))
      .fontSize(20)
      .fontWeight(FontWeight.Medium)
      .fontFamily('HarmonyHeiTi')
      .maxLines(1)
  }

  @Builder
  recordContent() {
    GridRow({
      columns: {
        xs: 2,
        sm: 4,
        md: 8,
        lg: 12
      },
      gutter: 0
    }) {
      GridCol({
        span: {
          xs: 2,
          sm: 4,
          md: 6,
          lg: this.isInPop ? 12 : 8
        },
        offset: {
          xs: 0,
          sm: 0,
          md: 1,
          lg: this.isInPop ? 0 : 2
        }
      }) {
        this.recordDetail()
      };
    }
    .layoutWeight(1)
  }

  @Builder
  recordDetail() {
    Column() {
      List() {
        ListItemGroup() {
          this.recordDetailContent()
        }
        .backgroundColor($r('sys.color.comp_background_list_card'))
        .borderRadius($r('sys.float.corner_radius_level8'))
        .padding($r('sys.float.padding_level2'))
        .divider({
          strokeWidth: '1px',
          color: $r('sys.color.comp_divider'),
          startMargin: $r('sys.float.padding_level4'),
          endMargin: $r('sys.float.padding_level4')
        });
      }
      .borderRadius($r('sys.float.corner_radius_level8'))
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .margin({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
    }
    .margin({ top: 36 })
    .layoutWeight(1)
  }

  @Builder
  recordDetailContent() {
    ListItem() {
      VersionInfo()
    }
    ListItem() {
      buildCall({ textTitle: $r('app.string.preferences_customer_service_title') });
    }.onClick(() => {
      if (!call.hasVoiceCapability()) {
        Log.log(TAG, 'not support voice capability, return.');
        return;
      }
      call.makeCall(this.description, (err) => {
        if (!err) {
          Log.info(TAG, 'make call success.');
        } else {
          Log.logErrorMsg(TAG, 'make call fail, err is:', err);
        }
      });
    })
  }

  @Builder
  deviceInformation() {
    Column() {
      Text($r('app.string.su_icp_17040376'))
        .fontSize($r('sys.float.Body_S'))
        .fontColor(this.themeColor)
        .fontWeight(FontWeight.Medium)
        .fontFamily('HarmonyHeiTi')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
        .onClick(() => {
          const context = GlobalThis.getInstance().context;
          if (context) {
            JumpUtils.openBrowser(context, getContext().resourceManager.getStringSync($r('app.string.record_url').id));
          }
        })
        .backgroundColor(this.icpBackgroundColor)
        .onTouch((ev) => {
          if (ev.type === TouchType.Up || ev.type === TouchType.Cancel) {
            this.icpBackgroundColor = Color.Transparent
          } else if (ev.type === TouchType.Down) {
            this.icpBackgroundColor = $r('sys.color.interactive_click');
          }
        })
        .hoverEffect(HoverEffect.Highlight)
        .borderRadius($r('sys.float.corner_radius_level2'))
        .padding({ left: 4, right: 4 })
      Text($r('app.string.copyright_text', 2025))
        .maxFontSize($r('sys.float.Body_S'))
        .minFontSize(8)
        .fontColor($r('sys.color.icon_secondary'))
        .fontWeight(FontWeight.Regular)
        .fontFamily('HarmonyHeiTi')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .maxFontScale(BigFontSize.BIG_FONT_SIZE_SCALE_2X)
    }.padding({ left: $r('sys.float.padding_level8'), right: $r('sys.float.padding_level8') })
  }

  @Builder
  buildCustomTitle() {
    Text($r('app.string.about'))
      .maxLines(2)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
        GlobalThis.getInstance().fontSizeScale, BigFontSize.BIG_FONT_SIZE,
        20
      ))
      .minFontSize(10)
      .fontWeight(FontWeight.Bold)
      .padding({ start: LengthMetrics.vp(8), top: LengthMetrics.vp(16) })
  }

  build() {
    NavDestination() {
      this.buildAppDisplayRecord()
    }
    .padding({
      top: this.isInPop ? 0 : $r('sys.float.padding_level4'),
      bottom: this.inSmallWindow ? this.windowAvoidAreaNavigationRectHeight : 0
    })
    .backgroundColor(this.isDarkMode ? $r('app.color.color_privacy_background_black') : $r('app.color.color_privacy_background'))
    .onShown(() => this.viewProxy.onShown())
    .onHidden(() => this.viewProxy.onHidden())
    .hideTitleBar(false)
    .title(this.buildCustomTitle)
  }
}

@Component
struct buildCall {
  private textTitle: ResourceStr = '';

  private description: string = '950800';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  build() {
    Row() {
      Column() {
        Text(this.textTitle)
          .fontSize($r('sys.float.Body_L'))
          .fontColor($r('sys.color.font_primary'))
          .fontWeight(FontWeight.Medium)
          .fontFamily('HarmonyHeiTi')
          .maxLines(2)
        if (this.description) {
          Text(this.description)
            .fontSize(14)
            .fontColor($r('sys.color.font_tertiary'))
            .margin({ top: 2 })
        }
      }
      .flexShrink(1)
      .alignItems(HorizontalAlign.Start)
      .padding({ right: 8 })

      if (call.hasVoiceCapability()) {
        Row() {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(24)
            .fontColor([$r('sys.color.icon_fourth')])
            .margin({ left: 4 })
        }
        .alignItems(VerticalAlign.Center)
        .constraintSize({ minHeight: 24})
        .clip(true)
        .flexShrink(0)
      }
    }
    .constraintSize({
      minHeight: this.needCommerce ? 56 : 64
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      right: $r('sys.float.padding_level4'),
      left: $r('sys.float.padding_level4')
    })
    .borderRadius($r('sys.float.corner_radius_level7'))
    .stateStyles({
      pressed: {
        .backgroundColor(call.hasVoiceCapability() ? $r('sys.color.interactive_click') : Color.Transparent)
      },
      normal: {
        .backgroundColor($r('app.color.default_background'))
      }
    })
    .hoverEffect(call.hasVoiceCapability() ? HoverEffect.Highlight : HoverEffect.None)
  }
}