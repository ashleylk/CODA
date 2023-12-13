function [TA,fillval]=find_tissue_area(im0,IHC)
% calculates the tissue space of histological images for use in a nonlinear image registration algorithm
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('IHC','var');IHC=0;end

    %im=double(im0);

    im=double(im0);
    img=rgb2gray(im0);
    img=img==255 | img==0;
    im(cat(3,img,img,img))=NaN;
    fillval=squeeze(mode(mode(im,2),1))';
    ima=im(:,:,1);imb=im(:,:,2);imc=im(:,:,3);
    ima(img)=fillval(1);imb(img)=fillval(2);imc(img)=fillval(3);
    im=cat(3,ima,imb,imc);
    
    if IHC
        aa=mean2(im(:,:,2));
        if aa<210;HE=1;else;HE=0;end
    else
        HE=1;
    end

    if HE % H&E image
       % remove objects with very small standard deviations
        disp('H&E image')
        TA=im-permute(fillval,[1 3 2]);
        TA=mean(abs(TA),3)>10;
        if size(im0,3)==3
            black_line=imclose(std(im,[],3)<5 & rgb2gray(im0)<160,strel('disk',2));
            TA=TA & ~black_line;
        end
    else % IHC image
        disp('IHC image')
%         TA=im-permute(fillval,[1 3 2]);
%         TA=mean(abs(TA),3)>2;
%         TA=imclose(TA,strel('disk',4));
%         TA=imfill(TA,'holes');

        a=mode(im(:));
        TA=abs(mean(im,3)-double(a))>10;
        TA=imclose(TA,strel('disk',8));
        TA=imfill(TA,'holes');
        TA=bwareafilt(TA,1);
    end

    %TA=imdilate(TA,strel('disk',4));
    TA=imclose(TA,strel('disk',2));
    TA=bwlabel(TA);
    
    % remove objects that are less than 1/10 largest object size
    N=histcounts(TA(:),max(TA(:))+1);
    N(1)=0;
    N(N<(max(N)/20))=0;
    N(N>0)=1;
    TA=N(TA+1); 

    D=(sum(TA(:))/numel(TA));
    if D<0.05
        TA=fix_TA(im,fillval);
    end
    %figure(8),imagesc(TA)

end

function TA=fix_TA(im,fillval)
    TA=im-permute(fillval,[1 3 2]);
    TA=mean(TA,3)<-20;
    TA=imdilate(TA,strel('disk',4));
    TA=imclose(TA,strel('disk',6));
    TA=bwlabel(TA);

    % remove objects that are less than 1/10 largest object size
    N=histcounts(TA(:),max(TA(:))+1);
    N(1)=0;
    N(N<(max(N)/10))=0;
    N(N>0)=1;
    TA=N(TA+1); 

end