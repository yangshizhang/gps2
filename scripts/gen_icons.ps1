Add-Type -AssemblyName System.Drawing

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $here "..")).Path
$assetsRoot = "$repoRoot/LiquidGlassSpeedometer/LiquidGlassSpeedometer/Resources/Assets.xcassets"
$iconDir = "$assetsRoot/AppIcon.appiconset"
$accentDir = "$assetsRoot/AccentColor.colorset"

if (-not (Test-Path $iconDir)) { New-Item -ItemType Directory -Force -Path $iconDir | Out-Null }
if (-not (Test-Path $accentDir)) { New-Item -ItemType Directory -Force -Path $accentDir | Out-Null }

function New-SolidPng {
    param([string]$Path, [int]$Size)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 122, 255))
    $g.FillEllipse($brush, 0, 0, $Size, $Size)
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
}

$sizes = @(
    @{ file = "Icon-App-20x20@2x.png"; size = 40; idiom = "iphone"; scale = "2x"; psize = "20x20" }
    @{ file = "Icon-App-20x20@3x.png"; size = 60; idiom = "iphone"; scale = "3x"; psize = "20x20" }
    @{ file = "Icon-App-29x29@2x.png"; size = 58; idiom = "iphone"; scale = "2x"; psize = "29x29" }
    @{ file = "Icon-App-29x29@3x.png"; size = 87; idiom = "iphone"; scale = "3x"; psize = "29x29" }
    @{ file = "Icon-App-40x40@2x.png"; size = 80; idiom = "iphone"; scale = "2x"; psize = "40x40" }
    @{ file = "Icon-App-40x40@3x.png"; size = 120; idiom = "iphone"; scale = "3x"; psize = "40x40" }
    @{ file = "Icon-App-60x60@2x.png"; size = 120; idiom = "iphone"; scale = "2x"; psize = "60x60" }
    @{ file = "Icon-App-60x60@3x.png"; size = 180; idiom = "iphone"; scale = "3x"; psize = "60x60" }
    @{ file = "Icon-App-76x76@1x.png"; size = 76; idiom = "ipad"; scale = "1x"; psize = "76x76" }
    @{ file = "Icon-App-76x76@2x.png"; size = 152; idiom = "ipad"; scale = "2x"; psize = "76x76" }
    @{ file = "Icon-App-83.5x83.5@2x.png"; size = 167; idiom = "ipad"; scale = "2x"; psize = "83.5x83.5" }
    @{ file = "Icon-App-1024x1024@1x.png"; size = 1024; idiom = "ios-marketing"; scale = "1x"; psize = "1024x1024" }
)

$images = @()
foreach ($s in $sizes) {
    $filePath = "$iconDir/$($s.file)"
    New-SolidPng -Path $filePath -Size $s.size
    $images += @{
        filename = $s.file
        idiom = $s.idiom
        scale = $s.scale
        size = $s.psize
    }
}

$iconJson = @{
    images = $images
    info = @{ version = 1; author = "xcode" }
}
$iconJson | ConvertTo-Json -Depth 5 | Set-Content "$iconDir/Contents.json" -Encoding utf8

$accentJson = @{
    colors = @(
        @{
            idiom = "universal"
            color = @{
                "color-space" = "srgb"
                components = @{ alpha = "1.000"; blue = "0xFF"; green = "0x7A"; red = "0x00" }
            }
        }
    )
    info = @{ version = 1; author = "xcode" }
}
$accentJson | ConvertTo-Json -Depth 10 | Set-Content "$accentDir/Contents.json" -Encoding utf8

$assetsJson = @{
    info = @{ version = 1; author = "xcode" }
}
$assetsJson | ConvertTo-Json -Depth 3 | Set-Content "$assetsRoot/Contents.json" -Encoding utf8

Write-Host "Generated $($sizes.Count) PNG icons at: $assetsRoot"
