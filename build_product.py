#!/usr/bin/env python
# coding: utf-8
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

import os
import sys
import subprocess
import argparse
import threading


def run_command(command, cwd=None):
    """运行一个 shell 命令并打印日志"""
    print(f"----------------- {' '.join(command)} begin --------------------")

    # 定义一个函数来实时读取 stdout 并打印
    def read_output(stream, prefix):
        for line in stream:
            print(f"[{prefix}] {line.strip()}")

    # 检查是否是 Windows 上的 .bat 文件
    use_shell = False
    if os.name == 'nt' and command and command[0].endswith('.bat'):
        use_shell = True

    process = subprocess.Popen(
        command,
        shell=use_shell,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )

    # 启动线程来读取 stdout 和 stderr
    stdout_thread = threading.Thread(target=read_output, args=(process.stdout, "STDOUT"))
    stderr_thread = threading.Thread(target=read_output, args=(process.stderr, "STDERR"))
    stdout_thread.start()
    stderr_thread.start()

    # 等待子进程完成
    return_code = process.wait()

    # 等待线程结束
    stdout_thread.join()
    stderr_thread.join()

    if return_code != 0:
        print(f"Error: Command failed with exit code {return_code}")
        sys.exit(1)
    print(f"----------------- {' '.join(command)} end --------------------")


def get_hvigorw_command():
    """根据操作系统返回正确的 hvigorw 命令"""
    if os.name == 'nt':  # Windows
        return ["hvigorw.bat"]
    else:  # Linux/Mac
        return ["hvigorw"]


def check_hvigorw():
    """检查 hvigorw 是否可用"""
    try:
        hvigorw_cmd = get_hvigorw_command()
        use_shell = os.name == 'nt' and hvigorw_cmd[0].endswith('.bat')
        subprocess.run(hvigorw_cmd + ["--version"], shell=use_shell, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        print(f"Error: {' '.join(hvigorw_cmd)} not found or not executable.")
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: {' '.join(hvigorw_cmd)} not found. Please ensure the file exists in the project root.")
        sys.exit(1)


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(description="Build script for Hap modules and test packages.")

    # 新增模式参数
    parser.add_argument(
        "--mode",
        nargs='?',  # 表示可选参数，如果没传就用默认值
        choices=["app", "hap"],
        default="app",
        type=str,
        help="Build mode: 'app' for App mode, 'hap' for Hap mode"
    )
    # --product 参数（App 模式下必填，Hap 模式下也必填）
    parser.add_argument(
        "--product",
        nargs='?',
        choices=["default", "emulator-x86", "emulator-arm"],
        default="default",
        type=str,
        help="Product type (default, emulator-x86, emulator-arm)"
    )
    # --device 参数（Hap 模式下可选，支持多个设备）
    parser.add_argument(
        "--device",
        nargs='+',  # 支持多个设备
        choices=["phone", "wearable", "tv", "car"],
        default=["phone", "wearable", "tv", "car"],  # 默认全编译
        help="Device type (phone, wearable, tv, car)"
    )
    # --test 参数
    parser.add_argument(
        "--test",
        action="store_true",
        help="Run test modules"
    )

    # --incremental 参数
    parser.add_argument(
        "--incremental",
        nargs='?',
        const=True,
        type=bool,
        default=False,
        help="Build with incremental"
    )

    # --remoteHvigorCache 使用缓存参数
    parser.add_argument(
        "--remoteHvigorCache",
        nargs='?',
        choices=["false", "true"],
        default="false",
        type=str,
        help="Build with remoteHvigorCache"
    )

    # --pushRemoteCache 更新推送缓存参数
    parser.add_argument(
        "--pushRemoteCache",
        nargs='?',
        choices=["false", "true"],
        default="false",
        type=str,
        help="Build with pushRemoteCache"
    )

    args = parser.parse_args()
    return args


def setup_app_home():
    """设置 APP_HOME"""
    app_home = os.path.abspath(os.getcwd())
    print(f"APP_HOME: {app_home}")
    return app_home


def package_dt_pipeline(app_home):
    """打包 DTPipeline.zip"""
    print("----------------- handle DTPipeline.zip --------------------")
    dtpipeline_path = os.path.join(app_home, "build", "DTPipeline.zip")
    outputs_dir = os.path.join(app_home, "build", "outputs")
    # 检查 build/DTPipeline.zip 是否存在且非空
    if os.path.exists(dtpipeline_path):
        file_size = os.path.getsize(dtpipeline_path)
        if file_size > 0:
            print("DTPipeline.zip is normal")
            return  # 已经存在且正常，无需再打包
        else:
            print("DTPipeline.zip size is 0, will be re-packed.")
    else:
        print("build/DTPipeline.zip is not exist, will be re-packed.")

    # 检查 outputs 目录是否存在
    if not os.path.exists(outputs_dir):
        print("build/outputs is not exist")
        sys.exit(1)

    # 切换到 outputs 目录进行打包
    original_cwd = os.getcwd()
    try:
        os.chdir(outputs_dir)
        print("Packaging DTPipeline.zip...")

        # 安全地执行 zip 命令，不使用 shell=True
        command = ["zip", "-r", "../DTPipeline.zip", "."]
        run_command(command)
        print("Packaging completed.")
    except subprocess.CalledProcessError as e:
        print("Error during packaging:")
        print("STDOUT:", e.stdout)
        print("STDERR:", e.stderr)
        sys.exit(1)
    finally:
        os.chdir(original_cwd)  # 回到原来的目录


basic_args = "--parallel --incremental --no-daemon --stacktrace"
basic_args_list = basic_args.split()  # 将 basic_args 转换为列表形式


def build_hap(app_home, product, hap_module_name, dt_test, remoteHvigorCache, pushRemoteCache):
    """构建主模块（非测试）"""
    print(f"----------------- build {hap_module_name} hap --------------------")
    cmd = get_hvigorw_command() + [
        "--mode", "module",
        "-p", f"module={hap_module_name}",
        "-p", f"product={product}",
        "-p", "debuggable=false",
        "-p", "buildMode=release",
        "-p", f"remoteCache={remoteHvigorCache}",
        "-p", f"pushRemoteCache={pushRemoteCache}",
        "assembleHap",
        *basic_args_list
    ]
    if dt_test :
      ## 先编译带打桩信息的hap包, 完成DTPipeline.zip包的编译,再执行Release版本的编译
      test_cmd = cmd + ["-p", "ohos-test-coverage=true", "-p", "testing=true"]
      run_command(test_cmd)
      build_test_hap(app_home, product, hap_module_name, remoteHvigorCache, pushRemoteCache)
    run_command(cmd)


def build_test_hap(app_home, product, hap_module_name, remoteHvigorCache, pushRemoteCache):
    """构建测试模块"""
    print(f"----------------- build {hap_module_name} test hap (ohosTest) --------------------")
    cmd = get_hvigorw_command() + [
        "--mode", "module",
        "-p", f"product={product}",
        "-p", f"module={hap_module_name}@ohosTest",
        "-p", "debuggable=false",
        "-p", "buildMode=release",
        "-p", f"remoteCache={remoteHvigorCache}",
        "-p", f"pushRemoteCache={pushRemoteCache}",
        "assembleHap",
        "packageTesting",
        *basic_args_list,
        "-p", "ohos-test-coverage=true",
        "-p", "testing=true"
    ]
    run_command(cmd)

    package_dt_pipeline(app_home)


def build_app(app_home, product, hap_module_name, dt_test):
    """构建 App 并签名"""
    cmd = get_hvigorw_command() + [
        "assembleApp",
        "--mode", "project",
        "-p", f"product={product}",
        "-p", "debuggable=false",
        "-p", "buildMode=release",
        *basic_args_list
    ]
    run_command(cmd)

    sign_script_path = "./signature/sign_app.sh"
    if os.path.isfile(sign_script_path):
        run_command([sign_script_path, product])
    else:
        print(f"Error: sign_app.sh not found at {sign_script_path}")
        sys.exit(1)


def main():
    """主函数"""
    check_hvigorw()
    args = parse_arguments()
    app_home = setup_app_home()
    # 提取参数值
    mode = args.mode
    product = args.product
    device_list = args.device  # 支持多个设备
    test = args.test
    incremental = args.incremental  #false

    if not args.incremental:
        cmd_clean = get_hvigorw_command() + ["-p", f"product={product}", "clean", "--parallel", "--no-daemon"]
        run_command(cmd_clean)
    if args.mode == "app" :
        for device in device_list:
            """先构建 hap包"""
            build_hap(app_home, product, device, args.test, args.remoteHvigorCache, args.pushRemoteCache)
            build_app(app_home, product, device, args.test)
    else:
        for device in device_list:
            build_hap(app_home, product, device, args.test, args.remoteHvigorCache, args.pushRemoteCache)


if __name__ == "__main__":
    main()
