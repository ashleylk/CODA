function [im,TA]=get_ims(pth,nm,tp,IHC)
% loads RGB histological image and loads or creates tissue space image for use in a nonlinear image registration algorithm.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist([pth,'TA\'],'dir');mkdir([pth,'TA\']);end

im=imread([pth,nm,tp]);
if size(im,3)==1;im=cat(3,im,im,im);end
pthTA=[pth,'TA\'];
if exist([pthTA,nm,'tif'],'file')
    TA=imread([pthTA,nm,'tif']);
else
    TA=find_tissue_area(im,IHC);
    imwrite(TA,[pthTA,nm,'tif']);
end
TA=uint8(TA>0);
