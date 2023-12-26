import os
from fastapi import FastAPI, HTTPException, File, UploadFile
from pydantic import BaseModel
from fastapi.responses import StreamingResponse, PlainTextResponse
from mangum import Mangum
import boto3
from botocore.exceptions import NoCredentialsError
import llm

from datetime import datetime
import hashlib
import base64
import io
from PIL import Image
import re

# Specific imports for SageMaker
from sagemaker.predictor import Predictor
from sagemaker.serializers import JSONSerializer
from sagemaker.deserializers import BytesDeserializer, JSONDeserializer

import sagemaker
import json
from typing import List

class TextPrompt(BaseModel):
    text: str

class ImageGenerationPayload(BaseModel):
    text_prompts: List[TextPrompt]
    width: int = 1024
    height: int = 1024
    sampler: str
    cfg_scale: float
    steps: int
    seed: int
    use_refiner: bool
    refiner_steps: int
    refiner_strength: float

# The `decode_and_show` function remains the same as previously defined
class DownloadFileBody(BaseModel):
    bucket_name: str
    file_name: str

class SimplePromptRequest(BaseModel):
    prompt: str

# Default values
DEFAULT_CONTENT_TYPE = "application/json"
DEFAULT_HISTORY = [
]
DEFAULT_SYSTEM_PROMPT = "You are an expert in the field of cloud computing and will give helpful answers to questions about AWS."
DEFAULT_PARAMETERS = {
    "do_sample": True,
    "top_p": 0.9,
    "temperature": 0.8,
    "max_new_tokens": 512,
    "repetition_penalty": 1.03,
    "stop": ["###", "</s>"]
}

# Assume other necessary imports are already done

app = FastAPI()

# Initialize SageMaker session and predictor
sess = sagemaker.Session()
sdxl_endpoint_name = os.environ.get("SDXL_ENDPOINT_NAME", "endpoint-name-not-set")
llm_endpoint_name = os.environ.get("LLM_ENDPOINT_NAME", "endpoint-name-not-set")
s3_bucket = os.environ.get("S3_BUCKET", "s3-bucket-not-set")


# Define the predictor (this could also be done inside the endpoint call for a fresh setup each time)
sdxl_model_predictor = Predictor(
    endpoint_name=sdxl_endpoint_name, 
    sagemaker_session=sess,
    serializer=JSONSerializer(),
    deserializer=BytesDeserializer()
)

# Create a SageMaker client
smr = boto3.client('sagemaker-runtime')

s3_client = boto3.client('s3')

app = FastAPI()


@app.post("/generate-text")
async def prompt_mistral(request_data: SimplePromptRequest):
    """
    FastAPI endpoint to generate responses using Mistral.
    """
    try:
        llm_predictor = llm.get_llm_predictor(llm_endpoint_name, sess)
    
        return llm.generate_llm_response(request_data.prompt, llm_predictor)
    except HTTPException as http_exception:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing the request: {str(e)}")


@app.post("/generate-image")
async def generate_image(payload: ImageGenerationPayload):
    try:
        # Convert the Pydantic model to a dictionary
        sdxl_payload = payload.dict(by_alias=True)
        
        # Get prediction from SageMaker endpoint
        sdxl_response = sdxl_model_predictor.predict(sdxl_payload)
        prompt = sdxl_payload.get('text_prompts', [{}])[0].get('text', 'image')
        # Decode the response and return the image
        filename = sanitize_filename(prompt)
        return decode_and_show(sdxl_response, s3_bucket, 'images/'+filename)
    except Exception as e:
        # Handle general exceptions
        raise HTTPException(status_code=500, detail=str(e))

if os.getenv('AWS_EXECUTION_ENV') is not None:
    handler = Mangum(app)
else:
    handler = app
