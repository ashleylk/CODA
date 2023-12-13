function make_cell_detection_mosaic(pthHR,pthLR,num,sxy)
% this function will create a num x num mosaic image containing tiles from
% several histological images for use in validating automated cell detection
% the code will display num x num low resolution images to the user. the
% user must click once on each image to select the region to perform manual
% cell detection on
% REQUIRED INPUTS:
% pthHR: path to high resolution images to create mosaic from
% pthLR: path to low resolution images to choose mosaic locations
% OPTIONAL INPUTS:
% num: square root of number of tiles to create. default value = 3
% sxy: pixel size (in high resolution image space) of each desired tile. default value = 300
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('num','var');num=3;end
if ~exist('sxy','var');sxy=100;end

if pthHR(end)~='\';pthHR=[pthHR,'\'];end
if pthLR(end)~='\';pthLR=[pthLR,'\'];end

% make the output folder
pthmosaic=[pthHR,'cell_detection_validation\'];
if ~isfolder(pthmosaic);mkdir(pthmosaic);end

% randomly choose images to create tiles from
imlist=dir([pthHR,'*tif']);
if num^2>length(imlist)
    % allow duplicates if number of tiles needed exceeds number of images
    imnums=randi(length(imlist),[1 num^2]);
else
    % must choose non-repeating images
    imnums=randperm(length(imlist),num^2);
end
imlist=imlist(imnums);

% determine scale between low and high-resolution images
m1=imfinfo([pthHR,imlist(1).name]);m1=m1.Height;
m2=imfinfo([pthLR,imlist(1).name]);m2=m2.Height;
scale=m1/m2;

% load low-resolution images and manually select locations for validation
coords=zeros([length(imnums) 2]);
for b=1:length(imlist)
    nm=imlist(b).name;
    im=imread([pthLR,nm]);
    
    h=figure;
        imshow(im);
        title('click on an ROI in this image')
        [x,y]=ginput(1);
        close(h);
    coords(b,:)=[x y];
end

% create mosaic from high-resolution images
count=1;
imXX=[];
for xx=1:num
    imYY=[];
    for yy=1:num
        nm=imlist(count).name;
        coordxy=round(coords(count,:)*scale);
        xx=coordxy(1)-sxy:coordxy(1)+sxy;
        yy=coordxy(2)-sxy:coordxy(2)+sxy;
        imtmp=imread([pthHR,nm],'PixelRegion',{[yy(1) yy(end)],[xx(1) xx(end)]});
        
        imYY=cat(1,imYY,imtmp);
        count=count+1;
    end
    
    imXX=cat(2,imXX,imYY);
end

imwrite(imXX,[pthmosaic,'mosaic.tif']);
