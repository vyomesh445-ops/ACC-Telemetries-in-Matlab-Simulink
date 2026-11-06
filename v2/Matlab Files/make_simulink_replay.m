function make_simulink_replay(stopTime)

model = 'acc_replay';
if bdIsLoaded(model), close_system(model, 0); end
new_system(model);
open_system(model);

src = {'speed','gas','brake','steer','g_lat','g_long', ...
    'susp_FL','susp_FR','susp_RL','susp_RR'};
for i = 1:numel(src)
    y = 30 + 50*(i-1);
    add_block('simulink/Sources/From Workspace', [model '/' src{i}], ...
        'VariableName', ['ts_' src{i}], ...
        'Position', [30 y 130 y+30]);
end

scopes = { ...
    'Speed_kmh',      {'speed'}; ...
    'Pedals',         {'gas','brake'}; ...
    'G_forces',       {'g_lat','g_long'}; ...
    'Steering',       {'steer'}; ...
    'Suspension_m',   {'susp_FL','susp_FR','susp_RL','susp_RR'} };

for i = 1:size(scopes, 1)
    name = scopes{i,1};
    sigs = scopes{i,2};
    y = 30 + 150*(i-1);
    add_block('simulink/Sinks/Scope', [model '/' name], ...
        'NumInputPorts', num2str(numel(sigs)), ...
        'Position', [450 y 500 y+40+20*numel(sigs)]);
    for j = 1:numel(sigs)
        add_line(model, [sigs{j} '/1'], [name '/' num2str(j)], 'autorouting', 'on');
    end
end

add_block('simulink/Continuous/Derivative', [model '/d_FL'], ...
    'Position', [250 330 290 360]);
add_block('simulink/Sinks/Scope', [model '/Damper_velocity_FL'], ...
    'Position', [450 800 500 840]);
add_block('simulink/Continuous/Transfer Fcn', [model '/LPF_FL'], ...
    'Numerator', '1', 'Denominator', '[0.01 1]', ...
    'Position', [160 330 220 360]);
add_line(model, 'susp_FL/1', 'LPF_FL/1', 'autorouting', 'on');
add_line(model, 'LPF_FL/1', 'd_FL/1', 'autorouting', 'on');
add_line(model, 'd_FL/1', 'Damper_velocity_FL/1', 'autorouting', 'on');

set_param(model, 'StopTime', num2str(stopTime), 'MaxStep', '0.02');
open_system([model '/Speed_kmh']);
open_system([model '/Pedals']);
open_system([model '/Suspension_m']);
open_system([model '/Damper_velocity_FL']);
sim(model);
end