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

import { Action, eventAction } from '../groupConfig/declare';
import { NavPathName } from '@app/common/src/main/ets/constants/NavPathName';
import {
  BigFontSize,
  CommonInnerEvent,
  DeviceConfig,
  EmitterCollector,
  FontSizeScaleUtils,
  I18nUtil,
  Log,
  NavPathManager,
  RouterName,
  ServiceEnum,
  ServiceManager,
  TimeZoneUtil
} from '@app/common';
import { LengthMetrics } from '@kit.ArkUI';
import { emitter } from '@kit.BasicServicesKit';
import { TimeZoneService } from '@app/service.timezone';

const TAG: string = 'TimeZone';

@Component
export struct TimeZone {
  @State isShowAppDisplayRecordPage: boolean = false;

  @State isNeedShowNetWorkDialog: boolean = false;

  @State timeZone: string = '';

  @StorageProp('fontSizeScale') fontSizeScale: number = BigFontSize.BIG_FONT_SIZE_STANDARD;

  //系统语言
  @StorageProp('language') @Watch('onLanguageChange') language: string = '';

  private rowMinHeight: number = DeviceConfig.instance().config.rowMinHeight;

  // 主标题
  private title: ResourceStr = '';

  // 描述
  private description: ResourceStr = '';

  // 触发的行为类型，赋初值防止ArkTS报错
  private action: Action = eventAction.ROUTER;

  // 设置项key值
  private settingKey: string = '';

  // 设置项的默认值
  private defaultVal: string | number = '';

  //
  private compId: string = '';

  // 是否存在于弹窗中
  private isInPop: boolean = false;

  private emitterCollector: EmitterCollector = new EmitterCollector();

  @Builder
  timeZoneBuilder() {
    Column() {
      Text(this.title)
        .fontSize($r('sys.float.Subtitle_M'))
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Medium)
        .maxLines(this.isLargeFontLayout() ? 1 : 2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.description) {
        Text(this.description)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_tertiary'))
          .margin({ top: $r('sys.float.padding_level4') })
      }
    }
    .flexShrink(this.isLargeFontLayout() ? 0 : 1)
    .alignItems(HorizontalAlign.Start)
    .padding({ right: $r('sys.float.padding_level4') })

    Row() {
      Text(this.timeZone)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_tertiary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(this.isLargeFontLayout() ? TextAlign.Start : TextAlign.End)
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(FontSizeScaleUtils.getLimitFontSizeVp(
            this.fontSizeScale, BigFontSize.BIG_FONT_SIZE_SPECIAL,
            24
          ))
          .fontColor([$r('sys.color.icon_fourth')])
          .margin({ left: $r('sys.float.padding_level2') })
      }
      .alignItems(VerticalAlign.Center)
      .constraintSize({ minHeight: 24 })
      .clip(true)
    }
    .flexShrink(0)
    .width(this.isLargeFontLayout() ? '100%' : '65%')
    .justifyContent(this.isLargeFontLayout() ? FlexAlign.SpaceBetween : FlexAlign.Start)
  }

  @Builder
  buildVerticalLayout() {
    Column() {
      this.timeZoneBuilder();
    }
    .visibility(this.isLargeFontLayout() ? Visibility.Visible : Visibility.None)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .constraintSize({
      minHeight: this.rowMinHeight
    })
    .padding({
      top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 8),
      left: $r('sys.float.padding_level4'),
      right: $r('sys.float.padding_level4')
    })
  }

  build() {
    Row() {
      if (this.isLargeFontLayout()) {
        this.buildVerticalLayout()
      } else {
        Row() {
          this.timeZoneBuilder();
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
        .constraintSize({
          minHeight: this.rowMinHeight
        })
        .focusBox({ margin: LengthMetrics.vp(-2) })
        .padding({
          top: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
          bottom: FontSizeScaleUtils.getNormalBigFontSizeInterval(this.fontSizeScale, 4),
          left: $r('sys.float.padding_level4'),
          right: $r('sys.float.padding_level4')
        })
      }
    }
    .onClick(() => {
      const params: Record<string, number | boolean | string> = {};
      params.isInPop = this.isInPop;
      params.isFormAgenda = false;
      NavPathManager.getInstance().pushPath({
        builderName: NavPathName.SETTINGS_TIME_ZONE,
        routerName: RouterName.SETTING_HAP,
        param: params
      });
    })
    .stateStyles({
      pressed: {
        .backgroundColor($r('sys.color.interactive_click'))
      },
      normal: {
        .backgroundColor(Color.Transparent)
      }
    })
    .hoverEffect(HoverEffect.Highlight)
    .borderRadius(14)
    .id(this.compId)
  }

  private timeZoneChange: (eventData?: emitter.EventData) => void = (eventData?: emitter.EventData): void => {
    this.getTimeZone();
  };

  aboutToAppear() {
    this.getTimeZone();
    this?.onMounted();
    this.emitterCollector.on({ eventId: CommonInnerEvent.LOCKED_TIME_ZONE_CHANGED }, this.timeZoneChange);
  }

  aboutToDisappear(): void {
    this.emitterCollector.off();
  }

  async getTimeZone() {
    const service = await ServiceManager.getInstance()
      .getDynamicService<TimeZoneService>(ServiceEnum.LOCK_TIME_ZONE_SERVICE);
    if (!service) {
      Log.warn(TAG, `isTimeZoneLocked server is null`);
      return;
    }
    const isTimeZoneLocked: boolean = service.isTimeZoneLocked();
    Log.warn(TAG, `getTimeZoneSwitch isTimeZoneLocked ${isTimeZoneLocked}`);
    let lockedTimeZone = service.getLockedTimeZone();
    const systemTimeZone: string = I18nUtil.getSystemTimeZone();
    let currentTimeZone = lockedTimeZone ? lockedTimeZone : systemTimeZone;
    this.timeZone = TimeZoneUtil.localizedNameOfTheTimeZone(currentTimeZone, this.language);
  }

  isLargeFontLayout(): boolean {
    return this.fontSizeScale > BigFontSize.BIG_FONT_SIZE_STANDARD;
  }

  onLanguageChange() {
    this.getTimeZone();
  }

  // 组件挂载
  private onMounted: Function = () => {
  };

  // 打开弹框
  private openDialog: Function = () => {
  };
}