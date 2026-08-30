import sys
import re
import json

def extract_ppa(sta_report_path, synth_log_path, output_json_path):
    # 1. Extract WNS and Power from STA Report
    wns = 0.0
    total_power = 0.0
    try:
        with open(sta_report_path, 'r') as f:
            sta_content = f.read()
            
            # Find WNS (slack)
            wns_match = re.search(r'slack \(.*?\)\s+([-\d\.]+)', sta_content)
            if wns_match:
                wns = float(wns_match.group(1))
            else:
                wns_match_alt = re.search(r'wns (max|min) ([-\d\.]+)', sta_content)
                if wns_match_alt:
                    wns = float(wns_match_alt.group(2))
                    
            # Find Power (Total Power from report_power)
            power_match = re.search(r'Total\s+[\d\.e+-]+\s+[\d\.e+-]+\s+[\d\.e+-]+\s+([\d\.e+-]+)\s+100\.0%', sta_content)
            if power_match:
                total_power = float(power_match.group(1))
    except Exception as e:
        print(f"Error reading STA report: {e}")

    # 2. Extract Area from Synthesis Log
    chip_area = 0.0
    try:
        with open(synth_log_path, 'r') as f:
            synth_content = f.read()
            # Find Chip area from stat command
            area_match = re.search(r'Chip area for module.*?:\s+([\d\.]+)', synth_content)
            if area_match:
                chip_area = float(area_match.group(1))
    except Exception as e:
        print(f"Error reading Synthesis log: {e}")

    # 3. Write PPA Scorecard
    ppa_data = {
        "wns_ns": wns,
        "area_um2": chip_area,
        "power_watts": total_power
    }
    
    with open(output_json_path, 'w') as f:
        json.dump(ppa_data, f, indent=4)
        
    print("\n--- PPA SCORECARD ---")
    print(f"  WNS (ns):     {wns}")
    print(f"  Area (um^2):  {chip_area}")
    print(f"  Power (W):    {total_power}")
    print("---------------------\n")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 extract_ppa.py <sta_report.rpt> <synth_log.log> <output.json>")
        sys.exit(1)
    extract_ppa(sys.argv[1], sys.argv[2], sys.argv[3])
