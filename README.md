# ACC-Telemetries-in-Matlab-Simulink

MATLAB & Simulink toolkit for parsing, visualizing, replaying and live syncing (In upcoming versions) Assetto Corsa Competizione (ACC) telemetry data, featuring interactive 3D map plotting and vehicle kinematics analysis.

Versions:
Version	Folder	What it does
v2 (latest)	v2/	Replays a selected lap, draws the track map from the car's own telemetry (no external map file), and shows the car's rotation, tilt and other body motion in 3D.
v1	v1/	Early prototype. Plots graphs of the recorded telemetry data.

Start with v2 unless you want to see how the project began.

How it works:
Record: the Python script reads telemetry from ACC while you drive and saves it to a log file.
Analyse and replay: the MATLAB scripts load a log, plot the data, draw the track map and animate the car's body motion. A Simulink replay model can be generated from the same data.

Requirements:
- Assetto Corsa Competizione (must be running while recording).
- MATLAB with Simulink.
- Python 3.

See the README inside each version folder for exact steps.

Roadmap
- Live sync between ACC and Simulink.
- Support for more cars and tracks beyond the included test logs.

<img width="609" height="598" alt="Track Map" src="https://github.com/user-attachments/assets/52336020-35e6-4a95-bddd-9854efbde226" />

License

Released under the MIT License.
