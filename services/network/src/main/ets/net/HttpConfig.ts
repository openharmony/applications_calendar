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

export enum DavMethod {
  COPY = 'COPY',

  LOCK = 'LOCK',

  MK_COL = 'MKCOL',

  MOVE = 'MOVE',

  PROP_FIND = 'PROPFIND',

  PROP_PATCH = 'PROPPATCH',

  UNLOCK = 'UNLOCK',

  REPORT = 'REPORT',

  SEARCH = 'SEARCH',

  MK_CALENDAR = 'MKCALENDAR'
}

export enum HttpMethod {
  GET = 'GET',

  HEAD = 'HEAD',

  POST = 'POST',

  PUT = 'PUT',

  DELETE = 'DELETE',

  CONNECT = 'CONNECT',

  OPTIONS = 'OPTIONS',

  TRACE = 'TRACE',

  PATCH = 'PATCH'
}

/**
 * HTTP request headers.
 * @typedef RequestHeaders
 * @syscap SystemCapability.Collaboration.RemoteCommunication
 * @since 4.1.0(11)
 */
export type RequestHeaders = {
  [k: string]: string | string[];
  'authorization'?: string;
  'accept'?: ContentType | ContentType[];
  'accept-charset'?: string | string[];
  'accept-encoding'?: ContentCoding | ContentCoding[];
  'accept-language'?: string | string[];
  'cache-control'?: string | string[];
  'cookie'?: string | string[];
  'range'?: string | string[];
  'upgrade'?: string | string[];
  'user-agent'?: string;
  'content-type'?: ContentType;
};

/**
 * HTTP response headers.
 * @typedef ResponseHeaders
 * @syscap SystemCapability.Collaboration.RemoteCommunication
 * @since 4.1.0(11)
 */
export type ResponseHeaders = {
  [k: string]: string | string[] | undefined;
  'accept-ranges'?: 'none' | 'bytes' | (string & NonNullable<unknown>);
  'allow'?: HttpMethod | HttpMethod[];
  'cache-control'?: string | string[];
  'content-encoding'?: ContentCoding;
  'content-range'?: string;
  'content-type'?: ContentType;
  'date'?: string;
  'etag'?: string;
  'expires'?: string;
  'location'?: string;
  'retry-after'?: string;
  'set-cookie'?: string | string[];
  'server'?: string;
  'www-authenticate'?: string | string[];
};

/**
 * HTTP request predefined content types.
 * @typedef ContentType
 * @syscap SystemCapability.Collaboration.RemoteCommunication
 * @since 4.1.0(11)
 */
export type ContentType =
  | 'application/json'
    | 'text/plain'
    | 'multipart/form-data'
    | 'application/octet-stream'
    | 'application/x-www-form-urlencoded'
    | (string & NonNullable<unknown>);


export type ContentCoding =
  | 'aes128gcm'
    | 'br'
    | 'compress'
    | 'deflate'
    | 'exi'
    | 'gzip'
    | 'pack200-gzip'
    | 'x-compress'
    | 'x-gzip'
    | 'zstd'
    | (string & NonNullable<unknown>);
