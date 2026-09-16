# DHCP тохиргоонд буцаах скрипт
# Ethernet0 адаптерийг DHCP горимд шилжүүлж,
# DNS тохиргоог автомат болгоно.
# Үйлдэл болон алдаануудыг log файлд бүртгэнэ.

# ==========================================
# 1. Үндсэн тохиргоо
# ==========================================

$adapter = "Ethernet0"
$logPath = "$env:USERPROFILE\Desktop\network.log"


# ==========================================
# 2. Log бичих функц
# ==========================================

function Write-Log {

    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    "[$time] $Level - $Message" |
        Add-Content -Path $logPath
}


# ==========================================
# 3. Үндсэн ажиллагаа
# ==========================================

try {

    Write-Log "DHCP script started."


    # Adapter байгаа эсэхийг шалгах
    Get-NetAdapter `
        -Name $adapter `
        -ErrorAction Stop |
        Out-Null

    Write-Log "Network adapter found: $adapter"


    # DHCP-г идэвхжүүлэх
    Set-NetIPInterface `
        -InterfaceAlias $adapter `
        -AddressFamily IPv4 `
        -Dhcp Enabled `
        -ErrorAction Stop

    Write-Log "DHCP enabled."


    # DNS тохиргоог автомат горимд буцаах
    Set-DnsClientServerAddress `
        -InterfaceAlias $adapter `
        -ResetServerAddresses `
        -ErrorAction Stop

    Write-Log "DNS configuration reset to automatic."


    # DHCP серверээс шинэ тохиргоо авах
    ipconfig /renew $adapter | Out-Null

    Write-Log "DHCP lease renewed."


    # Шинэ тохиргоо хэрэгжихийг хүлээх
    Start-Sleep -Seconds 3


    # ======================================
    # 4. Шинэ тохиргоог шалгах
    # ======================================

    $dhcpStatus = (
        Get-NetIPInterface `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -ErrorAction Stop
    ).Dhcp


    $newIP = (
        Get-NetIPAddress `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -ErrorAction Stop |
        Where-Object {
            $_.PrefixOrigin -eq "Dhcp"
        } |
        Select-Object -First 1
    ).IPAddress


    $newGateway = (
        Get-NetRoute `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -DestinationPrefix "0.0.0.0/0" `
            -ErrorAction Stop |
        Select-Object -First 1
    ).NextHop


    $newDNS = (
        Get-DnsClientServerAddress `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -ErrorAction Stop
    ).ServerAddresses


    # ======================================
    # 5. Үр дүнг дэлгэцэнд харуулах
    # ======================================

    Write-Host ""
    Write-Host "===== DHCP CONFIGURATION ====="
    Write-Host "Adapter    : $adapter"
    Write-Host "DHCP       : $dhcpStatus"
    Write-Host "IP Address : $newIP"
    Write-Host "Gateway    : $newGateway"
    Write-Host "DNS        : $($newDNS -join ', ')"
    Write-Host ""
    Write-Host "DHCP configuration completed."
    Write-Host "Log        : $logPath"

    Write-Log "DHCP configuration completed successfully."
}


# ==========================================
# 6. Алдаа боловсруулах хэсэг
# ==========================================

catch {

    $errorMessage = $_.Exception.Message

    Write-Host ""
    Write-Host "===== ERROR ====="
    Write-Host "ERROR: $errorMessage"
    Write-Host "Check log: $logPath"

    Write-Log $errorMessage "ERROR"
}