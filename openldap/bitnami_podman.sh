mkdir -p /opt/podman/openldap
chown -R $user:$group
chmod -R 777 /opt/podman/openldap

podman run \
--name openldap \
-e LDAP_ADMIN_USERNAME=admin \
-e LDAP_ADMIN_PASSWORD=Password \
-e LDAP_USERS=user01,user02 \
-e LDAP_PASSWORDS=password1,password2 \
-e LDAP_ROOT=dc=openvpn,dc=server \
-e LDAP_ADMIN_DN=cn=admin,dc=openvpn,dc=server \
-v /opt/podman/openldap:/bitnami/openldap \
-p 1389:1389 \
-p 1636:1636 \
-d bitnami/openldap:latest

或者

podman run \
--name openldap \
-e LDAP_ADMIN_USERNAME="admin" \
-e LDAP_ADMIN_PASSWORD="Password" \
-e LDAP_ROOT="dc=openvpn,dc=server" \
-e LDAP_ADMIN_DN="cn=admin,dc=openvpn,dc=server" \
-v /opt/podman/openldap:/bitnami/openldap \
-p 1389:1389 \
-p 1636:1636 \
-d bitnami/openldap:latest

#### /opt/podman/openldap/memberof.ldif

dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
olcModulePath: /opt/bitnami/openldap/lib/openldap
olcModuleLoad: memberof.so
olcModuleLoad: refint.so

dn: olcOverlay=memberof,olcDatabase={2}mdb,cn=config
objectClass: olcMemberOf
objectClass: olcOverlayConfig
olcOverlay: memberof

dn: olcOverlay=refint,olcDatabase={2}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcRefintConfig
objectClass: top
olcOverlay: refint
olcRefintAttribute: memberof member manager owner

------------------------------------------------------
#### /opt/podman/openldap/ppolicy.ldif

dn: cn=module,cn=config
cn: module
objectClass: olcModuleList
olcModulePath: /opt/bitnami/openldap/lib/openldap
olcModuleLoad: ppolicy.so

dn: olcOverlay=ppolicy,olcDatabase={2}mdb,cn=config
objectClass: olcConfig
objectClass: olcOverlayConfig
objectClass: olcPPolicyConfig
objectClass: top
olcOverlay: ppolicy
olcPPolicyDefault: dc=openvpn,dc=server
# olcPPolicyDefault: cn=default,ou=policies,dc=example,dc=com

---------------------------------------------------------------------
podman exec -ti openldap ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /bitnami/openldap/memberof.ldif
podman exec -ti openldap ldapadd -Y EXTERNAL -Q -H ldapi:/// -f /bitnami/openldap/ppolicy.ldif

# /opt/openvpn/server/ldap.conf
<LDAP>
        URL             ldap://127.0.0.1:1389
        BindDN          ou=openvpn,dc=openvpn,dc=server
        Password        easy2005
        Timeout         15
        TLSEnable       no
        FollowReferrals yes

</LDAP>

<Authorization>
        BaseDN          "ou=openvpn,dc=openvpn,dc=server"
        SearchFilter    "uid=%u"
        RequireGroup    fales
</Authorization>

# SearchFilter  "(cn=%u)"
# SearchFilter	"sAMAccountName=%u"

--------------------------------------------------------------------------
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
-----------------------------------------------------------------------------------
