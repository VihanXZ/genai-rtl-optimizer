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
    "restructure": {
        "template_file": "restructure_v1.txt",
        "description": "Restructure combinational logic (balance XOR trees, factor subexpressions) without adding latency.",
    },
    "fsm_opt": {
        "template_file": "fsm_opt_v1.txt",
        "description": "Optimize FSM encoding and next-state logic to reduce decode depth.",
    },
}


def load_prompt(transformation: str, previous_error: str | None = None, previous_candidate: str | None = None, **kwargs) -> str:
    """Load a strategy's template and fill in <<PLACEHOLDER>> values."""
    if transformation not in STRATEGIES:
        raise ValueError(f"Unknown transformation: {transformation}")

    template_path = PROMPTS_DIR / STRATEGIES[transformation]["template_file"]
    template = template_path.read_text()

    for key, value in kwargs.items():
        template = template.replace(f"<<{key.upper()}>>", str(value))
        
    if previous_error:
        template += f"\n\n## PREVIOUS ATTEMPT FAILED\n"
        template += f"Your last candidate failed Formal Equivalence (EQY) with the following error:\n"
        template += f"{previous_error}\n\n"
        if previous_candidate:
            template += f"Code that caused the error:\n"
            template += f"```systemverilog\n{previous_candidate}\n```\n\n"
        template += f"Please analyze this failure and generate a NEW candidate that fixes it.\n"

    return template
