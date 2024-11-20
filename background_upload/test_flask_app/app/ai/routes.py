import uuid

from flask import Blueprint, jsonify, request

from app import db

from .models import MachineAnalysis

bp = Blueprint("ai", __name__, url_prefix="/ai")


@bp.route("/analyze", methods=["POST"])
def analyze():
    data = request.get_json()
    if not data or "file_path" not in data:
        return jsonify({"error": "No file path provided"}), 400

    file_path = data["file_path"]

    # Perform analysis (mocked for simplicity)
    analysis_result = {"example_key": "example_value"}

    new_analysis = MachineAnalysis(
        media_uuid=uuid.uuid4().hex, analysis=analysis_result
    )

    db.session.add(new_analysis)
    db.session.commit()

    return jsonify({"message": "Analysis completed", "analysis": analysis_result}), 201
