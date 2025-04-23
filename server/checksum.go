/*
2025/04/17 --张祝玙
*/
package main

import (
	"crypto/sha1"
	"encoding/hex"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// GenerateSHA1For7zFiles 遍历指定目录，为 content.7z 文件生成 .sha1，忽略 -meta.7z 文件
func GenerateSHA1For7zFiles(root string) error {
	return filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// 只处理以 .7z 结尾的文件
		if !info.IsDir() && filepath.Ext(path) == ".7z" {
			filename := filepath.Base(path)

			// 跳过 -meta.7z 文件
			if strings.HasSuffix(filename, "-meta.7z") {
				return nil
			}

			// 打开 .7z 文件
			file, err := os.Open(path)
			if err != nil {
				return err
			}
			defer file.Close()

			// 计算 SHA1
			hasher := sha1.New()
			if _, err := io.Copy(hasher, file); err != nil {
				return err
			}
			sum := hex.EncodeToString(hasher.Sum(nil))

			// 写入 .sha1 文件（同路径）
			shaPath := path + ".sha1"
			err = os.WriteFile(shaPath, []byte(sum), 0644)
			if err != nil {
				return err
			}
		}
		return nil
	})
}
