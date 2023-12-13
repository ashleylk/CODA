function build_model_tiles(pthDL,classNames,nblack,sxy,numann0,ctlist,ntrain,nvalidate)
% this function will separately create training and validation tiles for
% construction and optimization of the semantic segmentation model
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

titles=classNames(1:end-1);

%% combine tiles  
numann=numann0;
percann=double(numann0>0);
percann=cat(3,percann,percann);
percann0=percann;
ty='training\';obg=[pthDL,ty,'big_tiles\'];tic;
while length(dir([obg,'HE*jpg']))<ntrain
    [numann,percann]=combine_tiles_density_shuffle(numann0,numann,percann,ctlist,nblack,pthDL,ty,sxy);
    disp([num2str(length(dir([obg,'HE*jpg']))),' images complete in ',num2str(round(toc/60)),' minutes'])
    baseclass1=sum(percann0(:,:,1));usedclass1=sum(percann(:,:,1));
    baseclass2=sum(percann0(:,:,2)==1);usedclass2=sum(percann(:,:,2)==2);
    tmp1=usedclass1./baseclass1*100;
    tmp2=usedclass2./baseclass2*100;
    for b=1:length(titles)
        tt=sprintf(['   used %2.1f%s counts and %2.1f%s unique annotations of ',char(titles(b))],tmp1(b),'%',tmp2(b),'%');
        disp(tt);
    end
end

% make validation tiles
ty='validation\';obg=[pthDL,ty,'big_tiles\'];
numann=numann0;
percann=double(numann0>0);
percann=cat(3,percann,percann);
percann0=percann;tic;
while length(dir([obg,'HE*jpg']))<nvalidate
    [numann,percann]=combine_tiles_density_shuffle(numann0,numann,percann,ctlist,nblack,pthDL,ty,sxy);
    disp([num2str(length(dir([obg,'HE*jpg']))),' images complete in ',num2str(round(toc/60)),' minutes'])
    baseclass1=sum(percann0(:,:,1));usedclass1=sum(percann(:,:,1));
    baseclass2=sum(percann0(:,:,2)==1);usedclass2=sum(percann(:,:,2)==2);
    tmp1=usedclass1./baseclass1*100;
    tmp2=usedclass2./baseclass2*100;
    for b=1:length(titles)
        tt=sprintf(['   used %2.1f%s counts and %2.1f%s unique annotations of ',char(titles(b))],tmp1(b),'%',tmp2(b),'%');
        disp(tt); %#ok<*DSPSP> 
    end
end

