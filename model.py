from ultralytics import YOLO

# Load a YOLO11n PyTorch model
# model = YOLO("yolov8n_tugas_akhir.pt")

# # Export the model to NCNN format
# model.export(format="ncnn")  # creates 'yolo11n_ncnn_model'

# Load the exported NCNN model
ncnn_model = YOLO("yolov11m_tugas_akhir_pretrained.onnx")

# Run inference
results = ncnn_model("test.jpg")