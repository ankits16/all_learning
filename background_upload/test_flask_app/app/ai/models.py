from app import db


class MachineAnalysis(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    media_uuid = db.Column(db.String(32), unique=True, nullable=False)
    analysis = db.Column(db.JSON, nullable=False)
