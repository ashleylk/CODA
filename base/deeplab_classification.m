function deeplab_classification(pth5x,pthDL,sxy,nm,cmap,nblack,nwhite,col,outpth)
if ~exist('col','var');col=0;end


load([pthDL,'net.mat'],'net');
if exist('outpth','var')
    outpth=[outpth,'classification_',nm,'\'];
else
    outpth=[pth5x,'classification_',nm,'\'];
end

mkdir(outpth);

b=100;
imlist=dir([pth5x,'*tif']);
if isempty(imlist);imlist=dir([pth5x,'*jp2']);end
if isempty(imlist);imlist=dir([pth5x,'*jpg']);end

x=tic;

for kk=1:length(imlist)
    tic;
    if exist([outpth,imlist(kk).name(1:end-3),'tif'],'file');continue;end
    disp(imlist(kk).name)
    
    im=imread([pth5x,imlist(kk).name]);
    try
        TA=imread([pth5x,'TA\',imlist(kk).name(1:end-3),'tif']);
    catch
        TA=rgb2gray(im)<220;
        imfill(TA,'holes');
    end
    
    % pad image so we classify all the way to the edge
    im=padarray(im,[sxy+b sxy+b],0,'both');
    TA=padarray(TA,[sxy+b sxy+b],1,'both');
    
    imclassify=zeros(size(TA));
    sz=size(im);
    for s1=1:sxy-b*2:sz(1)-sxy
        for s2=1:sxy-b*2:sz(2)-sxy
            tileHE=im(s1:s1+sxy-1,s2:s2+sxy-1,:);
            tileTA=TA(s1:s1+sxy-1,s2:s2+sxy-1,:);
            if sum(tileTA(:))<100
                tileclassify=zeros(size(tileTA));
            else
                tileclassify=semanticseg(tileHE,net);
            end
            tileclassify=tileclassify(b+1:end-b,b+1:end-b,:);
            imclassify(s1+b:s1+sxy-b-1,s2+b:s2+sxy-b-1)=tileclassify;

%             tileclassify=double(tileclassify);
%             tileclassify(tileclassify==nblack | tileclassify==0)=nwhite;
%             imcolor=uint8(cat(3,am(tileclassify),bm(tileclassify),cm(tileclassify)));
%             tileHE=tileHE(b+1:end-b,b+1:end-b,:);
%             figure(18),
%                 subplot(1,2,1),imshow(tileHE)
%                 subplot(1,2,2),imshow(imcolor)
        end
    end
   
    % remove padding
    im=im(sxy+b+1:end-sxy-b,sxy+b+1:end-sxy-b,:);
    imclassify=imclassify(sxy+b+1:end-sxy-b,sxy+b+1:end-sxy-b,:);
    
    disp([kk length(imlist) round(toc)])
    imclassify(imclassify==nblack | imclassify==0)=nwhite; % make black class and zeros class whitespace
    imwrite(uint8(imclassify),[outpth,imlist(kk).name(1:end-3),'tif']);
    
    if col==1
        outpthcolor=[outpth,'color\'];
        if ~isfolder(outpthcolor);mkdir(outpthcolor);end
        am=cmap(:,1);bm=cmap(:,2);cm=cmap(:,3);
        imcolor=uint8(cat(3,am(imclassify),bm(imclassify),cm(imclassify)));
        imwrite(imcolor,[outpthcolor,imlist(kk).name(1:end-3),'tif']);
    end
%     figure,imshow(imcolor);
%     figure(18),
%         subplot(1,2,1),imshow(uint8(im))
%         subplot(1,2,2),imshow(imcolor)
    
end
disp(['total time: ',num2str(round(toc(x)/60)),' minutes'])