function apply_image_registration(pthim,pthdata,scale,padnum,cropim,redo)
% Applies the registration calculated by 'calculate_image_registration' to a separate list of images
% REQUIRED INPUTS: 
% 1. pthim: path to images you want to register with previously calculated registration information
% 2. pthdata: path to the registration transfromations previously calculated. Folder is output by 'calculate_image_registration' and is named 'save_warps'
% 3. scale: scale between the images you want to register and the images the registration was calculated on. [example: pthim=10x images, original registration on 1x images. scale=10]
% OPTIONAL INPUTS:
% 1. padnum: pixel value to fill in empty space in images due to rotation / translation. Default is the mode of each channel of the image.
% 2. cropim: logical input. 1 if you want to manually crop out whitespace from the registered images. 0 if you do not. Default is 0
          % if 1, you will be shown a concatenated image made from the first, center, and last image in your z-stack.
          % type a rotation angle, then press enter to see the rotated image.
          % press 0 while you want to update the angle. press 1 when the angle is good.
          % next, select the cropping by highlighting a box on the tissue image with your mouse. double-click to accept the crop region.
          % this cropping will be applied to all registered images in pthim
% 3. redo: logical input. 1 if you want to overwrite previous registration results. 0 if you want to skip previously registered images. Default is 0
% OUTPUTS:
% 1. will create a folder named 'registeredE' inside of the pthim folder containing the images in pthim registered using the registration data in pthdata.
%    only images in pthim with matching '.mat' files in pthdata will be    registered.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('redo','var');redo=0;end
if ~exist('padnum','var');pd=1;padnum=[];else;pd=0;end
if isempty(padnum);pd=1;end
if ~exist('cropim','var');cropim=0;end

% add base functions to the MATLAB search path
path(path,'image registration base functions');

if pthim(end)~='\';pthim=[pthim,'\'];end
if pthdata(end)~='\';pthdata=[pthdata,'\'];end
imlist=dir([pthim,'*tif']);fl='tif';
if isempty(imlist);imlist=dir([pthim,'*jp2']);fl='jp2';end
if isempty(imlist);imlist=dir([pthim,'*jpg']);fl='jpg';end
outpth=[pthim,'registeredE\'];
if ~isfolder(outpth);mkdir(outpth);end
matlist=dir([pthdata,'D\','*mat']);

try 
    datafileE=[pthdata,matlist(1).name];
    load(datafileE,'szz','padall');
catch
    datafileE=[pthdata,matlist(end).name];
    load(datafileE,'szz','padall');
end

padall=ceil(padall*scale);
refsize=ceil(szz*scale);

% determine crop region
if cropim~=0
    if exist([outpth,'crop_data.mat'],'file')
        load([outpth,'crop_data.mat'],'rot','rr');
    else
        if length(cropim)==1
            [rot,rr]=get_cropim(pthdata,scale);
        else
            rot=cropim(1);rr=cropim(2:end);
        end
        save([outpth,'crop_data.mat'],'rot','rr');
    end
end

% register each image and save to outpth
count=1;
for kz=1:length(matlist)
    imnm=[matlist(kz).name(1:end-3),fl];outnm=imnm;
    disp(['registering image ',num2str(kz),' of ',num2str(length(matlist)),': ',imnm])
    if exist([outpth,outnm],'file') && ~redo;disp('  already registered');continue;end
    
    
    if ~exist([pthim,imnm],'file');continue;end
    datafileE=[pthdata,imnm(1:end-3),'mat'];
    datafileD=[[pthdata,'D\'],imnm(1:end-3),'mat'];
    if ~exist(datafileD,'file');continue;end
    
    % load image
    IM=imread([pthim,imnm]);
    szim=size(IM(:,:,1));
    if pd;padnum=squeeze(mode(mode(IM,2),1))';end
    if szim(1)>refsize(1) || szim(2)>refsize(2)
        a=min([szim; refsize]);
        IM=IM(1:a(1),1:a(2),:);
    end
    IM=pad_im_both2(IM,refsize,padall,padnum);
    
    % if not reference image, register
    try
        load(datafileE,'tform','cent','f');
        if f==1;IM=IM(end:-1:1,:,:);end
        IMG=register_IM(IM,tform,scale,cent,padnum);

        load(datafileD,'D');
        D2=imresize(D,size(IM(:,:,1)));
        D2=D2.*scale;
        IME=imwarp(IMG,D2,'nearest','FillValues',padnum);
    % no transformation if this is reference image
    catch
        IME=IM;
    end
    
    if count==1
       pth1=[pthdata,'..\'];
       try 
           im=imread([pth1,matlist(kz).name(1:end-3),'jpg']);
       catch
           im=imread([pth1,matlist(kz).name(1:end-3),'tif']);
       end
       im2=imresize(IME,size(im(:,:,1)),'nearest');
       figure,imshowpair(im,im2);pause(2);
    end
    
    if cropim
        IME=imrotate(IME,rot,'nearest');
        IME=imcrop(IME,rr);
    end
    imwrite(IME,[outpth,outnm]);

    count=count+1;
    disp('  done');
    clearvars tform rsc cent D f
end

end

function IM=register_IM(IM,tform,scale,cent,abc)    
    % rough registration
    cent=cent*scale;
    tform.T(3,1:2)=tform.T(3,1:2)*scale;
    Rin=imref2d(size(IM));
        Rin.XWorldLimits = Rin.XWorldLimits-cent(1);
        Rin.YWorldLimits = Rin.YWorldLimits-cent(2);
    IM=imwarp(IM,Rin,tform,'nearest','outputview',Rin,'fillvalues',abc);
end


function [rot,rr]=get_cropim(pthdata,scale)

    pth1=[pthdata,'..\'];
    imlist=dir([pth1,'*tif']);if isempty(imlist);imlist=dir([pth1,'*jpg']);end
    im1=rgb2gray(imread([pth1,imlist(1).name]));
    im2=rgb2gray(imread([pth1,imlist(round(length(imlist)/2)).name]));
    im3=rgb2gray(imread([pth1,imlist(end).name]));
    im=cat(3,im1,im2,im3);
    h=figure;imshow(im);isgood=0;
    while isgood~=1
        rot=input('angle?\n');
        imshow(imrotate(im,rot));
        isgood=input('is good?\n');
    end
    im=imrotate(im,rot,'nearest');
    [~,rr]=imcrop(im);
    rr=round(rr)*scale;
    close(h)

end


