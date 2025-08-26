#!/bin/bash
set -euo pipefail  # 启用严格模式，遇到错误立即退出

# ==============================================
# 配置路径（兼容本地编译和GitHub Actions环境）
# ==============================================
if [ -n "${GITHUB_WORKSPACE:-}" ]; then
    BASE_DIR="${GITHUB_WORKSPACE}"
else
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# ==============================================
# 1. 基础配置修改
# ==============================================
# 修改默认IP（取消注释启用）
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认Shell为zsh（取消注释启用）
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD免登录（取消注释启用）
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# ==============================================
# 2. 移除冲突包
# ==============================================
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan

# ==============================================
# 3. 定义稀疏克隆函数（优化仓库目录提取）
# ==============================================
function git_sparse_clone() {
    local branch="$1"
    local repourl="$2"
    shift 2
    
    # 提取仓库名称（移除.git后缀）
    local repodir=$(echo "$repourl" | awk -F '/' '{print $(NF)}' | sed 's/\.git$//')
    
    # 稀疏克隆并处理目标文件
    git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl" || {
        echo "错误：克隆仓库 $repourl 失败"
        return 1
    }
    
    cd "$repodir" && git sparse-checkout set "$@" || {
        echo "错误：设置稀疏 checkout 失败"
        cd .. && rm -rf "$repodir"
        return 1
    }
    
    # 移动文件到package目录并清理
    mv -f "$@" ../package/ || echo "警告：部分文件移动失败，可能已存在"
    cd .. && rm -rf "$repodir"
}

# ==============================================
# 4. 添加额外插件（按需取消注释启用）
# ==============================================
# git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
# git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-serverchan
# git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy
# git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
# git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
# git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata
# git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server
# git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos

# ==============================================
# 5. 科学上网插件（按需取消注释启用）
# ==============================================
# git clone --depth=1 -b main https://github.com/fw876/helloworld package/luci-app-ssr-plus
# git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
# git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
# git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
# git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# ==============================================
# 6. 主题相关配置
# ==============================================
git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom
git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear

# 替换Argon主题背景图（自动适配环境路径）
BG_IMAGE="${BASE_DIR}/images/bg1.jpg"
if [ -f "$BG_IMAGE" ]; then
    mkdir -p package/luci-theme-argon/htdocs/luci-static/argon/img/
    cp -f "$BG_IMAGE" package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
    echo "已替换Argon主题背景图"
else
    echo "警告：未找到背景图 ${BG_IMAGE}，跳过替换"
fi

# ==============================================
# 7. 其他插件配置（按需取消注释启用）
# ==============================================
# 晶晨宝盒
# git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
# sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" package/luci-app-amlogic/root/etc/config/amlogic
# sed -i "s|ARMv8|ARMv8_PLUS|g" package/luci-app-amlogic/root/etc/config/amlogic

# SmartDNS
# git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
# git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# msd_lite
# git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
# git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

# MosDNS
# git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Alist
# git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

# DDNS.to
# git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
# git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# iStore
# git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
# git_sparse_clone main https://github.com/linkease/istore luci

# ==============================================
# 8. 系统优化配置
# ==============================================
# 在线用户插件
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# x86型号只显示CPU型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# ==============================================
# 9. 补丁与依赖修复
# ==============================================
# 修复hostapd报错
PATCH_FILE="${BASE_DIR}/scripts/011-fix-mbo-modules-build.patch"
if [ -f "$PATCH_FILE" ]; then
    mkdir -p package/network/services/hostapd/patches/
    cp -f "$PATCH_FILE" package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
else
    echo "警告：未找到补丁文件 ${PATCH_FILE}，跳过修复"
fi

# 修复armv8设备xfsprogs报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# ==============================================
# 10. 批量修改Makefile路径和源
# ==============================================
find package/*/ -maxdepth 2 -name "Makefile" | while read -r makefile; do
    sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' "$makefile"
    sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' "$makefile"
    sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' "$makefile"
    sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' "$makefile"
done

# ==============================================
# 11. 主题相关清理
# ==============================================
# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# ==============================================
# 12. 更新并安装 feeds
# ==============================================
./scripts/feeds update -a
./scripts/feeds install -a

echo "DIY脚本执行完成！"
