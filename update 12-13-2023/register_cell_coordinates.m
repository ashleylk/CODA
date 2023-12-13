function register_cell_coordinates(pth0,pthcoords,scale)
% registers coordinates of cells using previously calculated image registration data.  
% REQUIRED INPUTS:
% 1. pth0 = path containing images that registration was upon
% 2. pthcoords = path containing cell coordinates
%         cell coordinates should be saved in .mat files in a variable called 'xy', with a separate file for each image. 
%         [example image_001.tif has image_001.mat, containing a variable xy that is size Nx2 for N cell coordinates] 
% 3. scale = scale between coordinate images and registration images.
%         [example: registration calculated on 1x images, cell detection performed on 10x images. scale=10]
% OUTPUTS:
% 1. Will create a folder inside of pthcoords called 'cell_coordinates_registered.'
%    Inside of this folder will be mat files for each image containing variables:
%        xy (unregistered cell coordinates)
%        xyg (globally registered cell coordinates)
%        xye (elastically registered cell coordinates)
% 2. During the run, MATLAB will output 3 images for the first image:
%        The unregistered H&E image with the unregistered coordinates overlayed
%        The globally H&E image with the globally registered coordinates overlayed
%        The elastically H&E image with the elastically registered coordinates overlayed
%    if the coordinates do not overlay with the image, something is wrong.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

% add base functions to the MATLAB search path
path(path,'image registration base functions');

% define paths using pth0
if pth0(end)~='\';pth0=[pth0,'\'];end
if pthcoords(end)~='\';pthcoords=[pthcoords,'\'];end
pthimG=[pth0,'registered\'];
pthimE=[pthimG,'elastic registration\'];
outpth=[pthcoords,'cell_coordinates_registered\'];mkdir(outpth);
datapth=[pthimE,'save_warps\'];
pthD=[datapth,'D\'];

% set up padding information and find registered images
matlist=dir([pthcoords,'*mat']);
if exist([pthimE,matlist(1).name(1:end-4),'.jpg'],'file');tp='.jpg';tp2='.tif';else;tp='.tif';tp2='.jpg';end
try 
    load([datapth,matlist(1).name],'padall','szz');
catch
    load([datapth,matlist(2).name],'padall','szz');
end
szz2=szz+(2*padall);
szz3=round(szz2*scale);
pad2=1;

% register coordinates for each image
for kk=1:length(matlist)
    tic;
    if ~exist([pthD,matlist(kk).name],'file');continue;end
    if exist([outpth,matlist(kk).name],'file');continue;end
    
    load([pthcoords,matlist(kk).name],'xy');
    xy=xy/scale;
    
    % check unregistered image
    if kk==1
        try im0=imread([pth0,matlist(kk).name(1:end-4),tp]);catch im0=imread([pth0,matlist(kk).name(1:end-4),tp2]);end
        figure(31),imshow(im0);hold on;scatter(xy(:,1),xy(:,2),'*y');hold off;title('unregistered results')
    end
    
    % rough register points
    xyp=xy+padall;
    if pad2==1
        try a=imfinfo([pth0,matlist(kk).name(1:end-4),tp]);catch a=imfinfo([pth0,matlist(kk).name(1:end-4),tp2]);end
        a=[a.Height a.Width];
        szim=[szz(1)-a(1) szz(2)-a(2)];szA=floor(szim/2);szA=[szA(2) szA(1)];
        xyp=xyp+szA;
    end
    try
        load([datapth,matlist(kk).name],'tform','cent','f');
        if f==1;xyp=[xyp(:,1) szz(1)+2*padall-xyp(:,2)];end
        xyr = transformPointsForward(tform,xyp-cent);
        xyr=xyr+cent;
        cc=min(xyr,[],2)>1 & xyr(:,1)<szz2(2) & xyr(:,2)<szz2(1);
        xyr=xyr(cc,:);
    catch
        disp(['no tform for ',matlist(kk).name])
        xyr=xyp;
    end
    if kk==1
        try imG=imread([pthimG,matlist(kk).name(1:end-4),tp]);catch;imG=imread([pthimG,matlist(kk).name(1:end-4),tp2]);end
        figure(32),imshow(imG);hold on;scatter(xyr(:,1),xyr(:,2),'*y');hold off;title('globally registered results')
    end
    
    % elastic register points
    try
        xytmp=xyr*scale;
        load([pthD,matlist(kk).name],'D');
        D=imresize(D,5);
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
        figure(33),imshow(imE);hold on;scatter(xye(:,1),xye(:,2),'*y');hold off;title('elastically registered results')
        pause(1)
    end
    
    xy=xy*scale;xyr=xyr*scale;xye=xye*scale;
    save([outpth,matlist(kk).name],'xy','xyr','xye');
    disp([' registered cells from image ',num2str(kk),' of ',...
        num2str(length(matlist)),' in ',num2str(round(toc)),' seconds']);
    clearvars tform cent f
end


