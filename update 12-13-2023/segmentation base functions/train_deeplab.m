function train_deeplab(pth,classes,sz,classNames)
% this function will train the deepLab model
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

if exist([pth,'net.mat'],'file');disp(' model already built');return;end

disp(' normalizing')
nmim='im\'; % nmim='im_blank\';
nmlabel='label\';

pthTrain=[pth,'training\'];
pthVal=[pth,'validation\'];
% pthTest=[pth,'testing\'];

% 1 make training data
TrainHE=[pthTrain,nmim];
Trainlabel=[pthTrain,nmlabel];
imdsTrain = imageDatastore(TrainHE);
pxdsTrain = pixelLabelDatastore(Trainlabel,classNames,classes);
pximdsTrain = pixelLabelImageDatastore(imdsTrain,pxdsTrain); %'DataAugmentation',augmenter);
tbl = countEachLabel(pxdsTrain);

% make validation data
ValHE=[pthVal,nmim];
Vallabel=[pthVal,nmlabel];
imdsVal = imageDatastore(ValHE);
pxdsVal = pixelLabelDatastore(Vallabel,classNames,classes);
pximdsVal = pixelLabelImageDatastore(imdsVal,pxdsVal); %'DataAugmentation',augmenter);

% make testing data
% TestHE=[pthTest,nmim];
% Testlabel=[pthTest,nmlabel];
% imdsTest = imageDatastore(TestHE);
% pxdsTest = pixelLabelDatastore(Testlabel,classNames,classes);
% pximdsTest = pixelLabelImageDatastore(imdsTest,pxdsTest); %'DataAugmentation',augmenter);


% visualize pixel counts by class
% frequency = tbl.PixelCount/sum(tbl.PixelCount);
% figure(132),bar(1:numel(classes),frequency),title('distribution of class labels')
% xticks(1:numel(classes)) 
% xticklabels(tbl.Name)
% xtickangle(45)
% ylabel('Frequency')

disp(' starting training')
options = trainingOptions('adam',...  % stochastic gradient descent solver
    'MaxEpochs',8,...
    'MiniBatchSize',4,... % datapoints per 'mini-batch' - ideally a small power of 2 (32, 64, 128, or 256)
    'Shuffle','every-epoch',...  % reallocate mini-batches each epoch (so min-batches are new mixtures of data)
    'ValidationData',pximdsVal,...
    'ValidationPatience',6,... % stop training when validation data doesn't improve for __ iterations 5
    'InitialLearnRate',0.0005,...  %     'InitialLearnRate',0.0005,...
    'LearnRateSchedule','piecewise',... % drop learning rate during training to prevent overfitting
    'LearnRateDropPeriod',1,... % drop learning rate every _ epochs
    'LearnRateDropFactor',0.75,... % multiply learning rate by this factor to drop it
    'ValidationFrequency',128,... % initial loss should be -ln( 1 / # classes )
    'ExecutionEnvironment','gpu',... % train on gpu
    'Plots','training-progress');%,... % view progress while training
    %'OutputFcn', @(info)savetrainingplot(info,pth)); % save training progress as image

% Design network
numclass = numel(classes);
imageFreq = tbl.PixelCount ./ tbl.ImagePixelCount;
classWeights = median(imageFreq) ./ imageFreq;

lgraph = deeplabv3plusLayers([sz sz 3],numclass,"resnet50");
pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
lgraph = replaceLayer(lgraph,"classification",pxLayer);
% lgraph=make_CNN_layers_deeplab(sz,numclass,tbl,classWeights);

% lgraph = deeplabv3plusLayers([sz sz 3], numclass, "resnet101");
% pxLayer = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
% lgraph = replaceLayer(lgraph,"ClassificationLayer_predictions",pxLayer);

% train
[net, info] = trainNetwork(pximdsTrain,lgraph,options);
save([pth,'net.mat'],'net','info');

% I = readimage(imdsTrain,35);
% L = readimage(pxdsTrain,35);
% figure,
%     subplot(1,2,1),imshow(I)
%     subplot(1,2,2),imagesc(double(L));axis equal;axis off
% test on one image
% I = readimage(imdsTest,35);
% C = semanticseg(I, net);

% cmap=[121 248 252;... % 1 islet
%     0    0    255;... % 2 duct
%     80 237 80;...     % 3 blood vessel
%     255  255  0;...   % 4 fat
%     149 35  184;...   % 5 acinus
%     255 194 245;...   % 6 connective tissue
%     255 255 255;...   % 7 whitespace
%     255  0  0;...     % 8 PanIN
%     255 255 255]/255; % 9 noise 
% 
% B = labeloverlay(I,C,'Colormap',cmap,'Transparency',0.4);
% figure(651),imshow(B)
% make_pixel_colorbar(cmap,classes);
% 
% expectedResult = readimage(pxdsTest,35);
% actual = uint8(C);
% figure(183)
%     subplot(1,2,1),imshow(I)
%     subplot(1,2,2),imagesc(actual),axis equal;axis off


end

function stop=savetrainingplot(info,pthSave)
    stop=false;  %prevents this function from ending trainNetwork prematurely
    if info.State=='done'   %check if all iterations have completed
        exportapp(findall(groot, 'Type', 'Figure'),[pthSave,'training_process.png'])
    end


end
