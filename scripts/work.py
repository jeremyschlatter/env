from pathlib import Path
from datetime import datetime

d = datetime.now()
w = Path.home() / "work" / str(d.year) / f"{d.month:02d}" / f"{d.day:02d}"
w.mkdir(parents=True, exist_ok=True)
print(w)
