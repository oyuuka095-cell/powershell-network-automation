# Static IP тохируулах скрипт
# Одоогийн сүлжээний тохиргоог нөөцөлж,
# Ethernet0 адаптерийг Static IP тохиргоонд шилжүүлнэ.
# Үйлдэл болон алдаануудыг log файлд бүртгэнэ.

# ==========================================
# 1. Үндсэн тохиргоонууд
# ==========================================

$adapter = "Ethernet0"
$ip = "192.168.1.20"
$prefix = 24
$gateway = "192.168.1.1"
$dns = @("202.70.32.11", "202.70.32.10")

$backupPath = "$env:USERPROFILE\Desktop\network_backup.txt"
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

    Write-Log "Static IP script started."


    # --------------------------------------
    # Adapter байгаа эсэхийг шалгах
    # --------------------------------------

    Get-NetAdapter `
        -Name $adapter `
        -ErrorAction Stop |
        Out-Null

    Write-Log "Network adapter found: $adapter"


    # --------------------------------------
    # Одоогийн тохиргоог нөөцлөх
    # --------------------------------------

    ipconfig /all |
        Out-File `
            -FilePath $backupPath `
            -Encoding UTF8

    Write-Log "Network configuration backup created."


    # --------------------------------------
    # DHCP-г унтраах
    # --------------------------------------

    Set-NetIPInterface `
        -InterfaceAlias $adapter `
        -AddressFamily IPv4 `
        -Dhcp Disabled `
        -ErrorAction Stop

    Write-Log "DHCP disabled."


    # --------------------------------------
    # Хуучин IPv4 хаягуудыг цэвэрлэх
    # --------------------------------------

    Get-NetIPAddress `
        -InterfaceAlias $adapter `
        -AddressFamily IPv4 `
        -ErrorAction SilentlyContinue |
        Remove-NetIPAddress `
            -Confirm:$false `
            -ErrorAction SilentlyContinue

    Write-Log "Old IPv4 addresses removed."


    # --------------------------------------
    # Хуучин Default Gateway route-уудыг
    # цэвэрлэх
    # --------------------------------------

    Get-NetRoute `
        -InterfaceAlias $adapter `
        -AddressFamily IPv4 `
        -DestinationPrefix "0.0.0.0/0" `
        -ErrorAction SilentlyContinue |
        Remove-NetRoute `
            -Confirm:$false `
            -ErrorAction SilentlyContinue

    Write-Log "Old default gateway routes removed."


    # Өмнөх тохиргоо цэвэрлэгдэхийг хүлээх
    Start-Sleep -Seconds 2


    # ======================================
    # 4. Static IP тохируулах
    # ======================================

    New-NetIPAddress `
        -InterfaceAlias $adapter `
        -IPAddress $ip `
        -PrefixLength $prefix `
        -ErrorAction Stop |
        Out-Null

    Write-Log "Static IP configured: $ip/$prefix"


    # ======================================
    # 5. Default Gateway тохируулах
    # ======================================

    # Gateway аль хэдийн байгаа эсэхийг шалгах
    $existingGateway = Get-NetRoute `
        -InterfaceAlias $adapter `
        -AddressFamily IPv4 `
        -DestinationPrefix "0.0.0.0/0" `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.NextHop -eq $gateway
        }


    # Gateway байхгүй бол шинээр үүсгэнэ
    if (-not $existingGateway) {

        New-NetRoute `
            -InterfaceAlias $adapter `
            -DestinationPrefix "0.0.0.0/0" `
            -NextHop $gateway `
            -ErrorAction Stop |
            Out-Null

        Write-Log "Default gateway configured: $gateway"
    }
    else {

        Write-Log "Default gateway already exists: $gateway"
    }


    # ======================================
    # 6. DNS серверүүдийг тохируулах
    # ======================================

    Set-DnsClientServerAddress `
        -InterfaceAlias $adapter `
        -ServerAddresses $dns `
        -ErrorAction Stop

    Write-Log "DNS servers configured: $($dns -join ', ')"


    # Тохиргоо бүрэн хэрэгжихийг хүлээх
    Start-Sleep -Seconds 2


    # ======================================
    # 7. Шинэ тохиргоог шалгах
    # ======================================

    $newIP = (
        Get-NetIPAddress `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -ErrorAction Stop |
        Where-Object {
            $_.IPAddress -eq $ip
        }
    ).IPAddress


    $newGateway = (
        Get-NetRoute `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -DestinationPrefix "0.0.0.0/0" `
            -ErrorAction Stop |
        Where-Object {
            $_.NextHop -eq $gateway
        } |
        Select-Object -First 1
    ).NextHop


    $newDNS = (
        Get-DnsClientServerAddress `
            -InterfaceAlias $adapter `
            -AddressFamily IPv4 `
            -ErrorAction Stop
    ).ServerAddresses


    # ======================================
    # 8. Үр дүнг дэлгэцэнд харуулах
    # ======================================

    Write-Host ""
    Write-Host "===== STATIC IP CONFIGURATION ====="
    Write-Host "Adapter    : $adapter"
    Write-Host "IP Address : $newIP"
    Write-Host "Prefix     : /$prefix"
    Write-Host "Gateway    : $newGateway"
    Write-Host "DNS        : $($newDNS -join ', ')"
    Write-Host ""
    Write-Host "Static IP configuration completed."
    Write-Host "Backup     : $backupPath"
    Write-Host "Log        : $logPath"

    Write-Log "Static IP configuration completed successfully."
}


# ==========================================
# 9. Алдаа боловсруулах хэсэг
# ==========================================

catch {

    $errorMessage = $_.Exception.Message

    Write-Host ""
    Write-Host "===== ERROR ====="
    Write-Host "ERROR: $errorMessage"
    Write-Host "Check log: $logPath"

    Write-Log $errorMessage "ERROR"
}