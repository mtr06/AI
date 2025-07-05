# Production-ready Dockerfile untuk CPU-only inference
FROM python:3.11.5-slim

ENV PIP_BREAK_SYSTEM_PACKAGES=1

# Instal dependensi sistem yang dibutuhkan OpenCV di Debian/Ubuntu
RUN apt-get update && apt-get install -y libgl1-mesa-glx libglib2.0-0 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies dengan versi yang stabil
RUN python -m pip install --upgrade pip
RUN python -m pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY main.py .
COPY yolov11m_tugas_akhir_pretrained_ncnn_model ./yolov11m_tugas_akhir_pretrained_ncnn_model/

# Create hasil directory
RUN mkdir hasil

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
ENV OMP_NUM_THREADS=1
ENV MKL_NUM_THREADS=1

# Expose port
EXPOSE 8000

# Run application
CMD ["python", "-c", "import uvicorn; uvicorn.run('main:app', host='0.0.0.0', port=8000)"]