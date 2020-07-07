r0 = [10 10];

%options = optimoptions('patternsearch', 'MeshTolerance', 0.5);
options = optimoptions('patternsearch', 'ConstraintTolerance', 1);
patternsearch(@parabola, r0, [], [], [], [], [], [], [], options)


function z = parabola(R)
    z = R(1)^2 + R(2)^2;
end