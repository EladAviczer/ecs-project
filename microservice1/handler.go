package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
)

type EmailData struct {
	EmailSubject    string `json:"email_subject"`
	EmailSender     string `json:"email_sender"`
	EmailTimestream string `json:"email_timestream"` // Validate this is a valid UNIX timestamp
	EmailContent    string `json:"email_content"`
}

type RequestPayload struct {
	Data  EmailData `json:"data"`
	Token string    `json:"token"`
}

func handlePost(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields() // Reject unexpected keys

	var payload RequestPayload
	if err := decoder.Decode(&payload); err != nil {
		http.Error(w, fmt.Sprintf("Invalid JSON: %v", err), http.StatusBadRequest)
		return
	}

	if payload.Token == "" {
		http.Error(w, "Missing token", http.StatusBadRequest)
		return
	}
	if !checkTokenCorrectness(token, payload.Token) {
		http.Error(w, "Unauthorized: invalid token", http.StatusUnauthorized)
		return
	}

	if payload.Data.EmailSubject == "" ||
		payload.Data.EmailSender == "" ||
		payload.Data.EmailTimestream == "" ||
		payload.Data.EmailContent == "" {
		http.Error(w, "All fields in 'data' must be present", http.StatusBadRequest)
		return
	}

	if _, err := strconv.ParseInt(payload.Data.EmailTimestream, 10, 64); err != nil {
		http.Error(w, "Invalid email_timestream, must be a UNIX timestamp string", http.StatusBadRequest)
		return
	}

	log.Printf("Valid payload received: %+v", payload)
	// publish message to sqs
	ctx := context.Background()
	if err := sendMessage(ctx, sqsClient, queueURL, payload.Data); err != nil {
		log.Fatalf("failed to send message: %v", err)
	}

	// Respond with success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Payload accepted",
	})
}
