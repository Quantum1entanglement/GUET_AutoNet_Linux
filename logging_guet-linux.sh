#!/bin/bash

# 修改以下内容
YourID="123456789"           # 学号
Password="abcdefg"           # 密码
YourISP=""                   # ISP
# 校园网请留空
# 中国移动 cmcc
# 中国联通 unicom
# 中国电信 telecom
JumpIP="1.2.3.4"                 # 非认证服务器地址

# 将密码转换为 Base64 编码，并去除填充字符 '='
base64_Password=$(echo -n "$Password" | base64 | tr -d '=')

# 执行 ping 命令检测网络连接
pingResult=$(ping -c 3 223.5.5.5)

# 输出 ping 命令的结果
echo "$pingResult"

# 检查是否有 100% 丢包
if echo "$pingResult" | grep -q "100\.[0-9]*% packet loss\|100% packet loss"; then
    echo ""
    echo "Fail Ping! Try Auto Connecting..."

    # 使用 curl 发起 HTTP 请求到 JumpIP 并获取最终的重定向 URL
    url_redirect=$(curl -s -L -w '%{url_effective}' "http://$JumpIP/" \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'Accept-Language: zh-CN,zh;q=0.9' \
        -H 'Cache-Control: no-cache' \
        -H 'Connection: keep-alive' \
        -H 'DNT: 1' \
        -H 'Pragma: no-cache' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36' -o /dev/null)

    # 输出重定向后的 URL 以供调试
    #echo ""
    #echo "Redirect URL: $url_redirect"

    # 检查是否成功获取到重定向 URL
    if [ -z "$url_redirect" ]; then
        echo "Failed to retrieve redirect URL from JumpIP."
        exit 1
    fi

    # 提取 URL 中的查询参数
    query_string=$(echo "$url_redirect" | awk -F'?' '{print $2}')

    # 输出查询字符串以供调试
    echo "Query String: $query_string"

    # 解析查询参数
    params=""
    IFS='&' read -r -a pairs <<< "$query_string"
    for pair in "${pairs[@]}"; do
        key=$(echo "$pair" | cut -d '=' -f1)
        value=$(echo "$pair" | cut -d '=' -f2-)
        params="$params$key=$value, "
    done

    # 去除最后的逗号
    params=$(echo "$params" | sed 's/, $//')

    # 提取各个参数
    wlan_user_ip=$(echo "$params" | awk -F'wlanuserip=' '{print $2}' | cut -d ',' -f1)
    wlan_ac_name=$(echo "$params" | awk -F'wlanacname=' '{print $2}' | cut -d ',' -f1)
    wlan_ac_ip=$(echo "$params" | awk -F'wlanacip=' '{print $2}' | cut -d ',' -f1)
    wlan_user_mac_raw=$(echo "$params" | awk -F'wlanusermac=' '{print $2}' | cut -d ',' -f1)

    # 去除 MAC 地址中的连字符或冒号
    wlan_user_mac=$(echo "$wlan_user_mac_raw" | tr -d ':-')

    # 输出提取的参数以供调试
    echo ""
    echo "wlan_user_ip: $wlan_user_ip"
    echo "wlan_ac_name: $wlan_ac_name"
    echo "wlan_ac_ip: $wlan_ac_ip"
    echo "wlan_user_mac: $wlan_user_mac"

    # 检查是否成功提取所有必要参数
    if [ -z "$wlan_user_ip" ] || [ -z "$wlan_ac_name" ] || [ -z "$wlan_ac_ip" ] || [ -z "$wlan_user_mac" ]; then
        echo ""
        echo "Failed to extract all required parameters from URL."
        exit 1
    fi

    # 构造登录请求的 URL
    login_url="http://10.0.1.5:801/eportal/portal/login?callback=dr1003&login_method=1&user_account=%2C0%2C${YourID}%40${YourISP}&user_password=${base64_Password}%3D&wlan_user_ip=${wlan_user_ip}&wlan_user_ipv6=&wlan_user_mac=${wlan_user_mac}&wlan_ac_ip=${wlan_ac_ip}&wlan_ac_name=${wlan_ac_name}&jsVersion=4.2&terminal_type=1&lang=zh-cn&v=3713&lang=zh"
    
    # 输出登录 URL 以供调试
    echo ""
    echo "Login URL: $login_url"

    # 向 Drcom 发送登录请求
    curl_response=$(curl -s -A "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36" \
        -H "Accept: */*" \
        -H "Accept-Encoding: gzip, deflate" \
        -H "Accept-Language: zh-CN,zh;q=0.9" \
        -H "Referer: http://10.0.1.5/" \
        "$login_url" -o /dev/null -w "%{http_code}")

    # 检查登录请求的响应状态码
    if [ "$curl_response" -eq 200 ]; then
        echo ""
        echo "Login request successful."
        pingResult=$(ping -c 3 223.5.5.5)
        echo "$pingResult"
    else
        echo ""
        echo "Login request failed with status code: $curl_response"
    fi

else
    echo ""
    echo "You have Internet!"
fi
