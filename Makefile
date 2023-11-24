### 問題ごとに調整が必要な変数 ###
# 管理したいconfigの絶対パス
CONFIG_FILES := /etc/mysql/mysql.conf.d/mysqld.cnf \
				/etc/nginx/nginx.conf \
				/lib/systemd/system/nginx.service \
				/lib/systemd/system/mysql.service \
				/etc/nginx/sites-available/isucon.conf \
				/etc/systemd/system/isucon.service
WEBAPP_DIR := /home/isucon/webapp

### その他の変数 ###
# CONFIG_FILESのコピー先
CONFIG_SAVE_DIR := config/all
# Go以外の実装言語
IGNORE_IMPL_LANG := perl php python ruby rust node java
# ツールのバージョン
GO_VERSION := 1.21.4
ALP_VERSION := 1.0.21
SLP_VERSION := 0.2.0
PPROTEIN_VERSION := 1.2.3

.PHONY: all
all: init

.PHONY: init
init: install-tools webapp webapp-ignore gather-config

# 必要なツールをinstall
.PHONY: install-tools
install-tools: install-go install-alp install-slp install-pprotein
	@echo "Update, upgrade and install tools"
	@sudo apt update && sudo apt upgrade -y
	@sudo apt install -y percona-toolkit graphviz

.PHONY: install-go
install-go:
	@if ! which go > /dev/null 2>&1; then \
		echo "Install Go"; \
		cd /tmp && wget https://go.dev/dl/go$(GO_VERSION).linux-amd64.tar.gz \
			&& sudo tar -C /usr/local -xf go$(GO_VERSION).linux-amd64.tar.gz; \
	fi

.PHONY: install-alp
install-alp:
	@if ! which alp > /dev/null 2>&1; then \
		echo "Install alp"; \
		cd /tmp && wget https://github.com/tkuchiki/alp/releases/download/v$(ALP_VERSION)/alp_linux_amd64.tar.gz \
			&& tar xf alp_linux_amd64.tar.gz \
			&& sudo install alp /usr/local/bin/alp; \
	fi

.PHONY: install-slp
install-slp:
	@if ! which slp > /dev/null 2>&1; then \
		echo "Install slp"; \
		cd /tmp && wget https://github.com/tkuchiki/slp/releases/download/v$(SLP_VERSION)/slp_linux_amd64.tar.gz \
			&& tar xf slp_linux_amd64.tar.gz \
			&& sudo install slp /usr/local/bin/slp; \
	fi

.PHONY: install-pprotein
install-pprotein:
	@if ! (which pprotein || which pprotein-agent) > /dev/null 2>&1; then \
  		echo "Install pprotein"; \
		cd /tmp && wget https://github.com/kaz/pprotein/releases/download/v$(PPROTEIN_VERSION)/pprotein_$(PPROTEIN_VERSION)_linux_amd64.tar.gz \
			&& tar xf pprotein_$(PPROTEIN_VERSION)_linux_amd64.tar.gz \
			&& sudo install pprotein /usr/local/bin/pprotein \
			&& sudo install pprotein-agent /usr/local/bin/pprotein-agent; \
	fi

# 元の場所にはシンボリックリンクを作成
webapp: $(WEBAPP_DIR)
	@echo "Move webapp to current directory"
	@cp -r $(WEBAPP_DIR) $(WEBAPP_DIR).bak
	@mv $(WEBAPP_DIR) ./webapp
	@ln -s $$PWD/webapp $(WEBAPP_DIR)

# IGNORE_IMPL_LANGを名前に含むファイル/ディレクトリをignore
# サイズの大きいファイルもignore
webapp-ignore: webapp
	@echo "Ignore some files/directories in webapp"
	@for lang in $(IGNORE_IMPL_LANG); do \
  		echo webapp/*$$lang* | tr ' ' '\n' >> .gitignore; \
	done
	@find webapp -size +10M >> .gitignore

# /etc/path/to/config -> config/all/etc/path/to/config
.PHONY: gather-config
gather-config: $(CONFIG_FILES)
	@echo "Gather config files"
	@for file in $(CONFIG_FILES); do \
  		dst=$(CONFIG_SAVE_DIR)`dirname $$file`; \
  		mkdir -p $$dst; \
  		sudo cp $$file $$dst; \
	done