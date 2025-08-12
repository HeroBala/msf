#!/usr/bin/env bash
# MSF Interview Q&A - Plain View (Enhanced Visualization)
# Usage: chmod +x msf_interview_plain.sh && ./msf_interview_plain.sh
# Goal: Plain, sequential display with clean visual formatting. No menus, filters, or sorting.

# ---------- Styling ----------
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold); DIM=$(tput dim); RESET=$(tput sgr0)
  FG_TITLE=$(tput setaf 4)   # Blue
  FG_QNUM=$(tput setaf 2)    # Green
  FG_ANS=$(tput setaf 6)     # Cyan
  FG_RULE=$(tput setaf 5)    # Magenta
  FG_WARN=$(tput setaf 3)    # Yellow
else
  BOLD=""; DIM=""; RESET=""
  FG_TITLE=""; FG_QNUM=""; FG_ANS=""; FG_RULE=""; FG_WARN=""
fi

cols() { tput cols 2>/dev/null || echo 80; }

rule() {
  local c=${1:-"─"}
  printf "%s" "${FG_RULE}"
  printf "%${2:-$(cols)}s" | tr ' ' "$c"
  printf "%s\n" "${RESET}"
}

center() {
  local text="$1" width; width=$(cols)
  local pad=$(( (width - ${#text}) / 2 ))
  [ "$pad" -lt 0 ] && pad=0
  printf "%*s%s\n" "$pad" "" "$text"
}

wrap() {
  # Wrap stdin to terminal width minus left/right padding
  local pad_left=${1:-2}
  local pad_right=${2:-2}
  local width=$(cols)
  local wrapw=$(( width - pad_left - pad_right ))
  [ "$wrapw" -lt 20 ] && wrapw=20
  if command -v fold >/dev/null 2>&1; then
    fold -s -w "$wrapw" | sed "s/^/$(printf '%*s' "$pad_left")/"
  else
    # Fallback naive wrapper with awk
    awk -v w="$wrapw" -v p="$pad_left" '
      {
        line=$0
        while (length(line)>w) {
          for (i=w; i>0 && substr(line,i,1)!=" "; i--) {}
          if (i==0) i=w
          print sprintf("%"p"s%s"," ",substr(line,1,i))
          line=substr(line,i+1)
        }
        print sprintf("%"p"s%s"," ",line)
      }'
  fi
}

progress() {
  local cur=$1 total=$2
  local width=$(cols)
  local barw=$(( width - 18 ))
  [ $barw -lt 10 ] && barw=10
  local filled=$(( barw * cur / total ))
  local empty=$(( barw - filled ))
  printf "%s[" "${DIM}"
  printf "%0.s#" $(seq 1 $filled)
  printf "%0.s." $(seq 1 $empty)
  printf "] %2d/%-2d%s\n" "$cur" "$total" "${RESET}"
}

# ---------- Data (ID|Question|Answer) ----------
DATA=$(cat <<'EOF'
1|What is your experience with Microsoft 365 administration?|User creation, license assignment, MFA, mailbox management, SharePoint permissions, OneDrive sync troubleshooting.
2|How would you troubleshoot Teams not loading?|Check credentials → service health → internet/VPN → clear cache → try web → escalate if unresolved.
3|Difference between Tier 1 and Tier 2 support?|Tier 1: common issues using KB; Tier 2: complex, requires deeper admin skills.
4|How do you prioritize tickets?|Based on urgency + impact; follow SLA; critical outages take priority.
5|How do you reset a OneDrive sync issue?|Check connection → restart client → clear cache → reset OneDrive → re-sync.
6|How do you create a new user in M365?|Admin center → Add user → set details → assign license → configure MFA.
7|What is Conditional Access in Azure AD?|Policies controlling access based on conditions like location, device, MFA.
8|How would you handle a mailbox migration issue?|Verify source/target, check migration batch, correct permissions, retry.
9|How do you fix SharePoint permission issues?|Check group membership, restore inheritance, update permissions as needed.
10|How do you handle MFA setup problems?|Verify contact methods, reset MFA in admin, guide user through setup.
11|How do you diagnose slow Outlook performance?|Check network, service health, disable add-ins, rebuild profile.
12|What is your process for handling a VPN connection failure?|Check credentials, server status, firewall, network adapter settings.
13|Tell me about a time you helped a frustrated user.|Kept calm, reassured, explained steps, fixed issue, followed up for satisfaction.
14|How do you handle urgent incidents during night shifts?|Prioritize, troubleshoot quickly, provide workaround, escalate if needed.
15|How do you act when you don’t know the answer?|Research or escalate, document all actions, keep user updated.
16|How do you work with colleagues in different time zones?|Clear documentation, concise updates, respect time differences.
17|Give an example of multitasking in high-pressure situations.|Managed multiple high-priority tickets by timeboxing tasks and constant updates.
18|How do you explain technical issues to non-technical users?|Use plain language, analogies, avoid jargon, confirm understanding.
19|Tell me about a mistake you made and how you handled it.|Admitted error, fixed quickly, documented to prevent recurrence.
20|How do you keep yourself updated on tech changes?|Online training, Microsoft Learn, IT community forums.
21|Describe a time you worked on a team to solve a problem.|Coordinated with network and security teams to fix VPN outage.
22|How do you ensure high user satisfaction?|Quick response, clear communication, follow-ups after resolution.
23|Why do you want to work for MSF?|Humanitarian mission, meaningful impact, support life-saving operations.
24|How do you align with MSF’s values?|Respect impartiality, independence, neutrality; treat all users equally.
25|What does good customer service mean in IT?|Efficient problem-solving with patience, empathy, and clarity.
26|How do you handle cultural differences in support?|Listen actively, be respectful, adapt communication style.
27|What’s challenging about working in a 3-shift rotation?|Managing sleep and life balance; requires discipline and adaptability.
28|How do you keep track of tickets in progress?|Use ITSM system, update logs, set reminders for follow-up.
29|How would you handle an SLA breach risk?|Escalate early, re-prioritize, communicate delays to stakeholders.
30|How do you deal with repetitive issues from users?|Educate user, create KB article, suggest preventive measures.
31|Why should we hire you for this role?|Technical skills + service mindset + flexibility + passion for MSF’s mission.
32|What motivates you in IT support?|Helping people work effectively, solving problems, continuous learning.
EOF
)

# ---------- Render ----------
clear
rule "═"
center "${BOLD}${FG_TITLE}MSF Interview Questions & Answers${RESET}"
rule "═"
echo

total=$(printf "%s\n" "$DATA" | wc -l | awk '{print $1}')
idx=0

printf "%sTip:%s Plain scrolling view. No filters or search.\n" "${DIM}" "${RESET}"
rule

printf "%s" "$DATA" | while IFS='|' read -r id question answer; do
  idx=$((idx+1))

  # Header line
  printf "%s┌─ Q%s%02d%s ─%s\n" "${FG_TITLE}" "${FG_QNUM}${BOLD}" "$id" "${RESET}${FG_TITLE}" "${RESET}"

  # Question
  printf "%s● Question:%s\n" "${BOLD}" "${RESET}"
  printf "%s" "$question" | wrap 4 2

  # Spacer + Answer
  echo
  printf "%s■ Answer:%s\n" "${FG_ANS}${BOLD}" "${RESET}"
  printf "%s" "$answer" | wrap 4 2

  # Footer box line + progress
  printf "%s└" "${FG_TITLE}"
  printf "%0.s─" $(seq 1 $(( $(cols) - 2 )))
  printf "%s\n" "${RESET}"
  progress "$idx" "$total"
  rule

done

echo
printf "%sAll %d Q&A items displayed.%s\n" "${FG_WARN}${BOLD}" "$total" "${RESET}"
