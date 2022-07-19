function [out,outid]=gcnt(im,mx,sz,th,rsq)
%cntrd:  calculates the centroid of bright spots to sub-pixel accuracy.
%  Inspired by Grier & Crocker's feature for IDL, but greatly simplified and optimized
%  for matlab
% INPUTS:
% im: image to process, particle should be bright spots on dark background with little noise
%     ofen an bandpass filtered brightfield image or a nice fluorescent image
%
% mx: locations of local maxima to pixel-level accuracy from pkfnd.m
%
% sz: diamter of the window over which to average to calculate the centroid.  
%     should be big enough
%     to capture the whole particle but not so big that it captures others.  
%     if initial guess of center (from pkfnd) is far from the centroid, the
%     window will need to be larger than the particle size.  RECCOMMENDED
%     size is the long lengthscale used in bpass plus 2.
% 
% 
%
%OUTPUT:  a N x 3 array containing, x, y and brightness for each feature
%           out(:,1) is the x-coordinates
%           out(:,2) is the y-coordinates
%           out(:,3) is the Peak intensity
%           out(:,4) is the intensity radius
% update (12/16/2010) : eliminate the complex output...

if nargin<4; 
    th=0;
    rsq=0;
elseif nargin <5;
    rsq=0;
end
    
[nr,nc]=size(im);
%remove all potential locations within distance sz from edges of image
if 1 % remove edge object
    ind=find(mx(:,2) > 1.5*sz/2 & mx(:,2) < nr-1.5*sz/2);
    mx=mx(ind,:);
    ind=find(mx(:,1) > 1.5*sz/2 & mx(:,1) < nc-1.5*sz/2);
    mx=mx(ind,:);
end
[nmx,crap] = size(mx); %nmx is number of particles


%inside of the window, assign an x and y coordinate for each pixel

dimm=sz;
x1=zeros(dimm,dimm);
for i=1:dimm
    x1(i,:)=1:dimm;
end
x1=x1-(dimm+1)/2;
y1=x1';
kk=(dimm-1)/2;
pts=[];
%%%%%%%%  generate the diamend mask matrix ( only valid below sz<=5 )
% msk=mskdiamond(sz);
% msk=mskcircle(sz);
msk=ones(sz);
%%%%%%%%

%msk=ones(dimm,dimm);
%msk(1,1)=0;msk(dimm,1)=0; msk(dimm,dimm)=0; msk(1,dimm)=0;
 AAt=[x1(:).^2+y1(:).^2,x1(:),y1(:),ones(size(x1(:)))];
%loop through all of the candidate positions
for i=1 :nmx
    
    %create a small working array around each candidate location, and apply the window function
    tmp = msk.*im((mx(i,2)-kk:mx(i,2)+kk),(mx(i,1)-kk:mx(i,1)+kk)) ;% intensity    
    tmp=tmp - th;    
    tmp=max(tmp,1);
%     AA=AAt;
%     intensity=[];
%     xx=[];x0=[];inthat=[];
    eint=0;rint=0;rsquare=0;
    
    intensity=tmp(:);   
    cci=intensity>1;
    intensity=log(intensity(cci));
    AA=AAt(cci,:);
%     for ii =1 : dimm*dimm  
%             
%         if tmp(ii)== 1
%         %   tmp(ii)= tmp(ii)+1;
%         else
%        AA=[AA; [x1(ii)^2+y1(ii)^2 ,x1(ii), y1(ii) , 1]];
%        intensity=[intensity;log(tmp(ii))] ;
%        
%       %xx=[xx; [x1(ii),y1(ii),tmp(ii)]];
%       %AA([1 5 21 25],:)=[];
%       %intensity(1 5 21 25)=[];
%         end
%     end
        
    AT=AA' ;
    maa=AT*AA ;
    bb=AT*intensity ;
    c=maa\bb  ;
    inthat=AA*inv(maa)*AT*intensity ;% estimated y value from regression model
    mint=mean(intensity);
    eint=sum((inthat-mint).^2);
    rint=sum((intensity-mint).^2);
    rsquare=eint/rint;
    % use the rsquare to filter bad beads
    if rsquare >rsq  && isreal(c)== 1 && isreal(rsquare)==1 && c(1)<0
    % c(1) (-1/sigma^2)
        xavg=-c(2)/c(1)/2 ;
        yavg=-c(3)/c(1)/2 ;
        peak=exp(c(4)-(xavg^2+yavg^2)*c(1));
        % the initial guess for optimiation
        %x0(4)=(-1/c(1))
        x0(4)=sqrt((-1/c(1))/2);  % chage to fit the standard deviation for gaussian fucntion
        x0(2)=xavg;
        x0(3)=yavg;
        x0(1)=peak;
    %x0=x0' 
    %x0=ones(4,1);      
        %global p1 d1
        %simplex method :: amoeba,
        %steepest cresent method :: mincg.
        
        %xa=mincg('f801','f801pd','ftau2cg',x0,5e-6);
      % [p,y]=amoeba(x0,'f801',1e-5); xa=p(1,:);  
            xa=x0;
        
    % call out the function to optimized the solution start from the at
    % least estimator.
    % 
    
    %concatenate it up
        pts=[pts,[mx(i,1)+xa(2),mx(i,2)+xa(3),xa(1),xa(4),rsquare, i]'];
    end
end

pts=pts';
outid=pts(:,end);
out=pts(:,1:end-1);