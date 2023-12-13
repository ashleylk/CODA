function I2=make_check_annotation_classified_image(im,J,cmap,ds,filename)
% this function will make you a nice visualization of the classfication
% overlayed on top of the original, RGB image
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('ds','var');ds=2;end

cmap2=cat(1,[0 0 0],cmap)/255;

im=im(1:ds:end,1:ds:end,:);J=J(1:ds:end,1:ds:end,:);
I=im2double(im);J=double(J);
J1=cmap2(J+1,1);J1=reshape(J1,size(J));
J2=cmap2(J+1,2);J2=reshape(J2,size(J));
J3=cmap2(J+1,3);J3=reshape(J3,size(J));
mask=cat(3,J1,J2,J3);
I2=(I*0.6)+(mask*0.4);
I2=uint8(I2*255);

if exist('filename','var')
    imwrite(I2,strrep(filename,'.tif','.jpg'));
end
