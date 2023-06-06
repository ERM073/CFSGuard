#!/bin/bash

echo "[成功] ドメインとサーバーは、CFSGuardによってDDoS保護されています。"
echo "[注意] このスクリプトを閉じると、DDoS保護が停止されます。"

# UAMをオンにするためのCloudFlare グローバルAPIキーとゾーンID
api_key="YOUR_API_KEY"
zone_id="YOUR_ZONE_ID"

# スクリプトの要件を満たしてるか確認する
for command in tcpdump jq curl
do
    if [[ ! $(type $command 2> /dev/null) ]]; then
        echo "エラー: ${command} コマンドが見つかりません。(sudo apt install ${command} を実行してください)"
        exit
    fi
done

if [[ -z $api_key || -z $zone_id ]]; then
    echo "スクリプトのAPI_KEYとZONE_IDを書き換える必要があります。"
    exit
fi

api_url="https://api.cloudflare.com/client/v4/zones/$zone_id/settings/security_level"

# セキュリティレベル設定の取得
current_security_level=$(curl -X GET "$api_url" \
    -H "Authorization: Bearer $api_key" \
    -H "Content-Type: application/json" \
    --silent \
    | jq -r '.result.value')

#1秒間辺りのアクセス数(デフォルト50トラフィック)
threshold=50

#何秒以上トラフィックが続く場合にUAMをオンにするか(デフォルト10秒以上)
duration_threshold=10

#UAMモードをオフにする際のセキュリティレベル(デフォルトhigh)
default_security_level="high"


while true; do
    counter=0

    while true; do
        # 1秒ごとにトラフィック量を取得
        traffic=$(tcpdump -i eth0 -c 100 -n 2>/dev/null | wc -l)

        if [ "$traffic" -gt "$threshold" ]; then
            # トラフィックが閾値を超えた場合、カウンタをインクリメント
            counter=$((counter + 1))
        else
            # トラフィックが閾値を下回った場合、カウンタをリセット
            counter=0
        fi

        if [ "$counter" -ge "$duration_threshold" ]; then
            if [ "$current_security_level" != "under_attack" ]; then
                # UAMモードをオンにするAPIリクエストを送信
                result=$(curl -X PATCH "$api_url" \
                    -H "Authorization: Bearer $api_key" \
                    -H "Content-Type: application/json" \
                    --data '{"value": "under_attack"}' \
                    --silent \
                    | jq -r '.success')

                if [ "$result" = "true" ]; then
                # UAMモードがオンになった時のメッセージ
                start_time=$(date +"%Y-%m-%d %H:%M:%S")
                echo "[+] UAMモードがオンになりました。 ($start_time)"

                    # UAMモードのセキュリティレベルを更新
                    current_security_level="under_attack"
                fi
            fi

            break
        fi

        sleep 1
    done

    # UAMを指定した秒数後に停止する (攻撃が続いている場合は、再度UAMモードが直ぐに有効になります)
    sleep 600 #秒

    if [ "$current_security_level" = "under_attack" ]; then
        # UAMモードがオンの場合、UAMモードをオフにするAPIリクエストを送信
        result=$(curl -X PATCH "$api_url" \
            -H "Authorization: Bearer $api_key" \
            -H "Content-Type: application/json" \
            --data "{\"value\": \"$default_security_level\"}" \
            --silent \
            | jq -r '.success')

        if [ "$result" = "true" ]; then
        # UAMモードがオフになった時のメッセージ
        end_time=$(date +"%Y-%m-%d %H:%M:%S")
        echo "[-] UAMモードがオフになりました。 ($end_time)"

            # UAMモードのセキュリティレベルを更新
            current_security_level="$default_security_level"
        fi
    fi
done
