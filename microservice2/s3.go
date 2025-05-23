package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type BucketBasics struct {
	S3Client *s3.Client
}

func (basics BucketBasics) UploadMessageJSON(ctx context.Context, bucketName string, messageBody string) error {
	timestamp := time.Now().UnixMilli()
	objectKey := fmt.Sprintf("emails/%d.json", timestamp)
	log.Printf("Uploading to bucket: %s", bucketString)

	_, err := basics.S3Client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucketName),
		Key:         aws.String(objectKey),
		Body:        bytes.NewReader([]byte(messageBody)),
		ContentType: aws.String("application/json"),
	})
	if err != nil {
		log.Printf("Failed to upload message to %s/%s: %v\n", bucketName, objectKey, err)
		return err
	}

	err = s3.NewObjectExistsWaiter(basics.S3Client).Wait(
		ctx,
		&s3.HeadObjectInput{Bucket: aws.String(bucketName), Key: aws.String(objectKey)},
		time.Minute,
	)
	if err != nil {
		log.Printf("Failed to wait for object %s to exist in bucket %s\n", objectKey, bucketName)
	}
	return err
}
