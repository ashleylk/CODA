function make_confusion_matrix(D,classNames)
% this function will create a pretty confusion matrix given as input a
% table of numbers and classnames for the rows and columns
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if length(classNames)>size(D,1);classNames=classNames(1:end-1);end

if isempty(D);disp('no testing annotations');return;end

% make D into blue-red heatmap
nn=20;
Dc=round(D/max(D(:))*(nn-1))+1;
Cb=[39 123 227]/255; % blue
Cw=[245 242 237]/255; % white
Cr=[227 57 39]/255; % red
a1=linspace(Cw(1),Cb(1),nn)';
b1=linspace(Cw(2),Cb(2),nn)';
c1=linspace(Cw(3),Cb(3),nn)';
a2=linspace(Cw(1),Cr(1),nn)';
b2=linspace(Cw(2),Cr(2),nn)';
c2=linspace(Cw(3),Cr(3),nn)';
Cb=[a1 b1 c1];

% eye white to blue, non eye is white to red
Deye=(cat(3,a1(Dc),b1(Dc),c1(Dc)));
Dneye=(cat(3,a2(Dc),b2(Dc),c2(Dc)));
DD=Deye.*eye(size(D))+Dneye.*~eye(size(D));

D1=D.*eye(size(D));
D2=sum(D1,1)./sum(D,1)*100;
D3=sum(D1,2)./sum(D,2)*100;
D4=sum(D1(:))/sum(D(:))*100;

% round accuracy to nearest 10th place
D2=round(D2*10)/10;
D3=round(D3*10)/10;
D4=round(D4*10)/10;

% make text and RGB of combined confusion data
D2b=ones(size(D2))*0.9;D3b=ones(size(D3))*0.9;D4b=ones(size(D4))*0.9;
Db=cat(2,cat(1,D,D2),[D3;D4]);
a=DD(:,:,1);a=cat(2,cat(1,a,D2b),[D3b;D4b]);
b=DD(:,:,2);b=cat(2,cat(1,b,D2b),[D3b;D4b]);
c=DD(:,:,3);c=cat(2,cat(1,c,D2b),[D3b;D4b]);
DDb=cat(3,a,b,c);
for b=1:length(classNames);classNames(b)=strrep(classNames(b),'_',' ');end
classnamesA=[classNames "PRECISION"];
classnamesB=[classNames "RECALL"];

Db(isnan(Db))=0;
figure('units','normalized','outerposition',[0 0 1 1]);
    imagesc(DDb);axis equal;
    xlim([0.5 size(Db,1)+0.5]);ylim([0.5 size(Db,1)+0.5]);
    xticks(1:size(Db,1));yticks(1:size(Db,1))
    grid off;hold on;
    add_text(Db);
    xticklabels(classnamesB);yticklabels(classnamesA)
    set(gca,'XAxisLocation','top')
    xlabel('predicted')
    ylabel('ground truth')
    set(gca,'Fontsize',15)


end


function add_text(D)
% make colormap

% Cb=[11, 163, 29]/255; % green
% Cw=[163, 34, 11]/255; % red
% a1=linspace(C1(1),C2(1),5)';
% b1=linspace(C1(2),C2(2),5)';
% c1=linspace(C1(3),C2(3),5)';
% Cb=[a1 b1 c1];
% Cb=cat(1,Cb,Cb(end,:));

Cb=[50, 168, 76;...
    168, 140, 50;...
    168, 121, 50;...
    168, 74, 50;...
    168, 58, 50;...
    168, 58, 50;...
    168, 58, 50;...
    168, 58, 50;...
    168, 58, 50;...
    168, 58, 50]/255;
Cb=Cb(end:-1:1,:);

    for ii = 1:size(D,1)
      for jj = 1:size(D,2)
          nu = D(ii,jj);
          val = num2str(round(nu,2));
          
          % choose fontcolor
          if jj==ii;c='w';else;c='k';end
          if jj==size(D,2) || ii==size(D,1)
               kk=ceil(nu/10);
               if kk==0;kk=1;end
               c=Cb(kk,:);
          end
          
          text(jj,ii,val,'Color',c,'HorizontalAlignment','center','FontSize',12)
      end
    end


end


