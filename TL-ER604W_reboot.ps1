# TL-ER604W_reboot.ps1
param(
    [string]$RouterIP = "192.168.xxx.xxx",
    [string]$Username = "your_admin",
    [string]$Password = "your_password",
    [int]$Port = 23
)

function Write-ProgressStep {
    param(
        [string]$Message,
        [string]$Status = "Processing",
        [int]$Step = 1,
        [int]$TotalSteps = 8
    )
    
    $PercentComplete = [math]::Round(($Step / $TotalSteps) * 100)
    Write-Host "[$Step/$TotalSteps] " -NoNewline -ForegroundColor Cyan
    Write-Host $Message -NoNewline -ForegroundColor White
    Write-Host " ... " -NoNewline -ForegroundColor Gray
    
    if ($Status -eq "Processing") {
        Write-Host "⏳" -ForegroundColor Yellow
    } elseif ($Status -eq "Success") {
        Write-Host "✅" -ForegroundColor Green
    } elseif ($Status -eq "Error") {
        Write-Host "❌" -ForegroundColor Red
    } elseif ($Status -eq "Warning") {
        Write-Host "⚠️" -ForegroundColor Yellow
    }
}

function Invoke-TelnetReboot {
    try {
        # Clear screen and show header
        Clear-Host
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host "    TP-Link TL-ER604W Router Reboot Script" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-ProgressStep -Message "Initializing connection to router $RouterIP" -Step 1
        
        # Buat koneksi TCP
        Write-ProgressStep -Message "Creating TCP connection to $RouterIP`:$Port" -Step 2
        $TCPClient = New-Object System.Net.Sockets.TCPClient
        $TCPClient.Connect($RouterIP, $Port)
        
        $NetworkStream = $TCPClient.GetStream()
        $StreamReader = New-Object System.IO.StreamReader($NetworkStream)
        $StreamWriter = New-Object System.IO.StreamWriter($NetworkStream)
        $StreamWriter.AutoFlush = $true

        Write-ProgressStep -Message "TCP connection established successfully" -Status "Success" -Step 3
        
        # Tunggu prompt login
        Write-ProgressStep -Message "Waiting for router login prompt" -Step 4
        Start-Sleep -Seconds 2
        
        # Login process
        Write-ProgressStep -Message "Sending username: $Username" -Step 5
        $StreamWriter.WriteLine($Username)
        Start-Sleep -Seconds 1
        
        Write-ProgressStep -Message "Sending password: ******" -Step 6
        $StreamWriter.WriteLine($Password)
        Start-Sleep -Seconds 1
        
        # Masuk ke enable mode dan reboot
        Write-ProgressStep -Message "Entering enable mode" -Step 7
        $StreamWriter.WriteLine("enable")
        Start-Sleep -Seconds 1
        
        Write-ProgressStep -Message "Sending enable password" -Step 8
        $StreamWriter.WriteLine("admin")
        Start-Sleep -Seconds 1
        
        Write-ProgressStep -Message "Sending reboot command" -Step 9
        $StreamWriter.WriteLine("sys reboot")
        Start-Sleep -Seconds 1
        
        Write-ProgressStep -Message "Confirming reboot (y)" -Step 10
        $StreamWriter.WriteLine("y")
        
        Write-ProgressStep -Message "Reboot command confirmed" -Status "Success" -Step 11
        
        # Tunggu sebentar sebelum menutup
        Write-Host ""
        Write-Host "Waiting for reboot to initiate..." -ForegroundColor Yellow
        for ($i = 30; $i -gt 0; $i--) {
            Write-Host "  $i..." -NoNewline -ForegroundColor Gray
            Start-Sleep -Seconds 1
        }
        Write-Host " done!" -ForegroundColor Green
        
        $StreamWriter.WriteLine("exit")
        
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "✅ SUCCESS: Router reboot command sent!" -ForegroundColor Green
        Write-Host "📍 Target: $RouterIP" -ForegroundColor White
        Write-Host "🕒 Time: $(Get-Date)" -ForegroundColor White
        Write-Host "================================================" -ForegroundColor Green
        Write-Host ""
        
        return $true
    }
    catch {
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Red
        Write-Host "❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "================================================" -ForegroundColor Red
        Write-Host ""
        return $false
    }
    finally {
        if ($TCPClient) { 
            Write-Host "Closing network connection..." -ForegroundColor Gray
            $TCPClient.Close() 
        }
        if ($StreamReader) { $StreamReader.Close() }
        if ($StreamWriter) { $StreamWriter.Close() }
    }
}

# Main execution
Write-Host "Starting router reboot process..." -ForegroundColor Yellow
Write-Host ""

$result = Invoke-TelnetReboot

Write-Host ""
if ($result) {
    Write-Host "Script completed successfully! " -NoNewline -ForegroundColor Green
    Write-Host "The router should reboot shortly." -ForegroundColor White
    exit 0
} else {
    Write-Host "Script failed! " -NoNewline -ForegroundColor Red
    Write-Host "Check the error message above." -ForegroundColor White
    exit 1
}

# Keep window open if run by double-click
Write-Host ""
Write-Host "Press any key to close this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
