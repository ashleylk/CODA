function [numann,ctlist0]=annotation_bounding_boxes(im,outpth,nm,numclass,fn,imlabel)
disp('  Creating bounding box tiles of all annotations')

im=double(im);
if ~exist('imlabel','var')
    try
        imlabel=imread([outpth,'view_annotations.tif']);
    catch
        imlabel=imread([outpth,'view_annotations_raw.tif']);
    end
end
imlabel=double(imlabel);

pthbb=[outpth,nm,'_boundbox\'];
pthim=[pthbb,'im\'];
pthlabel=[pthbb,'label\'];
if isfolder('pthim');rmdir(pthim);rmdir(pthlabel);end
mkdir(pthim);mkdir(pthlabel);
numann=[];
count=1;


tmp=imclose(imlabel>0,strel('disk',10));
tmp=imfill(tmp,'holes');
tmp=bwareaopen(tmp,500);
L=bwlabel(tmp);
for pk=1:max(L(:))
    tmp=double(L==pk);
    a=sum(tmp,1);b=sum(tmp,2);
    rect=[find(a,1,'first') find(a,1,'last') find(b,1,'first') find(b,1,'last')];
    tmp=tmp(rect(3):rect(4),rect(1):rect(2));
    
    % make label bounding box
    tmplabel=imlabel(rect(3):rect(4),rect(1):rect(2)).*tmp;
    
    % make H&E bounding box
    tmp=tmplabel>0;
    %tmpim=im(rect(3):rect(4),rect(1):rect(2),:).*tmp;
    tmpim=im(rect(3):rect(4),rect(1):rect(2),:);
    
    nm=num2str(count,'%05.f');
    imwrite(uint8(tmpim),[pthim,nm,'.tif']);
    imwrite(uint8(tmplabel),[pthlabel,nm,'.tif']);

    for anns=1:numclass
       numann(count,anns)=sum(tmplabel(:)==anns);           
    end
    count=count+1;
end
ctlist0=dir([pthim,'*tif']);
    
bb=1; % indicate that xml file is fully analyzed
if exist('fn','var')
    if exist([outpth,fn],'file')
        save([outpth,fn],'numann','ctlist0','bb','-append');
    else
        save([outpth,fn],'numann','ctlist0','bb');
    end
else
    if exist([outpth,'annotations.mat'],'file')
        save([outpth,'annotations.mat'],'numann','ctlist0','bb','-append');
    else
        save([outpth,'annotations.mat'],'numann','ctlist0','bb');
    end
end