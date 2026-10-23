"""Build restored_vessel.db (SQLite) from the CSVs and run the SQL scripts.
Use it to check the queries quickly, or open the .db in DB Browser for SQLite."""
import csv, os, sqlite3, sys

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "restored_vessel.db")
if os.path.exists(DB):
    os.remove(DB)
con = sqlite3.connect(DB)
con.executescript(open(os.path.join(HERE, "sql", "01_create_tables.sql")).read())

def load(table, csv_name, keep_empty=False):
    with open(os.path.join(HERE, "data", csv_name), encoding="utf-8") as f:
        rows = list(csv.reader(f))
    cols, data = rows[0], rows[1:]
    if not keep_empty:
        data = [[None if v == "" else v for v in r] for r in data]
    con.executemany(f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?' * len(cols))})", data)

load("raw_youth_intake", "raw_youth_intake.csv", keep_empty=True)
load("dim_date", "dim_date.csv")
con.executescript(open(os.path.join(HERE, "sql", "02_clean_youth.sql")).read())
load("fact_sessions", "sessions.csv")
load("fact_referrals", "referrals.csv")
load("fact_outcomes", "outcomes.csv")
con.commit()

if "--kpis" in sys.argv:
    sql = open(os.path.join(HERE, "sql", "03_kpi_queries.sql")).read()
    for block in [b.strip() for b in sql.split(";") if "SELECT" in b]:
        title = [l for l in block.splitlines() if l.startswith("-- Q")]
        print("\n" + (title[0] if title else ""))
        cur = con.execute(block)
        print(" | ".join(c[0] for c in cur.description))
        for r in cur.fetchall():
            print(" | ".join(str(v) for v in r))
print("built", DB)
