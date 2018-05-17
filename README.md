## Introduction
- An Automated, High-throughput Plant Phenotyping System using Machine Learning-based Plant Segmentation and Image Analysis [[paper]](http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0196615)
## Folder structure
```
├── image_acquisition
│   ├── db_analysis_computer_side.py
│   ├── raspberry_side.py
│   └── sync.sh 	# data synchronization between a db_analysis_computer and a raspberry pi
├── image_processing
│   ├── analysisResult 	# result images after execution ('visualization.m')
│   │   └── README.md
│   ├── raw_data 		# raw tray images
│   │   └── README.md
│   ├── test_data		# preprocessed images after execution('preprocessing.py')
│   │   └── README.md
│   ├── train_data 		# ground truth images for training ('training.m')
│   │   └── README.md
│   ├── trainingResult
│   │   ├── training_rf.mat 	# random forest model after execution ('training.m')
│   │   ├── training_slicParameters.mat	
│   │   └── training_superpixelData.mat
│   ├── vlfeat 				# libraries for generating superpixels
│   ├── draw_contours.m 	# function of draw superpixel using contours
│   ├── preprocessing.py 	# distortion correction, cropping, arrangement
│   ├── subdir.m 			# function of file searching recursively
│   ├── test.m 				# segmentation and data processing
│   ├── training.m 			# generating a classification model
│   └── visualization.m 	# visualization using segmented images
└── README.md
```
## Development environment
- Image acquisition
	- pyserial 3.4
- Preprocessing
	- Python 2.7
	- OpenCV 3.1.0 (python)
	- Numpy 1.11.3
	- imutils 0.4.5
- Training, segmentation, visualization
	- Matlab R2016b (9.1)
	- VLFeat -- Vision Lab Features Library 0.9.20


## Usage
### Training
```
1. Check 'trainingDatasetPath'(Default : ./train_data)
2. Check 'trainingResultPath'(Default : ./trainingResult)
3. Execute 'training.m' 
```

### Preprocessing, Test, Visualzation
```
1. Check raw image source directory --> 'path'(Default : ./raw_data) in 'preprocessing.py'
2. Check processed image destination directory --> 'newpath'(Default : ./test_data) in 'preprocessing.py'
3. Execute python code
4. Check test images directory path --> 'testDatasetPath'(Default : ./test_data/*.bmp) in 'test.m'
5. Excecute test.m code
6. Check binary, segmentation, result directory path --> testBWPath(Default:./test_data/*_bwImg.bmp), testSegmentationPath(Default: ./test_data/*_segmentationImg.bmp), analysisResultPath(Default:./analysisResult) in 'visualization.m'
7. Execute 'visualization.m' 
8. Check results in 'analysisResult' folder 
```



## Download data
- Ground truth data
	- https://github.com/ektf1130/high-throughput-plant-phenotyping-system/tree/master/image_processing/train_data
- Raw tray images
	- https://github.com/ektf1130/high-throughput-plant-phenotyping-system/tree/master/image_processing/raw_data
- Preprocessed images
	- https://github.com/ektf1130/high-throughput-plant-phenotyping-system/tree/master/image_processing/test_data
- Visualzaion results
	- https://github.com/ektf1130/high-throughput-plant-phenotyping-system/tree/master/image_processing/analysisResult
	
- All-in-one (code + data + results)
	- https://drive.google.com/open?id=1MaG_1kekDy1iptWE30M8ABN-Op3x1VfT

## Figures
### Raw image
![](raw_data_example.png)

### Training image
![](gt_example1.png) ![](gt_example2.png)

### Preprocessed / superpixel / segmentation image
![](processed_example.bmp) ![](superpixel_example.bmp) ![](segmentation_example.bmp)

### Preprocessed result folder
![](preprocess_example.png)

### Segmentation result folder
![](segmentation_processing_example.png)


### Visualization
![](time_series_example.png)

![](visualization_example2.png)
![](visualization_example3.png)
