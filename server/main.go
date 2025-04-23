/*
2025/04/17 --张祝玙
*/
package main

import (
	"log"
	"net/http"
)

func main() {

// 	err := GenerateSHA1For7zFiles("./static")
// 	if err != nil {
// 		log.Fatalf("生成 SHA1 校验和时出错: %v", err)
// 	}

	fs := http.StripPrefix("/repo", http.FileServer(http.Dir("./static")))
	http.Handle("/repo/", fs)

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/repo/", http.StatusFound) // 302 Temporary Redirect
	})

	log.Println("🚀 服务器运行中：http://localhost:8090")
	err := http.ListenAndServe("0.0.0.0:8090", nil)
	if err != nil {
		log.Fatal("服务器启动失败: ", err)
	}
}
