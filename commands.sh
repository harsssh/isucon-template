#!/bin/bash -eux

repo="/home/isucon/isucon-template"
app_service="isucon.go"

function deploy() {
  # WARN: .gitkeep is also added to /.gitkeep
  find "$repo/config/all" -type f | while read -r src; do
    dst="/${src#$repo/config/all}"
    sudo cp "$src" "$dst"
  done
  find "$repo/config/$HOSTNAME" -type f | while read -r src; do
    dst="/${src#$repo/config/$HOSTNAME}"
    sudo cp "$src" "$dst"
  done

  sudo systemctl daemon-reload

  # build
  # (cd "$repo/webapp/go" && go build -o app)

  if [ "$HOSTNAME" = "s1" ]; then
    sudo systemctl restart {nginx,mysql,"$app_service"}
  fi
  if [ "$HOSTNAME" = "s2" ]; then
    sudo systemctl restart {nginx,mysql,"$app_service"}
  fi
  if [ "$HOSTNAME" = "s3" ]; then
    sudo systemctl restart {nginx,mysql,"$app_service"}
  fi

  sudo sysctl -q -p /etc/sysctl.d/99-isucon.conf
}

function sync() {
  # $1: branch name
  (cd "$repo" && git fetch && git reset --hard "origin/${1:-main}")
  source "$repo/commands.sh"
}
