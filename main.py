import csv
from pathlib import Path

SRC = Path("results/results/statistics-h-5.csv")       # <— original file
DST = Path("results.csv")   # <— new file

# Desired header in the new file
NEW_HEADER = ["benchmark", "instance", "result", "time", "comment"]

def row_is_header(row):
    """True if the row is just another copy of the old header."""
    return row[:3] == ["Name", "Tactic", "Status"]

with SRC.open(newline="") as inp, DST.open("w", newline="") as out:
    reader = csv.DictReader(inp)
    writer = csv.DictWriter(out, fieldnames=NEW_HEADER)
    writer.writeheader()

    for raw in reader:
        if row_is_header(list(raw.values())):
            # Skip duplicate header lines that sometimes appear in your file
            continue

        comment_parts = [
            f'timeout={raw["Timeout"]}',
            f'QE={raw["QE duration"]}',
            f'RCF={raw["RCF duration"]}',
            f'proof_steps={raw["Proof steps"]}',
            f'tactic_size={raw["Tactic size"]}',
        ]
        writer.writerow(
            {
                "benchmark": raw["Name"],
                "instance":  raw["Tactic"],
                "result":    raw["Status"],
                "time":      raw["Duration"],
                "comment":   " | ".join(comment_parts),
            }
        )

print(f"Wrote cleaned file to {DST.resolve()}")
