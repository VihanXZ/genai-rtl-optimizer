import sys
import json
import re
from datetime import datetime, timezone

def parse_timing_report(report_path):
    with open(report_path, 'r') as f:
        content = f.read()

    # Initialize general schema
    data = {
        "$schema": "timing_report_v1",
        "module_name": "generic_module",  # Can be overridden by args if needed
        "wns_ns": 0.0,
        "num_violations": 0,
        "critical_paths": [],
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

    # 1. Extract WNS (usually at the very end of the file)
    wns_match = re.search(r'wns max\s+([-\d\.]+)', content)
    if wns_match:
        data['wns_ns'] = float(wns_match.group(1))

    # 2. Split the report into individual path blocks
    # "Startpoint:" marks the beginning of a specific timing trace
    path_blocks = content.split('Startpoint: ')[1:]
    
    for block in path_blocks:
        path_data = {
            "startpoint": "",
            "endpoint": "",
            "clock_domain": "",
            "slack_ns": 0.0,
            "stages": []
        }

        # Extract Metadata
        start_m = re.search(r'^(\S+)', block)
        end_m = re.search(r'Endpoint:\s*(\S+)', block)
        clk_m = re.search(r'Path Group:\s*(\S+)', block)
        slack_m = re.search(r'([-\d\.]+)\s+slack\s+\(VIOLATED\)', block)

        if start_m: path_data['startpoint'] = start_m.group(1)
        if end_m: path_data['endpoint'] = end_m.group(1)
        if clk_m: path_data['clock_domain'] = clk_m.group(1)
        if slack_m: 
            path_data['slack_ns'] = float(slack_m.group(1))
            data['num_violations'] += 1
        
        # 3. Extract the gate-level stages from the table
        # Matches OpenSTA lines like:  0.37   0.37 ^ uart_tx/_8478_/Q (sky130_fd_sc_hd__dfrtp_1)
        for line in block.split('\n'):
            # Group 1: delay_ns
            # Group 2: arrival_ns
            # Group 3: pin
            # Group 4: cell
            stage_m = re.search(r'^\s*([-\d\.]+)\s+([-\d\.]+)\s+[v\^]\s+(\S+)\s+\(([^)]+)\)', line)
            if stage_m:
                path_data['stages'].append({
                    "delay_ns": float(stage_m.group(1)),
                    "arrival_ns": float(stage_m.group(2)),
                    "pin": stage_m.group(3),
                    "cell": stage_m.group(4)
                })

        path_data['path_depth'] = len(path_data['stages'])
        data['critical_paths'].append(path_data)

    return data

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 parser.py input.rpt output.json")
        sys.exit(1)
    
    parsed = parse_timing_report(sys.argv[1])
    with open(sys.argv[2], 'w') as f:
        json.dump(parsed, f, indent=2)
    
    print(f"✅ Successfully parsed {len(parsed['critical_paths'])} critical paths!")
    print(f"Worst Negative Slack (WNS): {parsed['wns_ns']} ns")
