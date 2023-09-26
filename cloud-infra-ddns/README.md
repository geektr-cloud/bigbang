# DDNS

ddns function for cloud infra

## Notice

alicloud fc_go_sdk not parse trigger url, so we need to get it in gui, this module will output url as "get_ddns_trigger_url_on".

Reference:

- https://help.aliyun.com/zh/fc/developer-reference/api-fc-open-2021-04-06-gettrigger
- https://github.com/aliyun/fc-go-sdk/blob/master/trigger.go#L163
- https://github.com/aliyun/terraform-provider-alicloud/blob/master/alicloud/data_source_alicloud_fc_triggers.go#L47

TODO: contribute to aliyun/fc-go-sdk and aliyun/terraform-provider-alicloud

## Service Usage

```bash
node sign.js "<subdomain>.<primary-domain>""
# ...
# Signature: xxxxxxxxxxxxx
# ...

curl https://<http-trigger-url>/<signature>/<primary-domain>/<subdomain>/[ip]
```
