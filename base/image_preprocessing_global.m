function [arf,amv,sz,cent]=image_preprocessing_global(immv,imrf,rf,cropim)
    if ~isa(imrf,'uint8')
        imrf=im2uint8(imrf);
        immv=im2uint8(immv);
    end

    % complement images
    if size(imrf,3)==3
        mvn=im2double(immv);
        rfn=im2double(imrf);
        mvn=std(mvn,[],3)>0.03;
        rfn=std(rfn,[],3)>0.03;
        
        arf=imcomplement(rgb2gray(imrf));arf(rfn==0)=mode(arf(:));
        amv=imcomplement(rgb2gray(immv));amv(mvn==0)=mode(amv(:));
    else
        arf=imcomplement(imrf);
        amv=imcomplement(immv);
    end
    
    if cropim && size(imrf,3)~=3
        % crop tissue from slide
        amvsz=imgradient(im2double(amv));
        amvsz=imfilter(amvsz,fspecial('gauss',15,11),'replicate');
        amvsz=imbinarize(amvsz);
        amvsz=imopen(amvsz,strel('disk',5));
        amvsz=imclose(amvsz,strel('disk',10));
        amvsz=bwareafilt(amvsz,1,'largest');
        statsmv = regionprops(amvsz,'BoundingBox');

        arfsz=imgradient(im2double(arf));
        arfsz=imfilter(arfsz,fspecial('gauss',15,11),'replicate');
        arfsz=imbinarize(arfsz);
        arfsz=imopen(arfsz,strel('disk',5));
        arfsz=imclose(arfsz,strel('disk',10));
        arfsz=bwareafilt(arfsz,1,'largest');
        statsrf = regionprops(arfsz,'BoundingBox');

        % full sized crop
        Bmv=round(statsmv.BoundingBox*rf);
        Brf=round(statsrf.BoundingBox*rf);
        Bmv(3:4)=[min([Bmv(3) Brf(3)]) min([Bmv(4) Brf(4)])];
        Brf(3:4)=[min([Bmv(3) Brf(3)]) min([Bmv(4) Brf(4)])];
        cent=round([Bmv(1)+Bmv(3)/2 Bmv(2)+Bmv(4)/2]);
        sz=Brf(1:2)-Bmv(1:2);

        % smaller crop
        Bmv=round(Bmv/rf);
        Brf=round(Brf/rf);
        amv=imfilter(amv,fspecial('gauss',21,11),'replicate');
        arf=imfilter(arf,fspecial('gauss',21,11),'replicate');
        arf=imcrop(arf,Brf);
        amv=imcrop(amv,Bmv);
        
        % resize images
        amv=imresize(amv,1/rf,'nearest');
        arf=imresize(arf,1/rf,'nearest');

%         figure(3)
%             subplot(1,2,1),imagesc(amv),axis equal, axis off
%             subplot(1,2,2),imagesc(arf),axis equal, axis off
    else
        % remove noise
        modeimr=mode(arf(:));
        modeimv=mode(amv(:));
        % resize images
        amv=imresize(amv,1/rf,'nearest');
        arf=imresize(arf,1/rf,'nearest');
        if size(immv,3)==3
            im2=amv>(modeimv+20); % delete small objects in image
            im2=imdilate(im2,strel('disk',1));
            im2=bwlabel(im2);
            N=histcounts(im2(:),max(im2(:))+1);
            N(1)=0;
            N(N<(max(N)/10))=0;
            N(N>0)=1;
            im2=N(im2+1);
            amv(~im2)=modeimv;

            im2=arf>(modeimr+20);
            im2=imdilate(im2,strel('disk',1));
            im2=bwlabel(im2);
            N=histcounts(im2(:),max(im2(:))+1);
            N(1)=0;
            N(N<(max(N)/10))=0;
            N(N>0)=1;
            im2=N(im2+1);
            arf(~im2)=modeimr;
        end
        sz=[0 0];
        cent=[0 0];
    end
    
    amv=imgaussfilt(amv,2);
    arf=imgaussfilt(arf,2);
end