Start = cputime;
m = 2; % m <= n
n = 2;

[X,Y,Z] = zern(m, n, 300, 500);

% tiledlayout(4,4) %for show Zernikes
% for i = 1:length(ZM)
%     nexttile 
%     imagesc(linspace(-1,1,Nx),linspace(-1,1,Ny),Z(:,:,i))
%     title('m = '+string(ZM(i))+',n = ' + string(ZN(i)))
% end


imagesc(Z);

% 
% 
% r = linspace(0,1,20);
% tt = linspace(0,2*pi,15);
% 
% k = 0:(n-m)/2;
% R = zeros( 1,length(r) );
% for i = 1:length(r)
%     R(i) = sum(  (-1).^k .* factorial(n-k) ./...
%     (factorial(k).* factorial(0.5*(n+m) - k) .*...
%                    factorial(0.5*(n-m) - k) ) .* r(i).^(n-2.*k) );
% end
% 
% Z = zeros(length(tt),length(r));
% X0 = zeros(length(tt),length(r));
% Y0 = zeros(length(tt),length(r));
% for i = 1 : length(tt)
%     Z(i,:) = R.*cos(tt(i)*m);
%     %Z(i,:) = r.* cos(tt(i));
%     X0(i,:) = r.*cos(tt(i));
%     Y0(i,:) = r.*sin(tt(i));
% end  
% figure()
% polarPcolor(r,radtodeg(tt),Z)
% 
% X = linspace(-1,1,8);
% Y = linspace(-1,1,8);
% Zxy =  zeros(length(Y),length(X));
% for indy = 1:(length(Y)-1)
%     for indx = 1:(length(X)-1)
%         U = ( X0>X(indx) )&( X0<=X(indx+1) )...
%             &( Y0>Y(indy) )&( Y0<=Y(indy+1) );
%         Zxy(indy,indx) = mean2(Z(U));
%     end
% end
%         
% figure()
% imagesc(X,Y,Zxy)

% 
% x = linspace(-1,1,20);
% y = linspace(-1,1,20);
% 
% l = n - 2*m;
% m = (n-abs(l))/2;
% q = 0.5*(abs(l)-1);
% if mod(n,2)==0
%     if l>0
%         q = abs(l)/2-1;
%     else
%         q = abs(l)/2;
%     end
% end
% p = 0;
% if l>0 
%     p=1;
% end
% 
% Z = zeros(length(y),length(x));
% 
% for ind = 1:length(y)
%     U = (x.^2+y(ind)^2<=1);
%     for i = 0:q
%         for j = 0:m
%             k0 = (-1)^(i+j);
%             for k = 0:(m-j)
%                 k1 = nchoosek(abs(l), (2*i+p));
%                 k2 = nchoosek(m-j, k);
%                 powx = 2*(i+l) + p;
%                 powy = n - 2*(i+j+k) - p;
%                 k3 = factorial(n-j) /...
%           (factorial(j)*factorial(m-j)*factorial(n-m-j) );
%                 Z(ind, :) = Z(ind,:) + k1*k2*k3*...
%                     (x.^powx)*(y(ind)^powy);
%             end
%         end
%     end
% end
% 
% imagesc(x,y,Z);
Elapsed = cputime - Start
