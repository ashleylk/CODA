function Dnew=invert_D(D,skk2)
% inverts the 'D' elastic registration transform for registration of cell coordinates.
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

    if ~exist('skk','var');skk=5;end
    if ~exist('skk2','var');skk2=5;end
    
    % calculate coordinates
    [xx,yy]=meshgrid(1:size(D,2),1:size(D,1));
    xnew=xx+D(:,:,1); % new position of x
    ynew=yy+D(:,:,2); % new position of y
    
    % interpolate D at original position
    D1=D(:,:,1);D2=D(:,:,2);
    D1=D1(:);D2=D2(:);xnew2=xnew(:);ynew2=ynew(:);
    F1=scatteredInterpolant(xnew2(1:skk:end),ynew2(1:skk:end),D1(1:skk:end));
    F2=scatteredInterpolant(xnew2(1:skk:end),ynew2(1:skk:end),D2(1:skk:end));
    
    [xx,yy]=meshgrid(1:skk2:size(D,2),1:skk2:size(D,1));
    D1=-F1(xx,yy);
    D2=-F2(xx,yy);
    Dnew=zeros(size(D));
    Dnew(:,:,1)=imresize(D1,size(D(:,:,1)));
    Dnew(:,:,2)=imresize(D2,size(D(:,:,1)));
    Dnew(isnan(Dnew))=0;
end