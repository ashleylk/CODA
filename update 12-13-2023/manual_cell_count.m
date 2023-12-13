function manual_cell_count(pth)
% reads all tif images in pth and allows manual annotation of images
% saves annotation locations to datafile
% REQUIRED INPUT: 
% pth: character string of path to images (remember backslash at the end of the path
% NOTES: zoom and toggle to desired location 
%   1. press space to start annotating
%   2. click or press space to annotate a coordinate
%   3. press 'z' to change zoom or field of view
%   4. press space to return to annotating
% Written in 2019 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if pth(end)~='\';pth=[pth,'\'];end
outpth=[pth,'manual detection\'];
if ~isfolder(outpth);mkdir(outpth);end

%close all
imlist=dir([pth,'*tif']);
warning('off','all')

count=1;
for kk=1:length(imlist)
    % load and display image
    nm=imlist(kk).name(1:end-4);
    im=imread([pth,nm,'.tif']);
    h=figure(22);title(nm);imshow(im);hold on
    answer='';
    
    % load previous data if it exists
    datafile=[nm,'.mat'];
    if exist([outpth,datafile],'file');load([outpth,datafile],'xym');else;xym=[];end

    % if the image's datafile is not empty, add previous annotations 
    if ~isempty(xym)
        scatter(xym(:,1),xym(:,2),'*c')        
        answer = questdlg('Is this image finished?','Annotation Window','Yes','No','No');
        switch answer
            case 'No'
                disp('Click to annotate.  Press enter or z to change zoom or end')
            case 'Yes'
                close(h);
                continue;
        end
    end
    
    
    % While annotations are not finished 
    while ~contains(answer,'Next image')
        tt=get(gcf, 'CurrentCharacter');
        if isempty(xym) || isempty(tt) || tt=='z'
            answer = questdlg('Change zoom or end annotation?','Annotation prompt','Zoom','Next image','Quit','Zoom');
            switch answer
                case 'Zoom'
                    zoom on;
                    disp('Press spacebar to return to annotation')
                    waitfor(gcf,'CurrentCharacter',' ');clc
                    disp('click to annotate.  Press z to change zoom or end')
                    zoom off
                case 'Next image'
                    close all;
                    save_annotations(xym,[outpth,datafile]);clc
                case 'Quit'
                   close all;
                   save_annotations(xym,[outpth,datafile])
                   return;
            end
        end

        if ~contains(answer,'Next image')
            [x,y]=ginput(1);
            if get(gcf, 'CurrentCharacter')~='z'
                scatter(x,y,'*c')
                xym=[xym; round([x y])];
                if rem(count,50)==0;disp('saving progress ..');save_annotations(xym,[outpth,datafile]);end
                count=count+1;
            end
        end
    end
end

% turn warnings back on for future code
warning('on','all')

end

function save_annotations(xym,outfile)
   if exist(outfile,'file')
       save(outfile,'xym','-append');
   else
       save(outfile,'xym');
   end
end
