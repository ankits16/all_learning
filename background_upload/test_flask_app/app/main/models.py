import uuid

from app import db


class MediaCollection(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ns_id = db.Column(
        db.String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4())
    )
    name = db.Column(db.String(100), nullable=False)
    state = db.Column(
        db.String(50), nullable=False, default="created"
    )  # 'created', 'media_items_uploaded', 'published'
    media_items = db.relationship("MediaItem", backref="collection", lazy=True)


class MediaItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    ns_id = db.Column(
        db.String(36), unique=True, nullable=False, default=lambda: str(uuid.uuid4())
    )
    name = db.Column(db.String(100), nullable=False)
    path = db.Column(db.String(200), nullable=True)
    type = db.Column(db.String(50), nullable=False)  # 'image', 'video', 'pdf'
    state = db.Column(
        db.String(50), nullable=False, default="created"
    )  # 'created', 'uploaded', 'failed'
    collection_id = db.Column(
        db.Integer, db.ForeignKey("media_collection.id"), nullable=False
    )
