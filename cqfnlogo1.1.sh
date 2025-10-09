#!/bin/bash
set -euo pipefail

# 配置参数
TARGET_DIR="${1:-/usr/trim/www/assets}"
MOVIE_DIR="${1:-/usr/local/apps/@appcenter/trim.media/static/assets}"
LOG_FILE="${2:-./js_modification.log}"
BASE_DIR="/usr/trim/www"
RESOURCE_DIR="userimg"
# 定义index.html路径
INDEX_FILE="${BASE_DIR}/index.html"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# URL验证函数
validate_url() {
    local url=$1
    [[ $url =~ ^https?:// ]] || return 1
    return 0
}

# 检查并创建资源目录
check_resource_dir() {
    if [ ! -d "${BASE_DIR}/${RESOURCE_DIR}" ]; then
        echo -e "${YELLOW}⚠️ 资源目录不存在，正在创建: ${BASE_DIR}/${RESOURCE_DIR}${NC}"
        mkdir -p "${BASE_DIR}/${RESOURCE_DIR}"
        chmod 755 "${BASE_DIR}/${RESOURCE_DIR}"
        echo -e "${GREEN}✓ 资源目录创建成功${NC}"
    fi
}

# 安全替换函数
safe_replace() {
    local file_path=$1
    local original=$2
    local new_value=$3

    # 转义特殊字符
    local escaped_value=$(printf '%q' "$new_value" | sed "s/'/'\\\\''/g")

    # 执行替换并保留双引号结构
    sed -i "s|${original}[^\"]*\"|${original}${escaped_value}\"|g" "$file_path"
    echo -e "${GREEN}✓ 安全更新: ${NC}$new_value"
}

# 带提示的输入函数
prompt_input() {
    local prompt=$1
    read -p "$prompt (返回不修改请直接按Enter): " input
    echo "$input"
}

# 功能1：修改登录界面logo
modify_login_logo() {
    local mode=$1
    local value=""
    
    case $mode in
        1) value="${RESOURCE_DIR}/login_logo.png" ;;
        2) 
            while true; do
                value=$(prompt_input "请输入登录logo图片URL")
                if [ -z "$value" ]; then
                    echo -e "${YELLOW}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$value"; then
                    break
                else
                    echo -e "${RED}× 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    echo -e "\n${YELLOW}=== 修改登录界面logo图片 ===${NC}"
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$value"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
}

# 功能2：修改登录背景图片
modify_login_bg() {
    local mode=$1
    local value=""
    
    case $mode in
        1) value="${RESOURCE_DIR}/login_bg.jpg" ;;
        2) 
            while true; do
                value=$(prompt_input "请输入登录背景图片URL")
                if [ -z "$value" ]; then
                    echo -e "${YELLOW}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$value"; then
                    break
                else
                    echo -e "${RED}× 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    echo -e "\n${YELLOW}=== 修改登录界面背景图片 ===${NC}"
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$value"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
}

# 功能3：修改设备信息logo
modify_device_logo() {
    local mode=$1
    local value=""
    
    case $mode in
        1) value="${RESOURCE_DIR}/fnlogo.png" ;;
        2) 
            while true; do
                value=$(prompt_input "请输入设备logo图片URL")
                if [ -z "$value" ]; then
                    echo -e "${YELLOW}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$value"; then
                    break
                else
                    echo -e "${RED}× 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    echo -e "\n${YELLOW}=== 修改设备信息logo图片 ===${NC}"
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$value"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
}

# 新增功能：修改飞牛网页标题（同时更新index.html和最大JS文件）
modify_web_title() {
    echo -e "\n${YELLOW}=== 修改飞牛网页标题 ===${NC}"
    echo -e "\n${RED}注意:自定义标题最好不要有特殊字符, 空格, 横线, 下划线都可以, 其他请谨慎!!!${NC}"
    
    # 获取新标题
    local new_title=$(prompt_input "请输入新的网页标题")
    if [ -z "$new_title" ]; then
        echo -e "${YELLOW}⚠️ 未输入标题，跳过修改${NC}"
        return
    fi
    
    # 转义特殊字符
    local escaped_title=$(printf '%q' "$new_title" | sed "s/'/'\\\\''/g")
    
    # 1. 修改index.html中的<title>标签
    if [ -f "$INDEX_FILE" ]; then
        if sed -i "s|<title>[^<]*</title>|<title>${escaped_title}</title>|g" "$INDEX_FILE"; then
            echo -e "${GREEN}✓ 网页标题已成功更新: ${NC}$new_title"
        else
            echo -e "${RED}× 标题修改失败（HTML文件），请检查文件权限${NC}"
        fi
    else
        echo -e "${RED}× 未找到文件: ${INDEX_FILE}${NC}"
    fi
    
    # 2. 修改最大JS文件中的'${t} - 飞牛 fnOS'内容
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
sed -i.bak 's|\(document\.title=`\)[^`]*|\1'"$escaped_title"'|' "$largest_js"
        echo -e "${GREEN}✓ 修改的JS文件: ${NC}$largest_js"
        echo -e "${GREEN}✓ 修改的文件: ${NC}$INDEX_FILE"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
}

# 关闭登录框透明度
apply_touming_off() {
    local largest_css=$(find "$TARGET_DIR" -type f -name "*.css" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_css" ]; then
sed -i 's/backdrop-blur-\\\[20px\\\]{--tw/backdrop-blur-\\\[0px\\\]{--tw/g' "$largest_css"
    else
        echo -e "${RED}× 未找到任何CSS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 完成:大幅削弱登录框透明度${NC}"
}

# 打开登录框透明度
apply_touming_on() {
    local largest_css=$(find "$TARGET_DIR" -type f -name "*.css" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_css" ]; then
sed -i 's/backdrop-blur-\\\[0px\\\]{--tw/backdrop-blur-\\\[20px\\\]{--tw/g' "$largest_css"
    else
        echo -e "${RED}× 未找到任何CSS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 完成:原登录框透明度${NC}"
}

# 预设主题：高达00
apply_gundam_theme() {
    echo -e "\n${YELLOW}=== 应用高达00主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759752438383_login.png"
    local login_bg="https://img.on79.cfd/file/1759751427376_bg.png"
    local device_logo="https://img.on79.cfd/file/1759752817818_993788ea3f5acb3d42151f7b3a30e496.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 高达00主题应用完成${NC}"
}

# 预设主题：初音未来
apply_miku_theme() {
    echo -e "\n${YELLOW}=== 应用初音未来主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759755919009_3a431f4408e2d8879beb3ae0a6d9473897be8ee1.jpg_.png"
    local login_bg="https://img.on79.cfd/file/1759755273357_dca742293ef3b268e5e1153d9a90abe63016.jpeg"
    local device_logo="https://img.on79.cfd/file/1759755278837_403748c03ada425a0008f8f9f43c7b4c.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 初音未来主题应用完成${NC}"
}

# 预设主题：钢之炼金术师
apply_gzljss_theme() {
    echo -e "\n${YELLOW}=== 应用钢之炼金术师主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759757773908_0.png"
    local login_bg="https://img.on79.cfd/file/1759758745814_ca847658-796a-4e0f-83e1-1093613cfa96.webp"
    local device_logo="https://img.on79.cfd/file/1759758028574_1.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 钢之炼金术师主题应用完成${NC}"
}
# 预设主题：海贼王
apply_haizeiwang_theme() {
    echo -e "\n${YELLOW}=== 应用海贼王主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759760428928_FvC0L7Rz4U6ImCiHAFOyQsHZu6Nw.png"
    local login_bg="https://img.on79.cfd/file/1759760423918_703ddc5a7ea9972e74769ee7a8543e9793b62592.webp"
    local device_logo="https://img.on79.cfd/file/1759760422420_87bc5de4ly1hrwn0xs3zej20u011in0b.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 海贼王主题应用完成${NC}"
}
# 预设主题：JOJO的奇妙冒险
apply_jojo_theme() {
    echo -e "\n${YELLOW}=== 应用JOJO的奇妙冒险主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759815392132_jojo.png"
    local login_bg="https://img.on79.cfd/file/1759815397774_jojo.webp"
    local device_logo="https://img.on79.cfd/file/1759815392132_jojo.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ JOJO的奇妙冒险主题应用完成${NC}"
}
# 预设主题：新世纪福音战士
apply_eva_theme() {
    echo -e "\n${YELLOW}=== 应用新世纪福音战士主题 ===${NC}"
    
    local login_logo="https://img.on79.cfd/file/1759817609585_b0d3-hxsrwwr3510582.png"
    local login_bg="https://img.on79.cfd/file/1759817614289_v2-f3b2d8c46c5c9f09c8ccf3f0f01b480c_r.webp"
    local device_logo="https://img.on79.cfd/file/1759817614477_a08b87d6277f9e2f678e991d1930e924b899f368.png"
    
    # 修改登录logo
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "*login-form*" | head -n1)
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'o="' "$login_logo"
    else
        echo -e "${RED}× 未找到登录表单JS文件${NC}"
    fi
    
    # 修改登录背景
    if [ -n "$login_file" ]; then
        safe_replace "$login_file" 'url("' "$login_bg"
    fi
    
    # 修改设备logo
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$largest_js" ]; then
        safe_replace "$largest_js" 'n8="' "$device_logo"
    else
        echo -e "${RED}× 未找到任何JS文件${NC}"
    fi
    
    echo -e "${GREEN}✓ 新世纪福音战士主题应用完成${NC}"
}

# 新增：飞牛影视相关功能
# 新增功能：修改飞牛影视标题
modify_movie_title() {
    echo -e "\n${YELLOW}=== 修改飞牛影视标题 ===${NC}"
    echo -e "${RED}注意: 自定义标题建议避免特殊字符，空格、横线、下划线可正常使用${NC}"
    
    # 定义影视页面index.html路径
    local MOVIE_INDEX_FILE="/usr/local/apps/@appcenter/trim.media/static/index.html"
    
    # 获取新标题
    local new_title=$(prompt_input "请输入新的影视页面标题")
    if [ -z "$new_title" ]; then
        echo -e "${YELLOW}⚠️ 未输入标题，跳过修改${NC}"
        return
    fi
    
    # 转义特殊字符
    local escaped_title=$(printf '%q' "$new_title" | sed "s/'/'\\\\''/g")
    
    # 修改影视页面index.html中的<title>标签
    if [ -f "$MOVIE_INDEX_FILE" ]; then
        if sed -i "s|<title>[^<]*</title>|<title>${escaped_title}</title>|g" "$MOVIE_INDEX_FILE"; then
            echo -e "${GREEN}✓ 影视页面标题已成功更新: ${NC}$new_title"
            echo -e "${GREEN}✓ 修改的文件: ${NC}$MOVIE_INDEX_FILE"
        else
            echo -e "${RED}× 标题修改失败，请检查文件权限${NC}"
        fi
    else
        echo -e "${RED}× 未找到影视页面文件: ${MOVIE_INDEX_FILE}${NC}"
    fi
}

modify_movie_logo() {
    local mode=$1
    local value=""
    
    case $mode in
        1) value="/${RESOURCE_DIR}/movie_logo.png" ;;
        2) 
            while true; do
                value=$(prompt_input "请输入飞牛影视LOGO图片URL")
                if [ -z "$value" ]; then
                    echo -e "${YELLOW}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$value"; then
                    break
                else
                    echo -e "${RED}× 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    echo -e "\n${YELLOW}=== 修改飞牛影视LOGO ===${NC}"
    local movie_file=$(find "$MOVIE_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    if [ -n "$movie_file" ]; then
        safe_replace "$movie_file" 'WDe="' "$value"
        safe_replace "$movie_file" 'KDe="' "$value"
        echo -e "${CYAN}注意！由于肥牛此处目录结构比较复杂，暂时只修改了登录之后的LOGO, 登录界面的LOGO暂未修改！！！${NC}"
    else
        echo -e "${RED}× 未找到飞牛影视相关JS文件${NC}"
    fi
}

# 查找飞牛影视中path:"login"后紧跟的第一个JS文件
modify_movie_bg() {
   
    local mode=$1
    local value=""
    
    case $mode in
        1) value="/${RESOURCE_DIR}/movie_bg.jpg" ;;
        2) 
            while true; do
                value=$(prompt_input "请输入飞牛影视背景图片URL")
                if [ -z "$value" ]; then
                    echo -e "${YELLOW}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$value"; then
                    break
                else
                    echo -e "${RED}× 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    echo -e "\n${YELLOW}=== 修改飞牛影视背景 ===${NC}"
    
    local TARGET_DIR="/usr/local/apps/@appcenter/trim.media/static/assets"
    local largest_js=$(find "$TARGET_DIR" -type f -name "*.js" -exec du -ah {} + | sort -rh | head -n1 | awk '{print $2}')
    
    if [ -z "$largest_js" ] || [ ! -f "$largest_js" ]; then
        echo -e "${RED}× 未找到主JS文件${NC}"
        return 1
    fi
    
    # 提取目标JS文件名
    local js_filename=$(grep -oP 'path:"login",async lazy\(\)\{return\{Component:\(await Zn\(\(\)\=>import\("\./\K[^"]+' "$largest_js" | head -n1)
    
    if [ -z "$js_filename" ]; then
        echo -e "${RED}× 未找到匹配的JS文件名${NC}"
        return 1
    fi
    
    # 构建完整路径
    local target_js="${TARGET_DIR}/${js_filename}"
    if [ ! -f "$target_js" ]; then
        echo -e "${RED}× 目标文件不存在: ${target_js}${NC}"
        return 1
    fi
    
    
    if [ -n "$target_js" ]; then
        safe_replace "$target_js" 'J="' "$value"
        echo -e "${GREEN}✓ 修改的文件: ${NC}$target_js"
    else
        echo -e "${RED}× 未找到目标JS文件${NC}"
    fi
}

# 预设主题菜单
show_preset_menu() {
    echo -e "\n${YELLOW}===== 预设主题菜单 =====${NC}"
    echo -e "1. 高达00"
    echo -e "2. 初音未来"
    echo -e "3. 钢之炼金术师"
    echo -e "4. 海贼王"
    echo -e "5. JOJO的奇妙冒险"
    echo -e "6. 新世纪福音战士"
    echo -e "0. 返回主菜单"
    echo -e "${YELLOW}==================${NC}"
}
# 选择透明度菜单
show_touming_menu() {
    echo -e "\n${YELLOW}===== 透明度菜单 =====${NC}"
    echo -e "1. 大幅削弱登录框透明度"
    echo -e "2. 还原登录框透明度"
    echo -e "0. 返回主菜单"
    echo -e "${YELLOW}==================${NC}"
}

# 飞牛影视二级菜单
show_movie_submenu() {
    echo -e "\n${YELLOW}===== 飞牛影视修改菜单 =====${NC}"
    echo -e "1. 修改飞牛影视标题"
    echo -e "2. 修改飞牛影视LOGO"
    echo -e "3. 修改飞牛影视背景"
    echo -e "0. 返回主菜单"
    echo -e "${YELLOW}======================${NC}"
}

# 影视修改子菜单（用于LOGO和背景的修改方式选择）
show_movie_file_submenu() {
    local title=$1
    echo -e "\n${YELLOW}===== $title =====${NC}"
    echo -e "1. 默认：直接修改（使用${RESOURCE_DIR}路径）"
    echo -e "2. 自定义：输入完整URL路径"
    echo -e "0. 返回上一级"
    echo -e "${YELLOW}==================${NC}"
}

# 子菜单
show_submenu() {
    local title=$1
    echo -e "\n${YELLOW}===== $title =====${NC}"
    echo -e "1. 默认：直接修改（使用${RESOURCE_DIR}路径）"
    echo -e "2. 自定义：输入完整URL路径"
    echo -e "0. 返回主菜单"
    echo -e "${YELLOW}==================${NC}"
}

# 主菜单
show_menu() {
    echo -e "\n${YELLOW}==== 米恋泥肥牛脚本v1.0 ====${NC}"
    echo -e "1. 选择预设主题（小白推荐）"
    echo -e "2. 修改登录界面背景图片"
    echo -e "3. 修改设备信息logo图片"
    echo -e "4. 修改登录界面logo图片"
    echo -e "5. 修改飞牛网页标题"
    echo -e "6. 修改飞牛登录框透明度"
    echo -e "7. 修改飞牛影视界面"  # 新增项
    echo -e "0. 退出"
    echo -e "${YELLOW}==========================${NC}"
}

# 主执行流程
main() {
    check_resource_dir
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${RED}错误: 目标目录不存在 $TARGET_DIR${NC}" >&2
        exit 1
    fi

    while true; do
        show_menu
        read -p "请选择主菜单操作 (0-7): " main_choice
        
        case $main_choice in
            4) 
                while true; do
                    show_submenu "修改登录界面logo图片"
                    read -p "请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case $sub_choice in
                        1|2) modify_login_logo $sub_choice; break ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            2) 
                while true; do
                    show_submenu "修改登录界面背景图片"
                    read -p "请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case $sub_choice in
                        1|2) modify_login_bg $sub_choice; break ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            3) 
                while true; do
                    show_submenu "修改设备信息logo图片"
                    read -p "请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case $sub_choice in
                        1|2) modify_device_logo $sub_choice; break ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            6)
                while true; do
                    show_touming_menu
                    read -p "请选择操作 (0-2): " touming_choice
                    
                    case $touming_choice in
                        1) apply_touming_off; break ;;
                        2) apply_touming_on; break ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            5)
                modify_web_title
                ;;
            1)
                while true; do
                    show_preset_menu
                    read -p "请选择预设主题 (0-6): " preset_choice
                    
                    case $preset_choice in
                        1) apply_gundam_theme; break ;;
                        2) apply_miku_theme; break ;;
                        3) apply_gzljss_theme; break ;;
                        4) apply_haizeiwang_theme; break ;;
                        5) apply_jojo_theme; break ;;
                        6) apply_eva_theme; break ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            7)  # 新增：飞牛影视菜单处理
                while true; do
                    show_movie_submenu
                    read -p "请选择飞牛影视修改操作 (0-3): " movie_choice
                    
                    case $movie_choice in
                        1) 
                            modify_movie_title
                            break 
                            ;;
                        2) 
                            while true; do
                                show_movie_file_submenu "修改飞牛影视LOGO"
                                read -p "请选择修改方式 (0-2) [默认1]: " sub_choice
                                sub_choice=${sub_choice:-1}
                                
                                case $sub_choice in
                                    1|2) modify_movie_logo $sub_choice; break ;;
                                    0) break ;;
                                    *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                                esac
                            done
                            break 
                            ;;
                        3) 
                            while true; do
                                show_movie_file_submenu "修改飞牛影视背景"
                                read -p "请选择修改方式 (0-2) [默认1]: " sub_choice
                                sub_choice=${sub_choice:-1}
                                
                                case $sub_choice in
                                    1|2) modify_movie_bg $sub_choice; break ;;
                                    0) break ;;
                                    *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                                esac
                            done
                            break 
                            ;;
                        0) break ;;
                        *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选择，请重新输入${NC}" ;;
        esac
    done
}

main