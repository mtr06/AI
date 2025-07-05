# Deploy script untuk IoT Agrari AI Container
# File: deploy.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "deploy",
    
    [Parameter(Mandatory=$false)]
    [string]$Port = "8000"
)

$ErrorActionPreference = "Stop"

Write-Host "=== IoT Agrari AI Deployment Script ===" -ForegroundColor Green

# Function untuk check prerequisites
function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    # Check Docker
    try {
        $dockerVersion = docker --version
        Write-Host "✓ Docker found: $dockerVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Docker not found. Please install Docker Desktop with Windows containers support." -ForegroundColor Red
        exit 1
    }
    
    # Check if Docker is running
    try {
        docker info | Out-Null
        Write-Host "✓ Docker is running" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
        exit 1
    }
    
    # Check Windows containers mode
    $dockerInfo = docker info --format "{{.OSType}}"
    if ($dockerInfo -ne "windows") {
        Write-Host "⚠ Docker is in Linux containers mode. Switching to Windows containers..." -ForegroundColor Yellow
        & "C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchDaemon
        Start-Sleep -Seconds 10
    }
    
    Write-Host "✓ All prerequisites met" -ForegroundColor Green
}

# Function untuk build container
function Build-Container {
    Write-Host "Building Docker container..." -ForegroundColor Yellow
    
    # Create hasil directory if not exists
    if (!(Test-Path -Path ".\hasil")) {
        New-Item -ItemType Directory -Path ".\hasil" -Force
        Write-Host "✓ Created hasil directory" -ForegroundColor Green
    }
    
    # Build container
    docker build -t iot-agrari-ai:latest .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container built successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Container build failed" -ForegroundColor Red
        exit 1
    }
}

# Function untuk deploy container
function Deploy-Container {
    Write-Host "Deploying container on port $Port..." -ForegroundColor Yellow
    
    # Stop existing container if running
    $existingContainer = docker ps -q --filter "name=iot-agrari-ai-container"
    if ($existingContainer) {
        Write-Host "Stopping existing container..." -ForegroundColor Yellow
        docker stop iot-agrari-ai-container
        docker rm iot-agrari-ai-container
    }
    
    # Run new container
    docker run -d `
        --name iot-agrari-ai-container `
        -p "${Port}:8000" `
        -v "${PWD}\hasil:C:\app\hasil" `
        --restart unless-stopped `
        iot-agrari-ai:latest
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container deployed successfully" -ForegroundColor Green
        Write-Host "🌐 API available at: http://localhost:$Port" -ForegroundColor Cyan
        Write-Host "📖 API documentation: http://localhost:$Port/docs" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Container deployment failed" -ForegroundColor Red
        exit 1
    }
}

# Function untuk stop container
function Stop-Container {
    Write-Host "Stopping container..." -ForegroundColor Yellow
    
    docker stop iot-agrari-ai-container
    docker rm iot-agrari-ai-container
    
    Write-Host "✓ Container stopped and removed" -ForegroundColor Green
}

# Function untuk show logs
function Show-Logs {
    Write-Host "Showing container logs..." -ForegroundColor Yellow
    docker logs -f iot-agrari-ai-container
}

# Function untuk check status
function Check-Status {
    Write-Host "Checking container status..." -ForegroundColor Yellow
    
    $containerStatus = docker ps --filter "name=iot-agrari-ai-container" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    if ($containerStatus) {
        Write-Host $containerStatus -ForegroundColor Green
        
        # Test API endpoint
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$Port/docs" -UseBasicParsing -TimeoutSec 5
            Write-Host "✓ API is responding" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Container is running but API is not responding" -ForegroundColor Yellow
        }
    } else {
        Write-Host "✗ Container is not running" -ForegroundColor Red
    }
}

# Main execution
switch ($Action.ToLower()) {
    "deploy" {
        Check-Prerequisites
        Build-Container
        Deploy-Container
    }
    "build" {
        Check-Prerequisites
        Build-Container
    }
    "start" {
        Deploy-Container
    }
    "stop" {
        Stop-Container
    }
    "restart" {
        Stop-Container
        Deploy-Container
    }
    "logs" {
        Show-Logs
    }
    "status" {
        Check-Status
    }
    default {
        Write-Host "Usage: .\deploy.ps1 [-Action <deploy|build|start|stop|restart|logs|status>] [-Port <port_number>]" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Actions:" -ForegroundColor Yellow
        Write-Host "  deploy  - Build and deploy container (default)" -ForegroundColor White
        Write-Host "  build   - Build container only" -ForegroundColor White
        Write-Host "  start   - Start container" -ForegroundColor White
        Write-Host "  stop    - Stop container" -ForegroundColor White
        Write-Host "  restart - Restart container" -ForegroundColor White
        Write-Host "  logs    - Show container logs" -ForegroundColor White
        Write-Host "  status  - Check container status" -ForegroundColor White
        Write-Host ""
        Write-Host "Examples:" -ForegroundColor Yellow
        Write-Host "  .\deploy.ps1" -ForegroundColor White
        Write-Host "  .\deploy.ps1 -Action build" -ForegroundColor White
        Write-Host "  .\deploy.ps1 -Action deploy -Port 9000" -ForegroundColor White
    }
}