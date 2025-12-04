# ===============================
# FUNCTIONS
# ===============================

function Test-PingHost {
    param ([string]$HostName)

    try {
        Test-Connection -ComputerName $HostName -Count 4 -ErrorAction Stop #sends 4 packets in case of failure jumps to catch block
        Write-Host "Ping to $HostName successful" -ForegroundColor Green 
    }
    catch {
        Write-Host "Ping to $HostName FAILED" -ForegroundColor Red
    }
}

function Test-TraceRoute {
    param ([string]$HostName)

    try {
        tracert $HostName
    }
    catch {
        Write-Host "Traceroute FAILED" -ForegroundColor Red
    }
}

function Test-DnsLookup {
    param ([string]$DomainName)

    try {
        $result = Resolve-DnsName $DomainName -ErrorAction Stop
        Write-Host "DNS Lookup Successful for $DomainName" -ForegroundColor Green
        $result.IPAddress
    }
    catch {
        Write-Host "DNS Lookup FAILED for $DomainName" -ForegroundColor Red
    }
}

function Test-PortConnection {
    param (
        [string]$HostName,
        [int]$Port
    )

    try {
        $result = Test-NetConnection -ComputerName $HostName -Port $Port -ErrorAction Stop

        if ($result.TcpTestSucceeded) {
            Write-Host "Port $Port on $HostName is OPEN" -ForegroundColor Green
        }
        else {
            Write-Host "Port $Port on $HostName is CLOSED" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Port Test FAILED" -ForegroundColor Red
    }
}

function Get-NetworkInfo {
    try {
        $info = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
        $info | Select Description, IPAddress, DefaultIPGateway, DNSServerSearchOrder
    }
    catch {
        Write-Host "Failed to get network info" -ForegroundColor Red
    }
}

function Run-FullDiagnostic {

    Write-Host "Running Full Network Diagnostic..." -ForegroundColor Cyan

    # ---- USER INPUT ----
    $targetHost = Read-Host "Enter the Hostname or IP for full diagnostic"
    $targetPort = Read-Host "Enter a Port Number to test"

    # ---- CREATE NEW CSV FILE FOR THIS RUN ONLY ----
    $Folder = "C:\Toolkit"
    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder | Out-Null
    }

    $timeStampFile = Get-Date -Format "yyyyMMdd_HHmmss"
    $csvFile = "$Folder\FullDiagnostic_$timeStampFile.csv"

    "TimeStamp,Test,Target,Detail,Result" | Out-File $csvFile

    Write-Host "Saving report to $csvFile" -ForegroundColor Yellow
    Write-Host "----------------------------------------"

    # =========================
    # PING (SUCCESS / FAILED)
    # =========================
    try {
        Test-Connection -ComputerName $targetHost -Count 2 -ErrorAction Stop | Out-Null
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Ping,$targetHost,Reachable,SUCCESS" |
            Out-File -Append $csvFile
        Write-Host "Ping: SUCCESS" -ForegroundColor Green
    }
    catch {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Ping,$targetHost,Unreachable,FAILED" |
            Out-File -Append $csvFile
        Write-Host "Ping: FAILED" -ForegroundColor Red
    }

    # =========================
    # TRACEROUTE (SUCCESS / FAILED)
    # =========================
    try {
        tracert $targetHost | Out-Null
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Traceroute,$targetHost,Route Completed,SUCCESS" |
            Out-File -Append $csvFile
        Write-Host "Traceroute: SUCCESS" -ForegroundColor Green
    }
    catch {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Traceroute,$targetHost,Route Failed,FAILED" |
            Out-File -Append $csvFile
        Write-Host "Traceroute: FAILED" -ForegroundColor Red
    }

    # =========================
    # DNS LOOKUP (RESOLVED IPs)
    # =========================
    try {
        $dnsResults = Resolve-DnsName $targetHost -ErrorAction Stop
        $ipList = ($dnsResults | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress) -join " | "

        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),DNS Lookup,$targetHost,$ipList,SUCCESS" |
            Out-File -Append $csvFile

        Write-Host "DNS Lookup: SUCCESS" -ForegroundColor Green
    }
    catch {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),DNS Lookup,$targetHost,Resolution Failed,FAILED" |
            Out-File -Append $csvFile

        Write-Host "DNS Lookup: FAILED" -ForegroundColor Red
    }

    # =========================
    # PORT TEST (OPEN / CLOSED)
    # =========================
    try {
        $portResult = Test-NetConnection -ComputerName $targetHost -Port $targetPort -ErrorAction Stop

        if ($portResult.TcpTestSucceeded) {
            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Port Test,${targetHost}:$targetPort,TCP Connection Established,OPEN" |
                Out-File -Append $csvFile
            Write-Host "Port ${targetPort}: OPEN" -ForegroundColor Green
        }
        else {
            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Port Test,${targetHost}:$targetPort,No TCP Response,CLOSED" |
                Out-File -Append $csvFile
            Write-Host "Port ${targetPort}: CLOSED" -ForegroundColor Yellow
        }
    }
    catch {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Port Test,${targetHost}:$targetPort,Port Test Error,FAILED" |
            Out-File -Append $csvFile
        Write-Host "Port Test: FAILED" -ForegroundColor Red
    }

    # =========================
    # FULL NETWORK INFO (DETAILED)
    # =========================
    try {
        #list of all network adapters
        $netInfo = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }

        #starts loop and executes each network adapter found in net info
        foreach ($adapter in $netInfo) {
            $ip = $adapter.IPAddress -join " | "
            $gw = $adapter.DefaultIPGateway -join " | "
            $dns = $adapter.DNSServerSearchOrder -join " | "

            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Network Info,Local Machine,Adapter: $($adapter.Description),Collected" |
                Out-File -Append $csvFile
            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Network Info,Local Machine,IP: $ip,Collected" |
                Out-File -Append $csvFile
            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Network Info,Local Machine,Gateway: $gw,Collected" |
                Out-File -Append $csvFile
            "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Network Info,Local Machine,DNS: $dns,Collected" |
                Out-File -Append $csvFile
        }

        Write-Host "Network Info: COLLECTED" -ForegroundColor Green
    }
    catch {
        "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),Network Info,Local Machine,Network Info Failed,FAILED" |
            Out-File -Append $csvFile
        Write-Host "Network Info: FAILED" -ForegroundColor Red
    }

    Write-Host "----------------------------------------"
    Write-Host "Full Diagnostic Complete for $targetHost" -ForegroundColor Green
    Write-Host "CSV Report Saved To:" -ForegroundColor Cyan
    Write-Host $csvFile
}

# ===============================
# MENU FUNCTION
# ===============================

function Show-Menu {
    param ([string]$Title = "Troubleshooting toolkit")

    Write-Host "================ $Title ================"
    Write-Host "1: Press '1' for Ping test."
    Write-Host "2: Press '2' for Trace Route test."
    Write-Host "3: Press '3' for DNS lookup test."
    Write-Host "4: Press '4' for Port Connection test."
    Write-Host "5: Press '5' to get Network Info."
    Write-Host "6: Press '6' to run a full diagnostic."
    Write-Host "Q: Press 'Q' to quit."
}

# ===============================
# MAIN PROGRAM LOOP
# ===============================

do {
    Show-Menu
    $input = Read-Host "Please make a selection"

    switch ($input) {

        '1' {
            $ping = Read-Host "Enter Hostname"
            Test-PingHost -HostName $ping
        }

        '2' {
            $trace = Read-Host "Enter Hostname"
            Test-TraceRoute -HostName $trace
        }

        '3' {
            $DNSlookup = Read-Host "Enter Domain Name"
            Test-DnsLookup -DomainName $DNSlookup
        }

        '4' {
            $Targethost = Read-Host "Enter Hostname"
            $port = Read-Host "Enter Port Number"
            Test-PortConnection -HostName $Targethost -Port $port
        }

        '5' {
            Get-NetworkInfo
        }

        '6' {
            Run-FullDiagnostic
        }

        'q' {
            Write-Host "Exiting program..."
            return
        }
    }

    pause
}
until ($input -eq 'q')