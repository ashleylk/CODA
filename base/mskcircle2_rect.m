function msk=mskcircle2_rect(sz,da)
% generate the circle mask based on size of input matrix
% sz : matrix size 
% da : diameter of circle;
if nargin==1;
    da=min(sz);
end
msk=zeros(sz);
m = sz;
cent = (m+1)/2;

x = 1:m(2) ;
y = 1:m(1) ;
[gx,gy]=meshgrid(x,y);
gx=gx-cent(2);
gy=gy-cent(1);

% calculate distance;
D=sqrt(gx.^2 + gy.^2);
rr=(da-1)/2;
ind= D <= rr;
msk(ind)=1;


end