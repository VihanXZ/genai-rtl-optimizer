import sys
import json
import re
from datetime import datetime, timezone

def parse_timing_report(report_path):
    # Read the text report
    with open(report_path, 'r') as f:
        content = f.read()

    # Initialize our clean JSON structure
    data = {
        "$schema": "timing_report_v1",
        "module_name": "test_counter",
        "wns_ns": 0.0,
        "num_violations": 0,
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

    # Search the text for the "slack" value
    slack_match = re.search(r'([-\d\.]+)\s+slack\s+\((?:VIOLATED|MET|.*)\)', content)


    
    if slack_match:
        data["wns_ns"] = float(slack_match.group(1))

    # If the slack is negative, we have a timing violation
    if data["wns_ns"] < 0:
        data["num_violations"] = 1 

    return data

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python parser.py <input.rpt> <output.json>")
        sys.exit(1)

    input_rpt = sys.argv[1]
    output_json = sys.argv[2]

    parsed_data = parse_timing_report(input_rpt)
    
    with open(output_json, 'w') as f:
        json.dump(parsed_data, f, indent=2)
    
    print(f"✅ Successfully parsed report!")
    print(f"Worst Negative Slack (WNS): {parsed_data['wns_ns']} ns")
