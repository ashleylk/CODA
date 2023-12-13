function [D,xgg,ygg,x,y]=make_final_grids(xgg0,ygg0,bf,x,y,szim)
% xgg / ygg = 20x17 or whatever grid of displacements for image
% x / y = points on 1x image that xgg and ygg are centered at
% C0 = corr2 of immv and imrf tiles before elastic registration
% CR = corr2 of immv and imrf tiles after elastic registration (same size as xgg / ygg)
% bf = buffer I applied around 1x image (bf = 0 if you have no buffer)
% sz = size of each tile that finetune registration is calculated on (mine are 250)
% szim = size of 1x image
% xgg / ygg are -5000 at locations that don't have tissue space

xgg=xgg0;
ygg=ygg0;
if 1
    mxy=75;%50 % allow no translation larger than this cutoff
    cmxy=xgg>mxy | ygg>mxy; % non continuous values
    xgg(cmxy)=-5000;
    
    % find points where registration was calculated
    cempty=xgg==-5000;
    xgg(cempty)=0;ygg(cempty)=0;
    
    %xgg0=xgg;ygg0=ygg;
    % replace non continuous values with mean of neighbors
    [~,~,dxgg,dygg,~,sxgg,sygg]=fill_vals(xgg,ygg,cempty,1);
    m1=abs((xgg-dxgg)./dxgg);m1(m1==Inf)=0; % percent difference between x and mean of surrounding
    m2=abs((ygg-dygg)./dygg);m2(m2==Inf)=0;
    dds=sxgg>50 | sygg>50;ddm=m1>5 | m2>5;ddp=abs(xgg)>80 | abs(ygg)>80;
    dd=(dds | ddm | ddp) & ~cempty;
    xgg(dd)=dxgg(dd);ygg(dd)=dygg(dd);
    
    % fill in values outside tissue region with mean of neighbors
    cc=cempty;count=1;
    while sum(cc(:))>0 && count<500
        [~,~,dxgg,dygg,denom]=fill_vals(xgg,ygg,cc);
        cfill=denom>2 & cc; % touching 3+ numbers and needs to be filled
        xgg(cfill)=dxgg(cfill);
        ygg(cfill)=dygg(cfill);
        cc=cc & ~cfill; % needs to be filled and has not been filled
        count=count+1;
    end
    disp([count 500])
    xgg=imgaussfilt(xgg,1);
    ygg=imgaussfilt(ygg,1);    
else
    cempty=xgg==-5000;
    xgg(cempty)=0;ygg(cempty)=0;
    
    ct=30;
    xgg(abs(xgg)>ct)=0;
    ygg(abs(ygg)>ct)=0;
    
    xgg=imgaussfilt(xgg,2);
    ygg=imgaussfilt(ygg,2);
end
    
    % add buffer to outline of displacement map to avoid discontinuity
    xgg=cat(1,xgg(1,:),xgg,xgg(end,:));
    xgg=cat(2,xgg(:,1),xgg,xgg(:,end));
    ygg=cat(1,ygg(1,:),ygg,ygg(end,:));
    ygg=cat(2,ygg(:,1),ygg,ygg(:,end));
    
    x=[1; unique(x)-bf; szim(2)];
    y=[1; unique(y)-bf; szim(1)];
    
    % get D
    [xq,yq] = meshgrid(1:szim(2),1:szim(1));
    xgq=interp2(x,y,xgg,xq,yq,'spline');
    ygq=interp2(x,y,ygg,xq,yq,'spline');
    D=cat(3,xgq,ygq);
    
end


function [xgg,ygg,dxgg,dygg,denom,sxgg,sygg]=fill_vals(xgg,ygg,cc,xystd)
if ~exist('xystd','var');xystd=0;sxgg=[];sygg=[];end
% xgg ygg are matrices to be smoothed
% cc is logical matrix containing locations to be smoothed
    denom=imfilter(double(~cc),[1 1 1;1 0 1;1 1 1]);
    
    if xystd % get standard deviation of nearest neighbors
        gridX=get_nn_grids(xgg);
        gridY=get_nn_grids(ygg);
        gridD=get_nn_grids(~cc);
        gridX=(gridX-xgg).^2.*gridD;
        gridY=(gridY-ygg).^2.*gridD;
        
        sxgg=(sum(gridX,3)./sum(denom,3)).^0.5;sxgg(cc)=0;
        sygg=(sum(gridY,3)./sum(denom,3)).^0.5;sygg(cc)=0;
    end
    
    denom(denom==0)=1;
    dxgg=imfilter(xgg,[1 1 1;1 0 1;1 1 1])./denom;
    dygg=imfilter(ygg,[1 1 1;1 0 1;1 1 1])./denom;
    xgg(cc)=dxgg(cc);
    ygg(cc)=dygg(cc);
end

function gridX=get_nn_grids(xgg)
    d1=imfilter(xgg,[1 0 0;0 0 0;0 0 0]);
    d2=imfilter(xgg,[0 1 0;0 0 0;0 0 0]);
    d3=imfilter(xgg,[0 0 1;0 0 0;0 0 0]);
    d4=imfilter(xgg,[0 0 0;1 0 0;0 0 0]);
    d5=imfilter(xgg,[0 0 0;0 0 1;0 0 0]);
    d6=imfilter(xgg,[0 0 0;0 0 0;1 0 0]);
    d7=imfilter(xgg,[0 0 0;0 0 0;0 1 0]);
    d8=imfilter(xgg,[0 0 0;0 0 0;0 0 1]);
    gridX=cat(3,d1,d2,d3,d4,d5,d6,d7,d8);
end

%     CP=(CR-C0)./C0;
%     cc=CP<0;  %     cc=(CR-C0)./C0<0 | abs(xgg)>sz/4 | abs(ygg)>sz/4;
%     [xgg,ygg]=fill_vals(xgg,ygg,cc);