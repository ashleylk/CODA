function [im,TA]=get_ims(pth,nm,tp,rdo)
if ~exist([pth,'TA\'],'dir');mkdir([pth,'TA\']);end
if ~exist('rdo','var');rdo=0;end

im=imread([pth,nm,tp]);
if size(im,3)==1;im=cat(3,im,im,im);end
pthTA=[pth,'TA\'];
if exist([pthTA,nm,'tif'],'file') && ~rdo
    TA=imread([pthTA,nm,'tif']);
else
    TA=find_tissue_area(im,nm);
    imwrite(TA,[pthTA,nm,'tif']);
end


% figure,subplot(1,2,1),imshow(im);subplot(1,2,2),imshow(TA)
% TA=im(:,:,1);
% TA=TA>30;
% TA=imclose(TA,strel('disk',10));
% TA=bwareaopen(TA,5000);
% imshow(TA)