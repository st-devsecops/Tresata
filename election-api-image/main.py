import os
from fastapi import FastAPI
from redis import Redis

app = FastAPI(title="Election API – Secure Voting Demo")

redis = Redis(
    host=os.getenv("REDIS_HOST", "redis"),
    port=6379,
    db=0,
    decode_responses=True,
    socket_connect_timeout=5
)

@app.get("/")
def root():
    return {"status": "Election API is running!", "allowed_namespaces": ["ns-b", "ns-c"]}

@app.post("/vote/{candidate}")
def vote(candidate: str):
    count = redis.incr(candidate)
    return {"candidate": candidate, "total_votes": count}

@app.get("/results")
def results():
    keys = redis.keys("*")
    if not keys:
        return {"message": "No votes yet"}
    return {k: int(redis.get(k)) for k in keys}