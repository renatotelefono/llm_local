"""Pulisce data/letture.jsonl e scrive data/sintesi_pulite.jsonl.

1. Corregge le preposizioni non articolate davanti alle carte ("da la Forza" -> "dalla Forza").
2. Scarta le sintesi che copiano la frase d'esempio del prompt ("hai fatto fatica a lasciare andare"...).
3. Limita a MAX_PER_ATTACCO le sintesi che iniziano con le stesse tre parole, per evitare tic ripetitivi.
"""
import collections, json, random, re
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

DATA = Path(__file__).resolve().parent.parent / "data"
INGRESSO, USCITA = DATA / "letture.jsonl", DATA / "sintesi_pulite.jsonl"
MAX_PER_ATTACCO = 60
SEED = 0

PREP = {
    "di": {"il": "del", "lo": "dello", "la": "della", "l'": "dell'", "gli": "degli", "le": "delle"},
    "a":  {"il": "al",  "lo": "allo",  "la": "alla",  "l'": "all'",  "gli": "agli",  "le": "alle"},
    "da": {"il": "dal", "lo": "dallo", "la": "dalla", "l'": "dall'", "gli": "dagli", "le": "dalle"},
    "in": {"il": "nel", "lo": "nello", "la": "nella", "l'": "nell'", "gli": "negli", "le": "nelle"},
    "su": {"il": "sul", "lo": "sullo", "la": "sulla", "l'": "sull'", "gli": "sugli", "le": "sulle"},
}
# Preposizione e articolo separati, seguiti dal nome di una carta con la MAIUSCOLA
# ("da la Forza", "di L'Eremita"). La maiuscola dopo l'articolo è controllata in modo stretto,
# così "a lasciare" non viene toccato.
RE_PREP = re.compile(r"\b((?i:di|a|da|in|su)) (?:((?i:il|lo|la|gli|le)) (?=[A-Z])|((?i:l'))(?=[A-Z]))")

def unisci(m):
    prep, art = m.group(1), (m.group(2) or m.group(3)).lower()
    fusa = PREP[prep.lower()][art]
    if prep[0].isupper():
        fusa = fusa.capitalize()
    return fusa if fusa.endswith("'") else fusa + " "

def correggi(testo):
    return RE_PREP.sub(unisci, testo)

COPIA_ESEMPIO = re.compile(r"fatto fatica a lasciar|senti il bisogno di libertà|fidati di te\b", re.I)

def main():
    righe = [json.loads(r) for r in INGRESSO.open(encoding="utf-8") if r.strip()]
    random.Random(SEED).shuffle(righe)
    corrette, scartate_esempio, scartate_attacco = 0, 0, 0
    per_attacco, tenute = collections.Counter(), []
    for r in righe:
        testo = r["messages"][2]["content"]
        nuovo = correggi(testo)
        corrette += nuovo != testo
        if COPIA_ESEMPIO.search(nuovo):
            scartate_esempio += 1
            continue
        attacco = " ".join(nuovo.split()[:3]).lower()
        if per_attacco[attacco] >= MAX_PER_ATTACCO:
            scartate_attacco += 1
            continue
        per_attacco[attacco] += 1
        r["messages"][2]["content"] = nuovo
        tenute.append(r)
    with USCITA.open("w", encoding="utf-8") as f:
        for r in tenute:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"Lette: {len(righe)}")
    print(f"Preposizioni corrette in: {corrette}")
    print(f"Scartate (copiavano l'esempio): {scartate_esempio}")
    print(f"Scartate (attacco troppo ripetuto): {scartate_attacco}")
    print(f"Tenute: {len(tenute)} -> {USCITA.name}")
    print(f"\n✅ Completato — ore {datetime.now(ZoneInfo('Europe/Rome')):%H:%M:%S}")

if __name__ == "__main__":
    main()
