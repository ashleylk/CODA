function [xmatch,x1nomatch,x2nomatch,ii]=cell_cell_dist(x10,x20,ct)
% determines matching and non-matching coordinates for 2 sets of xy
% coordinates and a minimum distance (in pixels) for cells to 'match'
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

        if ~exist('ct','var');ct=20;end
        x1=permute(x10,[1 3 2]);
        x2=permute(x20,[3 1 2]);
        x1=double(repmat(x1,[1 size(x2,2) 1]));
        x2=double(repmat(x2,[size(x1,1) 1 1]));
        
        % get index of cell in list 1 closest to cells in list 2
        dist=sqrt(sum((x1-x2).^2,3));
        %[m,dd]=min(dist,[],2);
    
        xmatch=[];
        x2nomatch=[];
        ii=[];
        for bb=1:size(x20,1)
            
            distbb=dist(:,bb);       % distance from cell bb to all cells in other image
            nums=find(distbb==min(distbb),1,'first');  % find closest cell
            
            if distbb(nums)>ct        % no cell within distance of cell we want
                x2nomatch=[x2nomatch;x20(bb,:)];
            elseif isempty(distbb)  
                x2nomatch=[x2nomatch;x20(bb,:)];
            else
                xmatch=[xmatch;x20(bb,:)];
                dist(nums,:)=ct+1;    % make matched cell unavailable 
            end

        end
        m=sum(dist,2);
        mm=(ct+1)*size(dist,2);
        nmatch=find(m~=mm);
        x1nomatch=x10(nmatch,:);

end