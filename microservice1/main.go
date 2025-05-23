package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/smithy-go"
)

var (
	token     string
	queueName string
	queueURL  string
	sqsClient *sqs.Client
)

func init() {
	token = os.Getenv("TOKEN")
	if token == "" {
		log.Fatal("Missing required environment variable: TOKEN")
	}
	queueName = os.Getenv("QUEUE_NAME")
	if queueName == "" {
		log.Fatal("Missing required environment variable: QUEUE_NAME")
	}

	ctx := context.Background()

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("failed to load AWS config: %v", err)
	}

	sqsClient = sqs.NewFromConfig(cfg)

	urlOutput, err := sqsClient.GetQueueUrl(ctx, &sqs.GetQueueUrlInput{
		QueueName: aws.String(queueName),
	})

	if err != nil {
		var apiErr smithy.APIError
		if errors.As(err, &apiErr) && apiErr.ErrorCode() == "AWS.SimpleQueueService.NonExistentQueue" {
			log.Fatalf("queue %s does not exist", queueName)
		}
		log.Fatalf("failed to get queue URL: %v", err)
	}

	queueURL = *urlOutput.QueueUrl
	fmt.Printf("Queue exists. URL: %s\n", queueURL)

}

func main() {

	http.HandleFunc("/submit", handlePost)
	fmt.Println("Server listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))

}
