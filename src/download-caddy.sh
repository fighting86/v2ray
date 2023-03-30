_download_caddy_file() {
	caddy_tmp="/tmp/install_caddy/"
	caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	[[ -d $caddy_tmp ]] && rm -rf $caddy_tmp
	if [[ ! ${caddy_arch} ]]; then
		echo -e "$red 获取 Caddy 下载参数失败！$none" && exit 1
	fi
	local caddy_download_link="https://github.com/caddyserver/caddy/releases/download/v2.6.2/caddy_2.6.2_linux_${caddy_arch}.tar.gz"

	mkdir -p $caddy_tmp

	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "$red 下载 Caddy 失败！$none" && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	# wget -qO- https://getcaddy.com | bash -s personal

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "$red 安装 Caddy 出错！$none" && exit 1
	fi
}
_install_caddy_service() {
	# setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy

	if [[ $systemd ]]; then
		#### 。。。。。 Warning.....Warning.......Warning........Warning......
		#### 。。。。。 use root user run caddy...

		cat >/lib/systemd/system/caddy.service <<-EOF
			#https://github.com/caddyserver/dist/blob/master/init/caddy.service
			[Unit]
			Description=Caddy
			Documentation=https://caddyserver.com/docs/
			After=network.target network-online.target
			Requires=network-online.target

			[Service]
			Type=notify
			User=root
			Group=root
			ExecStart=/usr/local/bin/caddy run --environ --config /etc/caddy/Caddyfile
			ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
			TimeoutStopSec=5s
			LimitNOFILE=1048576
			LimitNPROC=512
			PrivateTmp=true
			ProtectSystem=full
			#AmbientCapabilities=CAP_NET_BIND_SERVICE

			[Install]
			WantedBy=multi-user.target
		EOF
		systemctl enable caddy
	else
		cp -f ${caddy_tmp}init/linux-sysvinit/caddy /etc/init.d/caddy
		sed -i "s/www-data/root/g" /etc/init.d/caddy
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi

	# ref https://github.com/caddyserver/caddy/tree/master/dist/init/linux-systemd

	mkdir -p /etc/caddy
	# chown -R root:root /etc/caddy
	mkdir -p /etc/ssl/caddy
	# chown -R root:www-data /etc/ssl/caddy
	# chmod 0770 /etc/ssl/caddy

	## create sites dir
	mkdir -p /etc/caddy/sites
}
