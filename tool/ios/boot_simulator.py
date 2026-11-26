"""Boot a named device on the pinned iOS simulator runtime."""
import json
import os
import subprocess
import sys


def simctl(*args):
    return subprocess.check_output(["xcrun", "simctl", *args], text=True)


model = sys.argv[1]
devices = json.loads(simctl("list", "devices", "available", "-j"))["devices"]
runtime = "com.apple.CoreSimulator.SimRuntime.iOS-26-5"
device = next((item for item in devices.get(runtime, []) if item["name"] == model), None)
if not device:
    print(f"::error::Simulator {model} on {runtime} is unavailable.")
    print(simctl("list", "devices", "available"))
    sys.exit(1)
udid = device["udid"]
if device["state"] != "Booted":
    simctl("boot", udid)
simctl("bootstatus", udid, "-b")
simctl("ui", udid, "appearance", "light")
simctl("status_bar", udid, "override", "--time", "9:41", "--dataNetwork", "wifi",
       "--wifiMode", "active", "--wifiBars", "3", "--cellularMode", "active",
       "--cellularBars", "4", "--batteryState", "unplugged", "--batteryLevel", "100")
with open(os.environ["GITHUB_ENV"], "a") as output:
    output.write(f"SIMULATOR_UDID={udid}\n")
print(f"Booted {model} on {runtime}.")
