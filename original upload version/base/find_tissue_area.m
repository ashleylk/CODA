function [TA,fillval]=find_tissue_area(im0,nm)
if ~exist('nm','var');nm='';end
    %fillval=squeeze(mode(mode(im0,2),1))';
    %im=double(im0);
    %if max(fillval)==255
        im=double(im0);
        img=rgb2gray(im0);
        img=img==255 | img==0;
        im(cat(3,img,img,img))=NaN;
        fillval=squeeze(mode(mode(im,2),1))';
        ima=im(:,:,1);imb=im(:,:,2);imc=im(:,:,3);
        ima(img)=fillval(1);imb(img)=fillval(2);imc(img)=fillval(3);
        im=cat(3,ima,imb,imc);
    %end
    if contains(nm,'CD45')
        TA=im-permute(fillval,[1 3 2]);
        TA=mean(abs(TA),3)>2;
    elseif contains(nm,'CD3')
        TA=mean(im,3)<210;%figure(10),imagesc(TA)
    else
        % remove objects with very small standard deviations
        TA=im-permute(fillval,[1 3 2]);
        TA=mean(abs(TA),3)>10;
        if size(im0,3)==3
            black_line=imclose(std(im,[],3)<5 & rgb2gray(im0)<160,strel('disk',2));
            TA=TA & ~black_line;
        end
        %TA=im(:,:,1)<210;
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

        %TA=imfill(TA,'holes');
        D=(sum(TA(:))/numel(TA));
        if D<0.05
            TA=fix_TA(im,fillval);
        end
        %figure(8),imagesc(TA)
        %TA=rgb2gray(im0)<255;
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

    %TA=imfill(TA,'holes');
end