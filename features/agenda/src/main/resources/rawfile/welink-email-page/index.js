/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
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
(function (window) {

  // css样式
  const CSS_STYLE = `
    body, p {
      margin: 0;
    }

    ul {
      margin: 0;
      padding: 0;
    }

    ul:first-of-type {
      border-top-left-radius: 20px;
      border-top-right-radius:20px;
      overflow: hidden;
    }

    ul:last-of-type {
      border-bottom-left-radius: 20px;
      border-bottom-right-radius:20px;
      overflow: hidden;
    }

    .title-table .item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      min-height: 32px;
      padding: 12px;
      white-space: pre-line;
      background-color: #f8f8f8;
    }

    .title-table .item .title {
      min-width: 100px;
      padding-right: 12px;
      font-size: 16px;
      font-weight: bold;
    }

    .title-table .item .content {
      text-align: right;
    }

    .meeting-table .item {
      display: flex;
      justify-content: space-between;
      align-items: center;
      min-height: 32px;
      padding: 12px;
      white-space: pre-line;
    }

    .meeting-table .item:nth-of-type(2n) {
      background-color: #f8f8f8;
    }

    .meeting-table .item:nth-of-type(2n + 1) {
      background-color: #fff;
    }

    .meeting-table .item .title {
      min-width: 88px;
      padding-right: 12px;
      font-size: 16px;
      font-weight: bold;
    }

    /******************************/
    .meeting-table .item .content {
      word-break: break-all;
    }

    .title + .content {
      text-align: right;
    }
  `;

  // TODO 后续关键字扩展
  const KEY_WORD_MAP = new Map([
  // 标题表格包含关键内容
    ['titleTable', /weMeeting|Agendas/],
    // 会议表格包含关键内容
    ['meetingTable', /Subject/],
    // 会议表格中子表格标题名, 视频|语音|会议议题
    ['meetingTableChildTableKey', /Meeting URL|Video Meeting|VoIP|Agenda/],
    // 会议议题表格标题名
    ['topicTableKey', /Agenda/],
    // 议题表格标题栏目名
    ['topicTableTitleColumn', /Topic/],
    // 左右|上下布局分界点，与会人|会议议题|会议公告
    ['limitRow', /Attendees|Guests|Agenda|Bulletins/]
  ]);

  // 会议类型
  const MODE_TYPE = {
    TABLE_COUNT_ERROR: 'TABLE_COUNT_ERROR',
    MEETING_TABLE_EMPTY_ERROR: 'MEETING_TABLE_EMPTY_ERROR',
    MEETING_TABLE_COLUMN_COUNT_ERROR: 'MEETING_TABLE_COLUMN_COUNT_ERROR',
    TOPIC_TABLE_COUNT_ERROR: 'TOPIC_TABLE_COUNT_ERROR',
    TOPIC_TABLE_MERGE_ERROR: 'TOPIC_TABLE_MERGE_ERROR',
    TOPIC_TABLE_CHILD_ERROR: 'TOPIC_TABLE_CHILD_ERROR',
    NORMAL: 'NORMAL'
  };

  // 禁止缩放
  function disableZoomPage() {
    let content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0';
    let viewportMeta = document.querySelector('meta[name="viewport"]');
    if (viewportMeta) {
      viewportMeta.content = content;
    } else {
      viewportMeta = document.createElement('meta');
      viewportMeta.name = 'viewport';
      viewportMeta.content = content;
      document.head.appendChild(viewportMeta);
    }
  }

  // 插入css样式
  function insertStyle(css) {
    const style = document.head.querySelector('#mainStyle');
    if (style) {
      style.textContent = css;
    } else {
      const style = document.createElement('style');
      style.id = 'mainStyle';
      style.textContent = css;
      document.head.appendChild(style);
    }
  }

  // 单个Node添加样式
  function addStyle(el, style) {
    if (el && el.getAttribute) {
      const oldStyle = el.getAttribute('style') || '';
      el.setAttribute('style', `${oldStyle}${style}`);
    }
  }

  // NodeList添加样式
  function addStyles(els, style) {
    Array.from(els).forEach((el) => {
      addStyle(el, style);
    });
  }

  // 移除link样式
  function removeLink() {
    const linkList = document.querySelectorAll('a');
    // 获取a链接子元素，span | font
    const linkChildren = document.querySelectorAll('a *');
    addStyles(linkList, ';pointer-events: none;color:rgba(0,0,0,0.4);text-decoration: initial;');

    if (linkChildren.length) {
      // a链接里面的font带颜色
      // eg：10：39
      addStyles(linkChildren, ';color:rgba(0,0,0,0.4);font-size:14px;');
    }
  }

  // 清除括号内容
  // 加入会议(Guest) =>加入会议
  // Join(Guest) =>Join
  function removeBracketsText(str = '') {
    return str.replace(/([\u4e00-\u9fa5_a-zA-Z]+)(\(.*\))/, '$1');
  }

  // 计算高度
  // 扩展extHeight，避免出现滚动条
  function resetWebHeight(extHeight = 5) {
    // br换行符，存在高度
    const getElHeight = el => el.getBoundingClientRect().height;

    const container = document.querySelector('body > div');
    const bodyChildren = Array.from(document.body.children);
    // 隐藏br换行符，避免产生垂直滚动
    const bodyHeight = bodyChildren.reduce((a, c) => a + getElHeight(c), 0);
    let maxHeight = bodyHeight;

    if (container) {
      const containerChildren = Array.from(container.children);
      const containerHeight = containerChildren.reduce((a, c) => a + getElHeight(c), 0);
      maxHeight = Math.max(bodyHeight, containerHeight);
    }

    window.mailObj?.onHeightChange?.(maxHeight + extHeight);
  }

  /**********************************工具函数*****************************************/
  // 从根元素过滤所需的Node节点
  // @params {Node}   root，根节点，默认body
  // @params {string} nodeName，节点名称，如：table
  // @return {Node[]} nodes
  function filterNode(root = document.body, nodeName) {
    if (!nodeName) {
      console.error('welink-email-page', 'filterNode, nodeName is null');
      throw new Error();
    }

    const queue = [root.children];
    const nodes = [];
    // 一般层级为1，即body>table;特殊层级，body>div>...>div>table;最多找10层
    const MAX_LEVEL = 10;
    let level = 0;
    while (queue.length && nodes.length === 0 && level < MAX_LEVEL) {
      level++;
      const nodeList = queue.shift();
      Array.from(nodeList).forEach(node => {
        if (node.tagName === nodeName.toUpperCase()) {
          nodes.push(node);
        } else {
          queue.push(node.children);
        }
      });
    }

    return nodes;
  };

  // 从table获取第一层子元素tr， table>tboty>tr
  // @params {Node}   table，表格
  // @return {Node[]} trList, 表格Tr
  function getTrList(table) {
    if (!table) {
      console.error('welink-email-page', 'getTrList, table is null');
      throw new Error();
    }

    // table>tboty>tr
    // 第一个子元素不是tbody——eg：10:32
    let tbody = table.querySelector('tbody');

    if (!tbody) {
      console.error('welink-email-page', 'getTrList, tbody is null');
      throw new Error();
    }

    const trList = Array.from(tbody.children);
    return trList;
  }

  // 从table中寻找需要的tr
  // @params {Node}   table，表格
  // @params {Reg|string} keywork，关键字，如：/Agenda/
  // @return {Node} tr
  function findTr(table, keyword) {
    if (!table) {
      console.error('welink-email-page', 'findTr, table is null');
      throw new Error();
    }

    if (!(keyword instanceof RegExp) && typeof (keyword) !== 'string') {
      console.error('welink-email-page', 'findTr, keyword is not Reg or String');
      throw new Error();
    }

    const trList = getTrList(table);

    return trList.find(tr => {
      if (!tr.children || !tr.children?.[0]) {
        console.error('welink-email-page', 'findTr, children is null');
        throw new Error();
      }

      const text = tr.children?.[0]?.innerText;
      // 第一列为标，匹配关键字
      if (keyword instanceof RegExp) {
        return keyword?.test(text);
      }

      return text.includes(keyword);
    });
  }

  // 获取Table信息
  // @return { TableInfo } tableInfo，表格信息
  function getTableInfo() {
    const tableInfo = {
      titleTable: null,
      meetingTable: null,
      topicTable: null,
      tableCount: 2,
      topicTableCount: 1,
    };

    const tables = filterNode(document.body, 'table');

    // 表格数量
    tableInfo.tableCount = tables.length;

    // 标题表格
    tableInfo.titleTable = tables.find(table => KEY_WORD_MAP.get('titleTable').test(table.innerText));

    // 会议表格
    tableInfo.meetingTable = tables.find(table => KEY_WORD_MAP.get('meetingTable').test(table.innerText));
    // 如果有会议表格
    if (tableInfo.meetingTable) {
      // 会议表格里面寻找议题表格Tr
      const topicTableTr = findTr(tableInfo.meetingTable, KEY_WORD_MAP.get('topicTableKey'));
      if (topicTableTr) {
        const topicTables = topicTableTr.querySelectorAll('table');

        // 议题表格数量
        tableInfo.topicTableCount = topicTables.length;

        // 如果只有1个表格，则为议题表格
        if (topicTables.length === 1) {
          tableInfo.topicTable = topicTables[0];
        }
      }
    }

    return tableInfo;
  }

  // 递归解析table数据
  // @params {Node}   table，表格
  // @return {TableData} tableData, 表格数据
  function parseTableWalker(table, data = []) {
    const trList = getTrList(table);
    trList.forEach((tr, i) => {
      data[i] = [];
      const tdList = Array.from(tr.children);
      tdList.forEach((td, j) => {
        const innerTable = td.querySelector('table');
        if (innerTable) {
          // 递归获取table数据
          data[i][j] = parseTableWalker(innerTable, []);
        } else {
          data[i][j] = td.innerText;
        }
      });
    });
    return data;
  }

  // 解析table数据
  // @params {Node}   table，表格
  // @return {TableData} tableData, 表格数据
  function parseTable(table) {
    if (!table) {
      console.error('welink-email-page', 'parseTable, table is null');
      throw new Error();
    }

    return parseTableWalker(table);
  }

  // 获取模式类型
  // @params { TableInfo } tableInfo 表格信息
  // @return {string} MODE_TYPE
  function getModeType(tableInfo) {
    const { meetingTable, topicTable, tableCount, topicTableCount } = tableInfo;

    // 1.标准模式一定有会议表格
    if (!meetingTable) {
      return MODE_TYPE.MEETING_TABLE_EMPTY_ERROR;
    }

    // 2.标准模式会议表格，有且只有2列
    const meetingTableTrList = getTrList(meetingTable);
    const tdList = Array.from(meetingTableTrList?.[0]?.children) ?? [];
    if (tdList.length !== 2) {
      return MODE_TYPE.MEETING_TABLE_COLUMN_COUNT_ERROR;
    }

    // 3.标准模式议题表格如果有，有且只有1个
    if (topicTableCount > 1) {
      return MODE_TYPE.TOPIC_TABLE_COUNT_ERROR;
    }

    if (topicTable) {
      // 4.标准模式议题表格如果有，有且只有1个，且没有行列拆分
      const spans = topicTable.querySelectorAll('[colspan], [rowspan]');
      if (spans.length > 0) {
        return MODE_TYPE.TOPIC_TABLE_MERGE_ERROR;
      }

      // 5.标准模式议题表格如果有，有且只有1个，且没有子表格
      const subTopicTables = topicTable.querySelectorAll('table');
      if (subTopicTables.length > 0) {
        return MODE_TYPE.TOPIC_TABLE_CHILD_ERROR;
      }
    }

    return MODE_TYPE.NORMAL;
  }

  /**********************************工具函数*****************************************/


  /**********************************正常模式处理*****************************************/
  // 会议文本转会议链接
  // @params {JoinData}  joinData，视频或语音表格数据
  // @return {JoinDataWithLinkStr} joinDataWithLinkStr，带链接的表格数据
  function joinDataAddLink(joinData) {
    // 标准会议会议链接为两组，加入会议，主持会议，每组分别为数组
    if (!(Array.isArray(joinData) && joinData.length === 2 && Array.isArray(joinData[0]) && Array.isArray(joinData[1]))) {
      console.error('welink-email-page', 'joinDataAddLink, joinData is abnormal');
      // 08:44 joinData [guest, host, external] length为3
      // 09:13 joinData [guest] length为1
      throw new Error();
    }

    const [guest, host] = joinData;
    const [guestLinkText, guestId] = guest;
    const [hostLinkText, hostId] = host;
    const linkList = Array.from(document.querySelectorAll('a'));
    const guestLink = linkList.find(link => link.innerText.includes(guestLinkText));
    const hostLink = linkList.find(link => link.innerText.includes(hostLinkText));

    if (!guestLink && !hostLink) {
      console.error('welink-email-page', 'joinDataAddLink, link is null');
      throw new Error();
    }

    let JoinDataWithLinkStr = '';

    if (guestLinkText) {
      JoinDataWithLinkStr += `<a href="${guestLink.href}" target="_BLANK">${removeBracketsText(guestLinkText)}</a>`;
    }

    if (guestId) {
      // 入会链接为MeetingId&nbsp;&nbsp;&nbsp;&nbsp;嘉宾密码，去除多余空格——测试会议16
      // guestId.replace(/\s+/g, '')
      JoinDataWithLinkStr += `&nbsp;&nbsp;${guestId}`;
    }

    if (hostLinkText) {
      JoinDataWithLinkStr += `\n<a href="${hostLink.href}" target="_BLANK">${removeBracketsText(hostLinkText)}</a>`;
    }

    if (hostId) {
      JoinDataWithLinkStr += `&nbsp;&nbsp;${hostId}`;
    }

    return JoinDataWithLinkStr;
  }

  // 议题表格数据转换为需要的单项数据
  // @params {TopicData}  topicData，表格单项数据
  // @return {ListItemData} listItemData，列表数据
  function topicData2listItemData(topicData) {
    const thead = topicData[0];
    const tbody = topicData.slice(1);
    let listItemData = [];

    // 以议题栏目为标题，议题后面栏目为内容
    const topicIndex = thead.findIndex(td => KEY_WORD_MAP.get('topicTableTitleColumn').test(td));

    if (topicIndex === -1) {
      // 没有议题标题名，不做解析——测试的议题会议32
      console.error('welink-email-page', 'topicData2listItemData, topicTableTitleColumn is null');
      throw new Error();
    }

    tbody.forEach((tr, i) => {
      // 议题标题
      const order = thead[0].includes('No.') ? tr[0] : `${i + 1}`;
      const flag = order.includes('.') ? ' ' : '.';
      const topicVal = tr[topicIndex] ?? '--';
      listItemData.push([`${order}${flag}${topicVal}`, '', 'is-topic']);

      // 议题后面的栏目
      const columns = tr.slice(topicIndex + 1);
      const columnsContent = columns.map((column, j) => {
        const key = thead[topicIndex + 1 + j] ?? '--';
        const value = column.trim() ?? '--';

        return `· ${key.replace('\n', '&nbsp;')}: ${value}`;
      });

      // 议题内容
      listItemData.push(['', columnsContent.join('\n'), 'is-topic']);
    });

    return listItemData;
  }

  // 表格单项数据转换为需要的数据
  // @params {Tr}  tr，表格项
  // @params {number}  i，表格项指数
  // @params {number}  limitIndex，区分上下|左右布局的分界线
  // @return {ListData} listItemData，列表数据
  function handleMeetingItemData(tr, i, limitIndex) {
    let listItemData = [];
    let title = tr[0];
    let content = tr[1];

    if (i < limitIndex) {
      // 左右布局
      listItemData.push([title, Array.isArray(content) ? joinDataAddLink(content) : content, 'is-meeting']);
    } else {
      // 议题表格单独处理
      if (KEY_WORD_MAP.get('topicTableKey').test(title)) {
        // 议题表格不是表格
        if (!Array.isArray(content)) {
          console.error('welink-email-page', 'handleMeetingItemData, Agenda is not table');
          throw new Error();
        }

        listItemData = listItemData.concat(topicData2listItemData(content));
      } else {
        // 空值默认使用--
        if (title.trim() || content.trim()) {
          // 上下布局
          listItemData.push([title, '', 'is-meeting']);
          // 会议公告两个空行——eg：08：00
          // 与会人内容为空——eg：11：22
          listItemData.push(['', content.trim().replace(/\n+/g, '\n') ?? '--', 'is-meeting']);
        } else {
          console.warn('welink-email-page', 'handleMeetingItemData, title and content is null');
          // 内容和标题都没有——eg：12：27
        }
      }
    }

    return listItemData;
  }

  // 表格数据转换为需要的数据
  // @params {MeetingData}  meetingData，表格数据
  // @return {ListData} listData，列表数据
  function meetingData2listData(meetingData) {
    let listData = [];

    // 以与会人作为分界线，以上左右布局，以下上下布局
    // 没有与会人则取嘉宾
    let limitIndex = meetingData.findIndex(tr => {
      // 表格栏目不为2，无法解析
      if (tr.length !== 2) {
        console.error('welink-email-page', 'meetingData2listData, table column count is not 2');
        throw new Error();
      }

      // 没有与会人，有会议议题——eg：10:16
      // 没有与会人，有会议公告——eg：12:36
      return KEY_WORD_MAP.get('limitRow').test(tr[0]);
    });

    if (limitIndex < 0) {
      // 没有与会人，没有会议公告——eg：08:48
      console.error('welink-email-page', 'meetingData2listData, content has no Agenda or Bulletins');
      throw new Error();
    }

    meetingData.forEach((tr, i) => {
      const title = tr[0];
      const content = tr[1];

      // 议题会议是表格, 视频|语音|议题
      const whiteList = KEY_WORD_MAP.get('meetingTableChildTableKey');
      // 不在白名单内的表格内容为表格，无法解析
      if (!whiteList.test(title) && Array.isArray(content)) {
        console.error('welink-email-page', `meetingData2listData, ${title} content is table`);
        // 09:18 议题表格栏目名为：【会议议题Meeting Contents】，不是【会议议题Agenda】
        throw new Error();
      }

      const listItemData = handleMeetingItemData(tr, i, limitIndex);
      listData = listData.concat(listItemData);
    });

    return listData;
  }

  // 处理标题表格
  function titleData2htmlStr(titleData = []) {
    if (titleData.length === 0) {
      return '';
    }

    // 表格栏目不为2，无法解析
    if (titleData.length > 2) {
      console.error('welink-email-page', 'titleData2htmlStr, table column count is over 2');
      // 会议议题不是子表格，为会议表格的栏目，栏目超过2
      // eg：11:13
      throw new Error();
    }

    if (!Array.isArray(titleData[0]) || !Array.isArray(titleData[1])) {
      console.error('welink-email-page', 'titleData2htmlStr, table data is not table');
      throw new Error();
    }

    let title = titleData[0][0].trim();
    let content = titleData[1][0].trim();

    // 标题中间由空格连接 【议空间 WeMeeting】
    if (title.includes(' ')) {
      // 中间空格替换为换行符
      title = title.replace(' ', '\n');
    } else {
      console.warn('welink-email-page', 'titleData2htmlStr, title has no space');

      // 标题中间由括号连接
      // eg：10：33
      if (title.includes('(') && title.includes(')')) {
        console.warn('welink-email-page', 'titleData2htmlStr, title has ()');
        title = title.replace('(', '\n').replace(')', '');
      }
    }

    // 补齐a链接
    const linkList = Array.from(document.querySelectorAll('a'));
    const titleLink = linkList.find(link => link.innerText.includes(content));
    if (titleLink) {
      content = `\n<a href="${titleLink.href}" target="_BLANK">${content}</a>`;
    }

    const htmlStr = `
      <ul class="title-table">
        <li class="item is-title">
          <div class="title">${title}</div>
          <div class="content">${content ?? ''}</div>
        </li>
      </ul>
    `;

    return htmlStr;
  }

  // 处理会议表格
  function meetingData2htmlStr(meetingData) {
    // 表格数据转列表数据
    const listData = meetingData2listData(meetingData);

    // table数据重新排版
    const trList = listData.map(tr => {
      const [title, content, className] = tr;
      return `
        <li class="item ${className}">
          ${title ? `<div class="title">${title}</div>` : ''}
          ${content ? `<div class="content">${content ?? '--'}</div>` : ''}
        </li>
      `;
    });
    const htmlStr = `<ul class="meeting-table">${trList.join('')}</ul>`;

    return htmlStr;
  }

  // 获取邮件内容
  function getEmailHtmlStr(meetingTable) {
    const parentNode = meetingTable.parentNode;
    const children = Array.from(parentNode.children);
    const wrap = document.createElement('div');

    // 将table之前的Node添加到fragment
    for (child of children) {
      // 标题会议不是table，而是div，跳过
      // eg: 08:15
      if (KEY_WORD_MAP.get('titleTable').test(child.innerText)) {
        continue;
      }

      // 标题表格或会议表格，截止
      if (child.tagName === 'TABLE') {
        break;
      }
      wrap.appendChild(child);
    }

    return wrap.innerHTML;
  }

  // 处理标题div
  function handleTitleDiv(meetingTable) {
    if (!meetingTable) {
      console.log('welink-email-page', `handleNormalType meetingTable is null`);
    }

    // 标题会议不是table，而是div
    // eg: 08:15
    const titleDiv = meetingTable.previousElementSibling;
    const tabledata = [];
    if (titleDiv && titleDiv.tagName === 'DIV' && titleDiv.innerText.includes('WeMeeting')) {
      const children = Array.from(titleDiv.children);
      children.forEach(child => {
        if (child.innerText.includes('WeMeeting')) {
          // title
          tabledata.push([child.innerText]);
        } else if (tabledata.length === 1 && child.tagName === 'A') {
          // content
          tabledata.push([child.innerText]);
        }
      });
    }

    return tabledata;
  }

  // 获取table内容
  function getTableHtmlStr(callback) {
    const tableList = filterNode(document.body, 'table');
    let htmlStr = '';

    if (tableList.length === 0) {
      console.error('welink-email-page', 'getTableHtmlStr, table is null');
      throw new Error();
    }

    const tableDataList = tableList.map(parseTable);

    tableDataList.forEach(tableData => {
      if (KEY_WORD_MAP.get('titleTable').test(tableData.join())) {
        htmlStr += titleData2htmlStr(tableData);
      } else if (KEY_WORD_MAP.get('meetingTable').test(tableData.join())) {
        callback && callback(tableData);
        htmlStr += meetingData2htmlStr(tableData);
      } else {
        // TODO 后续表格排版扩展
        console.warn('welink-email-page', 'getTableHtmlStr, other table is not parse');
      }
    });

    return htmlStr;
  }

  // 处理正常模式
  function handleNormalType(tableInfo) {
    const { titleTable, meetingTable } = tableInfo;
    let htmlStr = '';

    // 处理邮件内容
    const emailHtmlStr = getEmailHtmlStr(meetingTable);
    htmlStr = emailHtmlStr;

    // 处理非table的标题会议——标题会议是div
    // eg: 08:15
    const titleData = handleTitleDiv(meetingTable);
    htmlStr += titleData2htmlStr(titleData);

    // 处理table
    const tableHtml = getTableHtmlStr();
    htmlStr = tableHtml;

    document.body.innerHTML = htmlStr;
  }

  /**********************************正常模式处理*****************************************/


  /**********************************表格合并处理*****************************************/
  // 更新合并行的编号
  // [2 2 2] =>[2.1 2.2 2.3]
  function updateOrder(_tableRows) {
    // copy一份数据
    let tableRows = _tableRows.slice();
    let order = 1;
    for (let i = 0; i < tableRows.length - 1; i++) {
      if (tableRows[i][0] === tableRows[i + 1][0]) {
        // 相同序列号重新排序
        tableRows[i][0] = tableRows[i][0] + '.' + order;
        order++;

        // 相同的序列号处于总长度最后一个元素
        if (i + 1 === tableRows.length - 1) {
          tableRows[i + 1][0] = tableRows[i + 1][0] + '.' + order;
        }
      } else {
        // 当前合并行最后一个相同的序列号重新排序后
        // 转到下一个合并列，并重置order
        if (order > 1) {
          tableRows[i][0] = tableRows[i][0] + '.' + order;
          order = 1;
        }
      }
    }

    return tableRows;
  }

  // 合并表格数据转标准表格数据
  // @params {MergeTableData}  mergeTableData，合并表格数据
  // @return {TableData} tableData，表格数据
  function mergeTableData2tableData(mergeTableData) {
    const tableHead = mergeTableData.slice(0, 1);
    const tableRows = mergeTableData.slice(1);
    const minColumnCount = Math.min(...tableRows.map(row => row.length));
    const tempRows = [];

    // 补齐缺省
    tableRows.forEach((tr, i) => {
      if (tr.length > minColumnCount) {
        tempRows[i] = tr;
      } else {
        tempRows[i] = tempRows[i - 1].slice(0, 2).concat(tr);
      }
    });

    // 合并主副标题
    tempRows.forEach(tr => {
      // 合并主副标题
      tr[1] = [tr[1], tr[2]].filter(text => text.trim()).join('/');

      // 删除多余合并项，删除副标题栏目
      tr.splice(2, 1);
    });

    // 更新序号
    const newTableRows = updateOrder(tempRows);

    return tableHead.concat(newTableRows);
  }

  // 处理表格合并模式
  function handleTopicTableMergeType(tableInfo) {
    const { titleTable, meetingTable, topicTable } = tableInfo;

    const colspanTds = topicTable.querySelectorAll('[colspan]');
    const titleReg = KEY_WORD_MAP.get('topicTableTitleColumn');
    // 如果有列合并，只处理单个栏目合并，且合并栏目是议题名称，且合并项为2
    if (!(colspanTds.length === 1 && titleReg.test(colspanTds[0].innerText) && colspanTds[0].getAttribute('colspan') === '2')) {
      console.error('welink-email-page', 'handleTopicTableMergeType, colspan is not topic');
      throw new Error();
    }

    const mergeTopicData = parseTable(topicTable);
    // 只处理表头第一列是编号的合并
    if (!mergeTopicData[0][0].includes('No.')) {
      console.error('welink-email-page', 'handleTopicTableMergeType, first thead row is not No.');
      throw new Error();
    }

    let htmlStr = '';

    // 处理邮件内容
    const emailHtmlStr = getEmailHtmlStr(meetingTable);
    htmlStr = emailHtmlStr;

    // 处理非table的标题会议——标题会议是div
    // eg: 08:15
    const titleData = handleTitleDiv(meetingTable);
    htmlStr += titleData2htmlStr(titleData);

    // 处理table
    const tableHtml = getTableHtmlStr(meetingData => {
      const topicData = mergeTableData2tableData(mergeTopicData);
      const topicIndex = meetingData.findIndex(tr => KEY_WORD_MAP.get('topicTableKey').test(tr[0]));
      meetingData[topicIndex][1] = topicData;
    });
    htmlStr = tableHtml;

    document.body.innerHTML = htmlStr;
  }

  /**********************************表格合并处理*****************************************/


  /**********************************没有会议表格错误处理*****************************************/
  function handleMeetingTableEmptyErrorType() {
    // 1.没有会议表格的纯文本会议——eg: 测试的会议标题5
    const containers = document.querySelectorAll('body > div');
    if (containers.length === 1) {
      const container = containers[0];
      const children = container.children;
      // 只有一个子元素，且标签是SPAN或P
      if (children && children.length === 1 && ['SPAN', 'P'].includes(children[0].tagName)) {
        console.log('welink-email-page', `handleMeetingTableErrorType， only div text`);

        if (children[0].innerText.trim()) {
          // 样式调整
          addStyle(container, ';display: flex;align-items: center;min-height: 56px;padding: 9pt 10pt;border-radius: 20px;background: #fff;');
        } else {
          // 没有内容——eg: 测试的会议标题33
          console.log('welink-email-page', `handleMeetingTableErrorType， no text`);
        }

        return;
      }
    }

    // 2.单个表格单列的纯文本会议——eg: 测试的会议标题9
    const tdList = document.querySelectorAll('td');
    const blockquoteEl = document.querySelector('td > blockquote');
    if (tdList.length === 1 && blockquoteEl) {
      console.log('welink-email-page', `handleMeetingTableErrorType， only table text`);

      if (blockquoteEl.innerText.trim()) {
        // 样式调整
        addStyle(document.querySelector('table'), ';height: auto;border-radius: 20px;overflow: hidden;');
        addStyle(tdList[0], ';padding-top: 16px;height: auto;');
        addStyle(document.querySelector('table blockquote'), ';margin-left: 10pt;margin-right: 10pt;');
      } else {
        console.log('welink-email-page', `handleMeetingTableErrorType， no text`);
      }

      return;
    }

    console.error('welink-email-page', 'handleMeetingTableEmptyErrorType');
    // 08:53 | 09:12
    // 08:59 | 09:03
    // 09:26 底部多余空行
    // 10:55 没有内容
    throw new Error();
  }

  /**********************************没有会议表格错误处理*****************************************/


  /**********************************无法解析处理*****************************************/
  // 处理表格宽度自适应
  function resetTableWidth() {
    // 防止议题内部td宽度固定值过大，右侧边框不显示，重置宽度——eg: 11:47
    const hasAgendaTr = Array.from(document.querySelectorAll('tr')).find(tr => tr.innerText.includes('会议议题'));
    // 议题表格以多个td形式往下排
    if (hasAgendaTr && hasAgendaTr?.children?.length > 2) {
      // 所有td均设置固定宽度
      addStyles(document.querySelectorAll('td'), ';width: unset;');
    }
  }

  // 处理表格高度自适应
  function resetTableHeight() {
    // 防止表格父级容器固定高度过小
    Array.from(document.querySelectorAll('table')).forEach(table => {
      const wrap = table?.parentElement;
      // 防止表格父级容器固定高度过小，页面被压缩部分不显示——测试会议25
      if (wrap && wrap?.style?.height) {
        wrap.style.height = 'auto';
      }

      // 防止背景容器高度不足，背景色无法完全包裹表格——测试会议17
      if (wrap && wrap?.style?.background) {
        wrap.style.background = 'transparent';
      }
    });

    // 设置最后一个表格高度自动，防止文字超出——09：42
    const contentTable = document.querySelector('div > table:last-of-type');
    if (contentTable) {
      const lastTr = Array.from(contentTable.querySelectorAll('tr')).slice(-1)[0];
      const validTds = Array.from(lastTr.children).filter(td => td?.innerText?.trim());

      if (validTds.length === 2) {
        addStyle(validTds[1], `;height: auto;`);
      }
    }
  }

  // 处理表格特殊格式
  function resetTableSpecial() {
    // 防止表格内容显示空间不足下移重叠，去除td的display属性
    Array.from(document.querySelectorAll('td')).forEach(td => {
      if (td && td?.style?.display === 'inline-block') {
        td.style.display = '';
      }
    });
  }

  // 表格样式重置——适配固定宽高
  function resetTable() {
    // 防止宽度固定值过大，横向滚动——测试会议28
    // 防止宽度固定值过小，展示不全——08:34
    addStyles(document.querySelectorAll('table'), ';width: 100%;');
    // 防止右侧边框被截断—测试会议28
    addStyle(document.body, `;padding-right: 2px;`);

    // 防止内层表格td宽度固定值过大，右侧边框不显示——测试会议25
    addStyles(document.querySelectorAll('td > table td'), ';width: unset;');

    // 移除文字白底——eg：12:38
    addStyles(document.querySelectorAll('span'), `;background: transparent;`);

    // 处理表格宽度自适应
    resetTableWidth();
    // 处理表格高度自适应
    resetTableHeight();
    // 处理表格特殊格式
    resetTableSpecial();
  }

  // table外层div设置居中属性，无需重置表格样式，保持居中
  // document.querySelector('table').parentElement.align
  function tableParentAlignIsCenter() {
    const tables = document.querySelectorAll('table');
    if (tables.length !== 1) {
      console.warn('welink-email-page', `tableParentAlignIsCenter tables is ${tables.length}`);
      return false;
    }

    const parent = tables[0].parentElement;
    if (!parent) {
      console.warn('welink-email-page', `tableParentAlignIsCenter parent is null`);
      return false;
    }

    console.info('welink-email-page', `tableParentAlignIsCenter parent align is ${parent.align}`);
    return parent.align === 'center';
  }

  // 错误加载-恢复原有结构
  function handleErrorType(oldHTML) {
    console.error('welink-email-page', 'handleErrorType');
    window.mailObj?.onParseStatusChange?.(false);
    document.documentElement.innerHTML = oldHTML;

    // 重置表格
    if (!tableParentAlignIsCenter()) {
      resetTable();
    }

    // 手机平板,链接置灰
    if (window.mailObj?.getWelinkInfoDisplayParams()?.isRemoveLink) {
      console.log('welink-email-page', `page link is disabled`);
      removeLink();
    }

    setTimeout(() => {
      resetWebHeight();
    }, 20);
  }

  /**********************************无法解析处理*****************************************/
  // 通用转置处理
  function baseRelayout(needStyle, callback) {
    window.mailObj?.onParseStatusChange?.(true);

    if (needStyle) {
      insertStyle(CSS_STYLE);
    }

    if (typeof (callback) === 'function') {
      callback();
    }

    disableZoomPage();
    resetWebHeight();
  }

  // 竖版重置——表格转置处理
  function relayout(tableInfo, oldHTML) {
    const type = getModeType(tableInfo);
    console.log('welink-email-page', type);

    try {
      switch (type) {
        case MODE_TYPE.NORMAL:
          baseRelayout(true, () => handleNormalType(tableInfo));
          break;
        case MODE_TYPE.TOPIC_TABLE_MERGE_ERROR:
          baseRelayout(true, () => handleTopicTableMergeType(tableInfo));
          break;
        case MODE_TYPE.MEETING_TABLE_EMPTY_ERROR:
          baseRelayout(false, () => handleMeetingTableEmptyErrorType(tableInfo));
          break;
        default:
          handleErrorType(oldHTML);
      }

      // 手机平板,链接置灰
      if (window.mailObj?.getWelinkInfoDisplayParams()?.isRemoveLink) {
        console.log('welink-email-page', `page link is disabled`);
        removeLink();
      }
    } catch (e) {
      console.error('welink-email-page', `page relayout error ${e?.message}`);
      handleErrorType(oldHTML);
    }
  }


  /**********************************原版改造*****************************************/
  // 设置Tr高度
  function restoreTrHeight(meetingTable) {
    let trList = Array.from(meetingTable.children[0].children);
    for (let i = 0; i < trList.length; i++) {
      const tdList = Array.from(trList[i].querySelectorAll('td'));
      tdList.forEach(td => addStyle(td, ';height: 70px;padding-top: 4px;padding-bottom: 4px;'));
    }
  }

  // 设置背景色
  function restoreSetBgOfTr(meetingTable) {
    let trList = Array.from(meetingTable.children[0].children);
    for (let i = 0; i < trList.length; i++) {
      const tr = trList[i];
      const td = tr.querySelector('td:last-of-type');
      if (i % 2 === 0) {
        addStyle(td, ';background-color: #fff;');
      } else {
        addStyle(td, ';background-color: #f8f8f8;');
      }
    }
  }

  // 增加宽度
  function restoreWidthOfTd(meetingTable, width = '16%') {
    let trList = Array.from(meetingTable.children[0].children);
    for (let i = 0; i < trList.length; i++) {
      const tr = trList[i];
      const td = tr.querySelector('td:first-of-type');

      if (tr.children.length !== 2) {
        console.log('welink-email-page', `restoreWidthOfTd, tr children length is not 2`);
        // tr里面的td不是2个——eg：12:38
        throw new Error();
      }

      if (!td.innerText.trim()) {
        console.log('welink-email-page', `restoreWidthOfTd, the first td is empty`);
        throw new Error();
      }

      addStyle(td, `;width: ${width};padding-left: 7pt;padding-right: 7px;`);
    }
  }

  // 调整视频会议
  function restoreVideoMeeting(meetingTable) {
    let trList = Array.from(meetingTable.children[0].children);
    let videoMeetingTr = trList.find(tr => tr.innerText.includes('Video Meeting'));

    if (videoMeetingTr) {
      let videoMeetingLastTd = videoMeetingTr.querySelector('td:last-of-type');
      addStyle(videoMeetingLastTd, ';line-height: 1.5;');

      if (videoMeetingLastTd.querySelector('td')) {
        // td > table > tr > td + td
        let [guestTr, hostTr] = videoMeetingLastTd.querySelectorAll('tr');
        let [guest, id] = guestTr?.children || [];
        let [host] = hostTr?.children || [];

        // 匹配中英文
        // 加入会议(Guest) =>加入会议
        // Join(Guest) =>Join
        if (guest) {
          guest.querySelector('a').innerText = removeBracketsText(guest.querySelector('a').innerText);
        } else {
          console.warn('welink-email-page', `guest is null`);
        }

        if (host) {
          host.querySelector('a').innerText = removeBracketsText(host.querySelector('a').innerText);
        } else {
          console.warn('welink-email-page', `host is null`);
          // 没有host——eg：09:13
        }

        addStyles(id.querySelectorAll('span'), ';padding-left: 0;padding-right: 6px;');
        addStyles(videoMeetingLastTd.querySelectorAll('a'), ';padding-right: 6px;');

        videoMeetingLastTd.innerHTML = [
          id ? id.children[0].parentNode.innerHTML : '',
          host ? host.querySelector('a').parentNode.innerHTML : '',
          guest ? guest.querySelector('a').parentNode.innerHTML : '',
        ].join('');
      } else if (videoMeetingLastTd.querySelector('a')) {
        // 兼容重复日程
        // td > a + id + a
        const matches = videoMeetingLastTd.innerText.match(/(Meeting ID: \d+)/);
        guest = videoMeetingLastTd.querySelector('a');
        host = videoMeetingLastTd.querySelector('a:last-of-type');
        idText = matches ? matches[0] : '';

        guest.innerText = removeBracketsText(guest.innerText);
        host.innerText = removeBracketsText(host.innerText);
        addStyles(videoMeetingLastTd.querySelectorAll('a'), ';padding-right: 6px;');

        videoMeetingLastTd.innerHTML = `<span style="padding-right: 6px;">${idText}</span>`;
        videoMeetingLastTd.appendChild(host);
        videoMeetingLastTd.appendChild(guest);
      }
    }
  }

  // 调整语音会议
  function restoreVoiceMeeting(meetingTable) {
    let trList = Array.from(meetingTable.children[0].children);
    let voiceMeetingTr = trList.find(tr => tr.innerText.includes('Voice Meeting'));

    if (voiceMeetingTr) {
      let voiceMeetingLastTd = voiceMeetingTr.children[1];
      let tdList = Array.from(voiceMeetingLastTd.querySelectorAll('td'));
      let [d1, d2, d3, d4, d5] = tdList;
      voiceMeetingLastTd.innerHTML = `
        <span>${d1.innerHTML} | ${d2.innerHTML}</span>
        <span>${d3.innerHTML} | ${d4.innerHTML}</span>
        ${d5.innerHTML}
      `;

      addStyle(voiceMeetingLastTd, ';display: flex;flex-direction: column;' +
        'height: auto;min-height: 70px;line-height: 1.5;');
      addStyles(voiceMeetingLastTd.querySelectorAll('span'), ';padding: 0;');
    }
  }

  // 调整内容格式
  function restoreContent(meetingTable, keyWord = 'Attendees') {
    const AttendeesTr = findTr(meetingTable, keyWord);
    // 没有与会人
    if (!AttendeesTr) {
      return;
    }
    // 与会人不是两列
    if (AttendeesTr.children.length !== 2) {
      return;
    }

    const content = AttendeesTr.children[1];

    addStyle(content, ';display: revert;');
    content.innerHTML = content.innerText.trim();
  }

  // 设置圆角
  function restoreRadius(titleTable, meetingTable) {
    // 有边框无需圆角——测试会议20
    if (meetingTable.border && meetingTable.border > 0) {
      console.log('welink-email-page', `restoreRadius meetingTable has border`);
      return;
    }

    // 有标题表格，圆角均摊
    if (titleTable) {
      addStyle(titleTable, ';border-top-left-radius: 20px;border-top-right-radius:20px;overflow: hidden;');
      addStyle(meetingTable, ';border-bottom-left-radius: 20px;border-bottom-right-radius:20px;overflow: hidden;');
    } else {
      addStyle(meetingTable, ';border-radius: 20px;overflow: hidden;');
    }
  }

  function handleTitleDiv(meetingTable, callback) {
    if (!meetingTable) {
      console.log('welink-email-page', `handleTitleDiv meetingTable is null`);
      return [];
    }

    // 标题会议不是table，而是div
    // eg: 08:15
    const titleDiv = meetingTable.previousElementSibling;
    const tabledata = [];
    if (titleDiv && titleDiv.tagName === 'DIV' && titleDiv.innerText.includes('WeMeeting')) {
      const children = Array.from(titleDiv.children);
      children.forEach(child => {
        if (child.innerText.includes('WeMeeting')) {
          tabledata.push([child.innerText]);
        } else if (tabledata.length === 1 && child.tagName === 'A') {
          // content
          tabledata.push([child.innerText]);
        }
      });

      callback && callback(titleDiv);
    }

    return tabledata;
  }

  // 添加标题表格
  function addTitleTable(meetingTable) {
    const titleTableData = handleTitleDiv(meetingTable, titleDiv => addStyle(titleDiv, 'display: none;'));

    if (titleTableData.length === 0) {
      console.log('welink-email-page', `addTitleTable titleTableData is null`);
      return null;
    }

    if (!Array.isArray(titleTableData[0]) || !Array.isArray(titleTableData[1])) {
      console.error('welink-email-page', 'addTitleTable, table data is not table');
      throw new Error();
    }

    let wrap = document.createElement('div');
    let title = titleTableData[0][0].trim();
    let content = titleTableData[1][0].trim();

    // 替换换行符
    title = title.replace(' ', '<br>').replace('(', '<br>').replace(')', '');
    const table = `
      <table cellspacing="0" style="width: 100%;height: 70px;">
        <tbody>
          <tr>
            <td style="border-bottom:1px solid #fff;border-right:1px solid #fff;padding-left: 7pt;padding-right: 7px; width:20%;padding-top: 4px;
            padding-bottom: 4px;background-color: rgb(243,249,255);font-weight:bolder;word-break:break-all">${title}</td>
            <td style="display: flex;align-items: center;padding:9pt 10pt;height: 100%;background-color: #f8f8f8;border-bottom: 1px solid #fff;">${content}</td>
          </tr>
        <tbody>
      <table>
     `;

    wrap.innerHTML = table;
    meetingTable.parentNode.insertBefore(wrap.children[0], meetingTable);

    return meetingTable.previousElementSibling;
  }

  // 调整标题表格
  function restoreTitleTable(titleTable) {
    addStyle(titleTable, ';width: 100%;height: 70px;');

    const [titleTr, linkTr] = titleTable.querySelectorAll('tr');
    // 内容tr有两个td——eg：测试的会议12
    const [titleTd, contentTd] = Array.from(titleTr.children);
    const [linkTd] = Array.from(linkTr.children);

    // 空格替换换行符
    // 括号替换换行符——eg：10：00
    let title = `<p style="white-space: pre-line !important">${titleTd.innerText.replace(' ', '\n').replace('(', '\n').replace(')', '')}</p>`;
    let content = linkTd?.innerHTML ?? contentTd?.innerHTML ?? '';

    titleTr.innerHTML = `
      <td style="border-bottom:1px solid #fff;border-right:1px solid #fff;padding-left: 7pt;padding-right: 7px; width:20%;padding-top: 4px;
      padding-bottom: 4px;background-color: rgb(243,249,255);font-weight:bolder;word-break:break-all">${title}</td>
      <td style="display: flex;align-items: center;padding:9pt 10pt;height: 100%;background-color: #f8f8f8;border-bottom: 1px solid #fff;">${content}</td>
    `;
    addStyle(linkTr, ';display: none;');
  }

  // 调整会议表格
  function restoreMeetingTable(meetingTable, titleTable) {
    // 重置高度
    restoreTrHeight(meetingTable);
    // 设置背景色
    restoreSetBgOfTr(meetingTable);
    // 增加宽度
    restoreWidthOfTd(meetingTable, '20%');
    // 调整视频会议
    restoreVideoMeeting(meetingTable);
    // 调整语音会议
    restoreVoiceMeeting(meetingTable);
    // 调整与会人
    restoreContent(meetingTable, 'Attendees');
    // 调整会议公告
    restoreContent(meetingTable, 'Bulletins');
    // 设置圆角
    restoreRadius(titleTable, meetingTable);
  }

  // 重置表格
  function restoreResetTable(meetingTable) {
    // 表格样式重置——适配固定宽高
    resetTable();

    if (meetingTable) {
      // 表格边框是黑色——eg: 08:41
      addStyles(meetingTable.querySelectorAll('td'), ';border-color: white;');
    }
  }

  // 原版改造——调整表格样式
  function restore(tableInfo, oldHTML) {
    let { titleTable, meetingTable } = tableInfo;

    try {
      if (titleTable) {
        restoreTitleTable(titleTable);
      } else {
        console.warn('welink-email-page', `restore titleTable is null`);
        // 标题表格是DIV——测试的会议标题14
        titleTable = addTitleTable(meetingTable);
      }

      if (meetingTable) {
        addStyle(meetingTable, ';width: 100%;');
        restoreMeetingTable(meetingTable, titleTable);
      } else {
        console.log('welink-email-page', `restore meetingTable is null`);
        handleMeetingTableEmptyErrorType();
      }

      // 重置表格
      restoreResetTable(meetingTable);

      // 手机平板,链接置灰
      if (window.mailObj?.getWelinkInfoDisplayParams()?.isRemoveLink) {
        console.log('welink-email-page', `page link is disabled`);
        removeLink();
      }

      // 禁止缩放
      disableZoomPage();
      // 重置高度
      resetWebHeight();
    } catch (e) {
      console.error('welink-email-page', `page restore error ${e?.message}`);
      handleErrorType(oldHTML);
    }
  }

  /**********************************原版改造*****************************************/

  window.onload = function () {
    console.log('welink-email-page', `page is ${window.mailObj?.getPageInfo()?.name}`);
    console.log('welink-email-page', `isRemoveLink  ${window.mailObj?.getWelinkInfoDisplayParams()?.isRemoveLink}`);
    console.log('welink-email-page', `isTranspose  ${window.mailObj?.getWelinkInfoDisplayParams()?.isTranspose}`);

    // 挂载在window上，供外部WebviewController使用
    window.commonResetWebHeight = resetWebHeight;

    // 更新页面宽度
    window.mailObj?.onWidthChange(document.body.offsetWidth);

    // 存储旧的结构
    const oldHTML = document.documentElement.innerHTML;

    const isTranspose = window.mailObj?.getWelinkInfoDisplayParams()?.isTranspose;
    const isMainPage = window.mailObj?.getPageInfo()?.name === 'main_page_nav_destination';
    const tableInfo = getTableInfo();

    if (isTranspose || isMainPage) {
      console.log('welink-email-page', `page will be relayout`);
      relayout(tableInfo, oldHTML);
    } else {
      console.log('welink-email-page', `page will be restore`);
      restore(tableInfo, oldHTML);
    }
  };
})(window);