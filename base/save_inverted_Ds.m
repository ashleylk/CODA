function save_inverted_Ds(pth)
outpth=[pth,'Dnew\'];
mkdir(outpth);
imlist=dir([pth,'*mat']);


for k=1:length(imlist)
    tic;
    if exist([outpth,imlist(k).name],'file');continue;end
    if contains(imlist(k).name,'CD');continue;end % skip IHC for now
    
    % crop and resize if desired
    load([pth,imlist(k).name],'D');
    rr=round([929 35 2487 2019].*1.5);
    D2=D(rr(2):rr(2)+rr(4),rr(1):rr(1)+rr(3),:);
    Dnew2=invert_D(D2);
    
    % put back in original size and position
    Dnew=zeros(size(D));
    Dnew(rr(2):rr(2)+rr(4),rr(1):rr(1)+rr(3),:)=Dnew2;
    
    save([outpth,imlist(k).name],'Dnew');
    disp([k length(imlist) round(toc/60)]);
    clearvars D Dnew
end