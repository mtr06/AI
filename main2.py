from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import FileResponse
from ultralytics import YOLO
from PIL import Image
import shutil
import os
import uuid
import cv2
import math

app = FastAPI()

model = YOLO("yolov11m_tugas_akhir_pretrained_ncnn_model")

@app.post("/predict/")
async def predict(
    file: UploadFile = File(...),
    berat_kardus: float = Form(...),
    berat_per_jeruk: float = Form(...),
    z: float = Form(...),
    folder: str = Form(...)
):
    # Buat folder jika belum ada
    os.makedirs(folder, exist_ok=True)

    # Simpan file upload sementara
    temp_path = f"temp_{file.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Inference
    results = model(temp_path)
    os.remove(temp_path)

    # Ubah label ke "fresh" dan "rotten"
    results[0].names = {
        0: 'fresh',
        1: 'rotten'
    }

    # Hitung jumlah fresh dan rotten
    fresh_count = 0
    rotten_count = 0
    for cls in results[0].boxes.cls:
        label = results[0].names[int(cls)]
        if label == "fresh":
            fresh_count += 1
        elif label == "rotten":
            rotten_count += 1

    n = fresh_count + rotten_count
    x = rotten_count
    N = math.floor(berat_kardus / berat_per_jeruk)
    p = x / n if n > 0 else 0

    if N > 1 and n > 0:
        moe = z * math.sqrt((p * (1 - p)) / n * ((N - n) / (N - 1)))
        ci_lower = max(0, p - moe)
        ci_upper = min(1, p + moe)
    else:
        ci_lower = ci_upper = p

    # Simpan hasil gambar ke dalam folder
    img_bgr = results[0].plot()
    img_rgb = img_bgr[..., ::-1]
    img_pil = Image.fromarray(img_rgb)
    output_filename = f"result_{uuid.uuid4().hex}.jpg"
    output_path = os.path.join(folder, output_filename)
    img_pil.save(output_path)

    return {
        "jumlah_fresh": fresh_count,
        "jumlah_rotten": rotten_count,
        "jumlah_sampel (n)": n,
        "populasi_total (N)": N,
        "proporsi_busuk (p)": round(p, 4),
        "confidence_interval": {
            "lower_bound": round(ci_lower, 4),
            "upper_bound": round(ci_upper, 4)
        },
        "penjelasan": "Input yang dibutuhkan dalam metode ini meliputi ukuran sampel (n), ukuran populasi (N), jumlah elemen busuk dalam sampel (x), dan tingkat kepercayaan (z-score)",
        "output_image_path": output_path
    }
