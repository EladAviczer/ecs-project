package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/sqs"
	"github.com/aws/smithy-go"
)

var (
	queueName    string
	queueURL     string
	sqsClient    *sqs.Client
	bucketString string
)

func init() {
	queueName = os.Getenv("QUEUE_NAME")
	if queueName == "" {
		log.Fatal("Missing required environment variable: QUEUE_NAME")
	}
	bucketString = os.Getenv("S3_BUCKET")
	if bucketString == "" {
		log.Fatal("Missing required environment variable: S3_BUCKET")
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
	ctx := context.Background()

	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		log.Fatalf("Unable to load SDK config: %v", err)
	}

	interval := 10 * time.Second

	s3Client := s3.NewFromConfig(cfg)
	bucketBasics := BucketBasics{S3Client: s3Client}

	sqsClient := sqs.NewFromConfig(cfg)
	sqsActions := SqsActions{SqsClient: sqsClient}

	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			log.Println("Fetching messages...")
			messages, err := sqsActions.GetMessages(ctx, queueURL, 5, 10)
			if err != nil {
				log.Println("Error fetching messages:", err)
				continue
			}
			for _, msg := range messages {
				log.Printf("Got message: %s\n", *msg.Body)

				err := bucketBasics.UploadMessageJSON(ctx, bucketString, *msg.Body)
				if err != nil {
					log.Printf("Upload failed, skipping delete for message: %s", *msg.MessageId)
					continue
				}

				err = sqsActions.DeleteMessage(ctx, queueURL, *msg.ReceiptHandle)
				if err != nil {
					log.Printf("Failed to delete message %s: %v", *msg.MessageId, err)
				} else {
					log.Printf("Successfully deleted message %s", *msg.MessageId)
				}

			}
		}
	}

}
