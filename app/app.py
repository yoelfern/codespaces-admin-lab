import os
import time
from datetime import datetime, timezone

from flask import Flask, jsonify
import psycopg2
import redis

app = Flask(__name__)

DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://lab:lab@db:5432/labdb",
)
REDIS_URL = os.environ.get("REDIS_URL", "redis://redis:6379/0")
APP_MESSAGE = os.environ.get("APP_MESSAGE", "Laboratorio de Codespaces")
LAB_SECRET = os.environ.get("LAB_SECRET", "")


def db_connection():
    return psycopg2.connect(DATABASE_URL)


def redis_connection():
    return redis.Redis.from_url(REDIS_URL, decode_responses=True)


def initialize_database() -> None:
    last_error = None
    for _ in range(30):
        try:
            with db_connection() as connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        CREATE TABLE IF NOT EXISTS page_views (
                            id BIGSERIAL PRIMARY KEY,
                            viewed_at TIMESTAMPTZ NOT NULL,
                            source TEXT NOT NULL
                        )
                        """
                    )
            return
        except Exception as exc:  # El arranque depende de otro contenedor.
            last_error = exc
            time.sleep(2)
    raise RuntimeError(f"No fue posible inicializar PostgreSQL: {last_error}")


initialize_database()


@app.get("/")
def index():
    viewed_at = datetime.now(timezone.utc)
    cache = redis_connection()
    redis_visits = cache.incr("visits")

    with db_connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO page_views (viewed_at, source) VALUES (%s, %s)",
                (viewed_at, "web"),
            )
            cursor.execute("SELECT COUNT(*) FROM page_views")
            db_visits = cursor.fetchone()[0]

    return jsonify(
        message=APP_MESSAGE,
        redis_visits=redis_visits,
        database_rows=db_visits,
        secret_loaded=bool(LAB_SECRET),
        timestamp=viewed_at.isoformat(),
    )


@app.get("/health")
def health():
    try:
        with db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.fetchone()
        redis_connection().ping()
    except Exception as exc:
        return jsonify(status="unhealthy", error=str(exc)), 503

    return jsonify(status="healthy")


@app.get("/environment")
def environment():
    return jsonify(
        lab_environment=os.environ.get("LAB_ENVIRONMENT", "not-set"),
        hostname=os.uname().nodename,
        secret_loaded=bool(LAB_SECRET),
    )
