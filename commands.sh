#!/bin/bash -eux

repo="/home/isucon/isucon-template"
app="isucon.go"

function deploy() {
  # show commit info
  echo "Current Branch: $(cd $repo git && rev-parse --abbrev-ref HEAD)" && \
  echo "Last Commit Message: $(cd $repo && git log -1 --pretty=%B)"

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
    sudo systemctl restart {nginx,mysql,"$app"} && echo -e "\e[32mRestarted:\e[0m" "$_"
    # sudo systemctl disable --now {} && echo -e "\e[32mDisabled:\e[0m" "$_"
  fi
  if [ "$HOSTNAME" = "s2" ]; then
    sudo systemctl restart {nginx,mysql,"$app"} && echo -e "\e[32mRestarted:\e[0m" "$_"
    # sudo systemctl disable --now {} && echo -e "\e[32mDisabled:\e[0m" "$_"
  fi
  if [ "$HOSTNAME" = "s3" ]; then
    sudo systemctl restart {nginx,mysql,"$app"} && echo -e "\e[32mRestarted:\e[0m" "$_"
    # sudo systemctl disable --now {} && echo -e "\e[32mDisabled:\e[0m" "$_"
  fi

  sudo sysctl -q -p /etc/sysctl.d/99-isucon.conf && echo -e "\e[32mApplied:\e[0m" "$_"
}

function sync() {
  # $1: branch name
  (cd "$repo" && git fetch && git reset --hard "origin/${1:-main}")
  source "$repo/commands.sh"
}
