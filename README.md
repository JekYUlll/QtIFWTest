# QtIFW包测试项目

这是一个用于测试Qt Installer Framework (QtIFW)的项目，演示如何创建安装包和支持在线升级功能。

## 项目结构

- `component1`: 主应用程序组件
- `subcomponent1`: 辅助库组件 
- `installer-config`: 安装器配置文件
- `server`: 本地文件服务器（模拟更新仓库）
- `QtIFWTools`: Qt IFW工具目录

## 版本管理

项目包含两个版本：
- 1.0.0: 基础版本
- 1.1.0: 更新版本

## 使用方法

### 1. 构建组件并准备仓库

运行以下命令构建所有版本的组件并更新远程仓库：

```bash
./build_and_prepare.sh
```

这将：
- 构建1.0.0和1.1.0两个版本的组件
- 准备packages目录，包含所有版本的数据
- 用1.0.0版本的组件创建安装包
- 更新远程仓库，包含所有版本

### 2. 创建安装包

运行以下命令创建离线和在线安装包：

```bash
./create_installer.sh
```

这将生成：
- 离线安装包：`installer-build/offline/QtIFWTest-offline-installer-1.0.0`
- 在线安装包：`installer-build/online/QtIFWTest-online-installer-1.0.0`

### 3. 启动本地服务器

运行以下命令启动本地文件服务器：

```bash
cd server
go run main.go
```

服务器将在 http://localhost:8090 启动，为在线安装和更新提供服务。

### 4. 测试更新功能

1. 安装在线安装包
2. 启动已安装的应用程序，验证版本为1.0.0
3. 通过QtIFW的维护工具检查更新
4. 更新应用到1.1.0版本
5. 再次启动应用程序，验证版本已更新到1.1.0

## 注意事项

- 本项目使用的Qt IFW版本可能不是最新版本，某些功能可能不可用
- 安装包仅包含1.0.0版本的组件，但远程仓库包含1.0.0和1.1.0两个版本
- 这样设计是为了测试在线更新功能

# Qt ifw 测试

[component1](component1/)为可执行程序。  
[subcomponent1](subcomponent1/)为动态库。  
内置`.data`资源文件。


```txt
-packages
    - com.vendor.root
        - data
        - meta
    - com.vendor.root.component1
        - data
        - meta
    - com.vendor.root.component1.subcomponent1
        - data
        - meta
    - com.vendor.root.component2
        - data
        - meta
```

---

# bash

1.  archivegen（可省略）
```bash
# QtIFWTools/archivegen component1.7z component1/
```

```bash
# QtIFWTools/archivegen component1.7z component1/
```

2. repogen（此处直接生成到服务端的static目录下）
```bash
QtIFWTools/repogen -p packages -i \
  com.vendor.root.component1,com.vendor.root.component1.subcomponent1 \
  server/static
```

```bash
QtIFWTools/repogen \
  --packages packages/1.0.0 packages/1.1.0 \
  --repository server/static
```

3. binarycreator

```bash
QtIFWTools/binarycreator \
  --packages staging/packages-v1.0.0 \
  --config installer-config/config.xml \
  installer-1.0.0.run
```

*eg*.
- 离线：
```bash
QtIFWTools/binarycreator --offline-only \
 -c installer-config/config.xml \
 -p staging/packages-1.0.0 \
 release/offlineInstaller.run
```
- 在线：
```bash
QtIFWTools/binarycreator \
  --online-only \
  -p packages \
  -c config/config.xml \
  release/qtifwtest-online-installer.run
```

```bash
QtIFWTools/binarycreator \
--offline-only \
  -p staging/packages-v1.0.0 \
  -c config/config.xml \
  -e com.vendor.root.component1,com.vendor.root.component1.subcomponent1 \
  release/qtifwtest-hybrid-installer.run
```

---

1. 构建旧版本安装包：
```bash
QtIFWTools/binarycreator \
  -p packages \
  -c installer-config/config.xml \
  Installer_1.0.0.exe
```