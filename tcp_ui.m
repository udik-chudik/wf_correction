function myprogress3
    f = uifigure;
    d = uiprogressdlg(f,'Title','Approximating Pi',...
        'Message','1','Cancelable','on');

    % Approximate pi^2/8 as: 1 + 1/9 + 1/25 + 1/49 + ...
    pisqover8 = 1;
    denom = 3;
    valueofpi = sqrt(8 * pisqover8);
    steps = 20000;
    for step = 1:steps 
        % Check for Cancel button press
        if d.CancelRequested
            break
        end
        % Update progress, report current estimate
        d.Value = step/steps;
        d.Message = sprintf('%12.9f',valueofpi);

        % Calculate next estimate
        pisqover8 = pisqover8 + 1 / (denom * denom);
        denom = denom + 2;
        valueofpi = sqrt(8 * pisqover8);
    end

    % Close the dialog box
    close(d);
end