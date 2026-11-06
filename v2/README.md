# Version 2

Version 2 adds lap replay and body-motion visualisation on top of the telemetry plotting from v1.

What's new:

Lap replay: replays the lap you select.
Map from telemetry only: the track map is drawn purely from the car's recorded telemetry, with no external track map or outside help.
3D body animation: shows the car's rotation, tilt and other body motion as it moves around the track.
Sensible defaults: if you open acc_map_body.m directly, it uses the default Spa map and selects lap 7.

Folder contents:
- Matlab Files/acc_map_body.m	Main script. Draws the map and animates the car body for a chosen lap.
- Matlab Files/acc_viewer.m	Plots the recorded telemetry channels.
- Matlab Files/make_simulink_replay.m	Builds a Simulink model that replays the log.
- Python Script/ACC Telemetries Recorder.py	Records telemetry from ACC to a log file.
- Test Logs/Sample log: Spa, Ford Mustang GT3.

Requirements:
- Assetto Corsa Competizione
- MATLAB with Simulink (version: fill in the version you tested on)
- Python 3 (packages: fill in from your script's imports)

Quick start:
- Try it with the included log
- Clone or download the repository.
- Open MATLAB and set the current folder to v2/Matlab Files.
- Run acc_map_body. With no arguments it loads the default Spa log and plays lap 7.
- Record your own laps
- Start ACC and begin a session.
- Run Python Script/ACC Telemetries Recorder.py and drive some laps.
- Stop the script. The log file is saved to (fill in where it's saved).
- In MATLAB, run acc_map_body and point it at your new log and the lap number you want (fill in the exact call or prompt).

Notes:
- The default map and lap are only used when acc_map_body.m is run without a chosen log or lap.
- The sample log was recorded at Spa in the Ford Mustang GT3.
