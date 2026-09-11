from fastapi.testclient import TestClient
from main import app
client = TestClient(app)
def test_root():
    r=client.get("/")
    assert r.status_code == 200 and r.json()["status"] == "running"
def test_health():
    r=client.get("/health")
    assert r.status_code == 200 and r.json() == {"status":"healthy"}
def test_metrics():
    assert client.get("/metrics").status_code == 200
