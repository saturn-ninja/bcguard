#!/bin/sh

# uninstall-bcguard.sh - Скрипт удаления bcguard

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ Ошибка: $1${NC}" >&2
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Этот скрипт должен быть запущен с правами root"
        echo "Используйте: sudo $0"
        exit 1
    fi
}

remove_bcguard() {
    info "Удаление bcguard..."
    
    # Пытаемся удалить из разных возможных мест
    local removed=0
    for path in "/usr/local/bin/bcguard" "/usr/bin/bcguard"; do
        if [ -f "$path" ]; then
            rm -f "$path"
            info "Удален: $path"
            removed=1
        fi
    done
    
    if [ $removed -eq 0 ]; then
        warning "bcguard не найден в стандартных местах установки"
    fi
}

remove_config() {
    info "Удаление конфигурационных файлов..."
    
    if [ -f ~/.bcguard ]; then
        printf "Удалить конфигурационный файл ~/.bcguard? [y/N]: "
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            rm -f ~/.bcguard
            success "Конфигурационный файл удален"
        else
            info "Конфигурационный файл сохранен"
        fi
    fi
}

main() {
    echo "🗑️  Удаление bcguard"
    echo "=================="
    echo ""
    
    check_root
    remove_bcguard
    remove_config
    
    success "bcguard успешно удален"
    echo ""
    info "Примечание: Установленные зависимости (gnupg, xxd, tar) не были удалены"
    info "так как они могут использоваться другими программами."
}

main "$@"
