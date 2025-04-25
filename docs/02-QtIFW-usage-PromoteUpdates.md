# 推广更新

- [Promoting Updates](https://doc.qt.io/qtinstallerframework/ifw-updates.html)

1. 将更新的内容复制到包目录。
2. 增加 `package.xml` 文件中更新组件的 `<Version>` 元素的值。
3. 使用 `repogen` 工具重新创建具有更新内容的在线存储库，并在存储库的根目录中生成 `Updates.xml` 文件。
4. 将存储库上传到 Web 服务器。
5. 使用 `binarycreator` 工具创建安装程序。

安装程序在<u>启动时</u>会下载 `Updates.xml` 文件，并将已安装的版本与文件中的版本进行比较。  
如果文件中的在线版本号大于本地版本号，则安装程序会将其显示在可用更新列表中。

改变 `package.xml` 文件中组件的 `<Version>` 元素的值。

> `repogen` 每次调用时都会重新创建 `7zip` 存档。  
> 由于 `7zip` 会存储所包含文件（在此过程中移动或复制）的时间戳，因此每个存档的 `SHA` 值会发生变化。由于 `SHA` 值存储在 `Updates.xml` 文件中，因此必须上传完整的存储库。可以使用 `repogen` 的 `--update` 选项来避免这种情况。

## 更新存储库

在`Updates.xml`里的`<RepositoryUpdate>`添加标签。  

- 添加存储库：

```xml
<Repository action="add" url="http://www.example.com/repository" name="user" password="password"
             displayname="Example Repository" />
```

- 删除存储库：

```xml
<Repository action="remove" url="http://www.example.com/repository" />
```

- 替换存储库：

```xml
<Repository action="replace" oldUrl="http://www.example.com/repository"
            newUrl="http://www.example.com/newrepository" name="user" password="password"
            displayname="New Example Repository" />
```

