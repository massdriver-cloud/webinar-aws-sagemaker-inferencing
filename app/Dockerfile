FROM public.ecr.aws/lambda/python:3.10
# Set environment variables

ENV SDXL_ENDPOINT_NAME=neuro-dev-sdxl-w8kx-endpoint
ENV LLM_ENDPOINT_NAME=neuro-dev-mistral-7bqp-endpoint
ENV S3_BUCKET=neuro-dev-awss3applica-xmb1

ADD requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install -r requirements.txt
ADD main.py ${LAMBDA_TASK_ROOT}
CMD ["main.handler"]
