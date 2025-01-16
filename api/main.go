package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

type General struct {
	Message string `json:"message"`
}

func NewGeneral(message string) *General {
	return &General{Message: message}
}

func main() {

	r := mux.NewRouter()

	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"Content-Type", "Authorization"},
	})

	handler := c.Handler(r)

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, World!")
	}).Methods("GET")

	r.HandleFunc("/testapi", apiHandler).Methods("GET")

	log.Println("server start at port 8080")
	err := http.ListenAndServe(":8080", handler)
	if err != nil {
		log.Fatal(err)
	}
}

func apiHandler(w http.ResponseWriter, r *http.Request) {

	res := NewGeneral("Hello, World!@yamamoto desu")

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(res)
}
