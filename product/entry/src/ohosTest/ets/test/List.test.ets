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

import MainAbilityTest from './abilities/MainAbility.test';
// import account Start
import AccountCommonTest from './account/AccountCommon.test';
// import account End
// import common_date Start
import DateTest from './common/date/Date.test';
import DateUtilTest from './common/date/DateUtil.test';
import DateRangeTest from './common/date/DateRange.test';
import DateManagerTest from './common/date/DateManager.test';
import FestivalTest from './common/date/FestivalData.test';
import CalendarDateTest from './common/date/CalendarDate.test';
// import common_date End
// import common/layout Start
import BreakPoint2DTest from './common/layout/BreakPoint2D.test';
import LayoutRuleTest from './common/layout/LayoutRule.test';
import LayoutModelTest from './common/layout/LayoutModel.test';
import LayoutPropTest from './common/layout/LayoutProp.test';
import GlobalEnvTest from './common/layout/GlobalEnv.test';
import LayoutModelEnvTest from './common/layout/LayoutModelEnvTest.test';
import LayoutTreeModelTest from './common/layout/LayoutModelTree.test';
// import common/layout End
// import common/calendar Start
import CalendarUtilsTest from './common/calendar/CalendarUtils.test';
// import common/calendar End
// import common/util Start
import GlobalDataTest from './common/data/GlobalData.test';
import DeviceConfigTest from './common/data/DeviceConfig.test';
import CombineAnimateParamTest from './common/data/CombineAnimateParam.test';
import GlobalThisTest from './common/data/GlobalThis.test';
import ThrottleFunctionTest from './common/util/ThrottleFunction.test';
import CommonUtilsTest from './common/util/CommonUtils.test';
import TimeZoneUtilTest from './common/util/TimeZoneUtil.test';
import SensitiveStrUtilTest from './common/util/SensitiveStrUtils.test';
import RecurrenceImportantAdaptTest from './common/RecurrenceImportantAdapt.test';
import AccountUtilsTest from './common/AccountUtils.test';
import AgendaEventInfoTest from './common/AgendaEventInfo.test';
import ShareUtilsTest from './common/util/ShareUtil.test';
import Base64UtilTest from './common/util/Base64Util.test';
import GetDayOffsetTest from './common/util/GetDayOffset.test';
import GetYearDayOffset from './common/util/GetYearDayOffset.test';
import UtilTest from './common/util/Util.test';
import NetWorkMangerTest from './common/util/NetWorkManger.test';
import NotificationHelperTest from './common/commoncapability/NotificationHelper.test';
import PreferencesUtilTest from './common/util/PreferencesUtil.test';
import FileUtilsTest from './common/util/FileUtils.test';
import InitializeHelperTest from './common/InitializeHelper.test';
import I18nUtilTest from './common/util/I18nUtil.test';
import HttpUtilsTest from './common/util/HttpUtils.test';
import WorkSchedulerHelperTest from './common/WorkSchedulerHelper.test';
import ResultTest from './common/data/Result.test';
import AbilityStateHelperTest from './common/util/AbilityStateHelper.test';
import LunarDateUtilTest from './common/date/LunarDateUtil.test';
import FontSizeScaleUtilsTest from './common/util/FontSizeScaleUtil.test';
import AgendaTransitionUtilTest from './common/util/AgendaTransitionUtil.test';
import StringUtilsTest from './common/util/StringUtils.test';
import TypeUtilsTest from './common/util/TypeUtils.test';
import WindowSizeManagerTest from './common/util/WindowSizeManager.test';
import ImageUtilTest from './common/util/ImageUtil.test';
import EmitterCollectorTest from './common/util/EmitterCollector.test';
import PhoneNumberUtilsTest from './common/util/PhoneNumberUtils.test';
import TimeZoneServiceImplTest from './common/util/TimeZoneServiceImpl.test';
import NumberFormatManagerTest from './common/util/NumberFormatManager.test'
// import common/util End
// import common/dao Start
import EventServiceTest from './common/dao/EventService.test';
import AttendeeServiceTest from './common/dao/AttendeeService.test';
import CalendarCacheServiceTest from './common/dao/CalendarCacheService.test';
import CloudUtilsTest from './common/dao/CloudUtils.test';
import CalendarServiceTest from './common/dao/CalendarService.test';
import OneLinkServiceTest from './common/dao/OneLinkService.test';
import ReminderServiceTest from './common/dao/ReminderService.test';
import EventRepositoryTest from './common/dao/repo/EventRepository.test';
import OneLinkRepositoryTest from './common/dao/repo/OneLinkRepository.test';
import ReminderRepositoryTest from './common/dao/repo/ReminderRepository.test';
import CalendarRepositoryTest from './common/dao/repo/CalendarRepository.test';
import InstanceRepositoryTest from './common/dao/repo/InstanceRepository.test';
import BaseVersionDBHelperTest from './common/dao/database/BaseVersionDBHelper.test';
import BaseDBHelperTest from './common/dao/database/BaseDBHelper.test';
import DBUtilsTest from './common/dao/database/DBUtils.test';
import LockTimeZoneInfoTest from './common/dao/model/LockTimeZoneInfo.test';
import CalendarCacheParserTest from './common/dao/parsers/CalendarCacheParser.test';
// import common/dao End
// import common/graphic Start
import PaletteCacheTest from './common/graphic/PaletteCache.test';
import TextCacheTest from './common/graphic/PaintCache.test';
// import common/graphic End
// import common/template Start
import AccessCountMapTest from './common/template/AccessCountMap.test';
import SwipeDataSourceTest from './common/template/SwipeDataSource.test';
// import common/template End
// import common/service Start
import ManagementServiceTest from './common/service/ManagementService.test';
import ServiceManagerTest from './common/service/ServiceManager.test';
import ServiceTest from './common/service/Service.test';
import ServiceFactoryTest from './common/service/ServiceFactory.test';
import ServiceStateObserverTest from './common/service/ServiceStatePublisher.test';
import ServiceApiTest from './common/service/ServiceApi.test';
import ServiceStrategyTest from './common/service/ServiceStrategy.test';
// import common/service End
// import common/agenda Start
import AgendaUtilTest from './common/agenda/AgendaUtil.test';
import ReminderUtilTest from './common//agenda/ReminderUtil.test';
// import common/template End

// import common/router Start
import NavPageBuilderFactoryTest from './common/router/NavPageBuilderFactory.test';
import NavPathManagerTest from './common/router/NavPathManager.test';
// import common/router End

// import card Start
import importantCardUtilsTest from './card/importantCardUtils.test';
import CardUiUtilsTest from './card/importantCard/CardUiUtils.test';
import SingleDayViewModelTest from './card/monthCard/model/SingleDayViewModel.test';
import ImportantCardModelTest from './card/importantCard/ImportantCardModel.test';
import CardUtilsTest from './card/CardUtils.test';
import MonthCardViewModelTest from './card/monthCard/viewModel/MonthCardViewModel.test';
import MonthCardVM2x2Test from './card/monthCard/viewModel/MonthCardVM2x2.test';
import MonthCardVM4x4Test from './card/monthCard/viewModel/MonthCardVM4x4.test';
import MonthCardViewModelUtils from './common/util/MonthCardViewModelUtils.test';
import AgendaCardUiUtils from './common/util/AgendaCardUiUtils.test';
import MonthCardLayoutBuilderTest from './card/monthCard/layout/MonthCardLayoutBuilder.test';
import FromUtilsTest from './common/card/FormUtils.test';
import AgendaCardInfoTest from './common/card/AgendaCardInfo.test';
import AgendaFormCommonStructTest from './common/card/AgendaFormCommonStruct.test';
// import card End

// import WeekView Start
import DateCellViewModelTest from './weekview/viewmodel/DateCellViewModel.test';
import RootViewModelTest from './weekview/viewmodel/RootViewModel.test';
import GanttViewModelTest from './weekview/viewmodel/GanttViewModel.test';
import DateViewLayoutTest from './weekview/viewmodel/DateViewLayout.test';
import GanttBlockViewModelTest from './weekview/viewmodel/GanttBlockViewModel.test';
import DateViewModelTest from './weekview/viewmodel/DateViewModel.test';
import NewGanttBlockViewModelTest from './weekview/viewmodel/NewGanttBlockViewModel.test';
import AgendaModelTest from './weekview/model/AgendaModel.test';
import WeekViewDayModelTest from './weekview/model/DayModel.test';
import NewWeekTitleViewModelTest from './weekview/viewmodel/NewWeekTitleViewModel.test';
// import WeekView End
// import MonthView Start
import MonthViewSingleDayViewModelTest from './monthview/viewmodel/SingleDayViewModel.test';
import SingleMonthlyViewModelTest from './monthview/viewmodel/SingleMonthViewModel.test';
import SingleMonthAgendaManagerTest from './monthview/SingleMonthAgendaManager.test';
import MonthlyInfoTest from './monthview/viewmodel/MonthlyInfo.test';
import MonthlyViewStateTest from './monthview/viewmodel/MonthlyViewState.test';
import SingleMonthlyViewModel from './monthview/viewmodel/SingleMonthAgendaManager.test';
import WeekAgendaBlockModelTest from './monthview/viewmodel/WeekAgendaBlockModel.test';
import SingleWeekViewModelTest from './monthview/viewmodel/SingleWeekViewModel.test';
import WeekTitleViewModel from './monthview/viewmodel/WeekTitleViewModel.test';
import WeekNumViewModel from './monthview/viewmodel/WeekNumViewModel.test';
import DayCellLayoutRuleTest from './monthview/layoutmodel/DayCellLayoutRule.test';
import FrameLayoutRuleTest from './monthview/layoutmodel/FrameLayoutRule.test';
import MonthViewLayoutModelTest from './monthview/layoutmodel/MonthViewLayoutModel.test';
import WeekNumLayoutRuleTest from './monthview/layoutmodel/WeekNumLayoutRule.test';
import WeekTitleLayoutRuleTest from './monthview/layoutmodel/WeekTitleLayoutRule.test';
// import MonthView End
// import YearView Start
import YearViewModelTest from './yearview/YearViewModel.test';
import SingleMonthViewModelTest from './yearview/SingleMonthViewModel.test';
import YearTitleModelTest from './yearview/YearTitleModel.test';
import SingleMonthLayoutRuleTest from './yearview/layoutmodel/SingleMonthLayoutRule.test';
import SingleDayLayoutRuleTest from './yearview/layoutmodel/SingleDayLayoutRule.test';
import YearGridLayoutRuleTest from './yearview/layoutmodel/YearGridLayoutRule.test';
import YearMonthPaintTest from './yearview/MonthPaint.test';
// import YearView End
import SideBarWeekTitleViewModelTest from './sidebarmonth/WeekTitleViewModel.test';
import SideBarMonthViewModelTest from './sidebarmonth/SideBarMonthViewModel.test';

// import importexport Start
import QuotedPrintableHelperTest from './importexport/QuotedPrintableHelper.test';
import FormatTimeTest from './importexport/FormatTime.test';
import DurationTest from './importexport/Duration.test';
import CalendarParserV10Test from './importexport/import/parser/CalendarParserV10.test';
import CalendarParserV20Test from './importexport/import/parser/CalendarParserV20.test';
import ImportExportServiceTest from './importexport/core/ImportExportService.test';
import CalDevParserTest from './importexport/import/parser/CalDevParser.test';
import VCalParserTest from './importexport/vcalendar/VCalParser.test';
import CalendarInfoTest from './importexport/vcalendar/CalendarInfo.test';
import CalendarBuilderV10Test from './importexport/vcalendar/builder/CalendarBuilderV10.test';
import CalendarBuilderV20Test from './importexport/vcalendar/builder/CalendarBuilderV20.test';
import ExportTextProcessorTest from './importexport/export/ExportTextProcessor.test';
import ExportVcsProcessorTest from './importexport/export/ExportVcsProcessor.test';
import ExportVcsCallBackTest from './importexport/export/ExportVcsCallBack.test';
import VCalUtilTest from './importexport/VCalUtils.test';
import VCSToICSRRuleTranslatorTest from './importexport/VCSToICSRRuleTranslator.test';
import ImportProcessorTest from './importexport/import/ImportProcessor.test';
import InsertProcessorTest from './importexport/import/InsertProcessor.test';
import BaseProcessorTest from './importexport/core/BaseProcessor.test';
import CalendarFactoryTest from './importexport/vcalendar/CalendarFactory.test';
// import importexport End

// import repeatrule Start
import RecurrenceParserTest from './repeatrule/RecurrenceParser.test';
import ParseFreqTest from './repeatrule/ParseFreq.test';
import ParseUntilTest from './repeatrule/ParseUntil.test';
import ParseCountTest from './repeatrule/ParseCount.test';
import ParseIntervalTest from './repeatrule/ParseInterval.test';
import ParseByWeekDayTest from './repeatrule/ParseByWeekDay.test';
import ParseByMonthDayTest from './repeatrule/ParseByMonthDay.test';
import ParseByMonthTest from './repeatrule/ParseByMonth.test';
import TimeUtilTest from './repeatrule/TimeUtil.test';
import CustomTimeTest from './repeatrule/CustTime.test';
import EffectiveDateViewModelTest from './repeatrule/EffectiveDateViewModel.test';

// import repeatrule End
// import agenda Start
import SearchAgendaViewModelTest from './agenda/SearchAgendaViewModel.test';
import AgendaOperateHelperTest from './agenda/AgendaOperateHelper.test';
import AgendaListDataModelTest from './agenda/AgendaListDataModel.test';
import AgendaListViewModelTest from './agenda/AgendaListViewModel.test';
import AgendaListBaseModelTest from './agenda/AgendaListBaseModel.test';
import CopyHelperTest from './agenda/helpers/CopyHelper.test';
import PasteHelperTest from './agenda/helpers/PasteHelper.test';
import CreateAgendaViewModelTest from './agenda/CreateAgenda/CreateAgendaViewModel.test';
// import agenda End

import CalendarDBHelperTest from './common/dao/database/CalendarDBHelper.test';
import RepeatruleDurationTest from './repeatrule/RepeatruleDurationTest.test';
import NotificationTriggerHelperTest from './common/util/NotificationTriggerHelper.test';
import AccessibilityUtilTest from './common/util/AccessibilityUtil.test';
import EmitterFormHandlerTest from './product/EmitterFormHandler.test';
import ModeUtilTest from './common/util/ModeUtil.test';
import AgendaDeleteServiceTest from './agenda/AgendaDeleteService.test';

// import appContinue Start
import AppContinueManagerTest from './appContinue/appContinueManager.test'
import AgendaServiceImplTest from './agenda/AgendaServiceImpl.test';
//import feature/settings Start
import TimeZoneViewModelTest from './settings/routerPages/TimeZoneViewModelTest.test';
//import feature/settings End

// import appContinue End
import DeduplicateProcessorTest from './common/util/DeduplicateProcessor.test';
import CardDeduplicateProcessorTest from './card/CardDeduplicateProcessor.test';
import FestivalJumpUtilTest from './agenda/util/FestivalJumpUtil.test';


//import AgendaPreview Start
import JumpUtilsTest from './settings/JumpUtil.test';

//import AgendaPreview End

export default function testsuite() {
  MainAbilityTest();
  EmitterFormHandlerTest()

  // account List Begin
  AccountCommonTest();
  // account List End

  // common/date List Begin
  DateTest();
  DateManagerTest();
  FestivalTest();
  DateUtilTest();
  TimeZoneUtilTest();
  SensitiveStrUtilTest();
  DateRangeTest();
  CalendarDateTest();
  // common/date List End

  // import/export List Begin
  DurationTest();
  CalendarParserV10Test();
  CalendarParserV20Test();
  ImportExportServiceTest();
  CalDevParserTest();
  VCalParserTest();
  VCalUtilTest();
  CalendarInfoTest();
  CalendarBuilderV10Test();
  CalendarBuilderV20Test();
  ExportTextProcessorTest();
  ExportVcsProcessorTest();
  ExportVcsCallBackTest();
  ImportProcessorTest();
  InsertProcessorTest();
  CalendarFactoryTest();
  // import/export List End

  // common/dao List Begin
  // service
  AttendeeServiceTest();
  EventServiceTest();
  CalendarCacheServiceTest();
  CloudUtilsTest();
  CalendarServiceTest();
  OneLinkServiceTest();
  ReminderServiceTest();
  // repo
  CalendarRepositoryTest();
  EventRepositoryTest();
  InstanceRepositoryTest();
  OneLinkRepositoryTest();
  ReminderRepositoryTest();
  BaseVersionDBHelperTest();
  BaseDBHelperTest();
  DBUtilsTest();
  LockTimeZoneInfoTest();
  CalendarCacheParserTest();
  // common/dao List End

  // common/graphic Begin
  PaletteCacheTest();
  TextCacheTest();
  // common/graphic End

  // common/calendar List Begin
  CalendarUtilsTest();
  // common/calendar List End

  // common/util List Begin
  NetWorkMangerTest();
  NotificationHelperTest();
  PreferencesUtilTest();
  CommonUtilsTest();
  Base64UtilTest();
  GlobalDataTest();
  DeviceConfigTest();
  CombineAnimateParamTest();
  GlobalThisTest();
  ThrottleFunctionTest();
  FileUtilsTest();
  InitializeHelperTest();
  I18nUtilTest();
  HttpUtilsTest();
  WorkSchedulerHelperTest();
  ResultTest();
  AbilityStateHelperTest();
  LunarDateUtilTest();
  FontSizeScaleUtilsTest();
  AgendaTransitionUtilTest();
  StringUtilsTest();
  CalendarDBHelperTest();
  NotificationTriggerHelperTest();
  AccessibilityUtilTest();
  TypeUtilsTest();
  WindowSizeManagerTest();
  ImageUtilTest();
  EmitterCollectorTest();
  ModeUtilTest();
  PhoneNumberUtilsTest();
  TimeZoneServiceImplTest();
  NumberFormatManagerTest();
  // common/util List End

  // common/layout List Begin
  GlobalEnvTest();
  LayoutRuleTest();
  LayoutModelTest();
  LayoutModelEnvTest();
  LayoutPropTest();
  BreakPoint2DTest();
  LayoutTreeModelTest();
  // common/layout List End

  // common/oneLink List Begin
  HAGHelperTest();
  // common/oneLink List End
  AccessCountMapTest();
  // common/template List Begin
  HAGHelperTest();
  SwipeDataSourceTest();
  // common/template List End

  // common/service List Begin
  ServiceManagerTest();
  ServiceTest();
  ManagementServiceTest();
  ServiceFactoryTest();
  ServiceStateObserverTest();
  ServiceApiTest();
  ServiceStrategyTest();
  // common/service List End

  // common/agenda List Begin
  AgendaUtilTest();
  ReminderUtilTest();
  // common/service List End

  // common/router Begin
  NavPageBuilderFactoryTest();
  // common/router End

  // Card Begin
  importantCardUtilsTest();
  CardUiUtilsTest();
  SingleDayViewModelTest();
  ImportantCardModelTest();
  CardUtilsTest();
  MonthCardViewModelTest();
  MonthCardLayoutBuilderTest();
  MonthCardVM2x2Test();
  MonthCardVM4x4Test();
  MonthCardViewModelUtils();
  AgendaCardUiUtils();
  FromUtilsTest();
  AgendaCardInfoTest();
  CardDeduplicateProcessorTest();
  AgendaFormCommonStructTest();
  // Card End

  // MonthView List Begin
  SingleMonthlyViewModelTest();
  MonthViewSingleDayViewModelTest();
  SingleMonthAgendaManagerTest();
  MonthlyInfoTest();
  MonthlyViewStateTest();
  SingleMonthlyViewModel();
  WeekAgendaBlockModelTest();
  SingleWeekViewModelTest();
  WeekNumViewModel();
  WeekTitleViewModel();

  MonthViewLayoutModelTest();
  DayCellLayoutRuleTest();
  FrameLayoutRuleTest();
  WeekNumLayoutRuleTest();
  WeekTitleLayoutRuleTest();
  // MonthView List End

  // WeekView List Begin
  GanttViewModelTest();
  RootViewModelTest();
  DateCellViewModelTest();
  DateViewLayoutTest();
  GanttBlockViewModelTest();
  DateViewModelTest();
  NewGanttBlockViewModelTest();
  AgendaModelTest();
  WeekViewDayModelTest();
  NewWeekTitleViewModelTest();
  // WeekView List End

  QuotedPrintableHelperTest();
  VCSToICSRRuleTranslatorTest();

  RecurrenceImportantAdaptTest();
  FormatTimeTest();

  // YearView List Begin
  YearViewModelTest();
  SingleMonthViewModelTest();
  YearTitleModelTest();
  SingleMonthLayoutRuleTest();
  SingleDayLayoutRuleTest();
  YearGridLayoutRuleTest();
  YearMonthPaintTest();
  // YearView List End

  // SideBar List Begin
  SideBarWeekTitleViewModelTest();
  SideBarMonthViewModelTest();
  // SideBar List End

  // Agenda List Begin
  SearchAgendaViewModelTest();
  AgendaOperateHelperTest();
  AgendaListDataModelTest();
  AgendaDeleteServiceTest();
  AgendaListViewModelTest();
  AgendaListBaseModelTest();
  CopyHelperTest();
  PasteHelperTest();
  AgendaServiceImplTest();
  CreateAgendaViewModelTest();
  DeduplicateProcessorTest();
  FestivalJumpUtilTest();
  // Agenda List End


  ShareUtilsTest();

  NavPathManagerTest();

  CalDevParserTest();

  GetDayOffsetTest();

  GetYearDayOffset();

  UtilTest();

  RecurrenceParserTest();
  DurationTest();
  ParseFreqTest();
  ParseUntilTest();
  RepeatruleDurationTest();
  ParseCountTest();
  ParseIntervalTest();
  ParseByWeekDayTest();
  ParseByMonthDayTest();
  ParseByMonthTest();
  TimeUtilTest();
  CustomTimeTest();
  EffectiveDateViewModelTest();

  AccountUtilsTest();
  AgendaEventInfoTest();

  // feature/settings start
  TimeZoneViewModelTest();
  JumpUtilsTest();
  //feature/settings end

  //feature/importexport start
  BaseProcessorTest();
  //feature/importexport end

  // appContinue
  AppContinueManagerTest();
}