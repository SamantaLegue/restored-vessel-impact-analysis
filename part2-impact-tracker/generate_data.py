"""
Generate a SYNTHETIC dataset for The Restored Vessel impact tracker.

Every record is made up. No real young person is described here.
The rules below are assumptions chosen to look plausible, not findings.

Outputs (in ./data):
  raw_youth_intake.csv   intake register WITH deliberate data-quality issues (for the cleaning step)
  sessions.csv           one row per mentoring / group / counselling session
  referrals.csv          one row per referral to an outside service
  outcomes.csv           assessments at intake (month 0) and at 3, 6 and 12 months
  dim_date.csv           calendar table for SQL and Power BI

Run:  python generate_data.py
"""
import csv
import os
import random
from datetime import date, timedelta

import numpy as np

SEED = 2026
rng = np.random.default_rng(SEED)
random.seed(SEED)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(OUT, exist_ok=True)

START = date(2024, 1, 1)
DATA_CUTOFF = date(2026, 9, 30)   # "today" for the dataset
N_YOUTH = 500

REGIONS = ["Littoral", "Northwest", "Southwest", "Centre", "West",
           "South", "East", "Adamawa", "North", "Far North"]
REGION_P = [0.48, 0.17, 0.13, 0.07, 0.07, 0.03, 0.02, 0.01, 0.01, 0.01]

ISSUES = ["Substance use", "Crime", "Sexual exploitation", "Multiple"]
ISSUE_P = [0.44, 0.24, 0.20, 0.12]

REFERRAL_SOURCES = ["Church", "Street outreach", "Family", "Self", "School", "Police / court", "NGO partner"]
REF_P = [0.22, 0.26, 0.18, 0.08, 0.10, 0.07, 0.09]

EDUCATION = ["In school", "Dropped out", "Never enrolled", "Working"]

SESSION_TYPES = ["One-to-one mentoring", "Group session", "Counselling", "Bible study", "Skills training"]
SESSION_P = [0.34, 0.26, 0.14, 0.14, 0.12]
SESSION_MINUTES = {"One-to-one mentoring": 60, "Group session": 90, "Counselling": 50,
                   "Bible study": 75, "Skills training": 120}

SERVICES = ["Medical", "Rehabilitation centre", "Legal aid", "Safe housing", "Vocational training", "School re-entry"]

CHECKPOINTS = [0, 3, 6, 12]


def add_months(d, m):
    y, mo = divmod(d.month - 1 + m, 12)
    y += d.year
    mo += 1
    day = min(d.day, [31, 29 if y % 4 == 0 else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][mo - 1])
    return date(y, mo, day)


def rand_date(a, b):
    return a + timedelta(days=int(rng.integers(0, (b - a).days + 1)))


def clip(x, lo, hi):
    return max(lo, min(hi, x))


# ---------------------------------------------------------------- youth
# Intake grows over time (the ministry is growing): weight later days more.
span = (date(2026, 8, 31) - START).days
w = np.linspace(1.0, 2.6, span + 1)
w /= w.sum()
intake_offsets = np.sort(rng.choice(span + 1, size=N_YOUTH, p=w))

youth = []
for i, off in enumerate(intake_offsets, start=1):
    intake = START + timedelta(days=int(off))
    issue = rng.choice(ISSUES, p=ISSUE_P)
    if issue == "Sexual exploitation":
        gender = rng.choice(["Female", "Male"], p=[0.82, 0.18])
    elif issue == "Crime":
        gender = rng.choice(["Female", "Male"], p=[0.22, 0.78])
    else:
        gender = rng.choice(["Female", "Male"], p=[0.40, 0.60])
    age = int(clip(round(rng.normal(18, 2.8)), 13, 24))
    region = rng.choice(REGIONS, p=REGION_P)
    displaced = region in ("Northwest", "Southwest")
    edu_p = [0.30, 0.42, 0.10, 0.18] if not displaced else [0.18, 0.55, 0.12, 0.15]
    education = rng.choice(EDUCATION, p=edu_p)
    source = rng.choice(REFERRAL_SOURCES, p=REF_P)

    # Latent engagement (0..1). Family and church referrals engage a bit better.
    eng = rng.beta(2.2, 2.0)
    if source in ("Family", "Church"):
        eng = clip(eng + 0.08, 0, 1)
    if source == "Police / court":
        eng = clip(eng - 0.08, 0, 1)

    # How long they stay engaged (days). Low engagement = early drop-out.
    stay_days = int(rng.exponential(120 + 520 * eng))
    exit_date = intake + timedelta(days=stay_days)
    if exit_date > DATA_CUTOFF:
        exit_date, exit_reason = None, None
    else:
        if eng > 0.6 and stay_days > 240:
            exit_reason = rng.choice(["Completed programme", "Moved away"], p=[0.85, 0.15])
        else:
            exit_reason = rng.choice(["Lost contact", "Moved away", "Declined to continue"], p=[0.6, 0.2, 0.2])

    youth.append(dict(youth_id=f"RV{i:04d}", intake_date=intake, age=age, gender=gender,
                      home_region=region, primary_issue=issue, referral_source=source,
                      education_at_intake=education, exit_date=exit_date, exit_reason=exit_reason,
                      _eng=eng, _displaced=displaced))

# ---------------------------------------------------------------- sessions
sessions = []
sid = 1
for y in youth:
    end = y["exit_date"] or DATA_CUTOFF
    weeks = max(1, (end - y["intake_date"]).days / 7)
    rate = 0.35 + 1.6 * y["_eng"]          # sessions per week
    n = int(rng.poisson(rate * weeks * 0.55)) + 1
    for _ in range(n):
        d = rand_date(y["intake_date"], end)
        if d.weekday() == 0 and rng.random() < 0.6:   # few Monday sessions
            d += timedelta(days=1)
        if d > end:
            d = end
        t = rng.choice(SESSION_TYPES, p=SESSION_P)
        sessions.append(dict(session_id=f"S{sid:06d}", youth_id=y["youth_id"], session_date=d,
                             session_type=t,
                             duration_min=int(SESSION_MINUTES[t] + rng.integers(-10, 16)),
                             attended=1 if rng.random() < 0.80 + 0.15 * y["_eng"] else 0))
        sid += 1
sessions.sort(key=lambda s: (s["session_date"], s["youth_id"]))
for k, s in enumerate(sessions, start=1):
    s["session_id"] = f"S{k:06d}"

# ---------------------------------------------------------------- referrals
SERVICE_BY_ISSUE = {
    "Substance use": [0.25, 0.35, 0.03, 0.07, 0.17, 0.13],
    "Crime": [0.10, 0.08, 0.32, 0.10, 0.25, 0.15],
    "Sexual exploitation": [0.30, 0.04, 0.18, 0.30, 0.12, 0.06],
    "Multiple": [0.22, 0.22, 0.16, 0.16, 0.14, 0.10],
}
referrals = []
rid = 1
for y in youth:
    end = y["exit_date"] or DATA_CUTOFF
    for _ in range(int(rng.poisson(1.1 + 1.2 * y["_eng"]))):
        svc = rng.choice(SERVICES, p=SERVICE_BY_ISSUE[y["primary_issue"]])
        d = rand_date(y["intake_date"], min(end, y["intake_date"] + timedelta(days=200)))
        p_done = 0.35 + 0.5 * y["_eng"] - (0.12 if svc == "Rehabilitation centre" else 0)
        referrals.append(dict(referral_id=f"R{rid:05d}", youth_id=y["youth_id"], referral_date=d,
                              service_type=svc, completed=1 if rng.random() < p_done else 0))
        rid += 1

# ---------------------------------------------------------------- outcomes
outcomes = []
oid = 1
for y in youth:
    issue = y["primary_issue"]
    substance = issue in ("Substance use", "Multiple")
    # Baseline (month 0)
    # Displaced youth (Northwest / Southwest) arrive with lower wellbeing.
    wb = clip(round(rng.normal(3.1 if y["_displaced"] else 3.9, 1.2)), 1, 10)
    sub_free = 0 if substance else (1 if rng.random() < 0.7 else 0)
    school_work = 1 if y["education_at_intake"] in ("In school", "Working") else 0
    safe_house = 1 if rng.random() < (0.35 if issue == "Sexual exploitation" else 0.6) else 0
    for m in CHECKPOINTS:
        due = add_months(y["intake_date"], m)
        if due > DATA_CUTOFF:
            break
        active = y["exit_date"] is None or y["exit_date"] >= due
        if m > 0:
            # Follow-up reached? Active youth almost always; exited youth sometimes.
            reached = rng.random() < (0.95 if active else (0.55 if y["exit_reason"] == "Completed programme" else 0.15))
            if not reached:
                continue
            e = y["_eng"]
            gain = (0.9 + 2.2 * e) * (1 if active else 0.5) * (0.85 if y["_displaced"] else 1)
            wb = clip(round(wb + rng.normal(gain * 0.6, 0.8)), 1, 10)
            if substance:
                sub_free = 1 if rng.random() < (0.12 + 0.55 * e) * (1 if active else 0.6) + 0.05 * (m / 3) else 0
            school_work = 1 if school_work or rng.random() < (0.02 + 0.45 * e * e) else 0
            if school_work and rng.random() < 0.05:
                school_work = 0
            safe_house = 1 if safe_house or rng.random() < 0.15 + 0.4 * e else 0
            reoffend = 1 if issue in ("Crime", "Multiple") and rng.random() < (0.42 - 0.30 * e) * (1 - m / 30) else (
                1 if rng.random() < 0.04 else 0)
        else:
            reoffend = None
        outcomes.append(dict(outcome_id=f"O{oid:05d}", youth_id=y["youth_id"], checkpoint_month=m,
                             assessment_date=due + timedelta(days=int(rng.integers(0, 10))) if m else due,
                             wellbeing_score=wb, substance_free_30d=sub_free,
                             in_school_or_work=school_work, safe_housing=safe_house,
                             reoffended_since_last=reoffend))
        oid += 1

# ---------------------------------------------------------------- raw intake with deliberate mess
REGION_VARIANTS = {
    "Littoral": ["Littoral", "littoral", "LITTORAL", " Littoral", "Littoral (Douala)"],
    "Northwest": ["Northwest", "North West", "North-West", "NW", "northwest"],
    "Southwest": ["Southwest", "South West", "South-West", "SW"],
    "Far North": ["Far North", "Far-North", "Extreme Nord"],
}
GENDER_VARIANTS = {"Female": ["Female", "F", "female", "f"], "Male": ["Male", "M", "male", "m"]}

raw = []
for y in youth:
    r = dict(y)
    if rng.random() < 0.25:
        r["home_region"] = random.choice(REGION_VARIANTS.get(y["home_region"], [y["home_region"]]))
    if rng.random() < 0.20:
        r["gender"] = random.choice(GENDER_VARIANTS[y["gender"]])
    if rng.random() < 0.04:
        r["age"] = None                      # missing
    elif rng.random() < 0.01:
        r["age"] = random.choice([2, 99, 180])  # typo
    if rng.random() < 0.05:
        r["referral_source"] = r["referral_source"].upper()
    raw.append(r)
# duplicate entries (same youth typed twice by different staff)
for r in random.sample(raw, 12):
    raw.append(dict(r))
random.shuffle(raw)

# ---------------------------------------------------------------- dim_date
dates = []
d = START
n = 1
while d <= DATA_CUTOFF:
    dates.append(dict(date=d, day_number=n, year=d.year, quarter=(d.month - 1) // 3 + 1,
                      month=d.month, month_name=d.strftime("%B"), year_month=d.strftime("%Y-%m"),
                      year_quarter=f"{d.year}-Q{(d.month - 1) // 3 + 1}", weekday=d.strftime("%A")))
    d += timedelta(days=1)
    n += 1


# ---------------------------------------------------------------- write
def write(name, rows, cols):
    with open(os.path.join(OUT, name), "w", newline="", encoding="utf-8") as f:
        wr = csv.writer(f)
        wr.writerow(cols)
        for row in rows:
            wr.writerow(["" if row[c] is None else (row[c].isoformat() if isinstance(row[c], date) else row[c])
                         for c in cols])


write("raw_youth_intake.csv", raw, ["youth_id", "intake_date", "age", "gender", "home_region", "primary_issue",
                                     "referral_source", "education_at_intake", "exit_date", "exit_reason"])
write("sessions.csv", sessions, ["session_id", "youth_id", "session_date", "session_type", "duration_min", "attended"])
write("referrals.csv", referrals, ["referral_id", "youth_id", "referral_date", "service_type", "completed"])
write("outcomes.csv", outcomes, ["outcome_id", "youth_id", "checkpoint_month", "assessment_date", "wellbeing_score",
                                 "substance_free_30d", "in_school_or_work", "safe_housing", "reoffended_since_last"])
write("dim_date.csv", dates, ["date", "day_number", "year", "quarter", "month", "month_name", "year_month",
                              "year_quarter", "weekday"])

print(f"youth={len(youth)} raw_rows={len(raw)} sessions={len(sessions)} "
      f"referrals={len(referrals)} outcomes={len(outcomes)} dates={len(dates)}")
