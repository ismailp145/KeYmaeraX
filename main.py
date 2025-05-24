import csv
from pathlib import Path

def row_is_header(row):
    """True if the row is just another copy of the old header."""
    return row[:3] == ["Name", "Tactic", "Status"]

def process_csv(src_path: Path, dst_path: Path) -> None:
    """Process the CSV file and write the cleaned version.
    
    Args:
        src_path: Path to source CSV file
        dst_path: Path to destination CSV file
    """
    # Desired header in the new file
    NEW_HEADER = ["benchmark", "instance", "result", "time", "comment"]

    with src_path.open(newline="") as inp, dst_path.open("w", newline="") as out:
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

def main():
    src = Path("results/results/statistics-h-5.csv")  # original file
    dst = Path("results.csv")  # new file
    
    process_csv(src, dst)
    print(f"Wrote cleaned file to {dst.resolve()}")

if __name__ == "__main__":
    main()
