#!/bin/bash

#
# Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -ex
export DEVECO_SDK_HOME=${HOS_SDK_HOME}

# NODE_HOME的环境变量多配置了一个bin目录, 在这里去除掉
[[ "${NODE_HOME}" =~ .*\bin$ ]] && NODE_HOME=${NODE_HOME%\bin*}
node -v
npm -v
# Setup npm
npm config list
npm config set registry https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/npm/npm-central-repo/
npm config set @ohos:registry https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/npm/product_npm/
npm config set strict-ssl false
# 初始化相关路径
APP_HOME=$(pwd -P)
PROJECT_PATH=$(pwd -P)  # 工程目录
TOOLS_INSTALL_ROOT_DIR="$PROJECT_PATH"

# 根据业务情况适配local.properties
cd "${APP_HOME}"

# 如果构建过程报错 ERR_PNPM_OUTDATED_LOCKFILE，需要增加配置：lockfile=false
cat ${HOME}/.npmrc | grep 'lockfile=false' || echo 'lockfile=false' >> ${HOME}/.npmrc

# 获得签名jar文件
cd $APP_HOME/signature
chmod +x build.sh
./build.sh

cd ${APP_HOME}

function init_dir()
{
  if [ ! -d "$TOOLS_INSTALL_ROOT_DIR" ]; then
    mkdir "$TOOLS_INSTALL_ROOT_DIR"
  fi

  if [ ! -d "$TOOLS_INSTALL_ROOT_DIR" ]; then
    mkdir "$TOOLS_INSTALL_ROOT_DIR"
  fi
}

function init_ohpm()
{
    ohpm config set registry https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/ohpm/ohpm-center/,https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/ohpm/product_ohpm/,https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/npm/npm-central-repo/,https://cmc.centralrepo.rnd.openharmony.com/artifactory/api/npm/product_npm,https://mirrors.tools.openharmony.com/ohpm/,https://ohpm.openharmony.cn/ohpm/
    ohpm config set strict_ssl false
}

function install_dependence() {
  # 根据业务情况安装ohpm三方库依赖,
  cd "$APP_HOME"
  ohpm -v
  ohpm install --all
}

function main {
  local startTime=$(date '+%s')
  init_dir
  init_ohpm
  install_dependence

  # 调用 build_main.sh 并传递参数
  echo "arguments passed to this script: $@"
  # 检查第一个参数是否为 "entry"
  if [ "$1" = "entry" ]; then
      # 如果是 entry，则添加 --product default
      python3 build_product.py --mode hap --device phone wearable tv --test
  else
      # 否则直接传递所有参数
      python3 build_product.py "$@"
  fi
  local end_time=$(date '+%s')
  local elapsed_time=$((end_time - start_time))
  echo "build completed in ${elapsed_time}s"
}

main "$@"