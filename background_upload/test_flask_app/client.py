import requests


def upload_video(file_path, url="http://127.0.0.1:8000/upload"):
    try:
        with open(file_path, "rb") as file:
            files = {"file": file}
            response = requests.post(url, files=files)

        if response.status_code == 201:
            print("File uploaded successfully")
            print("Response:", response.json())
        else:
            print("Failed to upload file")
            print("Response:", response.json())
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    file_path = "/Users/ankitsachan/Documents/code/test_data/upload_samples/SampleVideo_360x240_20mb.mp4"  # input('Enter the path to the video file: ')
    upload_video(file_path)

# file_path = '/Users/ankitsachan/Documents/code/test_data/upload_samples/SampleVideo_360x240_20mb.mp4'
# url = 'http://127.0.0.1:8000/upload'
# import sys
# print(f"<<<<<<< Python executable: {sys.executable}")
# print(f"<<<<<<< Python version: {sys.version}")
# upload_file_in_chunks(file_path, url)
