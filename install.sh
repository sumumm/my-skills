#!/bin/bash
# * =====================================================
# * Copyright © sumu. 2026-present. Tech. Co., Ltd. All rights reserved.
# * File name  : install.sh
# * Author     : 苏木
# * Date       : 2026/04/12
# * Version    : 1.0.0
# * Description: 安装 skills 到各 AI 扩展 (RooCode / Claude Code / CodeBuddy)
# * ======================================================
##
# 脚本和工程路径
# ========================================================
SCRIPT_NAME=${0#*/}
SCRIPT_CURRENT_PATH=${0%/*}
SCRIPT_ABSOLUTE_PATH=$(cd $(dirname ${0}); pwd)

# 颜色和日志标识
# ========================================================
# |      ---       |Black |  Red | Green | Yellow | Blue | Magenta | Cyan | White |
# | Fore(Standard) |  30  |  31  |  32   |   33   |  34  |   35    |  36  |   37  |
# | Fore(light)    |  90  |  91  |  92   |   93   |  94  |   95    |  96  |   97  |
# | Back(Standard) |  40  |  41  |  42   |   43   |  44  |   45    |  46  |   47  |
# | Back(light)    | 100  | 101  | 102   |  103   | 104  |  105    | 106  |  107  |
step() {
    echo -e "\e[96m➤  $@\e[0m"
}

warning() {
    echo -n "⚠️  "
    echo -e "\e[33m$@\e[0m"
}

error() {
    echo -n "❌ "
    echo -e "\e[31m$@\e[0m"
}

success() {
    echo -n "✅ "
    echo -e "\e[32m$@\e[0m"
}

info() {
    echo -ne "\e[32mℹ️ [INFO]\e[0m"
    echo -e "\e[0m$@\e[0m"
}

dim() {
    echo -e "\e[90m$@\e[0m"
}

# 目录切换函数定义
cdi() {
    if command -v pushd &>/dev/null; then
        pushd $1 >/dev/null || return 1
    else
        cd $1
    fi
}

cdo() {
    if command -v popd &>/dev/null; then
        popd >/dev/null || return 1
    else
        cd -
    fi
}

# ========================================================
# 参数配置
# ========================================================

# Skills 源目录 (脚本所在目录下的 skills/)
SKILLS_SRC_DIR="${SCRIPT_ABSOLUTE_PATH}/skills"

# 各 AI 扩展的目标安装路径
# RooCode    : ~/.roo/skills/<skill-name>/SKILL.md
# Claude Code: ~/.claude/skills/<skill-name>/SKILL.md
# CodeBuddy  : ~/.codebuddy/skills/<skill-name>/SKILL.md
ROOCODE_SKILLS_DIR="${HOME}/.roo/skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
CODEBUDDY_SKILLS_DIR="${HOME}/.codebuddy/skills"

# ========================================================
# 获取所有技能目录名称列表 (仅返回子目录, 排除 skills/SKILL.md 等文件)
get_skill_names() {
    local names=()
    for item in "${SKILLS_SRC_DIR}"/*/; do
        [ ! -d "$item" ] && continue
        names+=("$(basename "$item")")
    done
    echo "${names[@]}"
}

# ========================================================
# 安装技能到 RooCode
# 目标: ~/.roo/skills/<skill-name>/  (复制整个技能目录)
install_to_roocode() {
    step "installing skills to RooCode (${ROOCODE_SKILLS_DIR})..."

    # 检查源目录
    if [ ! -d "${SKILLS_SRC_DIR}" ]; then
        error "skills source directory not found: ${SKILLS_SRC_DIR}"
        return 1
    fi

    # 创建目标目录
    mkdir -p "${ROOCODE_SKILLS_DIR}"

    local skill_names=$(get_skill_names)
    local count=0

    for skill_name in ${skill_names}; do
        local src="${SKILLS_SRC_DIR}/${skill_name}"
        local dst="${ROOCODE_SKILLS_DIR}/${skill_name}"

        # 跳过非目录项
        [ ! -d "${src}" ] && continue

        # 目标已存在则先移除
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " overwrite existing skill: ${skill_name}"
        fi

        cp -rf "${src}" "${dst}"
        count=$((count + 1))
        dim "  ${src}/ -> ${dst}/"
    done

    success "RooCode: ${count} skill(s) installed."
}

# ========================================================
# 安装技能到 Claude Code
# 目标: ~/.claude/skills/<skill-name>/  (复制整个技能目录)
install_to_claude() {
    step "installing skills to Claude Code (${CLAUDE_SKILLS_DIR})..."

    # 检查源目录
    if [ ! -d "${SKILLS_SRC_DIR}" ]; then
        error "skills source directory not found: ${SKILLS_SRC_DIR}"
        return 1
    fi

    # 创建目标目录
    mkdir -p "${CLAUDE_SKILLS_DIR}"

    local skill_names=$(get_skill_names)
    local count=0

    for skill_name in ${skill_names}; do
        local src="${SKILLS_SRC_DIR}/${skill_name}"
        local dst="${CLAUDE_SKILLS_DIR}/${skill_name}"

        # 跳过非目录项
        [ ! -d "${src}" ] && continue

        # 目标已存在则先移除
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " overwrite existing skill: ${skill_name}"
        fi

        cp -rf "${src}" "${dst}"
        count=$((count + 1))
        dim "  ${src}/ -> ${dst}/"
    done

    success "Claude Code: ${count} skill(s) installed."
}

# ========================================================
# 安装技能到 CodeBuddy
# 目标: ~/.codebuddy/skills/<skill-name>/  (复制整个技能目录)
install_to_codebuddy() {
    step "installing skills to CodeBuddy (${CODEBUDDY_SKILLS_DIR})..."

    # 检查源目录
    if [ ! -d "${SKILLS_SRC_DIR}" ]; then
        error "skills source directory not found: ${SKILLS_SRC_DIR}"
        return 1
    fi

    # 创建目标目录
    mkdir -p "${CODEBUDDY_SKILLS_DIR}"

    local skill_names=$(get_skill_names)
    local count=0

    for skill_name in ${skill_names}; do
        local src="${SKILLS_SRC_DIR}/${skill_name}"
        local dst="${CODEBUDDY_SKILLS_DIR}/${skill_name}"

        # 跳过非目录项
        [ ! -d "${src}" ] && continue

        # 目标已存在则先移除
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " overwrite existing skill: ${skill_name}"
        fi

        cp -rf "${src}" "${dst}"
        count=$((count + 1))
        dim "  ${src}/ -> ${dst}/"
    done

    success "CodeBuddy: ${count} skill(s) installed."
}

# ========================================================
# 安装到所有 AI 扩展
install_to_all() {
    install_to_roocode  || return 1
    echo ""
    install_to_claude   || return 1
    echo ""
    install_to_codebuddy || return 1
}

# ========================================================
# 卸载所有 AI 扩展中的技能
do_uninstall() {
    step "uninstalling skills from all AI extensions..."

    local skill_names=$(get_skill_names)

    # RooCode
    for skill_name in ${skill_names}; do
        local dst="${ROOCODE_SKILLS_DIR}/${skill_name}"
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " removed ${dst}"
        fi
    done

    # Claude Code
    for skill_name in ${skill_names}; do
        local dst="${CLAUDE_SKILLS_DIR}/${skill_name}"
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " removed ${dst}"
        fi
    done

    # CodeBuddy
    for skill_name in ${skill_names}; do
        local dst="${CODEBUDDY_SKILLS_DIR}/${skill_name}"
        if [ -d "${dst}" ]; then
            rm -rf "${dst}"
            info " removed ${dst}"
        fi
    done

    success "uninstall done."
}

# ========================================================
# 显示已安装的技能状态
show_status() {
    step "skills installation status"
    echo ""

    local skill_names=$(get_skill_names)

    # 源目录技能列表
    step "Available skills (${SKILLS_SRC_DIR}):"
    for skill_name in ${skill_names}; do
        echo "  - ${skill_name}"
    done
    echo ""

    # RooCode 状态
    step "RooCode (${ROOCODE_SKILLS_DIR}):"
    for skill_name in ${skill_names}; do
        if [ -d "${ROOCODE_SKILLS_DIR}/${skill_name}" ]; then
            success "${skill_name}"
        else
            error "${skill_name} (not installed)"
        fi
    done
    echo ""

    # Claude Code 状态
    step "Claude Code (${CLAUDE_SKILLS_DIR}):"
    for skill_name in ${skill_names}; do
        if [ -d "${CLAUDE_SKILLS_DIR}/${skill_name}" ]; then
            success "${skill_name}"
        else
            error "${skill_name} (not installed)"
        fi
    done
    echo ""

    # CodeBuddy 状态
    step "CodeBuddy (${CODEBUDDY_SKILLS_DIR}):"
    for skill_name in ${skill_names}; do
        if [ -d "${CODEBUDDY_SKILLS_DIR}/${skill_name}" ]; then
            success "${skill_name}"
        else
            error "${skill_name} (not installed)"
        fi
    done
}

# ========================================================
# 打印菜单
do_echo_menu() {
    echo "================================================="
    echo -e "           Skills Installer for AI Extensions"
    echo "================================================="
    echo -e "SKILLS_SRC_DIR      :${SKILLS_SRC_DIR}"
    echo -e "ROOCODE_SKILLS_DIR  :${ROOCODE_SKILLS_DIR}"
    echo -e "CLAUDE_SKILLS_DIR   :${CLAUDE_SKILLS_DIR}"
    echo -e "CODEBUDDY_SKILLS_DIR:${CODEBUDDY_SKILLS_DIR}"
    echo -e "SCRIPT_ABSOLUTE_PATH:${SCRIPT_ABSOLUTE_PATH}"
    echo -e "SHELL_PARAM         :($# total)arg=$*"
    echo ""
    echo "================================================="
}

# ========================================================
# 用法说明
usage() {
    echo "用法: ${SCRIPT_NAME} [选项]"
    echo ""
    echo "选项:"
    echo "  all         安装到所有 AI 扩展"
    echo "  roocode     安装到 RooCode    (~/.roo/skills/)"
    echo "  claude      安装到 Claude Code (~/.claude/skills/)"
    echo "  codebuddy   安装到 CodeBuddy  (~/.codebuddy/skills/)"
    echo "  status      显示安装状态"
    echo "  uninstall   卸载所有已安装的技能"
    echo "  help        显示此帮助信息"
    echo ""
    echo "无参数运行时进入交互式菜单"
}

# ========================================================
# 交互式菜单
interactive_menu() {
    do_echo_menu "$@"

    echo "请选择操作:"
    echo "  1) 安装到所有 AI 扩展"
    echo "  2) 安装到 RooCode"
    echo "  3) 安装到 Claude Code"
    echo "  4) 安装到 CodeBuddy"
    echo "  5) 显示安装状态"
    echo "  6) 卸载所有技能"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 [0-6]: " choice

    case ${choice} in
        1) install_to_all ;;
        2) install_to_roocode ;;
        3) install_to_claude ;;
        4) install_to_codebuddy ;;
        5) show_status ;;
        6) do_uninstall ;;
        0) echo "退出"; exit 0 ;;
        *) error "无效选项: ${choice}"; exit 1 ;;
    esac
}

# ========================================================
# 主入口
do_echo_menu "$@"

case "$1" in
    all)         install_to_all ;;
    roocode)     install_to_roocode ;;
    claude)      install_to_claude ;;
    codebuddy)   install_to_codebuddy ;;
    status)      show_status ;;
    uninstall)   do_uninstall ;;
    help|--help|-h) usage ;;
    "")          interactive_menu "$@" ;;
    *)           error "未知选项: $1"; usage; exit 1 ;;
esac

exit $?

