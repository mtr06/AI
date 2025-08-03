def read_file_binary(file_path):
    """
    Membaca file dan mengembalikan binary data
    """
    try:
        with open(file_path, 'rb') as file:
            binary_data = file.read()
        return binary_data
    except FileNotFoundError:
        print(f"File {file_path} tidak ditemukan")
        return None
    except Exception as e:
        print(f"Error membaca file: {e}")
        return None

import base64

def file_to_base64(file_path):
    """
    Membaca file dan mengkonversi ke base64 string
    """
    try:
        with open(file_path, 'rb') as file:
            binary_data = file.read()
            base64_string = base64.b64encode(binary_data).decode()
        return base64_string
    except Exception as e:
        print(f"Error: {e}")
        return None

# Contoh penggunaan
file_path = "test.jpg"
binary_data = file_to_base64(file_path)
if binary_data:
    print(f"File size: {len(binary_data)} bytes")
    print(f"First 10 bytes: {binary_data}")