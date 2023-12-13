function [ctlist0,numann0]=load_xml_loop(pth,pthim,WS,umpix,nm,numclass,cmap,classcheck)
% this function loads the xml data from the annotations and generates
% masks, colored masks for validation, and annotation bounding boxes for
% construction of training tiles.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

    cmap2=cat(1,[0 0 0],cmap)/255;
    
    imlist=dir([pth,'*xml']);
    numann0=[];ctlist0=[];
    outim=[pth,'check_annotations\'];mkdir(outim);
    % for each annotation file
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
            load([outpth,'annotations.mat'],'numann','ctlist');
            numann0=cat(1,numann0,numann);
            ctlist0=cat(1,ctlist0,ctlist);
            continue;
        end
        
        % 1 read xml annotation files and saves as mat files
        load_xml_file(outpth,[pth,imnm,'.xml'],date_modified);
        
         % 2 fill annotation outlines and delete unwanted pixels
        try 
            [I0,TA,~]=calculate_tissue_space(pthim,imnm);
        catch
            disp('');disp(['SKIP IMAGE ',imnm]);disp('')
            continue;
        end
        J=fill_annotations_file(I0,outpth,WS,umpix,TA,1); 
        imwrite(uint8(J),[outpth,'view_annotations.tif']);

        % show mask in color:
        I=im2double(I0(1:2:end,1:2:end,:));J=double(J(1:2:end,1:2:end,:));
        J1=cmap2(J+1,1);J1=reshape(J1,size(J));
        J2=cmap2(J+1,2);J2=reshape(J2,size(J));
        J3=cmap2(J+1,3);J3=reshape(J3,size(J));
        mask=cat(3,J1,J2,J3);
        I=(I*0.5)+(mask*0.5);
        imwrite(im2uint8(I),[outim,imnm,'.jpg']);
        clearvars I J J1 J2 J3
        % create annotation bounding boxes
        if exist('classcheck','var')
            [numann,ctlist]=save_annotation_bounding_boxes(I0,outpth,nm,numclass,pthim,imnm,classcheck);
        else
            [numann,ctlist]=save_annotation_bounding_boxes(I0,outpth,nm,numclass);
        end
        numann0=cat(1,numann0,numann);
        ctlist0=cat(1,ctlist0,ctlist);
    
        toc;
    end

end