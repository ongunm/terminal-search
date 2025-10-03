# terminal-search

A web-search CLI tool assisted with AI for quick research in between commands.

## What is it?

A lightweight shell function that lets you ask questions directly from your terminal. The AI automatically searches the web when needed and provides real-time answers with proper citations.

## Features

- 🔍 **Automatic web search** - AI decides when to search for current information
- 🌀 **Live status indicators** - Shows "🔎 Searching" and "🤔 Thinking" spinners
- 🎯 **Smart context** - Searches for weather, news, current events, and more
- ⚡ **Fast & lightweight** - Minimal dependencies, runs in any terminal

## Installation

### Prerequisites

- Python 3.7+
- OpenAI API key

### Quick Install

```bash
# Clone or download the install script, then run:
bash install.sh

# Or manually:
pip install -r requirements.txt
chmod +x shellsearch.py
```

### Setup

1. Set your OpenAI API key:
   ```bash
   export OPENAI_API_KEY="sk-..."
   ```
   
   Or store it in `~/keys/openaikey.json`:
   ```json
   {
     "OPENAI_API_KEY": "sk-..."
   }
   ```

2. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## Usage

Simply use `?` followed by your question:

```bash
? what's the weather in tokyo right now
? latest news on AI
? explain kubernetes in simple terms
? upcoming movies in 2024
```

The tool will:
1. Show a thinking spinner while the AI processes your query
2. Automatically search the web if needed (yellow "Searching" spinner)
3. Display the final answer with sources

## Examples

```bash
# Current information
? what's the stock price of AAPL

# Weather queries
? weather in amsterdam now

# General knowledge
? how does photosynthesis work

# News & current events
? latest updates on space exploration
```

## Configuration

Edit `~/scripts/shellsearch.py` to customize:

- **Spinner style**: Change `SPINNER_STYLE` to `"arc"` or `"pulse"`
- **Model**: Change `model="gpt-4o-mini"` to other OpenAI models
- **Prompt wrapper**: Modify the wrapper in `.zshrc` function

## Requirements

See `requirements.txt`:
