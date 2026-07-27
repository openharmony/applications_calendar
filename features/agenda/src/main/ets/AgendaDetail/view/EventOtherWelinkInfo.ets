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
  AgendaTransitionUtil,
  DeviceConfig,
  GlobalThis,
  Log,
  PasteHelper,
  ThrottleFunction
} from '@app/common';
import web_webview from '@ohos.web.webview';
import { prompt } from '@kit.ArkUI';
import { LoadingView } from '../../components/LoadingView';
import { DEFAULT_NUM, DEFAULT_STR } from '../../CreateAgenda/Constants';
import { Account } from './Account';
import { HTML_ADAPTER } from '../../components/formateWebView/WelinkEmailPageJS';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { uiObserver } from '@kit.ArkUI'
import { AgendaCollapseButton } from './AgendaCollapseButton';

const TAG = 'EventOtherWelinkInfo';
const IMG_REGEX = new RegExp('<(img|IMG)(.*?)(\/>|><\/img>|>)', 'g');

interface Event { data: WebResourceRequest }

@Extend(Menu)
function menuCommerceStyle(needCommerce: boolean) {
  .radius(needCommerce ? 8 : undefined)
}

@Extend(MenuItem)
function menuItemCommerceStyle(needCommerce: boolean) {
  .borderRadius(needCommerce ? $r('sys.float.corner_radius_level2') : $r('sys.float.corner_radius_level8'))
  .constraintSize(needCommerce ? { minHeight: 40 } : { minHeight: 48 })
}

/**
 * 日程其他信息：帐户和说明
 */
@Component
export struct EventOtherWelinkInfo {
  // 窗口大小
  @LocalStorageLink('windowWidth') @Watch('onWindowSizeChange') windowWidth: number = 0;

  @LocalStorageLink('windowHeight') @Watch('onWindowSizeChange') windowHeight: number = 0;

  // 帐户颜色
  @Prop accountColor: number = 0;

  // 帐户展示名
  @Prop accountDisName: ResourceStr = '';

  // 帐户描述，业务上的描述信息
  @Prop @Watch('onDescriptionChange') description: string = '';

  // 视图上的用到的描述信息
  @State descriptionInView: string = '';

  @Prop mImportantEventType: number;

  //是否显示加载
  @State isLoading: boolean = true;

  contentWebController: web_webview.WebviewController = new web_webview.WebviewController();

  @Consume agendaTransitionUtil: AgendaTransitionUtil;

  // 原始账户描述
  private oldDescription: string = '';

  private webContentLoadTimes: number = 0;

  @State selectText: string = '';

  @State linkUrl: string = '';

  private menuResult: WebContextMenuResult = new WebContextMenuResult();

  private needCommerce: boolean = DeviceConfig.instance().config.needCommerce;

  private isCover: boolean = false;

  @State navDesInfo: uiObserver.NavDestinationInfo | undefined = undefined;
  @State viewModel: EventOtherWelinkInfoViewModel = new EventOtherWelinkInfoViewModel();

  @State pageScale: number = 1;

  @Link isAgendaCollapse: boolean;

  eventUuid: string = '';

  touchStart: Array<number> = [];

  private longPressGestureHandler(evt: TouchEvent) {
    switch (evt.type) {
      case TouchType.Down:
        Log.info(TAG, `onTouch, Down`);
        AppStorage.setOrCreate('isInCopy', false);
        this.touchStart = [Date.now(), evt.touches[0].displayX, evt.touches[0].displayY];
        break;
      case TouchType.Move:
        const now = Date.now();
        const displayX = evt.touches[0].displayX;
        const displayY = evt.touches[0].displayY;

        const deltaTs = now - this.touchStart[0];
        const deltaX = Math.abs(displayX - this.touchStart[1]);
        const deltaY = Math.abs(displayY - this.touchStart[2]);

        // 模拟长按，同一个地方按压500ms
        if (deltaTs > 500 && deltaX < 5 && deltaY < 5) {
          Log.info(TAG, `onTouch, is LongPressGesture`);
          AppStorage.setOrCreate('isInCopy', true);
        }
        break;
      case TouchType.Up:
        Log.info(TAG, `onTouch, Up`);
        this.touchStart = [];
    }
  }

  @Builder
  MenuBuilder() {
    Menu() {
      MenuItemGroup() {
        //判断复制内容不能为空
        if (this.selectText.length > 0 || this.linkUrl.length > 0) {
          MenuItem({ content: this.selectText.length > 0 ? $r('app.string.copy') : '复制链接' })// 待提翻
            .menuItemCommerceStyle(this.needCommerce)
            .onClick(async () => {
              await this.webCopyToPasteboard();
              prompt.showToast({
                message: GlobalThis.getResourceStr($r('app.string.share_dialog_success_toast'))
              })
            })
        }
        MenuItem({ content: $r('app.string.select_all') })
          .menuItemCommerceStyle(this.needCommerce)
          .onClick(async () => {
            this.menuResult.selectAll();
          })
      }
    }
    .width(224)
    .menuCommerceStyle(this.needCommerce)
  }

  @Builder
  DescriptionWebBuilder() {
    LoadingView()
      .flexGrow(1)
      .visibility(this.isLoading ? Visibility.Visible : Visibility.Hidden)
    Column() {
      Web({ src: 'about:blank', controller: this.contentWebController, renderMode: RenderMode.SYNC_RENDER })
        .textZoomRatio(this.viewModel.parseStatus ? 100 : 150)// 默认100
        .backgroundColor(this.viewModel.parseStatus ? $r('app.color.id_color_system_background') : $r('sys.color.background_secondary'))
        .javaScriptAccess(true)
        .domStorageAccess(false)
        .databaseAccess(false)
        .darkMode(WebDarkMode.Auto)
        .forceDarkAccess(true)
        .zoomAccess(true)
        .onLoadIntercept(this.loadOverride)
        .onPageBegin(() => {
          if (this.webContentLoadTimes === 0) {
            Log.debug(TAG, `onPageEnd loadContentData start`);
            this.loadContentData();

            this.webContentLoadTimes += 1;
          }
        })
        .onPageEnd(() => {
          Log.info(TAG, `onPageEnd start`);
          // 延迟加载，避免DOM加载过程闪屏
          setTimeout(() => {
            this.isLoading = false;
          }, 300);
        })
        .onContextMenuShow((event: OnContextMenuShowEvent) => {
          if (event) {
            this.selectText = event.param.getSelectionText();
            this.linkUrl = event.param.getLinkUrl();
            this.menuResult = event.result;
          }
          return true
        })
        .bindContextMenu(this.MenuBuilder, ResponseType.RightClick, {
          onDisappear: () => {
            Log.debug(TAG, 'close menu');
            this.menuResult.closeContextMenu();
          }
        })
        .visibility(!this.isLoading ? Visibility.Visible : Visibility.Hidden)
        .onConsole((event) => {
          Log.info(TAG, event.message.getMessage());
          return true;
        })
        .onTouch((evt) => {
          // 触摸过程中已识别为长按，无需额外处理
          if (AppStorage.get('isInCopy') && evt.type === TouchType.Move) {
            Log.info(TAG, 'onTouch isInCopy and isMoving');
            return;
          }

          this.longPressGestureHandler(evt);
        })
        .javaScriptProxy({
          object: this.viewModel,
          name: 'mailObj',
          methodList: ['onWidthChange', 'onHeightChange', 'onParseStatusChange', 'getPageInfo', 'getWelinkInfoDisplayParams'],
          controller: this.contentWebController
        })
    }
    .width('100%')
    // 最小高度400，避免过小双指无法缩放
    .height(Math.max(this.viewModel.webHeight * this.pageScale, 400))
  }

  @Builder
  DescriptionWeb() {
    Stack({ alignContent: Alignment.Top }) {
      this.DescriptionWebBuilder()
    }
  }

  build() {
    Column() {
      if (this.accountColor !== DEFAULT_NUM && this.accountDisName !== DEFAULT_STR) {
        Account({
          accountColor: this.accountColor,
          accountDisName: this.accountDisName
        })
          .visibility(this.mImportantEventType !== 0 || this.isAgendaCollapse ? Visibility.None : Visibility.Visible)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 8 })
          .backgroundColor($r('sys.color.comp_background_list_card'))
          .borderRadius($r('sys.float.corner_radius_level10'))
      }

      AgendaCollapseButton({
        eventUuid: this.eventUuid,
        isCollapse: this.isAgendaCollapse
      })
        .margin({ bottom: 16 })

      if (this.description && this.description.length > 0 &&
        (!this.isCover || this.agendaTransitionUtil.isEditPageShow)) {
        this.DescriptionWeb();
      }
    }
    .onSizeChange((ov: SizeOptions, nv: SizeOptions) => {
      Log.info(TAG, `onSizeChange, width: ${nv.width}, height: ${nv.height}`);
      if (this.viewModel.parseStatus) {
        this.pageScale = 1;
        return;
      }

      const clientWidth = nv.width as number;
      if (clientWidth > 0) {
        // 0.332 ->0.34,避免高度不足产生滚动
        // eg: 11:49
        this.pageScale = Math.ceil(clientWidth / this.viewModel.webWidth * 100) / 100;
        Log.info(TAG, `onSizeChange, pageScale: ${this.pageScale}`);
      }
    })
  }

  aboutToAppear() {
    this.webContentLoadTimes = 0;
    this.oldDescription = this.description;
    this.navDesInfo = this.queryNavDestinationInfo();
    this.viewModel.setPageInfo(this.navDesInfo)
  }

  deleteImgHTML() {
    let imgs = this.descriptionInView.match(IMG_REGEX)
    if (imgs && imgs.length > 0) {
      for (let img of imgs) {
        this.descriptionInView = this.descriptionInView.replace(img, '')
      }
    }
  }

  setFormHtmlBody() {
    let bodyJSStr = this.description;
    let posS = bodyJSStr.indexOf('<body');

    if (posS != -1) {
      posS = bodyJSStr.indexOf('>', posS + 1) + 1;

      let preBody = bodyJSStr.substring(0, posS);
      let sufBody = bodyJSStr.substring(posS);
      let styleStr = HTML_ADAPTER;
      bodyJSStr = preBody + styleStr + sufBody;
    }

    this.descriptionInView = bodyJSStr;
  }

  loadContentData() {
    try {
      this.setFormHtmlBody();
      this.deleteImgHTML();
      this.contentWebController.loadData(this.descriptionInView, 'text/html', 'UTF-8', 'data');
    } catch (err) {
      Log.logErrorMsg(TAG, 'loadContentData', err);
    }
  }

  /**
   * web容器中右键复制到剪贴板
   * @param agendaEventInfo
   */
  async webCopyToPasteboard() {
    const contents: string = this.selectText || this.linkUrl; // 在这里要么复制文本，要么复制超链接
    PasteHelper.getInstance().clearSystemBoard();
    PasteHelper.getInstance().setSystemBoard(contents);
    return;
  }

  /**
   * 复写url加载策略
   * 检测到跳转时用系统浏览器打开
   */
  loadOverride = (event: Event): boolean => {
    const url = event.data.getRequestUrl();

    if (url.startsWith('data:text/html')) {
      return false
    }
    // 拦截
    this.openExternalBrowser(url);
    return true;
  }

  /**
   * 用外部浏览器打开url链接
   */
  openExternalBrowser = (url: string) => {
    const context = getContext(this) as common.UIAbilityContext;
    const wantInfo: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: url
    };
    context.startAbility(wantInfo);
  }

  onDescriptionChange() {
    Log.debug(TAG, 'onDescriptionChange start');
    //描述为空不触发此逻辑
    if (!this.description || this.description.length === 0) {
      // 此时web容器会取消挂载,故归零计数,从而重新触发初始化
      this.webContentLoadTimes = 0;
      return;
    }

    //组件未挂载或未初始化不需要触发此逻辑
    if (this.webContentLoadTimes === 0) {
      return;
    }

    if (this.oldDescription === this.description) {
      return;
    }

    try {
      this.oldDescription = this.description;
      this.setFormHtmlBody();
      this.deleteImgHTML();
      this.contentWebController.loadData(this.descriptionInView, 'text/html', 'UTF-8', 'data')
    } catch (err) {
      Log.logErrorMsg(TAG, 'loadData fail', err);
    }
  }

  onWindowSizeChange() {
    Log.info(TAG, 'onWindowSizeChange start');

    // 防抖，防止重复触发
    ThrottleFunction.instance().debounce(TAG + ':onWindowSizeChange', (): void => {
      // 窗口变化，重新排版
      this.commonResetWebHeight();
    }, 200)
  }

  // 重置高度
  commonResetWebHeight() {
    try {
      this.contentWebController.runJavaScript(
        'commonResetWebHeight()',
        (error: BusinessError) => {
          if (error) {
            Log.hilogError(TAG, 'runJavaScript', error);
            return;
          }
        });
    } catch (error) {
      Log.hilogError(TAG, 'catch', error);
    }
  }
}

export class EventOtherWelinkInfoViewModel {
  public webWidth: number = 980;
  public webHeight: number = 600;
  public parseStatus: boolean = true;
  public navDesInfo: uiObserver.NavDestinationInfo | undefined;

  public onWidthChange(webWidth: number) {
    Log.info(TAG, `webWidth = ${webWidth}`);
    this.webWidth = webWidth;
  }

  public onHeightChange(webHeight: number) {
    Log.info(TAG, `webHeight = ${webHeight}`);
    this.webHeight = webHeight;
  }

  public onParseStatusChange(parseStatus: boolean) {
    Log.info(TAG, `parseStatus = ${parseStatus}`);
    this.parseStatus = parseStatus;
  }

  public setPageInfo(navDesInfo: uiObserver.NavDestinationInfo | undefined) {
    this.navDesInfo = navDesInfo;
  }

  public getPageInfo() {
    return this.navDesInfo;
  }

  public getWelinkInfoDisplayParams() {
    return DeviceConfig.instance().config.welinKInfoDisplayParams;
  }
}