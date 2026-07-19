#!/usr/bin/env bash
set -euo pipefail

# 烧录脚本 - 默认烧录 Debug 版本，使用 --release 烧录 Release 版本
# 用法: ./scripts/flash.sh [--release]

BUILD_TYPE="Debug"

# 解析参数
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        -h|--help)
            echo "用法: $0 [--release | --debug]"
            echo ""
            echo "选项:"
            echo "  --release   烧录 Release 版本"
            echo "  --debug     烧录 Debug 版本 (默认)"
            echo "  -h, --help  显示帮助信息"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--release | --debug]"
            exit 1
            ;;
    esac
done

# 切换到项目根目录 (脚本在 scripts/ 下)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

ELF_FILE="build/${BUILD_TYPE}/stm32-nano.elf"
CFG_DIR="$PROJECT_DIR"

echo "============================================"
echo "  STM32F103 烧录工具"
echo "  构建类型: ${BUILD_TYPE}"
echo "  镜像文件: ${ELF_FILE}"
echo "============================================"

# 检查 ELF 文件是否存在
if [[ ! -f "$ELF_FILE" ]]; then
    echo "[错误] 镜像文件不存在: $ELF_FILE"
    echo "       请先执行构建: cmake --build build/${BUILD_TYPE}"
    exit 1
fi

# 检查 OpenOCD 配置文件
if [[ ! -f "$CFG_DIR/stlink.cfg" ]]; then
    echo "[错误] 配置文件不存在: $CFG_DIR/stlink.cfg"
    exit 1
fi

if [[ ! -f "$CFG_DIR/stm32f1x.cfg" ]]; then
    echo "[错误] 配置文件不存在: $CFG_DIR/stm32f1x.cfg"
    exit 1
fi

openocd \
    -f "$CFG_DIR/stlink.cfg" \
    -f "$CFG_DIR/stm32f1x.cfg" \
    -c "program ${ELF_FILE} verify reset exit"

EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "============================================"
    echo "  烧录成功!"
    echo "============================================"
else
    echo "============================================"
    echo "  烧录失败! (退出码: $EXIT_CODE)"
    echo "============================================"
    exit $EXIT_CODE
fi
