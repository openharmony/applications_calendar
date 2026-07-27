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

import zlib from '@ohos.zlib';

import { Log } from '../default/common/Log';
import { Result } from '../templates/Result';

export type ZipOptions = zlib.Options;

const TAG = 'ZipUtils';

/*
 * zip工具类
 *
 */

const defaultOptions: ZipOptions = {
  level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
  memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
  strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
};


export async function compressFile(inFile: string, outFile: string,
                                   options: ZipOptions = defaultOptions): Promise<Result<boolean>> {
  try {
    await zlib.compressFile(inFile, outFile, options);
    return Result.buildSuccessResult(true);
  } catch (error) {
    Log.logErrorMsg(TAG, 'compressFile', error);
    return Result.buildByErrorWithData(error, false);
  }
}

export async function decompressFile(inFile: string, outFile: string,
                                     options: ZipOptions = defaultOptions): Promise<Result<boolean>> {
  try {
    await zlib.decompressFile(inFile, outFile, options);
    return Result.buildSuccessResult(true);
  } catch (error) {
    Log.logErrorMsg(TAG, 'decompressFile', error);
    return Result.buildByErrorWithData(error, false);
  }
}

export async function compressFiles(inFiles: string[], outFile: string,
                                    options: ZipOptions = defaultOptions): Promise<Result<boolean>> {
  try {
    await zlib.compressFiles(inFiles, outFile, options);
    return Result.buildSuccessResult(true);
  } catch (error) {
    Log.logErrorMsg(TAG, 'compressFiles', error);
    return Result.buildByErrorWithData(error, false);
  }
}