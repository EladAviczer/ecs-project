This project contains two Go-based microservices designed to communicate via AWS SQS and S3. \
It's built to run locally using Docker, with AWS resources deployed via the AWS CLI and setup automated via a `Makefile` or by using terraform for full provisioning based on needed variables.



Run `make all` will boot up the project. \
creating env files. \
building images. \
provision the needed AWS infrastructure. \
deploying the docker images


Prerequisites:
golang
docker
awscli
linux/MacOS to run the makefile (for the prompting part)

