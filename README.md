# ACC-Telemetries-in-Matlab-Simulink

MATLAB & Simulink toolkit for parsing, visualizing, replaying and live syncing Assetto Corsa Competizione (ACC) telemetry data, featuring interactive 3D map plotting and vehicle kinematics analysis.

<!-- TODO: add a screenshot or GIF of the track map + 3D car body animation here -->
Versions
Version	Folder	What it does
v2 (latest)	v2/	Replays a selected lap, draws the track map from the car's own telemetry (no external map file), and shows the car's rotation, tilt and other body motion in 3D.
v1	v1/	Early prototype. Plots graphs of the recorded telemetry data.

Start with v2 unless you want to see how the project began.

Repository layout
ACC-Telemetries-in-Matlab-Simulink/
├── v1/
│   ├── Matlab Files/      acc_viewer.m, make_simulink_replay.m
│   ├── Python Script/     ACC Telemetries Recorder.py
│   └── Test Logs/         sample telemetry logs
├── v2/
│   ├── Matlab Files/      acc_map_body.m, acc_viewer.m, make_simulink_replay.m
│   ├── Python Script/     ACC Telemetries Recorder.py
│   └── Test Logs/         sample telemetry logs
├── LICENSE
└── README.md
How it works
Record: the Python script reads telemetry from ACC while you drive and saves it to a log file.
Analyse and replay: the MATLAB scripts load a log, plot the data, draw the track map and animate the car's body motion. A Simulink replay model can be generated from the same data.
Requirements
Assetto Corsa Competizione (must be running while recording)
MATLAB (version: to be filled in) with Simulink
Python 3 (version and packages: to be filled in)

See the README inside each version folder for exact steps.

Roadmap
 Live sync between ACC and Simulink
 Support for more cars and tracks beyond the included test logs

(Edit this list to match what you actually plan to build.)

License

Released under the MIT License.
