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

import { UnusualMode } from '../constants/Constants';
import { Log } from '../default/common/Log';
import { ModeUtil } from '../util/ModeUtil';
import { DeviceConfig } from './DeviceConfig';
import { GlobalDataKeys } from './GlobalDataKeys';


const TAG: string = 'CalendarLayout';

export interface ButtonLayoutParam {
  buttonHeight: Length, // 按钮高宽
  menuHeight: number, // 按钮所处菜单栏的高度
  imageSize: Length, // 图片大小
  symbolSize: Length, // symbol图标大小
  symbolWeight: number, // symbol字重
  backTextSize: Length, // 回到今天文字大小
}


@Observed
export class ButtonLayout implements ButtonLayoutParam {
  public buttonHeight: Length = 40;
  public menuHeight: number = 56;
  public imageSize: Length = '20vp';
  public symbolSize: Length = '24vp';
  public symbolWeight: number = 400;
  public backTextSize: Length = '20vp';
}

const defaultLayout: ButtonLayoutParam = {
  buttonHeight: 40,
  menuHeight: 56,
  imageSize: '20vp',
  symbolSize: '24vp',
  symbolWeight: 400,
  backTextSize: '20vp',
}

const compactLayout: ButtonLayoutParam = {
  buttonHeight: 32,
  menuHeight: 40,
  imageSize: '14vp',
  symbolSize: '16vp',
  symbolWeight: 500,
  backTextSize: '16vp',
}


export interface AgendaItemLayoutParam {
  mainTextFontSize: Resource, // 主标题字体大小
  subTextFontSize: Resource, // 副标题字体大小
  agendaItemHeight: number, // 日程item高度
}

const compactAgendaLayout: AgendaItemLayoutParam = {
  mainTextFontSize: $r('sys.float.Subtitle_S'), // 主标题字体大小
  subTextFontSize: $r('sys.float.Body_S'), // 副标题字体大小
  agendaItemHeight: 76, // 日程item高度
}

@Observed
export class AgendaItemLayout implements AgendaItemLayoutParam {
  public mainTextFontSize: Resource = DeviceConfig.instance().config.agendaItemMainFontSize;
  public subTextFontSize: Resource = DeviceConfig.instance().config.agendaItemSubFontSize;
  public agendaItemHeight: number = 80;
}


// 布局管理器，用于不同状态下页面布局的变化
export class CalendarLayoutManager {
  private static _instance: CalendarLayoutManager = new CalendarLayoutManager();
  public buttonLayout: ButtonLayoutParam = new ButtonLayout();
  public agendaLayout: AgendaItemLayoutParam = new AgendaItemLayout();

  private defaultAgendaLayout: AgendaItemLayoutParam = {
    // 因DeviceConfig初始化问题故将其放置于manager内部
    mainTextFontSize: DeviceConfig.instance().config.agendaItemMainFontSize, // 主标题字体大小
    subTextFontSize: DeviceConfig.instance().config.agendaItemSubFontSize, // 副标题字体大小
    agendaItemHeight: 80, // 日程item高度
  }

  public static getInstance(): CalendarLayoutManager {
    return CalendarLayoutManager._instance;
  }

  constructor() {
  }

  init() {
    this.defaultAgendaLayout.mainTextFontSize = DeviceConfig.instance().config.agendaItemMainFontSize;
    this.defaultAgendaLayout.subTextFontSize = DeviceConfig.instance().config.agendaItemSubFontSize;
    this.changeLayout();
  }

  public changeLayout() {
    const unusualMode: UnusualMode | undefined = AppStorage.get<UnusualMode>(GlobalDataKeys.UNUSUAL_MODE);
    if (ModeUtil.isSmallUpDownFoldMode(unusualMode)) {
      this.changeLayoutParam(compactLayout);
      this.changeAgendaLayoutParam(compactAgendaLayout);
    } else {
      this.changeLayoutParam(defaultLayout);
      this.changeAgendaLayoutParam(this.defaultAgendaLayout);
    }
    Log.info(TAG, `layoutChange unusualMode ${unusualMode}, buttonHeight: ${this.buttonLayout.buttonHeight}`);
  }

  private changeLayoutParam(layout: ButtonLayoutParam) {
    this.buttonLayout.buttonHeight = layout.buttonHeight;
    this.buttonLayout.menuHeight = layout.menuHeight;
    this.buttonLayout.imageSize = layout.imageSize;
    this.buttonLayout.symbolSize = layout.symbolSize;
    this.buttonLayout.symbolWeight = layout.symbolWeight;
    this.buttonLayout.backTextSize = layout.backTextSize;
  }

  private changeAgendaLayoutParam(layout: AgendaItemLayoutParam) {
    this.agendaLayout.mainTextFontSize = layout.mainTextFontSize;
    this.agendaLayout.subTextFontSize = layout.subTextFontSize;
    this.agendaLayout.agendaItemHeight = layout.agendaItemHeight;
  }
}