# QtIFW的安装包的构建

[//]: # (2025-04-19)

- `installerbase`：作为维护工具保存在客户端（通常命名为maintenancetool），用于更新、维护和卸载
- `binarycreator`：创建安装程序二进制文件
- `archivegen`：创建组件归档文件
- `repogen`：生成和管理组件仓库
- `devtool`：开发辅助工具，用于测试单个操作
- `repocompare`：仓库比较工具，对比不同版本的仓库内容（这什么玩意？没编出来）

`maintenancetool`实际是配置过的`installerbase`。

## 一、安装包的整体构建流程

- [Creating Installers](https://doc.qt.io/qtinstallerframework/ifw-creating-installers.html)

#### 1. 为可安装组件创建软件包目录：

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

- `data/` 目录包含安装程序在安装过程中提取的内容，这些数据必须打包到归档文件中。  
  这可以由 `binarycreator` 和 `repogen` 在创建安装程序或存储库时自动完成。

- 手动创建档案（压缩包）可以使用附带的 `archivegen` 工具，或手动生成以下格式：`7z` 、 `zip` 、 `tar.gz` 、 `tar.bz2` 和
  `tar.xz` 。

```bash
# 为每个组件创建归档文件
   archivegen component1.7z component1/
   archivegen component2.7z component2/
```

- 组件名称遵循类似域标识符的语法，例如 `com.vendor.root` 、 `com.vendor.root.subcomponent` 等。  
  这允许在图形模式下运行安装程序时轻松地从组件构建为树。  
  但是给人类看不直观，所以可以使用[`aliases.xml`](aliases.xml) （位于 `config/` 目录中）定义别名。

#### 2. 在 config 目录中创建一个名为 [`config.xml`](config.xml) 的配置文件。

#### 3. 在 `packages\{component}\meta` 目录中创建一个名为 [`package.xml`](package.xml) 的软件包信息文件。该文件包含部署和安装过程的设置。

#### 4. 创建安装程序内容并将其复制到软件包目录。

#### 5. 对于在线安装程序，使用 `repogen` 工具创建具有可安装内容的存储库并将存储库上传到 Web 服务器。

#### 6. 使用 `binarycreator` 工具创建安装程序。

---

## 二、离线安装包的构建

- [Creating Offline Installers](https://doc.qt.io/qtinstallerframework/ifw-offline-installers.html)

使用 binarycreator 工具的 `--offline-only` 选项：

```bash
<location-of-ifw>\binarycreator.exe --offline-only -t <location-of-ifw>\installerbase.exe -p <package_directory> -c <config_directory>\<config_file> <installer_name>
```

例如，输入以下命令创建一个名为 `SDKInstaller.exe` 的安装程序二进制文件，其中包含 `org.qt-project.sdk` 标识的软件包及其依赖项：

```bash
binarycreator.exe --offline-only -c installer-config -p installer-packes SDKInstaller.exe
```

---

## 三、在线安装包的构建

- [Creating Online Installers](https://doc.qt.io/qtinstallerframework/ifw-online-installers.html)

eg. 安装程序配置文件 `config.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Installer>
    <Name>Online Installer Example</Name>
    <Version>1.0.0</Version>
    <Title>Online Installer Example</Title>
    <Publisher>The Qt Company</Publisher>
    <!-- Directory name is used in component.xml -->
    <StartMenuDir>Qt IFW Examples</StartMenuDir>
    <TargetDir>@HomeDir@/IfwExamples/online</TargetDir>
    <RemoteRepositories>
        <Repository>
            <Url>http://localhost/repository</Url>
        </Repository>
    </RemoteRepositories>
</Installer>
```

- 完整配置：[Configuration File](https://doc.qt.io/qtinstallerframework/ifw-globalconfig.html)。

### 1. 服务端 - 远程存储库配置

使用`repogen`工具创建一个包目录的所有包的在线存储库：

```bash
repogen.exe -p < 软件包目录> < 存储库目录>
```

例如，要创建仅包含 `org.qt-project.sdk.qt` 和 `org.qt-project.sdk.qtcreator` 的存储库：

```bash
repogen.exe -p packages -i org.qt-project.sdk.qt,org.qt-project.sdk.qtcreator repository
```

`repogen`整体做的工作：读取每个包的`package.xml`、压缩为`.7z`、生成sha1校验和、生成文件目录结构、生成`Updates.xml`。

**配置存储库**：

`config.xml` 中的 `<RepositoryCategory>` 元素可以包含多个 `<RemoteRepositories>` 元素的列表：

```xml
<RepositoryCategories>
    <RemoteRepositories>
        <Displayname>Category 1</Displayname>
        <Preselected>true</Preselected>
        <Tooltip>Tooltip for category 1</Tooltip>
        <Repository>
            <Url>http://www.example.com/packages</Url>
            <Enabled>1</Enabled>
            <Username>user</Username>
            <Password>password</Password>
            <DisplayName>Example repository</DisplayName>
        </Repository>
    </RemoteRepositories>
</RepositoryCategories>
```

`<RemoteRepositories>` 元素可以包含多个存储库的列表：

```xml

<RemoteRepositories>
    <Repository>
        <Url>http://www.example.com/packages</Url>
        <Enabled>1</Enabled>
        <Username>user</Username>
        <Password>password</Password>
        <DisplayName>Example repository</DisplayName>
    </Repository>
</RemoteRepositories>
```

- `<Username>` ，用作受保护存储库上的用户。
- `<DisplayName>` ，可选择设置要显示的字符串而不是 URL。

### 2. 创建安装程序二进制文件

使用 `binarycreator` 工具创建在线安装程序：

```bash
<location-of-ifw>\binarycreator.exe -t <location-of-ifw>\installerbase.exe -p <package_directory> -c <config_directory>\<config_file> -e <packages> <installer_name>
```

例如，输入以下命令来创建名为 `SDKInstaller.exe` 的安装程序二进制文件，该文件将不包含 `org.qt-project.sdk.qt` 和
`org.qt-project.qtcreator` 的数据，因为这些包是从远程存储库下载的：

```bash
binarycreator.exe -p installer-packages -c installer-config\config.xml -e org.qt-project.sdk.qt,org.qt-project.qtcreator SDKInstaller.exe
```

> 即使组件是从 Web 服务器获取的， binarycreator 也会默认将其添加到安装程序二进制文件中。

> 可以创建不包含任何数据并从 Web 服务器获取所有数据的在线安装程序。  
> 使用 `binarycreator` 工具的 `-n` 参数，并仅将根组件添加到安装程序中。通常根组件为空，因此仅添加根组件的 XML 描述。






