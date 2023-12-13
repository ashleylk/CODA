function im=edit_individual_classes_082(im0,imnm)
    im=im0;
    
    % close fat area
    tmp0=im==4;
    im(im==4)=0;
    tmpk=im~=4 & im~=0;
    tmp=imclose(tmp0,strel('disk',3));
    tmp2=tmp-tmp0;
    tmp=imfill(tmp,'holes');
    tmp=imdilate(tmp,strel('disk',1));
    im(tmp==1)=4;
    im(tmp2==1)=6;
    im(tmpk==1)=im0(tmpk==1);
    clearvars -except im0 im imnm
    
    % close blood vessel area
%     tmp=im==3;
%     im(im==3)=0;
%     tmp=imclose(tmp,strel('disk',1));
%     tmp=bwareaopen(tmp,50); % remove small
%     im(tmp==1)=3;
%     clearvars -except im0 im imnm
%     
    % close duct area
%     tmp0=im==2;
%     im(im==2)=0;
%     tmp=imfill(tmp0,'holes')-tmp0; % find holes
%     tmp=tmp-bwareaopen(tmp,30);   % keep only small holes
%     tmp=bwareaopen(tmp | tmp0,75); % remove small
%     im(tmp==1)=2;
%     clearvars -except im0 im imnm
    
    % close PanIN area
%     tmp0=im==8;
%     im(im==8)=0;
%     tmp=imfill(tmp0,'holes')-tmp0; % find holes
%     tmp=tmp-bwareaopen(tmp,30);   % keep only small holes
%     tmp=bwareaopen(tmp | tmp0,75); % remove small
%     im(tmp==1)=8;
%     clearvars -except im0 im imnm
    
    % remove small white
    tmp=im==7;
    im(tmp==1)=0;
    tmp=bwareaopen(tmp,300);
    im(tmp==1)=7;
    clearvars -except im0 im imnm
    
    imwrite(uint8(im),imnm);
end
