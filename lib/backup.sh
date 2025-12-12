#!/bin/bash

# 备份管理功能

BACKUP_BASE_DIR="/opt/server-config-tool/backups"
BACKUP_INDEX="$BACKUP_BASE_DIR/backup_index.txt"

# 初始化备份系统
init_backup_system() {
    ensure_dir "$BACKUP_BASE_DIR"
    
    if [ ! -f "$BACKUP_INDEX" ]; then
        touch "$BACKUP_INDEX"
        log "INFO" "Created backup index file"
    fi
}

# 创建备份条目
create_backup_entry() {
    local original_file="$1"
    local backup_file="$2"
    local module="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp|$module|$original_file|$backup_file" >> "$BACKUP_INDEX"
}

# 备份配置文件
backup_config() {
    local file="$1"
    local module="$2"
    
    init_backup_system
    
    if [ ! -f "$file" ]; then
        warn "文件不存在: $file"
        return 1
    fi
    
    local filename=$(basename "$file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_BASE_DIR/${module}_${filename}_${timestamp}.bak"
    
    cp "$file" "$backup_file"
    
    if [ $? -eq 0 ]; then
        success "已备份: $file"
        info "  -> $backup_file"
        create_backup_entry "$file" "$backup_file" "$module"
        echo "$backup_file"
        return 0
    else
        error "备份失败: $file"
        return 1
    fi
}

# 列出所有备份
list_backups() {
    init_backup_system
    
    if [ ! -s "$BACKUP_INDEX" ]; then
        info "暂无备份记录"
        return 0
    fi
    
    separator
    echo -e "${GREEN}备份列表:${NC}"
    separator
    
    local count=1
    while IFS='|' read -r timestamp module original backup; do
        echo -e "${BLUE}[$count]${NC} $timestamp"
        echo "    模块: $module"
        echo "    原文件: $original"
        echo "    备份: $backup"
        echo ""
        ((count++))
    done < "$BACKUP_INDEX"
}

# 列出指定模块的备份
list_module_backups() {
    local module="$1"
    init_backup_system
    
    if [ ! -s "$BACKUP_INDEX" ]; then
        info "暂无备份记录"
        return 0
    fi
    
    local found=0
    while IFS='|' read -r timestamp mod original backup; do
        if [ "$mod" = "$module" ]; then
            if [ $found -eq 0 ]; then
                separator
                echo -e "${GREEN}$module 模块的备份:${NC}"
                separator
                found=1
            fi
            echo -e "${BLUE}●${NC} $timestamp"
            echo "  原文件: $original"
            echo "  备份: $backup"
            echo ""
        fi
    done < "$BACKUP_INDEX"
    
    if [ $found -eq 0 ]; then
        info "$module 模块暂无备份记录"
    fi
}

# 恢复备份
restore_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        error "备份文件不存在: $backup_file"
        return 1
    fi
    
    # 从索引中查找原始文件路径
    local original_file=""
    while IFS='|' read -r timestamp module original backup; do
        if [ "$backup" = "$backup_file" ]; then
            original_file="$original"
            break
        fi
    done < "$BACKUP_INDEX"
    
    if [ -z "$original_file" ]; then
        error "在索引中未找到备份记录"
        return 1
    fi
    
    # 在恢复前备份当前文件
    if [ -f "$original_file" ]; then
        local current_backup="${original_file}.before_restore.$(date +%Y%m%d_%H%M%S)"
        cp "$original_file" "$current_backup"
        info "已备份当前配置: $current_backup"
    fi
    
    # 恢复备份
    cp "$backup_file" "$original_file"
    
    if [ $? -eq 0 ]; then
        success "已恢复: $original_file"
        return 0
    else
        error "恢复失败"
        return 1
    fi
}

# 恢复指定模块的最新备份
restore_module_latest() {
    local module="$1"
    init_backup_system
    
    # 查找该模块的最新备份
    local latest_backup=""
    local latest_timestamp=""
    local original_file=""
    
    while IFS='|' read -r timestamp mod original backup; do
        if [ "$mod" = "$module" ]; then
            if [ -z "$latest_timestamp" ] || [[ "$timestamp" > "$latest_timestamp" ]]; then
                latest_timestamp="$timestamp"
                latest_backup="$backup"
                original_file="$original"
            fi
        fi
    done < "$BACKUP_INDEX"
    
    if [ -z "$latest_backup" ]; then
        error "未找到 $module 模块的备份"
        return 1
    fi
    
    info "找到最新备份: $latest_timestamp"
    info "备份文件: $latest_backup"
    info "将恢复到: $original_file"
    
    if confirm "确认恢复此备份?" "n"; then
        restore_backup "$latest_backup"
        return $?
    else
        info "已取消恢复操作"
        return 1
    fi
}

# 清理旧备份（保留最近N个）
cleanup_old_backups() {
    local keep_count="${1:-10}"
    init_backup_system
    
    local total_backups=$(wc -l < "$BACKUP_INDEX")
    
    if [ "$total_backups" -le "$keep_count" ]; then
        info "备份数量 ($total_backups) 未超过保留数量 ($keep_count)，无需清理"
        return 0
    fi
    
    local remove_count=$((total_backups - keep_count))
    
    info "将删除 $remove_count 个旧备份（保留最新 $keep_count 个）"
    
    if ! confirm "确认清理?" "n"; then
        info "已取消清理操作"
        return 1
    fi
    
    # 创建临时文件
    local temp_index=$(mktemp)
    
    # 获取要删除的备份
    head -n "$remove_count" "$BACKUP_INDEX" | while IFS='|' read -r timestamp module original backup; do
        if [ -f "$backup" ]; then
            rm -f "$backup"
            info "已删除: $backup"
        fi
    done
    
    # 更新索引（保留最新的记录）
    tail -n "$keep_count" "$BACKUP_INDEX" > "$temp_index"
    mv "$temp_index" "$BACKUP_INDEX"
    
    success "清理完成"
}

# 删除所有备份
remove_all_backups() {
    init_backup_system
    
    warn "警告: 这将删除所有备份文件！"
    
    if ! confirm "确认删除所有备份?" "n"; then
        info "已取消操作"
        return 1
    fi
    
    while IFS='|' read -r timestamp module original backup; do
        if [ -f "$backup" ]; then
            rm -f "$backup"
        fi
    done < "$BACKUP_INDEX"
    
    # 清空索引
    > "$BACKUP_INDEX"
    
    success "所有备份已删除"
}

# 显示备份统计信息
show_backup_stats() {
    init_backup_system
    
    separator
    echo -e "${GREEN}备份统计信息:${NC}"
    separator
    
    local total=$(wc -l < "$BACKUP_INDEX")
    echo "总备份数: $total"
    
    # 按模块统计
    echo -e "\n${BLUE}各模块备份数量:${NC}"
    awk -F'|' '{print $2}' "$BACKUP_INDEX" | sort | uniq -c | while read count module; do
        echo "  $module: $count"
    done
    
    # 计算总大小
    local total_size=0
    while IFS='|' read -r timestamp module original backup; do
        if [ -f "$backup" ]; then
            local size=$(stat -f%z "$backup" 2>/dev/null || stat -c%s "$backup" 2>/dev/null || echo 0)
            total_size=$((total_size + size))
        fi
    done < "$BACKUP_INDEX"
    
    local size_mb=$((total_size / 1024 / 1024))
    echo -e "\n总大小: ${size_mb} MB"
    separator
}
