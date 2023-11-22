mass_push:
	mass image push massdriver/sagemaker_demo -a $ARTIFACT_ID -r us-east-1

run_local:
	docker build -t local-fast-api:latest -f local.Dockerfile .
	docker run -p 8000:80 -v $HOME/.aws/credentials:/root/.aws/credentials:ro -v $HOME/.aws/config:/root/.aws/config:ro -e AWS_PROFILE=md-sandbox local-fast-api:latest
