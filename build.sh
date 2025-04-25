#!/usr/bin/env bash
set -euo pipefail

VERSIONS=("1.0.0" "1.1.0" "1.2.0" "1.3.0")
COMPONENTS=("com.vendor.root.component1" "com.vendor.root.component1.subcomponent1")

SRC_DIR=$(pwd)
BUILD_DIR="$SRC_DIR/build"
INSTALL_DIR="$SRC_DIR/tmp"
PKG_BASE="$SRC_DIR/staging"
REPO_BASE="$SRC_DIR/server/static"

# 清理旧目录
rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$PKG_BASE" "$REPO_BASE"
mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$PKG_BASE" "$REPO_BASE"

# 生成 package.xml、license.txt、installscript.qs 和 errorpage.ui
gen_meta() {
  comp=$1
  ver=$2
  meta_dir="$PKG_BASE/packages-${ver}/${comp}/meta"
  mkdir -p "$meta_dir"

  # license.txt
  cat > "$meta_dir/license.txt" <<EOF
License Agreement for ${comp} ${ver}
Copyright (c) $(date +%Y) Vendor

By installing this software, you agree to the terms and conditions outlined here.
EOF

  # installscript.qs
  cat > "$meta_dir/installscript.qs" <<EOF
function Component()
{
    // Add a user interface file called ErrorPage, which should not be complete
    installer.addWizardPage( component, "ErrorPage", QInstaller.ReadyForInstallation );
    component.userInterface( "ErrorPage" ).complete = true;
}
EOF

  # errorpage.ui
  cat > "$meta_dir/errorpage.ui" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>ErrorPage</class>
 <widget class="QWidget" name="ErrorPage">
  <layout class="QVBoxLayout" name="verticalLayout">
   <item>
    <widget class="QLabel" name="label">
     <property name="text">
      <string>这是一个测试用的errorpage</string>
     </property>
    </widget>
   </item>
   <item>
    <widget class="QPushButton" name="continueButton">
     <property name="text">
      <string>OK</string>
     </property>
    </widget>
   </item>
  </layout>
 </widget>
 <resources/>
</ui>
EOF

  # package.xml
  cat > "$meta_dir/package.xml" <<EOF
<Package>
    <DisplayName>${comp}</DisplayName>
    <Description>${comp} ${ver}</Description>
    <Version>${ver}</Version>
    <ReleaseDate>$(date +%F)</ReleaseDate>
    <Default>true</Default>
    <Licenses>
        <License name="License Agreement" file="license.txt"/>
    </Licenses>
    <Script>installscript.qs</Script>
    <UserInterfaces>
        <UserInterface>errorpage.ui</UserInterface>
    </UserInterfaces>
</Package>
EOF
}

# ✅ 修复：generate_data_file 现在在 gen_meta 外部
generate_data_file() {
  local version=$1

  cat > "${SRC_DIR}/src/component1/example.data" <<EOF
Component1 Resource File
Version: ${version}
Timestamp: $(date)
EOF

  cat > "${SRC_DIR}/src/subcomponent1/helper.data" <<EOF
Subcomponent1 Resource File
Version: ${version}
Timestamp: $(date)
EOF
}

# 构建每个版本
for ver in "${VERSIONS[@]}"; do
  echo "🔨 Building version $ver..."

  generate_data_file "$ver"

  cmake -S . -B "$BUILD_DIR/$ver" -DAPP_VERSION="$ver" -DINSTALL_PREFIX="$INSTALL_DIR/$ver"
  cmake --build "$BUILD_DIR/$ver"
  cmake --install "$BUILD_DIR/$ver"

  PKG_DIR="$PKG_BASE/packages-${ver}"
  for comp in "${COMPONENTS[@]}"; do
    mkdir -p "$PKG_DIR/${comp}/data"
    cp "$INSTALL_DIR/$ver/${comp}/data/"* "$PKG_DIR/${comp}/data/" || echo "⚠️ No data for $comp $ver"
    gen_meta "$comp" "$ver"
  done

  REPO_DIR="$REPO_BASE/repo-${ver}"
  echo "📦 Generating repository for $ver → $REPO_DIR"
  QtIFWTools/repogen -p "$PKG_DIR" "$REPO_DIR"
done

# 查看结果
echo "✅ All repositories built:"
tree "$REPO_BASE"
