# Quick Start Card - Print This!

## 🚀 Get Started in 3 Steps

```bash
# Step 1: Install dependencies
pip install -r requirements.txt

# Step 2: Build mock database (one-time)
python mock_warehouse.py build

# Step 3: Run all 19 queries
python mock_warehouse.py run

# Results: Check outputs/query_NN.csv files
```

---

## 📂 What You Have

| File | Purpose | Size |
|------|---------|------|
| `mock_warehouse.py` | Core engine | 19 KB |
| `test_automation.py` | Testing framework | 4.5 KB |
| `test2.sql` | 19 SQL queries | ~30 KB |
| `mock_warehouse.duckdb` | Database | 2.6 MB |
| `outputs/` | Query results (CSVs) | Auto-generated |

---

## 📚 Documentation Map

| Start | Read | Time | Learn |
|-------|------|------|-------|
| **Beginner** | README.md | 10 min | Run & use |
| **User** | MOCK_SETUP_GUIDE.md | 20 min | All features |
| **Developer** | IMPLEMENTATION_GUIDE.md | 40 min | Architecture |
| **Coder** | CODE_WALKTHROUGH.md | 30 min | Code patterns |
| **Index** | DOCUMENTATION_INDEX.md | 5 min | Find answers |

---

## ⚡ Common Tasks

```bash
# Run with custom output directory
python mock_warehouse.py run --out my_results

# Rebuild database from scratch
python mock_warehouse.py build

# Full validation & testing
python test_automation.py

# Inspect the database
duckdb mock_warehouse.duckdb
```

---

## 🔧 Quick Modifications

### Add More Subscribers (240 → 1000)
**File:** `mock_warehouse.py`
```python
for index in range(1, 1001):  # Change from 241 to 1001
```
Then rebuild: `python mock_warehouse.py build`

### Change Date Range
**File:** `mock_warehouse.py`
```python
WINDOW_DAYS = 30  # Change from 120
```
Then rebuild: `python mock_warehouse.py build`

### Add SQL Query
**File:** `test2.sql`
```sql
--------------------------------MY NEW QUERY---------------------------------------------------

SELECT id_date, COUNT(*) FROM BI.REF_SUBSCRIBER
GROUP BY id_date;
```
Then run: `python mock_warehouse.py run`

---

## ✅ Verify Installation

```bash
# Check Python
python --version

# Check dependencies
pip show duckdb
pip show pandas

# Build database
python mock_warehouse.py build
# Expected: "built mock_warehouse.duckdb"

# Run queries
python mock_warehouse.py run
# Expected: 19 "query NN: X rows" messages

# Test automation
python test_automation.py
# Expected: "✅ All tests passed!"
```

---

## 🐛 Troubleshooting Quick Guide

| Error | Solution |
|-------|----------|
| `No module duckdb` | `pip install duckdb` |
| `No module pandas` | `pip install pandas` |
| `0 rows returned` | Normal for some queries (GA data) |
| `Ambiguous column` | Run `python mock_warehouse.py build` |
| `File locked` | Kill Python: `taskkill /F /IM python.exe` |
| `No outputs/` | Recreate: `mkdir outputs` |

---

## 📞 Finding Help

| Question | Answer |
|----------|--------|
| How do I run it? | [README.md](README.md) |
| What commands exist? | [MOCK_SETUP_GUIDE.md](MOCK_SETUP_GUIDE.md) |
| How does it work? | [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) |
| Show me code | [CODE_WALKTHROUGH.md](CODE_WALKTHROUGH.md) |
| Where's the answer? | [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) |

---

## 💡 Example - Add Premium Subscriber Flag

```python
# 1. Edit mock_warehouse.py

# Add to Subscriber class (line ~35):
is_premium: int  # 0 or 1

# Add to build_subscribers() (line ~75):
is_premium = 1 if index % 5 == 0 else 0,

# Add to build_database() table creation (line ~120):
is_premium INTEGER

# Update INSERT statement to include is_premium
```

```bash
# 2. Rebuild
python mock_warehouse.py build

# 3. Verify
duckdb mock_warehouse.duckdb
SELECT is_premium, COUNT(*) FROM BI.REF_SUBSCRIBER GROUP BY is_premium;
```

---

## 🎯 Next Steps

- [ ] Read README.md
- [ ] Run 3 commands
- [ ] Check outputs/
- [ ] Run test_automation.py
- [ ] Explore SQL queries
- [ ] Make 1st modification
- [ ] Read IMPLEMENTATION_GUIDE.md
- [ ] Build your feature

---

## 📊 By The Numbers

- **240** mock subscribers
- **120** days of history
- **19** SQL queries
- **11** regions/territories
- **2,836** lines of documentation
- **60 KB** total code
- **2.6 MB** database

---

## 🎓 Learning Paths

### 5-Minute Beginner
1. Read: "Quick Start (3 Commands)" in README.md
2. Run: 3 commands above
3. Done! ✅

### 1-Hour User
1. Read: README.md (10 min)
2. Read: MOCK_SETUP_GUIDE.md (20 min)
3. Run: experiments (20 min)
4. Read: SQL_OVERVIEW.txt (10 min)

### 2-Hour Developer
1. Read: IMPLEMENTATION_GUIDE.md (40 min)
2. Read: CODE_WALKTHROUGH.md (30 min)
3. Make modifications (30 min)
4. Read: DOCUMENTATION_INDEX.md (5 min)

### 4-Hour Master
- Read all documentation
- Try all examples
- Modify code
- Build features
- Test everything

---

## 🚀 You're All Set!

Everything is ready. Pick a learning path above and get started.

**Recommended order:**
1. **README.md** (overview)
2. **Run the 3 commands** (see it work)
3. **MOCK_SETUP_GUIDE.md** (understand features)
4. **IMPLEMENTATION_GUIDE.md** (learn architecture)
5. **CODE_WALKTHROUGH.md** (copy patterns)
6. **Add your first feature!** 🎉

---

## 📝 Quick Notes Template

```markdown
# My Modifications

## Change 1: Added Premium Flag
- Date: ___________
- Changes: ___________
- Result: ___________

## Change 2: ___________
- Date: ___________
- Changes: ___________
- Result: ___________

## Lessons Learned
- ___________
- ___________
```

---

**Print this card and keep it handy! 📌**

Questions? Check DOCUMENTATION_INDEX.md first!
