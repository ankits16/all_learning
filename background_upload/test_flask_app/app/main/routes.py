import os
import time

from flask import Blueprint, jsonify, request
from werkzeug.utils import secure_filename

from app.config import Config
from app.log import logger

from .models import MediaCollection, MediaItem, db

bp = Blueprint("main", __name__)


@bp.route("/")
def home():
    return "Welcome to the Video Upload API"


@bp.route("/upload", methods=["POST"])
def upload_video():
    logger.info("upload_video called")
    chunk_number = request.form.get("chunk", -100)
    logger.info(f"Received chunk = {chunk_number}")

    if "file" not in request.files:
        logger.error("No file part in request")
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        logger.error("No selected file")
        return jsonify({"error": "No selected file"}), 400

    if file:
        filename = secure_filename(file.filename)
        file_path = os.path.join(Config.UPLOAD_FOLDER, filename)
        try:
            with open(file_path, "ab") as f:
                f.write(file.read())
            time.sleep(2)  # Simulate processing time
            logger.info(f"Successfully uploaded chunk {chunk_number}")
            return jsonify(
                {"message": "File uploaded successfully", "file_path": file_path}
            ), 201
        except Exception as e:
            logger.error(f"Failed to save file: {e}")
            return jsonify({"error": "Failed to save file"}), 500


@bp.route("/log", methods=["POST"])
def log_event():
    data = request.get_json()
    if not data or "event" not in data:
        logger.error("No event data in request")
        return jsonify({"error": "No event data"}), 400

    event = data["event"]
    log_file_path = os.path.join(Config.LOG_FOLDER, "events.log")
    try:
        with open(log_file_path, "a") as log_file:
            log_file.write(event + "\n")
        logger.info(f"Event logged: {event}")
        return jsonify({"message": "Event logged successfully"}), 201
    except Exception as e:
        logger.error(f"Failed to log event: {e}")
        return jsonify({"error": "Failed to log event"}), 500


@bp.route("/generate_collection", methods=["POST"])
def generate_collection():
    data = request.get_json()
    file_types = data.get("file_types")
    logger.info(f"*<<<<<<<< file_types = {file_types}")
    if not file_types or not isinstance(file_types, list):
        return jsonify({"error": "file_types must be a list of file types"}), 400

    collection = MediaCollection(name="New Media Collection")
    db.session.add(collection)
    db.session.commit()

    media_items = []
    for file_type in file_types:
        media_item = MediaItem(
            name=f"{file_type} file", type=file_type, collection=collection
        )
        db.session.add(media_item)
        db.session.flush()  # Ensure the ns_id is generated before commit
        media_items.append(
            {
                "ns_id": media_item.ns_id,
                "upload_url": f"/upload_media_item?{media_item.ns_id}",
            }
        )

    db.session.commit()
    time.sleep(40)
    logger.info("sending generate_collection after sleep")
    return jsonify(
        {"collection_ns_id": collection.ns_id, "media_items": media_items}
    ), 201


@bp.route("/publish_collection/<ns_id>", methods=["POST"])
def publish_collection(ns_id):
    collection = MediaCollection.query.filter_by(ns_id=ns_id).first_or_404()
    logger.info(f"*<<<<<<<< publish_collection called = {collection}")

    if all(item.state == "uploaded" for item in collection.media_items):
        collection.state = "published"
    else:
        collection.state = "MEDIA_ITEMS_NOT_UPLOADED"

    db.session.commit()
    logger.info(f"*<<<<<<<< publish_collection: collection.state = {collection.state}")
    time.sleep(40)
    logger.info("publish_collection after sleep")
    return jsonify(
        {
            "message": "Collection state updated",
            "collection": {"ns_id": collection.ns_id, "state": collection.state},
        }
    ), 200


@bp.route("/collections/<ns_id>", methods=["GET"])
def get_collection_details(ns_id):
    collection = MediaCollection.query.filter_by(ns_id=ns_id).first_or_404()
    media_items = [
        {
            "id": item.id,
            "ns_id": item.ns_id,
            "name": item.name,
            "path": item.path,
            "type": item.type,
            "state": item.state,
        }
        for item in collection.media_items
    ]
    return jsonify(
        {
            "id": collection.id,
            "ns_id": collection.ns_id,
            "name": collection.name,
            "state": collection.state,
            "media_items": media_items,
        }
    ), 200


@bp.route("/upload_media_item", methods=["POST"])
def upload_media_item():
    logger.info("upload_media_item called")
    item_ns_id = request.form.get("ns_id")
    media_item = MediaItem.query.filter_by(ns_id=item_ns_id).first_or_404()
    collection_ns_id = media_item.collection.ns_id
    logger.info(
        f"upload_media_item: collection_ns_id = {collection_ns_id} media_item ={media_item}"
    )

    if "file" not in request.files:
        logger.error("No file part in request")
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    if file.filename == "":
        logger.error("No selected file")
        return jsonify({"error": "No selected file"}), 400

    if file:
        filename = secure_filename(file.filename)
        collection_folder = os.path.join(Config.UPLOAD_FOLDER, collection_ns_id)
        item_folder = os.path.join(collection_folder, item_ns_id)
        os.makedirs(item_folder, exist_ok=True)
        file_path = os.path.join(item_folder, filename)

        try:
            file.save(file_path)
            media_item.path = file_path
            media_item.state = "uploaded"
            db.session.commit()

            # Check if all media items in the collection are uploaded
            collection = media_item.collection
            if all(item.state == "uploaded" for item in collection.media_items):
                collection.state = "media_items_uploaded"
                db.session.commit()

            logger.info(f"Successfully uploaded media item {item_ns_id}")
            time.sleep(10)
            return jsonify(
                {"message": "File uploaded successfully", "file_path": file_path}
            ), 201
        except Exception as e:
            logger.error(f"Failed to save file: {e}")
            return jsonify({"error": "Failed to save file"}), 500


@bp.route("/collections", methods=["GET"])
def get_all_collections():
    logger.info("<<<<<< get_all_collections called")
    collections = MediaCollection.query.all()
    result = []
    for collection in collections:
        media_items = [
            {
                "id": item.id,
                "ns_id": item.ns_id,
                "name": item.name,
                "path": item.path,
                "type": item.type,
                "state": item.state,
            }
            for item in collection.media_items
        ]
        result.append(
            {
                "id": collection.id,
                "ns_id": collection.ns_id,
                "name": collection.name,
                "state": collection.state,
                "media_items": media_items,
            }
        )
    return jsonify(result), 200
