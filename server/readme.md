Golang文件服务器原型，测试用。  
有`Updates.xml`以及`.7z`格式的组件提供下载。

`checksum.go`中有在服务端计算sha1和MD5校验和的工具函数。  
默认不调用，`repogen`工具已经含有在本地计算sha1校验和的功能。

运行：
```bash
go run .
```

---

`repogen`工具生成仓库结构如下：
```txt
repository/
├── Updates.xml                 # 仓库主索引文件
├── [componentname]/            # 每个组件有独立目录
│   ├── [version]/              # 每个版本的目录
│   │   ├── [archivename].7z    # 组件内容存档
│   │   └── [archivename].7z.sha1 # 内容校验和
│   └── [version]-meta.7z       # 组件元数据存档
└── components.xml              # 组件清单文件(可选)
```

示例：
```txt
repository/
├── Updates.xml
├── com.example.component1/
│   ├── 1.0.0/
│   │   ├── content.7z
│   │   └── content.7z.sha1
│   └── 1.0.0-meta.7z
├── com.example.component2/
│   ├── 2.1.0/
│   │   ├── content.7z
│   │   ├── content.7z.sha1
│   │   ├── resources.7z
│   │   └── resources.7z.sha1
│   └── 2.1.0-meta.7z
└── ...
```

每个`[version]-meta.7z`存档包含：
```txt
meta/
├── installscript.qs     # 安装脚本(如有)
├── *.qm                 # 翻译文件(如有)
├── *.ui                 # 自定义界面文件(如有)
├── license.txt          # 许可证文件(如有)
└── ...                  # 其他元数据
```