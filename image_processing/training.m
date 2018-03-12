%% [ Training ] %%
% [ Training Parameters ] %
clear all;  
close all; 
clc;

trainingDatasetPath = './data/';
trainingResultPath = './trainingResult/';

% Parameters of SLIC superpixel segmentation algorithm
% regionSize is the starting size of the superpixels
% regularizer is the the trades-off appearance for spatial regularity when clustering
% (a larger value results in more spatial regularization)
regionSize = 9;
regularizer = 1000;
n_tree=100;

save([trainingResultPath 'training_slicParameters.mat'],'regionSize','regularizer');

run('vlfeat/vlfeat-0.9.20/toolbox/vl_setup');

trainingimage_listing = dir([trainingDatasetPath '*.png']);
numTrainingImages = size(trainingimage_listing,1)/2;
training_superpixelData = cell(numTrainingImages,2);
data_index = 1;

for img_index=2:2:numTrainingImages*2
    I = imread([trainingDatasetPath trainingimage_listing(img_index-1,1).name]);
    [rows,cols,channels] = size(I);
    
    groundtruth = imread([trainingDatasetPath trainingimage_listing(img_index,1).name]);
    
    colorTransform = makecform('srgb2lab');
    imlab = applycform(I,colorTransform);
    
    segments = vl_slic(im2single(double(imlab)),regionSize,regularizer);
    segments = segments + uint32(ones(rows,cols));
        
    segments_no_separate = uint32(zeros(rows,cols));
    superpixel_labeling = 0;
    for i=1:max(max(segments))
        labelMask = uint8(segments(:,:) == i);
        [connectedCompLabel,connectedCompNum] = bwlabel(logical(labelMask),8);
        
        if connectedCompNum ~= 1
            for j=1:connectedCompNum
                component = (connectedCompLabel(:,:) == j);
                
                superpixel_labeling = superpixel_labeling+1;
                segments_no_separate = segments_no_separate + uint32(component .* superpixel_labeling);
            end
        else
            superpixel_labeling = superpixel_labeling+1;
            segments_no_separate = segments_no_separate + uint32(connectedCompLabel .* superpixel_labeling);
        end
    end
    segments = segments_no_separate;
    clear superpixel_labeling;
    
    minLabel = min(min(segments));
    maxLabel = max(max(segments));
    numSuperpixels_train = maxLabel-minLabel+1;
    
    superpixelColor_train = double(zeros(numSuperpixels_train,channels)); % Color average
        
    for k = minLabel:maxLabel
        labelMask = uint8(segments(:,:) == k);
        superpixel_loc = find(labelMask);
        
        % Lab color feature
        l = imlab(:,:,1);
        valueL = l(superpixel_loc);
        superpixelColor_train(k,1) = mean(valueL);
        
        a = imlab(:,:,2);
        valueA = a(superpixel_loc);
        superpixelColor_train(k,2) = mean(valueA);
        
        b = imlab(:,:,3);
        valueB = b(superpixel_loc);
        superpixelColor_train(k,3) = mean(valueB);
    end
    superpixelFeatures_train = superpixelColor_train;
    
    % Superpixel labeling (foreground/background superpixel)
    backgroundLabel = 0;
    foregroundMask = uint8(groundtruth(:,:) ~= backgroundLabel);
    
    superpixelLabel = zeros(numSuperpixels_train,1);
    for k = minLabel:maxLabel
        labelMask = uint8(segments(:,:) == k);
        numPixels = sum(sum(labelMask));
        
        superpixelLabel(k,1) = sum(sum(labelMask .* foregroundMask)) / numPixels;
        superpixelLabel(k,1) = uint8(round(superpixelLabel(k,1)));
    end
    
    training_superpixelData{data_index,1} = superpixelFeatures_train;
    training_superpixelData{data_index,2} = superpixelLabel;
    data_index = data_index+1;
end
save([trainingResultPath 'training_superpixelData.mat'],'training_superpixelData');

superpixelFeatures_train = [];
superpixelLabel_train = [];
for data_index=1:numTrainingImages
    superpixelFeatures_train = [superpixelFeatures_train;training_superpixelData{data_index,1}];
    superpixelLabel_train = [superpixelLabel_train;training_superpixelData{data_index,2}];
end

% Train Random Forest
%SVMModel = fitcsvm(superpixelFeatures_train,superpixelLabel_train,'KernelFunction','rbf','Standardize',true);
paroptions = statset('UseParallel',true);
RFModel = TreeBagger(n_tree, superpixelFeatures_train, superpixelLabel_train,'Options',paroptions,'OOBPrediction','On');

save([trainingResultPath 'training_rf.mat'],'RFModel');
disp('Training Done');
