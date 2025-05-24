# === CONFIG ===
REGION = us-west-1

MS1_DIR = microservice1
MS2_DIR = microservice2

MS1_IMAGE = ms1:latest
MS2_IMAGE = ms2:latest

MS1_ENV = ms1.env
MS2_ENV = ms2.env

# === DEFAULT FLOW ===
.PHONY: all
all: init-env build deploy-aws run

# === HELP ===
.PHONY: help
help:
	@echo "Commands:"
	@echo "  make                 - Run full flow: env → build → deploy → run"
	@echo "  make init-env        - Prompt user to create ms1.env and ms2.env"
	@echo "  make build           - Build Docker images"
	@echo "  make deploy-aws      - Create SQS queue and S3 bucket"
	@echo "  make run             - Run both microservices"
	@echo "  make run-ms1         - Run Microservice 1"
	@echo "  make run-ms2         - Run Microservice 2"
	@echo "  make clean           - Remove Docker images"

# === STEP 1: INIT ENV FILES WITH PROMPTING ===
.PHONY: init-env
init-env:
	@echo "Creating ms1.env..."
	@read -p "Enter TOKEN: " TOKEN; \
	 read -p "Enter AWS_ACCESS_KEY_ID: " KEY; \
	 read -p "Enter AWS_SECRET_ACCESS_KEY: " SECRET; \
	 read -p "Enter QUEUE_NAME: " QNAME; \
	 echo "TOKEN=$$TOKEN" > $(MS1_ENV); \
	 echo "AWS_REGION=$(REGION)" >> $(MS1_ENV); \
	 echo "AWS_ACCESS_KEY_ID=$$KEY" >> $(MS1_ENV); \
	 echo "AWS_SECRET_ACCESS_KEY=$$SECRET" >> $(MS1_ENV); \
	 echo "QUEUE_NAME=$$QNAME" >> $(MS1_ENV); \
	 echo "✅ ms1.env created."

	@echo "Creating ms2.env..."
	@read -p "Enter S3_BUCKET: " BUCKET; \
	 read -p "Enter AWS_ACCESS_KEY_ID: " KEY2; \
	 read -p "Enter AWS_SECRET_ACCESS_KEY: " SECRET2; \
	 read -p "Enter QUEUE_NAME: " QNAME2; \
	 echo "S3_BUCKET=$$BUCKET" > $(MS2_ENV); \
	 echo "AWS_REGION=$(REGION)" >> $(MS2_ENV); \
	 echo "AWS_ACCESS_KEY_ID=$$KEY2" >> $(MS2_ENV); \
	 echo "AWS_SECRET_ACCESS_KEY=$$SECRET2" >> $(MS2_ENV); \
	 echo "QUEUE_NAME=$$QNAME2" >> $(MS2_ENV); \
	 echo "✅ ms2.env created."

# === STEP 2: BUILD IMAGES ===
.PHONY: build
build:
	docker build -t $(MS1_IMAGE) $(MS1_DIR)
	docker build -t $(MS2_IMAGE) $(MS2_DIR)

# === STEP 3: DEPLOY AWS RESOURCES ===
.PHONY: deploy-aws
deploy-aws:
	@echo "Creating SQS Queue..."
	aws sqs create-queue --queue-name $$(grep QUEUE_NAME $(MS1_ENV) | cut -d '=' -f2) --region $(REGION)

	@echo "Creating S3 Bucket..."
	aws s3api create-bucket --bucket $$(grep S3_BUCKET $(MS2_ENV) | cut -d '=' -f2) \
		--region $(REGION) \
		--create-bucket-configuration LocationConstraint=$(REGION)

# === STEP 4: RUN MICROSERVICES ===
.PHONY: run
run: run-ms1 run-ms2

.PHONY: run-ms1
run-ms1:
	docker run --rm --env-file $(MS1_ENV) $(MS1_IMAGE)

.PHONY: run-ms2
run-ms2:
	docker run --rm --env-file $(MS2_ENV) $(MS2_IMAGE)

# === CLEANUP ===
.PHONY: clean
clean:
	docker rmi -f $(MS1_IMAGE) $(MS2_IMAGE) || true
