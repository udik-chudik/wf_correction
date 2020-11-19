% Import SDK:
add_heds_path;
% Detect SLMs and open a window on the selected SLM:
heds_init_slm;
% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;
% Open the SLM preview window (might have an impact on performance):

data_width = heds_slm_width_px;
data_height = heds_slm_height_px;

phaseModulation = 957*pi;

phase_data = zeros(data_height,data_width);
for y = 1:data_height
    for x = 1:data_width
        phase_data(y, x) = phaseModulation*x/data_width;
    end
end

% Show the matrix of phase values on the SLM
heds_show_phasevalues(single(phase_data));