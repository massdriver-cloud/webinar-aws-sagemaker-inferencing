# SageMaker Demo

## Bundles Used:
- AWS VPC
- API Gateway
- S3 Bucket
- SageMaker Inference Endpoint (x2)
- Lambda
- SageMaker Domain

## Demo Values

### SDXL
For [SDXL 1.0](https://stablediffusionxl.com) we're using SageMaker's JumpStart model data along with [AWS's Deep Learning Container (DLC)](https://github.com/aws/deep-learning-containers/blob/master/available_images.md).
- Initial Instance Count: 1
- SageMaker Instance Type: ml.g5.4xlarge ($2.03/hr)
- ECR URL: 763104351884.dkr.ecr.us-east-1.amazonaws.com/stabilityai-pytorch-inference:2.0.1-sgm0.1.0-gpu-py310-cu118-ubuntu20.04-sagemaker
- Model Data S3 URL: s3://jumpstart-cache-prod-us-east-1/stabilityai-infer/prepack/v1.0.1/infer-prepack-model-imagegeneration-stabilityai-stable-diffusion-xl-base-1-0.tar.gz

### Mistral

Trained with https://github.com/philschmid/llm-sagemaker-sample

For [Mistral 7B](https://mistral.ai/news/announcing-mistral-7b/) we've downloaded the weights
  - Initial Instance Count: 1
  - SageMaker Instance Type: ml.g5.4xlarge ($2.03/hr)
  - ERC URL: 763104351884.dkr.ecr.us-east-1.amazonaws.com/huggingface-pytorch-tgi-inference:2.0.1-tgi1.1.0-gpu-py39-cu118-ubuntu20.04
  - Model Data: s3://neuro-dev-awss3applica-xmb1/model.tar.gz (trained via SageMaker Studio Notebook in Domain)

  | ENV VARS                    |                 |
  | ----------------------------- | -----------   |
  | HF_MODEL_ID                   | /opt/ml/model |
  | MAX_INPUT_LENGTH              | 1024          |
  | MAX_TOTAL_TOKENS              | 2048          |
  | SAGEMAKER_CONTAINER_LOG_LEVEL | 20            |
  | SAGEMAKER_REGION              | us-east-1     |
  | SM_NUM_GPUS                   | 1             |

### Lambda

In order to create a logic layer, we're going to create a Lambda that interacts with the SageMaker Endpoints via the SageMaker SDK
- Path: generate-image
- HTTP Method: POST
- Path: prompt-mistral
- HTTP Method: POST
- ECR URI: 083014189801.dkr.ecr.us-east-1.amazonaws.com/massdriver/sagemaker_demo
- ECR image tag: latest
- Runtime Memory Limit (MB): 1024
- Execution Timeout: 3 Minutes


### Set Lambda ENV VARS
| Key | Value |
|-------------------|----------------------------------|
|LLM_ENDPOINT_NAME  |	prefix-env-name-hash-endpoint |
|S3_BUCKET  |  prefix-env-name-hash |
|SDXL_ENDPOINT_NAME |	prefix-env-name-hash-endpoint |