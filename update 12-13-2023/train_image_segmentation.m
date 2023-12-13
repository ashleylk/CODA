% this script will train a resnet50 semantic segmentation model using DeepLab
% from annotations of structures made in aperio imagescope and saved in xml format
% VARIABLES YOU NEED TO DEFINE IN THIS SECTION:
% 1.  pth: a folder containing the xml files with annotations for model training
% 2.  pthtest: a folder containing the xml files for model testing
% 3.  pthim: a folder containing tif images at the same resolution or downsampled from the images annotated in imagescope in pth
% 4.  pthtestim: a folder containing tif images at the same resolution or downsampled from the images annotated in imagescope in pthtest
% 5.  pthclassify: a folder containing images you want the model to classify after training
% 6.  umpix: downsample factor from annotated images to tif images in pthim and pthimtest
%         example: annotated images in 20x, classify images in 10x. umpix=2
% 7.  nm: character array with the date this model is built (update for each iteration)
% 8.  sxy: size of image tiles seen by the model 
% 9.  ntrain: number of large images to make for training 
%         (each is cut into several smaller tiles, a good number is 5-20, depending on the number of annotations you have)
% 10. nvalidate: number of large images to make for validation 
%         a good number is ~1/4 the number of training tiles  
% 11. WS: contains information on how to manage the annotation layers inside the xml files. 
%     NOTE: annotions made in imagescope MUST be in the same order for all training and testing images
%     WS is made from 4 separate variables:
%      1. annotation_whitespace: 1xN list for N annotation layers in imagescope
%           0 indicates whitespace (ws) should be removed
%           1 indicates only ws should be kept, 
%           2 indicates keep ws and non-ws
%           example: annotation_whitespace=[0 1 2 0]; 
%             remove ws in annotation layer 1
%             keep only ws in annotation layer 2
%             keep both ws and non-ws in annotation layer 3
%             remove ws in annotation layer 1
%      2. add_whitespace_to: 1x2 list
%           first number indicates the class number to add ws to when it is removed from annotations
%           second number indicates the class number to add non-ws
%           example: add_whitespace=[3 2]
%             when ws is removed from classes 1 and 4 (as indicated by annotation_whitespace), add that ws to class 3
%             when tissue is removed from class 2 (as indicated by annotation_whitespace) add it to class 2
%      3. nesting_order: 1xN list
%           list indicating dominant class when overlapping annotations
%           were made in imagescope. numbers to the left are 'behind' classes to the right
%           example: nesting_order=[4 2 1 3]
%             layer 4 is on bottom. any other annotation layer that overlaps with layer 4 is dominant
%             layer 2 is on top of layer 4, but behind all other classes
%             layer 1 is on top of layers 4 and 2, but underneath layer 3
%             layer 3 is the dominant class. any pixels with overlapping annotations of class 3 with something else are given to class 3
%      4. combine_classes: 1xN list for N annotation layers in imagescope
%           list with new class number for each annotation in imagescope,
%           combine annotation classes by giving them the same number
%           example: combine_classes=[1 2 3 1]
%             annotation layer 1 is class 1
%             annotation layer 2 is class 2
%             annotation layer 3 is class 3
%             annotation layer 4 merges with class 1. the model will only have 3 classes
% 11. classNames: Mx1 string array containing the names of the finalclasses - CANNOT CONTAIN SPACES, USE '_'
%       example: classNames=["blood_vessels" "epithelium" "nontissue"];
% 12. cmap: Mx3 matrix for a model with M classes. each row contains an RGB triplet [0 255] of the desired color for that class in the final model
%       example: cmap=[255 000 000;  % class 1 = red
%                      000 000 255;  % class 2 = blue
%                      000 255 000]; % class 3 = green
% Written in 2020 by Ashley Lynn Kiemen, Johns Hopkins University
% please cite Kiemen et al, Nature methods (2022)
% last updated in December 2023 by ALK

% find base functions
path(path,'segmentation base functions');
warning ('off','all');

% folder containing xml files of annotations made in imagescope
pth='\\user\blahblah\model_annotations\training data\';
% folder containing annotations for model testing
pthtest='\\user\blahblah\model_annotations\testing data\';
% folder containing tif images to train the model on
pthim='\\user\blahblah\model_annotations\training data\10x\';
% folder containing tif images corresponding to xml files in pthtest
pthtestim='\\user\blahblah\model_annotations\testing data\10x\';
% folder containing images to classify with trained model
pthclassify='\\user\blahblah\tif_images_to_classify\';
% downsample factor of tif images from annotated images
umpix=1;

% date of model training
nm='12_04_2022';
% pixel size of square tiles the model trains on
sxy=700;
% number of large training tiles to make
ntrain=15;

% define actions to take per annotation class
annotation_whitespace=[0 1 2 0];
add_whitespace_to=[3 1];
nesting_order=[4 2 1 3]; 
combine_classes=[1 2 3 1];
WS={annotation_whitespace,add_whitespace_to,nesting_order,combine_classes};

% name for each class in the model
classNames = ["type_1" "type_2" "type_3"];
% RGB triplet for each class in the model [0 255]
cmap=[121 248 252;... % 1 type_1
    80 237 80;...     % 2 type_2
    240 159 10];      % 3 type_3

% don't change these:
numclass=max(WS{3});
nblack=numclass+1;
nwhite=WS{3};nwhite=nwhite(WS{2});nwhite=nwhite(1);
classNames=[classNames "black"];
pthDL=[pth,nm,'\'];
if pth(end)~='\';pth=[pth,'\'];end
if pthim(end)~='\';pthim=[pthim,'\'];end
% number of large validation tiles to make
nvalidate=max([round(ntrain/5) 1]);

%% 2 load and format annotations for each image
[ctlist,numann0]=load_xml_loop(pth,pthim,WS,umpix,nm,numclass,cmap);

%% make training tiles for model
build_model_tiles(pthDL,classNames,nblack,sxy,numann0,ctlist,ntrain,nvalidate)

%% build model
train_deeplab(pthDL,1:numclass+1,sxy,classNames);

%% test model
load_xml_loop(pthtest,pthtestim,WS,umpix,nm,numclass,cmap);

% make confusion matrix using testing data
pthtestdata=[pthtest,'data\'];
deeplab_classification(pthtestim,pthDL,sxy,nm,cmap,nblack,nwhite);
pthclassifytest=[pthtestim,'classification_',nm,'\'];
test_model_performance(pthclassifytest,pthtestdata,nwhite,nblack,classNames);

%% classify new images using trained model

deeplab_classification(pthclassify,pthDL,sxy,nm,cmap,nblack,nwhite);

