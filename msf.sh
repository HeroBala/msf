#!/usr/bin/env bash
# msf_sits_note.sh
# Nicely formatted note for MSF SITS – Service Desk Operator

set -euo pipefail

# -----------------------------
# Theming & Terminal Capabilities
# -----------------------------
# Detect terminal width
if command -v tput >/dev/null 2>&1; then
  COLS="$(tput cols || echo 100)"
else
  COLS="${COLUMNS:-100}"
fi

# Clamp width for readability
MAX_WIDTH=100
(( COLS > MAX_WIDTH )) && COLS=$MAX_WIDTH
PADDING=2
CONTENT_WIDTH=$(( COLS - (PADDING*2) ))

# Colors (fallback to no color if tput not available)
if command -v tput >/dev/null 2>&1 && [ -n "${TERM-}" ]; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RESET="$(tput sgr0)"
  FG_PRIMARY="$(tput setaf 6)"     # Cyan
  FG_ACCENT="$(tput setaf 4)"      # Blue
  FG_OK="$(tput setaf 2)"          # Green
  FG_MUTED="$(tput setaf 7)"       # Light gray
else
  BOLD=""; DIM=""; RESET=""
  FG_PRIMARY=""; FG_ACCENT=""; FG_OK=""; FG_MUTED=""
fi

# Unicode box-drawing (fallback to ASCII if not UTF-8)
USE_UNICODE=1
if [ -z "${LC_ALL-}" ] && [ -z "${LC_CTYPE-}" ] && [ -z "${LANG-}" ]; then
  USE_UNICODE=0
fi
case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
  *UTF-8*|*utf8*) : ;;
  *) USE_UNICODE=0 ;;
esac

if [ $USE_UNICODE -eq 1 ]; then
  VERT="│"; HOR="─"; TL="┌"; TR="┐"; BL="└"; BR="┘"; SEP="├"; SEPR="┤"; TSEP="┬"; BSEP="┴"
else
  VERT="|"; HOR="-"; TL="+"; TR="+"; BL="+"; BR="+"; SEP="+"; SEPR="+"; TSEP="+"; BSEP="+"
fi

repeat() { printf '%*s' "$1" '' | tr ' ' "${2:- }"; }

pad_line() {
  # Pad a single line to CONTENT_WIDTH
  local line="$1"
  local len=${#line}
  local spaces=$(( CONTENT_WIDTH - len ))
  (( spaces < 0 )) && spaces=0
  printf "%s%s" "$line" "$(repeat "$spaces" " ")"
}

wrap() {
  # Wrap stdin to CONTENT_WIDTH, preserving words
  if command -v fold >/dev/null 2>&1; then
    fold -s -w "$CONTENT_WIDTH"
  else
    # Minimal fallback: naive wrap using awk
    awk -v width="$CONTENT_WIDTH" '
      {
        line=$0
        while (length(line) > width) {
          space=0
          for (i=width; i>1; i--) {
            if (substr(line, i, 1)==" ") { space=i; break }
          }
          if (space==0) space=width
          print substr(line, 1, space)
          line=substr(line, space+1)
        }
        print line
      }'
  fi
}

print_border_top()    { printf "%s%s%s\n" "$TL" "$(repeat "$((COLS-2))" "$HOR")" "$TR"; }
print_border_bottom() { printf "%s%s%s\n" "$BL" "$(repeat "$((COLS-2))" "$HOR")" "$BR"; }
print_rule()          { printf "%s%s%s\n" "$SEP" "$(repeat "$((COLS-2))" "$HOR")" "$SEPR"; }

print_title() {
  local title="$1"
  printf "%s%s %s%s\n" "$VERT" "$(repeat "$PADDING" " ")" "${BOLD}${FG_PRIMARY}${title}${RESET}" "$(repeat "$((COLS-PADDING-2-${#title}))" " ")"; 
}

print_section_header() {
  local label="$1"
  printf "%s%s%s%s%s\n" "$VERT" "$(repeat "$PADDING" " ")" "${BOLD}${FG_ACCENT}${label}${RESET}" "$(repeat "$((COLS - 2 - PADDING - ${#label}))" " ")" "$VERT"
}

print_paragraph() {
  echo "$1" | wrap | while IFS= read -r line; do
    printf "%s%s" "$VERT" "$(repeat "$PADDING" " ")"
    pad_line "$line"
    printf "%s\n" "$VERT"
  done
}

print_bullet() {
  local bullet="•"
  [ $USE_UNICODE -eq 0 ] && bullet="*"
  local text="$1"
  # First line with bullet
  local first="$(echo "$text" | wrap | head -n1)"
  printf "%s%s%s %s" "$VERT" "$(repeat "$PADDING" " ")" "${FG_OK}${bullet}${RESET}" "$first"
  printf "%s\n" "$(repeat "$((COLS - 2 - PADDING - 2 - ${#first}))" " ")$VERT"
  # Continuation lines indented
  echo "$text" | wrap | tail -n +2 | while IFS= read -r line; do
    printf "%s%s%s%s" "$VERT" "$(repeat "$PADDING" " ")" "$(repeat 2 " ")" "$line"
    printf "%s\n" "$(repeat "$((COLS - 2 - PADDING - 2 - ${#line}))" " ")$VERT"
  done
}

# -----------------------------
# Content
# -----------------------------
TITLE="MSF Shared IT Services (SITS) – Service Desk Operator"

COMPANY_DESC=$'Médecins Sans Frontières (MSF) / Doctors Without Borders is an international humanitarian and medical organization that delivers emergency aid to people affected by armed conflict, epidemics, natural disasters, and healthcare exclusion. Founded in 1971 in France, MSF operates in 70+ countries with 65,000+ staff and is guided by impartiality, independence, and neutrality, funded primarily by private donors.\n\nIn 2019, MSF established the Shared IT Services (SITS) Centre in Prague to provide centralized IT support to the organization’s global network. SITS enables field operations by ensuring smooth, reliable, and secure IT services for 32,000+ users across offices and missions worldwide.'

RESPONSIBILITIES=(
  "Act as the first point of contact for local IT teams and internal users globally."
  "Manage Tier 1 and Tier 2 incidents and requests via ITSM/ticketing tools, ensuring timely, accurate resolution."
  "Administer Microsoft 365 (accounts, licenses, services) and support Azure infrastructure."
  "Guide and train users to confidently use Microsoft 365 applications and related technologies."
  "Maintain and evolve the internal IT knowledge base."
  "Collaborate with networking, security, and specialized IT teams for complex issue resolution."
  "Uphold high user satisfaction and comply with IT Service Level Agreements (SLAs)."
)

WHY_APPEAL=(
  "Purpose-driven impact: apply IT skills to directly support life-saving humanitarian missions."
  "Global exposure: collaborate with colleagues across regions and cultures."
  "Professional growth: deepen Microsoft 365/Azure administration in a large-scale environment."
  "Dynamic environment: international, multicultural setting with training and progression paths."
  "Strong benefits: competitive leave, flexible arrangements, and wellness perks."
)

# -----------------------------
# Render
# -----------------------------
print_border_top
print_title "$TITLE"
print_rule

print_section_header "Company Description"
print_paragraph "$COMPANY_DESC"
print_rule

print_section_header "Role Responsibilities"
for item in "${RESPONSIBILITIES[@]}"; do
  print_bullet "$item"
done
print_rule

print_section_header "Why This Role Might Appeal"
for item in "${WHY_APPEAL[@]}"; do
  print_bullet "$item"
done

print_border_bottom

# Footer hint
printf "%s%s%s%s\n" "$DIM" "Tip: resize your terminal for a wider layout." "$RESET" ""

