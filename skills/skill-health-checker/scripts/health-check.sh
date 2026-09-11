#!/usr/bin/env bash
# Skill Health Checker — Audit all installed skills across all agents
# Inspired by skills-janitor, built for multi-agent setups (Pi, Claude, Codex, omp, OpenCode)
#
# Usage:
#   health-check.sh                  # Full report
#   health-check.sh --brief          # Inventory only
#   health-check.sh --json           # Machine-readable
#   health-check.sh --security       # Security scan only
#   health-check.sh --tokens         # Token estimate only
#   health-check.sh --dupes          # Duplicate detection only
#   health-check.sh --scope user     # User-scope only
#   health-check.sh --scope project  # Project-scope only

set -euo pipefail

command -v python3 &>/dev/null || { echo "ERROR: python3 required" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRIEF=false
JSON_OUTPUT=false
SECURITY_ONLY=false
TOKENS_ONLY=false
DUPES_ONLY=false
SCOPE="all"
BUDGET=200000

while [[ $# -gt 0 ]]; do
  case "$1" in
    --brief)     BRIEF=true; shift ;;
    --json)      JSON_OUTPUT=true; shift ;;
    --security)  SECURITY_ONLY=true; shift ;;
    --tokens)    TOKENS_ONLY=true; shift ;;
    --dupes)     DUPES_ONLY=true; shift ;;
    --scope)     SCOPE="$2"; shift 2 ;;
    --budget)    BUDGET="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# ────────────────────────────────────────────────────────────────────────────
# Collect all skill directories
# ────────────────────────────────────────────────────────────────────────────
SKILLS_TSV=$(mktemp -t health-check.XXXXXX)
trap 'rm -f "$SKILLS_TSV"' EXIT

_f() {
  local v="${1:-}"
  v="${v//$'\t'/ }"
  v="${v//$'\n'/ }"
  [[ -z "$v" ]] && v="_"
  printf '%s' "$v"
}

add_skill() {
  local path="$1" scope="$2" agent="$3" namespace="${4:-}"
  [[ -d "$path" || -L "$path" ]] || return 0
  [[ -f "$path" ]] && return 0
  local name
  name=$(basename "$path")
  local qualified="$name"
  [[ -n "$namespace" ]] && qualified="${namespace}:${name}"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(_f "$name")" "$(_f "$scope")" "$(_f "$agent")" "$(_f "$qualified")" "$(_f "$path")" >> "$SKILLS_TSV"
}

# User-scope skills
if [[ "$SCOPE" == "all" || "$SCOPE" == "user" ]]; then
  for agent_dir in \
    "$HOME/.pi/agent/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.agents/skills" \
    "$HOME/.config/opencode/skills" \
    "$HOME/.omp/agent/skills"; do
    [[ -d "$agent_dir" ]] || continue
    agent_name=$(basename "$(dirname "$agent_dir")")
    [[ "$agent_name" == "skills" ]] && agent_name=$(basename "$(dirname "$(dirname "$agent_dir")")")
    for skill_dir in "$agent_dir"/*; do
      [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
      add_skill "$skill_dir" "user" "$agent_name"
    done
  done

  # Plugin skills
  if [[ -d "$HOME/.claude/plugins/marketplaces" ]]; then
    for plugin_dir in "$HOME/.claude/plugins/marketplaces"/*/; do
      [[ -d "$plugin_dir" ]] || continue
      plugin_name=$(basename "$plugin_dir")
      for sub in "skills" ".claude/skills"; do
        skill_parent="$plugin_dir$sub"
        [[ -d "$skill_parent" ]] || continue
        for skill_dir in "$skill_parent"/*; do
          [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
          add_skill "$skill_dir" "plugin" "claude" "$plugin_name"
        done
      done
    done
  fi

  # Source skills
  if [[ -d "$HOME/.claude/sources" ]]; then
    for source_dir in "$HOME/.claude/sources"/*/; do
      [[ -d "$source_dir" ]] || continue
      source_name=$(basename "$source_dir")
      skill_parent="$source_dir/skills"
      [[ -d "$skill_parent" ]] || continue
      for skill_dir in "$skill_parent"/*; do
        [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
        add_skill "$skill_dir" "source" "claude" "$source_name"
      done
    done
  fi
fi

# Project-scope skills
if [[ "$SCOPE" == "all" || "$SCOPE" == "project" ]]; then
  for skill_dir in ./.claude/skills/* ./.agents/skills/*; do
    [[ -d "$skill_dir" || -L "$skill_dir" ]] || continue
    add_skill "$skill_dir" "project" "local"
  done 2>/dev/null || true
fi

TOTAL_SKILLS=$(wc -l < "$SKILLS_TSV" | tr -d ' ')

if [[ "$TOTAL_SKILLS" -eq 0 ]]; then
  echo "No skills found."
  exit 0
fi

# ────────────────────────────────────────────────────────────────────────────
# Run analysis in Python
# ────────────────────────────────────────────────────────────────────────────
export SKILLS_TSV BUDGET BRIEF JSON_OUTPUT SECURITY_ONLY TOKENS_ONLY DUPES_ONLY

python3 << 'PYEOF'
import json
import math
import os
import re
import sys
from collections import defaultdict
from datetime import datetime

SKILLS_TSV = os.environ["SKILLS_TSV"]
BUDGET = int(os.environ.get("BUDGET", "200000"))
BRIEF = os.environ.get("BRIEF", "false") == "true"
JSON_OUTPUT = os.environ.get("JSON_OUTPUT", "false") == "true"
SECURITY_ONLY = os.environ.get("SECURITY_ONLY", "false") == "true"
TOKENS_ONLY = os.environ.get("TOKENS_ONLY", "false") == "true"
DUPES_ONLY = os.environ.get("DUPES_ONLY", "false") == "true"

# ─── Load skills ────────────────────────────────────────────────────────────
skills = []
with open(SKILLS_TSV) as f:
    for line in f:
        parts = line.rstrip("\n").split("\t", 4)
        if len(parts) < 5:
            continue
        name, scope, agent, qualified, path = parts
        skills.append({
            "name": name,
            "scope": scope,
            "agent": agent,
            "qualified": qualified,
            "path": path,
        })

# ─── SKILL.md analysis ──────────────────────────────────────────────────────
STOP_WORDS = {
    "use", "when", "the", "user", "wants", "to", "or", "and", "a", "an",
    "this", "skill", "also", "that", "for", "with", "in", "on", "of",
    "is", "are", "it", "be", "as", "at", "by", "from", "their", "they",
    "has", "have", "do", "does", "can", "will", "about", "not", "but",
    "if", "its", "into", "your", "you", "how", "what", "which", "any",
    "all", "each", "every", "both", "more", "most", "other", "some",
    "such", "than", "too", "very", "just", "only", "own", "same",
}

def extract_keywords(text):
    words = re.findall(r'[a-z]+', text.lower())
    return set(w for w in words if w not in STOP_WORDS and len(w) > 2)

def estimate_tokens(text):
    return max(1, len(text) // 4)

def extract_description(skill_file):
    """Extract description from frontmatter, handles block scalars."""
    try:
        with open(skill_file, encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except OSError:
        return ""
    in_fm = False
    desc_lines = []
    capture = False
    for line in lines:
        stripped = line.rstrip("\n").rstrip("\r")
        if stripped == "---":
            if not in_fm:
                in_fm = True
                continue
            else:
                break
        if in_fm:
            if stripped.startswith("description:"):
                val = stripped[len("description:"):].strip().strip('"').strip("'")
                if val in ("|", ">", "|-", "|+", ">-", ">+"):
                    capture = True
                    continue
                if val:
                    return val
                capture = True
                continue
            if capture:
                if stripped.startswith("  ") or stripped.startswith("\t"):
                    desc_lines.append(stripped.strip())
                else:
                    break
    return " ".join(desc_lines)

# Analyze each skill
analyzed = []
for s in skills:
    path = s["path"]
    skill_file = None
    for candidate in ["SKILL.md", "Skill.md"]:
        p = os.path.join(path, candidate)
        if os.path.isfile(p):
            skill_file = p
            break

    info = {
        "name": s["name"],
        "scope": s["scope"],
        "agent": s["agent"],
        "qualified": s["qualified"],
        "path": path,
        "has_skill_file": skill_file is not None,
        "is_symlink": os.path.islink(path),
        "symlink_broken": os.path.islink(path) and not os.path.exists(path),
        "has_frontmatter": False,
        "description": "",
        "body_tokens": 0,
        "desc_tokens": 0,
        "total_tokens": 0,
        "line_count": 0,
        "extra_files": 0,
        "security_findings": [],
        "keywords": set(),
    }

    if skill_file:
        try:
            with open(skill_file, encoding="utf-8", errors="replace") as f:
                content = f.read()
        except OSError:
            content = ""

        lines = content.split("\n")
        info["line_count"] = len([l for l in lines if l.strip()])

        # Frontmatter check
        if lines and lines[0].strip() == "---":
            info["has_frontmatter"] = True

        # Description
        desc = extract_description(skill_file)
        info["description"] = desc
        info["desc_tokens"] = estimate_tokens(desc)
        info["keywords"] = extract_keywords(desc)

        # Body tokens (everything after second ---)
        fm_end = 0
        found_first = False
        for i, line in enumerate(lines):
            if line.strip() == "---":
                if not found_first:
                    found_first = True
                else:
                    fm_end = i + 1
                    break
        body = "\n".join(lines[fm_end:])
        info["body_tokens"] = estimate_tokens(body)
        info["total_tokens"] = info["desc_tokens"] + info["body_tokens"]

    # Extra files count
    if os.path.isdir(path):
        count = 0
        for root, dirs, files in os.walk(path):
            dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
            for fn in files:
                if fn not in ("SKILL.md", "Skill.md", ".DS_Store"):
                    count += 1
            if count > 50:
                break
        info["extra_files"] = count

    analyzed.append(info)

# ─── Security scan ──────────────────────────────────────────────────────────
def security_scan(skill_info):
    findings = []
    path = skill_info["path"]

    MD_RULES = [
        ("inj-ignore", "HIGH", re.compile(r"(ignore|disregard|forget)\s+(all\s+|any\s+)?(previous|prior|above|earlier)\s+(instructions?|prompts?|rules?)", re.I),
         "Instruction-override phrase"),
        ("inj-conceal", "HIGH", re.compile(r"do\s+not\s+(tell|inform|mention)(\s+(this|it|anything))?\s+(to\s+)?the\s+(user|human|operator)", re.I),
         "Tells agent to hide from user"),
        ("inj-secrecy", "HIGH", re.compile(r"\b(secretly|covertly)\s+(run|execute|send|upload|install|delete|download)\b|\bwithout\s+the\s+user('|')?s\s+knowledge\b", re.I),
         "Secrecy directive"),
        ("inj-newrole", "MEDIUM", re.compile(r"\byou\s+are\s+no\s+longer\b|\bnew\s+system\s+prompt\b|\boverride\s+(the\s+)?system\s+prompt\b", re.I),
         "Role override language"),
    ]

    SCRIPT_RULES = [
        ("sh-curlpipe", "HIGH", re.compile(r"\b(curl|wget)\b[^\n|;&]*\|\s*(sudo\s+)?(ba)?sh\b"),
         "Network piped into shell"),
        ("sh-b64exec", "HIGH", re.compile(r"base64\s+(-d|--decode)[^\n]*\|\s*(sudo\s+)?(ba)?sh\b"),
         "Decode-and-execute"),
        ("sh-creds", "HIGH", re.compile(r"(~|\$HOME|/Users/[^/\s]+|/home/[^/\s]+)/(\.ssh/|\.aws/credentials|\.netrc|\.gnupg/)"),
         "Touches credential stores"),
        ("sh-shortener", "HIGH", re.compile(r"https?://(bit\.ly|tinyurl\.com|t\.co|goo\.gl|is\.gd|cutt\.ly)/"),
         "URL shortener"),
        ("sh-http", "MEDIUM", re.compile(r"\b(curl|wget)\b[^\n]*\bhttp://(?!localhost|127\.0\.0\.1)"),
         "Plain-HTTP call"),
    ]

    UNI_ALWAYS = re.compile("[\u200b\u2060\u202a-\u202e\ufeff]")
    HTML_COMMENT = re.compile(r"<!--(.*?)-->", re.S)
    B64_BLOB = re.compile(r"[A-Za-z0-9+/]{120,}={0,2}")

    def scan_file(fp, rel, is_md):
        try:
            if os.path.getsize(fp) > 1_000_000:
                return
            with open(fp, encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError:
            return

        # Zero-width unicode
        m = UNI_ALWAYS.search(text)
        if m:
            ctx = text[max(0, m.start()-40):m.start()+40]
            findings.append({"rule": "uni-hidden", "severity": "HIGH",
                           "title": "Zero-width/bidi unicode", "file": rel, "evidence": repr(ctx)[:120]})

        if is_md:
            for rule_id, sev, rx, title in MD_RULES:
                m = rx.search(text)
                if m:
                    findings.append({"rule": rule_id, "severity": sev, "title": title,
                                   "file": rel, "evidence": text[max(0, m.start()-30):m.end()+30][:120]})
            # HTML comments
            for m in HTML_COMMENT.finditer(text):
                body = m.group(1)
                if len(body) > 20:
                    findings.append({"rule": "md-htmlcomment", "severity": "MEDIUM",
                                   "title": "HTML comment with content", "file": rel, "evidence": body[:120]})
                    break
            # Base64 blobs
            for m in B64_BLOB.finditer(text):
                blob = m.group(0)
                try:
                    decoded = base64.b64decode(blob + "=" * (-len(blob) % 4), validate=False)
                    printable = sum(1 for b in decoded if 32 <= b < 127 or b in (9, 10, 13))
                    if printable / max(1, len(decoded)) > 0.85:
                        findings.append({"rule": "md-b64", "severity": "MEDIUM",
                                       "title": "Large decodable base64", "file": rel,
                                       "evidence": blob[:60] + "..."})
                        break
                except Exception:
                    pass
        else:
            for rule_id, sev, rx, title in SCRIPT_RULES:
                m = rx.search(text)
                if m:
                    line_start = text.rfind("\n", 0, m.start()) + 1
                    line_end = text.find("\n", m.end())
                    findings.append({"rule": rule_id, "severity": sev, "title": title,
                                   "file": rel, "evidence": text[line_start:line_end][:120]})

    MD_EXT = {".md", ".markdown", ".txt"}
    SCRIPT_EXT = {".sh", ".bash", ".zsh", ".py", ".js", ".mjs", ".ts", ".rb"}

    import base64
    n = 0
    for root, dirs, files in os.walk(path):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", "__pycache__")]
        for fn in files:
            if n >= 100:
                break
            fp = os.path.join(root, fn)
            if os.path.islink(fp):
                continue
            ext = os.path.splitext(fn)[1].lower()
            rel = os.path.relpath(fp, path)
            if ext in MD_EXT:
                scan_file(fp, rel, True)
                n += 1
            elif ext in SCRIPT_EXT:
                scan_file(fp, rel, False)
                n += 1

    return findings

if not TOKENS_ONLY and not DUPES_ONLY:
    for s in analyzed:
        s["security_findings"] = security_scan(s)

# ─── Duplicate detection ────────────────────────────────────────────────────
def find_dupes(skills_list):
    # Group by realpath (dedup symlinks)
    by_realpath = {}
    for s in skills_list:
        rp = os.path.realpath(s["path"])
        if rp not in by_realpath:
            by_realpath[rp] = s

    unique = list(by_realpath.values())

    # Name collisions
    by_name = defaultdict(list)
    for s in unique:
        by_name[s["qualified"]].append(s)
    name_collisions = {n: lst for n, lst in by_name.items() if len(lst) > 1}

    # Description overlap (Jaccard)
    overlaps = []
    for i in range(len(unique)):
        kw_i = unique[i]["keywords"]
        if not kw_i:
            continue
        for j in range(i + 1, len(unique)):
            kw_j = unique[j]["keywords"]
            if not kw_j:
                continue
            common = kw_i & kw_j
            union = kw_i | kw_j
            sim = len(common) / len(union) if union else 0
            if sim > 0.3:
                overlaps.append({
                    "a": unique[i]["qualified"],
                    "b": unique[j]["qualified"],
                    "similarity": round(sim * 100),
                    "common": sorted(common)[:8],
                    "scope_a": unique[i]["scope"],
                    "scope_b": unique[j]["scope"],
                })
    overlaps.sort(key=lambda x: x["similarity"], reverse=True)

    return name_collisions, overlaps

name_collisions, overlaps = find_dupes(analyzed)

# ─── Build output ───────────────────────────────────────────────────────────
def severity_rank(f):
    return {"HIGH": 0, "MEDIUM": 1, "INFO": 2}.get(f["severity"], 3)

total_tokens = sum(s["total_tokens"] for s in analyzed)
desc_tokens = sum(s["desc_tokens"] for s in analyzed)
budget_pct = (total_tokens / BUDGET * 100) if BUDGET else 0

risk_skills = [s for s in analyzed if any(f["severity"] == "HIGH" for f in s["security_findings"])]
review_skills = [s for s in analyzed if not any(f["severity"] == "HIGH" for f in s["security_findings"]) and any(f["severity"] == "MEDIUM" for f in s["security_findings"])]
pass_skills = [s for s in analyzed if not s["security_findings"]]

top_tokens = sorted(analyzed, key=lambda s: s["total_tokens"], reverse=True)[:10]
unused = [s for s in analyzed if s["description"] == "" and not s["has_skill_file"]]
broken = [s for s in analyzed if s["symlink_broken"]]

# ─── JSON output ────────────────────────────────────────────────────────────
if JSON_OUTPUT:
    out = {
        "scan_date": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
        "total_skills": len(analyzed),
        "total_tokens": total_tokens,
        "desc_tokens": desc_tokens,
        "budget_pct": round(budget_pct, 1),
        "security": {"risk": len(risk_skills), "review": len(review_skills), "passed": len(pass_skills)},
        "broken_symlinks": len(broken),
        "name_collisions": len(name_collisions),
        "description_overlaps": len(overlaps),
        "skills": [{k: v for k, v in s.items() if k != "keywords"} for s in analyzed],
    }
    print(json.dumps(out, indent=2, default=str))
    sys.exit(0)

# ─── Human-readable output ──────────────────────────────────────────────────
if SECURITY_ONLY:
    print("=== Security Scan ===")
    print(f"Scanned: {len(analyzed)} skills | RISK: {len(risk_skills)} | REVIEW: {len(review_skills)} | PASS: {len(pass_skills)}")
    print()
    for s in risk_skills + review_skills:
        verdict = "RISK" if any(f["severity"] == "HIGH" for f in s["security_findings"]) else "REVIEW"
        print(f"[{verdict}] {s['qualified']} ({s['scope']}/{s['agent']})")
        for f in sorted(s["security_findings"], key=severity_rank):
            print(f"    {f['severity']:<6} {f['title']}")
            print(f"           {f['file']}: {f['evidence'][:100]}")
        print()
    if not risk_skills and not review_skills:
        print("No suspicious patterns found.")
    sys.exit(0)

if TOKENS_ONLY:
    print("=== Token Cost Estimate ===")
    print(f"Budget: {BUDGET:,} tokens")
    print(f"Total:  {total_tokens:,} tokens ({budget_pct:.1f}% of budget)")
    print(f"Always-loaded (descriptions): {desc_tokens:,} tokens")
    print(f"On-trigger (bodies):          {total_tokens - desc_tokens:,} tokens")
    print()
    print(f"{'Skill':<40} {'Desc':>6} {'Body':>6} {'Total':>6}")
    print("-" * 62)
    for s in top_tokens:
        print(f"{s['qualified']:<40} {s['desc_tokens']:>6} {s['body_tokens']:>6} {s['total_tokens']:>6}")
    sys.exit(0)

if DUPES_ONLY:
    print("=== Duplicate Detection ===")
    print()
    if name_collisions:
        print(f"--- Name Collisions ({len(name_collisions)}) ---")
        for name, entries in name_collisions.items():
            print(f"  {name}")
            for e in entries:
                print(f"    [{e['scope']}/{e['agent']}] {e['path']}")
            print()
    if overlaps:
        print(f"--- Description Overlap ({len(overlaps)}) ---")
        for o in overlaps:
            print(f"  [{o['similarity']}%] {o['a']} <-> {o['b']}")
            print(f"       Scopes: {o['scope_a']} / {o['scope_b']}")
            print(f"       Shared: {', '.join(o['common'][:6])}")
            print()
    if not name_collisions and not overlaps:
        print("No duplicates detected.")
    sys.exit(0)

# ─── Full report ────────────────────────────────────────────────────────────
print("=== Skill Health Checker ===")
print(f"Skills found: {len(analyzed)} across {len(set(s['agent'] for s in analyzed))} agents")
print(f"Budget: {BUDGET:,} tokens | Used: {total_tokens:,} ({budget_pct:.1f}%)")
print()

if BRIEF:
    # Brief mode: inventory only
    by_agent = defaultdict(list)
    for s in analyzed:
        by_agent[s["agent"]].append(s)
    for agent, agent_skills in sorted(by_agent.items()):
        print(f"  {agent}: {len(agent_skills)} skills")
    sys.exit(0)

# --- Inventory ---
print("--- Inventory ---")
by_agent = defaultdict(list)
for s in analyzed:
    by_agent[s["agent"]].append(s)
for agent, agent_skills in sorted(by_agent.items()):
    no_fm = sum(1 for s in agent_skills if not s["has_frontmatter"])
    no_file = sum(1 for s in agent_skills if not s["has_skill_file"])
    symlinks = sum(1 for s in agent_skills if s["is_symlink"])
    line = f"  {agent:<12} {len(agent_skills):>3} skills"
    if no_file:
        line += f"  ⚠ {no_file} missing SKILL.md"
    if no_fm:
        line += f"  ⚠ {no_fm} no frontmatter"
    if symlinks:
        line += f"  🔗 {symlinks} symlinks"
    print(line)
print()

# --- Broken symlinks ---
if broken:
    print(f"--- Broken Symlinks ({len(broken)}) ---")
    for s in broken:
        target = os.readlink(s["path"]) if os.path.islink(s["path"]) else "?"
        print(f"  ✗ {s['qualified']} -> {target}")
    print()

# --- Security ---
if risk_skills or review_skills:
    print(f"--- Security ({len(risk_skills)} RISK, {len(review_skills)} REVIEW) ---")
    for s in risk_skills + review_skills:
        verdict = "RISK" if any(f["severity"] == "HIGH" for f in s["security_findings"]) else "REVIEW"
        print(f"  [{verdict}] {s['qualified']}")
        for f in sorted(s["security_findings"], key=severity_rank):
            print(f"         {f['severity']:<6} {f['title']}")
    print()
elif not TOKENS_ONLY:
    print("--- Security: All clear ---")
    print()

# --- Tokens ---
print(f"--- Token Cost ---")
print(f"  Total: {total_tokens:,} / {BUDGET:,} ({budget_pct:.1f}%)")
print(f"  Always-loaded (descriptions): {desc_tokens:,}")
print()
print(f"  {'Skill':<35} {'Agent':<8} {'Tokens':>6}  {'%':>5}")
print(f"  {'-'*58}")
for s in top_tokens:
    pct = (s["total_tokens"] / BUDGET * 100) if BUDGET else 0
    print(f"  {s['qualified']:<35} {s['agent']:<8} {s['total_tokens']:>6}  {pct:>4.1f}%")
print()

# --- Duplicates ---
if name_collisions or overlaps:
    print(f"--- Duplicates ({len(name_collisions)} name collisions, {len(overlaps)} overlaps) ---")
    for name, entries in list(name_collisions.items())[:5]:
        print(f"  ⚠ Name collision: {name}")
        for e in entries:
            print(f"    [{e['scope']}/{e['agent']}] {e['path']}")
    for o in overlaps[:5]:
        print(f"  [{o['similarity']}%] {o['a']} <-> {o['b']}")
    print()

# --- Summary ---
print("=== Summary ===")
print(f"  Skills: {len(analyzed)}")
print(f"  Agents: {len(set(s['agent'] for s in analyzed))}")
print(f"  Context: {total_tokens:,} tokens ({budget_pct:.1f}% of {BUDGET:,})")
if risk_skills:
    print(f"  ⚠ Security: {len(risk_skills)} skills need manual review (RISK)")
if broken:
    print(f"  ✗ Broken symlinks: {len(broken)}")
if name_collisions:
    print(f"  ⚠ Name collisions: {len(name_collisions)}")
if overlaps:
    print(f"  ⚠ Description overlaps: {len(overlaps)}")
PYEOF
