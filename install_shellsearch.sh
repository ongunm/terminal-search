#!/usr/bin/env bash
set -e

# Make sure scripts dir exists
mkdir -p ~/scripts

# Write Python script exactly as provided
cat > ~/scripts/shellsearch.py <<"EOF"
#!/usr/bin/env python3
import os, sys, itertools, threading, time, json
from openai import OpenAI
import requests

# --- ANSI colours ---
YELLOW = "\033[33m"
BLUE   = "\033[34m"
GREEN  = "\033[32m"
RED    = "\033[31m"
RESET  = "\033[0m"

# --- Spinner style (choose "arc" or "pulse") ---
SPINNER_STYLE = "arc"

SPINNERS = {
    "arc":   ["⠋","⠙","⠹","⠸","⠼","⠴","⠦","⠧","⠇","⠏"],
    "pulse": ["·","●","·"," "]
}

def spinner(label, colour, stop_event):
    frames = SPINNERS.get(SPINNER_STYLE, SPINNERS["arc"])
    # Print label once (keep colour active) and show first frame
    sys.stdout.write(f"{colour}{label} ")
    sys.stdout.flush()

    first = True
    for c in itertools.cycle(frames):
        if stop_event.is_set():
            break
        if first:
            sys.stdout.write(c)
            first = False
        else:
            # Overwrite only the frame character
            sys.stdout.write("\b" + c)
        sys.stdout.flush()
        time.sleep(0.05)

    # Clear the line and reset colours when stopping
    sys.stdout.write("\r\033[K")
    sys.stdout.write(RESET)
    sys.stdout.flush()

def start_spinner(label, colour):
    stop = threading.Event()
    t = threading.Thread(target=spinner, args=(label, colour, stop))
    t.daemon = True
    t.start()
    return stop, t

# --- OpenAI setup ---
client = OpenAI()

if "OPENAI_API_KEY" not in os.environ:
    print(f"{RED}❌ OPENAI_API_KEY not set{RESET}")
    sys.exit(1)

if len(sys.argv) < 2:
    print(f"{RED}❌ No prompt provided{RESET}")
    sys.exit(1)

prompt = sys.argv[1]

stop_event, thread = None, None
searching = False
final_text = []

try:
    stop_event, thread = start_spinner("🤔 Thinking", BLUE)

    with client.responses.stream(
        model="gpt-4o-mini",
        input=prompt,
        tools=[{"type": "web_search"}],
    ) as stream:
        for event in stream:
            etype = getattr(event, "type", None)
            
            # Web search detected - switch to search spinner
            if etype and "web_search_call" in etype:
                if not searching:
                    if stop_event and thread and thread.is_alive():
                        stop_event.set(); thread.join()
                    stop_event, thread = start_spinner("🔎 Searching", YELLOW)
                    searching = True

            # Text output - switch to thinking spinner and collect
            elif etype == "response.output_text.delta" or (etype and "text" in etype.lower() and "delta" in etype.lower()):
                if searching:
                    searching = False
                    if stop_event and thread and thread.is_alive():
                        stop_event.set(); thread.join()
                    stop_event, thread = start_spinner("🤔 Thinking", BLUE)
                
                if hasattr(event, "delta"):
                    final_text.append(event.delta or "")

            # Completion
            elif etype == "response.completed":
                if stop_event and thread and thread.is_alive():
                    stop_event.set(); thread.join()
                break

except requests.exceptions.RequestException as e:
    if stop_event:
        stop_event.set()
        if thread:
            thread.join()
    print(f"\n{RED}❌ Network error:{RESET} {e}")
    sys.exit(1)
except Exception as e:
    if stop_event:
        stop_event.set()
        if thread:
            thread.join()
    print(f"\n{RED}❌ Error:{RESET} {e}")
    sys.exit(1)

# Print final response
if final_text:
    response = "".join(final_text).strip()
    print(f"{GREEN}Final Response:{RESET}")
    print("-----------------------------")
    print(response)
    print("-----------------------------")
EOF

chmod +x ~/scripts/shellsearch.py

# Append Zsh function exactly as provided
cat >> ~/.zshrc <<"EOF"

alias '?'='noglob ?'
function '?'() {
  setopt localoptions noglob
  local key="${OPENAI_API_KEY:-}"

  # Fallback to JSON file if not already set
  if [[ -z "$key" ]]; then
    if [[ -f "$HOME/keys/openaikey.json" ]]; then
      key=$(cat "$HOME/keys/openaikey.json" | jq -r '.OPENAI_API_KEY')
    fi
  fi

  if [[ -z "$key" || "$key" == "null" ]]; then
    echo "❌ No valid OpenAI key found"
    return 1
  fi

  local user_prompt="$*"
  local wrapped_prompt="If it is a knowledge request before responding check the internet regardless at least just to have context or if you dont know the answer use the internet and tailor or fix the response on how user might have wanted after the search and if not knowledge just return a response to the best of your capabilities.\n\nFollowing is the prompt:\n${user_prompt}"

  OPENAI_API_KEY="$key" python3 ~/scripts/shellsearch.py "$wrapped_prompt"
}
EOF

echo "Installed. Reload your shell with: source ~/.zshrc"
