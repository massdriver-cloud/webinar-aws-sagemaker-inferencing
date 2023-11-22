FROM python:3.10

WORKDIR /app

ENV SDXL_ENDPOINT_NAME=neuro-dev-sdxl-w8kx-endpoint
ENV LLM_ENDPOINT_NAME=neuro-dev-mistral-7bqp-endpoint
ENV S3_BUCKET=neuro-dev-awss3applica-xmb1

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the .env file and the rest of your application's code
COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]