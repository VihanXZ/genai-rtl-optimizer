#!/usr/bin/env python3
"""extract_submodule.py — Extract a combinational always block into a standalone module.

Given a Verilog file, a module name, and the name of an always block (its label),
this script extracts the block and wraps it in a standalone, purely combinational
Verilog module with all referenced signals declared as ports.

This lets the LLM optimize ONLY the critical combinational logic,
and EQY can verify it in seconds (no sequential state to unroll).

Usage:
    python3 extract_submodule.py \\
        --input rtl/benchmark/aes_key_mem.v \\
        --module aes_key_mem \\
        --block round_key_gen \\
        --output rtl/testcases/aes_round_key_gen.sv
"""

import argparse
import re
import sys
from pathlib import Path


def extract_module_body(src: str, module_name: str) -> str:
    """Extract the text between module <name>(...); and endmodule."""
    # Match from module declaration to endmodule
    pattern = re.compile(
        rf"module\s+{re.escape(module_name)}\s*\(.*?\)\s*;(.*?)endmodule",
        re.DOTALL,
    )
    m = pattern.search(src)
    if not m:
        print(f"ERROR: Could not find module '{module_name}' in input file.", file=sys.stderr)
        sys.exit(1)
    return m.group(1)


def extract_always_block(body: str, block_label: str) -> str:
    """Extract a labeled always block (always @* begin: <label> ... end)."""
    # Find the always block with the given label
    pattern = re.compile(
        rf"(always\s+@\*?\s*\n?\s*begin\s*:\s*{re.escape(block_label)}\b.*?end\s*//\s*{re.escape(block_label)})",
        re.DOTALL,
    )
    m = pattern.search(body)
    if not m:
        # Try alternate pattern without end comment
        # Count begin/end nesting
        start_pattern = re.compile(
            rf"always\s+@\*?\s*\n?\s*begin\s*:\s*{re.escape(block_label)}\b",
        )
        sm = start_pattern.search(body)
        if not sm:
            print(f"ERROR: Could not find always block '{block_label}' in module body.", file=sys.stderr)
            sys.exit(1)

        # Manual begin/end counting from the match start
        pos = sm.start()
        depth = 0
        i = pos
        block_started = False
        while i < len(body):
            # Check for 'begin' keyword (whole word)
            if body[i:i+5] == 'begin' and (i == 0 or not body[i-1].isalnum()) and (i+5 >= len(body) or not body[i+5].isalnum()):
                depth += 1
                block_started = True
                i += 5
            elif body[i:i+3] == 'end' and (i+3 >= len(body) or not body[i+3].isalnum() or body[i+3:i+9] == 'module'):
                # Don't match 'endmodule', 'endcase', etc. as 'end'
                if i+3 < len(body) and body[i+3:i+7] in ('modu', 'case', 'func', 'task', 'gene'):
                    i += 3
                    continue
                depth -= 1
                if block_started and depth == 0:
                    # Find the end of this line
                    line_end = body.find('\n', i)
                    if line_end == -1:
                        line_end = len(body)
                    return body[pos:line_end].strip()
                i += 3
            else:
                i += 1

        print(f"ERROR: Could not find matching end for always block '{block_label}'.", file=sys.stderr)
        sys.exit(1)

    return m.group(1).strip()


def strip_comments(text: str) -> str:
    """Remove // line comments and /* block comments */ from Verilog source."""
    # Remove block comments
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    # Remove line comments
    text = re.sub(r"//.*", "", text)
    return text


def find_signals_in_block(block: str, body: str, block_label: str = "") -> dict:
    """Identify all signals referenced in the block and classify as input/output.

    Returns dict with:
      inputs:  signals that are READ but not WRITTEN in this block
      outputs: signals that are WRITTEN in this block
      locals:  signals declared locally (reg inside the block)
      params:  localparams referenced in this block
    """
    # Strip comments FIRST so English words don't pollute the identifier list
    clean_block = strip_comments(block)

    # Find local variable declarations inside the block (reg [...] name;)
    local_pattern = re.compile(r"reg\s+(?:\[.*?\]\s+)?(\w+(?:\s*,\s*\w+)*)\s*;")
    locals_set = set()
    for m in local_pattern.finditer(clean_block):
        for name in m.group(1).split(","):
            locals_set.add(name.strip())

    # Find all identifiers in the cleaned block
    ident_pattern = re.compile(r"\b([a-zA-Z_]\w*)\b")
    all_idents = set(ident_pattern.findall(clean_block))

    # Remove Verilog keywords and local vars
    keywords = {
        "always", "begin", "end", "if", "else", "case", "endcase", "default",
        "reg", "wire", "input", "output", "assign", "integer", "localparam",
        "parameter", "module", "endmodule", "posedge", "negedge", "or",
        "h0", "h1", "b0", "b1",  # hex/binary literal fragments
    }
    if block_label:
        keywords.add(block_label)
    all_idents -= keywords
    all_idents -= locals_set

    # Find assignments (LHS of = or <=)
    assign_pattern = re.compile(r"(\w+)\s*(?:\[.*?\])?\s*=\s*(?!=)")  # blocking assign
    written = set()
    for m in assign_pattern.finditer(clean_block):
        name = m.group(1)
        if name not in keywords and name not in locals_set:
            written.add(name)

    # Inputs = referenced but not written (and not local)
    read = all_idents - written

    # Also find the localparams/parameters in the full module body
    param_pattern = re.compile(r"localparam\s+(\w+)\s*=")
    params = set(param_pattern.findall(body))

    # Separate params from real signals — params referenced in the block go to params list
    read_params = (read | written) & params
    read -= params
    written -= params

    # Remove any remaining numeric-looking identifiers
    read = {s for s in read if not s[0].isdigit()}
    written = {s for s in written if not s[0].isdigit()}

    return {
        "inputs": sorted(read),
        "outputs": sorted(written),
        "locals": sorted(locals_set),
        "params": sorted(read_params),
    }


def find_signal_width(signal_name: str, body: str) -> str:
    """Find the bit-width declaration of a signal in the module body."""
    # Check for array-style declarations like key_mem [0 : 14]
    patterns = [
        rf"reg\s+(\[.*?\])\s+{re.escape(signal_name)}\b",
        rf"wire\s+(\[.*?\])\s+{re.escape(signal_name)}\b",
        rf"input\s+(?:wire\s+)?(\[.*?\])\s+{re.escape(signal_name)}\b",
        rf"output\s+(?:wire\s+)?(\[.*?\])\s+{re.escape(signal_name)}\b",
    ]
    for pat in patterns:
        m = re.search(pat, body)
        if m:
            return m.group(1) + " "
    
    # Check for 1-bit signals (no width specifier)
    patterns_1bit = [
        rf"reg\s+{re.escape(signal_name)}\s*;",
        rf"wire\s+{re.escape(signal_name)}\s*;",
        rf"input\s+(?:wire\s+)?{re.escape(signal_name)}\b",
        rf"output\s+(?:wire\s+)?{re.escape(signal_name)}\b",
    ]
    for pat in patterns_1bit:
        if re.search(pat, body):
            return ""
    
    return ""


def find_param_def(param_name: str, body: str) -> str:
    """Find a localparam definition line."""
    pattern = re.compile(rf"(localparam\s+{re.escape(param_name)}\s*=\s*[^;]+;)")
    m = pattern.search(body)
    if m:
        return m.group(1).strip()
    return f"localparam {param_name} = 0; // WARNING: could not find definition"


def build_submodule(
    submodule_name: str,
    block_text: str,
    signals: dict,
    body: str,
) -> str:
    """Build a standalone combinational Verilog module from the extracted block."""
    lines = []
    lines.append(f"// Auto-extracted combinational sub-module from always block")
    lines.append(f"// Optimize this module, then stitch it back with stitch_submodule.py")
    lines.append(f"")
    lines.append(f"`default_nettype none")
    lines.append(f"")

    # Port list
    ports = []
    for sig in signals["inputs"]:
        width = find_signal_width(sig, body)
        ports.append(f"    input  wire {width}{sig}")
    for sig in signals["outputs"]:
        width = find_signal_width(sig, body)
        ports.append(f"    output reg  {width}{sig}")

    lines.append(f"module {submodule_name}(")
    lines.append(",\n".join(ports))
    lines.append(f");")
    lines.append(f"")

    # Parameters
    for param in signals["params"]:
        lines.append(f"  {find_param_def(param, body)}")
    if signals["params"]:
        lines.append(f"")

    # The always block itself
    lines.append(f"  {block_text}")
    lines.append(f"")
    lines.append(f"endmodule // {submodule_name}")
    lines.append(f"")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Extract a combinational always block into a standalone module.")
    parser.add_argument("--input", required=True, help="Input Verilog file")
    parser.add_argument("--module", required=True, help="Source module name")
    parser.add_argument("--block", required=True, help="Label of the always block to extract")
    parser.add_argument("--output", required=True, help="Output file for the extracted sub-module")
    parser.add_argument("--name", default=None, help="Name for the extracted module (default: <module>_<block>)")
    args = parser.parse_args()

    src = Path(args.input).read_text()
    body = extract_module_body(src, args.module)
    block_text = extract_always_block(body, args.block)
    signals = find_signals_in_block(block_text, body + "\n" + src, block_label=args.block)

    submodule_name = args.name or f"{args.module}_{args.block}"

    print(f"  Block:   {args.block}")
    print(f"  Inputs:  {signals['inputs']}")
    print(f"  Outputs: {signals['outputs']}")
    print(f"  Locals:  {signals['locals']}")
    print(f"  Params:  {signals['params']}")

    result = build_submodule(submodule_name, block_text, signals, body + "\n" + src)
    Path(args.output).write_text(result)
    print(f"\n  ✅ Extracted to: {args.output}")


if __name__ == "__main__":
    main()
