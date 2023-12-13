function make_cmap_legend(cmap,titles)
% this function will make you a visual of your deep learning colors 
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

% sample inputs:
% cmap=[240 159 10;     % 1 PDAC 
%     255  0  0;...     % 2 PanIN
%     0    0    255;... % 3 duct
%     121 248 252;...   % 4 islet
%     80 237 80;...     % 5 blood vessel
%     110 90 40;...     % 6 nerve
%     0 0 0;...         % 7 lymph
%     255  255  0;...   % 8 fat
%     149 35  184;...   % 9 acinus
%     255 194 245;...   % 10 connective tissue
%     255 255 255];...  % 11 whitespace
% titles=["PDAC" "PanIN" "duct" "islet" "blood vessel" "nerve" "lymph" "fat" "acinus" "collagen" "whitespace"];
    
im=uint8([]);
for k=1:size(cmap,1)
    tmp=permute(cmap(k,:),[1 3 2]);
    tmp=repmat(tmp,[50 50 1]);
    im=cat(2,im,tmp);
end

for b=1:length(titles);titles(b)=strrep(titles(b),'_',' ');end

if exist('titles','var')
    im=imrotate(im,270);
    figure,imagesc(im)
    axis equal
    xlim([0 size(im,2)]);ylim([0 size(im,1)])
    yticks(15:50:size(im,1))
    set(gca,'TickLength',[0 0])
    xticks([])
    yticklabels(titles)%ytickangle(90)
    set(gca,'fontsize',15);
else
    figure,imshow(im)
end
set(gcf,'color','w');set(gca,'LineWidth',1);

