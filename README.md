# PsRevokeCerts

吊销、恢复[RevokeChinaCerts](https://github.com/chengar28/RevokeChinaCerts)中Windows数字证书的PowerShell脚本。仅支持全部添加和全部删除。

## Usage

初始化：

```powershell
git clone https://github.com/TheCjw/PsRevokeCerts
cd PsRevokeCerts
git submodule update --init
```

使用管理员身份运行PowerShell，执行脚本：

```powershell
powershell -ExecutionPolicy Bypass .\PsRevokeCerts.ps1
```

删除腾讯的证书：

```powershell
Get-ChildItem Cert:\LocalMachine\Disallowed | Where-Object { $_.SubjectName.Name.toLower().Contains("tencent") } | Select-Object { Remove-Item (Join-Path Cert:\LocalMachine\Disallowed $_.Thumbprint) }
```