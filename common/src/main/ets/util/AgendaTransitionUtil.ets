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

import { AgendaEventInfo } from '../agenda/AgendaEventInfo';
import { FromType } from '../default/util/ReportUtil';
import { curves } from '@kit.ArkUI';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { traceEvents } from '../default/common/TraceEvents';
import { DeviceConfig } from '../data/DeviceConfig';
import { ClickSource } from '../constants/Constants';

@Observed
export class AgendaTransitionUtil {
  public static ANIMATE_TOTAL_TIME: number = 800;
  public static option: GeometryTransitionOptions = { follow: true };
  public isEditPageShow: boolean = false;
  // 共享元素转场的id，转场时设置相应的值，转场结束后设置为空字符串
  public geometryId: string = '';
  private deviceRadius: number = DeviceConfig.instance().config.deviceRadius;
  public editPageBorderRadius: number = this.deviceRadius; // 全模态卡片圆角,用于动效
  // 控制蒙板的上下树，在点击卡片和返回主页动画之外，需要保持蒙板下树，否则可能会一直绘制全屏大小的Column引起性能问题
  public isMaskEnabled: boolean = false;
  public showBottom: boolean = true; // 用于日程详情底部按钮的隐藏
  public maskAlpha: number = 0; // 蒙版透明度,同于动效
  public isShare: boolean = false; // 用于记录当前页面是否为共享页面
  public scalePage: number = 1; // 用于一镜到底打开卡片时的缩放
  public showTitle: boolean = false; // 用于一镜到底打开卡片时的缩放,标题栏替换
  // 由于点击卡片的动画完成后需要将geometryId置空，在返回时需要用到这个变量记录上一次点击的卡片的id
  private _formerId: string = '';
  public isStartAnimate: boolean = false;
  public isEndAnimate: boolean = false;
  public param: Record<string, string | number | boolean | AgendaEventInfo> = {};
  private openCoverCurve: ICurve = curves.interpolatingSpring(0, 1, 328, 36);
  private closeCoverCurve: ICurve = curves.interpolatingSpring(0, 1, 195, 23);
  public rootPage: string = '';
  private onAniStart: () => void = () => {};
  private onAniEnd: () => void = () => {};
  private isModeChange: boolean = false; // 是否切换模态
  public needAnimation: boolean = false; // 是否切换模态

  get formerId() {
    return this._formerId;
  }

  get modeChange() {
    return this.isModeChange;
  }

  set modeChange(isModeChange) {
    this.isModeChange = isModeChange;
  }

  // 点击卡片弹出编辑页
  public onCardClicked(itemName: string, needAnimate: boolean = true, onAniStart: () => void,
    onAniEnd: () => void, needScale: boolean = true): void {
    hiTraceMeter.startTrace(traceEvents.jumpToAgendaDetail, 0);
    this.needAnimation = needAnimate;
    if (this.isEndAnimate) {
      this.isEndAnimate = false;
      if (this.onAniEnd) {
        this.onAniEnd();
      }
    }
    this.onAniStart = onAniStart;
    this.onAniEnd = onAniEnd;
    this.isModeChange = false;
    if (this.onAniStart) {
      this.onAniStart();
    }
    this.showBottom = true;
    this.isStartAnimate = true;
    // 通过itemName将点击的卡片和弹出的编辑页进行绑定，实现从点击卡片位置弹出编辑页
    this.geometryId = itemName;
    this._formerId = itemName;

    this.editPageBorderRadius = this.deviceRadius;
    this.scalePage = 1;
    this.showTitle = true;

    this.isMaskEnabled = true;
    animateTo({
      duration: needAnimate ? 400 : 0,
      curve: this.openCoverCurve,
      onFinish: () => {
        hiTraceMeter.finishTrace(traceEvents.jumpToAgendaDetail, 0);
        if (!this.isStartAnimate) {
          return;
        }
        // 如果该动画后没有后续的接续动画，则设置geometryId为空字符串
        this.geometryId = '';
        // 如果后续无接续动画，则将蒙板下树，避免一直绘制造成性能问题
        this.isMaskEnabled = false;
        this.isStartAnimate = false;
        this.editPageBorderRadius = 0;
      }
    }, () => {
      this.isEditPageShow = true;
      this.maskAlpha = 0.2;
      if (needScale) {
        this.scalePage = 0.9;
      }
    })
  }

  // 点击编辑页的返回箭头返回
  public onBackClicked(needAnimate: boolean = true, isModeChange: boolean = false, needScale: boolean = true): void {
    if (this.isStartAnimate) {
      this.isStartAnimate = false;
    }
    this.needAnimation = needAnimate;
    this.geometryId = this.formerId;
    this.isEndAnimate = true;
    this.isModeChange = isModeChange;

    this.editPageBorderRadius = this.deviceRadius;
    if (needScale) {
      this.scalePage = 0.9;
      this.isMaskEnabled = true;
      this.maskAlpha = 0.2;
    }
    this.showBottom = false;
    animateTo({
      duration: needAnimate ? 400 : 0,
      curve: this.closeCoverCurve,
      onFinish: () => {
        if (!this.isEndAnimate) {
          return;
        }
        if (this.onAniEnd) {
          this.onAniEnd();
        }
        // 如果该动画后没有后续的接续动画，则设置geometryId为空字符串
        this.geometryId = '';
        this._formerId = '';
        // 如果后续无接续动画，则将蒙板下树，避免一直绘制造成性能问题
        this.isMaskEnabled = false;
        this.showTitle = false;
        this.isEndAnimate = false;
      }
    }, () => {
      if (needScale) {
        this.maskAlpha = 0;
        this.scalePage = 1;
      }
      this.isEditPageShow = false;
    })
  }

  // 初始化传递参数
  public buildEventDetail(info: AgendaEventInfo, fromType: FromType = FromType.UNKNOWN, canSubWindow: boolean = false) {
    this.isShare = false;
    this.param.id = info?.mId;
    this.param.isHoliday = info?.mIsHoliday ?? false;
    this.param.holidayTitle = info?.mTitle ?? '';
    this.param.instanceStartMills = info?.mBegin;
    this.param.instanceEndMills = info?.mEnd;
    this.param.fromType = fromType;
    this.param.source = ClickSource.MONTH_SHARE_AGENDA;
    this.param.isMessageResource = info?.isMessageResource;
    this.param.canSubWindow = canSubWindow;
    this.param.isPop = false;
  }

  // 初始化传递参数
  public setParamForCoverToPop(onAniEnd:() => void, geometry: string) {
    this.onAniEnd = onAniEnd;
    this._formerId = geometry;
  }

  public clearAniEnd() {
    if (this.onAniEnd) {
      this.onAniEnd();
    }
    // 清除动效参数
    this.needAnimation = true;
    this.showTitle = false;
    this.scalePage = 1;
    this.isMaskEnabled = false;
    this.showBottom = true;
    this._formerId = '';
    this.onAniEnd = () => {
    };
  }
}