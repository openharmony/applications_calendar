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

import { EmptyUtils, NavPageBuilderFactory, NavPathManager, NavPathName, RouterName } from '@app/common';
import { SearchFromPage } from '../common/AgendaEnum';
import { FlexSearchAgenda } from './FlexSearchAgenda';

const TAG: string = 'FlexSearchAgendaRoot';

/**
 * 搜索页面的路由层
 *
 * @since 2024-08-22
 */

@Builder
function harBuilder(value: object) {
  FlexSearchAgendaRoot({
    searchAgendaRootVM: new FlexSearchAgendaRootViewModel(false)
  });
}

const builderName = NavPathName.FLEX_SEARCH_AGENDA;
if (!NavPageBuilderFactory.getBuilder(builderName)) {
  let builder: WrappedBuilder<[object]> = wrapBuilder(harBuilder);
  NavPageBuilderFactory.registerBuilder(builderName, builder);
}

@Component
export struct FlexSearchAgendaRoot {
  @Provide navPathStackInPop: NavPathStack = new NavPathStack();

  // 本组件的视图模型
  @ObjectLink searchAgendaRootVM: FlexSearchAgendaRootViewModel;

  @State showResult:boolean = false;

  @State showSearch: boolean = false;

  showResultChange(showResult: boolean) {
    this.showResult = showResult;
  }

  @Builder
  navRoute(name: string, param: Object) {
    NavPageBuilderFactory.getBuilder(name)?.builder(param);
  }

  async aboutToAppear() {
    NavPathManager.getInstance().createRouter(RouterName.SEARCH_AGENDA_MAIN, this.navPathStackInPop);
  }

  aboutToDisappear(): void {
    NavPathManager.getInstance().discard(RouterName.SEARCH_AGENDA_MAIN);
  }

  build() {
    Navigation(this.navPathStackInPop) {
      FlexSearchAgenda({
        isInPop: this.searchAgendaRootVM.isInPop,
        showResultChange: (showResult: boolean) => {
          this.showResultChange(showResult)
        },
        showSearch: this.showSearch,
        fromPage: SearchFromPage.SEARCH_ROOT,
      })
    }
    .backgroundColor($r('sys.color.ohos_id_color_panel_bg'))
    .hideTitleBar(true)
    .navDestination(this.navRoute)
    .height(560)
    .constraintSize({
      minHeight: 320,
      maxHeight: 560
    })
  }
}

@Observed
export class FlexSearchAgendaRootViewModel {
  // 本组件是否存在与弹窗内
  public isInPop: boolean = false;

  reset() {
    this.isInPop = false;
  }

  constructor(isInPop?: boolean,) {
    if (!EmptyUtils.isUndefinedOrNull(isInPop)) {
      this.isInPop = isInPop as boolean;
    }
  }
}
