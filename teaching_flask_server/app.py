from __future__ import annotations

from flask import Flask

from config import Config
from db import init_app as init_db


def create_app(test_config: dict | None = None) -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)
    if test_config:
        app.config.update(test_config)

    init_db(app)

    from blueprints import admin, auth, bookings, common, courses, leaves, notifications, profile, schedule_changes

    app.register_blueprint(auth.bp)
    app.register_blueprint(profile.bp)
    app.register_blueprint(common.bp)
    app.register_blueprint(notifications.bp)
    app.register_blueprint(courses.bp)
    app.register_blueprint(bookings.bp)
    app.register_blueprint(leaves.bp)
    app.register_blueprint(schedule_changes.bp)
    app.register_blueprint(admin.bp)

    @app.after_request
    def add_headers(response):
        response.headers["Access-Control-Allow-Origin"] = "*"
        response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
        return response

    @app.get("/api/health")
    def health():
        return {"code": 0, "message": "success", "data": {"status": "UP"}}

    return app


if __name__ == "__main__":
    create_app().run(host="0.0.0.0", port=8080, debug=True)
