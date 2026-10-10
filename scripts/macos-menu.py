import argparse
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("-p", default="Select")
parser.add_argument("-lines", default=None)
args = parser.parse_args()
choices = sys.stdin.read().splitlines()

# Pass values as arguments so prompts and entries cannot become AppleScript code.
script = """
on run argv
    try
        set promptText to item 1 of argv
        if (count argv) > 1 then
            set selection to choose from list (items 2 thru -1 of argv) with prompt promptText
            if selection is false then return ""
            return item 1 of selection
        else
            set answer to display dialog promptText default answer ""
            return text returned of answer
        end if
    on error number -128
        return ""
    end try
end run
"""
result = subprocess.run(
    ["/usr/bin/osascript", "-e", script, "--", args.p, *choices],
    text=True,
    capture_output=True,
)
if result.returncode:
    sys.stderr.write(result.stderr)
    sys.exit(result.returncode)
sys.stdout.write(result.stdout)
