function J=fill_annotations_file(I,outpth,WS,umpix,TA,kpb)
if ~exist('kpb','var');kpb=0;end
if umpix==100;umpix=1;elseif umpix==200;umpix=2;end
disp('  2. of 3. interpolating and filling annotated regions')
% indices=[layer# annotation# x y]
num=length(WS{1});

load([outpth,'annotations.mat'],'xyout');
if ~isempty(xyout)
    xyout(:,3:4)=round(xyout(:,3:4)/umpix); % indices are already at desired resolution
    
    % find areas of image containing tissue
    if ~isempty(TA)
        TA=TA>0; % remove small background
        TA=bwareaopen(TA,300);
        TA=imclose(TA,strel('disk',1));
        TA=~TA;
    else
        I=double(I);
        % low standard deviation
        TA1=std(I(:,:,[1 2]),[],3);
        TA2=std(I(:,:,[1 3]),[],3);
        TA=max(cat(3,TA1,TA2),[],3);
        TAa=TA<10;
        % high green
        TAb=I(:,:,2)>210;
        TA=TAa & TAb;
        TA=bwareaopen(TA,5);
        
    end
    Ig=find(TA);
    szz=size(TA);
    J=cell([1 num]);
    % interpolate annotation points to make closed objects
    for k=unique(xyout(:,1))' % for each annotation type k
        Jtmp=zeros(szz);
        bwtypek=Jtmp;
        cc=xyout(:,1)==k;
        xyz=xyout(cc,:);
        for pp=unique(xyz(:,2))'  % for each individual annotation
            if pp==0
                continue
            end
            cc=find(xyz(:,2)==pp);

            xyv=[xyz(cc,3:4); xyz(cc(1),3:4)];
            dxyv=sqrt(sum((xyv(2:end,:)-xyv(1:end-1,:)).^2,2));

            xyv(dxyv==0,:)=[]; % remove the repeating points
            dxyv(dxyv==0)=[];
            dxyv=[0;dxyv];

            ssd=cumsum(dxyv);
            ss0=1:0.49:ceil(max(ssd)); % increase by <0.5 to avoid rounding gaps
            xnew=interp1(ssd,xyv(:,1),ss0);
            ynew=interp1(ssd,xyv(:,2),ss0);
            xnew=round(xnew);
            ynew=round(ynew);
            try
                indnew=sub2ind(szz,ynew,xnew);
            catch
                disp('annotation out of bounds');
                continue
            end
            indnew(isnan(indnew))=[];
            bwtypek(indnew)=1;
        end
        bwtypek=imfill(bwtypek>0,'holes');
        Jtmp(bwtypek==1)=k;
        if ~kpb;Jtmp(1:401,:)=0;Jtmp(:,1:401)=0;Jtmp(end-401:end,:)=0;Jtmp(:,end-401:end)=0;end
        J{k}=find(Jtmp==k);
    end
    clearvars bwtypek Jtmp xyout xyz

    % format annotations to keep or remove whitespace
    J=format_white(J,Ig,WS,szz);
    figure(93),imshowpair(J,I);
    imwrite(uint8(J),[outpth,'view_annotations_raw.tif']);
else
    J=zeros(size(I(:,:,1)));
end


end

function [J,ind]=format_white(J0,Ig,WS,szz)
    p=1;            % image number I think
    ws=WS{1};       % defines keep or delete whitespace
    wsa=WS{2};      % defines non-tissue label
    wsnew=WS{3};    % redefines CNN label names
    wsorder=WS{4};  % gives order of annotations
    wsdelete=WS{5}; % lists annotations to delete
    
    Jws=zeros(szz);
    ind=[];
   % remove white pixels from annotations areas
    for k=wsorder
        if intersect(wsdelete,k)>0;continue;end % delete unwanted annotation layers
        try ii=J0{k};catch;continue;end
        iiNW=setdiff(ii,Ig);   % indices that are not white
        iiW=intersect(ii,Ig);   % indices that are white
        if ws(k)==0     % remove whitespace and add to wsa
           Jws(iiNW)=k;
           Jws(iiW)=wsa;
        elseif ws(k)==1 % keep only whitespace
           Jws(iiW)=k;
        elseif ws(k)==2 % keep both whitespace and non whitespace
           Jws(iiNW)=k;
           Jws(iiW)=k;
        end
    end

    % remove small objects and redefine labels (combine labels if desired)
    J=zeros(szz);
    for k=1:max(Jws(:))
        if wsnew(k)==wsa;dll=5;else;dll=5;end
        tmp=bwareaopen(Jws==k,dll);
        ii=find(tmp==1);
        J(tmp)=wsnew(k);
        P=[ones([length(ii) 2]).*[p wsnew(k)] ii];
        ind=cat(1,ind,P);
    end
end
