path(path,'base');

warning ('off','all');
pth='\'; % path to annotations
umpix=1; % um/pixel of images used % 1=10x, 2=5x, 4=16x
pthim='\'; % path to tif images to classify
nm='06_17_2022'; % today's date
% classes
% 1  diseased
% 2  non-diseased tissue
% 3  non-tissue
cmap=[192 123 224;...   % 1  diseased
      224 211 123;...   % non-diseased tissue
      255 255 255];     % 3 whtespace
classNames = ["diseased" "nondiseased" "whitespace" "black"];

% define actions to take per annotation class
WS{1}=[];         % remove whitespace if 0, keep only whitespace if 1, keep both if 2
WS{2}=;               % add removed whitespace to this class
WS{3}=[];         % rename classes accoring to this order 
WS{4}=[];         % reverse priority of classes
WS{5}=[];              % delete classes
numclass=length(unique(WS{3}));
sxy=700;
pthDL=[pth,nm,'\'];
nblack=numclass+1;

%% load and format annotations for each image

% for each annotation file
imlist=dir([pth,'*xml']);
numann0=[];ctlist=[];
for kk=1:length(imlist)
    % set up names
    imnm=imlist(kk).name(1:end-4);tic;
    disp(['Image ',num2str(kk),' of ',num2str(length(imlist)),': ',imnm])
    outpth=[pth,'data\',imnm,'\'];
    if ~exist(outpth,'dir');mkdir(outpth);end
    matfile=[outpth,'annotations.mat'];
    
    % skip if file hasn't been updated since last load
    dm='';bb=0;date_modified=imlist(kk).date;
    if exist(matfile,'file');load(matfile,'dm','bb');end
    if contains(dm,date_modified) && bb==1
        disp('  annotation data previously loaded')
        load([outpth,'annotations.mat'],'numann','ctlist0');
        numann0=[numann0;numann];ctlist=[ctlist;ctlist0];
        continue;
    end
    
    % 1 read xml annotation files and saves as mat files
    load_xml_file(outpth,[pth,imnm,'.xml'],date_modified);
    
     % 2 fill annotation outlines and delete unwanted pixels
    [I,TA,pthTA]=calculate_tissue_space_082(pthim,imnm);
    J0=fill_annotations_file(I,outpth,WS,umpix,TA); 
    %J=edit_individual_classes_mouse_gut(J0,[outpth,'view_annotations.tif']);
    %figure,imshowpair(uint8(I),J)
    % 3 make bounding boxes of all annotations
    [numann,ctlist0]=annotation_bounding_boxes(I,outpth,nm,numclass);
    numann0=[numann0;numann];ctlist=[ctlist;ctlist0];
    toc;
end

%% combine tiles  
numann=numann0;
% make training tiles
ty='training\';obg=[pthDL,ty,'big_tiles\'];
while length(dir([obg,'*tif']))<18
    numann=combine_tiles_big(numann0,numann,ctlist,nblack,pthDL,ty,sxy,1);
end
% make validation tiles
ty='validation\';obg=[pthDL,ty,'big_tiles\'];
while length(dir([obg,'*tif']))<4
    numann=combine_tiles_big(numann0,numann,ctlist,nblack,pthDL,ty,sxy,1);
end

%% build model
train_deeplab(pthDL,1:numclass+1,sxy,classNames);

% classify
deeplab_classification(pthim,pthDL,sxy,nm,cmap,nblack,WS{2},1);

