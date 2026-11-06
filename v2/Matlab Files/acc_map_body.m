function acc_map_body(csvFile, lap, varargin)
projectDir = 'D:\Projects\ACC Telemetries MATLAB-SIMULINK';
cfg.csv        = fullfile(projectDir, 'logs', 'Spa_ford_mustang_gt3_20261022_113742.csv');
cfg.lap        = 7;
cfg.stl        = fullfile(projectDir, 'Cuboid.STL');
cfg.exaggerate = 1;
cfg.speed      = 1;
cfg.video      = '';
cfg.pitchSign  = 1;
cfg.rollSign   = 1;

if nargin < 1, csvFile = cfg.csv; end
if nargin < 2, lap = cfg.lap; end

p = inputParser;
addParameter(p, 'Stl', cfg.stl);
addParameter(p, 'Exaggerate', cfg.exaggerate);
addParameter(p, 'Speed', cfg.speed);
addParameter(p, 'Video', cfg.video);
addParameter(p, 'PitchSign', cfg.pitchSign);
addParameter(p, 'RollSign', cfg.rollSign);
parse(p, varargin{:});
o = p.Results;

if ~isfile(csvFile), error('CSV not found:\n%s', csvFile); end
if ~isempty(o.Stl) && ~isfile(o.Stl), error('STL not found:\n%s', o.Stl); end

T = readtable(csvFile);
vn = T.Properties.VariableNames;
need = {'t','lap','norm_pos','speed_kmh','heading','pitch','roll','vel_x','vel_z'};
miss = need(~ismember(need, vn));
if ~isempty(miss)
    error('Missing columns: %s. Record with acc_logger_full.py.', strjoin(miss, ', '));
end

L = T(T.lap == lap & T.speed_kmh > 5, :);
if height(L) < 100, error('Lap %d has too few samples.', lap); end

w = [0; find(diff(L.norm_pos) < -0.5); height(L)];
[~, kk] = max(diff(w));
L = L(w(kk)+1 : w(kk+1), :);
t = L.t - L.t(1);

hasC = ismember('car_x', vn) && ismember('car_z', vn) && isnumeric(L.car_x) && ...
       all(isfinite(L.car_x)) && (max(L.car_x) - min(L.car_x)) > 50;
if hasC
    px = -L.car_x;  py = L.car_z;
    fprintf('Map source: logged car coordinates (corrected)\n');
else
    px = cumtrapz(t, L.vel_x);  py = cumtrapz(t, L.vel_z);
    fprintf('Map source: dead reckoning from velocity (coordinates not usable)\n');
end

pathDir = unwrap(atan2(gradient(py), gradient(px)));
fast = L.speed_kmh > 60;
bestR = -inf;
for s = [1 -1]
    z = mean(exp(1i * (pathDir(fast) - s * L.heading(fast))));
    if abs(z) > bestR, bestR = abs(z); sgn = s; off = angle(z); end
end
yaw   = sgn * L.heading + off;
pitch = o.PitchSign * movmean(L.pitch, 5);
roll  = o.RollSign  * movmean(L.roll, 5);

[V, F] = bodyMesh(o.Stl);

fig = figure('Name', 'ACC map + body', 'Position', [80 80 1300 650]);
tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
fig.ToolBar = 'none'; fig.MenuBar = 'none';
ax1.Toolbar.Visible = 'off';

ax1 = nexttile(tl);
scatter(ax1, px, py, 6, L.speed_kmh, 'filled');
axis(ax1, 'equal'); grid(ax1, 'on'); colorbar(ax1);
xlabel(ax1, 'x (m)'); ylabel(ax1, 'z (m)');
title(ax1, 'Track map from telemetry (colour = speed, km/h)');
hold(ax1, 'on');
arrowLen = 0.04 * max(max(px) - min(px), max(py) - min(py));
mk = plot(ax1, px(1), py(1), 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'w');
ar = quiver(ax1, px(1), py(1), arrowLen*cos(yaw(1)), arrowLen*sin(yaw(1)), 0, ...
            'r', 'LineWidth', 2, 'MaxHeadSize', 2);

ax2 = nexttile(tl);
hold(ax2, 'on'); axis(ax2, 'equal'); grid(ax2, 'on');
xlim(ax2, [-4 4]); ylim(ax2, [-4 4]); zlim(ax2, [-2.5 2.5]);
view(ax2, 35, 22);
xlabel(ax2, 'x (map)'); ylabel(ax2, 'z (map)'); zlabel(ax2, 'up');
patch(ax2, 'Vertices', [-4 -4 -1.2; 4 -4 -1.2; 4 4 -1.2; -4 4 -1.2], 'Faces', [1 2 3 4], ...
      'FaceColor', [0.85 0.85 0.85], 'FaceAlpha', 0.6);

hg = hgtransform('Parent', ax2);
patch('Parent', hg, 'Vertices', V, 'Faces', F, 'FaceColor', [0.2 0.5 0.9], 'EdgeColor', 'k');

noseY = max(V(:,2));
line('Parent', hg, 'XData', [0 0], 'YData', [noseY noseY + 1.2], 'ZData', [0 0], ...
     'Color', 'r', 'LineWidth', 3);
ttl = title(ax2, '');

Rz = @(a) [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];
Rx = @(a) [1 0 0; 0 cos(a) -sin(a); 0 sin(a) cos(a)];
Ry = @(a) [cos(a) 0 sin(a); 0 1 0; -sin(a) 0 cos(a)];

if ~isempty(o.Video)
    vw = VideoWriter(o.Video, 'MPEG-4'); vw.FrameRate = 30; open(vw);
    for tn = 0 : o.Speed/30 : t(end)
        draw(find(t >= tn, 1));
        drawnow;
        writeVideo(vw, getframe(fig));
    end
    close(vw);
    fprintf('Saved %s\n', o.Video);
else
    tic;
    while isvalid(fig)
        tn = toc * o.Speed;
        if tn > t(end), break; end
        draw(find(t >= tn, 1));
        drawnow limitrate;
    end
end

    function draw(k)
        R = Rz(yaw(k) - pi/2) * Rx(o.Exaggerate * pitch(k)) * Ry(o.Exaggerate * roll(k));
        hg.Matrix = [R zeros(3,1); 0 0 0 1];
        mk.XData = px(k);  mk.YData = py(k);
        ar.XData = px(k);  ar.YData = py(k);
        ar.UData = arrowLen * cos(yaw(k));
        ar.VData = arrowLen * sin(yaw(k));
        bearing = mod(90 - rad2deg(yaw(k)), 360);
        ttl.String = sprintf('t = %.1f s | %.0f km/h | bearing %.0f° | pitch %.1f° | roll %.1f°  (tilt shown x%g)', ...
            t(k), L.speed_kmh(k), bearing, ...
            rad2deg(pitch(k)), rad2deg(roll(k)), o.Exaggerate);
    end
end

function [V, F] = bodyMesh(stl)
if isempty(stl)
    d = [1.9 4.6 1.2] / 2;
    V = [-1 -1 -1; 1 -1 -1; 1 1 -1; -1 1 -1; -1 -1 1; 1 -1 1; 1 1 1; -1 1 1] .* d;
    F = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
else
    TR = stlread(stl);
    V = double(TR.Points);
    F = TR.ConnectivityList;

    V = V - mean(V, 1);

    if max(max(V) - min(V)) > 50
        V = V / 1000;
    end

    span = max(V) - min(V);
    [~, lengthDim] = max(span);
    [~, heightDim] = min(span);
    widthDim  = setdiff(1:3, [lengthDim, heightDim]);

    V = V(:, [widthDim, lengthDim, heightDim]);

    currentLength = max(V(:,2)) - min(V(:,2));
    if currentLength > 0
        V = V * (4.6 / currentLength);
    end
end
end