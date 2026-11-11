<#
  Prova del modello tarocchi in locale con Ollama.

  Estrae tre arcani maggiori (passato, presente, futuro), ognuno dritto o rovesciato,
  prende le descrizioni da data\descrizione_it e chiede al modello la sintesi finale,
  nello stesso formato usato per l'addestramento.

  Uso (dalla cartella llm_local):
    powershell -ExecutionPolicy Bypass -File scripts\prova_tarocchi.ps1
    powershell -ExecutionPolicy Bypass -File scripts\prova_tarocchi.ps1 -Ripeti 2   # stesse carte, due sintesi
#>
param(
    [string]$Modello = "tarocchi",
    [int]$Ripeti = 1
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Cartella = Join-Path $PSScriptRoot "..\data\descrizione_it"

$Nomi = [ordered]@{
    "00_il_matto" = "Il Matto"; "01_il_mago" = "Il Mago"; "02_la_papessa" = "La Papessa"
    "03_l_imperatrice" = "L'Imperatrice"; "04_l_imperatore" = "L'Imperatore"; "05_il_papa" = "Il Papa"
    "06_gli_amanti" = "Gli Amanti"; "07_il_carro" = "Il Carro"; "08_la_forza" = "La Forza"
    "09_l_eremita" = "L'Eremita"; "10_la_ruota_della_fortuna" = "La Ruota della Fortuna"
    "11_la_giustizia" = "La Giustizia"; "12_l_appeso" = "L'Appeso"; "13_la_morte" = "La Morte"
    "14_la_temperanza" = "La Temperanza"; "15_il_diavolo" = "Il Diavolo"; "16_la_torre" = "La Torre"
    "17_la_stella" = "La Stella"; "18_la_luna" = "La Luna"; "19_il_sole" = "Il Sole"
    "20_il_giudizio" = "Il Giudizio"; "21_il_mondo" = "Il Mondo"
}
$Posizioni = @("Passato", "Presente", "Futuro")

function Pulisci([string]$testo) {
    $testo = $testo -replace "`r`n", "`n" -replace [char]0x2019, "'"
    ($testo -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) -join "`n"
}

# Estrazione: tre carte diverse, ognuna dritta o rovesciata
$carte = $Nomi.Keys | Get-Random -Count 3
$blocchi = @()
for ($i = 0; $i -lt 3; $i++) {
    $slug = $carte[$i]; $pos = $Posizioni[$i]
    $rovesciata = (Get-Random -Maximum 2) -eq 1
    $file = Join-Path $Cartella ("{0}_{1}{2}.md" -f $slug, $(if ($rovesciata) { "r_" } else { "" }), $pos)
    $testo = Pulisci (Get-Content -Raw -Encoding UTF8 $file)
    $orient = if ($rovesciata) { "rovesciata" } else { "dritta" }
    $blocchi += "{0}: {1} (carta {2})`n{3}" -f $pos.ToUpper(), $Nomi[$slug], $orient, $testo
    Write-Host ("{0,-9} {1} ({2})" -f $pos, $Nomi[$slug], $orient) -ForegroundColor Cyan
}
$prompt = $blocchi -join "`n`n"

for ($n = 1; $n -le $Ripeti; $n++) {
    $corpo = @{ model = $Modello; prompt = $prompt; stream = $false } | ConvertTo-Json -Compress
    $inizio = Get-Date
    $r = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post `
         -ContentType "application/json; charset=utf-8" -Body ([System.Text.Encoding]::UTF8.GetBytes($corpo))
    $secondi = [math]::Round(((Get-Date) - $inizio).TotalSeconds, 1)
    $parole = ($r.response -split "\s+" | Where-Object { $_ }).Count
    Write-Host ("`n--- Sintesi {0} ({1} parole, {2} s) ---" -f $n, $parole, $secondi) -ForegroundColor Yellow
    Write-Host $r.response.Trim()
}
Write-Host ("`nCompletato alle {0:HH:mm:ss}" -f (Get-Date)) -ForegroundColor Green
