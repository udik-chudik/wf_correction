r0 = [10 10];
gs = GlobalSearch;
opts = optimoptions(@fmincon,'Algorithm','sqp');
problem = createOptimProblem('fmincon', 'x0', r0, 'objective', @parabola,'lb',[1,1],'ub',[3,3],'options',opts);

x = run(gs,problem);


function z = parabola(R)
    z = R(1)^2 + R(2)^2;
end