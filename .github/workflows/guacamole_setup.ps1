# Enable RDP and create user
net user guacuser guacpass /add
net localgroup administrators guacuser /add
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
echo ✅ RDP Enabled and User Created.

# Download Guacamole Standalone
Invoke-WebRequest -Uri "https://downloads.apache.org/guacamole/1.5.4/binary/guacamole-1.5.4.war" -OutFile "guacamole.war"
mkdir C:\Guacamole\tomcat\webapps -Force
Move-Item guacamole.war C:\Guacamole\tomcat\webapps\ROOT.war

# Download Tomcat (updated to 10.1.43)
Invoke-WebRequest -Uri "https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.43/bin/apache-tomcat-10.1.43-windows-x64.zip" -OutFile "tomcat.zip"
Expand-Archive tomcat.zip -DestinationPath C:\Guacamole\tomcat
echo ✅ Tomcat extracted.

# Configure Guacamole user
mkdir C:\Guacamole\config
$xml = @"
<user-mapping>
  <authorize username="admin" password="admin">
    <connection name="RDP Session">
      <protocol>rdp</protocol>
      <param name="hostname">127.0.0.1</param>
      <param name="port">3389</param>
      <param name="username">guacuser</param>
      <param name="password">guacpass</param>
    </connection>
  </authorize>
</user-mapping>
"@
$xml | Out-File -Encoding UTF8 C:\Guacamole\config\user-mapping.xml
mkdir C:\Guacamole\tomcat\.guacamole -Force
Copy-Item C:\Guacamole\config\user-mapping.xml C:\Guacamole\tomcat\.guacamole\

# Set GUACAMOLE_HOME env
[System.Environment]::SetEnvironmentVariable("GUACAMOLE_HOME", "C:\Guacamole\tomcat\.guacamole", [System.EnvironmentVariableTarget]::Machine)

# Start Tomcat (make sure version matches)
Start-Process -FilePath "C:\Guacamole\tomcat\apache-tomcat-10.1.43\bin\startup.bat"
Start-Sleep -Seconds 10

# Download and Start Cloudflare Tunnel
Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "cloudflared.exe"
Start-Process -NoNewWindow -FilePath ".\cloudflared.exe" -ArgumentList "tunnel --url http://localhost:8080" -RedirectStandardOutput "cf.log" -RedirectStandardError "cf_err.log"
Start-Sleep -Seconds 45

echo "---- محتويات cf.log ----"
Get-Content cf.log
echo "------------------------"

$link = (Get-Content cf.log | Select-String -Pattern "https://[a-zA-Z0-9-]+\.trycloudflare\.com" | Select-Object -First 1).Matches.Value
if ($link) {
    echo "🌍 رابط Guacamole: $link/guacamole"
} else {
    echo "❌ لم يتم العثور على رابط Cloudflare في السجلات."
}
echo "👤 بيانات الدخول: admin / admin"

# Keep alive
while ($true) { Start-Sleep -Seconds 300 }
