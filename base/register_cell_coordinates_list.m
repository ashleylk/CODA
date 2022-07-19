function xyout=register_cell_coordinates_list(cellinfo,pth1x,scale,ext)
if ~exist('ext','var');ext='';end

% location of images and registration data
pthimG=[pth1x,'registered\'];
pthimE=[pthimG,'elastic registration',ext,'\'];
datapth=[pthimE,'save_warps\'];
datapthD=[pthimE,'save_warps\D\'];
outD=[datapthD,'Dnew\'];mkdir(outD);
matlist=dir([pthimE,'*jpg']);

% initial settings
load([datapth,matlist(1).name(1:end-3),'mat'],'padall');
szz2=imfinfo([pthimG,matlist(1).name]);
szz2=round([szz2.Height szz2.Width]*scale);
padall=padall*scale;
rsim=scale; % resize factor for elastic registration
xyout=zeros(size(cellinfo));
szzE=round(szz2/rsim);
scaleE=scale/rsim;

tic;
% register coordinates for each image
for kk=1:length(matlist)
    nm=matlist(kk).name(1:end-3);
    ff=find(cellinfo(:,1)==kk);
    xyout(ff,1)=kk;
    xy0=cellinfo(ff,2:3);
    if isempty(xy0);continue;end
    %im0=imread([pth1x,nm,'tif']);figure(1),imshow(im0),hold on,scatter(xy0(:,1)/scale,xy0(:,2)/scale,'*g');
    
    % pad cell coordinates to match registration
    xy=xy0+padall;
    
    % rough register
    try
        load([datapth,nm,'mat'],'tform','cent','f');
        if ~exist('f','var');f=0;end
        cent=cent*scale;tform.T(3,1:2)=tform.T(3,1:2)*scale;
        if f==1;xy=[xy(:,1) szz2(1)-xy(:,2)];end
        xyr = transformPointsForward(tform,xy-cent)+cent;
    catch
        disp(['no tform for ',nm])
        xyr=xy;
    end 
    %imR=imread([pthimG,nm,'jpg']);figure(2),imshow(imR),hold on,scatter(xyr(:,1)/scale,xyr(:,2)/scale,'*g');
    
    % elastic register points
    try
        load([datapthD,nm,'mat'],'D');
        D=imresize(D,szzE)*scaleE;
        xyim=zeros(size(D));
        try load([outD,nm,'mat'],'Dnew');catch;Dnew=invert_D(D);save([outD,nm,'mat'],'Dnew');end
    catch
        disp('center image elastic')
        Dnew=zeros([size(xyim) 2]);
    end
    D1=Dnew(:,:,1);D2=Dnew(:,:,2);
    xyrE=floor(xyr/rsim);
    cc=min(xyrE,[],2)>0;xyrE=xyrE(cc,:);
    ii=sub2ind(size(Dnew),xyrE(:,2),xyrE(:,1));
    ixyA=[D1(ii) D2(ii)];
    xye=xyrE+ixyA;
    xye=xye*rsim;
    %imE=imread([pthimE,nm,'jpg']);figure(3),imshow(imE),hold on,scatter(xye(:,1)/scale,xye(:,2)/scale,'*g');

    % add coordinates to list
    disp([kk length(matlist) size(xye,1) round(toc/60)])
    try xyout(ff,2:3)=xye;
    catch
        disp('cca')
    end
    clearvars xyim xy cell_unreg tform cent D Dnew f
end


end