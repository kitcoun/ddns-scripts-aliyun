#!/bin/bash

accessKey_id="<YOUR-ACCESSKEY-ID>"
accessKey_secret="<YOUR-ACCESSKEY-SECRET>"
algorithm="ACS3-HMAC-SHA256"

# 请求参数 --这部分内容需要根据实际情况修改
httpMethod="POST"
host="dns.aliyuncs.com"
queryParam=("DomainName=example.com" "RRKeyWord=@")
action="DescribeDomainRecords"
version="2015-01-09"
canonicalURI="/"
# body类型参数或者formdata类型参数通过body传参
# body类型参数：body的值为json字符串： "{'key1':'value1','key2':'value2'}"，且需在签名header中添加content-type:application/json; charset=utf-8
# body类型参数是二进制文件时：body无需修改，只需在签名header中添加content-type:application/octet-stream，并在curl_command中添加--data-binary参数
# formdata类型参数：body参数格式："key1=value1&key2=value2"，且需在签名header中添加content-type:application/x-www-form-urlencoded
body=""

# 按照ISO 8601标准表示的UTC时间
utc_timestamp=$(date +%s)
utc_date=$(date -u -d @${utc_timestamp} +"%Y-%m-%dT%H:%M:%SZ") 
# x-acs-signature-nonce 随机数
random=$(uuidgen | sed 's/-//g') 

# 签名header
headers="host:${host}
x-acs-action:${action}
x-acs-version:${version}
x-acs-date:${utc_date}
x-acs-signature-nonce:${random}"

# URL编码函数
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02X' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

# 步骤 1：拼接规范请求串
# 将queryParam中的参数全部平铺
newQueryParam=()

# 遍历每一个原始参数
for param in "${queryParam[@]}"; do
    # 检查是否包含等号，以确定是键值对
    if [[ "$param" == *"="* ]]; then
        # 分割键和值
        IFS='=' read -r key value <<< "$param"

        # 对值进行URL编码
        value=$(urlencode "$value")

        # 检查值是否为一个列表（通过查找括号）
        if [[ "$value" =~ ^\(.+\)$ ]]; then
            # 去掉两边的括号
            value="${value:1:-1}"

            # 使用IFS分割值列表
            IFS=' ' read -ra values <<< "$value"

            # 对于每个值添加索引
            index=1
            for val in "${values[@]}"; do
                # 去除双引号
                val="${val%\"}"
                val="${val#\"}"

                # 添加到新数组
                newQueryParam+=("$key.$index=$val")
                ((index++))
            done
        else
            # 如果不是列表，则直接添加
            newQueryParam+=("$key=$value")
        fi
    else
        # 如果没有等号，直接保留原样
        newQueryParam+=("$param")
    fi
done

# 处理并排序新的查询参数
sortedParams=()
declare -A paramsMap
for param in "${newQueryParam[@]}"; do
    IFS='=' read -r key value <<< "$param"
    paramsMap["$key"]="$value"
done
# 根据键排序
for key in $(echo ${!paramsMap[@]} | tr ' ' '\n' | LC_ALL=C sort); do
    sortedParams+=("$key=${paramsMap[$key]}")
done

# 1.1 拼接规范化查询字符串
canonicalQueryString=""
first=true
for item in "${sortedParams[@]}"; do
    [ "$first" = true ] && first=false || canonicalQueryString+="&"
    # 检查是否存在等号
    if [[ "$item" == *=* ]]; then
        canonicalQueryString+="$item"
    else
        canonicalQueryString+="$item="
    fi
done

# 1.2 处理请求体
hashedRequestPayload=$(echo -n "$body" | openssl dgst -sha256 | awk '{print $2}')
headers="${headers}
x-acs-content-sha256:$hashedRequestPayload"

# 1.3 构造规范化请求头
canonicalHeaders=$(echo "$headers" | grep -E '^(host|content-type|x-acs-)' | while read line; do
    key=$(echo "$line" | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')
    value=$(echo "$line" | cut -d':' -f2-)
    echo "${key}:${value}"
done | sort | tr '\n' '\n')

signedHeaders=$(echo "$headers" | grep -E '^(host|content-type|x-acs-)' | while read line; do
    key=$(echo "$line" | cut -d':' -f1 | tr '[:upper:]' '[:lower:]')
    echo "$key"
done | sort | tr '\n' ';' | sed 's/;$//')

# 1.4 构造规范请求
canonicalRequest="${httpMethod}\n${canonicalURI}\n${canonicalQueryString}\n${canonicalHeaders}\n\n${signedHeaders}\n${hashedRequestPayload}"
echo -e "canonicalRequest=${canonicalRequest}"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"

str=$(echo "$canonicalRequest" | sed 's/%/%%/g')
hashedCanonicalRequest=$(printf "${str}" | openssl sha256 -hex | awk '{print $2}')
# 步骤 2：构造签名字符串
stringToSign="${algorithm}\n${hashedCanonicalRequest}"
echo -e "stringToSign=$stringToSign"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"

# 步骤 3：计算签名
signature=$(printf "${stringToSign}" | openssl dgst -sha256 -hmac "${accessKey_secret}" | sed 's/^.* //')
echo -e "signature=${signature}"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"

# 步骤 4：构造Authorization
authorization="${algorithm} Credential=${accessKey_id},SignedHeaders=${signedHeaders},Signature=${signature}"
echo -e "authorization=${authorization}"

# 构造 curl 命令
url="https://$host$canonicalURI"
curl_command="curl -X $httpMethod '$url?$canonicalQueryString'"

# 添加请求头
IFS=$'\n'  # 设置换行符为新的IFS
for header in $headers; do
    curl_command="$curl_command -H '$header'"
done
curl_command+=" -H 'Authorization:$authorization'"
# body类型参数是二进制文件时，需要注释掉下面这行代码
curl_command+=" -d '$body'"
# body类型参数是二进制文件时，需要放开下面这行代码的注释
#curl_command+=" --data-binary @"/root/001.png" "

echo "$curl_command"
# 执行 curl 命令
eval "$curl_command"