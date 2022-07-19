function register_cell_coordinates_2022(pth0,pthcoords,scale)
% pth0 = path containing images where registration was calculated
% pthcoords = path to cell coordinates
% scale = scale between coordinate images and registration images (>1)

% define paths using pth0
pthimG=[pth0,'registered\'];
pthimE=[pthimG,'elastic registration\'];
outpth=[pthimE,'cell_coordinates_registered\'];mkdir(outpth);
datapth=[pthimE,'save_warps\'];
pthD=[datapth,'D\'];

% set up padding information and find registered images
matlist=dir([pthcoords,'*mat']);
if exist([pthimE,matlist(1).name(1:end-4),'.jpg'],'file');tp='.jpg';tp2='.tif';else;tp='.tif';tp2='.jpg';end
load([datapth,matlist(1).name],'padall','szz');
szz2=szz+(2*padall);
szz3=round(szz2*scale);
pad2=1;

% register coordinates for each image
for kk=1:length(matlist)
    if ~exist([pthD,matlist(kk).name],'file');continue;end
    load([pthcoords,matlist(kk).name],'xy');
    if isempty(xy) || ~isfile([pth0,matlist(kk).name(1:end-4),'.tif']);continue;end
    xy=xy/scale;
    
    % check unregistered image
%     if kk==1
%         try im0=imread([pth0,matlist(kk).name(1:end-4),tp]);catch im0=imread([pth0,matlist(kk).name(1:end-4),tp2]);end
%         figure(31),imshow(im0);hold on;scatter(xy(:,1),xy(:,2),'*y');hold off
%     end
    
    % rough register points
    xy=xy+padall;
    if pad2==1
        a=imfinfo([pth0,matlist(kk).name(1:end-4),'.tif']);a=[a.Height a.Width];
        szim=[szz(1)-a(1) szz(2)-a(2)];szA=floor(szim/2);szA=[szA(2) szA(1)];
        xy=xy+szA;
    end
    try
        load([datapth,matlist(kk).name],'tform','cent','szz');
        xyr = transformPointsForward(tform,xy-cent);
        xyr=xyr+cent;
        cc=min(xyr,[],2)>1 & xyr(:,1)<szz2(2) & xyr(:,2)<szz2(1);
        xyr=xyr(cc,:);
    catch
        disp(['no tform for ',matlist(kk).name])
        xyr=xy;
    end
%     if kk==1
%         try imG=imread([pthimG,matlist(kk).name(1:end-4),tp]);catch;imG=imread([pthimG,matlist(kk).name(1:end-4),tp2]);end
%         figure(32),imshow(imG);hold on;scatter(xyr(:,1),xyr(:,2),'*y');hold off
%     end
    
    % elastic register points
    try
        xytmp=xyr*scale;
        load([pthD,matlist(kk).name],'D');
        Dnew=invert_D(D);
        D2=imresize(Dnew,szz3)*scale;
        D2a=D2(:,:,1);D2b=D2(:,:,2);
        pp=round(xytmp);
        ii=sub2ind(szz3,pp(:,2),pp(:,1));
        xmove=[D2a(ii) D2b(ii)];
        xye=xytmp+xmove;
        xye=xye/scale;
    catch
        disp('center image')
        xye=xyr;
    end
    
    if kk==1
        try imE=imread([pthimE,matlist(kk).name(1:end-4),tp]);catch;imE=imread([pthimE,matlist(kk).name(1:end-4),tp2]);end
        figure(33),imshow(imE);hold on;scatter(xye(:,1),xye(:,2),'*y');hold off;pause(1)
    end
    
    save([outpth,matlist(kk).name],'xyr','xye');
    disp([kk size(xy,1) size(xye,1)])
end


