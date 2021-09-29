package main

import (
	"fmt"
	"net/http"
	"os"
)

var(
	mySecret = os.Getenv("APP_SECRET")
)

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":80", nil)
}

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Secret from keyvault: %s", mySecret)
}