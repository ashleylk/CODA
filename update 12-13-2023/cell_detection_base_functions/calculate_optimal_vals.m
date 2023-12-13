function [mb,sz,xya,TP,FP,FN]=calculate_optimal_vals(imB,mbs,szs,xym)
% determines optimal minimum brightness and object size to match manual
% coordinates to automatic coordinates
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if length(mbs)>1
    sz=szs;
    vals=zeros([length(mbs) 3]);
    for count=1:length(mbs)
        mb=mbs(count);
        xya=pkfndW(double(imB),mb,sz);
        [xmatch,xaut,xman,~]=cell_cell_dist(xya,xym);

        TP=size(xmatch,1)/size(xym,1);% true positive
        FP=size(xaut,1)/size(xym,1);  % false positive
        FN=size(xman,1)/size(xym,1);  % false negative
        vals(count,:)=[TP FP FN];
    end
    
    % find brightness that maximizes TP and minimizes FP + FN
    vals2=[1-vals(:,1) vals(:,[2 3])];
    vals2=[vals2(:,[2 3]) std(vals2,[],2)/3]; % add a variable for variation between TP, FP, and FN
    vals2=sum(vals2,2);
    ii=find(vals2==min(vals2),1,'first');
    mb=mbs(ii);
    
    % get final output values
    TP=vals(ii,1);
    FP=vals(ii,2);
    FN=vals(ii,3);
    xya=pkfndW(double(imB),mb,sz); 
else
    mb=mbs;
    vals=zeros([length(szs) 3]);
    for count=1:length(szs)
        sz=szs(count);
        xya=pkfndW(double(imB),mb,sz); 
        [xmatch,xaut,xman,~]=cell_cell_dist(xya,xym);

        TP=size(xmatch,1)/size(xym,1);% true positive
        FP=size(xaut,1)/size(xym,1);% false positive
        FN=size(xman,1)/size(xym,1);% false negative
        vals(count,:)=[TP FP FN];
    end
    
    % find brightness that maximizes TP and minimizes FP + FN
    vals2=[1-vals(:,1) vals(:,[2 3])];      % invert true positives
    vals2=[vals2(:,[2 3]) std(vals2,[],2)]; % add a variable for variation between TP, FP, and FN
    vals2=sum(vals2,2);
    ii=find(vals2==min(vals2),1,'first');
    sz=szs(ii);
    
    % get final output values
    TP=vals(ii,1);
    FP=vals(ii,2);
    FN=vals(ii,3);
    xya=pkfndW(double(imB),mb,sz); 
end
