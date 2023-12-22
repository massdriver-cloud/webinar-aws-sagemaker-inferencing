mass_push:
	cd app && mass image push massdriver/sagemaker_demo -a ${ARTIFACT_ID} -r us-east-1

mass_publish:
	cd lambda_bundle && mass bundle lint
	cd lambda_bundle && mass bundle build
	cd lambda_bundle/src && terraform init
	cd lambda_bundle/src && terraform validate
	cd lambda_bundle && mass bundle publish

run_local:
	docker build -t local-fast-api:latest -f local.Dockerfile .
	docker run -p 8000:80 -v ${HOME}/.aws/credentials:/root/.aws/credentials:ro -v ${HOME}/.aws/config:/root/.aws/config:ro -e AWS_PROFILE=md-sandbox local-fast-api:latest
