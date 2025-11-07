from fastapi import FastAPI, HTTPException, status
import uvicorn
from pydantic import BaseModel


app = FastAPI(title="Cloud Compute API")


class HelloRequest(BaseModel):
    name: str


class HelloResponse(BaseModel):
    message: str



@app.get("/")
async def read_root():
    return {"message": "Cloud Compute API is running"}


@app.post("/api/hello", response_model=HelloResponse)
async def hello_api(payload: HelloRequest):
    name = payload.name.strip()
    if not name:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Name must not be empty",
        )
    return HelloResponse(message=f"Hello, {name}!")


if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)

