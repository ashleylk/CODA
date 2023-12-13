function J=fill_annotations_file(I,outpth,WS,umpix,TA,kpb)
% this function will take coordinates of annotations and convert them into
% a mask, using layering and whitespace decisions defined in WS
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if ~exist('kpb','var');kpb=0;end
disp('  2. of 3. interpolating and filling annotated regions')
% indices=[layer# annotation# x y]
num=length(WS{1});

load([outpth,'annotations.mat'],'xyout');
if ~isempty(xyout)
    xyout(:,3:4)=round(xyout(:,3:4)/umpix); % indices are already at desired resolution
    
    % find areas of image containing tissue
    TA=TA>0; % remove small background
    TA=bwareaopen(TA,30);
    TA=~TA;

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
    %figure,imshowpair(J,I);
    imwrite(uint8(J),[outpth,'view_annotations_raw.tif']);
else
    J=zeros(size(I(:,:,1)));
end


end

function [J,ind]=format_white(J0,Ig,WS,szz)
    p=1;            % image number I think
    ws=WS{1};       % defines keep or delete whitespace
    wsa0=WS{2};     % defines non-tissue label
    wsa=wsa0(1);
    try wsfat=wsa0(2);catch;wsfat=0;end
    wsorder=WS{3};  % gives order of annotations
    wsnew=WS{4};    % redefines CNN label names
    
    Jws=zeros(szz);
    ind=[];
   % remove white pixels from annotations areas
    for k=wsorder
        try ii=J0{k};catch;continue;end
        iiNW=setdiff(ii,Ig);   % indices that are not white
        iiW=intersect(ii,Ig);   % indices that are white
        if ws(k)==0     % remove whitespace and add to wsa
           Jws(iiNW)=k;
           Jws(iiW)=wsa;
        elseif ws(k)==1 % keep only whitespace
           Jws(iiW)=k;
           Jws(iiNW)=wsfat;
        elseif ws(k)==2 % keep both whitespace and non whitespace
           Jws(iiNW)=k;
           Jws(iiW)=k;
        elseif ws(k)>10
            Jws(iiW)=k;
            Jws(iiNW)=ws(k)-10;
        end
    end

    % remove small objects and redefine labels (combine labels if desired)
    J=zeros(szz);
    for k=1:max(Jws(:))
        tmp=Jws==k;
        ii=find(tmp==1);
        J(tmp)=wsnew(k);
        P=[ones([length(ii) 2]).*[p wsnew(k)] ii];
        ind=cat(1,ind,P);
    end
end
