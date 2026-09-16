# Сүлжээний мэдээлэл авах скрипт
# Энэхүү скрипт нь сүлжээний үндсэн тохиргооны мэдээллийг цуглуулна

# Ашиглах сүлжээний адаптерийг сонгох
$adapter = "Ethernet0"

# Сүлжээний мэдээллүүдийг авах
$ip = (Get-NetIPAddress -InterfaceAlias $adapter -AddressFamily IPv4).IPAddress
$prefix = (Get-NetIPAddress -InterfaceAlias $adapter -AddressFamily IPv4).PrefixLength
$gateway = (Get-NetRoute -InterfaceAlias $adapter -DestinationPrefix "0.0.0.0/0").NextHop
$dns = (Get-DnsClientServerAddress -InterfaceAlias $adapter -AddressFamily IPv4).ServerAddresses
$mac = (Get-NetAdapter -Name $adapter).MacAddress

  # Prefix length-ийг Subnet Mask болгон хөрвүүлэх
  $maskBits = ("1" * $prefix).PadRight(32, "0")

  $mask = @(
      [Convert]::ToInt32($maskBits.Substring(0,8), 2)
      [Convert]::ToInt32($maskBits.Substring(8,8), 2)
      [Convert]::ToInt32($maskBits.Substring(16,8), 2)
      [Convert]::ToInt32($maskBits.Substring(24,8), 2)
  ) -join "."

# Гаралтын мэдээллийг бэлтгэх
$output = @"
===== NETWORK INFORMATION =====
Adapter     : $adapter
IP Address  : $ip
Subnet Mask : $mask
Gateway     : $gateway
DNS         : $($dns -join ', ')
MAC Address : $mac
"@

# Сүлжээний мэдээллийг дэлгэцэнд харуулах
Write-Host $output

# Сүлжээний мэдээллийг текст файлд хадгалах
$filePath = "$env:USERPROFILE\Desktop\network_info.txt"
$output | Out-File -FilePath $filePath -Encoding UTF8

# Файл хадгалагдсан байршлыг харуулах
Write-Host ""
Write-Host "Information saved to: $filePath"