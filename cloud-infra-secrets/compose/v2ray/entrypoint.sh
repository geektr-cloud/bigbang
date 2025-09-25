#!/bin/sh

set -e

if [ -z "${SERVER_ADDR}" ]; then
  echo "SERVER_ADDR is not set"
  exit 1
fi

if [ -z "${SERVER_PORT}" ]; then
  echo "SERVER_PORT is not set"
  exit 1
fi

if [ -z "${SERVER_UUID}" ]; then
  echo "SERVER_UUID is not set"
  exit 1
fi

cp /etc/v2ray/config.json.tmpl /etc/v2ray/config.json

sed -i "s|__SERVER_ADDR__|${SERVER_ADDR}|g" /etc/v2ray/config.json
sed -i "s|__SERVER_PORT__|${SERVER_PORT}|g" /etc/v2ray/config.json
sed -i "s|__SERVER_UUID__|${SERVER_UUID}|g" /etc/v2ray/config.json

exec /usr/bin/v2ray run -c /etc/v2ray/config.json
