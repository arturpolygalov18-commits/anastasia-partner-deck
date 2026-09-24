param(
  [Parameter(Mandatory=$true)][string]$Slug,
  [Parameter(Mandatory=$true)][string]$Channel,
  [Parameter(Mandatory=$true)][string]$Audience,
  [Parameter(Mandatory=$true)][string]$Description,
  [Parameter(Mandatory=$true)][string]$TopicCopy,
  [Parameter(Mandatory=$true)][string]$AnalysisCopy
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = 'C:\Users\Home\AppData\Roaming\Open Design\namespaces\release-stable-win\data\projects\c48dee28-a8b7-4c97-8d76-294c27ff7703'
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$output = Join-Path $root "partners\$Slug"
$slideOutput = Join-Path $output 'slides'
$renderFolder = Join-Path $env:TEMP "anastasia-partner-render-$Slug"
New-Item -ItemType Directory -Force -Path $slideOutput,$renderFolder | Out-Null

$sourceFiles = 1..3 | ForEach-Object { Join-Path $source ("partner-vladimir-sivergin-slide-0$_.html") }
$photoAssets = @('anastasia-broadcast-cover.png','joint-broadcast-studio.png','anastasia-yacht-classic-sails.png')
foreach ($asset in $photoAssets) {
  Copy-Item -LiteralPath (Join-Path $source "assets\$asset") -Destination (Join-Path $renderFolder $asset) -Force
}

for ($i=1; $i -le 3; $i++) {
  $html = Get-Content -Raw -LiteralPath $sourceFiles[$i-1]
  $html = $html.Replace('body{padding:24px;', 'body{padding:0;')
  $html = $html.Replace('assets/anastasia-broadcast-cover.png','anastasia-broadcast-cover.png')
  $html = $html.Replace('assets/joint-broadcast-studio.png','joint-broadcast-studio.png')
  $html = $html.Replace('assets/anastasia-yacht-classic-sails.png','anastasia-yacht-classic-sails.png')
  if ($i -eq 1) {
    $html = $html.Replace('ДЛЯ КАНАЛА «ОПЫТ В СТОМАТОЛОГИИ»', "ДЛЯ КАНАЛА «$Channel»")
    $html = $html.Replace('Для собственников стоматологических клиник', $Audience)
  }
  if ($i -eq 2) {
    $html = $html.Replace('Владимир, вы разбираете открытие и развитие стоматологий на реальных примерах. Анастасия дополнит этот разговор финансовым взглядом. Тему обсудим с вами.', $Description)
  }
  if ($i -eq 3) {
    $html = $html.Replace('Опираемся на ваши разборы роста клиник и решений собственника. Тему согласуем вместе.', $TopicCopy)
    $html = $html.Replace('Показываем собственникам, как оценивать влияние решений на прибыль и денежный поток клиники.', $AnalysisCopy)
  }
  $renderHtml = Join-Path $renderFolder ("slide-0$i.html")
  [System.IO.File]::WriteAllText($renderHtml,$html,[System.Text.UTF8Encoding]::new($false))
  $png = Join-Path $slideOutput ("slide-0$i.png")
  $url = [System.Uri]::new($renderHtml).AbsoluteUri
  & $chrome '--headless=new' '--disable-gpu' '--hide-scrollbars' '--force-device-scale-factor=1' '--window-size=1440,810' '--virtual-time-budget=3000' "--screenshot=$png" $url 2>$null | Out-Null
  if (-not (Test-Path -LiteralPath $png)) { throw "Failed to render slide $i" }
}

$index = Get-Content -Raw -LiteralPath (Join-Path $root 'partners\vladimir-sivergin\index.html')
$index = $index.Replace('Опыт в Стоматологии', $Channel)
[System.IO.File]::WriteAllText((Join-Path $output 'index.html'),$index,[System.Text.UTF8Encoding]::new($false))
Write-Output $output
