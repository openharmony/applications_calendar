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
export const HTML_ADAPTER = "\n" +
  "<style id=\"style\">\n" +
  "* {\n" +
  "    box-sizing: border-box;\n" +
  "}\n" +
  "\n" +
  "html, body{\n" +
  "    padding: 0;\n" +
  "    margin: 0;\n" +
  "    font-size: 16px;\n" +
  "    word-break: break-all;\n" +
  "}\n" +
  "p.MsoNormal span {\n" +
  "    line-height:normal !important;\n" +
  "}\n" +
  "@font-face {\n" +
  "    font-family: 'Wingdings';\n" +
  "    src: url(file:///OpenHarmony_asset/mailassets/fonts/Wingdings.ttf); /* �ĳ������ŵ�·�� */\n" +
  "}\n" +
  "\n" +
  "span, p {\n" +
  "    white-space: normal !important;\n" +
  "    word-break: break-word !important;\n" +
  "}\n" +
  "\n" +
  "p {\n" +
  "padding: 0;\n" +
  "margin: 0;\n" +
  "}\n" +
  "\n" +
  "table{\n" +
  "  font-size: 14px;\n" +
  "  margin: 0 !important;\n" +
  "}\n" +
  "img:not(.table-inner-img){\n" +
  "    max-width: 100% !important;\n" +
  "    height: auto !important;\n" +
  "}\n" +
  "img.table-inner-img{\n" +
  "    max-width: 3000px !important;\n" +
  "}\n" +
  ".email-table-wrap{\n" +
  "    overflow-y: hidden;\n" +
  "    overflow-x: auto;\n" +
  "}\n" +
  ".email-table-wrap table{\n" +
  "   -webkit-backface-visibility: hidden;\n" +
  "   transform-origin: 0 0;\n" +
  "}\n" +
  "</style>\n" +
 " <script src='resource://rawfile/welink-email-page/index.js'></script>\n"