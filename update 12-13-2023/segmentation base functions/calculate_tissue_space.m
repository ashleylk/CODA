function [im0,TA,outpth]=calculate_tissue_space(pth,imnm)
% creates logical image with tissue area
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

outpth=[pth,'TA\'];
if ~isfolder(outpth);mkdir(outpth);end

try im0=imread([pth,imnm,'.tif']);
catch
    try im0=imread([pth,imnm,'.jp2']);
    catch
        im0=imread([pth,imnm,'.jpg']);
    end
end
if exist([outpth,imnm,'.tif'],'file')
    TA=imread([outpth,imnm,'.tif']);disp('  existing TA loaded')
    return;
end

% im=double(imgaussfilt(im0,1));
% TA=std(im,[],3);
% TA=TA>6.5;
TA=im0(:,:,2)<220; % 210
TA=imclose(TA,strel('disk',1));
TA=bwareaopen(TA,4);
%figure,imshowpair(im0,TA);axis equal;axis off
imwrite(uint8(TA),[outpth,imnm,'.tif']);

