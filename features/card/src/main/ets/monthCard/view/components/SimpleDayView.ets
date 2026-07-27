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
import { WIDTH_ONE_IN_FIVE, WIDTH_ONE_IN_SEVEN, WIDTH_ONE_IN_SIXTH, WIDTH_QUARTER } from '../../../common/CardConsts';
import { MonthViewLayout } from '../../layout/MonthCardLayout';
import { CardSingleDayViewModel } from '../../viewModel/components/CardSingleDayViewModel';

const TAG: string = '[MonthCard][SimpleDay]';

/**
 * 用于简单样式的单天日期宫格绘制
 */
@Component
export struct SimpleDayView {
  @ObjectLink dayViewModel: CardSingleDayViewModel;

  // 是否处于小屏
  @LocalStorageProp('isSmallUp') isSmallUp: boolean = false;

  // 节点索引
  @Prop index: number;

  // 单月行数
  @Prop rowNum: number;

  private layoutModel: MonthViewLayout | undefined;

  updateDateTextOpacity() {
    if (this.dayViewModel.isToday) {
      return this.layoutModel?.isTodayOpacity; // 今天
    }
    if (!this.dayViewModel.isCurrentMonth) {
      return this.layoutModel?.notCurrentMonthOpacity; // 非当月
    }
    if (this.dayViewModel.showRecessData) {
      return this.layoutModel?.isRecessOpacity; // 班休
    }
    if (this.dayViewModel.isWeekends) {
      return this.layoutModel?.isWeekendsOpacity; // 周末
    }
    return 1; // 其它场景
  }

  updateDateTextColor() {
    if (this.dayViewModel.isCurrentMonth) {
      if (this.dayViewModel.isToday) {
        return this.layoutModel?.isTodayColor; // 今天选中，实心圆圈，字体颜色反转白色
      } else {
        if (this.dayViewModel.showRecessData) {
          return this.dayViewModel.mark === 0
            ? this.layoutModel?.defaultColor
            : (this.dayViewModel.mark === 1 ? this.layoutModel?.restDayColor : this.layoutModel?.workDayColor)
        }
        return this.layoutModel?.defaultColor; // 当月, 非今天 默认黑色
      }
    } else {
      return this.layoutModel?.notCurrentMonthColor; // 非当月
    }
  }

  @Builder
  buildCircle() {
    Column()
      .width($r('sys.float.ohos_id_text_size_caption'))
      .height($r('sys.float.ohos_id_text_size_caption'))
      .padding('50%')
      .backgroundColor($r('app.color.color_privacy_red'))
      .alignSelf(ItemAlign.Center)
      .borderRadius('50%')
  }

  // 月视图日期展示的内容
  isShowText() {
    // 如果是今天且展示班休，则判断是否有班休；mark = 1为休，mark = 2为班，其它均展示日期
    if (this.dayViewModel.isToday && this.dayViewModel.showRecessData) {
      if (this.dayViewModel.mark === 1) {
        return '休';
      } else if (this.dayViewModel.mark === 2) {
        return '班';
      } else {
        return this.dayViewModel.day.toString();
      }
    } else {
      return this.dayViewModel.day.toString();
    }
  }

  build() {
    if (this.dayViewModel.isToday) {
      this.buildToday()
    } else {
      this.buildOtherDay()
    }
  }

  @Builder
  buildToday() {
    Stack() {
      this.buildCircle()
      if (this.dayViewModel.isCurrentMonth) {
        Text(this.isShowText())
          .minFontSize((this.layoutModel?.minFontSize ?? 10) - (this.isSmallUp ? 1 : 0))
          .maxFontSize((this.layoutModel?.maxFontSize ?? 10) - (this.isSmallUp ? 1 : 0))
          .maxFontScale(1)
          .fontColor(this.updateDateTextColor())
          .opacity(this.updateDateTextOpacity())
          .fontWeight(600)
          .textAlign(TextAlign.Center)
      }
    }
    .width(WIDTH_ONE_IN_SEVEN)
    .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
    .alignRules({
      top: {
        anchor: this.index / 7 === 0 ? 'monthViewBase' : `monthView${this.index - 7}`,
        align: this.index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
      },
      left: {
        anchor: this.index % 7 === 0 ? 'monthViewBase' : `monthView${this.index - 1}`,
        align: this.index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
      }
    })
    .id(`monthView${this.index}`)
  }

  @Builder
  buildOtherDay() {
    Text(this.isShowText())
      .minFontSize((this.layoutModel?.minFontSize ?? 10) - (this.isSmallUp ? 1 : 0))
      .maxFontSize((this.layoutModel?.maxFontSize ?? 10) - (this.isSmallUp ? 1 : 0))
      .maxFontScale(1)
      .fontColor(this.updateDateTextColor())
      .opacity(this.updateDateTextOpacity())
      .fontWeight(600)
      .visibility(this.dayViewModel.isCurrentMonth ? Visibility.Visible : Visibility.Hidden)
      .textAlign(TextAlign.Center)
      .width(WIDTH_ONE_IN_SEVEN)
      .height(this.rowNum == 6 ? WIDTH_ONE_IN_SIXTH : (this.rowNum == 5 ? WIDTH_ONE_IN_FIVE : WIDTH_QUARTER))
      .alignRules({
        top: {
          anchor: this.index / 7 === 0 ? 'monthViewBase' : `monthView${this.index - 7}`,
          align: this.index / 7 === 0 ? VerticalAlign.Top : VerticalAlign.Bottom
        },
        left: {
          anchor: this.index % 7 === 0 ? 'monthViewBase' : `monthView${this.index - 1}`,
          align: this.index % 7 === 0 ? HorizontalAlign.Start : HorizontalAlign.End
        }
      })
      .id(`monthView${this.index}`)
  }
}