# ——— Import required libraries ———
from fastapi import FastAPI, Request, HTTPException             # FastAPI for creating REST API
from sqlalchemy import create_engine, Column, Integer, String, DateTime  # SQLAlchemy for database ORM
from sqlalchemy.orm import declarative_base, sessionmaker       # ORM base and session maker
from datetime import datetime                                   # Timestamping logs
import logging                                                  # For internal logging
import os                                                       # To access environment variables
from dotenv import load_dotenv                                  # Load variables from .env file

# ——— Load environment variables from .env file ———
load_dotenv()

# ——— Read the database URL from environment variables ———
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("❌ DATABASE_URL is not set in .env or environment variables.")

# ——— Set up basic logging configuration ———
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# ——— Initialize FastAPI application ———
app = FastAPI()

# ——— Set up PostgreSQL connection and ORM base ———
engine = create_engine(DATABASE_URL, pool_pre_ping=True)         # Create database engine
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)  # DB session factory
Base = declarative_base()                                        # Base class for ORM models

# ——— Define the log table model ———
class Log(Base):
    __tablename__ = "logs"

    id          = Column(Integer, primary_key=True, index=True)  # Auto-incremented primary key
    timestamp   = Column(DateTime, nullable=False)               # Timestamp (UTC)
    in_mac      = Column(String)                                 # Incoming MAC address
    out_mac     = Column(String)                                 # Outgoing MAC address
    direction   = Column(String)                                 # Traffic direction (in/out)
    length      = Column(Integer)                                # Packet length
    protocol    = Column(Integer)                                # Protocol type (e.g., TCP = 6)
    src_ip      = Column(String)                                 # Source IP
    dst_ip      = Column(String)                                 # Destination IP
    src_port    = Column(Integer)                                # Source port
    dst_port    = Column(Integer)                                # Destination port
    description = Column(String)                                 # Optional description or detail

# ——— Automatically create the table if it doesn't exist ———
Base.metadata.create_all(bind=engine)

# ——— Event hook: runs on FastAPI startup ———
@app.on_event("startup")
def on_startup():
    logging.info("🚀 FastAPI server started on port 10000")

# ——— Endpoint to receive logs via HTTP POST ———
@app.post("/logs")
async def receive_logs(request: Request):
    try:
        # Parse incoming JSON payload
        payload = await request.json()
    except Exception as e:
        logging.error("Invalid JSON: %s", e)
        raise HTTPException(400, "Invalid JSON payload")

    # Ensure it's a list of log entries
    entries = payload if isinstance(payload, list) else [payload]

    # Open a new DB session
    db = SessionLocal()
    inserted = skipped = errors = 0

    for entry in entries:
        logging.debug("Processing entry: %s", entry)
        ts = datetime.utcnow()

        # Optional: skip entries missing critical fields
        required_fields = ["in_mac", "out_mac", "dir", "len", "proto", "src_ip", "dst_ip", "src_port", "dst_port"]
        if not all(entry.get(field) is not None for field in required_fields):
            skipped += 1
            logging.warning("❗ Skipped incomplete log entry: %s", entry)
            continue

        try:
            # Create a Log object from the entry
            log = Log(
                timestamp   = ts,
                in_mac      = entry.get("in_mac"),
                out_mac     = entry.get("out_mac"),
                direction   = entry.get("dir"),
                length      = entry.get("len"),
                protocol    = entry.get("proto"),
                src_ip      = entry.get("src_ip"),
                dst_ip      = entry.get("dst_ip"),
                src_port    = entry.get("src_port"),
                dst_port    = entry.get("dst_port"),
                description = str(entry.get("description") or "")  # Convert to string to avoid type errors
            )
            db.add(log)
            inserted += 1
        except Exception as e:
            errors += 1
            logging.error("⚠️ Error inserting entry: %s → %s", e, entry)

    # Commit all successful inserts
    if inserted:
        try:
            db.commit()
            logging.info("✅ Inserted %d rows", inserted)
        except Exception as e:
            db.rollback()
            logging.error("❌ Database commit failed: %s", e)
            raise HTTPException(500, "Database commit failed")

    # Always close DB session
    db.close()

    # Return operation summary
    return {
        "status": "ok",
        "inserted": inserted,
        "skipped": skipped,
        "errors": errors
    }
