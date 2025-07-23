from fastapi import FastAPI, Request, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, DateTime
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, sessionmaker
from datetime import datetime
import logging

# ——— Logging setup ———
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# ——— FastAPI & Database setup ———
app = FastAPI()
DATABASE_URL = "postgresql://aso:aso@localhost:5432/logdb"
engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()

class Log(Base):
    __tablename__ = "logs"
    id          = Column(Integer, primary_key=True, index=True)
    timestamp   = Column(DateTime, nullable=False)  # now stamped by server
    count       = Column(String)
    seq         = Column(String, nullable=False)
    in_mac      = Column(String)
    out_mac     = Column(String)
    in_mac2     = Column(String)
    out_mac2    = Column(String)
    dir1        = Column(String)
    dir2        = Column(String)
    len1        = Column(String)
    proto1      = Column(String)
    len2        = Column(String)
    proto2      = Column(String)
    src1        = Column(String)
    dst1        = Column(String)
    src2        = Column(String)
    dst2        = Column(String)
    log_stage   = Column(String)
    kv_fields   = Column(JSONB)
    policy      = Column(String)
    session_id  = Column(String)
    description = Column(String)
    log_type    = Column(String)

Base.metadata.create_all(bind=engine)

@app.on_event("startup")
def on_startup():
    logging.info("🚀 FastAPI up and running on port 10000")

@app.post("/logs")
async def receive_logs(request: Request):
    try:
        payload = await request.json()
    except Exception as e:
        logging.error("Invalid JSON: %s", e)
        raise HTTPException(400, "Invalid JSON payload")

    entries = payload if isinstance(payload, list) else [payload]
    db = SessionLocal()
    inserted = skipped = errors = 0

    for entry in entries:
        logging.debug("Entry: %s", entry)
        if not entry.get("seq"):
            skipped += 1
            continue

        # Stamp with current server time
        ts = datetime.utcnow()

        try:
            log = Log(
                timestamp   = ts,
                count       = entry.get("count"),
                seq         = entry["seq"],
                in_mac      = entry.get("in_mac"),
                out_mac     = entry.get("out_mac"),
                in_mac2     = entry.get("in_mac2"),
                out_mac2    = entry.get("out_mac2"),
                dir1        = entry.get("dir1"),
                dir2        = entry.get("dir2"),
                len1        = entry.get("len1"),
                proto1      = entry.get("proto1"),
                len2        = entry.get("len2"),
                proto2      = entry.get("proto2"),
                src1        = entry.get("src1"),
                dst1        = entry.get("dst1"),
                src2        = entry.get("src2"),
                dst2        = entry.get("dst2"),
                log_stage   = entry.get("log_stage"),
                kv_fields   = entry.get("kv_fields") or {},
                policy      = entry.get("kv_fields", {}).get("POLNO"),
                session_id  = entry.get("kv_fields", {}).get("ID"),
                description = entry.get("kv_fields", {}).get("S"),
                log_type    = entry.get("kv_fields", {}).get("CacheFind"),
            )
            db.add(log)
            inserted += 1
        except Exception as e:
            errors += 1
            logging.error("Insert error: %s → %s", e, entry)

    if inserted:
        try:
            db.commit()
            logging.info("Inserted %d rows", inserted)
        except Exception as e:
            db.rollback()
            logging.error("DB commit failed: %s", e)
            raise HTTPException(500, "DB commit failed")
    db.close()
    return {"status":"ok","inserted":inserted,"skipped":skipped,"errors":errors}
