@rem
@rem Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem     http://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@echo off

@rem ##########################################################################
@rem
@rem  fetch hap sign tools for Windows
@rem
@rem ##########################################################################

@if "%DEBUG%" == "" @echo off

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0

if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%

set SIGN_TOOL_PATH=%APP_HOME%\signature\hap-sign-tool.jar
if not exist %SIGN_TOOL_PATH% (
    echo "sign tool is not exist. Start downloading..."
    copy "%HM_SDK_HOME%\10\toolchains\lib\hap-sign-tool.jar" "%SIGN_TOOL_PATH%"
) else (
    echo "sign tool is exist."
)
set SIGN_PLUGIN_PATH=%APP_HOME%\signature\hapsign-online-plugin.jar
if not exist %SIGN_PLUGIN_PATH% (
    echo "sign plugin is not exist. Start downloading..."
    curl -k "https://cmc.cloudartifact.whu.dragon.tools.openharmony.com/artifactory/trc-software-release/HMOS-Prototype/HMOS-Prototype%%202.0/HAPSIGNTOOLPLUGIN%%202.0.0.1/Software/IRDDepend_hapsigner_ext_OpenHarmony-Master-ALL-Global-Full-None_20230420_01/related_file/hapsign-online-plugin.jar" -o "%SIGN_PLUGIN_PATH%"
) else (
    echo "sign plugin is exist."
)