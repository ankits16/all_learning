import logging
import os

from .config import Config

log_file_path = os.path.join(Config.LOG_FOLDER, "app.log")

# Create a custom logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Disable propagation to avoid duplication in the root logger
logger.propagate = False

# Create handlers
file_handler = logging.FileHandler(log_file_path)
console_handler = logging.StreamHandler()

# Set level for handlers
file_handler.setLevel(logging.INFO)
console_handler.setLevel(logging.INFO)

# Create formatters and add them to handlers
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
file_handler.setFormatter(formatter)
console_handler.setFormatter(formatter)

# Add handlers to the logger only if they haven't been added already
if not logger.hasHandlers():
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

# Test logging
logger.info("This is a test log message")
