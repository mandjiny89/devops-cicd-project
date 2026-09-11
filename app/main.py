from fastapi import FastAPI
from prometheus_fastapi_instrumentator import Instrumentator
app = FastAPI(title="DevOps CI/CD Project")
Instrumentator().instrument(app).expose(app)
@app.get("/")
def root():
    return {"message": "DevOps CI/CD Project", "status": "running"}
@app.get("/health")
def health():
    return {"status": "healthy"}
