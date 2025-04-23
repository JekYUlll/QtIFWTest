/*
2025/04/17 --张祝玙
*/
package main

import (
	"crypto/md5"
	"crypto/sha1"
	"encoding/hex"
	"io"
	"os"
	"path/filepath"
	"strings"
)

// GenerateSHA1ForFiles 遍历指定目录，生成 .sha1，忽略 -meta.7z 文件
func GenerateSHA1ForFiles(root string) error {
	return filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// if !info.IsDir() && filepath.Ext(path) == ".7z" {
		if !info.IsDir() && filepath.Ext(path) != ".sha1" && filepath.Ext(path) != ".md5" {
			filename := filepath.Base(path)

			// 跳过 -meta.7z 文件
			if strings.HasSuffix(filename, "-meta.7z") {
				return nil
			}

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

// GenerateMD5ForFiles 遍历指定目录，生成 .md5，忽略 -meta.7z 文件
func GenerateMD5ForFiles(root string) error {
	return filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && filepath.Ext(path) != ".sha1" && filepath.Ext(path) != ".md5" {
			filename := filepath.Base(path)

			// 跳过 -meta.7z 文件
			if strings.HasSuffix(filename, "-meta.7z") {
				return nil
			}

			file, err := os.Open(path)
			if err != nil {
				return err
			}
			defer file.Close()

			// 计算 MD5
			hasher := md5.New()
			if _, err := io.Copy(hasher, file); err != nil {
				return err
			}
			sum := hex.EncodeToString(hasher.Sum(nil))

			// 写入 .md5 文件（同路径）
			md5Path := path + ".md5"
			err = os.WriteFile(md5Path, []byte(sum), 0644)
			if err != nil {
				return err
			}
		}
		return nil
	})
}
