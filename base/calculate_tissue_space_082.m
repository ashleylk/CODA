function [im0,TA,outpth]=calculate_tissue_space_082(pth,imnm)
% creates logical image with tissue area

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
    TA=imread([outpth,imnm,'.tif']);
    return;
end

im=double(imgaussfilt(im0,1));
TA=std(im,[],3);
TA=TA>4;
TA=bwareaopen(TA,9);
figure(12),imshowpair(im0,TA);axis equal;axis off
imwrite(uint8(TA),[outpth,imnm,'.tif']);

