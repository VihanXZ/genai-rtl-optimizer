"""Optimization strategy definitions.

Maps a transformation name to its prompt template. Add new strategies
(logic_restructure, retiming, fsm_opt) following the pipelining pattern.
"""

from pathlib import Path

PROMPTS_DIR = Path(__file__).resolve().parent / "prompts"

STRATEGIES = {
    "retiming": {
        "template_file": "retiming_v1.txt",
        "description": "Relocate existing registers to balance delay, without changing total latency.",
    },
    "pipelining": {
        "template_file": "pipelining_v1.txt",
        "description": "Insert pipeline registers along the critical path.",
    },
}


def load_prompt(transformation: str, **kwargs) -> str:
    """Load a strategy's template and fill in <<PLACEHOLDER>> values."""
    if transformation not in STRATEGIES:
        raise ValueError(f"Unknown transformation: {transformation}")

    template_path = PROMPTS_DIR / STRATEGIES[transformation]["template_file"]
    template = template_path.read_text()

    for key, value in kwargs.items():
        template = template.replace(f"<<{key.upper()}>>", str(value))

    return template
