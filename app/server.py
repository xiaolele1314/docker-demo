import os
import json
from datetime import datetime
from flask import Flask, request, jsonify
import pymysql
import redis

app = Flask(__name__)

def get_db():
    return pymysql.connect(
        host=os.environ["MYSQL_HOST"],
        user=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        database=os.environ["MYSQL_DB"],
        cursorclass=pymysql.cursors.DictCursor,
    )

def get_redis():
    return redis.Redis(host=os.environ["REDIS_HOST"], port=6379, decode_responses=True)

@app.route("/api/health")
def health():
    status = {"mysql": "ok", "redis": "ok"}
    try:
        get_db().close()
    except Exception as e:
        status["mysql"] = str(e)
    try:
        get_redis().ping()
    except Exception as e:
        status["redis"] = str(e)
    return jsonify(status)

@app.route("/api/visit")
def visit():
    r = get_redis()
    count = r.incr("visit_count")

    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute(
                "INSERT INTO visitors (ip, path) VALUES (%s, %s)",
                (request.remote_addr, request.path),
            )
            db.commit()
            cur.execute("SELECT COUNT(*) AS total FROM visitors")
            db_total = cur.fetchone()["total"]
    finally:
        db.close()

    return jsonify({
        "redis_visit_count": count,
        "mysql_visitor_total": db_total,
        "time": datetime.now().isoformat(),
    })

@app.route("/api/visitors")
def visitors():
    db = get_db()
    try:
        with db.cursor() as cur:
            cur.execute("SELECT * FROM visitors ORDER BY id DESC LIMIT 20")
            rows = cur.fetchall()
    finally:
        db.close()

    for row in rows:
        if isinstance(row.get("visited_at"), datetime):
            row["visited_at"] = row["visited_at"].isoformat()
    return jsonify(rows)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
