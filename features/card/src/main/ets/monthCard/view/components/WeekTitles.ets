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
import { WeekTitleLayout } from '../../layout/MonthCardLayout';
import { WeekTitleViewModel } from '../../viewModel/components/WeekTitlesViewModel';
import { DeviceLayout, SmallDeviceLayout } from '@app/common/src/main/ets/data/DeviceLayout';

const TAG: string = '[MonthCard][WeekTitles]';

@Component
export struct WeekTitle {
  // 周题 绑定的 周题数据模型
  @ObjectLink viewModel: WeekTitleViewModel;

  @LocalStorageProp('deviceLayout') deviceLayout: DeviceLayout = new SmallDeviceLayout();

  private layoutModel: WeekTitleLayout | undefined;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  aboutToAppear(): void {
    console.info('TestFormRemake WeekTitle aboutToAppear ' + JSON.stringify(this.viewModel.weekTitles))
  }

  @Builder
  buildForEachTitles() {
    ForEach(this.viewModel.weekTitles, (item: Resource, index: number) => {
      Text(this.viewModel.weekTitles[index])
        .fontSize(`${(this.layoutModel?.titleFontSize ?? 6)}vp`)
        .maxFontScale(1)
        .fontColor(this.layoutModel?.titleFontColor)
        .textAlign(TextAlign.Center)
        .fontWeight(FontWeight.Medium)
        .opacity(this.viewModel.isShowWeekends[index]
          ? $r('sys.float.alpha_tertiary')
          : $r('sys.float.alpha_primary'))
      .height(this.layoutModel?.titleHeight)
      .width(this.layoutModel?.titleWidth)
    }, (item: string, index: number) => index.toString())
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      wrap: FlexWrap.NoWrap,
      justifyContent: FlexAlign.SpaceBetween,
    }) {
      this.buildForEachTitles();
    }
    .accessibilityLevel('no')
    .margin(this.layoutModel?.weekTitleMargin)
  }
}