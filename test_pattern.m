% Import SDK:
add_heds_path;

% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):



global cx;
global cy;
global gain;
global siz;
global phase_data;

phaseModulation = 800*pi;
data_width = heds_slm_width_px;
data_height = heds_slm_height_px;

phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end

cx = 901; % увеличение - влево
cy = 440; % уменьшение - вверх
gain = 2*pi/20;
siz = 400;

global frame_count;
frame_count = 0;

global errors;
errors = [];

%{
fig = uifigure('Position',[100 100 600 275]);
sldx = uislider(fig,...
    'Position',[100 75 200 3],...
    'ValueChangedFcn',@(sld,event) sliderX(sld,cx));
sldx.Limits = [700 1100];
sldx.Value = cx;


sldy = uislider(fig,...
    'Position',[100 125 200 3],...
    'ValueChangedFcn',@(sld,event) sliderY(sld,cy));
sldy.Limits = [200 600];
sldy.Value = cy;

sldg = uislider(fig,...
    'Position',[100 175 200 3],...
    'ValueChangedFcn',@(sld,event) sliderGain(sld,cy));
sldg.Limits = [-10 10];
sldg.Value = gain;

slds = uislider(fig,...
    'Position',[100 225 200 3],...
    'ValueChangedFcn',@(sld,event) sliderSiz(sld,cy));
slds.Limits = [10 500];
slds.Value = siz;


%image1.ImageSource = a;
%}
assemblyWF();
wfs_receiver(@process);

function [] = process(wf, PV)

global errors;

errors = [errors PV];

global frame_count;
frame_count = frame_count + 1;
% обрабатываем каждый 2й фрейм
if (~(mod(frame_count, 2) == 0))
    return;
end


s = size(wf);

    for y = 1:s(1)
        for x = 1:s(2)
            if (isnan(wf(y,x)))
                wf(y,x) = 0;
            end
        end
    end
% crop image - выделим только апертуру пучка. ВАЖНО: это работает только
% для текущей конфигурации установки
wf = wf(10:31, 5:26);
img = imresize(wf, 21);
img = rot90(img);

assembly_correction(img);
disp(max(max(wf)) - min(min(wf)));

%set(image1, 'ImageSource', a);
end





function arr = plotArray(phase_data, array_to_plot, cx, cy)
    s = size(array_to_plot);
    sX = cy - round(s(1)/2);
    sY = cx - round(s(2)/2);
    arr = phase_data;
    arr(sX+1:sX+s(1),sY+1:sY+s(2)) = arr(sX+1:sX+s(1),sY+1:sY+s(2)) + array_to_plot;
    
end

function [] = assembly_correction(corrected)
% heds_utils_slm_preview_show;
global cx;
global cy;
global gain;
global phase_data;

phase_data = plotArray(phase_data, -corrected*gain, cx, cy);

% Show the matrix of phase values on the SLM:
heds_show_phasevalues(phase_data);
end

function [] = assemblyWF()
% heds_utils_slm_preview_show;
cx = 900;
cy = 440;
global siz;
global phase_data;
%{
phaseModulation = 800*pi;
data_width = heds_slm_width_px;
data_height = heds_slm_height_px;

phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end
%}
sphere = zeros(siz,siz);

for y = 1:siz
    for x = 1:siz
        sphere(y, x) = (((x-siz/2)^2 + (y-siz/2)^2)^(1/2))*pi/(sqrt((siz/2)^2 + (siz/2)^2));
    end
end

phase_data = plotArray(phase_data, -sphere*10, cx, cy);

% Show the matrix of phase values on the SLM:
heds_show_phasevalues(phase_data);
end
%{
function sliderX(sld, value)
global cx;
cx = round(sld.Value);
assemblyWF();
end

function sliderY(sld, value)
global cy;
cy = round(sld.Value);
assemblyWF();
end

function sliderGain(sld, value)
global gain;
gain = round(sld.Value);
assemblyWF();
end

function sliderSiz(sld, value)
global siz;
siz = round(sld.Value);
assemblyWF();
end
%}
