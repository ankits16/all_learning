import os


class Config:
    UPLOAD_FOLDER = "uploads/"
    LOG_FOLDER = "logs/"
    SQLALCHEMY_DATABASE_URI = "sqlite:///site.db"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    if not os.path.exists(LOG_FOLDER):
        os.makedirs(LOG_FOLDER)

    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
