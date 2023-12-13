function xyc=combine_z_projections(vol,nums,contrasts,cmap,axisxyz)
% this function will create pretty, RGB z-projections of tissue volumes
% REQUIRED INPUTS:
% vol: volumetric matrix (of size [M N Z])
% nums: numbers of classes you want to create a z-projection of
% contrasts: matrix with constrast numbers for z-projection (1 = base, >1 = increase contrast. 
%     example for a model with 5 classes: contrast = [1 1 1 1 1.5]; (increase contrast of type 5)
% cmap: rgb colors for each class in the vol. defined in segmentation code
% OPTIONAL INPUT
% axisxyz: which axis do you want to create the projection along? default = 3 (z-projection), could also be 1 or 2
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('axisxyz','var');axisxyz=3;end
cmap=double(cmap);
if max(cmap(:))>1
    cmap=cmap/255;
end

tmp=squeeze(sum(vol,axisxyz));
xyc=zeros([size(tmp) 3]);
for k=nums
    % make colormap
    cmap2=cmap(k,:);
    a=linspace(0,cmap2(1),100)';
    b=linspace(0,cmap2(2),100)';
    c=linspace(0,cmap2(3),100)';
    C=[a b c]*contrasts(k); % enhance contrast
    C(C>1)=1;
    
    % make rgb z-projection
    xy0=squeeze(sum(vol==k,axisxyz)); 
    xy0=round(xy0./max(xy0(:))*99)+1;

    xy0(isnan(xy0))=1;
    xy=cat(3,C(xy0,1),C(xy0,2),C(xy0,3));
    xy=reshape(xy,[size(xy0) 3]);
    xyc=xyc+xy;
end

