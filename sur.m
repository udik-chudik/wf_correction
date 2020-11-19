N_ACT = 4;

[X,Y] = ndgrid(1:N_ACT,1:N_ACT);
V = zeros(N_ACT, N_ACT);

Vreal = X.^2 + Y.^2;

for i=1:N_ACT
    for j=1:N_ACT
        V(j,i) = rand();
    end
end



F = griddedInterpolant(X,Y,V,'spline');
[Xq,Yq] = ndgrid(1:0.05:4,1:0.05:4);
Vq = F(Xq,Yq);
mesh(Xq,Yq,Vq);


