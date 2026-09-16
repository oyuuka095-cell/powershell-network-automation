# PowerShell Network Automation

Windows сүлжээний тохиргоог PowerShell ашиглан шалгах болон автоматжуулах скриптүүд.

## Scripts

### network_info.ps1
Сүлжээний адаптерийн мэдээллийг автоматаар цуглуулна:
- IP address
- Subnet mask
- Default gateway
- DNS servers
- MAC address

### set_static.ps1
Ethernet0 адаптерийг Static IPv4 тохиргоонд шилжүүлнэ.

Тохиргоо:
- IP: 192.168.1.20
- Prefix: /24
- Gateway: 192.168.1.1
- DNS: 202.70.32.11, 202.70.32.10

Мөн:
- Одоогийн тохиргоог backup хийнэ
- INFO/ERROR log бүртгэнэ
- try/catch ашиглан алдаа боловсруулна

### set_dhcp.ps1
Ethernet0 адаптерийг DHCP горимд буцаана:
- DHCP идэвхжүүлнэ
- DNS-ийг automatic болгоно
- DHCP lease шинэчилнэ
- Үйлдлүүдийг log файлд бүртгэнэ

## Run

PowerShell-ийг Administrator эрхээр ажиллуулна.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
