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

import { Log } from '@app/common/src/main/ets/default/common/Log';
import { ResponseInterceptor } from './interceptor/ResponseInterceptor';
import { LogInterceptor } from './interceptor/LogInterceptor';
import { HttpClient, HttpClientConfig, HttpInterceptor, ServerAuthConfig } from './HttpClient';

// ======================== 类型定义 ========================

/**
 * 请求头类型（替代 rcp.RequestHeaders）
 */
export type RequestHeaders = Record<string, string | string[]>;

/**
 * TLS 配置（替代 rcp.TlsV12Option）
 */
export interface TlsConfig {
  tlsVersion: string;
  cipherSuite: string[];
}

/**
 * URL 或字符串（替代 rcp.URLOrString）
 */
export type URLOrString = string;

/**
 * RequestEngineBuilder — 使用 HttpClient 替代 rcp.Session
 */
export class RequestEngineBuilder {
  private interceptors: HttpInterceptor[] = [];
  private baseAddress?: URLOrString;
  private commonRequestHeaders: RequestHeaders = {};
  private cookies: Record<string, string> = {};
  private prefixTag: string = '';
  private tlsConfig: TlsConfig = {
    tlsVersion: 'TlsV1.2',
    cipherSuite: [
      'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
      'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
    ]
  };
  private connectTimeout: number = 20000;
  private transferTimeout: number = 60000;
  private autoRedirect: boolean = true;
  private serverAuth?: ServerAuthConfig;

  constructor() {
  }

  setPrefixTag(prefixTag: string): RequestEngineBuilder {
    this.prefixTag = prefixTag;
    return this;
  }

  appendInterceptor(interceptor: HttpInterceptor): RequestEngineBuilder {
    this.interceptors.push(interceptor);
    return this;
  }

  appendInterceptors(interceptors: HttpInterceptor[]): RequestEngineBuilder {
    this.interceptors.push(...interceptors);
    return this;
  }

  appendRequestHeader(name: string, value: string): RequestEngineBuilder {
    this.commonRequestHeaders[name] = value;
    return this;
  }

  appendCookie(name: string, values: string): RequestEngineBuilder {
    this.cookies[name] = values;
    return this;
  }

  appendRequestHeaders(name: string, values: string[]): RequestEngineBuilder {
    this.commonRequestHeaders[name] = values;
    return this;
  }

  /**
   * 设置配置（支持 rcp.Configuration 的部分字段迁移）
   * @param config 包含 security 和 transfer 配置
   */
  setConfiguration(config: ConfigurationInput): RequestEngineBuilder {
    if (config.security) {
      if (config.security.remoteValidation) {
        // remoteValidation 在 HttpClient 中由系统默认处理
        Log.info('RequestEngine', 'remoteValidation set to: ' + config.security.remoteValidation);
      }
      if (config.security.tlsOptions) {
        this.tlsConfig = {
          tlsVersion: config.security.tlsOptions.tlsVersion ?? this.tlsConfig.tlsVersion,
          cipherSuite: config.security.tlsOptions.cipherSuite ?? this.tlsConfig.cipherSuite
        };
      }
      if (config.security.serverAuthentication) {
        this.serverAuth = {
          username: config.security.serverAuthentication.credential?.username ?? '',
          password: config.security.serverAuthentication.credential?.password ?? '',
          type: config.security.serverAuthentication.authenticationType === 'digest' ? 'digest' : 'basic'
        };
      }
    }
    if (config.transfer) {
      if (config.transfer.timeout) {
        this.connectTimeout = config.transfer.timeout.connectMs ?? this.connectTimeout;
        this.transferTimeout = config.transfer.timeout.transferMs ?? this.transferTimeout;
      }
      if (config.transfer.autoRedirect !== undefined) {
        this.autoRedirect = config.transfer.autoRedirect;
      }
    }
    return this;
  }

  setBaseUrl(baseAddress: URLOrString): RequestEngineBuilder {
    this.baseAddress = baseAddress;
    return this;
  }

  /**
   * 构建 HttpClient（替代 rcp.Session）
   */
  build(): HttpClient {
    const finalInterceptors: HttpInterceptor[] = [];
    finalInterceptors.push(new LogInterceptor(this.prefixTag));
    finalInterceptors.push(...this.interceptors);
    finalInterceptors.push(new ResponseInterceptor(this.prefixTag));

    const config: HttpClientConfig = {
      interceptors: finalInterceptors,
      baseAddress: this.baseAddress,
      headers: this.commonRequestHeaders,
      connectTimeout: this.connectTimeout,
      transferTimeout: this.transferTimeout,
      serverAuthentication: this.serverAuth
    };

    return new HttpClient(config);
  }
}

/**
 * 超时配置输入
 */
export interface TimeoutInput {
  connectMs?: number;
  transferMs?: number;
}

/**
 * 传输配置输入
 */
export interface TransferInput {
  timeout?: TimeoutInput;
  autoRedirect?: boolean;
}

/**
 * 凭证输入
 */
export interface CredentialInput {
  username?: string;
  password?: string;
}

/**
 * 服务器认证配置输入
 */
export interface ServerAuthInput {
  credential?: CredentialInput;
  authenticationType?: string;
}

/**
 * 安全配置输入
 */
export interface SecurityInput {
  remoteValidation?: string;
  tlsOptions?: TlsConfig;
  serverAuthentication?: ServerAuthInput;
}

/**
 * 配置输入接口（兼容原 rcp.Configuration 的参数结构）
 */
export interface ConfigurationInput {
  security?: SecurityInput;
  transfer?: TransferInput;
}