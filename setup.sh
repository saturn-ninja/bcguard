#!/bin/sh

# install-bcguard.sh - Скрипт установки bcguard
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
error() {
    echo -e "${RED}❌ Ошибка: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}⚠️  Предупреждение: $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Проверка прав root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error "Этот скрипт должен быть запущен с правами root"
        echo "Используйте: sudo $0"
        exit 1
    fi
}

# Определение дистрибутива
detect_distro() {
    if [ -f /etc/openwrt_release ]; then
        echo "openwrt"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    elif [ -f /etc/alpine-release ]; then
        echo "alpine"
    else
        echo "unknown"
    fi
}

# Проверка наличия команды
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Установка пакетов в OpenWRT
install_openwrt() {
    info "Обновление списка пакетов OpenWRT..."
    opkg update
    
    local packages=""
    
    # Проверяем и добавляем необходимые пакеты
    if ! command_exists gpg; then
        packages="$packages gnupg"
    fi
    
    if ! command_exists xxd; then
        # В OpenWRT xxd обычно входит в пакет vim-common
        if opkg list | grep -q "^vim-common"; then
            packages="$packages vim-common"
        elif opkg list | grep -q "^xxd"; then
            packages="$packages xxd"
        else
            # Если нет отдельного пакета, пробуем установить vim (содержит xxd)
            packages="$packages vim"
        fi
    fi
    
    if ! command_exists tar; then
        packages="$packages tar"
    fi
    
    if [ -n "$packages" ]; then
        info "Установка пакетов: $packages"
        opkg install $packages
    fi
}

# Установка пакетов в Debian/Ubuntu
install_debian() {
    info "Обновление списка пакетов Debian/Ubuntu..."
    apt update
    
    local packages=""
    
    if ! command_exists gpg; then
        packages="$packages gnupg"
    fi
    
    if ! command_exists xxd; then
        packages="$packages xxd"
    fi
    
    if ! command_exists tar; then
        packages="$packages tar"
    fi
    
    if [ -n "$packages" ]; then
        info "Установка пакетов: $packages"
        apt install -y $packages
    fi
}

# Установка пакетов в RedHat/CentOS
install_redhat() {
    info "Обновление списка пакетов RedHat/CentOS..."
    yum update -y
    
    local packages=""
    
    if ! command_exists gpg; then
        packages="$packages gnupg"
    fi
    
    if ! command_exists xxd; then
        # В RHEL/CentOS xxd находится в vim-common
        packages="$packages vim-common"
    fi
    
    if ! command_exists tar; then
        packages="$packages tar"
    fi
    
    if [ -n "$packages" ]; then
        info "Установка пакетов: $packages"
        yum install -y $packages
    fi
}

# Установка пакетов в Alpine
install_alpine() {
    info "Обновление списка пакетов Alpine..."
    apk update
    
    local packages=""
    
    if ! command_exists gpg; then
        packages="$packages gnupg"
    fi
    
    if ! command_exists xxd; then
        # В Alpine xxd находится в vim
        packages="$packages vim"
    fi
    
    if ! command_exists tar; then
        packages="$packages tar"
    fi
    
    if [ -n "$packages" ]; then
        info "Установка пакетов: $packages"
        apk add $packages
    fi
}

# Установка зависимостей
install_dependencies() {
    info "Проверка и установка зависимостей..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        openwrt)
            install_openwrt
            ;;
        debian)
            install_debian
            ;;
        redhat)
            install_redhat
            ;;
        alpine)
            install_alpine
            ;;
        *)
            warning "Неизвестный дистрибутив. Попытка определить зависимости вручную..."
            install_unknown
            ;;
    esac
}

# Установка для неизвестного дистрибутива
install_unknown() {
    info "Проверка основных зависимостей..."
    
    local missing=""
    
    for cmd in gpg xxd tar; do
        if ! command_exists "$cmd"; then
            missing="$missing $cmd"
        fi
    done
    
    if [ -n "$missing" ]; then
        error "Не удалось автоматически установить зависимости: $missing"
        echo "Пожалуйста, установите следующие пакеты вручную:"
        echo "  - gnupg (для gpg)"
        echo "  xxd (обычно входит в vim-common или vim)"
        echo "  tar"
        exit 1
    fi
}

# Установка bcguard
install_bcguard() {
    info "Установка bcguard..."
    
    # Определяем путь для установки
    local install_path="/usr/local/bin/bcguard"
    
    # Если /usr/local/bin недоступен, используем /usr/bin
    if [ ! -d "/usr/local/bin" ]; then
        install_path="/usr/bin/bcguard"
    fi
    
    # Копируем скрипт
    if [ -f "./bcguard" ]; then
        cp ./bcguard "$install_path"
        chmod +x "$install_path"
        success "bcguard установлен в $install_path"
    else
        error "Файл bcguard не найден в текущей директории"
        echo "Убедитесь, что скрипт установки находится в той же директории, что и bcguard"
        exit 1
    fi
    
    # Проверяем, что bcguard доступен из PATH
    if command_exists bcguard; then
        success "bcguard успешно установлен и доступен из командной строки"
    else
        warning "bcguard установлен, но может быть недоступен из PATH"
        echo "Добавьте /usr/local/bin в PATH или используйте полный путь: $install_path"
    fi
}

# Создание конфигурационного файла
setup_config() {
    info "Настройка конфигурации..."
    
    if [ ! -f ~/.bcguard ]; then
        info "Создание начального конфигурационного файла..."
        echo "# Конфигурационный файл bcguard" > ~/.bcguard
        echo "# Раскомментируйте и настройте следующие параметры:" >> ~/.bcguard
        echo "# mapping=ВАШ_MAPPING_КОД" >> ~/.bcguard
        echo "# recipient=ВАШ_GPG_ПОЛУЧАТЕЛЬ" >> ~/.bcguard
        success "Создан конфигурационный файл: ~/.bcguard"
        
        echo ""
        info "Рекомендуется сгенерировать mapping командой:"
        echo "  bcguard --generate-mapping"
    else
        info "Конфигурационный файл ~/.bcguard уже существует"
    fi
}

# Проверка установки
verify_installation() {
    info "Проверка установки..."
    
    local errors=0
    
    # Проверяем зависимости
    for cmd in gpg xxd tar; do
        if ! command_exists "$cmd"; then
            error "Команда $cmd не найдена"
            errors=$((errors + 1))
        fi
    done
    
    # Проверяем bcguard
    if ! command_exists bcguard; then
        error "bcguard не найден в PATH"
        errors=$((errors + 1))
    fi
    
    if [ $errors -eq 0 ]; then
        success "Все проверки пройдены успешно!"
        echo ""
        info "🎉 Установка завершена!"
        echo ""
        echo "Использование:"
        echo "  bcguard --help                    # Показать справку"
        echo "  bcguard --generate-mapping        # Сгенерировать новый mapping"
        echo "  bcguard -c file.txt               # Зашифровать файл"
        echo "  bcguard -d file.txt.bcg           # Расшифровать файл"
        echo ""
        info "Не забудьте сгенерировать mapping: bcguard --generate-mapping"
    else
        error "Обнаружены проблемы при установке"
        exit 1
    fi
}

# Основная функция
main() {
    echo "🛠️  Установка bcguard"
    echo "===================="
    echo ""
    
    check_root
    install_dependencies
    install_bcguard
    setup_config
    verify_installation
}

# Запуск основной функции
main "$@"
