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
  AgendaEventInfo,
  behaviorEvents,
  CalendarContract,
  CalendarService,
  DeviceConfig,
  EmptyUtils,
  EventService,
  FoldScreenType,
  Log,
  MILLS_PER_DAY,
  statisticEvents
} from '@app/common';
import { FileUtils } from '@app/common/src/main/ets/util/FileUtils';
import Want from '@ohos.app.ability.Want';
import formBindingData from '@ohos.app.form.formBindingData';
import formInfo from '@ohos.app.form.formInfo';
import FormExtensionCallback from '@app/common/src/main/ets/card/FormExtensionCallback';
import dataShare from '@ohos.data.dataShare';
import { ImportantCardConfig, EventMode } from '@app/common/src/main/ets/card/ImportantCardConfig';
import { FormConfigManager } from '@app/common/src/main/ets/card/FormConfigManager';
import { CardType, ReportHiEventParams, ReportUtil } from '@app/common/src/main/ets/default/util/ReportUtil';
import { MonthCardHandler } from '../../monthCard/controller/MonthCardHandler';
import {
  delAndAddDataShareHelper,
  MAX_RETRY_TIMES, PROXY_URI_CALENDAR,
  registerDataShareHelper } from '../../utils/RegisterDataShareHelperUtils';
import { formProvider } from '@kit.FormKit';
import { CardAction } from '../../common/CardAction';
import { display } from '@kit.ArkUI';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import lazy { ImageUtils } from '../util/ImageUtils';
import { i18n } from '@kit.LocalizationKit';
import { DataSource, getQueryColumns } from '../DataSource';
import { notifyImportantCardRefresh } from '../view/pages/ImportantCardEdit';
import { isExpired } from '../view/components/importantCardUtils';

const TAG: string = 'ImportantCardController';

// 卡片刷新时间计算
const REFRESH_BY_DATE: string = `SELECT remindTimer(MIN(min_time) * 1000) FROM (` +
  `SELECT ABS(strftime('%s', datetime('now', 'localtime', 'start of day'), 'UTC')) + ` +
  `${MILLS_PER_DAY} / 1000 as min_time)`;

/**
 * 重要日卡片controller
 */
export class ImportantCardController implements FormExtensionCallback {
  public static FORM_NAME_2x2: string = 'ImportantCard2x2';
  public static FORM_NAME_2x4: string = 'ImportantCard2x4';
  // 标记卡片大小是2x2卡片还是2x4卡片
  private formDimension: FormDimension = FormDimension.Dimension_2_2;

  constructor(formDimension: FormDimension) {
    this.formDimension = formDimension;
  }

  public static initCardUIConfig(formData: Record<string, Object>, formConfig: ImportantCardConfig): void {
    if (!formConfig) {
      Log.error(TAG, `initCardUIConfig get invalid config`);
      return;
    }

    Log.info(TAG, `initCardUIConfig,${formConfig.formId} color = ${formConfig.color}`);

    let importantConfig: CalendarContract.ImportantConfig = {
      backgroundId: formConfig.backgroundId,
      texturesId: formConfig.texturesId,
      layoutId: formConfig.layoutId,
      fontId: formConfig.fontId,
      color: formConfig.color,
      opacity: formConfig.opacity,
      topBright: formConfig.topBright,
      bottomBright: formConfig.bottomBright,
    }
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    formData['importantConfig'] = importantConfig;
    formData['eventMode'] = formConfig.eventMode;
    formData['timeZone'] = viewModel.getSettingData().timeZone;

    try {
      const foldStatus = display.getFoldStatus();
      const foldScreenType: string = systemParameterEnhance.getSync('const.window.foldscreen.type', '0,0,0,0');
      if (foldStatus === display.FoldStatus.FOLD_STATUS_FOLDED &&
        foldScreenType === FoldScreenType.SMALL_UP_DOWN_FOLD) {
        formData['isSmallUp'] = true;
      } else {
        formData['isSmallUp'] = false;
      }
    } catch (err) {
      Log.logErrorMsg(TAG, 'check is small up', err);
    }
    ImportantCardController.initCustomizeImage(formData, formConfig);
  }

  private static initCustomizeImage(formData: Record<string, Object>, formConfig: ImportantCardConfig): void {
    if (!formConfig.customizeImgPath || formConfig.customizeImgPath.length === 0) {
      // 此config无自定义卡片配置
      return;
    }
    const path = ImageUtils.getImportantImagePath(formConfig.customizeImgPath);
    if (!path || path.length === 0) {
      Log.warn(TAG, `initCustomizeImage get invalid path`);
      return;
    }
    const fd = ImageUtils.getImageFdByPath(path);
    if (fd <= 0) {
      Log.warn(TAG, `initCustomizeImage get invalid fd: ${fd}`);
      return;
    }
    let imgMap: Record<string, number> = {};
    const imgId: string = `${fd}`;
    imgMap[imgId] = fd;
    formData['formImages'] = imgMap;
    formData['imageName'] = imgId;
    Log.info(TAG, `initCustomizeImage success imgId: ${imgId}`);
  }

  /**
   * 用于注册数据代理
   * 说明：因onAddForm不支持异步，所以需要先注册一遍基础数据代理，然后异步查询出所有的Columns之后再重新注册新代理
   * @param context context
   * @param formId 卡片唯一标识
   * @param formBinding 卡片数据
   * @param formConfig 卡片配置
   */
  public static async reSetDataProxy(context: Context, formId: string, formBinding: formBindingData.FormBindingData,
    formConfig: ImportantCardConfig): Promise<void> {
    ImportantCardController.setDataProxy(context, formId, formBinding, formConfig);

    const queryColumns = await getQueryColumns();
    ImportantCardController.setDataProxy(context, formId, formBinding, formConfig, queryColumns);
  }

  public static setDataProxy(context: Context, formId: string, formBinding: formBindingData.FormBindingData,
    formConfig: ImportantCardConfig, queryColumns?: string[]): void {
    if (!formConfig) {
      Log.warn(TAG, 'setDataProxy with invalid config');
      return;
    }
    // 准备卡片代理配置
    const dataProxies: DataProxyItem[] = [];
    const hasFixedEventIds: boolean = formConfig.fixedEventIds && formConfig.fixedEventIds.length > 0;
    Log.warn(TAG, `setDataProxy ${formId}, mode=${formConfig.eventMode}, id=${formConfig.fixedEventIds}`);
    if (formConfig.eventMode === EventMode.RECENT_HOLIDAY) {
      dataProxies.push(ImportantCardController.createRecentHolidayProxy(formId, queryColumns?.join(',')));
    } else if (formConfig.eventMode === EventMode.FIXED_IMPORTANT && hasFixedEventIds) {
      dataProxies.push(ImportantCardController.createFixedImportantProxy(formId,
        formConfig.fixedEventIds, queryColumns?.join(',')));
    } else if (formConfig.eventMode === EventMode.FIXED_BIRTHDAY && hasFixedEventIds) {
      dataProxies.push(ImportantCardController.createFixedBirthdayProxy(formId,
        formConfig.fixedEventIds, queryColumns));
    } else if (formConfig.eventMode === EventMode.FIXED_HOLIDAY && hasFixedEventIds) {
      dataProxies.push(ImportantCardController.createFixedHolidayProxy(formId,
        formConfig.fixedEventIds, queryColumns?.join(',')));
    } else {
      Log.warn(TAG, `setDataProxy ${formId}, unknown mode: ${formConfig.eventMode}`);
      // 卡片初始加桌，需至少设置一个卡片代理，否则后续动态设置刷新的代理无法生效
      dataProxies.push(ImportantCardController.createRecentHolidayProxy(formId, queryColumns?.join(',')));
    }

    if (EmptyUtils.isEmptyArray(queryColumns)) {
      dataProxies.forEach((item) => {
        registerDataShareHelper(context, item.subscriberId, item.template, MAX_RETRY_TIMES);
      });
    } else {
      dataProxies.forEach((item) => {
        delAndAddDataShareHelper(context, item.subscriberId, item.template, MAX_RETRY_TIMES);
      });
    }

    // 将卡片代理配置进formBindingData中
    const proxies: formBindingData.ProxyData[] = [];
    dataProxies.forEach((item) => {
      proxies.push(item.proxy);
    });
    formBinding['proxies'] = proxies;
  }

  /**
   * 创建代理配置
   *
   * @param formId 卡片ID，作为subscriberId
   * @param subscriberSuffix 订阅ID的后缀
   * @param selection 查询条件
   * @param eventTypes 事件类型
   * @param dataKey 代码返回数据的字段名
   * @returns DataProxyItem
   */
  private static createDataProxyItem(
    formId: string,
    subscriberSuffix: number,
    dataKey: string,
    querySql: string
  ): DataProxyItem {
    // 预防克隆或升级场景formId过长导致template出现undefined问题
    const subscriberId: string = `${formId.slice(0, -1)}${subscriberSuffix}`;
    const predicates: Record<string, string> = {};
    predicates[dataKey] = querySql;
    return {
      uri: PROXY_URI_CALENDAR,
      subscriberId: subscriberId,
      template: {
        predicates: predicates,
        scheduler: REFRESH_BY_DATE
      },
      proxy: {
        'key': PROXY_URI_CALENDAR,
        'subscriberId': subscriberId
      }
    };
  }

  /**
   * 准备近期节假日的数据代理相关配置
   *
   * @param formId 卡片ID，作为subscriberId
   * @returns DataProxyItem
   */
  private static createRecentHolidayProxy(formId: string, queryColumns?: string): DataProxyItem {
    const querySql: string = DataSource.getRecentHolidayProxy(queryColumns);
    return ImportantCardController.createDataProxyItem(formId, SubscriberId.RECENT_HOLIDAY, 'recentHolidayList', querySql);
  }

  /**
   * 准备固定重要日的数据代理相关配置
   *
   * @param formId 卡片ID，作为subscriberId
   * @param eventIds 指定的日程ID数组
   * @returns DataProxyItem
   */
  private static createFixedImportantProxy(formId: string, eventIds: number[], queryColumns?: string): DataProxyItem {
    const querySql: string = DataSource.getFixedImportantProxy(eventIds, queryColumns);
    return ImportantCardController.createDataProxyItem(formId, SubscriberId.FIXED_IMPORTANT, 'fixedImportantList', querySql);
  }

  /**
   * 准备固定节假日的数据代理相关配置
   *
   * @param formId 卡片ID，作为subscriberId
   * @param eventIds 指定的日程ID数组
   * @returns DataProxyItem
   */
  private static createFixedHolidayProxy(formId: string, eventIds: number[], queryColumns?: string): DataProxyItem {
    const querySql: string = DataSource.getFixedHolidayProxy(eventIds, queryColumns);
    return ImportantCardController.createDataProxyItem(formId, SubscriberId.FIXED_HOLIDAY, 'fixedHolidayList', querySql);
  }

  /**
   * 准备固定生日的数据代理相关配置
   *
   * @param formId 卡片ID，作为subscriberId的一部分
   * @param eventIds 指定的日程ID数组
   * @returns 代理配置DataProxyItem
   */
  private static createFixedBirthdayProxy(formId: string, eventIds: number[], queryColumns?: string[]): DataProxyItem {
    const querySql: string = DataSource.getFixedBirthdayProxy(eventIds, queryColumns);
    return ImportantCardController.createDataProxyItem(formId, SubscriberId.FIXED_BIRTHDAY, 'fixedBirthdayList', querySql);
  }

  onAddForm(context: Context, want: Want): formBindingData.FormBindingData {
    let parameter: object | undefined = want.parameters;
    let formId: string = '';
    let formWidth: number = 0;
    let formHeight: number = 0;
    if (parameter) {
      formId = parameter[formInfo.FormParam.IDENTITY_KEY] as string;
      formWidth = parameter[formInfo.FormParam.WIDTH_KEY] as number;
      formHeight = parameter[formInfo.FormParam.HEIGHT_KEY] as number;
    }
    Log.info(TAG, `onAddForm formId: ${formId} start`);
    if (!formId || formId.length == 0) {
      Log.error(TAG, 'onAddForm formId is invalid');
      return formBindingData.createFormBindingData();
    }
    const formData: Record<string, Object> = {};
    const singleFormId = BigInt.asIntN(32, BigInt(formId)).toString();
    Log.info(TAG, `onAddForm fromId: ${formId}, singleFormId: ${singleFormId}`);
    const isCard2x2 = this.formDimension === FormDimension.Dimension_2_2;
    DeviceConfig.instance().init();
    const viewModel = MonthCardHandler.instance().getMonthCardVM();
    formData['needCommerce'] = DeviceConfig.instance().config.needCommerce;
    const formConfig: ImportantCardConfig = FormConfigManager.getImportantCardConfig(singleFormId, isCard2x2);
    formData['formWidth'] = formWidth;
    formData['formHeight'] = formHeight;
    formData['formId'] = formId;
    formData['language'] = i18n.System.getSystemLocale();
    formData['timeZone'] = viewModel.getSettingData().timeZone;
    const isAgreeStatement = viewModel.getSettingData().isAgreeStatement;
    formData['isAgreeStatement'] = isAgreeStatement;
    const isDoubleUpSingleAgreeStatement = MonthCardHandler.instance().getDoubleUpSingleAgreeStatement(formId);
    formData['isDoubleUpSingleAgreeStatement'] = isDoubleUpSingleAgreeStatement;
    Log.info(TAG, `onAddForm formId: ${formId}, isAgreeStatement = ${isAgreeStatement},` +
      `isDoubleUpSingleAgreeStatement = ${isDoubleUpSingleAgreeStatement}, dim=${this.formDimension}`);
    ImportantCardController.initCardUIConfig(formData, formConfig);

    let formBinding: formBindingData.FormBindingData = formBindingData.createFormBindingData(formData);
    ImportantCardController.reSetDataProxy(context, formId, formBinding, formConfig);
    this.reportFaStatistic(formId, 'create')
    this.reportImportantCardAdd();
    Log.info(TAG, `onAddForm formId: ${formId} end`);
    return formBinding;
  }

  onCastToNormalForm(context: Context, formId: string) {
  }

  onUpdateForm(context: Context, formId: string) {
    Log.info(TAG, `onUpdateForm formId: ${formId} start`);
    let params: ReportHiEventParams = {
      TYPE: this.formDimension === FormDimension.Dimension_2_2 ? CardType.IMPORTANT_CARD_2X2
        : CardType.IMPORTANT_CARD_2X4,
      FORM_ID: formId
    };
    ReportUtil.reportBehaviorEvent(behaviorEvents.cardRefresh, params);
    Log.info(TAG, `onUpdateForm formId: ${formId} end`);

    formProvider.updateForm(formId, formBindingData.createFormBindingData({
      'language': i18n.System.getSystemLocale()
    }));
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>) {
  }

  onFormEvent(context: Context, formId: string, message: string) {
    Log.info(TAG, `onFormEvent formId:${formId},message is ${message}`);
    if (!message) {
      return;
    }
    try {
      const msg: object = JSON.parse(message);
      if (!msg) {
        Log.info(TAG, `onFormEvent get invalid msg, dim=${this.formDimension}`);
        return;
      }
      const params: object = msg['params'];
      if (!params) {
        Log.info(TAG, `onFormEvent get invalid param, dim=${this.formDimension}`);
        return;
      }
      if (params['message'] === CardAction.FINISH_FIRST_DATA_PROCESSING) {
        Log.info(TAG, 'setIsDataProcessedFirstTime')
        formProvider.updateForm(formId, formBindingData.createFormBindingData({
          'isDataProcessedFirstTime': true
        }));
      } else if (params['message'] === CardAction.CALCULATE_IMPORTANT_CARD_MODE) {
        const formName: string = params['formName'] ?? 'ImportantCardView2x2';
        this.calculateEventMode(context, formId, formName);
      }
    } catch (e) {
      Log.hilogError(TAG, 'onFormEvent error', e)
    }
    Log.info(TAG, `onFormEvent formId: ${formId} end`);
  }

  onRemoveForm(context: Context, formId: string) {
    this.reportImportantCardRemove(formId);
    this.removeCustomizeImg(formId);
  }

  private removeCustomizeImg(formId: string) {
    // 删除重要日卡片可能存在的自定义背景图片
    const config = FormConfigManager.getImportantCardConfig(formId);
    if (!config) {
      Log.warn(TAG, `removeCustomizeImg get invalid config`);
      return;
    }
    const customizeImgPath: string = config.customizeImgPath;
    if (!customizeImgPath || customizeImgPath.length === 0) {
      // 该卡片无自定义背景
      return;
    }
    const realPath: string = ImageUtils.getImportantImagePath(customizeImgPath);
    if (!realPath || realPath.length === 0) {
      Log.warn(TAG, `removeCustomizeImg get invalid path`);
      return;
    }
    const deleteResult = FileUtils.deleteFile(realPath);
    Log.info(TAG, `removeCustomizeImg delete result=${deleteResult}`);
  }

  onAcquireFormState(context: Context, want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  reportFaStatistic(formId: string, action: string) {
    let params: ReportHiEventParams = {
      FA_DIMENSION: this.formDimension
    }
    if (action === 'create') {
      ReportUtil.reportStatisticEvent(statisticEvents.createImportantFa, params);
    } else {
      ReportUtil.reportStatisticEvent(statisticEvents.deleteImportantFa, params);
    }
  }

  reportImportantCardAdd() {
  }

  reportImportantCardRemove(formId: string) {
    this.reportFaStatistic(formId, 'delete');
  }

  private async calculateEventMode(
    context: Context,
    formId: string,
    formName: string,
  ): Promise<void> {
    const singleFormId = BigInt.asIntN(32, BigInt(formId)).toString();
    const isCard2x2 = this.formDimension === FormDimension.Dimension_2_2;
    const formConfig: ImportantCardConfig = FormConfigManager.getImportantCardConfig(singleFormId, isCard2x2);
    formConfig.formName = formName;
    const hasOriginalFixedIds: boolean = formConfig.fixedEventIds && formConfig.fixedEventIds.length > 0;
    Log.warn(TAG, `calculateEventMode, formId: ${formId}/${singleFormId}, hasOriginalFixedIds: ${hasOriginalFixedIds}, ` +
      `current eventMode/fixedEventIds: ${formConfig.eventMode}/${formConfig.fixedEventIds}`);
    let needRefreshCard: boolean = false;
    if (hasOriginalFixedIds) {
      // 有fixedEventId分两种情况：1、历史升级上来，有固定日程，但eventMode为default，需要升级设置eventMode；2、已升级eventMode，view层误调
      needRefreshCard = await this.setEventModeWithFixedEventId(singleFormId, formConfig, formConfig.fixedEventIds[0]);
    } else {
      // 无fixedEventId分两种情况：1、eventMode为近期节日模式；2、非近期模式且无fixedEventId，则卡片处于错误状态，需要重置
      needRefreshCard = await this.setEventModeWithoutFixedEventId(singleFormId, formConfig);
    }
    if (needRefreshCard) {
      Log.warn(TAG, `calculateEventMode refreshCard ${formId}, ${formConfig.eventMode}/${formConfig.fixedEventIds}`);
      notifyImportantCardRefresh(context, formId, isCard2x2, formConfig);
    }
  }

  /**
   * config中有固定的日程id，根据日程id是否能找到，以及日程id是什么类型数据，以及当前卡片状态，决定是否要变更卡片状态，以及变更成什么状态：
   * 1、日程id找不到，则是日程被删除场景，需要按默认逻辑重新刷新卡片到新的状态；
   * 2、如果卡片不是default状态，且日程id也存在，则无需做任何变更；
   * 3、日程id能找到，判断卡片是否为default状态，如果是default状态，则认为是升级场景，需做如下处理：
   *  1）判断固定的日程是重要日，则将卡片设置为fixed_important状态；
   *  2）判断固定的日程是生日，则将卡片设置为fixed_birthday；
   *  3）如果不是以上两种情况，则将卡片设置为近期节日模式；
   *
   * @param formId
   * @param formConfig
   * @param fixedEventId
   * @returns
   */
  private async setEventModeWithFixedEventId(formId: string, formConfig: ImportantCardConfig, fixedEventId: number):
    Promise<boolean> {
    const agendaEventInfo = await EventService.INSTANCE.queryEventById(fixedEventId);
    if (!agendaEventInfo || !agendaEventInfo.isValid()) {
      Log.warn(TAG, 'query with fixedEventId not found');
      // 配置中有fixedEventId，但是数据库中找不到了，卡片需要根据当前数据重置
      return this.setNewEventModeByCurrentData(formId, formConfig);
    }
    if (isExpired(agendaEventInfo, fixedEventId)) {
      Log.warn(TAG, `${formId}'s fixed event ${fixedEventId} is expired`);
      // 日程过期，按当前规格，等同于删除，卡片需要根据当前数据重置
      return this.setNewEventModeByCurrentData(formId, formConfig);
    }
    if (formConfig.eventMode && formConfig.eventMode !== EventMode.DEFAULT) {
      // fixedEventId对应数据在数据库中存在，且eventMode不是default，则表示是view层误调，不予回应处理
      Log.info(TAG, `${formId} eventMode ${formConfig.eventMode} no need change`);
      return false;
    }
    // 如果fixedEventId对应的数据在数据库中存在，但eventMode为default，表示是升级场景，根据数据类型设置为相应模式
    if (agendaEventInfo.mImportantEventType === CalendarContract.EventImportantType.HOLIDAY) {
      formConfig.eventMode = EventMode.RECENT_HOLIDAY;
      ImportantCardConfig.setFixedEventIds(formConfig, []);
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, 'setEventModeWithFixedEventId recent holiday');
      return true;
    }
    if (agendaEventInfo.isImportantEvent()) {
      formConfig.eventMode = EventMode.FIXED_IMPORTANT;
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, `setEventModeWithFixedEventId fix important: ${fixedEventId}`);
      return true;
    }
    const calendar = await CalendarService.INSTANCE.queryCalendarById(agendaEventInfo.mCalendarId);
    if (calendar && calendar.accountType === CalendarContract.CalendarType.BIRTHDAY) {
      formConfig.eventMode = EventMode.FIXED_BIRTHDAY;
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, `setEventModeWithFixedEventId fix birthday: ${fixedEventId}`);
      return true;
    }
    Log.error(TAG, `setEventMode ${formId} with unknown type event: ${fixedEventId}/${calendar?.accountType}`);
    return false;
  }

  /**
   * 无fixedEventId分两种情况，一种是近期节日模式，一种是id被删除，一种是UNKNOWN_BIRTHDAY
   *
   * @param formId 卡片id
   * @param formConfig 卡片config
   * @returns 是否需要刷新卡片
   */
  private async setEventModeWithoutFixedEventId(formId: string, formConfig: ImportantCardConfig): Promise<boolean> {
    if (formConfig.eventMode === EventMode.RECENT_HOLIDAY) {
      const holidayList = await DataSource.queryRecentHoliday();
      if (holidayList && holidayList.length > 0) {
        // 近期节日模式，检查数据库中存在节日数据，则不予处理
        return false;
      } else {
        // 近期节日模式，但数据库中已无节日数据，则需要刷新重置卡片
        return this.setNewEventModeByCurrentData(formId, formConfig);
      }
    } else if (formConfig.eventMode === EventMode.UNKNOWN_BIRTHDAY) {
      Log.info(TAG, 'setEventModeWithoutFixedEventId current eventMode is unknown_birthday');
      return false;
    } else {
      // 卡片进入了错误状态，走此分支进行恢复重置
      return this.setNewEventModeByCurrentData(formId, formConfig);
    }
  }

  /**
   * 按照默认规则设置新的卡片状态：
   * 1、有重要日则固定为最近重要日；
   * 2、有生日则固定为最近生日；
   * 3、无重要日或生日，则设置为近期节日；
   *
   * @param formId 卡片id
   * @param formConfig 卡片config
   * @returns 是否需要刷新卡片
   */
  private async setNewEventModeByCurrentData(formId: string, formConfig: ImportantCardConfig): Promise<boolean> {
    const importantList: AgendaEventInfo[] = await DataSource.queryRecentImportant();
    if (importantList && importantList.length > 0) {
      // 设置为固定重要日
      formConfig.eventMode = EventMode.FIXED_IMPORTANT;
      const fixedEventId: number = importantList[0].mId;
      ImportantCardConfig.setFixedEventIds(formConfig, [fixedEventId]);
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, `setNewEventModeByCurrentData fix important: ${fixedEventId}`);
      return true;
    }
    const birthdayList = await DataSource.queryRecentBirthday();
    if (birthdayList && birthdayList.length > 0) {
      // 设置为固定生日
      formConfig.eventMode = EventMode.FIXED_BIRTHDAY;
      const fixedEventId: number = birthdayList[0].mId;
      ImportantCardConfig.setFixedEventIds(formConfig, [fixedEventId]);
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, `setNewEventModeByCurrentData fix birthday: ${fixedEventId}`);
      return true;
    }
    const holidayList = await DataSource.queryRecentHoliday();
    if (holidayList && holidayList.length > 0) {
      formConfig.eventMode = EventMode.RECENT_HOLIDAY;
      ImportantCardConfig.setFixedEventIds(formConfig, []);
      FormConfigManager.saveImportantCardConfig(formId, formConfig);
      Log.info(TAG, 'setNewEventModeByCurrentData recent holiday');
      return true;
    }
    Log.warn(TAG, 'setNewEventModeByCurrentData do nothing');
    return false;
  }
}

interface DataProxyItem {
  uri: string;
  subscriberId: string;
  template: dataShare.Template;
  proxy: formBindingData.ProxyData;
}

enum SubscriberId {
  DEFAULT = 0,
  RECENT_IMPORTANT = 1,
  FIXED_IMPORTANT = 2,
  RECENT_HOLIDAY = 3,
  FIXED_HOLIDAY = 4,
  RECENT_BIRTHDAY = 5,
  FIXED_BIRTHDAY = 6
}