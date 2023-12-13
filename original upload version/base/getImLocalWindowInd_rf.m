function ind=getImLocalWindowInd_rf(xy,imsz,wndra,skipstep)
% convert the locations in images to indice matrice of regional windows.
% Input : xy; n by 2 vectors of centroid location
%           imsz: 1 by 2 vector represent image size (i.e. =size(image))
%           wndra: local window size (in radius)
% output: n by wndra*2+1 indices matrices ; each row represent the local
% windwos
%  
% to use: linearize pixel intensity of given locations and window size can be obtinaed by 
%         image(ind)
% 
% 05/17/2018 developed by P-H Wu. at JHU.
% 

% identify the location that are within the range of image

    ccx= xy(:,1)<imsz(2)-wndra-1 & xy(:,1)> wndra+1;
    ccy= xy(:,2)<imsz(1)-wndra-1 & xy(:,2)> wndra+1;
    cc=ccx & ccy;

    xmin=xy(:,1)-wndra;
    ymin=xy(:,2)-wndra;
    % account for negative indices
%     ymin(ymin<1)=-ymin(ymin<1)+1;
%     xmin(xmin<1)=-xmin(xmin<1)+1;
%     ymin(ymin<1)=1;
%     xmin(xmin<1)=1;

%     ymin(ymin>imsz(1))=2*imsz(1)-ymin(ymin>imsz(1));
%     xmin(xmin>imsz(2))=2*imsz(2)-xmin(xmin>imsz(2));
    
    indmin=sub2ind(imsz,ymin,xmin);
    indmax=imsz(1)*imsz(2);
    
if length(skipstep)==1    % if its a value
    [gx,gy]=meshgrid([0:skipstep:2*wndra]*imsz(1),0:skipstep:2*wndra);
    
else % when skipstep is a vector
    gx0=[0:1:2*wndra]*imsz(1);
    gy0=[0:1:2*wndra];
    gx0=gx0(skipstep);
    gy0=gy0(skipstep);
   [gx,gy]=meshgrid(gx0,gy0);       
end
    gxy=gx+gy;
    gxy=gxy(:)';
    ind=indmin+gxy(:)';
%     ind(ind>indmax)=1;
%     ind(ind<1)=1;
    %ind(~cc,:)=0;
end
