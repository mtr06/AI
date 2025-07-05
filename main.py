from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import FileResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi import BackgroundTasks
from ultralytics import YOLO
from PIL import Image
import shutil
import os
import uuid
import cv2
import math

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

model = YOLO("yolov11m_tugas_akhir_pretrained_ncnn_model")

@app.post("/predict/")
async def predict(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    berat_kardus: float = Form(...),
    berat_per_jeruk: float = Form(...),
    z: float = Form(...)
):
    temp_path = f"temp_{file.filename}"
    with open(temp_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

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

    n = fresh_count + rotten_count  # ukuran sampel
    x = rotten_count                # jumlah elemen busuk dalam sampel
    N = math.floor(berat_kardus / berat_per_jeruk)  # populasi total
    p = x / n if n > 0 else 0       # proporsi busuk

    # Hitung margin of error
    if N > 1 and n > 0:
        moe = z * math.sqrt((p * (1 - p)) / n * ((N - n) / (N - 1)))
        ci_lower = max(0, p - moe)
        ci_upper = min(1, p + moe)
    else:
        ci_lower = ci_upper = p  # fallback jika data tidak valid

    # Buat gambar hasil deteksi
    img_bgr = results[0].plot()
    img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    img_pil = Image.fromarray(img_rgb)
    output_path = f"temp_result_{uuid.uuid4().hex}.jpg"
    img_pil.save(output_path)

    headers = {
        "jumlah_fresh": str(fresh_count),
        "jumlah_rotten": str(rotten_count),
        "jumlah_sampel_n": str(n),
        "populasi_total_N": str(N),
        "proporsi_busuk_p": str(round(p, 4)),
        "ci_lower": str(round(ci_lower, 4)),
        "ci_upper": str(round(ci_upper, 4)),
        "confidence_interval": f"{round(ci_lower, 4)}-{round(ci_upper, 4)}"

    }
    background_tasks.add_task(os.remove, output_path)

    return FileResponse(
        output_path,
        media_type="image/jpeg",
        filename="detected.jpg",
        headers=headers,
        background=background_tasks
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)