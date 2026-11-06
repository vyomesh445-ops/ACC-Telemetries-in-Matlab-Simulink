function acc_viewer
 
T = [];     
L = []; 
csvPath = '';
 
fig = uifigure('Name', 'ACC Telemetry Viewer', 'Position', [100 100 1100 650]);
main = uigridlayout(fig, [2 1]);
main.RowHeight = {40, '1x'};
 
bar = uigridlayout(main, [1 5]);
bar.ColumnWidth = {120, 180, '1x', 180, 120};
bar.Padding = [5 5 5 5];
uibutton(bar, 'Text', 'Load CSV', 'ButtonPushedFcn', @onLoad);
ddLap = uidropdown(bar, 'Items', {'(load a file)'}, 'ValueChangedFcn', @(~,~) refresh());
lbl = uilabel(bar, 'Text', 'No file loaded');
uibutton(bar, 'Text', 'Replay in Simulink', 'ButtonPushedFcn', @onSim);
btn3d = uibutton(bar, 'Text', '3D Replay', 'ButtonPushedFcn', @on3D);
 
tg = uitabgroup(main);
ax1 = makeAxes('Speed');
ax2 = makeAxes('Pedals');
ax3 = makeAxes('g-g diagram');
ax4 = makeAxes('Suspension');
ax5 = makeAxes('Steering vs lat g');
 
function ax = makeAxes(titleText)
    tab = uitab(tg, 'Title', titleText);
    gl = uigridlayout(tab, [1 1]);
    ax = uiaxes(gl);
end

    function onLoad(~, ~)
        [f, p] = uigetfile('*.csv', 'Select an ACC log');
        if isequal(f, 0), return; end
        csvPath = fullfile(p, f);
        T = readtable(fullfile(p, f));
 
        items = {}; data = [];
        for k = unique(T.lap)'
            idx = T.lap == k & T.speed_kmh > 5;
            if nnz(idx) > 200                  
                items{end+1} = sprintf('Lap %d (%.1f s)', k, max(T.i_cur_ms(idx))/1000);
                data(end+1) = k;                  
            end
        end
        if isempty(items)
            uialert(fig, 'No complete laps found in this file.', 'Nothing to show');
            return
        end
        ddLap.Items = items;
        ddLap.ItemsData = data;
        ddLap.Value = data(1);
        lbl.Text = f;
        refresh();
    end
 
    function refresh()
        if isempty(T), return; end
        L = T(T.lap == ddLap.Value & T.speed_kmh > 5, :);
        L = L(abs(L.g_lat) < 6 & abs(L.g_long) < 6, :);
        x = L.norm_pos;
 
        plot(ax1, x, L.speed_kmh, 'LineWidth', 1.2);
        title(ax1, 'Speed around the lap'); xlabel(ax1, 'Track position (0-1)');
        ylabel(ax1, 'km/h'); grid(ax1, 'on');
 
        plot(ax2, x, L.gas, x, L.brake, 'LineWidth', 1.2);
        title(ax2, 'Throttle and brake'); xlabel(ax2, 'Track position (0-1)');
        ylabel(ax2, '0 - 1'); legend(ax2, 'Throttle', 'Brake'); grid(ax2, 'on');
 
        scatter(ax3, L.g_lat, L.g_long, 6, L.speed_kmh, 'filled');
        title(ax3, 'g-g diagram (colour = speed)'); xlabel(ax3, 'Lateral g');
        ylabel(ax3, 'Longitudinal g'); axis(ax3, 'equal'); grid(ax3, 'on');
        colorbar(ax3);
 
        if all(ismember({'susp_travel_FL','susp_travel_FR','susp_travel_RL','susp_travel_RR'}, ...
                T.Properties.VariableNames))
            plot(ax4, x, 1000*[L.susp_travel_FL L.susp_travel_FR L.susp_travel_RL L.susp_travel_RR]);
            title(ax4, 'Suspension travel'); xlabel(ax4, 'Track position (0-1)');
            ylabel(ax4, 'mm'); legend(ax4, 'FL', 'FR', 'RL', 'RR'); grid(ax4, 'on');
        end
 
        scatter(ax5, L.g_lat, L.steer, 6, x, 'filled');
        title(ax5, 'Steering vs lateral g (colour = track position)');
        xlabel(ax5, 'Lateral g'); ylabel(ax5, 'Steering'); grid(ax5, 'on');
    end
 
    function onSim(~, ~)
        if isempty(L)
            uialert(fig, 'Load a CSV and pick a lap first.', 'No lap selected');
            return
        end
        t = L.t - L.t(1);
        [t, ia] = unique(t);                      
        mk = @(v) timeseries(v(ia), t);
 
        assignin('base', 'ts_speed',   mk(L.speed_kmh));
        assignin('base', 'ts_gas',     mk(L.gas));
        assignin('base', 'ts_brake',   mk(L.brake));
        assignin('base', 'ts_steer',   mk(L.steer));
        assignin('base', 'ts_g_lat',   mk(L.g_lat));
        assignin('base', 'ts_g_long',  mk(L.g_long));
        assignin('base', 'ts_susp_FL', mk(L.susp_travel_FL));
        assignin('base', 'ts_susp_FR', mk(L.susp_travel_FR));
        assignin('base', 'ts_susp_RL', mk(L.susp_travel_RL));
        assignin('base', 'ts_susp_RR', mk(L.susp_travel_RR));
 
        make_simulink_replay(t(end));
    end

    function on3D(~, ~)
        if isempty(T) || isempty(csvPath)
            uialert(fig, 'Load a CSV and pick a lap first.', 'No lap selected');
            return
        end
        btn3d.Enable = 'off';
        btn3d.Text = 'Playing...';
        drawnow;
        try
            acc_map_body(csvPath, ddLap.Value);
        catch err
            uialert(fig, err.message, '3D replay failed');
        end
        if isvalid(fig)
            btn3d.Enable = 'on';
            btn3d.Text = '3D Replay';
        end
    end
end