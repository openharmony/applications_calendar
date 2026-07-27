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
import { describe, expect, it } from '@ohos/hypium'
import { Log } from '@app/common'
import { QuotedPrintableHelper } from '@app/feature.importexport'

const TAG = 'QuotedPrintableHelper'
const SUMMARY: string = '=E6=B5=8B=E8=AF=95=E4=B8=80=E4=B8=8Bgrydufhru=EF=BC=9A=EF=BC=88=E5=8F=91=E8=\r\n=B4=A7=EF=BC=9B=E5=B9=B2=E6=B4=BB=EF=BC=88=EF=BC=89=EF=BC=89#=EF=BD=9E=EF=BD=\r\n=9E=E2=80=A6=EF=BC=9A=EF=BC=9B=EF=BC=9F.=E2=80=9C=E7=88=B1=E6=88=91=E7=9A=84=\r\n=E4=BA=BA=E5=A4=9A=E5=A5=BD=E7=8E=A9=E5=90=A7=E3=80=82=E5=BA=94=E8=AF=A5=E5=\r\n=8F=AF=E4=BB=A5=E5=98=9B=E4=BD=A0=E5=9C=A8=E5=93=AA=E9=87=8C=E7=AD=89=E6=88=\r\n=91=E5=9B=9E=E5=8E=BB=E5=86=8D=E8=AF=B4=E8=AF=9D=E5=B0=B1=E5=8E=BB=E4=B9=B0=\r\n=E8=8D=AF=E4=BA=86=E5=90=97=E5=AE=9D=E5=AE=9D=E6=99=9A=E5=AE=89=E5=AE=9D=E5=\r\n=AE=9D=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=\r\n=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=\r\n=E4=B9=88=E5=93=92=E2=80=9D';
const SUMMARY_TEXT: string = '测试一下grydufhru：（发货；干活（））#～～…：；？.“爱我的人多好玩吧。应该可以嘛你在哪里等我回去再说话就去买药了吗宝宝晚安宝宝么么么么么么么么么么么么么么么么么哒”';
const SUMMARY_ENCODE: string = '=E6=B5=8B=E8=AF=95=E4=B8=80=E4=B8=8B=67=72=79=64=75=66=68=72=75=EF=BC=\r\n=9A=EF=BC=88=E5=8F=91=E8=B4=A7=EF=BC=9B=E5=B9=B2=E6=B4=BB=EF=BC=88=EF=\r\n=BC=89=EF=BC=89=23=EF=BD=9E=EF=BD=9E=E2=80=A6=EF=BC=9A=EF=BC=9B=EF=BC=\r\n=9F=2E=E2=80=9C=E7=88=B1=E6=88=91=E7=9A=84=E4=BA=BA=E5=A4=9A=E5=A5=BD=\r\n=E7=8E=A9=E5=90=A7=E3=80=82=E5=BA=94=E8=AF=A5=E5=8F=AF=E4=BB=A5=E5=98=\r\n=9B=E4=BD=A0=E5=9C=A8=E5=93=AA=E9=87=8C=E7=AD=89=E6=88=91=E5=9B=9E=E5=\r\n=8E=BB=E5=86=8D=E8=AF=B4=E8=AF=9D=E5=B0=B1=E5=8E=BB=E4=B9=B0=E8=8D=AF=\r\n=E4=BA=86=E5=90=97=E5=AE=9D=E5=AE=9D=E6=99=9A=E5=AE=89=E5=AE=9D=E5=AE=\r\n=9D=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=\r\n=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=E4=B9=88=\r\n=E4=B9=88=E4=B9=88=E5=93=92=E2=80=9D';

export default function QuotedPrintableHelperTest() {
  describe('QuotedPrintableHelperTest', () => {

    it('QuotedPrintableHelper_DecodeQuotedPrintable', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} QuotedPrintableHelper_DecodeQuotedPrintable begin`);
      expect(QuotedPrintableHelper.getInstance().decodeQuotedPrintable(SUMMARY, 'utf-8')).assertEqual(SUMMARY_TEXT);
      done();
    })


    it('QuotedPrintableHelper_EncodeQuotedPrintable', 0, async (done: Function) => {
      Log.info(TAG, `${TAG} QuotedPrintableHelper_EncodeQuotedPrintable begin`);
      expect(QuotedPrintableHelper.getInstance().encodeQuotedPrintable(SUMMARY_TEXT, 'utf-8')).assertEqual(SUMMARY_ENCODE);
      expect(QuotedPrintableHelper.getInstance().decodeQuotedPrintable(SUMMARY_ENCODE, 'utf-8')).assertEqual(SUMMARY_TEXT);
      done();
    })

  })
}