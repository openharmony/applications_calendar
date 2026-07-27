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

import { Log } from '../default/common/Log';
import { factory, Service } from '../service/framework/Service';
import { CommonInnerEvent } from '../event/CommonInnerEvent';
import { HashMap } from '@kit.ArkTS';
import { BusinessError, commonEventManager, emitter } from '@kit.BasicServicesKit';
import { i18n } from '@kit.LocalizationKit';
import { ServiceEnum } from '../service/framework/ServiceEnum';
import { ThrottleFunction } from '../util/FunctionUtil';
import { CalendarDate } from '../date/CalendarDate';
import { EmitterCollector } from '../util/EmitterCollector';
import { sendBroadcast } from '../util/broadcast/BroadcastHelper';
import { CommonEventAction } from '../util/broadcast/CommonEventAction';

// 系统订阅接口的封装
/* instrument ignore file */

const TAG: string = 'SysWrapperServiceImpl';
const COMMON_EVENT_DATA_CHANGED: string = 'calendardata.DATA_CHANGED';
const HWID_LOGIN: string = 'common.event.HWID_LOGIN';
const HWID_LOGOUT: string = 'common.event.HWID_LOGOUT';
const ACTIVATE_THEME_EVENT: string = 'com.ohos.ActivateTheme';
const CLICK_STATUSBAR: string = 'usual.event.CLICK_STATUSBAR';
const PACKAGE_REMOVED: string = 'usual.event.PACKAGE_REMOVED';
const PACKAGE_ADDED: string = 'usual.event.PACKAGE_ADDED';

@factory(ServiceEnum.SYS_WRAPPER_SERVICE)
export class SysWrapperService extends Service {
  private systemEventSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private calendarDataEventSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private localeEventSubscriber: commonEventManager.CommonEventSubscriber | undefined = undefined;
  private curDate: CalendarDate = new CalendarDate();

  private emitterCollector : EmitterCollector = new EmitterCollector();

  async subscribeSystemEvent(): Promise<void> {
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_TIME_CHANGED, // date hour 12-hour-circle
        commonEventManager.Support.COMMON_EVENT_TIME_TICK,
        commonEventManager.Support.COMMON_EVENT_TIMEZONE_CHANGED,
        commonEventManager.Support.COMMON_EVENT_SCREEN_UNLOCKED, // 屏幕解锁事件监听
        HWID_LOGIN,
        HWID_LOGOUT,
        ACTIVATE_THEME_EVENT,
        CLICK_STATUSBAR,
        PACKAGE_REMOVED,
        PACKAGE_ADDED
      ],
    };

    const localeSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED,
      ],
      publisherPermission: 'usual.event.LOCALE_CHANGED', //设置订阅权限
    };

    const dateSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [
        COMMON_EVENT_DATA_CHANGED
      ],
    };

    try {
      this.systemEventSubscriber = await commonEventManager.createSubscriber(subscribeInfo);
      this.localeEventSubscriber = await commonEventManager.createSubscriber(localeSubscribeInfo);
      this.calendarDataEventSubscriber = await commonEventManager.createSubscriber(dateSubscribeInfo);

      this.subscribeEvent();
    } catch (err) {
      Log.logErrorMsg(TAG, 'subscribeCommonEvent', err);
    }
  }

  protected async doStart(): Promise<void> {
    Log.info(TAG, `${this.name} dostart`);
    await this.subscribeSystemEvent();
    // 通知订阅更新
    this.emitterCollector.on({ eventId: CommonInnerEvent.NOTICE_SUBSCRIPTION_UPDATE },
      this.handleUpdateSubscribeAtomic);
  }

  protected async doStop(): Promise<void> {
    Log.info(TAG, `${this.name} doStop`);
    this.unSubscribeSystemEvent();
    this.emitterCollector.off();
  }

  /**
   * 通知订阅元服务更新
   */
  private handleUpdateSubscribeAtomic: (eventData?: emitter.EventData) => void =
    async (eventData?: emitter.EventData): Promise<void> => {
      try {
        Log.info(TAG, `handleUpdateSubscribeAtomic ${eventData?.data?.length}`);
        const dateSubscribeInfo: commonEventManager.CommonEventPublishData = {
          data: JSON.stringify(eventData?.data ?? [])
        };
        await sendBroadcast(CommonEventAction.SUBSCRIPTION_NOTICE_SUBSCRIBE_ATOMIC,
          dateSubscribeInfo, (error, sendResult) => {
          Log.info(TAG, `handleUpdateSubscribeAtomic sendBroadCast sendResult is ${sendResult}`);
        });
      } catch (error) {
        Log.logErrorMsg(TAG, `sendBroadCast error`, error);
      }
    };

  private subscribeEvent(): void {
    commonEventManager.subscribe(this.systemEventSubscriber, (err: BusinessError, data) => {
      if (err) {
        Log.error(TAG, `subscribe system event error ${err?.message}`);
        return;
      }

      Log.info(TAG, `receive system event ${data.event}`);
      Throttle.instance().runTask(data, () => this.handleSystemEvents(data));
    });
    commonEventManager.subscribe(this.calendarDataEventSubscriber, (err: BusinessError, data) => {
      if (err) {
        Log.error(TAG, `subscribe calendardata event error ${err?.message}`);
        return;
      }

      Log.info(TAG, `receive calendardata event ${data.event} ${data.parameters?.table}`);
      this.handleDataChange(data);
    });
    commonEventManager.subscribe(this.localeEventSubscriber,
      (err: BusinessError, data: commonEventManager.CommonEventData) => {
        if (err) {
          Log.error(TAG, `subscribe locale event error ${err?.message}`);
          return;
        }

        Log.info(TAG, `receive locale event ${data.event}`);
        Throttle.instance().runTask(data, () => this.handleSystemEvents(data));
      });
  }

  private handleDataChange(data: commonEventManager.CommonEventData): void {
    Throttle.instance()
      .runTask(data, () => emitter.emit({ eventId: CommonInnerEvent.SYSTEM_DATA_CHANGED }, { data: data.parameters }));
    return;
  }

  private handleSystemEvents(data: commonEventManager.CommonEventData): void {
    switch (data.event as string) {
      case commonEventManager.Support.COMMON_EVENT_TIME_CHANGED:
        this.handleTimeChange();
        break;
      case commonEventManager.Support.COMMON_EVENT_SCREEN_UNLOCKED:
      case commonEventManager.Support.COMMON_EVENT_TIME_TICK:
        this.handleTimeTick();
        break;
      case commonEventManager.Support.COMMON_EVENT_TIMEZONE_CHANGED:
        this.handleTimeZoneChange();
        break;
      case commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED:
        this.handleLocaleChange();
        break;
      case HWID_LOGIN:
        this.handleAccountLogin(true);
        break;
      case HWID_LOGOUT:
        this.handleAccountLogin(false);
        break;
      case ACTIVATE_THEME_EVENT:
        this.handleActiveTheme(data);
        break;
      case CLICK_STATUSBAR:
        this.handleClickStatusBar();
        break;
      case PACKAGE_REMOVED:
      case PACKAGE_ADDED:
        break;
      default:
        break;
    }
  }

  private handleTimeChange(): void {
    if (this.checkHourCycleChange()) {
      return;
    }

    this.checkDateChange();
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_TIME_CHANGED });
  }

  private handleTimeTick(): void {
    this.checkDateChange();
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_TIME_TICK });
  }

  private handleTimeZoneChange(): void {
    Log.info(TAG, 'handleTimeZoneChange');
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_TIMEZONE_CHANGED });
  }

  private handleLocaleChange(): void {
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_LOCALE_CHANGED });
  }

  private unSubscribeSystemEvent(): void {
    if (this.systemEventSubscriber) {
      commonEventManager.unsubscribe(this.systemEventSubscriber);
    }
    if (this.calendarDataEventSubscriber) {
      commonEventManager.unsubscribe(this.calendarDataEventSubscriber);
    }
    if (this.localeEventSubscriber) {
      commonEventManager.unsubscribe(this.localeEventSubscriber);
    }
  }

  private checkDateChange(): void {
    const nowDate: CalendarDate = new CalendarDate(); // 根据当前系统时区获取日期
    if (nowDate.getFullYear() === this.curDate.getFullYear() &&
      nowDate.getMonth() === this.curDate.getMonth() &&
      nowDate.getDate() === this.curDate.getDate()) {
      Log.info(TAG, `checkDateChange: same nowDate:${nowDate.toDateString()} curDate:${this.curDate.toDateString()}`);
      return;
    }
    this.curDate = nowDate;
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_DATE_CHANGED });
  }

  private checkHourCycleChange(): boolean {
    const is24HourClock: boolean = i18n.System.is24HourClock();
    if (AppStorage.get<boolean>('is24HourClock') === is24HourClock) {
      return false;
    }

    AppStorage.setOrCreate('is24HourClock', is24HourClock);
    emitter.emit({ eventId: CommonInnerEvent.SYSTEM_HOUR_CYCLE_CHANGED });
    return true;
  }

  private handleAccountLogin(isLogin: boolean): void {
    emitter.emit({ eventId: isLogin ? CommonInnerEvent.SYSTEM_HWID_LOGIN : CommonInnerEvent.SYSTEM_HWID_LOGOUT });
    AppStorage.setOrCreate('isAccountLogin', isLogin);
  }

  private handleActiveTheme(data: commonEventManager.CommonEventData): void {
    Log.info(TAG, `handleActiveTheme`);
    if (data.parameters && data.parameters.fonts === 1) { //fonts=1表示字体有变化
      emitter.emit({ eventId: CommonInnerEvent.THEME_FONT_CHANGE });
    }
  }

  private handleClickStatusBar(): void {
    emitter.emit({ eventId: CommonInnerEvent.CLICK_STATUSBAR });
  }
}


/**
 * 用于防止短时间大量广播导致应用卡死的措施
 */
class Throttle {
  private static _instance: Throttle = new Throttle();

  private readonly defaultLimit: number = 200;

  private readonly syncLimit: number = 5000;

  private runningMap: HashMap<string, number> = new HashMap();

  private lastRunTime: HashMap<string, number> = new HashMap();

  static instance(): Throttle {
    return Throttle._instance;
  }

  runTask(data: commonEventManager.CommonEventData, task: Function): void {
    const table: string = data?.parameters?.table ?? data?.event ?? 'null';
    const isFromSync: boolean = data?.parameters?.isFromSync ?? false;
    let checkString: string = `${table}${isFromSync}`;
    if (isFromSync) {
      this.runTaskForSyncScene(checkString, task, this.syncLimit);
    } else {
      this.runTaskForNormalScene(checkString, task, this.defaultLimit);
    }
  }

  private runTaskForNormalScene(tag: string, task: Function, delay: number): void {
    if (this.runningMap.hasKey(tag)) {
      Log.debug(TAG, `an action is block! ${tag}`);
      return;
    }

    // 非同步场景，按原先逻辑，统一delay 200ms后执行
    this.runWithDelay(tag, task, delay);
  }

  /**
   * 同步场景执行task的逻辑处理：
   * 1、单条广播，直接执行task；
   * 2、多条广播，第一次直接执行task；随后的广播5-10s内会被执行；若一直有task进来，则约每5s执行一次
   * （广播间隙超过5s会直接执行，小于5s会取消之前delay任务重新delay，最多不超过10s）
   *
   * @param tag task任务状态/计时标记为，取表名+sync标记
   * @param task 将被执行的广播处理任务
   * @param delay delay时间，目前固定5s
   */
  private runTaskForSyncScene(tag: string, task: Function, delay: number): void {
    if (this.runningMap.hasKey(tag)) {
      // 非首次，先取消之前的delay task，然后依据任务间隙做不同处理
      clearTimeout(this.runningMap.get(tag));
      this.runningMap.remove(tag);

      if (Date.now() - this.lastRunTime.get(tag) > delay) {
        // 若已距离上次执行task时间超过delay时间，当做初次执行处理
        this.firstRun(tag, task, delay);
      } else {
        // 若还在delay限制时间内，重新delay一段时间后执行
        this.runWithDelay(tag, task, delay);
      }
    } else {
      // 初次收到tag，先执行，并delay时间内标记正在执行
      this.firstRun(tag, task, delay);
    }
  }

  private firstRun(tag: string, task: Function, delay: number): void {
    // 初次执行任务，先执行task，并记录任务执行时间
    task();
    this.lastRunTime.set(tag, Date.now());
    Log.info(TAG, `DataChangeEvent -> run task ${tag}`);

    // 并在delay时间内仍标记正在执行
    const timeoutId = setTimeout((): void => {
      // 清理正在执行的标记
      clearTimeout(timeoutId);
      this.runningMap.remove(tag);
    }, delay);
    this.runningMap.set(tag, timeoutId);
  }

  private runWithDelay(tag: string, task: Function, delay: number): void {
    // delay时间后执行任务
    const timeoutId = setTimeout(() => {
      // 清理正在执行的标记
      clearTimeout(timeoutId);
      this.runningMap.remove(tag);

      // 执行任务，并记录任务执行时间
      task();
      this.lastRunTime.set(tag, Date.now());
      Log.info(TAG, `DataChangeEvent -> delay run task ${tag}`);
    }, delay);
    this.runningMap.set(tag, timeoutId);
  }
}