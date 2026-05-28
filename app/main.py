import logging
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

# Enterprise logging configuration for cloud native observability
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("ml-inference-api")

app = FastAPI(
    title="Secure ML Inference API",
    description="A secure, hardened serverless inference endpoint template.",
    version="1.0.0"
)

# Strict Pydantic validation schema to block malformed or oversized payloads
class InferenceRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000, description="The input text payload to analyze.")

class InferenceResponse(BaseModel):
    input_text: str
    prediction: str
    confidence: float

# Liveness/Health Probe (Mandatory for Cloud Run, GKE Load Balancers, and automated recovery)
@app.get("/health", status_code=status.HTTP_200_OK, tags=["Infrastructure"])
def health_check():
    logger.info("Platform health check triggered.")
    return {"status": "healthy", "service": "ml-inference-api"}

# Mock Prediction Endpoint (Simulating an NLP Classification Model Workload)
@app.post("/predict", response_model=InferenceResponse, status_code=status.HTTP_200_OK, tags=["Machine Learning"])
def predict(payload: InferenceRequest):
    logger.info("Processing incoming payload for inference.")
    
    try:
        input_lower = payload.text.lower()
        if "security" in input_lower or "lockdown" in input_lower or "perimeter" in input_lower:
            prediction = "SecOps / Cloud Security Focus"
            confidence = 0.94
        elif "mlops" in input_lower or "pipeline" in input_lower:
            prediction = "Platform Engineering Focus"
            confidence = 0.89
        else:
            prediction = "General Cloud Infrastructure"
            confidence = 0.75
            
        logger.info(f"Inference complete. Output category: {prediction}")
        return InferenceResponse(
            input_text=payload.text,
            prediction=prediction,
            confidence=confidence
        )
        
    except Exception as e:
        logger.error(f"Internal processing failure: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred while processing the machine learning model workload."
        )
        