# QtIFW 全流程  

安装包构建 & 仓库构建 & 服务端模拟 & 离线安装后的在线更新

张祝玙 2025/04/23 

> 环境：  Linux Mint 22  
> Cmake： 3.28.3

---

### Qt Installser Framework 工具一览

- `installerbase`：作为维护工具保存在客户端（通常命名为maintenancetool），用于更新、维护和卸载
- `binarycreator`：创建安装程序二进制文件
- `archivegen`：创建组件归档文件
- `repogen`：生成和管理组件仓库
- `devtool`：开发辅助工具，用于测试单个操作
- `repocompare`：仓库比较工具，对比不同版本的仓库内容（这什么玩意？没编出来）

`maintenancetool`实际是配置过的`installerbase`。

创建安装包，流程大致如下（详见 [Tutorial: Creating an Installer](https://doc.qt.io/qtinstallerframework/ifw-tutorial.html)）：  
1. 创建一个包含所有配置文件和可安装包的包目录 。
2. 创建一个配置文件 ，其中包含有关如何构建安装程序二进制文件和在线存储库的信息。
3. 创建包含有关可安装组件信息的包信息文件 。
4. 创建安装程序内容并将其复制到包目录。
5. 使用 `binarycreator` 工具创建安装程序 。

根据官方文档，此处可见`installerbase`的作用：
```bash
<location-of-ifw>\binarycreator.exe -t <location-of-ifw>\installerbase.exe -p <package_directory> -c <config_directory>\<config_file> -e <packages> <installer_name>
```

创建存储库则是使用 `repogen` 工具，详见 [Creating Online Installers](https://doc.qt.io/qtinstallerframework/ifw-online-installers.html)。

---

![流程](images/qtifw_general.png)

![流程](images/qtifw_details.png)

首先从理论上过一遍：

### 安装包的整体构建流程

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
  这可以由 `binarycreator` 和 `repogen` 在创建安装程序或存储库时自动完成（指归档）。

- 手动创建档案（压缩包）可以使用附带的 `archivegen` 工具，或手动生成以下格式：`7z` 、 `zip` 、 `tar.gz` 、 `tar.bz2` 和
  `tar.xz` 。

```bash
   archivegen component1.7z component1/
```

#### 2. 在 config 目录中创建一个名为 [`config.xml`](config.xml) 的配置文件。

#### 3. 在 `packages\{component}\meta` 目录中创建一个名为 [`package.xml`](package.xml) 的软件包信息文件。该文件包含部署和安装过程的设置。

#### 4. 创建安装程序内容并将其复制到软件包目录。

#### 5. 对于在线安装程序，使用 `repogen` 工具创建具有可安装内容的存储库并将存储库上传到 Web 服务器。

#### 6. 使用 `binarycreator` 工具创建安装程序。

---

# 实际流程

### 1. 准备组件

此处准备三种资源类型进行模拟：

1) **可执行程序** `component1`：elf 二进制`app1`，echo 命令行参数，并调用动态库（组件`subcomponent1`）；
```c++
int main(int argc, char* argv[]) {
    // ...
    for (int i = 0; i < argc; ++i) {
        std::cout << "  argv[" << i << "] = " << argv[i] << std::endl;
    }
    say_hello();  // 来自 libhelper.so
    // ...
}
```
2) **动态库** `subcomponent1`：`libhelper.so`，提供一个 `say_hello()` 函数；
3) **资源文件**（`.data`）：文本文件，`example.data`与可执行程序打包在一起，`helper.data`和动态库打包在一起；内容通过脚本动态生成。  
例：
```txt
Component1 Resource File
Version: 1.3.0
Timestamp: 2025年 04月 23日 星期三 16:17:38 CST
```

构建源文件初始结构：
```txt
$ tree src                                                              □ QtIFWPackTest △⎪▴│1│▪┤2│●◦◎◦✕⎥via △ v3.28.3  16:18
src
├── component1
│   ├── example.data
│   └── main.cpp
└── subcomponent1
    ├── helper.cpp
    ├── helper.data
    └── helper.h
```

### 2. 编译与版本模拟

通过脚本动态修改上述三种资源的内容，编译为4个版本（`1.0.0`、`1.1.0`、`1.2.0`、`1.3.0`）。

此处将两个组件命名为`com.vendor.root.component1`与`com.vendor.root.component1.subcomponent1`。

> 组件名称遵循类似域标识符的语法，例如 `com.vendor.root` 、 `com.vendor.root.subcomponent` 等。  
  这允许在图形模式下运行安装程序时轻松地从组件构建为树。  

给人类看不直观，所以可以使用[`aliases.xml`](aliases.xml) （位于 `config/` 目录中）定义别名（此处略过）。

### 3. 准备 packages 仓库

根据[官方手册](https://doc.qt.io/qtinstallerframework/ifw-tutorial.html)，推荐使用如下的目录结构：  

![官方目录结构](images/doc_packagedir.png)

通过脚本控制，生成上述4个版本的仓库：
```txt
$ tree staging                                                               □ QtIFWPackTest △⎪▴│1│▪┤3│●◦◎◦✕⎥via △ v3.28.3  16:35
staging
├── packages-1.0.0
│   ├── com.vendor.root.component1
│   │   ├── data
│   │   │   ├── app1
│   │   │   └── example.data
│   │   └── meta
│   │       └── package.xml
│   └── com.vendor.root.component1.subcomponent1
│       ├── data
│       │   ├── helper.data
│       │   └── libhelper.so
│       └── meta
│           └── package.xml
├── packages-1.1.0
│// ...
├── packages-1.2.0
│// ...
└── packages-1.3.0
 // ...
```

`package.xml` 内容如下：

```xml
<Package>
  <DisplayName>com.vendor.root.component1</DisplayName>
  <Description>com.vendor.root.component1 1.0.0</Description>
  <Version>1.0.0</Version>
  <ReleaseDate>2025-04-25</ReleaseDate>
  <Default>true</Default>
  <Licenses>
    <License name="License Agreement" file="license.txt"/>
  </Licenses>
  <UserInterfaces>
    <UserInterface>errorpage.ui</UserInterface>
  </UserInterfaces>
  <Script>installscript.qs</Script>
</Package>
```

- 使用`errorpage.ui`来模拟一个安装时自定义界面；
- 使用`installscript.qs`来定义界面的加载逻辑；

`package.xml`的额外配置：
```xml
<?xml version="1.0"?>
<Package>
    <DisplayName>QtGui</DisplayName>
    <Description>Qt gui libraries</Description>
    <Description xml:lang="de_de">Qt GUI Bibliotheken</Description>
    <Version>1.2.3</Version>
    <ReleaseDate>2009-04-23</ReleaseDate>
    <Name>com.vendor.root.component2</Name>
    <Dependencies>com.vendor.root.component1</Dependencies>
    <Virtual>false</Virtual>
    <Licenses>
        <License name="License Agreement" file="license.txt"/>
    </Licenses>
    <Script>installscript.qs</Script>
    <UserInterfaces>
        <UserInterface>specialpage.ui</UserInterface>
        <UserInterface>errorpage.ui</UserInterface>
    </UserInterfaces>
    <Translations>
        <Translation>sv_se.qm</Translation>
        <Translation>de_de.qm</Translation>
    </Translations>
    <DownloadableArchives>component2.7z, component2a.7z</DownloadableArchives>
    <AutoDependOn>com.vendor.root.component3</AutoDependOn>
    <SortingPriority>123</SortingPriority>
    <UpdateText>This changed compared to the last release</UpdateText>
    <Default>false</Default>
    <ForcedInstallation>false</ForcedInstallation>
    <ForcedUpdate>false</ForcedUpdate>
    <Essential>false</Essential>
    <Replaces>com.vendor.root.component2old</Replaces>
    <Operations>
        <Operation name="AppendFile">
            <Argument>@TargetDir@/A.txt</Argument>
            <Argument>lorem ipsum</Argument>
        </Operation>
        <Operation name="Extract">
            <Argument>@TargetDir@/Folder1</Argument>
            <Argument>content.7z</Argument>
        </Operation>
        <Operation name="Extract">
            <Argument>@TargetDir@/Folder2</Argument>
        </Operation>
    </Operations>
    <TreeName moveChildren="true">com.vendor.subcomponent</TreeName>
</Package>
```

### 4. 远程仓库构建

使用 shell 脚本，调用 `repogen` 工具，生成各个版本的仓库：

```bash
# ...
QtIFWTools/repogen -p "$PKG_DIR" "$REPO_DIR"
# ...
```

- `$PKG_DIR` 为此前构建的 packages 仓库，须指定不同版本分别构建。  
- `$REPO_DIR` 为仓库的目标路径。

生成结构如下：  

```txt
$ tree server/static                                                         □ QtIFWPackTest △⎪▴│1│▪┤4│●◦◎◦✕⎥via △ v3.28.3  16:55
server/static
├── repo-1.0.0
│   ├── 2025-04-23-1617_meta.7z
│   ├── com.vendor.root.component1
│   │   ├── 1.0.0content.7z
│   │   ├── 1.0.0content.7z.sha1
│   │   └── 1.0.0meta.7z
│   ├── com.vendor.root.component1.subcomponent1
│   │   ├── 1.0.0content.7z
│   │   ├── 1.0.0content.7z.sha1
│   │   └── 1.0.0meta.7z
│   └── Updates.xml
├── repo-1.1.0
│/...
├── repo-1.2.0
│/...
└── repo-1.3.0
 /...
```

在使用 `repogen` 生成仓库时：  
`package.xml` 并不会被包含在压缩后的仓库中，被用于生成 `Updates.xml` 索引文件。

### 5. 仓库服务器搭建

> 静态资源服务器是一种用于托管不会改变的资源，如HTML、CSS、JavaScript文件、图片等的服务器。这些资源通常以文件的形式存在，服务器处理这些资源的请求时，通常只需读取文件内容并返回给客户端。

使用 Golang 搭建静态资源文件服务器，在本地端口测试，托管上述生成的`./static`中的内容：

```C++
func main() {
    // ...
	fs := http.StripPrefix("/repo", http.FileServer(http.Dir("./static")))
	http.Handle("/repo/", fs)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/repo/", http.StatusFound) // 302 Temporary Redirect
	})

	err := http.ListenAndServe("0.0.0.0:8090", nil)
	// ...
}
```

仓库效果：
![/repo](images/img_1.png)

![/repo/repo-1.0.0/](images/img_2.png)

**服务端密码设置**：

> 实际上可以在nginx的配置里直接用`root`设置本地路径，将其作为静态资源服务器。  
> 但此处已经写好Golang服务器，另外考虑可能有服务端校验和等规则，此处将nigix直接作为反向代理：监听8091端口，代理8090的服务。

需要 Nginx 和 htpasswd 工具。

添加一个user`tr`，设置密码`123456`：
```bash
sudo htpasswd -c /etc/nginx/.htpasswd tr
```

修改nginx配置：
```bash
sudo nvim /etc/nginx/sites-available/default
````

设置规则（监听`8091`端口，反向代理之前的Go仓库服务）：

![nginx](images/img_32.png)

启动nignx：

```bash
sudo systemctl start nginx
```

重新加载配置：

```bash
sudo nginx -s reload
```

之后访问可见：

![nginx](images/img_31.png)

### 6. 安装包配置文件 `config.xml` 配置

指定了以下内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Installer>
    <Name>QtIFW Pack Test - TR</Name>
    <Version>1.0.0</Version> <!-- 安装器自身版本，不影响组件版本 -->
    <Title>QtIFW 测试安装器 - Title</Title>
    <Publisher>张祝玙</Publisher>
    <ProductUrl>https://www.qq.com</ProductUrl>
    <!-- 一些图标和水印 -->
    <InstallerWindowIcon>images/installer.png</InstallerWindowIcon>
    <InstallerApplicationIcon>images/installer.png</InstallerApplicationIcon>
    <Logo>images/logo.png</Logo>
    <Background>images/background.png</Background>
    <Watermark>images/watermark.png</Watermark>
    <!--  安装完成后可以直接勾选运行的可执行程序-->
    <RunProgram>@TargetDir@/app1</RunProgram>
    <RunProgramArguments>
        <Argument>Arg1</Argument>
        <Argument>Arg2</Argument>
    </RunProgramArguments>
    <RunProgramDescription>QtIFW 测试程序 - Description</RunProgramDescription>
    <!--  一些路径和命名-->
    <StartMenuDir>QtIFWTest</StartMenuDir>
    <MaintenanceToolName>TestMaintenanceTool</MaintenanceToolName>
    <AllowNonAsciiCharacters>true</AllowNonAsciiCharacters>
    <TargetDir>@HomeDir@/QtIFWTest/1.0.0</TargetDir>
    <AdminTargetDir>@RootDir@/QtIFWTest/1.0.0</AdminTargetDir>
    <!--  创建本地仓库（后续添加组件可选择）-->
    <CreateLocalRepository>true</CreateLocalRepository>
    <InstallActionColumnVisible>true</InstallActionColumnVisible>
    <!--  配置远程仓库-->
    <RemoteRepositories>
    <!--  <Repository>以包含Updates.xml的路径为单位，此处需要每个版本各配置一个-->
        <Repository>
            <Url>http://localhost:8090/repo</Url>
            <Enabled>true</Enabled>
            <DisplayName>本地测试仓库(Mint)</DisplayName>
        </Repository>
        <Repository>
            <Url>http://localhost:8090/repo/repo-1.0.0/</Url>
            <Enabled>true</Enabled>
            <DisplayName>本地测试仓库(Mint)-1.0.0</DisplayName>
        </Repository>
        <Repository>
            <Url>http://localhost:8090/repo/repo-1.1.0/</Url>
            <Enabled>true</Enabled>
            <DisplayName>本地测试仓库(Mint)-1.1.0</DisplayName>
        </Repository>
        <Repository>
            <Url>http://localhost:8090/repo/repo-1.2.0/</Url>
            <Enabled>true</Enabled>
            <DisplayName>本地测试仓库(Mint)-1.2.0</DisplayName>
        </Repository>
        <Repository>
            <!--  此处8091是nginx反向代理的端口8091-->
            <Url>http://localhost:8091/repo/repo-1.3.0/</Url>
            <Enabled>true</Enabled>
            <!--   对最新仓库启用用户与密码进行测试-->
            <Username>tr</Username>
            <Password>123456</Password>
            <DisplayName>本地测试仓库(Mint)-1.3.0</DisplayName>
        </Repository>
        <Repository>
            <Url>http://172.16.20.15:8090/repo/</Url>
            <Enabled>true</Enabled>
            <DisplayName>局域网测试仓库(DELL)</DisplayName>
        </Repository>
    </RemoteRepositories>
    <!--  为组件添加一些别名，此处未使用-->
    <AliasDefinitionsFile>aliases.xml</AliasDefinitionsFile>
</Installer>
```

- `<Username>` ，用作受保护存储库上的用户。
- `<DisplayName>` ，可选择设置要显示的字符串而不是 URL。

config.xml` 中的 `<RepositoryCategory>` 元素可以包含多个 `<RemoteRepositories>` 元素的列表（此处未启用）：

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

### 7. 离线安装包构建

为测试后续更新功能，使用 `1.0.0` 版本构建安装包程序：

```bash
QtIFWTools/binarycreator \
  --offline-only \
  -c config/config.xml \
  -p staging/packages-1.0.0 \
  -t QtIFWTools/installerbase \
  release/offlineInstaller-1.0.0.run
```

分别指定了配置文件路径、包位置、可执行文件目标路径。

此处使用 `--offline-only` 构建离线安装包，会将 `staging/packages-1.0.0` 中内容打包进可执行程序。


### 8. 安装

运行安装包程序：  

![](images/img_3.png)

![](images/img_4.png)

此处可见组件的树状关系（此前 `package.xml` 中并未显式指定依赖关系，此处是命名导致的行为）：

![](images/img_5.png)

无许可协议，直接跳到准备安装：

![](images/img_6.png)

安装成功，可以直接运行指定的程序：

![](images/img_7.png)

```txt
Running app1 (component 1)
Received arguments:
  argv[0] = /home/horeb/QtIFWTest/test/app1
  argv[1] = Arg1
  argv[2] = Arg2
Hello from libhelper.so!
```

安装完成后目录结构：

![](images/img_8.png)

```txt
$ tree                                                   □ QtIFWTest/test 17:14
.
├── app1
├── components.xml
├── example.data
├── helper.data
├── InstallationLog.txt
├── installer.dat
├── installerResources
│   ├── com.vendor.root.component1
│   │   └── 1.0.0content.txt
│   └── com.vendor.root.component1.subcomponent1
│       └── 1.0.0content.txt
├── libhelper.so
├── network.xml
├── repository
│   ├── com.vendor.root.component1
│   │   ├── 1.0.0content.7z
│   │   ├── 1.0.0content.7z.sha1
│   │   └── 1.0.0meta.7z
│   ├── com.vendor.root.component1.subcomponent1
│   │   ├── 1.0.0content.7z
│   │   ├── 1.0.0content.7z.sha1
│   │   └── 1.0.0meta.7z
│   └── Updates.xml
├── TestMaintenanceTool
├── TestMaintenanceTool.dat
└── TestMaintenanceTool.ini
```

`repository/` 下可见生成的本地仓库。

`TestMaintenanceTool.ini` 存储编码后的仓库地址。

`network.xml`为网络代理内容及后续添加的新仓库：

```xml
<?xml version="1.0"?>
<Network>
    <ProxyType>1</ProxyType>
    <Ftp>
        <Host></Host>
        <Port>0</Port>
        <Username></Username>
        <Password></Password>
    </Ftp>
    <Http>
        <Host></Host>
        <Port>0</Port>
        <Username></Username>
        <Password></Password>
    </Http>
    <Repositories/>
    <LocalCachePath>/home/horeb/.cache/qt-installer-framework/9e7b92a2-c218-384a-b87e-f010be7ddfbf</LocalCachePath>
</Network>
```

手动添加一个自定义仓库`qq.com`测试，可以看到`network.xml`中新增了条目：

![手动添加qq.com](images/img_37.png)

![network.xml](images/img_38.png)

本地的components.xml用于与远程仓库的对比：  
```xml
<Packages>
    <ApplicationName>QtIFW Pack Test - TR</ApplicationName>
    <ApplicationVersion>1.0.0</ApplicationVersion>
    <Package>
        <Name>com.vendor.root.component1</Name>
        <Title>com.vendor.root.component1</Title>
        <Description>com.vendor.root.component1 1.0.0</Description>
        <SortingPriority>0</SortingPriority>
        <TreeName moveChildren="false"></TreeName>
        <Version>1.0.0</Version>
        <LastUpdateDate></LastUpdateDate>
        <InstallDate>2025-04-23</InstallDate>
        <Size>16630</Size>
        <Checkable>true</Checkable>
    </Package>
    <Package>
        <Name>com.vendor.root.component1.subcomponent1</Name>
        <Title>com.vendor.root.component1.subcomponent1</Title>
        <Description>com.vendor.root.component1.subcomponent1 1.0.0</Description>
        <SortingPriority>0</SortingPriority>
        <TreeName moveChildren="false"></TreeName>
        <Version>1.0.0</Version>
        <LastUpdateDate></LastUpdateDate>
        <InstallDate>2025-04-23</InstallDate>
        <Size>16049</Size>
        <Checkable>true</Checkable>
    </Package>
</Packages>
```

### 9. 在线安装包构建

```bash
QtIFWTools/binarycreator \
  -c config/config.xml \
  -p staging/packages-1.0.0 \
  -e com.vendor.root.component1,com.vendor.root.component1.subcomponent1 \
  -t QtIFWTools/installerbase \
  release/onlineInstaller-1.0.0.run
```

- `-e` 是 `--exclude` 的简写，表示从最终的安装器中排除某些组件。这些组件不会包含在安装包中，但可以从在线源中手动选择安装。

![在线安装](images/img_25.png)

![在线安装](images/img_24.png)

![在线安装](images/img_26.png)

若此前设置用户与密码，此处会进行填充：

![在线安装](images/img_27.png)

### 9. 更新

运行此前安装目录中自动生成的 `TestMaintenanceTool`：

![](images/img_9.png)

若本地版本为所有仓库中的最高版本：

![](images/img_20.png)

左下角 [设置] 中可指定：

- 系统代理：

![](images/img_10.png)

- 资料档案库（仓库）
此处可见之前指定的各个仓库（此处仅勾选本地仓库与 `1.2.0` 版本的仓库）。

![](images/img_12.png)

- 本地缓存路径

![](images/img_13.png)

选择更新，可以注意到此处只能选择已经勾选的最新版本（如果勾选`1.3.0`的仓库则只能升级至`1.3.0`）：

![](images/img_14.png)

![](images/img_15.png)

更新完成：

![](images/img_16.png)

---

### 补充：license、自定义界面

自定义的ui文件：
```xml
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
```

自定义的qs脚本：

```javascript
function Component()
{
  // Add a user interface file called ErrorPage, which should not be complete
  installer.addWizardPage( component, "ErrorPage", QInstaller.ReadyForInstallation );
  component.userInterface( "ErrorPage" ).complete = true;
}

```

![license](images/img_39.png)

![license](images/img_40.png)

---

### 测试：components.xml

手动修改 `components.xml` 的内容，将组件版本改为 `1.1.0`，实际已更新至 `1.2.0`：

![](images/img_17.png)

打开更新，发现仍识别本地是 `1.2.0` （即为正确的版本）。

![](images/img_18.png)

更新至`1.3.0`。发现 components.xml 已随之更新：

![](images/img_19.png)

---

### 查看缓存目录：

```txt
$ tree      □ qt-installer-framework/8f696b25-f428-3e56-af40-667b325181e4 17:24
.
├── e907291c46b9087534e5a4c94edb81046452011a
│   ├── com.vendor.root.component1
│   ├── com.vendor.root.component1.subcomponent1
│   ├── repository.txt
│   └── Updates.xml
└── manifest.json
```

```txt
$ cat manifest.json
{
    "items": [
        "e907291c46b9087534e5a4c94edb81046452011a"
    ],
    "type": "Metadata",
    "version": "1.2.0"
}
```

```txt
$ cat repository.txt
/repo%  
```

---

### 网络测试

使用`tcpdump`对8090端口（服务器监听端口）进行抓包：

```bash
sudo tcpdump -i lo -w localhost_ifw.pcap port 8090
```

使用`wireshark`的图形化界面查看：

```bash
wireshark localhost_ifw.pcap
```

![抓包](images/img_23.png)


![Updates.xml](images/img_22.png)

请求Updates.xml时的完整url：`[Full request URI: http://localhost:8090/repo/repo-1.2.0/Updates.xml?3624636785]`  
"cache busting"，在 URL 后附带一个随机数或时间戳，用于：
- 避免浏览器或代理服务器缓存静态文件  
- 确保每次请求都拿到最新的内容

`/repo/repo-1.2.0/Updates.xml?...`

`/repo/repo-1.2.0/com.vendor.root.component1/1.2.0content.7z.sha1`

`/repo/repo-1.2.0/com.vendor.root.component1/1.2.0content.7z`

`/repo/repo-1.2.0/com.vendor.root.component1.subcomponent1/1.2.0content.7z.sha1`

- **问**：对设置了用户名和密码的仓库也进行了测试（仅在安装包即客户端设置，服务端未设置规则），为什么没有携带用户名或密码？

![Updates.xml](images/img_28.png)

Installer 行为是“懒发送”（延迟发送认证）：  
并不会主动发送用户名和密码——只有在服务器响应 401 Unauthorized 的时候，它才会携带用户名和密码（通常是用 Basic Auth）。

该`GET`请求没有没有 `Authorization` 头，这是因为服务端根本没要求验证（也就是没返回 `401`）。

因此配置nginx认证规则后，抓包8091端口：  

```bash
sudo tcpdump -i lo -w localhost_ifw_nginx.pcap port 8091
```

![Updates.xml](images/img_36.png)

此处可见安装包请求`Updates.xml`时，服务端返回的`HTTP/1.1 401 Unauthorized\r\n`：

![Updates.xml](images/img_33.png)

之后重新发送GET请求，携带`tr`和`123456`

![Updates.xml](images/img_35.png)

---

### [补充] 安装时解压性能调查

> QtIFW解压器是内置了 LZMA 解码器，性能接近 7-Zip。

在安装包内增加载荷，打包一个2.7G的压缩包进去（里面包含87首.flac格式音乐作为组件，含有简单目录层级）：

```txt
$ ll                                □ com.vendor.root.component1/data⎪●◦⎥ 09:13
drwxrwxr-x horeb horeb 4.0 KB Tue Apr 29 09:12:26 2025  ./
drwxrwxr-x horeb horeb 4.0 KB Fri Apr 25 20:03:03 2025  ../
.rwxr-xr-x horeb horeb  16 KB Fri Apr 25 20:03:03 2025  app1*
.rw-r--r-- horeb horeb  94 B  Fri Apr 25 20:03:03 2025  example.data
.rw-rw-r-- horeb horeb 2.5 GB Tue Apr 29 09:11:35 2025  payload.7z
```

打包后安装包大小从76.7MB增加至2.8GB。

安装时日志：
```txt
正在准备安装…

正在准备解压组件......

正在解压组件......
正在提取“1.0.0payload.7z”
正在提取“1.0.0content.7z”
正在提取“1.0.0content.7z”
已完成

正在安装组件 com.vendor.root.component1
已完成

正在安装组件 com.vendor.root.component1.subcomponent1
已完成

正在创建本地资料档案库
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/license.txt
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/errorpage.ui
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/installscript.qs
/home/horeb/QtIFWTest/1.0.0_whole/repository/config/config-internal.ini
/home/horeb/QtIFWTest/1.0.0_whole/repository/installer-config/aliases_xml.xml
/home/horeb/QtIFWTest/1.0.0_whole/repository/installer-config/images_background_png.png
/home/horeb/QtIFWTest/1.0.0_whole/repository/installer-config/images_installer_png.png
/home/horeb/QtIFWTest/1.0.0_whole/repository/installer-config/images_watermark_png.png
/home/horeb/QtIFWTest/1.0.0_whole/repository/installer-config/config.xml
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/license.txt
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/errorpage.ui
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/installscript.qs
/home/horeb/QtIFWTest/1.0.0_whole/repository/Updates.xml
/home/horeb/QtIFWTest/1.0.0_whole/repository/rccprojectMlaHaP.qrc
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/1.0.0meta.7z
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/1.0.0payload.7z
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/1.0.0payload.7z.sha1
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/1.0.0content.7z
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1/1.0.0content.7z.sha1
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/1.0.0meta.7z
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/1.0.0content.7z
/home/horeb/QtIFWTest/1.0.0_whole/repository/com.vendor.root.component1.subcomponent1/1.0.0content.7z.sha1
编写维护工具。

安装已完成!
```

手动解压性能测试：
```txt
◎ START=$(date +%s)                 □ com.vendor.root.component1/data⎪●◦⎥ 09:13
7z x payload.7z -o./manual_extract/
END=$(date +%s)
echo "Manual extraction took $((END-START)) seconds"


7-Zip 23.01 (x64) : Copyright (c) 1999-2023 Igor Pavlov : 2023-06-20
 64-bit locale=zh_CN.UTF-8 Threads:16 OPEN_MAX:2048

Scanning the drive for archives:
1 file, 2701388945 bytes (2577 MiB)

Extracting archive: payload.7z
--
Path = payload.7z
Type = 7z
Physical Size = 2701388945
Headers Size = 2325
Method = LZMA2:25
Solid = +
Blocks = 1

Everything is Ok

Folders: 9
Files: 87
Size:       2709077231
Compressed: 2701388945
Manual extraction took 3 seconds
```

花费时间3s。

---

### [补充] ini 文件解析

一个`TestMaintenanceTool.ini`的案例如下：

```ini
[General]
DefaultRepositories="@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0$aHR0cDovL2xvY2FsaG9zdDo4MDkwL3JlcG8=\x1\0\0\0\0\0\0\0\0\0\0\0\0 5pys5Zyw5rWL6K+V5LuT5bqTKE1pbnQp\0\0\0\0\0\0\0\0\0)", "@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0\x34\x61HR0cDovL2xvY2FsaG9zdDo4MDkwL3JlcG8vcmVwby0xLjEuMA==\x1\0\0\0\0\0\0\0\0\0\0\0\0(5pys5Zyw5rWL6K+V5LuT5bqTKE1pbnQpLTEuMS4w\0\0\0\0\0\0\0\0\0)", "@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0\x34\x61HR0cDovL2xvY2FsaG9zdDo4MDkxL3JlcG8vcmVwby0xLjMuMC8=\x1\x1\0\0\0\x4\x64HI=\0\0\0\bMTIzNDU2\0\0\0(5pys5Zyw5rWL6K+V5LuT5bqTKE1pbnQpLTEuMy4w\0\0\0\0\0\0\0\0\0)", "@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0(aHR0cDovLzE3Mi4xNi4yMC4xNTo4MDkwL3JlcG8=\x1\0\0\0\0\0\0\0\0\0\0\0\0$5bGA5Z+f572R5rWL6K+V5LuT5bqTKERFTEwp\0\0\0\0\0\0\0\0\0)", "@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0\x34\x61HR0cDovL2xvY2FsaG9zdDo4MDkwL3JlcG8vcmVwby0xLjIuMA==\x1\0\0\0\0\0\0\0\0\0\0\0\0(5pys5Zyw5rWL6K+V5LuT5bqTKE1pbnQpLTEuMi4w\0\0\0\0\0\0\0\0\0)", "@Variant(\0\0\0\x7f\0\0\0\x17QInstaller::Repository\0\0\0\0\x34\x61HR0cDovL2xvY2FsaG9zdDo4MDkwL3JlcG8vcmVwby0xLjAuMA==\x1\x1\0\0\0\0\0\0\0\0\0\0\0(5pys5Zyw5rWL6K+V5LuT5bqTKE1pbnQpLTEuMC4w\0\0\0\0\0\0\0\0\0)"
FilesForDelayedDeletion=@Invalid()
Variables=@Variant(\0\0\0\x1c\0\0\0\x1b\0\0\0\x12\0T\0\x61\0r\0g\0\x65\0t\0\x44\0i\0r\0\0\0\n\0\0\0$\0@\0R\0\x45\0L\0O\0\x43\0\x41\0T\0\x41\0\x42\0L\0\x45\0_\0P\0\x41\0T\0H\0@\0\0\0\x4\0o\0s\0\0\0\n\0\0\0\x6\0x\0\x31\0\x31\0\0\0\x1e\0R\0\x65\0m\0o\0v\0\x65\0T\0\x61\0r\0g\0\x65\0t\0\x44\0i\0r\0\0\0\n\0\0\0\b\0t\0r\0u\0\x65\0\0\0\x18\0S\0t\0\x61\0r\0t\0M\0\x65\0n\0u\0\x44\0i\0r\0\0\0\n\0\0\0\x12\0Q\0t\0I\0\x46\0W\0T\0\x65\0s\0t\0\0\0\x1e\0\x41\0p\0p\0l\0i\0\x63\0\x61\0t\0i\0o\0n\0s\0\x44\0i\0r\0\0\0\n\0\0\0\b\0/\0o\0p\0t\0\0\0\xe\0r\0o\0o\0t\0\x44\0i\0r\0\0\0\n\0\0\0\x2\0/\0\0\0\f\0\x42\0\x61\0n\0n\0\x65\0r\0\0\0\n\xff\xff\xff\xff\0\0\0\x1e\0I\0\x46\0W\0_\0V\0\x45\0R\0S\0I\0O\0N\0_\0S\0T\0R\0\0\0\n\0\0\0\n\0\x34\0.\0\x38\0.\0\x31\0\0\0&\0\x41\0p\0p\0l\0i\0\x63\0\x61\0t\0i\0o\0n\0s\0\x44\0i\0r\0U\0s\0\x65\0r\0\0\0\n\0\0\0\b\0/\0o\0p\0t\0\0\0\x1c\0P\0r\0o\0\x64\0u\0\x63\0t\0V\0\x65\0r\0s\0i\0o\0n\0\0\0\n\0\0\0\n\0\x31\0.\0\x30\0.\0\x30\0\0\0\b\0L\0o\0g\0o\0\0\0\n\xff\xff\xff\xff\0\0\0$\0\x41\0p\0p\0l\0i\0\x63\0\x61\0t\0i\0o\0n\0s\0\x44\0i\0r\0X\0\x38\0\x36\0\0\0\n\0\0\0\b\0/\0o\0p\0t\0\0\0\x36\0i\0n\0s\0t\0\x61\0l\0l\0\x65\0\x64\0O\0p\0\x65\0r\0\x61\0t\0i\0o\0n\0\x41\0r\0\x65\0S\0o\0r\0t\0\x65\0\x64\0\0\0\n\0\0\0\b\0t\0r\0u\0\x65\0\0\0\xe\0R\0o\0o\0t\0\x44\0i\0r\0\0\0\n\0\0\0\x2\0/\0\0\0\xe\0h\0o\0m\0\x65\0\x44\0i\0r\0\0\0\n\0\0\0\x16\0/\0h\0o\0m\0\x65\0/\0h\0o\0r\0\x65\0\x62\0\0\0\x1c\0P\0\x61\0g\0\x65\0L\0i\0s\0t\0P\0i\0x\0m\0\x61\0p\0\0\0\n\xff\xff\xff\xff\0\0\0\x16\0P\0r\0o\0\x64\0u\0\x63\0t\0N\0\x61\0m\0\x65\0\0\0\n\0\0\0(\0Q\0t\0I\0\x46\0W\0 \0P\0\x61\0\x63\0k\0 \0T\0\x65\0s\0t\0 \0-\0 \0T\0R\0\0\0\x12\0P\0u\0\x62\0l\0i\0s\0h\0\x65\0r\0\0\0\n\0\0\0\x6_ y]s\x99\0\0\0\x12\0W\0\x61\0t\0\x65\0r\0m\0\x61\0r\0k\0\0\0\n\0\0\0h\0:\0/\0m\0\x65\0t\0\x61\0\x64\0\x61\0t\0\x61\0/\0i\0n\0s\0t\0\x61\0l\0l\0\x65\0r\0-\0\x63\0o\0n\0\x66\0i\0g\0/\0i\0m\0\x61\0g\0\x65\0s\0_\0w\0\x61\0t\0\x65\0r\0m\0\x61\0r\0k\0_\0p\0n\0g\0.\0p\0n\0g\0\0\0\xe\0H\0o\0m\0\x65\0\x44\0i\0r\0\0\0\n\0\0\0\x16\0/\0h\0o\0m\0\x65\0/\0h\0o\0r\0\x65\0\x62\0\0\0\x6\0U\0r\0l\0\0\0\n\0\0\0$\0h\0t\0t\0p\0s\0:\0/\0/\0w\0w\0w\0.\0q\0q\0.\0\x63\0o\0m\0\0\0\x14\0U\0I\0L\0\x61\0n\0g\0u\0\x61\0g\0\x65\0\0\0\n\0\0\0\n\0z\0h\0_\0\x43\0N\0\0\0\"\0I\0n\0s\0t\0\x61\0l\0l\0\x65\0r\0\x46\0i\0l\0\x65\0P\0\x61\0t\0h\0\0\0\n\0\0\0L\0@\0R\0\x45\0L\0O\0\x43\0\x41\0T\0\x41\0\x42\0L\0\x45\0_\0P\0\x41\0T\0H\0@\0/\0T\0\x65\0s\0t\0M\0\x61\0i\0n\0t\0\x65\0n\0\x61\0n\0\x63\0\x65\0T\0o\0o\0l\0\0\0$\0\x41\0p\0p\0l\0i\0\x63\0\x61\0t\0i\0o\0n\0s\0\x44\0i\0r\0X\0\x36\0\x34\0\0\0\n\0\0\0\b\0/\0o\0p\0t\0\0\0\n\0T\0i\0t\0l\0\x65\0\0\0\n\0\0\0&\0Q\0t\0I\0\x46\0W\0 mK\x8b\xd5[\x89\x88\xc5Vh\0 \0-\0 \0T\0i\0t\0l\0\x65\0\0\0 \0I\0n\0s\0t\0\x61\0l\0l\0\x65\0r\0\x44\0i\0r\0P\0\x61\0t\0h\0\0\0\n\0\0\0$\0@\0R\0\x45\0L\0O\0\x43\0\x41\0T\0\x41\0\x42\0L\0\x45\0_\0P\0\x41\0T\0H\0@\0\0\0 \0\x46\0r\0\x61\0m\0\x65\0w\0o\0r\0k\0V\0\x65\0r\0s\0i\0o\0n\0\0\0\n\0\0\0\n\0\x34\0.\0\x38\0.\0\x31)
```

> @Variant 是 Qt 中用于序列化（存储/传输）复杂数据的一种二进制格式，主要用于 `QVariant` 类型的对象。

使用`@Variant`格式存储二进制数据，混合包含Base64编码和明文配置。

