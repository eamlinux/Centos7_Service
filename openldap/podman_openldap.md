## 更新内核
```sh
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum install https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm

sudo yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
sudo yum --enablerepo=elrepo-kernel install kernel-ml
sudo yum --enablerepo=elrepo-kernel -y swap kernel-tools-libs -- kernel-ml-tools-libs
sudo yum --enablerepo=elrepo-kernel -y install kernel-ml-tools

# 替换系统默认的
yum --enablerepo=elrepo-kernel -y swap kernel-headers -- kernel-lt-headers
yum --enablerepo=elrepo-kernel -y swap kernel-devel -- kernel-lt-devel

# /etc/default/grub
Grub_DEFAULT=0

sudo rpm -qa | grep kernel
sudo yum autoremove kernel-3.10.*
```
## 安装```podman```
```sh
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y update
sudo reboot
cd /etc/yum.repos.d/
wget https://download.opensuse.org/repositories/home:/alvistack/CentOS_7/home:alvistack.repo
yum update
yum install podman podman-docker podman-aardvark-dns slirp4netns container-selinux 
```

echo "user.max_user_namespaces=15000" | sudo tee /etc/sysctl.d/42-rootless.conf
sudo sysctl --system

sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $(id -nu)
sudo loginctl enable-linger $(id -nu)
# Failed to connect to bus: 找不到介质
# 在当前用户目录下编辑.bashrc添加：

export XDG_RUNTIME_DIR=/run/user/$(id -u)
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"

podman system reset --force

# sudo getsebool -a | grep "container"
# sudo setsebool container_use_devices=true
# sudo setsebool -P container_use_devices=true
# setsebool -P container_manage_cgroup true
# setsebool -P container_manage_cgroup 1
# sudo setsebool -P container_manage_cgroup 1
# sudo setsebool -P container_manage_cgroup on

# container_connect_any	off	允许容器访问主机上的特权端口。例如，如果您有一个容器需要将端口映射到主机上的 443 或 80。
# container_manage_cgroup	off	允许容器管理 cgroup 配置。例如，运行 systemd 的容器将需要启用此功能。
# container_use_cephfs	off	允许容器使用 ceph 文件系统。

podman run \
--name openldap \
-e LDAP_ADMIN_USERNAME="admin" \
-e LDAP_ADMIN_PASSWORD="As@123" \
-e LDAP_ROOT="dc=openvpn,dc=server" \
-e LDAP_ADMIN_DN="cn=admin,dc=openvpn,dc=server" \
-v /opt/podman/openldap:/bitnami/openldap \
--privileged \
-p 1389:1389 \
-p 1636:1636 \
-d bitnami/openldap:latest

firewall-cmd --add-port=1389/tcp --permanent
firewall-cmd --reload

podman generate systemd --files --name openldap
mkdir -p .config/systemd/user/
mv *.service ~/.config/systemd/user/

sudo nano /etc/systemd/system/user@YOUR_NON-ROOT_USER_ID.service
```
[Unit]
Description=User Manager for UID %i
After=systemd-user-sessions.service
After=user-runtime-dir@%i.service
Wants=user-runtime-dir@%i.service

[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
User=%i
PAMName=systemd-user
Type=notify

PermissionsStartOnly=true
ExecStartPre=/bin/loginctl enable-linger %i
ExecStart=-/lib/systemd/systemd --user
Slice=user-%i.slice
KillMode=mixed
Delegate=yes
TasksMax=infinity
Restart=always
RestartSec=15

[Install]
WantedBy=default.target
```

systemctl daemon-reload
systemctl enable user@YOUR_NON-ROOT_USER_ID.service
systemctl start user@YOUR_NON-ROOT_USER_ID.service


curl -L https://get.docker.com | sh
wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64
chmod +x docker-compose-linux-x86_64
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose

curl https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/docker-ce.repo
yum --enablerepo=docker-ce-stable -y install docker-ce
sudo usermod -aG docker $USER
systemctl enable --now docker
