#!/bin/bash
set -euo pipefail

# ==================== 变量定义区 ====================
# 备份相关变量
readonly BACKUP_DIR="/usr/cqshbak"
readonly BACKUP_RECORD_SUFFIX=".txt"

# 七彩渐变色彩组（18级扩展版：红→绿→蓝→亮紫过渡）
readonly GRAD_1='\033[38;5;196m' # 亮红色
readonly GRAD_2='\033[38;5;202m' # 橙红色
readonly GRAD_3='\033[38;5;208m' # 橙色
readonly GRAD_4='\033[38;5;214m' # 亮橙色
readonly GRAD_5='\033[38;5;220m' # 金黄色
readonly GRAD_6='\033[38;5;226m' # 亮黄色
readonly GRAD_7='\033[38;5;154m' # 黄绿色
readonly GRAD_8='\033[38;5;118m' # 亮绿色
readonly GRAD_9='\033[38;5;46m'  # 翠绿色
readonly GRAD_10='\033[38;5;47m' # 蓝绿色（青绿色）
readonly GRAD_11='\033[38;5;48m' # 深青绿色
readonly GRAD_12='\033[38;5;63m' # 深蓝色（偏紫）
readonly GRAD_13='\033[38;5;33m' # 紫色（偏红）
readonly GRAD_14='\033[38;5;45m' # 粉红色（亮粉）
readonly GRAD_15='\033[38;5;51m' # 玫红色
readonly GRAD_16='\033[38;5;105m' # 蓝紫色（偏蓝）
readonly GRAD_17='\033[38;5;197m' # 深红色
readonly GRAD_18='\033[38;5;201m' # 紫红色（红紫混合）
readonly GRAD_RESET='\033[0m'    # 重置文本格式（恢复默认颜色、样式）

# 基础色调
readonly LIGHT_GRAY='\033[0;37m'      # 浅灰文本
readonly WHITE='\033[1;37m'           # 亮白文本
readonly NC='\033[0m'                 # 重置颜色

# 特效定义
readonly BLINK='\033[5m'               # 闪烁效果
readonly NOBLINK='\033[25m'            # 关闭闪烁
readonly BOLD='\033[1m'                # 加粗
readonly UNDERLINE='\033[4m'           # 下划线
readonly REVERSE='\033[7m'             # 反色
readonly NO_EFFECT='\033[21;24;25;27m' # 关闭所有特效
# 路径定义
readonly TARGET_DIR="${1:-/usr/trim/www/assets}"
readonly MOVIE_DIR="${1:-/usr/local/apps/@appcenter/trim.media/static/assets}"
readonly LOG_FILE="${2:-./js_modification.log}"
readonly BASE_DIR="/usr/trim/www"
readonly RESOURCE_DIR="userimg"
readonly INDEX_FILE="${BASE_DIR}/index.html"
readonly MOVIE_INDEX_FILE="/usr/local/apps/@appcenter/trim.media/static/index.html"

# Favicon路径定义
readonly FLYING_BEE_FAVICON="/usr/trim/www/favicon.ico"
readonly MOVIE_FAVICON="/usr/local/apps/@appcenter/trim.media/static/static/favicon.ico"

# Debian 12 启动脚本路径
readonly STARTUP_SERVICE="/etc/systemd/system/cqshbak.service"
readonly STARTUP_SCRIPT="/usr/local/bin/cqshbak_restore.sh"

# JS/CSS标识定义
readonly LOGIN_FORM_JS_PATTERN="*login-form*"
readonly LOGIN_LOGO_MARKER='o="'
readonly LOGIN_BG_MARKER='url("'
readonly DEVICE_LOGO_MARKER='n8="'
readonly MOVIE_LOGO_MARKER1='WDe="'
readonly MOVIE_LOGO_MARKER2='KDe="'
readonly MOVIE_LOGO_MARKER3='f="'
readonly MOVIE_LOGO_MARKER4='e="'
readonly MOVIE_BG_MARKER='J="'
readonly BACKDROP_BLUR_OFF='backdrop-blur-\\\[0px\\\]{--tw'
readonly BACKDROP_BLUR_OFF1='backdrop-blur-\\\[0px\\\]{--un'
readonly BACKDROP_BLUR_ON='backdrop-blur-\\\[20px\\\]{--tw'
readonly BACKDROP_BLUR_ON1='backdrop-blur-\\\[20px\\\]{--un'

# 透明度相关模式
readonly FLYING_BEE_BLUR_PATTERN='un-backdrop-blur:blur('
readonly MOVIE_BLUR_PATTERN=']{--tw-backdrop-blur: blur('

# ======== cqfnicon 相关配置 ========
readonly JSON_FILE="/usr/cqfnicon/cqfnicon.json"
readonly BASE_PATH="/usr/trim/www"
readonly INDEX_HTML="/usr/trim/www/index.html"
readonly IMAGE_DIR="$BASE_DIR/$RESOURCE_DIR"
readonly DEST_JSON="$IMAGE_DIR/cqfnicon.json"

# 确保目录存在
ensure_cqfnicon_dir() {
    mkdir -p "$(dirname "$JSON_FILE")"
    mkdir -p "$IMAGE_DIR"
}

# 检查依赖工具
check_cqfnicon_dependencies() {
    if ! command -v jq &> /dev/null; then
        echo -e "${GRAD_17}✗ 错误：未安装 jq 工具，请先安装（sudo apt install jq）${NC}"
        return 0
    fi
    if ! command -v curl &> /dev/null; then
        echo -e "${GRAD_17}✗ 错误：未安装 curl 工具，请先安装（sudo apt install curl）${NC}"
        return 0
    fi
    if ! command -v sed &> /dev/null; then
        echo -e "${GRAD_17}✗ 错误：未找到 sed 工具${NC}"
        return 0
    fi
    return 0
}

# 初始化JSON文件（如果不存在）
init_cqfnicon_json() {
    if [ ! -f "$JSON_FILE" ]; then
        echo "[]" > "$JSON_FILE"
        if [ $? -ne 0 ]; then
            echo -e "${GRAD_17}✗ 错误：无法创建配置文件，请检查目录权限（可能需要sudo）${NC}"
            return 0
        else
            echo -e "${GRAD_8}✓ 配置文件创建成功${NC}"
        fi
    fi
    return 0
}

# 宽松URL验证规则：支持包含特殊字符的URL
is_cqfnicon_valid_url() {
    local url="$1"
    # 匹配基本协议格式，允许后续包含任意非空白字符
    local regex='^(https?|ftp)://[^[:space:]]+$'
    
    if [[ $url =~ $regex ]]; then
        # 快速检测URL是否可访问（仅检查头部）
        if curl -s -L --connect-timeout 10 --head "$url" &> /dev/null; then
            return 0
        else
            echo -e "${GRAD_4}⚠️ 提示：该URL格式正确，但可能无法访问（网络问题或链接失效）${NC}"
            return 0
        fi
    else
        return 0
    fi
}

# 获取下一个序号（优先填补空缺）
get_cqfnicon_next_seq() {
    local seq_list=$(jq -r '.[] | .["序号"]' "$JSON_FILE" | sort -n)
    local current=1
    
    if [ -z "$seq_list" ]; then
        echo 1
        return
    fi
    
    while true; do
        if ! echo "$seq_list" | grep -q "^$current$"; then
            echo "$current"
            return
        fi
        current=$((current + 1))
    done
}

# 下载图片（生成相对路径）
download_cqfnicon_image() {
    local image_url=$1
    local title=$2
    
    local safe_title=$(echo "$title" | sed 's/[\\/*?:"<>|]/_/g')
    local ext=$(echo "$image_url" | awk -F. '{print $NF}' | tr '[:upper:]' '[:lower:]')
    # 支持多种图片格式
    if [[ ! $ext =~ ^(jpg|jpeg|png|gif|bmp|webp|svg|ico)$ ]]; then
        ext="jpg"
    fi
    
    local file_path="$IMAGE_DIR/$safe_title.$ext"
    local rel_path=$(echo "$file_path" | sed "s|^$BASE_PATH/||")
    
    # 下载图片，允许重定向
    if curl -s -S -L --connect-timeout 15 -o "$file_path" "$image_url"; then
        echo "$rel_path"
        return 0
    else
        echo "下载失败"
        return 0
    fi
}

# 添加记录
add_cqfnicon_record() {
    local title
while true; do
    read -p "请输入图标标题（按下回车取消并返回）：" title
    # 若输入为空（按下回车），则取消操作并返回
    if [ -z "$title" ]; then
        echo -e "${GRAD_4}已取消操作${NC}"
        return 0
    fi
    # 输入非空则退出循环，继续后续流程
    break
done

    local jump_url
while true; do
    read -p "请输入点击图标跳转URL（按下回车取消并返回）：" jump_url
    # 若输入为空（按下回车），则取消操作并返回
    if [ -z "$jump_url" ]; then
        echo -e "${GRAD_4}已取消操作${NC}"
        return 0
    fi
    # 验证URL格式是否有效
    if is_cqfnicon_valid_url "$jump_url"; then
        break
    fi
    echo -e "${GRAD_17}✗ 跳转URL格式无效，请重新输入（需以http/https/ftp开头，且无空格）${NC}"
done

    local image_url
while true; do
    read -p "请输入图标图片文件URL（按下回车取消并返回）：" image_url
    # 若输入为空（按下回车），则取消操作并返回
    if [ -z "$image_url" ]; then
        echo -e "${GRAD_4}已取消操作${NC}"
        return 0
    fi
    # 验证图片URL格式是否有效
    if is_cqfnicon_valid_url "$image_url"; then
        break
    fi
    echo -e "${GRAD_17}✗ 图片URL格式无效，请重新输入（需以http/https/ftp开头，且无空格）${NC}"
done

    echo -e "${GRAD_12}正在下载图片（可能需要几秒，取决于网络）...${NC}"
    local local_image=$(download_cqfnicon_image "$image_url" "$title")
    if [ "$local_image" = "下载失败" ]; then
        echo -e "${GRAD_17}✗ 图片下载失败，取消添加记录${NC}"
        return 0
    fi

    local seq=$(get_cqfnicon_next_seq)
    
    jq --arg seq "$seq" \
       --arg title "$title" \
       --arg jump_url "$jump_url" \
       --arg image_url "$local_image" \
       '. + [{ "序号": ($seq | tonumber), "标题": $title, "跳转URL": $jump_url, "图片URL": $image_url }]' \
       "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"

    # 检查源目录是否存在
if [ -d "/usr/cqshbak/resource_dir_backup" ]; then
    # 源目录存在，执行复制（-r递归，-n不覆盖已存在文件）
    cp -r "$BASE_PATH/$local_image" "/usr/cqshbak/resource_dir_backup"
fi

    apply_cqfnicon_settings
    echo -e "${GRAD_8}✓ 成功添加一只图标，序号：$seq${NC}"
}

delete_cqfnicon_record() {
    query_cqfnicon_records
    local count=$(jq 'length' "$JSON_FILE")
    if [ $count -eq 0 ]; then
        echo -e "${GRAD_4}⚠️ 没有记录可删除${NC}"
        return 0
    fi

    local seq
    while true; do
        read -p "请输入要删除的图标序号（按下回车取消并返回）：" seq
        # 若输入为空（按下回车），直接返回
        if [ -z "$seq" ]; then
            echo -e "${GRAD_4}已取消删除操作${NC}"
            return 0
        fi
        # 检查是否为有效数字
        if [[ $seq =~ ^[0-9]+$ ]]; then
            break
        fi
        echo -e "${GRAD_17}✗ 请输入有效的数字序号${NC}"
    done

    # 检查记录是否存在并获取对应的图片URL
    local image_url=$(jq --arg seq "$seq" '.[] | select(.[ "序号" ] == ($seq | tonumber)) | .["图片URL"]' "$JSON_FILE" -r)
    local exists=$(echo "$image_url" | wc -l)  # 检查是否找到记录
    if [ $exists -eq 0 ] || [ "$image_url" = "null" ]; then
        echo -e "${GRAD_17}✗ 未找到序号为 $seq 的记录${NC}"
        return 0
    fi

    # 构建图片实际路径（基于BASE_PATH和存储的相对路径）
    local image_path="$BASE_PATH/$image_url"
    local image_path_bak="/usr/cqshbak/resource_dir_backup/${image_url##*/}"

    # 删除图片文件
    if [ -f "$image_path" ]; then
        if rm -f "$image_path"; then
            echo -e "${GRAD_8}✓ 已删除对应的图片文件: $image_path${NC}"
        else
            echo -e "${GRAD_17}✗ 图片文件删除失败（可能权限不足）: $image_path${NC}"
            # 即使图片删除失败，仍继续删除记录（可根据需求调整是否终止）
        fi
    else
        echo -e "${GRAD_4}⚠️ 未找到对应的图片文件（可能已被手动删除）: $image_path${NC}"
    fi
    if [ -f "$image_path_bak" ]; then
        if rm -f "$image_path_bak"; then
            echo -e "${GRAD_8}✓ 已删除对应的图片文件: $image_path_bak${NC}"
        else
            echo -e "${GRAD_17}✗ 图片文件删除失败（可能权限不足）: $image_path_bak${NC}"
            # 即使图片删除失败，仍继续删除记录（可根据需求调整是否终止）
        fi
    else
        echo -e "${GRAD_4}⚠️ 未找到对应的图片文件（可能已被手动删除）: $image_path_bak${NC}"
    fi

    # 删除JSON中的记录
    jq --arg seq "$seq" 'del(.[] | select(.[ "序号" ] == ($seq | tonumber)))' "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
    apply_cqfnicon_settings
    echo -e "${GRAD_8}✓ 成功删除序号为 $seq 的记录${NC}"
}

# 查询记录
query_cqfnicon_records() {
    local count=$(jq 'length' "$JSON_FILE")
    if [ $count -eq 0 ]; then
        echo -e "${GRAD_4}⚠️ 没有记录${NC}"
        return 0
    fi

    show_header "所有自定义图标记录"
    jq -r 'sort_by(["序号"])[] | "\(.["序号"]) - \(.["标题"]) (\(.["跳转URL"]))"' "$JSON_FILE"
    show_separator
}

# 应用设置功能
apply_cqfnicon_settings() {
    show_header "执行应用设置"
SOURCE_DIR="/usr/cqshbak/resource_dir_backup"
DEST_DIR="/usr/trim/www/userimg/"

# 检查源目录是否存在
if [ -d "/usr/cqshbak/resource_dir_backup" ]; then
    # 源目录存在，执行复制（-r递归，-n不覆盖已存在文件）
    cp -r "$JSON_FILE" "/usr/trim/www/userimg/"
    cp -r "$JSON_FILE" "/usr/cqshbak/resource_dir_backup"
fi
    # 1. 复制JSON文件到目标目录
    echo -e "${GRAD_12}复制配置文件到$IMAGE_DIR...${NC}"
    if cp "$JSON_FILE" "$DEST_JSON"; then
        echo -e "${GRAD_8}✓ 配置文件复制成功${NC}"
    else
        echo -e "${GRAD_17}✗ 错误：配置文件复制失败${NC}"
        return 0
    fi
    
    # 2. 处理index.html文件
    echo -e "${GRAD_12}处理飞牛文件...${NC}"
    
    if [ ! -f "$INDEX_HTML" ]; then
        echo -e "${GRAD_17}✗ 错误：未找到$INDEX_HTML文件${NC}"
        return 0
    fi
    
    local script_temp=$(mktemp)
    local html_temp=$(mktemp)
    
    # 插入到HTML中的脚本
    cat << 'EOF' > "$script_temp"
    <script>
    window.onload = function() {
        const targetSelector = 'div.box-border.flex.size-full.flex-col.flex-wrap.place-content-start.items-start.py-base-loose';
        const maxRetries = 100;
        let retryCount = 0;
        const retryInterval = 1500;

        function findTargetElement() {
            return document.querySelector(targetSelector);
        }

        function processData() {
            fetch("userimg/cqfnicon.json")
                .then(response => {
                    if (!response.ok) throw new Error("JSON文件加载失败");
                    return response.json();
                })
                .then(data => {
                    const targetDiv = findTargetElement();
                    if (!targetDiv) {
                        console.error("最终未找到目标div元素");
                        return;
                    }

                    data.sort((a, b) => a.序号 - b.序号);
                    
                    data.forEach(item => {
                        const aTag = document.createElement("a");
                        aTag.target = "_blank";
                        aTag.href = item["跳转URL"];
                        aTag.className = "flex h-[124px] w-[130px] cursor-pointer flex-col items-center justify-center gap-4 no-underline";
                        
                        aTag.innerHTML = `
                            <div class="flex shrink-0 flex-row items-center overflow-hidden">
                                <div class="size-[80px] p-[15%] box-border !h-[50px] !w-[50px] !p-0">
                                    <div class="semi-image size-full">
                                        <img src="${item["图片URL"]}" alt="${item["标题"]}" class="semi-image-img w-full h-full !rounded-[10%]" style="user-select: none; pointer-events: none;">
                                    </div>
                                </div>
                            </div>
                            <div class="flex h-base-loose shrink-0 items-center justify-center gap-x-2.5 self-stretch px-2.5">
                                <div class="line-clamp-1 text-white" title="${item["标题"]}" style="text-shadow: rgba(0, 0, 0, 0.2) 0px 1px 6px, rgba(0, 0, 0, 0.5) 0px 0px 4px;font-size: 14px;font-weight: bold;line-height: 1.25;">${item["标题"]}</div>
                            </div>
                        `;
                        
                        targetDiv.appendChild(aTag);
                    });
                    console.log("数据加载完成，共添加", data.length, "条记录");
                })
                .catch(error => console.error("处理数据时出错:", error));
        }

        function initWithRetry() {
            const targetDiv = findTargetElement();
            if (targetDiv) {
                console.log("找到目标div元素，开始处理数据");
                processData();
            } else if (retryCount < maxRetries) {
                retryCount++;
                console.log(`未找到目标div，将在${retryInterval}ms后重试（${retryCount}/${maxRetries}）`);
                setTimeout(initWithRetry, retryInterval);
            } else {
                console.error(`超过最大重试次数（${maxRetries}次），仍未找到目标div`);
            }
        }

        initWithRetry();
    };
    </script>
EOF

    # 处理HTML文件内容
    sed -e '/<body>/,/<div id="root">/ {
        //!d
    }' "$INDEX_HTML" > "$html_temp"

    # 插入脚本内容
    sed -i "/<div id=\"root\">/e cat $script_temp" "$html_temp"

    # 写回原文件并设置权限
    if mv "$html_temp" "$INDEX_HTML"; then
        chmod 644 "$INDEX_HTML"
        echo -e "${GRAD_8}✓ 飞牛文件处理成功${NC}"
        # 备份修改后的文件
        backup_modified_file "$INDEX_HTML"
    else
        echo -e "${GRAD_17}✗ 错误：HTML文件处理失败${NC}"
        rm -f "$html_temp"
        return 0
    fi
    
    # 清理临时文件
    rm -f "$script_temp"
    backup_modified_file "$INDEX_FILE"
    echo -e "${GRAD_8}✓ 应用设置完成${NC}"
}

# cqfnicon子菜单
show_cqfnicon_menu() {
    show_header "自定义飞牛主界面APP图标"
    echo -e "\n${BOLD}${GRAD_4}* ${GRAD_11}图标管理已改单独工具，更便捷更好用${GRAD_4} *${NC}\n${BOLD}${GRAD_4}* ${GRAD_11}请到飞牛论坛搜米恋泥或Github：IMGZCQ/fndesk${GRAD_4} *${NC}\n"
    # echo -e "1. 增加一只APP图标"
    # echo -e "2. 删除一只APP图标"
    # echo -e "3. 查询所有APP图标编号"
    echo -e "0. 返回主菜单"
    show_separator
}

# 执行cqfnicon功能
run_cqfnicon() {
    # 确保目录存在
    # ensure_cqfnicon_dir
    # 检查依赖
    # if ! check_cqfnicon_dependencies; then
    #     return 0
    # fi
    
    # 初始化JSON
    # if ! init_cqfnicon_json; then
    #     return 0
    # fi
    # apply_cqfnicon_settings
    while true; do
        show_cqfnicon_menu
        read -p "→ 请选择操作 (0-4): " choice

        case $choice in
            # 1) add_cqfnicon_record ;;
            # 2) delete_cqfnicon_record ;;
            # 3) query_cqfnicon_records ;;
            # 4) apply_cqfnicon_settings ;;
            0) break ;;
            *) echo -e "${GRAD_17}✗ 无效的选择，请输入0-3之间的数字${NC}" ;;
        esac
    done
}

# 显示带科技感的标题
show_header() {
    local title="$1"
    local line=$(printf "%0.s═" $(seq 1 $(( ${#title} + 35 )) ))
    echo -e "\n${GRAD_15}╔${line}╗${NC}"
    echo -e "${GRAD_15}          -- ${BLINK}${title}${NOBLINK} --${NC}"
    echo -e "${GRAD_15}╚${line}╝${NC}"
}

# 检查是否为root用户
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${GRAD_17}✗ 错误：此脚本需要root权限才能运行${NC}" >&2
        echo -e "${GRAD_17}✗ 请使用 sudo -i 命令或以 root 用户身份执行。${NC}" >&2
        exit 1
    fi
    echo -e "${GRAD_8}✓ 已确认root权限，开始执行脚本...${NC}"
}

# URL验证函数
# 参数: 待验证的URL
# 返回: 0-有效, 1-无效
validate_url() {
    local url="$1"
    [[ "$url" =~ ^https?:// ]] || return 1
    return 0
}

# 检查并创建资源目录
check_resource_dir() {
    local dir_path="${BASE_DIR}/${RESOURCE_DIR}"
    if [ ! -d "$dir_path" ]; then
        echo -e "${GRAD_4}⚠️ 资源目录不存在，正在创建: $dir_path${NC}"
        mkdir -p "$dir_path" && chmod 755 "$dir_path" && \
        echo -e "${GRAD_8}✓ 资源目录创建成功${NC}" || \
        echo -e "${GRAD_17}✗ 资源目录创建失败${NC}"
    fi
}

# 初始化备份目录
init_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${GRAD_4}⚠️ 备份目录不存在，正在创建: $BACKUP_DIR${NC}"
        mkdir -p "$BACKUP_DIR" && chmod 755 "$BACKUP_DIR" && \
        echo -e "${GRAD_8}✓ 备份目录创建成功${NC}" || \
        echo -e "${GRAD_17}✗ 备份目录创建失败${NC}"
    fi
}

# 备份修改后的文件
backup_modified_file() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${GRAD_17}✗ 要备份的文件不存在: $file_path${NC}"
        return 0
    fi

    # 获取文件名和路径，生成唯一标识（替换路径分隔符为下划线）
    local file_name=$(basename "$file_path")
    local file_dir=$(dirname "$file_path" | tr '/' '_')  # 将路径中的/替换为_
    local unique_name="${file_dir}_${file_name}"  # 生成如"usr_trim_www_favicon.ico"的唯一名称
    
    local backup_file="${BACKUP_DIR}/${unique_name}"
    local record_file="${BACKUP_DIR}/${unique_name}${BACKUP_RECORD_SUFFIX}"

    # 复制文件到备份目录（使用唯一名称）
    if cp -f "$file_path" "$backup_file"; then
        # 记录原始路径
        echo "$file_path" > "$record_file"
        echo -e "${GRAD_8}✓ 修改后的文件已备份到: ${NC}$backup_file"
        echo -e "${GRAD_8}✓ 原始路径记录到: ${NC}$record_file"
    else
        echo -e "${GRAD_17}✗ 文件备份失败: $file_path${NC}"
    fi
}

# 安全替换函数（备份修改后的文件）
safe_replace() {
    local file_path="$1"
    local original="$2"
    local new_value="$3"

    # 转义特殊字符
    local escaped_value=$(printf '%q' "$new_value" | sed "s/'/'\\\\''/g")

    # 执行替换并保留双引号结构
    if sed -i "s|${original}[^\"]*\"|${original}${escaped_value}\"|g" "$file_path"; then
        echo -e "${GRAD_8}✓ 成功更新: ${NC}$new_value"
        # 备份修改后的文件
        backup_modified_file "$file_path"
    else
        echo -e "${GRAD_17}✗ 更新失败: ${NC}$file_path"
    fi
}

# 带提示的输入函数
# 参数: 提示信息
# 返回: 用户输入内容
prompt_input() {
    local prompt="$1"
    read -p "$prompt (返回不修改请直接按Enter): " input
    echo "$input"
}

# 查找最大的文件
# 参数: 目录路径, 文件模式(如"*.js")
# 返回: 最大文件的路径
find_largest_file() {
    local dir="$1"
    local pattern="$2"
    
    if [ ! -d "$dir" ]; then
        echo -e "${GRAD_17}✗ 目录不存在: $dir${NC}"
        return 0
    fi
    
    local largest_file=$(find "$dir" -type f -name "$pattern" -exec du -ah {} + 2>/dev/null | sort -rh | head -n1 | awk '{print $2}')
    
    if [ -z "$largest_file" ] || [ ! -f "$largest_file" ]; then
        echo -e "${GRAD_17}✗ 未找到符合条件的$pattern文件${NC}"
        return 0
    fi
    
    echo "$largest_file"
    return 0
}

# 查找登录表单JS文件
# 返回: 登录表单JS文件路径
find_login_form_js() {
    local login_file=$(find "$TARGET_DIR" -type f -name "*.js" -iname "$LOGIN_FORM_JS_PATTERN" | head -n1)
    
    if [ -z "$login_file" ] || [ ! -f "$login_file" ]; then
        echo -e "${GRAD_17}✗ 未找到登录表单JS文件${NC}"
        return 0
    fi
    
    echo "$login_file"
    return 0
}

add_persistence() {
    # 创建恢复脚本（重点修改恢复资源文件夹的逻辑）
    cat << 'EOF' > "$STARTUP_SCRIPT"
#!/bin/bash
BACKUP_DIR="/usr/cqshbak"
BACKUP_RECORD_SUFFIX=".txt"
RESOURCE_BACKUP_NAME="resource_dir_backup"
RESOURCE_RECORD_FILE="${BACKUP_DIR}/${RESOURCE_BACKUP_NAME}${BACKUP_RECORD_SUFFIX}"

# 先恢复资源文件夹（修复嵌套问题）
if [ -f "$RESOURCE_RECORD_FILE" ]; then
    original_resource_dir=$(cat "$RESOURCE_RECORD_FILE")
    resource_backup_path="${BACKUP_DIR}/${RESOURCE_BACKUP_NAME}"
    
    if [ -d "$resource_backup_path" ] && [ -n "$original_resource_dir" ]; then
        # 创建原始目录（如果不存在）
        mkdir -p "$original_resource_dir"
        # 恢复备份内容到目标目录（覆盖现有内容，不嵌套目录）
        cp -rf "$resource_backup_path"/* "$original_resource_dir/"
        echo "Restored resource files to: $original_resource_dir"
    fi
fi

# 恢复其他文件（保持不变）
if [ -d "$BACKUP_DIR" ]; then
    find "$BACKUP_DIR" -type f ! -name "*$BACKUP_RECORD_SUFFIX" ! -path "$BACKUP_DIR/$RESOURCE_BACKUP_NAME/*" | while read -r backup_file; do
        base_name=$(basename "$backup_file")
        record_file="${BACKUP_DIR}/${base_name}${BACKUP_RECORD_SUFFIX}"
        
        if [ -f "$record_file" ]; then
            original_path=$(cat "$record_file")
            original_dir=$(dirname "$original_path")
            
            if [ -d "$original_dir" ]; then
                cp -f "$backup_file" "$original_path"
                echo "Restored modified version of: $original_path"
            fi
        fi
    done
fi
EOF

    # 确保备份目录存在
    mkdir -p "$BACKUP_DIR"
    
    # 复制整个资源文件夹到备份目录（修复备份逻辑，只备份内容）
    if [ -d "${BASE_DIR}/${RESOURCE_DIR}" ]; then
        echo -e "${GRAD_12}正在备份资源文件夹到 $BACKUP_DIR...${NC}"
        resource_backup_path="${BACKUP_DIR}/resource_dir_backup"
        # 先清空旧备份（避免残留文件干扰）
        rm -rf "$resource_backup_path"
        mkdir -p "$resource_backup_path"
        # 只复制userimg内的内容（包括隐藏文件），不复制文件夹本身
        cp -rf "${BASE_DIR}/${RESOURCE_DIR}/." "$resource_backup_path/"
        # 记录原始资源文件夹路径
        echo "${BASE_DIR}/${RESOURCE_DIR}" > "${BACKUP_DIR}/resource_dir_backup${BACKUP_RECORD_SUFFIX}"
        echo -e "${GRAD_8}✓ 资源文件夹备份完成${NC}"
    else
        echo -e "${GRAD_4}⚠️ 资源文件夹 ${BASE_DIR}/${RESOURCE_DIR} 不存在，跳过备份${NC}"
    fi

    # 后续代码（壁纸备份、服务配置等）保持不变...
    # 新增：备份默认壁纸文件
    local wallpaper_path="/usr/trim/www/static/bg/wallpaper-1.webp"
    if [ -f "$wallpaper_path" ]; then
        echo -e "${GRAD_12}正在备份默认壁纸文件: $wallpaper_path${NC}"
        local wallpaper_backup_name=$(echo "$wallpaper_path" | tr '/' '_')
        local wallpaper_backup_file="${BACKUP_DIR}/${wallpaper_backup_name}"
        cp -f "$wallpaper_path" "$wallpaper_backup_file"
        echo "$wallpaper_path" > "${BACKUP_DIR}/${wallpaper_backup_name}${BACKUP_RECORD_SUFFIX}"
        echo -e "${GRAD_8}✓ 默认壁纸文件已备份到: $wallpaper_backup_file${NC}"
    else
        echo -e "${GRAD_4}⚠️ 默认壁纸文件不存在: $wallpaper_path，跳过备份${NC}"
    fi

    # 设置脚本权限
    chmod +x "$STARTUP_SCRIPT" || {
        echo -e "${GRAD_17}✗ 设置脚本权限失败${NC}"
        return 0
    }

    # 创建systemd服务文件（保持不变）
    cat << EOF > "$STARTUP_SERVICE"
[Unit]
Description=CQSHBAK Persistence Service
After=network.target

[Service]
Type=oneshot
ExecStart=$STARTUP_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # 编辑服务文件添加延迟启动配置（保持不变）
    if ! sudo sed -i '/\[Service\]/a ExecStartPre=/bin/sleep 100' "$STARTUP_SERVICE"; then
        echo -e "${GRAD_17}✗ 编辑服务文件失败${NC}"
        return 0
    fi

    # 重新加载系统服务配置（保持不变）
    echo -e "${GRAD_12}正在重新加载系统服务配置...${NC}"
    if ! systemctl daemon-reload; then
        echo -e "${GRAD_17}✗ 系统服务配置重载失败${NC}"
        return 0
    fi

    # 启用服务（保持不变）
    echo -e "${GRAD_12}正在启用服务...${NC}"
    if ! systemctl enable cqshbak.service; then
        echo -e "${GRAD_17}✗ 服务启用失败${NC}"
        return 0
    fi

    # 启动服务（保持不变）
    echo -e "${GRAD_12}正在启动服务（可能需要几秒钟）...${NC}"
    if ! timeout 30 systemctl start cqshbak.service; then
        echo -e "${GRAD_4}⚠️ 服务启动超时，但已成功设置开机自启${NC}"
        echo -e "${GRAD_4}⚠️ 下次重启时将自动生效${NC}"
    else
        echo -e "${GRAD_8}✓ 服务启动成功${NC}"
    fi

    echo -e "${GRAD_8}✓ 持久化处理已添加到系统服务（已配置100秒延迟生效）${NC}"
    echo -e "${GRAD_8}✓ 服务名称: cqshbak.service${NC}"
}

# 设置开机自动执行mount操作
todo_www_mount() {
    # 定义绑定挂载的源路径和目标挂载点
    SOURCE_DIR="/usr/trim/share/.restore/tow"
    MOUNT_POINT="/usr/trim/www"
    
    # 创建systemd服务文件
    SERVICE_FILE="/etc/systemd/system/www-mount.service"
    
    echo -e "${GRAD_12}正在配置开机自动挂载服务...${NC}"
    
    # 检查并卸载所有已存在的挂载，确保只有一条mount记录
    echo -e "${GRAD_4}⚠️ 检查并卸载已存在的挂载...${NC}"
    if mount | grep -q "$MOUNT_POINT"; then
        echo -e "${GRAD_12}发现已存在的挂载，正在卸载...${NC}"
        if umount "$MOUNT_POINT"; then
            echo -e "${GRAD_8}✓ 已成功卸载现有挂载${NC}"
        else
            echo -e "${GRAD_17}✗ 卸载失败，尝试强制卸载...${NC}"
            if umount -f "$MOUNT_POINT"; then
                echo -e "${GRAD_8}✓ 已成功强制卸载现有挂载${NC}"
            else
                echo -e "${GRAD_17}✗ 强制卸载也失败${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GRAD_4}⚠️ 未发现已存在的挂载${NC}"
    fi
    
    # 创建服务文件内容 - 延时100秒后再卸载挂载，确保只有一条mount记录
    cat << EOF > "$SERVICE_FILE"
[Unit]
Description=WWW Directory Bind Mount Service
After=network.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 180
ExecStart=/bin/bash -c "if mount | grep -q '$MOUNT_POINT'; then umount -f '$MOUNT_POINT' 2>/dev/null; fi && mount -o bind $SOURCE_DIR $MOUNT_POINT"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd配置
    if systemctl daemon-reload; then
        echo -e "${GRAD_8}✓ 系统服务配置重载成功${NC}"
    else
        echo -e "${GRAD_17}✗ 系统服务配置重载失败${NC}"
        return 1
    fi
    
    # 启用服务
    if systemctl enable www-mount.service; then
        echo -e "${GRAD_8}✓ 服务已设置为开机自启${NC}"
    else
        echo -e "${GRAD_17}✗ 服务启用失败${NC}"
        return 1
    fi
    
    # 立即启动服务
    if systemctl start www-mount.service; then
        echo -e "${GRAD_8}✓ 服务启动成功，挂载已生效${NC}"
        echo -e "${GRAD_4}⚠️ 重启后将自动执行挂载操作${NC}"
    else
        echo -e "${GRAD_17}✗ 服务启动失败${NC}"
        # 尝试直接执行挂载命令
        echo -e "${GRAD_4}⚠️ 尝试直接执行挂载命令...${NC}"
        if mount -o bind "$SOURCE_DIR" "$MOUNT_POINT"; then
            echo -e "${GRAD_8}✓ 直接挂载成功${NC}"
        else
            echo -e "${GRAD_17}✗ 直接挂载失败${NC}"
        fi
    fi
    
    # 显示当前挂载状态
    echo -e "${GRAD_12}当前挂载状态:${NC}"
    findmnt "$MOUNT_POINT"
    return 0
}

# 取消开机自动mount操作并立即umount
todo_www_umount() {
    # 定义目标挂载点
    MOUNT_POINT="/usr/trim/www"
    SERVICE_FILE="/etc/systemd/system/www-mount.service"
    
    echo -e "${GRAD_12}正在取消开机自动挂载并立即卸载...${NC}"
    
    # 检查并停止服务
    if systemctl is-active --quiet www-mount.service; then
        if systemctl stop www-mount.service; then
            echo -e "${GRAD_8}✓ 服务已停止${NC}"
        else
            echo -e "${GRAD_17}✗ 服务停止失败${NC}"
        fi
    else
        echo -e "${GRAD_4}⚠️ 服务未运行，跳过停止步骤${NC}"
    fi
    
    # 禁用服务
    if systemctl is-enabled --quiet www-mount.service; then
        if systemctl disable www-mount.service; then
            echo -e "${GRAD_8}✓ 服务已禁用，不再开机自启${NC}"
        else
            echo -e "${GRAD_17}✗ 服务禁用失败${NC}"
        fi
    else
        echo -e "${GRAD_4}⚠️ 服务未启用，跳过禁用步骤${NC}"
    fi
    
    # 删除服务文件
    if [ -f "$SERVICE_FILE" ]; then
        if rm -f "$SERVICE_FILE"; then
            echo -e "${GRAD_8}✓ 服务文件已删除${NC}"
            # 重新加载systemd配置
            systemctl daemon-reload
        else
            echo -e "${GRAD_17}✗ 服务文件删除失败${NC}"
        fi
    else
        echo -e "${GRAD_4}⚠️ 服务文件不存在，跳过删除步骤${NC}"
    fi
    
    # 立即执行卸载操作
    echo -e "${GRAD_12}正在执行卸载操作...${NC}"
    if findmnt "$MOUNT_POINT" >/dev/null 2>&1; then
        # 尝试常规卸载
        if umount "$MOUNT_POINT"; then
            echo -e "${GRAD_8}✓ 常规卸载成功${NC}"
        else
            # 尝试懒卸载
            echo -e "${GRAD_4}⚠️ 常规卸载失败，尝试懒卸载...${NC}"
            if umount -l "$MOUNT_POINT"; then
                echo -e "${GRAD_8}✓ 懒卸载成功${NC}"
            else
                echo -e "${GRAD_17}✗ 卸载失败，请手动处理${NC}"
            fi
        fi
        
        # 显示卸载后的状态
        echo -e "${GRAD_12}卸载后的挂载状态:${NC}"
        findmnt "$MOUNT_POINT" || echo -e "${GRAD_8}✓ 挂载已移除${NC}"
    else
        echo -e "${GRAD_4}⚠️ $MOUNT_POINT 当前未挂载，跳过卸载步骤${NC}"
    fi
    
    return 0
}

# 移除启动项中的持久化处理（保留但已被新函数替代）
remove_persistence() {
    # 停止并禁用服务
    if systemctl is-active --quiet cqshbak.service; then
        systemctl stop cqshbak.service
    fi
    
    if systemctl is-enabled --quiet cqshbak.service; then
        systemctl disable cqshbak.service
    fi

    # 删除服务文件和脚本
    rm -f "$STARTUP_SERVICE"
    rm -f "$STARTUP_SCRIPT"
    
    # 清空备份目录中的所有文件（保留原始目录结构）
if [ -d "$BACKUP_DIR" ]; then
    echo -e "${GRAD_4}⚠️ 正在删除备份目录中的文件: $BACKUP_DIR${NC}"
    # 只删除主目录内的直接文件，不处理子目录及其内容
    find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type f -delete
    if [ $? -eq 0 ]; then
        echo -e "${GRAD_8}✓ 备份目录文件已删除${NC}"
    else
        echo -e "${GRAD_17}✗ 备份目录文件删除失败${NC}"
    fi
fi
    
    systemctl daemon-reload
    
    echo -e "${GRAD_8}✓ 已取消持久化处理，重启后修改将还原${NC}"
}

# 下载图片并替换favicon，保持原文件权限
replace_favicon() {
    local target_path="$1"
    local file_type="${2:-ico}"  # 默认ico格式
    local url=""
    local original_perms=""
    
    while true; do
        url=$(prompt_input "请输入图标URL，建议用64x64或128*128像素的图片")
        if [ -z "$url" ]; then
            echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
            return
        elif validate_url "$url"; then
            break
        else
            echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
        fi
    done

    # 临时文件路径
    local temp_file=$(mktemp)
    
    # 保存原始文件权限（如果存在）
    if [ -f "$target_path" ]; then
        original_perms=$(stat -c "%a" "$target_path")
        echo -e "${GRAD_12}已记录原始文件权限: ${original_perms}${NC}"
    else
        # 如果文件不存在，使用默认权限
        original_perms="644"
        echo -e "${GRAD_4}文件不存在，将使用默认权限: ${original_perms}${NC}"
    fi
    
    # 下载图片
    echo -e "${GRAD_12}正在下载图片...${NC}"
    if curl -s -f -o "$temp_file" "$url"; then
        # 替换文件
        if mv -f "$temp_file" "$target_path"; then
            # 恢复原始文件权限
            chmod "$original_perms" "$target_path"
            echo -e "${GRAD_8}✓ 成功替换图标文件并恢复权限: ${NC}$target_path"
            echo -e "${GRAD_8}✓ 权限已设置为: ${original_perms}${NC}"
            # 备份修改后的文件
            backup_modified_file "$target_path"
            return 0
        else
            echo -e "${GRAD_17}✗ 替换文件失败${NC}"
            rm -f "$temp_file"
            return 0
        fi
    else
        echo -e "${GRAD_17}✗ 下载图片失败，请检查URL是否有效${NC}"
        rm -f "$temp_file"
        return 0
    fi
}

# ==================== 功能函数区 ====================

# 修改登录界面logo
# 参数: 模式(1-使用本地路径, 2-使用URL)
modify_login_logo() {
    local mode="$1"
    local value=""
    local local_filename="login_logo.png"
    local local_path="${BASE_DIR}/${RESOURCE_DIR}/${local_filename}"
    local local_relative_path="${RESOURCE_DIR}/${local_filename}"
    
    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local path="$2"
        
        # 检查资源目录
        check_resource_dir
                
        local temp_file=$(mktemp)
        echo -e "${GRAD_12}正在下载 $local_filename...${NC}"
        
        if curl -s -f -o "$temp_file" "$url"; then
            if mv -f "$temp_file" "$path"; then
                chmod 644 "$path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }
    
    case "$mode" in
        1) 
            value="$local_relative_path"
            # 检查本地文件是否存在
            if [ ! -f "$local_path" ]; then
                echo -e "${GRAD_4}⚠️ 本地文件不存在: $local_path${NC}"
                return 0
            fi
            ;;
        2) 
            while true; do
                local url=$(prompt_input "请输入登录logo图片URL")
                if [ -z "$url" ]; then
                    echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$url"; then
                    # 下载图片
                    if download_image "$url" "$local_path"; then
                        value="$local_relative_path"
                    else
                        echo -e "${GRAD_4}⚠️ 下载失败，取消修改${NC}"
                        return 0
                    fi
                    break
                else
                    echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    show_header "修改登录界面logo图片"
    local login_file=$(find_login_form_js)
    if [ -n "$login_file" ] && [ -f "$login_file" ]; then
        safe_replace "$login_file" "$LOGIN_LOGO_MARKER" "$value"
    fi
}

# 修改登录背景图片
# 参数: 模式(1-使用本地路径, 2-使用URL)
modify_login_bg() {
    local mode="$1"
    local value=""
    local local_filename="login_bg.jpg"
    local local_path="${BASE_DIR}/${RESOURCE_DIR}/${local_filename}"
    local local_relative_path="${RESOURCE_DIR}/${local_filename}"
    local modify_success=0  # 标记修改是否成功
    
    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local path="$2"
        
        # 检查资源目录
        check_resource_dir
                
        local temp_file=$(mktemp)
        echo -e "${GRAD_12}正在下载 $local_filename...${NC}"
        
        if curl -s -f -o "$temp_file" "$url"; then
            if mv -f "$temp_file" "$path"; then
                chmod 644 "$path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }
    
    case "$mode" in
        1) 
            value="$local_relative_path"
            # 检查本地文件是否存在
            if [ ! -f "$local_path" ]; then
                echo -e "${GRAD_4}⚠️ 本地文件不存在: $local_path${NC}"
                return 0
            fi
            ;;
        2) 
            while true; do
                local url=$(prompt_input "请输入登录背景图片URL")
                if [ -z "$url" ]; then
                    echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$url"; then
                    # 下载图片
                    if download_image "$url" "$local_path"; then
                        value="$local_relative_path"
                    else
                        echo -e "${GRAD_4}⚠️ 下载失败，取消修改${NC}"
                        return 0
                    fi
                    break
                else
                    echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    show_header "修改登录界面背景图片"
    local login_file=$(find_login_form_js)
    if [ -n "$login_file" ] && [ -f "$login_file" ]; then
        safe_replace "$login_file" "$LOGIN_BG_MARKER" "$value"
        modify_success=1  # 标记修改成功
    fi

    # 询问是否应用到默认壁纸
    if [ $modify_success -eq 1 ]; then
        echo -e "\n${GRAD_15}是否把修改的图片同时应用到默认壁纸？（Y or N）${NC}"
        read -p "请选择: " choice
        case "$choice" in
            [Yy])
                local target_dir="/usr/trim/www/static/bg"
                local target_file="${target_dir}/wallpaper-1.webp"
                # 创建目标目录（如果不存在）
                mkdir -p "$target_dir"
                # 复制文件并覆盖
                if cp -f "$local_path" "$target_file"; then
                    # 设置权限
                    chmod 644 "$target_file"
                    echo -e "${GRAD_8}✓ 已成功将图片应用到默认壁纸: ${target_file}${NC}"
                else
                    echo -e "${GRAD_17}✗ 应用到默认壁纸失败，请检查文件权限${NC}"
                fi
                ;;
            [Nn])
                echo -e "${GRAD_4}⚠️ 已取消应用到默认壁纸${NC}"
                ;;
            *)
                echo -e "${GRAD_4}⚠️ 无效输入，已取消应用到默认壁纸${NC}"
                ;;
        esac
    fi
}

# 修改设备信息logo
# 参数: 模式(1-使用本地路径, 2-使用URL)
modify_device_logo() {
    local mode="$1"
    local value=""
    local local_filename="fnlogo.png"
    local local_path="${BASE_DIR}/${RESOURCE_DIR}/${local_filename}"
    local local_relative_path="${RESOURCE_DIR}/${local_filename}"
    
    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local path="$2"
        
        # 检查资源目录
        check_resource_dir
               
        local temp_file=$(mktemp)
        echo -e "${GRAD_12}正在下载 $local_filename...${NC}"
        
        if curl -s -f -o "$temp_file" "$url"; then
            if mv -f "$temp_file" "$path"; then
                chmod 644 "$path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }
    
    case "$mode" in
        1) 
            value="$local_relative_path"
            # 检查本地文件是否存在
            if [ ! -f "$local_path" ]; then
                echo -e "${GRAD_4}⚠️ 本地文件不存在: $local_path${NC}"
                return 0
            fi
            ;;
        2) 
            while true; do
                local url=$(prompt_input "请输入设备logo图片URL")
                if [ -z "$url" ]; then
                    echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$url"; then
                    # 下载图片
                    if download_image "$url" "$local_path"; then
                        value="$local_relative_path"
                    else
                        echo -e "${GRAD_4}⚠️ 下载失败，取消修改${NC}"
                        return 0
                    fi
                    break
                else
                    echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    show_header "修改设备信息logo图片"
    local largest_js=$(find_largest_file "$TARGET_DIR" "*.js")
    if [ -n "$largest_js" ] && [ -f "$largest_js" ]; then
        safe_replace "$largest_js" "$DEVICE_LOGO_MARKER" "$value"
    fi
}

# 修改飞牛网页标题
modify_web_title() {
    show_header "修改飞牛网页标题"
    echo -e "${GRAD_17}注意: 自定义标题最好不要有特殊字符, 空格、横线、下划线都可以, 其他请谨慎!!!${NC}"
    
    # 获取新标题
    local new_title=$(prompt_input "请输入新的网页标题")
    if [ -z "$new_title" ]; then
        echo -e "${GRAD_4}⚠️ 未输入标题，跳过修改${NC}"
        return
    fi
    
    # 转义特殊字符
    local escaped_title=$(printf '%q' "$new_title" | sed "s/'/'\\\\''/g")
    
    # 修改index.html中的<title>标签
if [ -f "$INDEX_FILE" ]; then
    # 确保中文变量正确处理，不添加多余转义
    if sed -i -e '/<\/head>/,/<body>/ {
        /<\/head>/!{ /<body>/!d; }
        # 使用 addEventListener 替代直接赋值 onload
        /<\/head>/a <script>window.addEventListener("load", function() {document.title = "'"${escaped_title}"'"});</script>
    }' "$INDEX_FILE"; then
        echo -e "${GRAD_8}✓ 已成功添加含中文标题的脚本，标题: ${NC}${escaped_title}"
        backup_modified_file "$INDEX_FILE"
    else
        echo -e "${GRAD_17}✗ 中文标题脚本添加失败${NC}"
    fi
else
    echo -e "${GRAD_17}✗ 未找到文件: ${INDEX_FILE}${NC}"
fi
    
    # 修改最大JS文件中的标题内容
    local largest_js=$(find_largest_file "$TARGET_DIR" "*.js")
    if [ -n "$largest_js" ] && [ -f "$largest_js" ]; then
        sed -i.bak 's|\(document\.title=`\)[^`]*|\1'"$escaped_title"'|' "$largest_js"
        echo -e "${GRAD_8}✓ 修改的JS文件: ${NC}$largest_js"
        echo -e "${GRAD_8}✓ 修改的文件: ${NC}$INDEX_FILE"
        # 备份修改后的文件
        backup_modified_file "$largest_js"
        rm -f "${largest_js}.bak"
    fi
}

# 设置透明度通用函数
set_transparency() {
    local dir="$1"
    local pattern="$2"
    local value="$3"
    
    show_header "设置透明度为 ${value}px"
    local largest_css=$(find_largest_file "$dir" "*.css")
    if [ -n "$largest_css" ] && [ -f "$largest_css" ]; then
        # 执行替换，匹配模式后的数值部分
sed -i -E "s/]\{--tw-backdrop-blur: blur\((0|[1-2]?[0-9]|30) *px\);/]\{--tw-backdrop-blur: blur(${value}px);/g" "$largest_css"
        sed -i -E "s/un-backdrop-blur:blur\((0|[1-2]?[0-9]|30) *px\);/un-backdrop-blur:blur(${value}px);/g" "$largest_css"
        
        echo -e "${GRAD_8}✓ 完成: 透明度已设置为 ${value}px${NC}"
        # 备份修改后的文件
        backup_modified_file "$largest_css"
    else
        echo -e "${GRAD_17}✗ 未找到任何CSS文件${NC}"
    fi
}

# 显示透明度选择菜单
show_transparency_menu() {
    local title="$1"
    show_header "$title"
    echo -e "请输入透明度值 (0-30，数值越大模糊效果越强)"
    echo -e "输入 'q' 可返回到上一级菜单"
    show_separator
}

# 处理飞牛登录框透明度设置
handle_flying_bee_transparency() {
    while true; do
        show_transparency_menu "飞牛登录框透明度设置"
        read -p "→ 请输入透明度值 (0-30) 或 'q' 返回: " input
        
        # 检查是否要返回上一级
        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            break
        fi
        
        # 验证输入是否为0-30之间的整数
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 0 ] && [ "$input" -le 30 ]; then
            set_transparency "$TARGET_DIR" "$FLYING_BEE_BLUR_PATTERN" "$input"
            break
        else
            echo -e "${GRAD_17}✗ 无效输入，请输入0-30之间的整数或输入'q'返回${NC}"
        fi
    done
}

# 处理影视登录框透明度设置
handle_movie_transparency() {
    while true; do
        show_transparency_menu "影视登录框透明度设置"
        read -p "→ 请输入透明度值 (0-30) 或 'q' 返回: " input
        
        # 检查是否要返回上一级
        if [ "$input" = "q" ] || [ "$input" = "Q" ]; then
            break
        fi
        
        # 验证输入是否为0-30之间的整数
        if [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 0 ] && [ "$input" -le 30 ]; then
            set_transparency "$MOVIE_DIR" "$MOVIE_BLUR_PATTERN" "$input"
            break
        else
            echo -e "${GRAD_17}✗ 无效输入，请输入0-30之间的整数或输入'q'返回${NC}"
        fi
    done
}

# 修改飞牛网页标签小图标
modify_flying_bee_favicon() {
    show_header "修改飞牛网页标签小图标"
    echo -e "${GRAD_4}⚠️ 图标格式不一定要ico，jpe，png都可以！${NC}"
    if [ -f "$FLYING_BEE_FAVICON" ]; then
        replace_favicon "$FLYING_BEE_FAVICON" "ico"
    else
        echo -e "${GRAD_4}⚠️ 飞牛网页图标文件不存在，将创建新文件: $FLYING_BEE_FAVICON${NC}"
        replace_favicon "$FLYING_BEE_FAVICON" "ico"
    fi
}

# 修改影视网页标签小图标
modify_movie_favicon() {
    show_header "修改影视网页标签小图标"
    echo -e "${GRAD_4}⚠️ 影视图标必须得标准的ico格式，否则不生效，飞牛的图标则没所谓！${NC}"
    if [ -f "$MOVIE_FAVICON" ]; then
        replace_favicon "$MOVIE_FAVICON" "ico"
    else
        echo -e "${GRAD_4}⚠️ 影视网页图标文件不存在，将创建新文件: $MOVIE_FAVICON${NC}"
        replace_favicon "$MOVIE_FAVICON" "ico"
    fi
}
# ==================== 预设主题函数区 ====================

# 应用高达00主题
apply_gundam_theme() {
    show_header "应用高达00主题"
    
    local login_logo="https://img.on79.cfd/file/1759752438383_login.png"
    local login_bg="https://img.on79.cfd/file/1759751427376_bg.png"
    local device_logo="https://img.on79.cfd/file/1759752817818_993788ea3f5acb3d42151f7b3a30e496.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 高达00主题应用完成${NC}"
}

# 应用初音未来主题
apply_miku_theme() {
    show_header "应用初音未来主题"
    
    local login_logo="https://img.on79.cfd/file/1759755919009_3a431f4408e2d8879beb3ae0a6d9473897be8ee1.jpg_.png"
    local login_bg="https://img.on79.cfd/file/1759755273357_dca742293ef3b268e5e1153d9a90abe63016.jpeg"
    local device_logo="https://img.on79.cfd/file/1759755278837_403748c03ada425a0008f8f9f43c7b4c.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 初音未来主题应用完成${NC}"
}

# 应用钢之炼金术师主题
apply_gzljss_theme() {
    show_header "应用钢之炼金术师主题"
    
    local login_logo="https://img.on79.cfd/file/1759757773908_0.png"
    local login_bg="https://img.on79.cfd/file/1759758745814_ca847658-796a-4e0f-83e1-1093613cfa96.webp"
    local device_logo="https://img.on79.cfd/file/1759758028574_1.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 钢之炼金术师主题应用完成${NC}"
}

# 应用海贼王主题
apply_haizeiwang_theme() {
    show_header "应用海贼王主题"
    
    local login_logo="https://img.on79.cfd/file/1759760428928_FvC0L7Rz4U6ImCiHAFOyQsHZu6Nw.png"
    local login_bg="https://img.on79.cfd/file/1759760423918_703ddc5a7ea9972e74769ee7a8543e9793b62592.webp"
    local device_logo="https://img.on79.cfd/file/1759760422420_87bc5de4ly1hrwn0xs3zej20u011in0b.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 海贼王主题应用完成${NC}"
}

# 应用JOJO的奇妙冒险主题
apply_jojo_theme() {
    show_header "应用JOJO的奇妙冒险主题"
    
    local login_logo="https://img.on79.cfd/file/1759815392132_jojo.png"
    local login_bg="https://img.on79.cfd/file/1759815397774_jojo.webp"
    local device_logo="https://img.on79.cfd/file/1759815392132_jojo.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ JOJO的奇妙冒险主题应用完成${NC}"
}

# 应用新世纪福音战士主题
apply_eva_theme() {
    show_header "应用新世纪福音战士主题"
    
    local login_logo="https://img.on79.cfd/file/1759817609585_b0d3-hxsrwwr3510582.png"
    local login_bg="https://picx.zhimg.com/v2-586fedc672445aa448a9b0a09168eb08_r.jpg"
    local device_logo="https://img.on79.cfd/file/1759817614477_a08b87d6277f9e2f678e991d1930e924b899f368.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 新世纪福音战士主题应用完成${NC}"
}
# 应用鬼灭之刃主题
apply_guimie_theme() {
    show_header "应用鬼灭之刃主题"
    
    local login_logo="https://img.on79.cfd/file/1759992697671_98c94b81f3ca7ac89f172c83897472ef5ef67989.png"
    local login_bg="https://img.on79.cfd/file/1759992283415_068e9b2f65baeb9eda58f789bbaa4b32.webp"
    local device_logo="https://img.on79.cfd/file/1759992276741_98c94b81f3ca7ac89f172c83897472ef5ef67989.png"
    
    apply_theme "$login_logo" "$login_bg" "$device_logo"
    echo -e "${GRAD_8}✓ 鬼灭之刃主题应用完成${NC}"
}

# 应用主题的通用函数
# 参数: login_logo_url, login_bg_url, device_logo_url
apply_theme() {
    local login_logo_url="$1"
    local login_bg_url="$2"
    local device_logo_url="$3"
    
    # 定义本地保存的文件名
    local login_logo_name="login_logo.png"
    local login_bg_name="login_bg.jpg"
    local device_logo_name="device_logo.png"
    
    # 本地资源完整路径
    local login_logo_path="${BASE_DIR}/${RESOURCE_DIR}/${login_logo_name}"
    local login_bg_path="${BASE_DIR}/${RESOURCE_DIR}/${login_bg_name}"
    local device_logo_path="${BASE_DIR}/${RESOURCE_DIR}/${device_logo_name}"
    
    # 本地引用路径（相对目标文件的路径）
    local login_logo_local="${RESOURCE_DIR}/${login_logo_name}"
    local login_bg_local="${RESOURCE_DIR}/${login_bg_name}"
    local device_logo_local="${RESOURCE_DIR}/${device_logo_name}"

    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local local_path="$2"
        local filename=$(basename "$local_path")
                
        # 临时文件存储
        local temp_file=$(mktemp)
        
        echo -e "${GRAD_12}正在下载 $filename...${NC}"
        if curl -s -f -o "$temp_file" "$url"; then
            # 移动到资源目录并设置权限
            if mv -f "$temp_file" "$local_path"; then
                chmod 644 "$local_path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $local_path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }

    # 下载所有主题图片到本地
    download_image "$login_logo_url" "$login_logo_path"
    download_image "$login_bg_url" "$login_bg_path"
    download_image "$device_logo_url" "$device_logo_path"

    # 修改登录logo（使用本地路径）
    local login_file=$(find_login_form_js)
    if [ -n "$login_file" ] && [ -f "$login_file" ]; then
        safe_replace "$login_file" "$LOGIN_LOGO_MARKER" "$login_logo_local"
    fi
    
    # 修改登录背景（使用本地路径）
    if [ -n "$login_file" ] && [ -f "$login_file" ]; then
        safe_replace "$login_file" "$LOGIN_BG_MARKER" "$login_bg_local"
    fi
    
    # 修改设备logo（使用本地路径）
    local largest_js=$(find_largest_file "$TARGET_DIR" "*.js")
    if [ -n "$largest_js" ] && [ -f "$largest_js" ]; then
        safe_replace "$largest_js" "$DEVICE_LOGO_MARKER" "$device_logo_local"
    fi
                local target_dir="/usr/trim/www/static/bg"
                local target_file="${target_dir}/wallpaper-1.webp"
                # 创建目标目录（如果不存在）
                mkdir -p "$target_dir"
                # 复制文件并覆盖
                if cp -f "$login_bg_path" "$target_file"; then
                    # 设置权限
                    chmod 644 "$target_file"
                    echo -e "${GRAD_8}✓ 已成功将图片应用到默认壁纸: ${target_file}${NC}"
                else
                    echo -e "${GRAD_17}✗ 应用到默认壁纸失败，请检查文件权限${NC}"
                fi
}
# ==================== 飞牛影视相关功能 ====================

# 修改飞牛影视标题
modify_movie_title() {
    show_header "修改飞牛影视标题"
    echo -e "${GRAD_17}注意: 自定义标题建议避免特殊字符，空格、横线、下划线可正常使用${NC}"
    
    # 获取新标题
    local new_title=$(prompt_input "请输入新的影视页面标题")
    if [ -z "$new_title" ]; then
        echo -e "${GRAD_4}⚠️ 未输入标题，跳过修改${NC}"
        return
    fi
    
    # 转义特殊字符
    local escaped_title=$(printf '%q' "$new_title" | sed "s/'/'\\\\''/g")
    
    # 修改影视页面index.html中的<title>标签
    if [ -f "$MOVIE_INDEX_FILE" ]; then
        if sed -i "s|<title>[^<]*</title>|<title>${escaped_title}</title>|g" "$MOVIE_INDEX_FILE"; then
            echo -e "${GRAD_8}✓ 影视页面标题已成功更新: ${NC}$new_title"
            echo -e "${GRAD_8}✓ 修改的文件: ${NC}$MOVIE_INDEX_FILE"
            # 备份修改后的文件
            backup_modified_file "$MOVIE_INDEX_FILE"
        else
            echo -e "${GRAD_17}✗ 标题修改失败，请检查文件权限${NC}"
        fi
    else
        echo -e "${GRAD_17}✗ 未找到影视页面文件: ${MOVIE_INDEX_FILE}${NC}"
    fi
}

# 修改飞牛影视LOGO
# 参数: 模式(1-使用本地路径, 2-使用URL)
modify_movie_logo() {
    local mode="$1"
    local value=""
    local local_filename="movie_logo.png"
    local local_path="${BASE_DIR}/${RESOURCE_DIR}/${local_filename}"
    local local_relative_path="/${RESOURCE_DIR}/${local_filename}"  # 保持原模式1的路径格式
    
    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local path="$2"     
        local temp_file=$(mktemp)
        echo -e "${GRAD_12}正在下载 $local_filename...${NC}"
        
        if curl -s -f -o "$temp_file" "$url"; then
            if mv -f "$temp_file" "$path"; then
                chmod 644 "$path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }
    
    case "$mode" in
        1) 
            value="$local_relative_path"
            # 检查本地文件是否存在
            if [ ! -f "$local_path" ]; then
                echo -e "${GRAD_4}⚠️ 本地文件不存在: $local_path${NC}"
                return 0
            fi
            ;;
        2) 
            while true; do
                local url=$(prompt_input "请输入飞牛影视LOGO图片URL")
                if [ -z "$url" ]; then
                    echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$url"; then
                    # 下载图片
                    if download_image "$url" "$local_path"; then
                        value="$local_relative_path"
                    else
                        echo -e "${GRAD_4}⚠️ 下载失败，取消修改${NC}"
                        return 0
                    fi
                    break
                else
                    echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    show_header "修改飞牛影视LOGO"
    local movie_file=$(find_largest_file "$MOVIE_DIR" "*.js")
    if [ -n "$movie_file" ] && [ -f "$movie_file" ]; then
        # 提取目标文件名
        local target_filename=$(
            sed -n '1p' "$movie_file" |
            grep -o '\["assets/[^"]*",.*"assets/[^"]*"\]' |
            sed 's/^\["//; s/"\]$//' |
            tr ',' '\n' |
            sed 's/^[[:space:]]*"//; s/"[[:space:]]*$//' |
            sed 's/^assets\///' |
            tail -n 6 | head -n 1
        )

        # 执行替换（使用本地路径）
        safe_replace "$movie_file" "$MOVIE_LOGO_MARKER1" "$value"
        safe_replace "$movie_file" "$MOVIE_LOGO_MARKER2" "$value"
        
        if [ -n "$target_filename" ] && [ -f "${MOVIE_DIR}/${target_filename}" ]; then
            safe_replace "${MOVIE_DIR}/${target_filename}" "$MOVIE_LOGO_MARKER3" "$value"
            safe_replace "${MOVIE_DIR}/${target_filename}" "$MOVIE_LOGO_MARKER4" "$value"
        fi
        
        echo -e "${GRAD_8}✓ 成功修改影视LOGO${NC}"
    else
        echo -e "${GRAD_17}✗ 未找到飞牛影视相关JS文件${NC}"
    fi
}

# 修改飞牛影视背景
# 参数: 模式(1-使用本地路径, 2-使用URL)
modify_movie_bg() {
    local mode="$1"
    local value=""
    local local_filename="movie_bg.jpg"
    local local_path="${BASE_DIR}/${RESOURCE_DIR}/${local_filename}"
    local local_relative_path="/${RESOURCE_DIR}/${local_filename}"  # 保持原模式1的路径格式
    
    # 下载图片到本地资源目录的函数
    download_image() {
        local url="$1"
        local path="$2"               
        local temp_file=$(mktemp)
        echo -e "${GRAD_12}正在下载 $local_filename...${NC}"
        
        if curl -s -f -o "$temp_file" "$url"; then
            if mv -f "$temp_file" "$path"; then
                chmod 644 "$path"
                echo -e "${GRAD_8}✓ 图片已保存到本地: $path${NC}"
                return 0
            else
                echo -e "${GRAD_17}✗ 无法移动文件到资源目录${NC}"
                rm -f "$temp_file"
                return 0
            fi
        else
            echo -e "${GRAD_17}✗ 下载失败，请检查URL有效性: $url${NC}"
            rm -f "$temp_file"
            return 0
        fi
    }
    
    case "$mode" in
        1) 
            value="$local_relative_path"
            # 检查本地文件是否存在
            if [ ! -f "$local_path" ]; then
                echo -e "${GRAD_4}⚠️ 本地文件不存在: $local_path${NC}"
                return 0
            fi
            ;;
        2) 
            while true; do
                local url=$(prompt_input "请输入飞牛影视背景图片URL")
                if [ -z "$url" ]; then
                    echo -e "${GRAD_4}⚠️ 未输入URL，跳过修改${NC}"
                    return
                elif validate_url "$url"; then
                    # 下载图片
                    if download_image "$url" "$local_path"; then
                        value="$local_relative_path"
                    else
                        echo -e "${GRAD_4}⚠️ 下载失败，取消修改${NC}"
                        return 0
                    fi
                    break
                else
                    echo -e "${GRAD_17}✗ 无效的URL格式，请重新输入${NC}"
                fi
            done
            ;;
    esac

    show_header "修改飞牛影视背景"
    
    local largest_js=$(find_largest_file "$MOVIE_DIR" "*.js")
    if [ -z "$largest_js" ] || [ ! -f "$largest_js" ]; then
        echo -e "${GRAD_17}✗ 未找到主JS文件${NC}"
        return 0
    fi
    
    # 提取目标JS文件名
    local js_filename=$(grep -oP 'path:"login",async lazy\(\)\{return\{Component:\(await Zn\(\(\)\=>import\("\./\K[^"]+' "$largest_js" | head -n1)
    
    if [ -z "$js_filename" ]; then
        echo -e "${GRAD_17}✗ 未找到匹配的JS文件名${NC}"
        return 0
    fi
    
    # 构建完整路径
    local target_js="${MOVIE_DIR}/${js_filename}"
    if [ ! -f "$target_js" ]; then
        echo -e "${GRAD_17}✗ 目标文件不存在: ${target_js}${NC}"
        return 0
    fi
    
    safe_replace "$target_js" "$MOVIE_BG_MARKER" "$value"
    echo -e "${GRAD_8}✓ 修改的文件: ${NC}$target_js"
}

# ==================== 菜单函数区 ====================

# 预设主题菜单
show_preset_menu() {
    show_header "选择主题菜单"
    echo -e "1. 高达00"
    echo -e "2. 初音未来"
    echo -e "3. 钢之炼金术师"
    echo -e "4. 海贼王"
    echo -e "5. JOJO的奇妙冒险"
    echo -e "6. 新世纪福音战士"
    echo -e "7. 鬼灭之刃"
    echo -e "0. 返回主菜单"
    show_separator
}

# 透明度菜单
show_touming_menu() {
    show_header "透明度菜单"
    echo -e "1. 修改飞牛登录框透明度"
    echo -e "2. 修改影视登录框透明度"
    echo -e "0. 返回主菜单"
    show_separator
}

# Favicon修改子菜单
show_favicon_submenu() {
    show_header "修改浏览器标签小图标"
    echo -e "1. 修改飞牛网页标签小图标"
    echo -e "2. 修改影视网页标签小图标"
    echo -e "0. 返回主菜单"
    show_separator
}

# 飞牛影视二级菜单
show_movie_submenu() {
    show_header "飞牛影视修改菜单"
    echo -e "1. 修改飞牛影视标题"
    echo -e "2. 修改飞牛影视LOGO"
    echo -e "3. 修改飞牛影视背景"
    echo -e "0. 返回主菜单"
    show_separator
}

# 影视修改子菜单（用于LOGO和背景的修改方式选择）
show_movie_file_submenu() {
    local title="$1"
    show_header "$title"
    echo -e "1. 默认：直接修改（使用${RESOURCE_DIR}路径）"
    echo -e "2. 自定义：输入完整URL路径"
    echo -e "0. 返回上一级"
    show_separator
}

# 子菜单
show_submenu() {
    local title="$1"
    show_header "$title"
    echo -e "1. 默认：直接修改（使用${RESOURCE_DIR}路径）"
    echo -e "2. 自定义：输入完整URL路径"
    echo -e "0. 返回主菜单"
    show_separator
}

# 持久化处理菜单
show_persistence_menu() {
    show_header "保存脚本设置/卸载清空脚本"
    echo -e "1. 是，重启后保持个性化设置（系统启动后30秒生效）"
    echo -e "2. 否，立即还原飞牛官方设置"
    echo -e "0. 返回主菜单\n"
    echo -e "${GRAD_4}注意！ 如果系统更新后或遇到任何问题，请选择2然后重启一次即可${NC}"
    show_separator
}

# 主菜单
show_separator() {
    echo -e "${GRAD_12}═════════════════════════════════════════════${NC}"
}

show_menu() {

    echo -e "\n${GRAD_12}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GRAD_12}║                                           ${GRAD_12}║${NC}"
    echo -e "${GRAD_12}║${GRAD_15}    ${BOLD}${BLINK}-- 肥牛定制化脚本v1.35 by 米恋泥 --${NO_EFFECT}    ${GRAD_12}║${NC}"
    echo -e "${GRAD_12}║                                           ${GRAD_12}║${NC}"
    echo -e "${GRAD_12}╚═══════════════════════════════════════════╝${NC}"
    
    # 主菜单选项 - 每个选项使用独特颜色
    echo -e "\n${BOLD}${GRAD_4}***${GRAD_11}公告:飞牛0.9.35版已经适配可用，在此感谢大家使用！${GRAD_4}***${NC}\n"
    echo -e "${BOLD}${GRAD_4}***${GRAD_11}欢迎有兴趣的朋友加入交流群：1039270739${GRAD_4}***${NC}\n"
    echo -e "${GRAD_3} 1. 选择预设主题（小白推荐）${NC}"
    echo -e "${GRAD_4} 2. 修改登录界面背景图片${NC}"
    echo -e "${GRAD_5} 3. 修改设备信息logo图片${NC}"
    echo -e "${GRAD_6} 4. 修改登录界面logo图片${NC}"
    echo -e "${GRAD_7} 5. 修改飞牛网页标题${NC}"
    echo -e "${GRAD_8} 6. 修改登录框透明度${NC}"
    echo -e "${GRAD_9} 7. 修改飞牛影视界面${NC}"
    echo -e "${GRAD_10} 8. 修改浏览器标签小图标（favicon.ico）${NC}"
    echo -e "${GRAD_11} 9. 添加飞牛主界面APP图标(重磅推荐)${NC}"
    echo -e "${GRAD_14} S. 保存脚本设置/卸载清空脚本${NC}"
    echo -e "${GRAD_16} R. 立即重启系统${NC}"
    echo -e "${GRAD_18} 0. 退出脚本(输入i查看作者声明)${NC}"
    show_separator
}

# ==================== 主执行流程 ====================

# 检查系统启动时间是否超过指定分钟数
check_system_uptime() {
    local required_minutes=$1
    echo "⏰ 检查系统启动时间是否超过 $required_minutes 分钟..."
    
    # 获取系统运行时间（以秒为单位）
    local uptime_seconds=$(awk '{print $1}' /proc/uptime | cut -d. -f1)
    local required_seconds=$((required_minutes * 60))
    
    if [ "$uptime_seconds" -lt "$required_seconds" ]; then
        local remaining_seconds=$((required_seconds - uptime_seconds))
        echo "⚠️  系统启动时间不足 $required_minutes 分钟，需要等待 $remaining_seconds 秒..."
        
        # 显示动态倒计时
        local countdown=$remaining_seconds
        while [ $countdown -gt 0 ]; do
            # 使用printf和回车符实现动态更新
            printf "\r⏳ 剩余等待时间: %d 秒" $countdown
            sleep 1
            countdown=$((countdown - 1))
        done
        printf "\n"
        
        echo "✅ 系统启动时间已满足要求，继续执行脚本。"
    else
        echo "✅ 系统启动时间已满足要求，继续执行脚本。"
    fi
}

main() {
    # 初始化检查
    check_root
    
    # 确保系统启动至少3分钟后才执行脚本
    check_system_uptime 3
    
# 定义绑定挂载的源路径和目标挂载点
SOURCE_DIR="/usr/trim/share/.restore/tow"
MOUNT_POINT="/usr/trim/www"
WWW_INDEX="$MOUNT_POINT/index.html"
RESTORE_INDEX="$SOURCE_DIR/index.html"

# 第一步：检测/usr/trim/www/index.html是否存在，等待1秒尝试5次
echo "🔍 检测 $WWW_INDEX 是否存在..."
MAX_ATTEMPTS=5
attempt=1
while [ $attempt -le $MAX_ATTEMPTS ]; do
    if [ -f "$WWW_INDEX" ]; then
        echo "✅ 检测成功：$WWW_INDEX 存在（第 $attempt 次尝试）"
        break
    else
        echo "⚠️ 第 $attempt 次检测失败：$WWW_INDEX 不存在，等待1秒后重试..."
        sleep 1
        attempt=$((attempt + 1))
    fi
done

# 如果5次检测都失败，则退出脚本
if [ $attempt -gt $MAX_ATTEMPTS ]; then
    echo "❌ 检测失败：在5次尝试后仍然无法找到 $WWW_INDEX"
    echo "❌ 脚本将退出，请确保文件存在后再尝试"
    exit 1
fi

# 第二步：检查/usr/trim/share/.restore/tow/index.html是否存在，如果不存在则复制文件
echo "🔍 检测 $RESTORE_INDEX 是否存在..."
if [ ! -f "$RESTORE_INDEX" ]; then
    echo "⚠️ $RESTORE_INDEX 不存在，开始复制 $MOUNT_POINT 中的所有文件..."
    
    # 确保目标目录存在
    mkdir -p "$SOURCE_DIR"
    
    # 复制所有文件
    echo "📂 正在将 $MOUNT_POINT/* 复制到 $SOURCE_DIR..."
    if cp -r "$MOUNT_POINT"/* "$SOURCE_DIR/"; then
        echo "✅ 文件复制成功！"
    else
        echo "❌ 文件复制失败，请检查权限或磁盘空间"
        exit 1
    fi
else
    echo "✅ $RESTORE_INDEX 已存在，跳过复制步骤"
fi

# 第三步：清理所有现有挂载（包括重复的绑定挂载）
echo "🔍 检查并清理 $MOUNT_POINT 的现有挂载..."
while findmnt "$MOUNT_POINT" >/dev/null 2>&1; do
    echo "正在卸载 $MOUNT_POINT..."
    if umount "$MOUNT_POINT"; then
        echo "✅ 常规卸载成功"
    else
        echo "⚠️ 常规卸载失败，尝试懒卸载..."
        if umount -l "$MOUNT_POINT"; then
            echo "✅ 懒卸载成功"
        else
            echo "❌ 卸载失败，请手动处理"
            exit 1
        fi
    fi
done

# 第四步：确认已完全卸载
if findmnt "$MOUNT_POINT" >/dev/null 2>&1; then
    echo "❌ 仍有残留挂载，无法继续"
    exit 1
fi

# 第五步：执行绑定挂载（仅一次）

echo "⏱️  等待5秒后开始挂载操作..."
# 在SOURCE_DIR中创建测试文件
echo "📄 在 $SOURCE_DIR 创建测试文件 123.txt"
touch "$SOURCE_DIR/123.txt"
sleep 5
echo "📦 开始绑定挂载 $SOURCE_DIR 到 $MOUNT_POINT..."
if mount -o bind "$SOURCE_DIR" "$MOUNT_POINT"; then
    echo "✅ 绑定挂载成功！当前状态："
    findmnt "$MOUNT_POINT"
    # 删除SOURCE_DIR中的测试文件
    echo "🗑️  删除 $SOURCE_DIR/123.txt 测试文件"
    rm -f "$SOURCE_DIR/123.txt"
    
else
    echo "❌ 绑定挂载失败，请检查源路径或权限"
    exit 1
fi
 ##################################################################################################   
    check_resource_dir
    init_backup_dir  # 初始化备份目录
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${GRAD_17}✗ 错误: 目标目录不存在 $TARGET_DIR${NC}" >&2
        exit 1
    fi
 clear  ##########################################################################################################################################
    while true; do     
        show_menu
        read -p "→ 请选择主菜单操作: " main_choice
        
        case "$main_choice" in
            4)  # 修改登录界面logo图片
                while true; do
                    show_submenu "修改登录界面logo图片"
                    read -p "→ 请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case "$sub_choice" in
                        1|2) modify_login_logo "$sub_choice"; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            2)  # 修改登录界面背景图片
                while true; do
                    show_submenu "修改登录界面背景图片"
                    read -p "→ 请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case "$sub_choice" in
                        1|2) modify_login_bg "$sub_choice"; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            3)  # 修改设备信息logo图片
                while true; do
                    show_submenu "修改设备信息logo图片"
                    read -p "→ 请选择修改方式 (0-2) [默认1]: " sub_choice
                    sub_choice=${sub_choice:-1}
                    
                    case "$sub_choice" in
                        1|2) modify_device_logo "$sub_choice"; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            6)  # 修改登录框透明度
                while true; do
                    show_touming_menu
                    read -p "→ 请选择操作 (0-2): " touming_choice
                    
                    case "$touming_choice" in
                        1) handle_flying_bee_transparency; break ;;
                        2) handle_movie_transparency; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            5)  # 修改飞牛网页标题
                modify_web_title
                ;;
            1)  # 选择预设主题
                while true; do
                    show_preset_menu
                    read -p "→ 请选择预设主题 (0-7): " preset_choice
                    
                    case "$preset_choice" in
                        1) apply_gundam_theme; break ;;
                        2) apply_miku_theme; break ;;
                        3) apply_gzljss_theme; break ;;
                        4) apply_haizeiwang_theme; break ;;
                        5) apply_jojo_theme; break ;;
                        6) apply_eva_theme; break ;;
                        7) apply_guimie_theme; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            7)  # 飞牛影视菜单
                while true; do
                    show_movie_submenu
                    read -p "→ 请选择飞牛影视修改操作 (0-3): " movie_choice
                    
                    case "$movie_choice" in
                        1)  # 修改飞牛影视标题
                            modify_movie_title
                            break 
                            ;;
                        2)  # 修改飞牛影视LOGO
                            while true; do
                                show_movie_file_submenu "修改飞牛影视LOGO"
                                read -p "→ 请选择修改方式 (0-2) [默认1]: " sub_choice
                                sub_choice=${sub_choice:-1}
                                
                                case "$sub_choice" in
                                    1|2) modify_movie_logo "$sub_choice"; break ;;
                                    0) break ;;
                                    *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                                esac
                            done
                            break 
                            ;;
                        3)  # 修改飞牛影视背景
                            while true; do
                                show_movie_file_submenu "修改飞牛影视背景"
                                read -p "→ 请选择修改方式 (0-2) [默认1]: " sub_choice
                                sub_choice=${sub_choice:-1}
                                
                                case "$sub_choice" in
                                    1|2) modify_movie_bg "$sub_choice"; break ;;
                                    0) break ;;
                                    *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                                esac
                            done
                            break 
                            ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            8)  # 修改浏览器标签小图标
                while true; do
                    show_favicon_submenu
                    read -p "→ 请选择操作 (0-1): " favicon_choice
                    
                    case "$favicon_choice" in
                        1) modify_flying_bee_favicon; break ;;
                        2) modify_movie_favicon; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            9)  # 自定义飞牛图标管理
                run_cqfnicon
                ;;
            R|r)  # 立即重启系统
                echo -e "${GRAD_4}\n▲ 重启都要我帮你啊？？？\n▲ 自己不会打“reboot”啊！${NC}\n"
                exit 0 ;;
            S|s) # 选择是否保存脚本设置菜单
                while true; do
                    show_persistence_menu
                    read -p "→ 选择是否保存脚本设置 (0-2): " persistence_choice
                    
                    case "$persistence_choice" in
                        1) todo_www_mount; break ;;
                        2) todo_www_umount; break ;;
                        0) break ;;
                        *) echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
                    esac
                done
                ;;
            0)  # 退出
                echo -e "\n${GRAD_4}▲ 脚本已退出，欢迎再次使用~·${NC}\n"
                exit 0 ;;
            I|i)  # 作者声明
                # echo -e "\n${GRAD_13} 作者声明：留着有空再写,拜拜！${NC}\n"
                # 使用 curl 获取并输出内容
curl -fL# ghfast.top/raw.githubusercontent.com/IMGZCQ/cqfnsh/main/README.txt -o - | sed -e '/使用方法/,$d' -e '/^$/d'
                exit 0 ;;
            *) 
                echo -e "${GRAD_17}✗ 无效选择，请重新输入${NC}" ;;
        esac
    done
}

# 启动主程序
main
