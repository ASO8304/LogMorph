# ——— Import required libraries ———
from fastapi import FastAPI, Request, HTTPException           # FastAPI for creating REST API
from sqlalchemy import create_engine, Column, Integer, String, DateTime  # SQLAlchemy for database ORM
from sqlalchemy.dialects.postgresql import JSONB             # PostgreSQL-specific JSONB type (not used here)
from sqlalchemy.orm import declarative_base, sessionmaker    # SQLAlchemy base and session
from datetime import datetime                                # Used for timestamping logs
import logging                                                # For logging events and errors

# ——— Set up basic logging configuration ———
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# ——— Initialize FastAPI application ———
app = FastAPI()

# ——— PostgreSQL database connection setup ———
DATABASE_URL = "postgresql://aso:aso@localhost:5432/logdb"
engine = create_engine(DATABASE_URL, pool_pre_ping=True)     # Create connection engine with ping check
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)  # Session for DB interaction
Base = declarative_base()                                    # Base class for ORM models

# ——— Define log table model ———
class Log(Base):
    __tablename__ = "logs"

    id              = Column(Integer, primary_key=True, index=True)   # Primary key
    timestamp       = Column(DateTime, nullable=False)                # Server-side timestamp
    in_mac          = Column(String)                                  # Incoming MAC address
    out_mac         = Column(String)                                  # Outgoing MAC address
    direction       = Column(String)                                  # Direction of traffic (in/out)
    length          = Column(Integer)                                 # Packet length
    protocol        = Column(Integer)                                 # Protocol ID (e.g., TCP=6, UDP=17)
    src_ip          = Column(String)                                  # Source IP address
    dst_ip          = Column(String)                                  # Destination IP address
    src_port        = Column(Integer)                                 # Source port number
    dst_port        = Column(Integer)                                 # Destination port number
    description     = Column(String)                                  # Optional description field

# ——— Create the logs table in the database (if it doesn’t exist) ———
Base.metadata.create_all(bind=engine)

# ——— Event hook for application startup ———
@app.on_event("startup")
def on_startup():
    logging.info("🚀 FastAPI up and running on port 10000")

# ——— Endpoint for receiving log data ———
@app.post("/logs")
async def receive_logs(request: Request):
    try:
        # Try to parse the JSON payload from the incoming HTTP request
        payload = await request.json()
    except Exception as e:
        logging.error("Invalid JSON: %s", e)
        raise HTTPException(400, "Invalid JSON payload")  # Respond with 400 if JSON is malformed

    # Ensure entries is a list of log objects
    entries = payload if isinstance(payload, list) else [payload]

    # Start a new database session
    db = SessionLocal()
    inserted = skipped = errors = 0  # Counters for reporting

    # Process each entry in the list
    for entry in entries:
        logging.debug("Entry: %s", entry)

        # Timestamp the entry with server's current UTC time
        ts = datetime.utcnow()

        try:
            # Map log fields from the incoming JSON
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
                description = entry.get("description") or {}
            )
            db.add(log)      # Add the log object to session
            inserted += 1
        except Exception as e:
            errors += 1
            logging.error("Insert error: %s → %s", e, entry)

    # Attempt to commit all inserted logs to the database
    if inserted:
        try:
            db.commit()
            logging.info("Inserted %d rows", inserted)
        except Exception as e:
            db.rollback()  # Roll back if commit fails
            logging.error("DB commit failed: %s", e)
            raise HTTPException(500, "DB commit failed")

    db.close()  # Always close DB session

    # Return the final result as JSON
    return {"status": "ok", "inserted": inserted, "skipped": skipped, "errors": errors}
