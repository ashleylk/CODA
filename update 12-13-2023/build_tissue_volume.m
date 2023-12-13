function build_tissue_volume(pthclassifiedE,pthvolume,sk,nwhite,cmap)
% creates a volumetric matrix the registered, classified images
% REQUIRED INPUTS: 
% pthclassifiedE: folder containing the registered, segmented images
% outpth_vol: folder where you want to save the resulting volumetric file
% sk: downsample factor from the high-resolution images in pthDLE to the size you want to create. 
%     example: if you have 10x images of resolution 1um/pixel, and want a volume of xy resolution (z resolution defined by tissue section thickness) 4um/pixel, sk=4
% nwhite: the class number of background/whitespace in your segmentation model
% cmap: matrix containing RGB colors for each of the tissue labels in uint8-bit space (this should be defined in your deeplab code
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if pthclassifiedE(end)~='\';pthclassifiedE=[pthclassifiedE,'\'];end
if pthvolume(end)~='\';pthvolume=[pthvolume,'\'];end

if ~isfolder(pthvolume);mkdir(pthvolume);end
imlist=dir([pthclassifiedE,'*tif']);

a=imfinfo([pthclassifiedE,imlist(1).name]);
a=[a.Height a.Width];

% manually crop the whitespace out of hte tissue to save memory
im1=imread([pthclassifiedE,imlist(1).name],'PixelRegion',{[1 sk a(1)],[1 sk a(2)]});
im2=imread([pthclassifiedE,imlist(ceil(length(imlist)/2)).name],'PixelRegion',{[1 sk a(1)],[1 sk a(2)]});
im3=imread([pthclassifiedE,imlist(end).name],'PixelRegion',{[1 sk a(1)],[1 sk a(2)]});
im1(im1==nwhite)=0;im2(im2==nwhite)=0;im3(im3==nwhite)=0;
im=cat(3,im1,im2,im3);
minfact=floor(255/max(im(:)));
im=im*minfact;
h=figure;[~,rr]=imcrop(im);close(h);
rr=round(rr);
im=imcrop(im,rr);

% create volume at cropped size
vol=uint8(zeros([size(im(:,:,1)) length(imlist)]));
for k=1:length(imlist)
    im=imread([pthclassifiedE,imlist(k).name],'PixelRegion',{[1 sk a(1)],[1 sk a(2)]});
    vol(:,:,k)=imcrop(im,rr);
    disp([k length(imlist)]);
end

% make some z-projections
contrast=ones([1 size(cmap,1)]);
b=unique(vol);
b=setdiff(b,[0 nwhite]);
xyc=combine_z_projections(vol,b',contrast,cmap);
figure;imshow(xyc);title('z-projection of all structures');

imwrite(xyc,[pthvolume,'z-projection.jpg']);
save([pthvolume,'volume.mat'],'vol','rr','pthclassifiedE','imlist','sk');




