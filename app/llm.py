import json
import sagemaker
from sagemaker.predictor import Predictor
from sagemaker.serializers import JSONSerializer
from sagemaker.deserializers import JSONDeserializer

def get_llm_predictor(llm_endpoint_name, sess):
    try:
        # Create a SageMaker predictor
        
        llm_predictor = Predictor(
            endpoint_name=llm_endpoint_name,
            sagemaker_session=sess,
            serializer=JSONSerializer(),
            deserializer=JSONDeserializer()
        )
        return llm_predictor
    except Exception as e:
        print(f"Error creating predictor: {str(e)}")
        raise


def generate_llm_response(prompt: str, llm_predictor: Predictor):
    try:
        messages = [
            {
                "role": "user",
                "content": prompt,
            }
        ]
        input_json = json.dumps(messages)
        # Prepare the input data
        input_data = {"inputs": input_json,
                    "parameters": DEFAULT_PARAMETERS}

        # Query the SageMaker endpoint
        response = llm_predictor.predict(input_data)


        return response
    except Exception as e:
        print(f"Error generating response: {str(e)}")
        raise