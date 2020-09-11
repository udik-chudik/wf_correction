function [Z] = zern( m, n, Nx, Ny)
% In: angular frequency m and radial orders n for Zernice polynomial,
    % number points for grid Nx, Ny
% Out: Z = Zmn(x,y) -- Zernike polynomial. size(Z) = [Nx, Ny]
X = linspace(-1,1,Nx); % X-axis grid
Y = linspace(-1,1,Ny); % Y-axis grid
R = zeros(length(Y),length(X)); % Rmn
Z = zeros(length(Y),length(X)); % Zernike pol.

K = 0:(n-abs(m))/2; % max for sum (12)
for indy = 1:length(Y)
    U = (X.^2+Y(indy)^2<=1);  % cut unit circle
    [tt,r] = cart2pol(X, Y(indy).*ones(1,length(X))); % cart to polar SK
    % For (indy) row  calc Rmn
    for c = 1:length(K)
        k = K(c);
        R(indy, :) = R(indy, :) +... 
        (-1)^k * factorial(n-k).*r.^(n-2*k)./...
        (factorial(k)* factorial(0.5*(n+m) - k)*factorial(0.5*(n-m) - k) );  
    end
    % Calc Zern. pol. Rmn*cos(m*tt) or Rmn*sin(m*tt)
    if m >= 0
        Z(indy, :) = U.*R(indy, :) .* cos(m.*tt);
    else
        Z(indy, :) = U.*R(indy, :) .* sin(m.*tt);
    end 
end

end

