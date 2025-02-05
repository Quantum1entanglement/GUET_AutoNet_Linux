#!/bin/bash

# 你的学号
YourID="123456789"           # 学号

# 执行 ping 命令检测网络连接
pingResult=$(ping -c 3 223.5.5.5)

# 输出 ping 命令的结果
echo "$pingResult"

# 检查是否有 100% 丢包
if echo "$pingResult" | grep -q "100\.[0-9]*% packet loss\|100% packet loss"; then
    echo ""
    echo "Not logged in, logout failed"
    exit 1
fi

# 获取无线网卡的 MAC 地址
#wlan_user_mac=

# 获取无线网卡的 IP 地址
wlan_user_ip=$(hostname -I | cut -f 1 -d ' ')

# 调试输出 MAC 地址和 IP 地址
echo ""
echo "MAC Address: $wlan_user_mac"
echo "IP Address: $wlan_user_ip"

echo ""
echo "Logging out..."

# 构造注销请求的 URL
logout_url="http://10.0.1.5:801/eportal/portal/mac/unbind?callback=dr1003&user_account=&wlan_user_mac=${wlan_user_mac}&wlan_user_ip=${wlan_user_ip}&jsVersion=4.2&v=9673&lang=zh"

# 输出注销 URL 以供调试
echo ""
echo "Logout URL: $logout_url"

# 向注销 URL 发送请求
curl_response_logout=$(curl -s -A "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36" \
    -H "Accept: */*" \
    -H "Accept-Language: zh-CN,zh;q=0.9" \
    -H "Cache-Control: no-cache" \
    -H "Connection: keep-alive" \
    -H "DNT: 1" \
    -H "Pragma: no-cache" \
    -H "Referer: http://10.0.1.5/" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" \
    --insecure "$logout_url" -o /dev/null -w "%{http_code}")

# 检查注销请求的响应状态码
if [ "$curl_response_logout" -eq 200 ]; then
    echo ""
    echo "Logout request successful."
    sleep 5
    echo ""
    pingResult=$(ping -c 4 -W 3 223.5.5.5)
    echo "$pingResult"
else
    echo ""
    echo "Logout request failed with status code: $curl_response_logout"
fi
