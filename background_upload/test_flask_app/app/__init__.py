import os

from flask import Flask
from flask_sqlalchemy import SQLAlchemy

from app.config import Config

db = SQLAlchemy()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    with app.app_context():
        from .ai import routes as ai_routes
        from .main import routes as main_routes

        app.register_blueprint(main_routes.bp)
        app.register_blueprint(ai_routes.bp)
        db.create_all()  # Ensure the database is created

    return app
