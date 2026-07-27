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
import { beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { AgendaDeleteService, AgendaEventInfo, CalendarContract, CalendarService, CommonInnerEvent, EventService, Log, ServiceEnum} from '@app/common';
import { AgendaDeleteServiceImpl } from '@app/feature.agenda/src/main/ets/service/agendaDeleteServiceImpl';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'AgendaDeleteServiceTest';

export default function AgendaDeleteServiceTest() {
  describe('AgendaDeleteServiceTest', () => {
    let agenda: AgendaEventInfo;
    let agendaDeleteService: AgendaDeleteService;

    beforeEach(() => {
      agenda = new AgendaEventInfo();
      agendaDeleteService = new AgendaDeleteServiceImpl(ServiceEnum.AGENDA_DELETE_SERVICE);
    })

    it('getDeleteMessage', 0, () => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      let message: string = agendaDeleteService.getDeleteMessage(agenda, '');
      expect(message.toString().length).assertLarger(0);
      agenda.mImportantEventType = CalendarContract.EventImportantType.COUNTDOWN;
      message = agendaDeleteService.getDeleteMessage(agenda, '');
      expect(message.toString().length).assertLarger(0);
      agenda.mImportantEventType = CalendarContract.EventImportantType.NORMAL;
      message = agendaDeleteService.getDeleteMessage(agenda, '');
      expect(message.toString().length).assertLarger(0);
    });

    it('getDeleteAgendaDialogTitle', 0, () => {
      agenda.mImportantEventType = CalendarContract.EventImportantType.ANNIVERSARIES;
      agenda.mTitle = 'title';
      let message = agendaDeleteService.getDeleteAgendaDialogTitle(agenda.mTitle);
      expect(message.toString().length).assertLarger(0);
    });

    it('deleteEvent', 0, () => {
      //1.创建一个mock能力的对象MockKit
      let mocker: MockKit = new MockKit();
      let eventService: EventService = EventService.INSTANCE;
      //3.进行mock操作,比如需要对ClassName类的method_1函数进行mock
      const eventId: number = 1;
      let mockfunc: Function = mocker.mockFunc(eventService, eventService.deleteEventById);
      when(mockfunc)(eventId).afterThrow('这是一个主动抛出的错误');
      expect(agendaDeleteService.deleteEvent(eventId)).assertPromiseIsRejected();
    });

    it('notifyDeleteWithCallback', 0, async (done: Function) => {
      let deleteService = new AgendaDeleteServiceImpl(ServiceEnum.AGENDA_DELETE_SERVICE);
      let deleteCallback: (success: boolean) => void = (success: boolean) => {
        expect(success).assertTrue();
        emitter.off(CommonInnerEvent.DELETE_AGENDA, deleteHandler); // 通知主界面日程删除
        done();
      }
      let deleteHandler: (data: emitter.EventData) => void = (data: emitter.EventData) => {
        deleteCallback(true);
      }
      emitter.on({ eventId: CommonInnerEvent.DELETE_AGENDA }, deleteHandler); // 通知主界面日程删除
      deleteService.notifyDeleteEventWithCallback(0, 0, deleteCallback, true);
    });
  });
}