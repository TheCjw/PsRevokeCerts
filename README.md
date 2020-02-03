# PsRevokeCerts

吊销证书辅助脚本。目前支持以下功能：

- 批量吊销证书
- 通过关键字批量删除证书
- 查找已吊销的证书
- 显示所有已吊销的证书
- 从PE文件中导出证书

## Usage

初始化：

```bash
git clone https://github.com/TheCjw/PsRevokeCerts
cd PsRevokeCerts
```

使用管理员身份运行PowerShell，加载PsRevokeCerts模块：

```powershell
Import-Module ".\PsRevokeCerts.psm1"
```

批量吊销证书：

```powershell
Revoke-Certs ".\RevokeChinaCerts\Windows\Certificates\CodeSigning"
```

通过关键字批量删除证书

```powershell
Remove-RevokedCerts tencent
```

查找已吊销的证书

```powershell
Find-RevokedCerts tencent
```

显示所有已吊销的证书

```powershell
Get-RevokedCerts
```

从PE文件中导出证书

```powershell
Export-CertFileFromPE "360DrvMgrInstaller_beta.exe"
```
