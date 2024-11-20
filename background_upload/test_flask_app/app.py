
# from flask import Flask, request, jsonify
# import os
# import time

# app = Flask(__name__)
# UPLOAD_FOLDER = 'uploads/'
# app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# LOG_FOLDER = 'logs/'
# app.config['LOG_FOLDER'] = LOG_FOLDER

# if not os.path.exists(LOG_FOLDER):
#     os.makedirs(LOG_FOLDER)

# if not os.path.exists(UPLOAD_FOLDER):
#     os.makedirs(UPLOAD_FOLDER)

# @app.route('/')
# def home():
#     return "Welcome to the Video Upload API"

# @app.route('/upload', methods=['POST'])
# def upload_video():
#     print('<<<<<<<< upload_video called')
#     chunk_number = request.form.get('chunk', -100)
#     print(f'<<<<<<<<< received chunk = {chunk_number}')
#     if 'file' not in request.files:
#         print("'file' not in request.files:")
#         return jsonify({"error": "No file part"}), 400
    
#     file = request.files['file']
    
    
#     if file.filename == '':
#         print("file.filename == ''")
#         return jsonify({"error": "No selected file"}), 400
    
#     if file:
#         filename = file.filename
#         file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
#         file.save(file_path)
#         time.sleep(2)  # Sleep for 2 seconds
#         print(f'~~~~~~~~~~~~~~ successfully uploaded {chunk_number}')
#         return jsonify({"message": "File uploaded successfully", "file_path": file_path}), 201


# @app.route('/log', methods=['POST'])
# def log_event():
#     data = request.get_json()
#     if not data or 'event' not in data:
#         return jsonify({"error": "No event data"}), 400

#     event = data['event']
#     log_file_path = os.path.join(app.config['LOG_FOLDER'], 'events.log')
#     with open(log_file_path, 'a') as log_file:
#         log_file.write(event + '\n')

#     return jsonify({"message": "Event logged successfully"}), 201

# if __name__ == '__main__':
#     app.run(debug=True, host='0.0.0.0', port=8000)
