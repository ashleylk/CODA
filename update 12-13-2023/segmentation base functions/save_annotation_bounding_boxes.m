function [numann,ctlist]=save_annotation_bounding_boxes(im,outpth,nm0,numclass,pthcheck,imnm,classcheck)
% this function will crop H&E and corresponding mask tiles for use in deep
% learning training
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

disp('  Creating bounding box tiles of all annotations')

if exist('classcheck','var')
    outim=[pthcheck,'checkclass_',num2str(classcheck),'\'];
    mkdir(outim);
end

im=double(im);
try
    imlabel=double(imread([outpth,'view_annotations.tif']));
catch
    imlabel=double(imread([outpth,'view_annotations_raw.tif']));
end


pthbb=[outpth,nm0,'_boundbox\'];
pthim=[pthbb,'im\'];
pthlabel=[pthbb,'label\'];
if isfolder('pthim');rmdir(pthim);rmdir(pthlabel);end
mkdir(pthim);mkdir(pthlabel);

tmp=imclose(imlabel>0,strel('disk',10));
tmp=imfill(tmp,'holes');
tmp=bwareaopen(tmp,300);
L=bwlabel(tmp);
numann=zeros([max(L(:)) numclass]);
for pk=1:max(L(:))
    tmp=double(L==pk);
    a=sum(tmp,1);b=sum(tmp,2);
    rect=[find(a,1,'first') find(a,1,'last') find(b,1,'first') find(b,1,'last')];
    tmp=tmp(rect(3):rect(4),rect(1):rect(2));
    
    % make label and  H&E bounding boxes
    tmplabel=imlabel(rect(3):rect(4),rect(1):rect(2)).*tmp;
    tmpim=im(rect(3):rect(4),rect(1):rect(2),:);
    nm=num2str(pk,'%05.f');
    imwrite(uint8(tmpim),[pthim,nm,'.tif']);
    imwrite(uint8(tmplabel),[pthlabel,nm,'.tif']);

    if exist('classcheck','var')
        if sum(tmplabel(:)==classcheck)>0
            imnum=dir([outim,'*',imnm,'*']);
            nn=num2str(length(imnum)+1,'%03.f');
            nmout=[imnm,'_',nn,'.jpg'];
            imwrite(uint8(tmpim),[outim,nmout]);
        end
    end

    for anns=1:numclass
       numann(pk,anns)=sum(tmplabel(:)==anns);           
    end
end
ctlist=dir([pthim,'*tif']);

bb=1; % indicate that xml file is fully analyzed
if exist([outpth,'annotations.mat'],'file')
    save([outpth,'annotations.mat'],'numann','ctlist','bb','-append');
else
    save([outpth,'annotations.mat'],'numann','ctlist','bb');
end
