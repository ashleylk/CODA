function register_cell_coordinates_new(pth1x,pthcoords,datapth,scale,rsim,outpth)
if ~exist('rsim','var');rsim=12;end
if ~exist('outpth','var');outpth=[pth1x,'cell_coordinates_registered\'];end
mkdir(outpth);
pthimG=[pth1x,'registered\'];
pthimE=[pth1x,'registered\elastic registration\'];
if ~exist('scim','var');scim=4/3;end
pthD=[datapth,'D\'];
matlist=dir([pthcoords,'*mat']);


outpthim=[outpth,'ims\'];mkdir(outpthim);

load([datapth,matlist(1).name],'padall','szz');
padall=padall*scale;



szz2=imfinfo([pthimG,matlist(1).name(1:end-4),'.jpg']);
szz2=round([szz2.Height szz2.Width]*scale);
for kk=1:length(matlist)
    szz2=imfinfo([pthimG,matlist(kk).name(1:end-4),'.jpg']);
    szz2=round([szz2.Height szz2.Width]*scale);

    load([pthcoords,matlist(kk).name]);
    if exist('cell_unreg','var');xy0=cell_unreg;
    elseif exist('xyboth','var');xy0=xyboth;
    elseif exist('cell_locations','var');xy0=cell_locations;
    elseif exist('leuko','var');xy0=leuko;    
    else;xy0=xy;
    end

    % pad cell coordinates to match registration
    xy=xy0+padall;
    % rough register
    try
        load([datapth,matlist(kk).name],'tform','cent');
        cent=cent*scale;tform.T(3,1:2)=tform.T(3,1:2)*scale;
        
        xyr = transformPointsForward(tform,xy-cent)+cent;
        cc=min(xyr,[],2)>1 & xyr(:,1)<szz2(2) & xyr(:,2)<szz2(1); % keep in-bounds coordinates
        xyr=xyr(cc,:);
    catch
        disp(['no tform for ',matlist(kk).name])
        xyr=xy;
    end 
    %imR=imread([pthimG,matlist(kk).name(1:end-3),'jpg']);figure(1),imshow(imR),hold on,scatter(xyr(:,1)/scale,xyr(:,2)/scale,'*r');
    
    % elastic register points
    szzE=round(szz2/rsim);
    xyrE=floor(xyr/rsim);
    cc=min(xyrE,[],2)>0;xyrE=xyrE(cc,:);
    scaleE=scale/rsim;
    ii=sub2ind(szzE,xyrE(:,2),xyrE(:,1));

    [a,e]=histcounts(ii,1:max(ii)-1);
    xyim=zeros(szzE);
    xyim(e(1:end-1))=a;
    try
        load([pthD,matlist(kk).name],'D');
        D=imresize(D,szzE)*scaleE;
        xyim=imwarp(xyim,D,'nearest');
        y=[];x=[];
        for k=1:max(xyim(:))
            [yt,xt]=find(xyim>=k);
            y=cat(1,y,yt);x=cat(1,x,xt);
        end
        xye=[x y]*rsim;
    catch
        disp('center image elastic')
        xye=xyr;
    end
    %imE=imread([pthimE,matlist(kk).name(1:end-3),'jpg']);figure(2),imshow(imE),hold on,scatter(xye(:,1)/scale,xye(:,2)/scale,'*r');

    % save 12um/pixel image
    %volcell=cat(3,volcell,xyim);
    imwrite(uint8(xyim),[outpthim,matlist(kk).name(1:end-3),'tif']);
    save([outpth,matlist(kk).name],'xyr','xye');
    disp([kk length(matlist) round(sum(xyim(:))/size(xy,1)*100)])
    clearvars xyim xy cell_unreg tform cent D
end
%volcell=uint8(volcell);
%save([outpth,'cells_12um.mat'],'volcell','-v7.3');


end


function [h1,v1]=get_scale_nums(im0,v,h)
    imh=imresize(im0,size(im0(:,:,1)).*[1 h],'nearest');
    a=size(imh,2)-size(im0,2);
    h1=ceil(a/2);
    
    imv=imresize(im0,size(im0(:,:,1)).*[v 1],'nearest');
    a=size(imv,1)-size(im0,1);
    v1=ceil(a/2);
    
end