$ErrorActionPreference = 'Stop'

function Decode([string]$value) {
  [System.Net.WebUtility]::HtmlDecode(($value -replace '<[^>]+>', '' -replace '\s+', ' ').Trim())
}

function Get-Entity([string]$title) {
  $m = [regex]::Match($title, '^(.{2,45}?)(?:\u8FA6\u7406|\u9055\u53CD|\u56E0|\u524D|\u53CA\u5176|\u6240\u6D89|\u4E4B)')
  if ($m.Success) { return $m.Groups[1].Value.Trim() }
  return $title.Substring(0, [Math]::Min(30, $title.Length)).Trim()
}

function Get-CaseType([string]$title, [string]$unit) {
  if ($title -match '\u6D17\u9322|\u8CC7\u6050') { return 'aml' }
  if ($title -match '\u632A\u7528|\u4FB5\u5360|\u76DC\u5237|\u821E\u5F0A|\u8A50\u6B3A') { return 'employee' }
  if ($title -match '\u500B\u4EBA\u8CC7\u6599|\u500B\u8CC7') { return 'privacy' }
  if ($title -match '\u8CC7\u672C\u9069\u8DB3|\u6E05\u511F\u80FD\u529B|\u589E\u8CC7|\u8CA1\u52D9\u6539\u5584') { return 'capital' }
  if ($title -match '\u516C\u53F8\u6CBB\u7406|\u8463\u4E8B|\u5167\u90E8\u63A7\u5236|\u7A3D\u6838') { return 'governance' }
  if ($unit -match '^\u9280\u884C\u5C40$') { return 'banking' }
  if ($unit -match '^\u8B49\u5238\u671F\u8CA8\u5C40$') { return 'securities' }
  if ($unit -match '^\u4FDD\u96AA\u5C40$') { return 'insurance' }
  if ($unit -match '^\u6AA2\u67E5\u5C40$') { return 'inspection' }
  return 'other'
}

function Get-Amount([string]$title) {
  $total = [decimal]0
  foreach ($m in [regex]::Matches($title, '([0-9,]+(?:\.[0-9]+)?)\u842C\u5143')) {
    $total += [decimal](($m.Groups[1].Value -replace ',', '')) * 10000
  }
  return [int64]$total
}

$site = 'https://www.fsc.gov.tw/ch/home.jsp?id=131&parentpath=0,2'
$first = Invoke-WebRequest -Uri $site -UseBasicParsing
$token = [regex]::Match($first.Content, 'name="token" value="([^"]+)"').Groups[1].Value
if (!$token) { throw 'FSC page token was not found.' }

$rows = [System.Collections.Generic.List[object]]::new()
for ($page = 1; $page -le 5; $page++) {
  $body = @{ token=$token; id='131'; contentid='131'; parentpath='0,2'; mcustomize='multimessages_list.jsp'; page=$page; pagesize='100' }
  $response = Invoke-WebRequest -Uri 'https://www.fsc.gov.tw/ch/home.jsp?id=131&parentpath=0%2C2&mcustomize=multimessages_list.jsp' -Method Post -Body $body -UseBasicParsing
  $pattern = '<li role="row">(?s:.*?)<span class="date" role="cell">(?<date>.*?)</span>(?s:.*?)<span class="unit" role="cell">(?<unit>.*?)</span>(?s:.*?)<a href="(?<href>[^"]+)" title="(?<title>[^"]+)"'
  foreach ($m in [regex]::Matches($response.Content, $pattern)) {
    $date = Decode $m.Groups['date'].Value; $unit = Decode $m.Groups['unit'].Value; $title = Decode $m.Groups['title'].Value
    if (!$date -or !$title) { continue }
    $rows.Add([pscustomobject]@{ date=$date; year=([datetime]::Parse($date)).Year - 1911; unit=$unit; entity=Get-Entity $title; caseType=Get-CaseType $title $unit; amount=Get-Amount $title; title=$title; url=('https://www.fsc.gov.tw/ch/' + ($m.Groups['href'].Value -replace '&amp;', '&')) })
  }
}

$cases = @($rows | Sort-Object url -Unique | Sort-Object date -Descending)
if ($cases.Count -lt 400) { throw "Unexpected case count: $($cases.Count)" }

$root = Split-Path -Parent $PSScriptRoot
$dashboard = Join-Path $root 'fsc-penalty-dashboard.html'
$html = Get-Content -Raw -Encoding utf8 $dashboard
$json = $cases | ConvertTo-Json -Depth 4 -Compress
$html = [regex]::Replace($html, '(?s)const CASES = .*?\r?\n;\r?\nconst typeLabel', "const CASES = $json`n;`nconst typeLabel", 1)
$today = [datetime]::UtcNow.AddHours(8).ToString('yyyy-MM-dd')
$html = [regex]::Replace($html, '資料擷取：\d{4}-\d{2}-\d{2}', "資料擷取：$today", 1)
Set-Content -LiteralPath $dashboard -Value $html -Encoding utf8 -NoNewline
Write-Host "Updated $($cases.Count) FSC cases for $today."
