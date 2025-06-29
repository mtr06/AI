# Use Python 3.10 Windows Server Core image
FROM python:3.10-windowsservercore

# Set working directory
WORKDIR C:/app

# Set PowerShell as the default shell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install Visual C++ Redistributable (required for some Python packages)
RUN Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "vc_redist.x64.exe"; \
    Start-Process -FilePath "vc_redist.x64.exe" -ArgumentList "/quiet" -Wait; \
    Remove-Item "vc_redist.x64.exe"

# Copy requirements file
COPY req.txt .

# Upgrade pip and install Python dependencies
RUN python -m pip install --upgrade pip; \
    pip install --no-cache-dir -r req.txt

# Copy application files
COPY main2.py .
COPY yolov11m_tugas_akhir_pretrained_ncnn_model/ ./yolov11m_tugas_akhir_pretrained_ncnn_model/

# Create directories for uploads and results
RUN New-Item -ItemType Directory -Path "C:/app/uploads" -Force; \
    New-Item -ItemType Directory -Path "C:/app/results" -Force; \
    New-Item -ItemType Directory -Path "C:/app/temp" -Force

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Expose port
EXPOSE 8000

# Health check using PowerShell
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD powershell -Command "try { Invoke-RestMethod -Uri 'http://localhost:8000/docs' -Method Get -TimeoutSec 10; exit 0 } catch { exit 1 }"

# Run the application
CMD ["python", "-m", "uvicorn", "main2:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]