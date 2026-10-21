package main

import (
 "encoding/json"
 "log"
 "net/http"
 "os"
 "time"
)

func main() {
 if os.Getenv("EHR_DEV_MODE") != "1" { log.Fatal("production mode unsupported: security controls not implemented") }
 mux := http.NewServeMux()
 mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
  w.Header().Set("Content-Type", "application/json")
  _ = json.NewEncoder(w).Encode(map[string]string{"service":"ehrnow-operations","status":"ok"})
 })
 server := &http.Server{Addr:"127.0.0.1:8081", Handler:mux, ReadHeaderTimeout:5*time.Second, ReadTimeout:10*time.Second, WriteTimeout:10*time.Second}
 log.Println("Development operations service at 127.0.0.1:8081")
 log.Fatal(server.ListenAndServe())
}
