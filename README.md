# QtIFW包测试项目

这是一个用于测试Qt Installer Framework (QtIFW)的项目，演示如何创建安装包和支持在线升级功能。

！！！  
依赖`QtIFWTools/`中的二进制工具，需根据平台自行编译/下载。  
！！！

## 项目结构

- `src/component1/`: 主应用程序组件
- `src/subcomponent1/`: 辅助库组件 
- `install-tmp/`: 临时目录
- `config/`: 安装器配置文件
- `server/`: 本地文件服务器（模拟更新仓库）
- `staging`: 即`packages`目录，用于生成后续各种内容
- `server/static`: 更新仓库
- `QtIFWTools/`: Qt IFW工具目录

## 使用方法

### 1. 构建组件并准备仓库

运行以下命令构建所有版本的组件并更新远程仓库：

```bash
./build.sh
```

这将：
- 构建四个版本的组件
- 准备packages目录，包含所有版本的数据
- 更新远程仓库，包含所有版本

### 2. 创建安装包

运行以下命令创建离线和在线安装包：

```bash
./create_online_installer.sh
./create_offline_installer.sh
```

生成安装包将放置于`release/`目录下。

### 3. 启动本地服务器

运行以下命令启动本地文件服务器：

```bash
cd server
go run .
```

服务器将在 http://localhost:8090 启动，为在线安装和更新提供服务。

### 4. 测试更新功能

1. 安装在线安装包
2. 启动已安装的应用程序，验证版本为1.0.0
3. 通过QtIFW的维护工具检查更新
4. 更新应用到1.1.0版本
5. 再次启动应用程序，验证版本已更新到1.1.0