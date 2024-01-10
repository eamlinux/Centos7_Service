## 使用`Podman`安装`openldap`  
```sh
podman run \
--name openldap \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
-v /opt/podman/openldaps/data:/var/lib/ldap \
-v /opt/podman/openldaps/config:/etc/ldap/slapd.d \
-e LDAP_ORGANISATION="OpenVPN_Server" \
-e LDAP_DOMAIN=openvpn.server \
-e LDAP_ADMIN_PASSWORD=Password \
-e LDAP_TLS=false \
--privileged \
-p 127.0.0.1:1389:389 \
-d osixia/openldap:latest
```
## 进行搜索测试
```
podman exec -ti openldaps ldapsearch -x -H ldap://127.0.0.1:1389 -b "dc=openvpn,dc=server" -D "cn=admin,dc=openvpn,dc=server" -w Password
## docker exec $LDAP_CID ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -f /container/service/slapd/assets/test/new-user.ldif -H ldap://ldap.example.org -ZZ
## docker exec $LDAP_CID ldapadd -x -D "cn=admin,dc=example,dc=org" -w admin -f /container/service/slapd/assets/test/new-user.ldif -H ldap://ldap.example.org -ZZ
```
## 安装管理面板`phpldapadmin`https版
```
podman run \
--name phpldapadmin \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
--privileged \
-p 8080:443 \
-e PHPLDAPADMIN_LDAP_HOSTS="ldap://127.0.0.1:1389" \
-d osixia/phpldapadmin:latest
```
## 安装管理面板`phpldapadmin`http版
```
podman run \
--name phpldapadmin \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
--privileged \
-p 8080:80 \
-e PHPLDAPADMIN_HTTPS=false \
-e PHPLDAPADMIN_LDAP_HOSTS="ldap://127.0.0.1:1389" \
-d osixia/phpldapadmin:latest
```
## 或者安装管理面板LAM
```sh
podman run --rm \
-v "/opt/podman/lam:/config" \
--privileged \
ghcr.io/ldapaccountmanager/lam:8.6 \
bash -xc "cp -ar /var/lib/ldap-account-manager/config /config"
 
podman run \
--name lam \
--log-driver json-file \
--log-opt max-size=1m \
--log-opt max-file=1 \
--privileged \
-p 8080:80 \
-v /opt/podman/lam/config:/var/lib/ldap-account-manager/config \
-e LDAP_SERVER="ldap://127.0.0.1:1389" \
-e LDAP_DOMAIN="openvpn.server" \
-e LDAP_BASE_DN="dc=openvpn,dc=server" \
-e LDAP_USER="cn=admin,dc=openvpn,dc=server" \
-e LAM_PASSWORD=Password \
-e LAM_LANG=zh_CN \
-e DEBUG=false \
-d ghcr.io/ldapaccountmanager/lam:8.6
```
## caddy反代配置
```
{
  admin off
  log {
    output discard
  }
  auto_https off
  servers :80 {
    protocols h1 h2c
  }
}

:80 {
  reverse_proxy http://127.0.0.1:8081 {
    header_up Host {host}
    header_up X-Real-IP {remote}
  }
  handle_path /webui* {
    reverse_proxy http://127.0.0.1:8080 {
      header_up Host {host}
      header_up X-Real-IP {remote}
    }
  }
}
```
