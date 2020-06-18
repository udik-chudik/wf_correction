% Import SDK:
add_heds_path;
% Detect SLMs and open a window on the selected SLM:
heds_init_slm;

% Open the SLM preview window (might have an impact on performance):
heds_utils_slm_preview_show;

clear process;

wfs_receiver(@process);



function [] = process(wf, PV)


    s = size(wf);

    for y = 1:s(1)
        for x = 1:s(2)
            if (isnan(wf(y,x)))
                wf(y,x) = 0;
            end
        end
    end

    %phaseData = construct_wf(heds_slm_width_px, heds_slm_height_px, wf, 956, 380, 19.6);
    persistent i;
    if isempty(i)
        i = 0;
    end
    
    persistent awf;
    if isempty(awf)
        awf = wf;
    else
        awf = awf + wf;
    end
    
    %if mod(i,25) == 0
    %    phaseData = construct_wf(heds_slm_width_px, heds_slm_height_px, awf/25, 952, 384, 20.5);
    %    heds_show_phasevalues(phaseData);
    %    awf = wf;
    %end
    %i = i + 1;
    %return;

    X = [945 955];
    Y = [380 390];
    R = [85 85];
    delta_xy = 1;
    delta_r = 2;
    probes = 30;
    persistent X_OFFSET;
    persistent Y_OFFSET;
    persistent R_ANGLE;
    persistent probe;
    persistent min_pv;
    persistent sum_pv;
    
    if isempty(R_ANGLE)
        R_ANGLE = R(1);
    end
    if isempty(X_OFFSET)
        X_OFFSET = X(1);
    end
    if isempty(Y_OFFSET)
        Y_OFFSET = Y(1);
    end
    if isempty(min_pv)
        disp(PV);
        min_pv = 10;
    end
    if isempty(sum_pv)
        sum_pv = 0;
    end
    if isempty(probe) || probe == 0
        
        if (X_OFFSET > X(2))
            X_OFFSET = X(1);
            Y_OFFSET = Y_OFFSET + delta_xy;
        end
        if (Y_OFFSET > Y(2))
            Y_OFFSET = Y(1);
            R_ANGLE = R_ANGLE + delta_r;
        end
        if (R_ANGLE > R(2))
            R_ANGLE = R(1);
            disp("DONE");
        end
        X_OFFSET = X_OFFSET + delta_xy;
        
        
        if (min_pv > sum_pv/probes) && (~isempty(probe))
            min_pv = sum_pv/probes;
            disp(X_OFFSET);
            disp(Y_OFFSET);
            disp(R_ANGLE);
            disp(min_pv);
        end
        % make some number of measurments
        probe = probes;
        %disp(sum_pv/probes);
        sum_pv = 0;
        phaseData = construct_wf(heds_slm_width_px, heds_slm_height_px, awf/probes, X_OFFSET, Y_OFFSET, R_ANGLE);
        heds_show_phasevalues(phaseData);
        awf = wf;
    end
    
    sum_pv = sum_pv + PV;
    
    
    
    
    
    %phaseData = construct_wf(heds_slm_width_px, heds_slm_height_px, wf, X_OFFSET, Y_OFFSET, R_ANGLE);
    %heds_show_phasevalues(phaseData);
    % Show the matrix of phase values on the SLM:
    
    probe = probe - 1;
end



% Please uncomment to close SDK at the end:
% heds_close_slm