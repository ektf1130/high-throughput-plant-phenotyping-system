%% [ Test ] %%
% [ Test Parameters ] %
trainingResultPath = './trainingResult/';
%testDatasetPath = uigetdir('./','Please select root folder');
testDatasetPath = './test_data_6pm_v2/*.bmp';
testResultPath = './testImageResult/';

% Parameters of SLIC superpixel segmentation algorithm
% regionSize is the starting size of the superpixels
% regularizer is the the trades-off appearance for spatial regularity when clustering
% (a larger value results in more spatial regularization)
regionSize = 9;
regularizer = 1000;

%%
load([trainingResultPath 'training_slicParameters.mat']);
load([trainingResultPath 'training_rf.mat']);
run('vlfeat/vlfeat-0.9.20/toolbox/vl_setup');

testimage_listing=subdir(testDatasetPath);

%testimage_listing = dir([testDatasetPath '*.png']);
numTestImages = size(testimage_listing,1);
%test_superpixelData = cell(numTestImages,2);


for img_index=1:1:numTestImages
    %% Plant segmentation
    [testPlantName,extension] = strtok(testimage_listing(img_index).name,'.'); 
    testPlantName=strsplit(testPlantName,'/'); % '\' for windows users
    testPlantName=testPlantName(length(testPlantName));
    
    I_test = imread(testimage_listing(img_index).name);
    [rows,cols,channels] = size(I_test);
    
    colorTransform = makecform('srgb2lab');
    imlab_test = applycform(I_test,colorTransform);
    
    
    
    % Superpixel segmentation(SLIC)
    segments_test = vl_slic(im2single(double(imlab_test)),regionSize,regularizer);
    segments_test = segments_test + uint32(ones(rows,cols));
    
    segments_test_no_separate = uint32(zeros(rows,cols));
    superpixel_labeling = 0;
    for i=1:max(max(segments_test))
        labelMask = uint8(segments_test(:,:) == i);
        [connectedCompLabel,connectedCompNum] = bwlabel(logical(labelMask),8);
        
        if connectedCompNum ~= 1
            for j=1:connectedCompNum
                component = (connectedCompLabel(:,:) == j);
                
                superpixel_labeling = superpixel_labeling+1;
                segments_test_no_separate = segments_test_no_separate + uint32(component.*superpixel_labeling);
            end
        else
            superpixel_labeling = superpixel_labeling+1;
            segments_test_no_separate = segments_test_no_separate + uint32(connectedCompLabel.*superpixel_labeling);
        end
    end
    segments_test = segments_test_no_separate;
    clear superpixel_labeling;
    
    contourImg_test = draw_contours(segments_test,I_test); % Draw the contours of superpixels
    
    if ~isdir([testimage_listing(img_index).folder '/superpixel_images']) % '\superpixel_images' for windows users
        mkdir([testimage_listing(img_index).folder '/superpixel_images'])
    end
    
    
    imwrite(contourImg_test,[testimage_listing(img_index).folder '/superpixel_images/' ... 
        testPlantName{1} '_superpixelImg' extension]);
    
    minLabel = min(min(segments_test));
    maxLabel = max(max(segments_test));
    numSuperpixels_test = maxLabel-minLabel+1;
    superpixelSize_test = double(zeros(numSuperpixels_test,1));
    
    superpixelColor_test = double(zeros(numSuperpixels_test,channels)); % Color average
    superpixelCenterPoints_test = double(zeros(numSuperpixels_test,2)); % Center points
    
    for k = minLabel:maxLabel
        labelMask = uint8(segments_test(:,:) == k);
        numPixels = sum(sum(labelMask));
        superpixelSize_test(k,1) = numPixels;
        superpixel_loc = find(labelMask);
        
        % Lab color feature
        l = imlab_test(:,:,1);
        valueL = l(superpixel_loc);
        superpixelColor_test(k,1) = mean(valueL);
        
        a = imlab_test(:,:,2);
        valueA = a(superpixel_loc);
        superpixelColor_test(k,2) = mean(valueA);
        
        b = imlab_test(:,:,3);
        valueB = b(superpixel_loc);
        superpixelColor_test(k,3) = mean(valueB);
        
        [x,y] = find(labelMask == 1);
        superpixelCenterPoints_test(k,1) = mean(x);
        superpixelCenterPoints_test(k,2) = mean(y);
    end
    superpixelFeatures_test = superpixelColor_test;
    
    % Random Forest (RF) classification
    [group,~] = predict(RFModel,superpixelFeatures_test);
    group = uint8(str2num(cell2mat(group)));
    
    
    rfFgbgBinaryImg_test = uint8(zeros(rows,cols));
    for k = minLabel:maxLabel
        if group(k,1) == 1
            labelMask = uint8(segments_test(:,:) == k);
            rfFgbgBinaryImg_test = rfFgbgBinaryImg_test + labelMask;
        end
    end
    
    [connectedCompLabel_rfFgbgBinaryImg_test,connectedCompNum_rfFgbgBinaryImg_test] = bwlabel(logical(rfFgbgBinaryImg_test),8);
    if connectedCompNum_rfFgbgBinaryImg_test > 1 % Delete a foreground region on the border of image
        for component_number = 1:connectedCompNum_rfFgbgBinaryImg_test
            labelMask = uint8(connectedCompLabel_rfFgbgBinaryImg_test(:,:) == component_number);
            [component_rows,component_cols] = find(labelMask);
            
            if (min(component_rows) == 1) || (max(component_rows) == rows) || ...
                    (min(component_cols) == 1) || (max(component_cols) == cols)
                connectedCompSuperpixels = uint32(labelMask) .* segments_test;
                connectedCompSuperpixelList = unique(connectedCompSuperpixels);
                connectedCompSuperpixelList = connectedCompSuperpixelList(connectedCompSuperpixelList>0);
                for k=1:size(connectedCompSuperpixelList,1)
                    superpixel_number = connectedCompSuperpixelList(k,1);
                    group(superpixel_number,1) = 0;
                end
                
                rfFgbgBinaryImg_test = rfFgbgBinaryImg_test-labelMask;
            end
        end
    end
    
    rfForegroundImg_test = uint8(zeros(rows,cols,channels));
    for k = minLabel:maxLabel
        if group(k,1) == 1
            labelMask = uint8(segments_test(:,:) == k);
            
            rfForegroundImg_test(:,:,1) = rfForegroundImg_test(:,:,1) + (I_test(:,:,1).*labelMask);
            rfForegroundImg_test(:,:,2) = rfForegroundImg_test(:,:,2) + (I_test(:,:,2).*labelMask);
            rfForegroundImg_test(:,:,3) = rfForegroundImg_test(:,:,3) + (I_test(:,:,3).*labelMask);
        end
    end
     if ~isdir([testimage_listing(img_index).folder '/bw_images']) % '/bw_images' for windows users
        mkdir([testimage_listing(img_index).folder '/bw_images'])
     end
     
    if ~isdir([testimage_listing(img_index).folder '/segmentation_images']) % '/segmentation_images' for windows users
        mkdir([testimage_listing(img_index).folder '/segmentation_images'])
    end
    
    imwrite(mat2gray(rfFgbgBinaryImg_test),[testimage_listing(img_index).folder '/bw_images/' ... 
        testPlantName{1} '_bwImg' extension]);
    imwrite(rfForegroundImg_test,[testimage_listing(img_index).folder '/segmentation_images/' ... 
        testPlantName{1} '_segmentationImg' extension]);
        
   
end

disp('Done segmentation');