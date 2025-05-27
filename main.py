import csv
import sys
from pathlib import Path

def row_is_header(row):
    """True if the row is just another copy of the old header."""
    return row[:3] == ["Name", "Tactic", "Status"]

def process_file(src_path: Path, writer):
    """Process a single CSV file and write its rows to the writer."""
    with src_path.open(newline="") as inp:
        reader = csv.DictReader(inp)
        for raw in reader:
            if row_is_header(list(raw.values())):
                continue
            comment_parts = [
                f'timeout={raw["Timeout"]}',
                f'QE={raw["QE duration"]}',
                f'RCF={raw["RCF duration"]}',
                f'proof_steps={raw["Proof steps"]}',
                f'tactic_size={raw["Tactic size"]}',
            ]
            writer.writerow({
                "benchmark": raw["Name"],
                "instance":  raw["Tactic"],
                "result":    raw["Status"],
                "time":      raw["Duration"],
                "comment":   " | ".join(comment_parts),
            })

def find_files(root: Path, patterns):
    """Recursively find files matching any of the given patterns under root."""
    found = []
    for pattern in patterns:
        for path in root.rglob(pattern):
            if path.is_file():
                found.append(path)
    return found

def main():
    # Root directory to search in
    root = Path("results")
    # Output file (will be created or overwritten)
    dst = root / "results.csv"

    # Get filenames/patterns from command-line arguments
    patterns = sys.argv[1:]
    if patterns:
        src_files = find_files(root, patterns)
        missing = set(patterns) - {p.name for p in src_files}
        for name in missing:
            print(f"Warning: no files named '{name}' found under {root}", file=sys.stderr)
    else:
        # If no patterns given, process all CSV files except the output file
        src_files = [p for p in root.rglob("*.csv") if p.name != dst.name]

    if not src_files:
        print("No input files to process.", file=sys.stderr)
        return

    # Sort for consistent order
    src_files.sort()

    # Define the new header once
    NEW_HEADER = ["benchmark", "instance", "result", "time", "comment"]
    with dst.open("w", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=NEW_HEADER)
        writer.writeheader()
        for src in src_files:
            print(f"Processing {src}")
            process_file(src, writer)

    print(f"Wrote cleaned file to {dst.resolve()}")

if __name__ == "__main__":
    main()

