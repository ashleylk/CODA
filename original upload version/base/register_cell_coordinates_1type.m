function register_cell_coordinates_1type(pth1x,scale,pthcoords,pad2,szvol)
if ~exist('pad2','var');pad2=0;end
datapth=[pth1x,'registered\elastic registration\save_warps\'];
pthD=[pth1x,'registered\elastic registration\save_warps\D\'];
if ~exist('pthcoords','var');pthcoords=[pth1x(1:end-3),'5x\cell_coordinates\'];end


pthimG=[pth1x,'registered\'];
pthimE=[pth1x,'registered\elastic registration\'];
outpth=[pth1x,'registered\elastic registration\cell_coordinates_registered\'];
if ~isfolder(outpth);mkdir(outpth);end
matlist=dir([pthcoords,'*mat']);
volcell=uint8([]);
% scalevol=4/6; % scale from 1x (8um/pixl) to 6um/pixel
scalevol=4.5/8;
% scalevol=1; % scale from 1x (8um/pixl) to 12um/pixel
if exist([pthimE,matlist(1).name(1:end-4),'.jpg'],'file');tp='.jpg';tp2='.tif';else;tp='.tif';tp2='.jpg';end
if ~exist('szvol','var');im=imread([pthimE,matlist(1).name(1:end-4),tp]);szvol=round(size(im(:,:,1))*scalevol);end

load([datapth,matlist(1).name],'padall','szz');
szz2=szz+padall;if pad2==1;szz2=szz+padall;end
count=1;
for kk=1:length(matlist)
    if ~exist([pthD,matlist(kk).name],'file');continue;end
    load([pthcoords,matlist(kk).name],'cell_unreg','xy');%xy=cell_unreg;
    if isempty(xy) || ~isfile([pth1x,matlist(kk).name(1:end-4),'.tif']);continue;end
    xy=xy/scale;
    
    if kk==1
        try im0=imread([pth1x,matlist(kk).name(1:end-4),tp]);catch im0=imread([pth1x,matlist(kk).name(1:end-4),tp2]);end
        figure(31),imshow(im0);hold on;scatter(xy(:,1),xy(:,2),'*y');hold off
    end
    
    xy=xy+padall;
    if pad2==1
        a=imfinfo([pth1x,matlist(kk).name(1:end-4),'.tif']);a=[a.Height a.Width];
        szim=[szz(1)-a(1) szz(2)-a(2)];szA=floor(szim/2);szA=[szA(2) szA(1)];
        xy=xy+szA;
    end
    % rough register points
    try
        load([datapth,matlist(kk).name],'tform','cent','szz');
        xyr = transformPointsForward(tform,xy-cent);
        xyr=xyr+cent;
        cc=min(xyr,[],2)>1 & xyr(:,1)<szz2(2) & xyr(:,2)<szz2(1);
        xyr=round(xyr(cc,:));
    catch
        disp(['no tform for ',matlist(kk).name])
        xyr=xy;
    end

    if kk==1
        try imG=imread([pthimG,matlist(kk).name(1:end-4),tp]);catch;imG=imread([pthimG,matlist(kk).name(1:end-4),tp2]);end
        figure(32),imshow(imG);hold on;scatter(xyr(:,1),xyr(:,2),'*y');hold off
    end
    
    % elastic register points
    try
        load([pthD,matlist(kk).name],'D');
        ii=sub2ind(szz2,xyr(:,2),xyr(:,1));
        [a,e]=histcounts(ii,1:max(ii)-1);
        cl2=zeros(szz2);
        cl2(e(1:end-1))=a;
        cl2=imwarp(cl2,D,'nearest');
        y=[];x=[];
        for k=1:max(cl2(:))
            [yt,xt]=find(cl2==k);
            y=cat(1,y,yt);x=cat(1,x,xt);
        end
        xye=[x y];
    catch
        disp('center image')
        xye=xyr;
    end
    
    if kk==1
        try imE=imread([pthimE,matlist(kk).name(1:end-4),tp]);catch;imE=imread([pthimE,matlist(kk).name(1:end-4),tp2]);end
        figure(33),imshow(imE);hold on;scatter(xye(:,1),xye(:,2),'*y');hold off;pause(1)
    end
    
    % add here, make black image same size as imE, if cell exists, pixel = 1
%     xyevol=round(xye*scalevol);
%     im=uint8(zeros(szvol));
%     ie1=sub2ind(size(im),xyevol(:,2),xyevol(:,1));
%     for kl=1:length(ie1)
%         im(ie1(kl))=im(ie1(kl))+1;
%     end
%     volcell(:,:,count)=im;
    
    count=count+1;
    save([outpth,matlist(kk).name],'xyr','xye');
    disp([kk size(xy,1) size(xye,1)])
%     disp([size(xy,1) size(xye,1) kk length(matlist)])
end
% if max(volcell(:))<256;volcell=uint8(volcell);end
% save([outpth,'cells.mat'],'volcell');

