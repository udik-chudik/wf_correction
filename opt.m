% Example of simulated annealing algorithm
T_START = 10;
T_END = 0.00001;


S_START = 2.85;

T_current = T_START;
S_current = S_START;

N = 0;

while (T_current > T_END)
   
    N = N + 1;
    S_candidate = GenerateStateCandidate(S_current);
    dE = CalculateEnergy(S_candidate) - CalculateEnergy(S_current);
    if (dE <= 0)
        S_current = S_candidate;
    else
        if NeedMakeTransit(GetTransitionProbability(dE, T_current))
            S_current = S_candidate;
        end
    end
    T_current = DecreaseTemperature(T_START, N);
end

x = linspace(0, 3, 1000);
plot(x, CalculateEnergy(x));
hold on;
plot(S_START, CalculateEnergy(S_START), 'r*');
plot(S_current, CalculateEnergy(S_current), 'r*');
text(2, 16, "Initial position");
text(S_current, 4, "Finish position");

function [ a ] = NeedMakeTransit(probability )
    if(probability > 1 || probability < 0)
        error('Violation of argument constraint');
    end

    value = rand(1);

    if(value <= probability)
        a = 1;
    else
        a = 0; 
    end

end

function [state] = GenerateStateCandidate(state)
    state = rand(1)*5;
end

function [ PV ] = CalculateEnergy(x)
    PV = exp(x)+sin(50*x);
end

function [ T ] = DecreaseTemperature( initialTemperature, k)
T = initialTemperature * 0.1 / k; 
end

function [p] = GetTransitionProbability(dE, T)
    p = exp(-dE/T);
end