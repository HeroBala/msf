#!/usr/bin/env bash
# msf_tier_tickets.sh
# Visual summary of common Tier 1 & Tier 2 tickets for MSF SITS (M365/Azure context)
set -euo pipefail

# -----------------------------
# Configuration & CLI
# -----------------------------
WIDTH="${COLUMNS:-100}"
PLAIN=0
EXPORT_MD=""

while [[ "${1-}" ]]; do
  case "$1" in
    --plain) PLAIN=1 ;;
    --width) WIDTH="${2-}"; shift ;;
    --export-md) EXPORT_MD="${2-}"; shift ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--plain] [--width N] [--export-md FILE]
  --plain         Disable colors and Unicode for maximum compatibility
  --width N       Set output width (default: terminal width or 100)
  --export-md F   Also export a Markdown version to file F
EOF
      exit 0;;
    *) echo "Unknown option: $1" >&2; exit 1;;
  esac
  shift || true
done

# Width clamp
[[ "$WIDTH" -gt 120 ]] && WIDTH=120
[[ "$WIDTH" -lt 70  ]] && WIDTH=70

# -----------------------------
# Theme & Unicode
# -----------------------------
if [[ $PLAIN -eq 0 ]] && command -v tput >/dev/null 2>&1 && [[ -n "${TERM-}" ]]; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
  FG1="$(tput setaf 6)"; FG2="$(tput setaf 4)"; FG3="$(tput setaf 2)"; FG4="$(tput setaf 3)"
  FGm="$(tput setaf 7)"
else
  BOLD=""; DIM=""; RESET=""; FG1=""; FG2=""; FG3=""; FG4=""; FGm=""
fi

USE_UNICODE=1
if [[ $PLAIN -eq 1 ]]; then
  USE_UNICODE=0
else
  case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in *UTF-8*|*utf8*) : ;; *) USE_UNICODE=0 ;; esac
fi

if [[ $USE_UNICODE -eq 1 ]]; then
  VERT="│"; HOR="─"; TL="┌"; TR="┐"; BL="└"; BR="┘"; SEP="├"; SEPR="┤"
  BULLET="•"; BLOCK="█"
else
  VERT="|"; HOR="-"; TL="+"; TR="+"; BL="+"; BR="+"; SEP="+"; SEPR="+"
  BULLET="*"; BLOCK="#"
fi

# -----------------------------
# Data (edit weights to match your environment)
# Relative frequency = 100 total per tier (approximate sample distribution)
# -----------------------------
T1_LABELS=(
  "Password resets (M365)"
  "Account unlocks"
  "MFA setup/help"
  "Email not syncing (mobile)"
  "Teams not loading / cache"
  "OneDrive quick sync fix"
  "SharePoint access request"
  "New user license assignment"
  "Basic printing (network)"
  "How-to guidance (sharing/files)"
)
T1_VALUES=(18 11 10 9 9 9 8 8 9 9)

T2_LABELS=(
  "Complex M365 admin (bulk/licensing/groups)"
  "Azure AD provisioning issues"
  "Mailbox migration problems"
  "Advanced Teams (voice/call queues/federation)"
  "SharePoint permissions (inheritance/owners)"
  "Persistent OneDrive failures (policy/registry)"
  "Conditional Access troubleshooting"
  "App integrations (Power BI/Forms/Planner)"
  "Security alerts follow-up (unusual sign-in)"
  "Connectivity for field locations (VPN/routing)"
)
T2_VALUES=(14 11 10 10 10 9 9 9 9 9)

# -----------------------------
# Helpers
# -----------------------------
pad() { local n="$1"; printf "%*s" "$n" ""; }
repeat() { local n="$1" ch="${2:- }"; printf "%0.s$ch" $(seq 1 "$n"); }
border_line() { printf "%s%s%s\n" "$TL" "$(repeat $((WIDTH-2)) "$HOR")" "$TR"; }
border_sep()  { printf "%s%s%s\n" "$SEP" "$(repeat $((WIDTH-2)) "$HOR")" "$SEPR"; }
border_bot()  { printf "%s%s%s\n" "$BL" "$(repeat $((WIDTH-2)) "$HOR")" "$BR"; }

wrap() { # word wrap stdin to WIDTH-4 (inside borders)
  local max=$((WIDTH-4))
  awk -v w="$max" '
    {
      line=$0
      while (length(line)>w) {
        cut=w
        for(i=w;i>1;i--) if (substr(line,i,1)==" ") {cut=i;break}
        print substr(line,1,cut)
        line=substr(line,cut+1)
      }
      print line
    }'
}

print_block_bar() { # args: value max label
  local val="$1" max="$2" label="$3"
  local chartw=$(( (WIDTH/2) - 8 )); [[ $chartw -lt 12 ]] && chartw=12
  local len=$(( (val * chartw) / max ))
  printf " %s %s%s %3d\n" "$BULLET" "$(repeat "$len" "$BLOCK")" "$(repeat $((chartw-len)) " ")" "$val"
  # label line
  printf "     %s\n" "$label" | wrap
}

print_title() {
  local t="$1"
  border_line
  printf "%s %s%s%s\n" "$VERT" "$BOLD$FG1" "$t" "$RESET" | awk -v w="$((WIDTH-3))" '{printf "%s%s\n",$0,substr("                                                                                                                                                                                        ",1,w-length($0))}'
  border_sep
}

section_header() {
  local t="$1"
  printf "%s %s%s%s\n" "$VERT" "$BOLD$FG2" "$t" "$RESET" | awk -v w="$((WIDTH-3))" '{printf "%s%s\n",$0,substr("                                                                                                                                                                                        ",1,w-length($0))}'
}

paragraph() {
  while IFS= read -r line; do
    printf "%s %s%s%s\n" "$VERT" "$line" "$(pad $((WIDTH-3-${#line})))" "$RESET"
  done < <(echo -e "$1" | wrap)
}

two_col_lists() {
  # prints Tier1 vs Tier2 side-by-side (numbers + labels)
  local colw=$(( (WIDTH-4)/2 ))
  printf "%s %s%-*s%s %s%-*s%s\n" "$VERT" "$BOLD$FG3" "$colw" "Tier 1 — Most Common" "$RESET" "$BOLD$FG4" "$colw" "Tier 2 — Most Common" "$RESET"
  local n=${#T1_LABELS[@]}; [[ ${#T2_LABELS[@]} -gt $n ]] && n=${#T2_LABELS[@]}
  for ((i=0;i<n;i++)); do
    local l1="${T1_LABELS[i]-}"; local l2="${T2_LABELS[i]-}"
    printf "%s %2d. %-*s %2d. %-*s%s\n" \
      "$VERT" "$((i+1))" "$((colw-5))" "${l1:--}" "$((i+1))" "$((colw-5))" "${l2:--}" "$RESET"
  done
}

bar_charts() {
  # Scale bars to max=largest value in each tier
  local max1=0 max2=0
  for v in "${T1_VALUES[@]}"; do (( v>max1 )) && max1=$v; done
  for v in "${T2_VALUES[@]}"; do (( v>max2 )) && max2=$v; done

  printf "%s %s%s%s\n" "$VERT" "$BOLD$FG3" "Tier 1 – Relative Volume" "$RESET" | awk -v w="$((WIDTH-3))" '{printf "%s%s\n",$0,substr("                                                                                                      ",1,w-length($0))}'
  for ((i=0;i<${#T1_VALUES[@]};i++)); do
    print_block_bar "${T1_VALUES[i]}" "$max1" "${T1_LABELS[i]}"
  done
  border_sep
  printf "%s %s%s%s\n" "$VERT" "$BOLD$FG4" "Tier 2 – Relative Volume" "$RESET" | awk -v w="$((WIDTH-3))" '{printf "%s%s\n",$0,substr("                                                                                                      ",1,w-length($0))}'
  for ((i=0;i<${#T2_VALUES[@]};i++)); do
    print_block_bar "${T2_VALUES[i]}" "$max2" "${T2_LABELS[i]}"
  done
}

footer_note() {
  border_sep
  paragraph "${DIM}Note:${RESET} Values are illustrative relative volumes (sum≈100 per tier). Adjust arrays in the script to reflect real MSF SITS data."
  border_bot
}

# -----------------------------
# Render (Terminal)
# -----------------------------
print_title "MSF SITS – Top Tickets: Tier 1 vs Tier 2 (M365/Azure)"
paragraph "Purpose: quick visual for interview/onboarding. Left lists show the top items; bar charts show relative volumes per tier."

border_sep
two_col_lists
border_sep
bar_charts
footer_note

# -----------------------------
# Optional Markdown Export
# -----------------------------
if [[ -n "$EXPORT_MD" ]]; then
  {
    echo "# MSF SITS – Top Tickets: Tier 1 vs Tier 2"
    echo
    echo "Visual summary of common tickets in a Microsoft 365/Azure-centric environment."
    echo
    echo "## Tier 1 – Top 10"
    for ((i=0;i<${#T1_LABELS[@]};i++)); do
      echo "$((i+1)). ${T1_LABELS[i]}  —  **${T1_VALUES[i]}**"
    done
    echo
    echo "## Tier 2 – Top 10"
    for ((i=0;i<${#T2_LABELS[@]};i++)); do
      echo "$((i+1)). ${T2_LABELS[i]}  —  **${T2_VALUES[i]}**"
    done
    echo
    echo "> Note: Values are illustrative relative volumes (sum≈100 per tier)."
  } > "$EXPORT_MD"
  echo "Markdown exported to: $EXPORT_MD" >&2
fi

