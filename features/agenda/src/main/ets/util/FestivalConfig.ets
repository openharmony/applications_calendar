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
import { HashMap } from '@kit.ArkTS';

export interface FestivalConfig {
  DEFAULT_FESTIVAL_NAME: string
}

const festivalConfigInfoList: FestivalConfig[] = [
  {
    DEFAULT_FESTIVAL_NAME: '小寒',
  },
  {
    DEFAULT_FESTIVAL_NAME: '大寒',
  },
  {
    DEFAULT_FESTIVAL_NAME: '除夕',
  },
  {
    DEFAULT_FESTIVAL_NAME: '春节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '立春',
  },
  {
    DEFAULT_FESTIVAL_NAME: '元宵节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '情人节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '雨水',
  },
  {
    DEFAULT_FESTIVAL_NAME: '惊蛰',
  },
  {
    DEFAULT_FESTIVAL_NAME: '妇女节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '植树节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '春分',
  },
  {
    DEFAULT_FESTIVAL_NAME: '愚人节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '清明',
  },
  {
    DEFAULT_FESTIVAL_NAME: '清明节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '谷雨',
  },
  {
    DEFAULT_FESTIVAL_NAME: '劳动节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '青年节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '立夏',
  },
  {
    DEFAULT_FESTIVAL_NAME: '母亲节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '小满',
  },
  {
    DEFAULT_FESTIVAL_NAME: '儿童节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '芒种',
  },
  {
    DEFAULT_FESTIVAL_NAME: '夏至',
  },
  {
    DEFAULT_FESTIVAL_NAME: '父亲节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '端午节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '建党节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '小暑',
  },
  {
    DEFAULT_FESTIVAL_NAME: '大暑',
  },
  {
    DEFAULT_FESTIVAL_NAME: '建军节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '立秋',
  },
  {
    DEFAULT_FESTIVAL_NAME: '处暑',
  },
  {
    DEFAULT_FESTIVAL_NAME: '七夕',
  },
  {
    DEFAULT_FESTIVAL_NAME: '七夕节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '中元节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '白露',
  },
  {
    DEFAULT_FESTIVAL_NAME: '教师节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '秋分',
  },
  {
    DEFAULT_FESTIVAL_NAME: '中国烈士纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '中秋节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '国庆节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '寒露',
  },
  {
    DEFAULT_FESTIVAL_NAME: '霜降',
  },
  {
    DEFAULT_FESTIVAL_NAME: '重阳节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '万圣夜',
  },
  {
    DEFAULT_FESTIVAL_NAME: '立冬',
  },
  {
    DEFAULT_FESTIVAL_NAME: '小雪',
  },
  {
    DEFAULT_FESTIVAL_NAME: '大雪',
  },
  {
    DEFAULT_FESTIVAL_NAME: '感恩节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '国家公祭日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '冬至',
  },
  {
    DEFAULT_FESTIVAL_NAME: '平安夜',
  },
  {
    DEFAULT_FESTIVAL_NAME: '圣诞节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '腊八节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '北方小年',
  },
  {
    DEFAULT_FESTIVAL_NAME: '南方小年',
  },
  {
    DEFAULT_FESTIVAL_NAME: '元旦',
  },
  {
    DEFAULT_FESTIVAL_NAME: '中国人民抗日战争胜利纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '九一八事变',
  },
  {
    DEFAULT_FESTIVAL_NAME: '记者节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '澳门回归纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '龙抬头',
  },
  {
    DEFAULT_FESTIVAL_NAME: '辛亥革命纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '抗美援朝纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '寒衣节',
  },
  {
    DEFAULT_FESTIVAL_NAME: '台湾光复纪念日',
  },
  {
    DEFAULT_FESTIVAL_NAME: '国际禁毒日',
  }
]

const festivalConfigInfoMap: HashMap<string, FestivalConfig> = new HashMap();

festivalConfigInfoList.forEach(e => {
  festivalConfigInfoMap.set(e.DEFAULT_FESTIVAL_NAME, e);
})

export { festivalConfigInfoMap as FESTIVAL_CONFIG_INFO_MAP };