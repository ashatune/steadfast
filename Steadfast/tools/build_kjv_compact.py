# tools/build_kjv_compact.py
import sys, json, re
from pathlib import Path

BOOK_ID = {
 "Genesis":1,"Exodus":2,"Leviticus":3,"Numbers":4,"Deuteronomy":5,"Joshua":6,"Judges":7,"Ruth":8,
 "1Samuel":9,"2Samuel":10,"1Kings":11,"2Kings":12,"1Chronicles":13,"2Chronicles":14,"Ezra":15,"Nehemiah":16,
 "Esther":17,"Job":18,"Psalms":19,"Proverbs":20,"Ecclesiastes":21,"SongofSolomon":22,"Isaiah":23,"Jeremiah":24,
 "Lamentations":25,"Ezekiel":26,"Daniel":27,"Hosea":28,"Joel":29,"Amos":30,"Obadiah":31,"Jonah":32,"Micah":33,
 "Nahum":34,"Habakkuk":35,"Zephaniah":36,"Haggai":37,"Zechariah":38,"Malachi":39,"Matthew":40,"Mark":41,"Luke":42,
 "John":43,"Acts":44,"Romans":45,"1Corinthians":46,"2Corinthians":47,"Galatians":48,"Ephesians":49,"Philippians":50,
 "Colossians":51,"1Thessalonians":52,"2Thessalonians":53,"1Timothy":54,"2Timothy":55,"Titus":56,"Philemon":57,
 "Hebrews":58,"James":59,"1Peter":60,"2Peter":61,"1John":62,"2John":63,"3John":64,"Jude":65,"Revelation":66
}

# Extra filename aliases some repos use
ALIASES = {
    "SongofSongs": "SongofSolomon", "Canticles": "SongofSolomon",
    "Psalms": "Psalms", "Psalm": "Psalms",
    "1Samuel": "1Samuel", "1_Samuel": "1Samuel", "1 Samuel": "1Samuel",
    "2Samuel": "2Samuel", "2_Samuel": "2Samuel", "2 Samuel": "2Samuel",
    "1Kings": "1Kings", "1_Kings": "1Kings", "1 Kings": "1Kings",
    "2Kings": "2Kings", "2_Kings": "2Kings", "2 Kings": "2Kings",
    "1Chronicles": "1Chronicles", "1_Chronicles": "1Chronicles", "1 Chronicles": "1Chronicles",
    "2Chronicles": "2Chronicles", "2_Chronicles": "2Chronicles", "2 Chronicles": "2Chronicles",
    "1Corinthians": "1Corinthians", "1_Corinthians": "1Corinthians", "1 Corinthians": "1Corinthians",
    "2Corinthians": "2Corinthians", "2_Corinthians": "2Corinthians", "2 Corinthians": "2Corinthians",
    "1Thessalonians": "1Thessalonians", "1_Thessalonians": "1Thessalonians", "1 Thessalonians": "1Thessalonians",
    "2Thessalonians": "2Thessalonians", "2_Thessalonians": "2Thessalonians", "2 Thessalonians": "2Thessalonians",
    "1Timothy": "1Timothy", "1_Timothy": "1Timothy", "1 Timothy": "1Timothy",
    "2Timothy": "2Timothy", "2_Timothy": "2Timothy", "2 Timothy": "2Timothy",
    "1Peter": "1Peter", "1_Peter": "1Peter", "1 Peter": "1Peter",
    "2Peter": "2Peter", "2_Peter": "2Peter", "2 Peter": "2Peter",
    "1John": "1John", "1_John": "1John", "1 John": "1John",
    "2John": "2John", "2_John": "2John", "2 John": "2John",
    "3John": "3John", "3_John": "3John", "3 John": "3John",
}

def canon(filename_stem: str) -> str:
    s = filename_stem.replace(".json","")
    s = s.replace("-", "").replace("_", "").replace(" ", "")
    return s

def normalize_book_key(stem: str) -> str:
    c = canon(stem)
    # First, try direct match in BOOK_ID
    if c in BOOK_ID: return c
    # Try alias map
    for k, v in ALIASES.items():
        if canon(k) == c:
            return v
    return ""

def load_book(path: Path):
    data = json.loads(path.read_text(encoding="utf-8"))

    # Case A: dict with numeric chapter keys: { "1": ["v1","v2",...], "2": [...] }
    if isinstance(data, dict) and all(k.isdigit() for k in data.keys()):
        chapters = []
        for ck in sorted(data.keys(), key=lambda x: int(x)):
            ch = data[ck]
            if isinstance(ch, list):
                chapters.append([str(v) for v in ch])
            elif isinstance(ch, dict):
                verses = [ch[str(i)] for i in sorted(map(int, ch.keys()))]
                chapters.append([str(v) for v in verses])
        return chapters

    # Case B: dict with "chapters": [ { "chapter": n, "verses": [...] }, ... ]
    if isinstance(data, dict) and isinstance(data.get("chapters"), list):
        out = []
        for ch in data["chapters"]:
            if isinstance(ch, dict) and isinstance(ch.get("verses"), list):
                # ch["verses"] can be ["string", ...] or [{ "verse": n, "text": "..." }, ...]
                vs = []
                for v in ch["verses"]:
                    if isinstance(v, dict):
                        vs.append(str(v.get("text", "")))
                    else:
                        vs.append(str(v))
                out.append(vs)
            elif isinstance(ch, list):  # rare variant: chapters is a list of string lists
                out.append([str(v) for v in ch])
        return out

    # Case C: already list-of-chapters (each a list-of-verses)
    if isinstance(data, list) and all(isinstance(ch, list) for ch in data):
        return [[str(v) for v in ch] for ch in data]

    raise ValueError(f"Unrecognized structure in {path}")


def main(src_dir, out_file):
    src = Path(src_dir)
    out = Path(out_file)
    verses = []
    picked, skipped = [], []

    # 🔍 recursively scan for .json (handles subfolders like OT/NT)
    for p in sorted(src.rglob("*.json")):
        stem = p.stem
        key = normalize_book_key(stem)
        if not key or key not in BOOK_ID:
            skipped.append(p)
            continue
        book_id = BOOK_ID[key]
        chapters = load_book(p)
        per_file_count = 0
        for ci, ch in enumerate(chapters, start=1):
            for vi, txt in enumerate(ch, start=1):
                verses.append({
                    "book": book_id, "chapter": ci, "verse": vi,
                    "text": re.sub(r"\s+", " ", txt).strip()
                })
                per_file_count += 1
        picked.append((p, per_file_count))

    out.write_text(json.dumps(verses, ensure_ascii=False), encoding="utf-8")

    # 📊 Debug summary
    print(f"Recognized book files: {len(picked)}")
    for p, c in picked:
        print(f"  ✓ {p.name}: {c} verses")
    print(f"Skipped (unrecognized): {len(skipped)}")
    for p in skipped[:10]:
        print(f"  – {p}")
    print(f"\nWrote {len(verses)} verses to {out}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 build_kjv_compact.py <path_to_Bible-kjv> <out_json>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
