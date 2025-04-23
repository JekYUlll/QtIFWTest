#!/usr/bin/env bash
set -euo pipefail

VERSIONS=("1.0.0" "1.1.0" "1.2.0" "1.3.0")
COMPONENTS=("com.vendor.root.component1" "com.vendor.root.component1.subcomponent1")
SRC_DIR=$(pwd)
BUILD_DIR="$SRC_DIR/build"
INSTALL_DIR="$SRC_DIR/install-tmp"
STAGING_DIR="$SRC_DIR/staging"
REPO_DIR="$SRC_DIR/server/static"

# 清理
rm -rf "$BUILD_DIR" "$INSTALL_DIR" "$STAGING_DIR" "$REPO_DIR"
mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$STAGING_DIR" "$REPO_DIR"

# 生成 package.xml
gen_meta() {
  comp=$1
  ver=$2
  meta_dir="$STAGING_DIR/packages-${ver}/${comp}/meta"
  mkdir -p "$meta_dir"
  cat > "$meta_dir/package.xml" <<EOF
<Package>
    <DisplayName>${comp}</DisplayName>
    <Description>${comp} ${ver}</Description>
    <Version>${ver}</Version>
    <ReleaseDate>$(date +%F)</ReleaseDate>
    <Default>true</Default>
</Package>
EOF
}

for ver in "${VERSIONS[@]}"; do
  echo "🔨 Building version $ver..."
  cmake -S . -B "$BUILD_DIR/$ver" -DAPP_VERSION="$ver" -DINSTALL_PREFIX="$INSTALL_DIR/$ver"
  cmake --build "$BUILD_DIR/$ver"
  cmake --install "$BUILD_DIR/$ver"

  PKG_DIR="$STAGING_DIR/packages-${ver}"
  for comp in "${COMPONENTS[@]}"; do
    mkdir -p "$PKG_DIR/${comp}/data"
    cp "$INSTALL_DIR/$ver/${comp}/data/"* "$PKG_DIR/${comp}/data/"
    gen_meta "$comp" "$ver"
  done

  echo "📦 Generating standalone repository for $ver..."
  QtIFWTools/repogen -p "$PKG_DIR" "$STAGING_DIR/repo-$ver"
done

echo "📡 Merging all repositories into $REPO_DIR..."
for ver in "${VERSIONS[@]}"; do
  cp -r "$STAGING_DIR/repo-$ver/"* "$REPO_DIR/"
done

echo "✅ Done. Structure is:"
tree "$REPO_DIR"
