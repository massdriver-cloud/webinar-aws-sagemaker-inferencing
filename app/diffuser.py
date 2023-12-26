import base64
import datetime
import hashlib
import io
import json
import re
from typing import List


# Specific imports for SageMaker
from sagemaker.predictor import Predictor
from sagemaker.serializers import JSONSerializer
from sagemaker.deserializers import BytesDeserializer

from pydantic import BaseModel

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

def get_diffuser_predictor(diffuser_endpoint_name, sess):
    # Define the predictor (this could also be done inside the endpoint call for a fresh setup each time)
    diffuser_model_predictor = Predictor(
        endpoint_name=diffuser_endpoint_name, 
        sagemaker_session=sess,
        serializer=JSONSerializer(),
        deserializer=BytesDeserializer()
    )


def generate_image(payload: ImageGenerationPayload, s3_bucket: str, diffuser_model_predictor: Predictor):
    # Convert the Pydantic model to a dictionary
    diffuser_payload = payload.dict(by_alias=True)
    
    # Get prediction from SageMaker endpoint
    diffuser_response = diffuser_model_predictor.predict(diffuser_payload)
    prompt = diffuser_payload.get('text_prompts', [{}])[0].get('text', 'image')
    # Decode the response and return the image
    filename = sanitize_filename(prompt)
    return decode_and_show(diffuser_response, s3_bucket, 'images/'+filename)


def sanitize_filename(text):
    # Remove non-alphanumeric characters
    text = re.sub(r'[^a-zA-Z0-9 ]', '', text)
    # Replace spaces with underscores
    text = text.replace(' ', '_')
    # Shorten the text if it's too long
    safe_prompt = (text[:10] + '..') if len(text) > 10 else text
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    hash_part = hashlib.md5(text.encode()).hexdigest()[:6]
    filename = f"{safe_prompt}_{timestamp}_{hash_part}.png"
    return filename


def decode_and_show(response_bytes, s3_bucket, s3_key):
    # Parse the JSON response to get the base64-encoded string
    response_json = json.loads(response_bytes)
    image_base64 = response_json['generated_image']

    # Decode the base64 string
    image_data = base64.b64decode(image_base64)

    # Create an in-memory bytes buffer for the image data
    img_io = io.BytesIO(image_data)
    
    # Upload to S3
    try:
        # Ensure we're at the start of the image buffer before uploading
        img_io.seek(0)
        s3_client.put_object(Bucket=s3_bucket, Key=s3_key, Body=img_io, ContentType='image/png')
        print(f"Image uploaded to S3: {s3_bucket}/{s3_key}")
    except BotoCoreError as e:
        print(f"Failed to upload image to S3: {e}")
        raise HTTPException(status_code=500, detail=str(e))

    # Generate the S3 URL for the uploaded image
    s3_url = f"https://{s3_bucket}.s3.amazonaws.com/{s3_key}"
    return {"url": s3_url}