#!/bin/bash
echo -e "\n🌟 Получение Wildcard SSL через DNS API 🌟\n"

read -p "🌐 Введите ваш домен (без www и *, например, yandex.ru): " DOMAIN
read -p "📧 Введите ваш Email (для Let's Encrypt): " EMAIL

echo -e "\n🏢 Выберите вашего DNS-провайдера:"
echo "1) Reg.ru"
echo "2) Timeweb Cloud"
echo "3) Yandex (ПДД)"
echo "4) Beget"
echo "5) Selectel"
echo "6) DNS Exit"
echo "7) Cloudflare"
read -p "👉 Ваш выбор (1-7): " PROVIDER_CHOICE

case $PROVIDER_CHOICE in
    1)
        DNS_PLUGIN="dns_regru"
        read -p "👤 Логин Reg.ru: " REGRU_USERNAME
        read -s -p "🔑 Пароль Reg.ru (ввод скрыт): " REGRU_PASSWORD
        echo "
        export REGRU_API_Username="$REGRU_USERNAME"
        export REGRU_API_Password="$REGRU_PASSWORD"
        ;;
    2)
        DNS_PLUGIN="dns_timeweb"
        read -p "🔑 Timeweb API Token (TW_Token): " TW_Token
        export TW_Token="$TW_Token"
        ;;
    3)
        DNS_PLUGIN="dns_yandex"
        read -p "🔑 Yandex PDD Token (YANDEX_Token): " YANDEX_Token
        export YANDEX_Token="$YANDEX_Token"
        ;;
    4)
        DNS_PLUGIN="dns_beget"
        read -p "👤 Логин Beget: " BEGET_LOGIN
        read -s -p "🔑 Пароль Beget (ввод скрыт): " BEGET_PASSWORD
        echo ""
        export BEGET_LOGIN="$BEGET_LOGIN"
        export BEGET_PASSWORD="$BEGET_PASSWORD"
        ;;
    5)
        DNS_PLUGIN="dns_selectel"
        read -s -p "🔑 Selectel API Key (SL_Key): " SL_Key
        echo ""
        export SL_Key="$SL_Key"
        ;;
    6)
        DNS_PLUGIN="dns_dnsexit"
        read -s -p "🔑 DNS Exit API Key (DNSexit_Key): " DNSexit_Key
        echo ""
        export DNSexit_Key="$DNSexit_Key"
        ;;
    7)
        DNS_PLUGIN="dns_cf"
        read -p "🔑 Cloudflare Token (CF_Token): " CF_Token
        read -p "🆔 Cloudflare Account ID: " CF_Account_ID
        export CF_Token="$CF_Token"
        export CF_Account_ID="$CF_Account_ID"
        ;;
    *)
        echo "❌ Неверный выбор! Перезапустите скрипт."
        exit 1
        ;;
esac

echo -e "\n📦 Шаг 1: Установка acme.sh..."
cd ~

curl -s https://get.acme.sh | sh -s email="$EMAIL" --nocron >/dev/null 2>&1

if [ ! -f "$HOME/.acme.sh/acme.sh" ]; then
    echo "❌ КРИТИЧЕСКАЯ ОШИБКА: Утилита acme.sh не установилась!"
    echo "Возможно, ваш NAS не может скачать файлы с GitHub (проверьте интернет или DNS)."
    exit 1
fi

source ~/.acme.sh/acme.sh.env

echo -e "\n🛑 Шаг 2: Запрашиваем Wildcard-сертификат (*.$DOMAIN и $DOMAIN) через $DNS_PLUGIN..."
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue --dns "$DNS_PLUGIN" -d "$DOMAIN" -d "*.$DOMAIN" --force
ISSUE_STATUS=$?

if [ $ISSUE_STATUS -eq 0 ]; then
    echo -e "\n✅ Шаг 3: Сертификат получен! Внедряем в систему..."
    
    export SYNO_Create=1
    export SYNO_USE_TEMP_ADMIN=1
    
    ~/.acme.sh/acme.sh --deploy -d "$DOMAIN" -d "*.$DOMAIN" --deploy-hook synology_dsm
    
    if [ $? -eq 0 ]; then
        echo -e "\n🎉 ГОТОВО! Wildcard сертификат успешно установлен в DSM. Проверяй NAS!"
    else
        echo -e "\n❌ ОШИБКА: Сертификат выпущен, но не импортирован в систему."
    fi
else
    echo -e "\n❌ ОШИБКА: Не удалось получить сертификат по DNS."
fi
