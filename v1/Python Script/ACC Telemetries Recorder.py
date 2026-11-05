import mmap
import struct
import time
import csv
import os
import re
import sys
import json
import datetime

ROTATE_MIN = 30
WHEELS = ["FL", "FR", "RL", "RR"]
 
 
def W(prefix):
    return [f"{prefix}_{w}" for w in WHEELS]
 

PHYS_FIELDS = [
    (4,   "f", ["gas"]),
    (8,   "f", ["brake"]),
    (12,  "f", ["fuel"]),
    (16,  "i", ["gear"]),
    (20,  "i", ["rpm"]),
    (24,  "f", ["steer"]),
    (28,  "f", ["speed_kmh"]),
    (32,  "f", ["vel_x", "vel_y", "vel_z"]),
    (44,  "f", ["g_lat", "g_vert", "g_long"]),   
    (56,  "f", W("wheel_slip")),
    (72,  "f", W("load")),                    
    (88,  "f", W("press")),                    
    (104, "f", W("wheel_omega")),
    (120, "f", W("tyre_wear")),
    (152, "f", W("tyreT_core")),
    (168, "f", W("camber_rad")),
    (184, "f", W("susp_travel")),               
    (204, "f", ["tc"]),
    (208, "f", ["heading", "pitch", "roll"]),
    (224, "f", [f"car_damage_{k}" for k in range(5)]),
    (244, "i", ["tyres_out"]),
    (252, "f", ["abs"]),
    (268, "f", ["rideheight_F", "rideheight_R"]),
    (276, "f", ["turbo_boost"]),
    (288, "f", ["air_temp", "road_temp"]),
    (296, "f", ["angvel_x", "angvel_y", "angvel_z"]),
    (348, "f", W("brake_temp")),
    (364, "f", ["clutch"]),
    (368, "f", W("tyreT_inner")),
    (384, "f", W("tyreT_mid")),
    (400, "f", W("tyreT_outer")),
    (564, "f", ["brake_bias"]),
    (568, "f", ["lvel_x", "lvel_y", "lvel_z"]),  
    (592, "f", W("mz")),
    (608, "f", W("fx")),
    (624, "f", W("fy")),
    (640, "f", W("slip_ratio")),
    (656, "f", W("slip_angle")),
    (672, "i", ["tc_active"]),
    (676, "i", ["abs_active"]),
    (696, "f", W("tyreT_surface")),
    (712, "f", ["water_temp"]),
    (716, "f", W("brake_press")),
    (740, "f", W("pad_life")),
    (756, "f", W("disc_life")),
]
 
GFX_FIELDS = [
    (132, "i", ["lap"]),           
    (136, "i", ["position"]),
    (140, "i", ["i_cur_ms"]),   
    (144, "i", ["i_last_ms"]),
    (148, "i", ["i_best_ms"]),
    (156, "f", ["dist_m"]),         
    (160, "i", ["in_pit"]),
    (164, "i", ["sector"]),
    (248, "f", ["norm_pos"]),  
]
GFX_EXTRA_MIN_SIZE = 1300    
GFX_EXTRA_COLS = ["car_x", "car_y", "car_z", "surface_grip",
                  "tc_setting", "engine_map", "abs_setting"]
 
 
def build_spec(fields):
    spec, cols = [], []
    for off, ch, names in fields:
        spec.append((off, struct.Struct("<" + ch * len(names))))
        cols += names
    return spec, cols
 
 
PSPEC, PCOLS = build_spec(PHYS_FIELDS)
GSPEC, GCOLS = build_spec(GFX_FIELDS)
COLS = ["t"] + PCOLS + GCOLS + GFX_EXTRA_COLS
I32 = struct.Struct("<i")
F32 = struct.Struct("<f")
 
 
def decode(buf, spec):
    out = []
    for off, st in spec:
        out.extend(st.unpack_from(buf, off))
    return out
 
 
def fmt(v):
    return v if isinstance(v, int) else f"{v:.6g}"
 
 
def wstr(buf, off, n):
    return buf[off:off + 2 * n].decode("utf-16-le", errors="ignore").split("\x00")[0]
 
 
def safe(s):
    return re.sub(r"[^A-Za-z0-9_-]+", "_", s).strip("_") or "unknown"
 
 
def open_map(tag, sizes):
    for s in sizes:
        try:
            return mmap.mmap(-1, s, tag, access=mmap.ACCESS_READ), s
        except (OSError, ValueError):
            continue
    return None, 0
 
 
def read_static(stat_map, size):
    if stat_map is None:
        return "unknown", "unknown"
    buf = stat_map[:size]
    return wstr(buf, 68, 33), wstr(buf, 134, 33) 
 
 
def new_file(car, track, hz):
    os.makedirs("logs", exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    base = f"logs/{safe(track)}_{safe(car)}_{stamp}"
    fh = open(base + ".csv", "w", newline="")
    w = csv.writer(fh)
    w.writerow(COLS)
    with open(base + ".json", "w") as jf:
        json.dump({"car": car, "track": track, "hz": hz,
                   "started": stamp, "columns": COLS}, jf, indent=2)
    print("Logging to", base + ".csv")
    return fh, w
 
 
def main():
    hz = float(sys.argv[1]) if len(sys.argv) > 1 else 50.0
    period = 1.0 / hz
 
    print("Waiting for ACC shared memory (start the game)...")
    while True:
        phys, psize = open_map("Local\\acpmf_physics", [1024, 800])
        gfx, gsize = open_map("Local\\acpmf_graphics", [2048, 1600, 1320, 400])
        stat, ssize = open_map("Local\\acpmf_static", [1024, 800, 400, 200])
        if phys is not None and gfx is not None:
            break
        time.sleep(2)
 
    car, track = read_static(stat, ssize)
    print(f"Connected. Car: {car} | Track: {track} | {hz:.0f} Hz")
    print("Logs only while live on track. Ctrl+C to stop.")
 
    fh, w = new_file(car, track, hz)
    t0 = file_t0 = time.perf_counter()
    next_t, last_pid, rows, last_lap = 0.0, -1, 0, -1
 
    try:
        while True:
            pbuf = phys[:psize]
            gbuf = gfx[:gsize]
            pid = I32.unpack_from(pbuf, 0)[0]
            status = I32.unpack_from(gbuf, 4)[0]
            now = time.perf_counter()
 
            if status == 2 and pid != last_pid and now >= next_t:
                last_pid = pid
                next_t = max(next_t + period, now - period)
 
                vals = decode(pbuf, PSPEC) + decode(gbuf, GSPEC)
 
                if gsize >= GFX_EXTRA_MIN_SIZE:
                    pid_car = I32.unpack_from(gbuf, 1216)[0]
                    pid_car = pid_car if 0 <= pid_car < 60 else 0
                    cx, cy, cz = struct.unpack_from("<3f", gbuf, 256 + 12 * pid_car)
                    vals += [cx, cy, cz,
                             F32.unpack_from(gbuf, 1240)[0],
                             I32.unpack_from(gbuf, 1268)[0],
                             I32.unpack_from(gbuf, 1276)[0],
                             I32.unpack_from(gbuf, 1280)[0]]
                else:
                    vals += [""] * len(GFX_EXTRA_COLS)
 
                w.writerow([f"{now - t0:.3f}"] + [fmt(v) if v != "" else "" for v in vals])
                rows += 1
 
                lap = vals[len(PCOLS)] 
                if lap != last_lap:
                    if last_lap != -1:
                        print(f"Lap {last_lap} completed | last lap {vals[len(PCOLS)+3]/1000:.3f} s")
                    last_lap = lap
 
                if rows % int(hz * 2) == 0:
                    fh.flush()
 
                if now - file_t0 > ROTATE_MIN * 60:
                    fh.close()
                    fh, w = new_file(car, track, hz)
                    file_t0 = now
 
            time.sleep(0.001)
    except KeyboardInterrupt:
        pass
    finally:
        fh.close()
        print(f"Stopped. {rows} samples written.")
 
 
if __name__ == "__main__":
    main()