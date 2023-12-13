function test_model_performance(pthdata,pthclassify,nwhite,nblack,titles)
% this function will compare a classified image to manual annotations to
% determine the independent, testing accuracy of the model
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

numclass=nblack-1;

plist=dir(pthdata);
pDL=[];
ptrue=[];
for k=3:length(plist)
    tic;
    pth=[pthdata,plist(k).name,'\'];
    if exist([pth,'view_annotations.tif'],'file') || exist([pth,'view_annotations_raw.tif'],'file')
        try
            J0=double(imread([pth,'view_annotations.tif']));
        catch
            J0=double(imread([pth,'view_annotations_raw.tif']));
        end
        %im=imread([pthim,plist(k).name,'.tif']);
        imDL=imread([pthclassify,plist(k).name,'.tif']);
        
        % remove small pixels
        for b=1:max(J0)
            tmp=J0==b;
            J0(J0==b)=0;
            tmp=bwareaopen(tmp,25);
            J0(tmp==1)=b;
        end
        
        % get true and predicted class at testing annotation locations
        L=find(J0>0);
        ptrue=cat(1,ptrue,J0(L));
        pDL=cat(1,pDL,imDL(L));

    end
    disp([k length(plist) round(toc)])
end
pDL(pDL==nblack)=nwhite;
% fx=ptrue==numclass | pDL==numclass;
% ptrue(fx)=[];pDL(fx)=[];

% normalize to the minimum number of pixels, rounded to neartest 1000
km=min(histcounts(ptrue,numclass));
if km<100
    km=floor(km/10)*10;
elseif km<1000
    km=floor(km/100)*100;
else
    km=floor(km/1000)*1000;
end
ptrue2=[];
pDL2=[];
for k=unique(ptrue)'
    a=find(ptrue==k);
    b=randperm(length(a),km);
    ptrue2=[ptrue2;ptrue(a(b))];
    pDL2=[pDL2;pDL(a(b))];
end

% confusion matrix with equal number of pixels of each class
Dn=zeros([max(ptrue) max(pDL)]);
if length(titles)>size(Dn,1);titles=titles(1:end-1);end
for a=1:max(ptrue2)
    for b=1:max(pDL2)
        tmp1=ptrue2==a;
        tmp2=pDL2==b;
        Dn(a,b)=sum(tmp1 & tmp2);
    end
end
Dn(isnan(Dn))=0;
make_confusion_matrix(Dn,titles)



