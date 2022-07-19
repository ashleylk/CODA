function [imh,imlabel]=random_augmentation(imh0,imlabel0,rot,sc,hue,bl,rsz)
% randomly augments with rotation, scaling, and hue
if nargin<7
    rot=1;
    sc=1;
    hue=1;
    rsz=0;
    bl=0;
end
if ~exist('imlabel0','var');imlabel0=imh0;end

imh=double(imh0);
imlabel=double(imlabel0);
szz=size(imh0,1);

% random rotation
if rot
   angs=0:5:355;
   ii=randperm(3,1);
   imh=imrotate(imh,angs(ii));
   imlabel=imrotate(imlabel,angs(ii));
end

% random scaling
if sc
   scales=[0.75:0.01:0.9 1.1:0.01:1.25];
   ii=randperm(length(scales),1);
   imh=imresize(imh,scales(ii),'nearest');
   imlabel=imresize(imlabel,scales(ii),'nearest');
end

if hue
   % scale blue / red 
    rd=[0.88:0.01:0.98 1.02:0.01:1.12];
    bl=[0.88:0.01:0.98 1.02:0.01:1.12];
    gr=[0.88:0.01:0.98 1.02:0.01:1.12];
    ird=randperm(length(rd),1);
    ibl=randperm(length(bl),1);
    igr=randperm(length(gr),1);
    
    % scale red
    imr=255-imh(:,:,1);
    imh(:,:,1)=255-(imr*rd(ird));
    % scale blue
    imb=255-imh(:,:,3);    
    imh(:,:,3)=255-(imb*bl(ibl));
    % scale green
    img=255-imh(:,:,2);    
    imh(:,:,3)=255-(img*gr(igr));
end

if bl
   bll=ones([1 50]);
   bll(1)=1.05;
   bll(2)=1.1;
   bll(3)=1.15;
   bll(4)=1.2;
   ibl=randperm(length(bll),1);
   bll=bll(ibl);
   
   if bll~=1
       imh=imgaussfilt(imh,bll);
   end
end


if rsz
    szh=size(imh,1);
    if szh>szz
       cent=round(size(imh,1)/2);
       sz1=floor((szz-1)/2);
       sz2=ceil((szz-1)/2);
       imh=imh(cent-sz1:cent+sz2,cent-sz1:cent+sz2,:);
       imlabel=imlabel(cent-sz1:cent+sz2,cent-sz1:cent+sz2,:);
    end

    if szh<szz
       tt=szz-szh;
       imh=padarray(imh,[tt tt],0,'post');
       imlabel=padarray(imlabel,[tt tt],0,'post');
    end
end

% remove non-annotated pixels from imH
tmp=imlabel~=0;
tmp=cat(3,tmp,tmp,tmp);
imh=imh.*tmp;


% figure(18),
%     subplot(2,2,1),imshow(imh0)
%     subplot(2,2,2),imagesc(imlabel0);axis equal;axis off
%     subplot(2,2,3),imshow(uint8(imh))
%     subplot(2,2,4),imagesc(imlabel);axis equal;axis off