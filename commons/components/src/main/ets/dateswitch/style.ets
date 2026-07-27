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

/**
 * DateSwitch组件的尺寸、颜色等UI信息
 *
 * @since 2022-03-21
 */
const style: StyleInter = {
  button: {
    bg: '#E3E3E3', // 背景颜色
    fontColor: '#000000', // 字体颜色
    fontWeight: 400, // 字重
    fontSize: 14, // 字体大小
    width: 72, // 按钮宽度
    height: 32, // 按钮高度
    borderRadius: 8 // 按钮圆角
  },
  arrow: {
    margin: 16, // 箭头左右间距
    size: 24, // 箭头长宽尺寸
  },
  dropdown: {
    width: 90, // 宽度
    height: 32, // 高度
    bg: '#FFFFFF', // 背景颜色
    fontSize: 14, // 文字大小
    fontColor: '#000000', // 文字颜色
    arrowSize: 24, // 箭头尺寸
    border: {
      // 边框样式
      color: '#33000000',
      radius: 8,
      width: 1
    },
    innerPadding: {
      // 内边距
      left: 8,
      right: 8
    }
  },
  dropdownList: {
    listBorderRadius: 16, // 列表的边框圆角尺寸
    itemBorderRadius: 8, // 列表子项的边框圆角尺寸
    innerPadding: 4, // 列表内部的padding
    bg: '#FFFFFF', // 背景颜色
    shadow: {
      // 阴影
      radius: 50,
      color: '#26000000'
    },
    width: 156, // 列表宽度
    height: 340, // 列表高度
    marginTop: 8, // dropdownList和dropdown的间距
  },
  dropdownListItem: {
    itemHeight: 48, // 列表项高度
    itemBorderRadius: 8, // 列表项圆角尺寸
    innerPadding: {
      // 内边距
      left: 12,
      right: 12
    },
    checkImgSize: 24, // 列表项选中图标的尺寸
    fontSize: 16, // 字体大小
    dividerWidth: '1px', // 列表项分割线宽度
    dividerColor: '#0C000000', // 分割线颜色
    getTextColor(checked: Object): string {
      return checked ? '#FFFFFF' : '#000000';
    },
    getBackgroundColor(checked: Object): string {
      return checked ? '#0A59F7' : '';
    },
    imgTextGap: 6 // 图片文字的间距
  }
};

export { style };

interface ButtonInter {
  bg: string // 背景颜色
  fontColor: string; // 字体颜色
  fontWeight: number; // 字重
  fontSize: number; // 字体大小
  width: number; // 按钮宽度
  height: number; // 按钮高度
  borderRadius: number; // 按钮圆角
}

interface ArrowInter {
  margin: number;
  size: number;
}

interface DropdownInter {
  width: number; // 宽度
  height: number; // 高度
  bg: string; // 背景颜色
  fontSize: number; // 文字大小
  fontColor: string; // 文字颜色
  arrowSize: number; // 箭头尺寸
  border: borderInter;
  innerPadding: InnerPaddingInter;
}

interface borderInter {
  color: string;
  radius: number;
  width: number;
}

interface InnerPaddingInter {
  left: number;
  right: number;
}

interface DropdownListInter {
  listBorderRadius: number, // 列表的边框圆角尺寸
  itemBorderRadius: number, // 列表子项的边框圆角尺寸
  innerPadding: number, // 列表内部的padding
  bg: string, // 背景颜色
  shadow: ShadowInter,
  width: number, // 列表宽度
  height: number, // 列表高度
  marginTop: number, // dropdownList和dropdown的间距
}

interface ShadowInter {
  radius: number;
  color: string;
}

interface DropdownListItemInter {
  itemHeight: number; // 列表项高度
  itemBorderRadius: number; // 列表项圆角尺寸
  innerPadding: InnerPaddingInter;
  checkImgSize: number; // 列表项选中图标的尺寸
  fontSize: number; // 字体大小
  dividerWidth: string; // 列表项分割线宽度
  dividerColor: string; // 分割线颜色
  getTextColor: Function;
  getBackgroundColor: Function;
  imgTextGap: number; // 图片文字的间距
}

interface StyleInter {
  button: ButtonInter;
  arrow: ArrowInter;
  dropdown: DropdownInter;
  dropdownList: DropdownListInter;
  dropdownListItem: DropdownListItemInter;
}