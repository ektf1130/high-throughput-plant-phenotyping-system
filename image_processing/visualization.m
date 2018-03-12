clear;
close all;

testBWPath = './test_data_6pm_v2/*_bwImg.bmp';
testSegmentationPath='./test_data_6pm_v2/*_segmentationImg.bmp';

analysisResultPath='./analysisResult/';

testBW_listing=subdir(testBWPath);
testSegmentation_listing=subdir(testSegmentationPath);
numBWImages = size(testBW_listing,1);

time=[];
value=[];
mean_value=[];
temp_id='';
temp_trayID= '';
temp_potID='';
isSameTray=false;
isSamePot=false;
segmentation_images=[];
all_graph=[];
sub_graph=[];

for img_index=1:1:numBWImages
    %% arrange by tray and pot ID
    bwName=strsplit(testBW_listing(img_index).name,'/'); % '\' for windows users
    fname=bwName{length(bwName)};
    
    tray_potID=bwName{length(bwName)-2};
    temp_tray_potID = strsplit(tray_potID,'_');
    trayID = temp_tray_potID{length(temp_tray_potID)-1};
    
    potID = temp_tray_potID{length(temp_tray_potID)};
   
    
    bw=imread(testBW_listing(img_index).name);
    bw=imbinarize(bw);
    
    if img_index==1
       temp_id=tray_potID;
       temp_trayID=trayID;
       temp_potID=potID;
    end
    
    if strcmp(temp_trayID, trayID)
        isSameTray=true;
    else
        isSameTray=false;
    end
    if strcmp(temp_potID,potID)
        isSamePot=true;
    else
        isSamePot=false;
    end
    
    if isSameTray && isSamePot
       fname=strsplit(fname,'_');
       date=fname(2);
       area=sum(sum(bw));
       time=[time;date];
       value=[value;area];
       seg_img=imread(testSegmentation_listing(img_index).name); 
       segmentation_images=[segmentation_images seg_img];
       
       
    elseif isSameTray && ~(isSamePot)
         if sum(value)~=0
             x=datenum(time,'yyyymmdd');
             p=plot(x,value,'DisplayName',temp_potID,'color',rand(1,3));
             p.LineWidth = 2;
             p.LineStyle = ':';

             text(x(length(x)),value(length(value)),temp_potID,'FontSize', 8);
             datetick('x','yyyymmdd');
             title(temp_trayID);
             xlabel('Days');
             ylabel('Area (pixels)');
             mean_value=[mean_value value];
         end
         
         
         %save segmentation images over days
         imwrite(segmentation_images,[analysisResultPath temp_trayID '_' temp_potID '.png']);
         segmentation_images=[];
         
         time=[];
         value=[];
       
         temp_id=tray_potID;
         temp_trayID= trayID;
         temp_potID = potID;
         
         fname=strsplit(fname,'_');
         date=fname(2);
         area=sum(sum(bw));
         time=[time;date];
         value=[value;area];
         hold on
         
    elseif ~(isSameTray) && ~(isSamePot)
         
         
         if sum(value)~=0
             x=datenum(time,'yyyymmdd');
             p=plot(x,value,'DisplayName',temp_potID,'color',rand(1,3));
             p.LineWidth = 2;
             p.LineStyle = ':';
             mean_value=[mean_value value];
             text(x(length(x)),value(length(value)),temp_potID);
             m_y=mean(mean_value,2);
             p=plot(x,m_y,'DisplayName','Average','color','r');
             p.LineWidth = 3;
             p.LineStyle = '-';
             
             datetick('x','yyyymmdd');
             
             %mean of tray
             
         end
         legend('show','Location','northwest');
         disp('save');
        
         set(gcf, 'Position', get(0, 'Screensize'));
         saveas(p, [analysisResultPath temp_trayID '.png'],'png');
         close;
         size(imread([analysisResultPath temp_trayID '.png']),2);
        
         if mod(size(sub_graph,2) /  size(imread([analysisResultPath temp_trayID '.png']),2),5)==0
             
            all_graph=[all_graph;sub_graph];
            sub_graph=[];
            sub_graph=[sub_graph imread([analysisResultPath temp_trayID '.png'])];
         else
            sub_graph=[sub_graph imread([analysisResultPath temp_trayID '.png'])];
         end
         
         %save segmentation images over days
         imwrite(segmentation_images,[analysisResultPath temp_trayID '_' temp_potID '.png']);
         segmentation_images=[];
         
         time=[];
         value=[];
         mean_value=[];
         temp_id=tray_potID;
         temp_trayID= trayID;
         temp_potID = potID;
         hold off
         
         %figure;
         fname=strsplit(fname,'_');
         date=fname(2);
         area=sum(sum(bw));
         time=[time;date];
         value=[value;area];
        
    end
    
          
    %final
     if img_index==numBWImages
        if sum(value)~=0
            x=datenum(time,'yyyymmdd');
            p=plot(x,value,'DisplayName',temp_potID,'color',rand(1,3));
            p.LineWidth = 2;
            p.LineStyle = ':';
            text(x(length(x)),value(length(value)),temp_potID);

            title(temp_trayID);
            xlabel('Days');
            ylabel('Area (pixels)');
            mean_value=[mean_value value];          
            m_y=mean(mean_value,2);
            p=plot(x,m_y,'DisplayName','Average','color','r');
            p.LineWidth = 3;
            p.LineStyle = '-';
            
            datetick('x','yyyymmdd');
        end
         legend('show','Location','northwest');
         set(gcf, 'Position', get(0, 'Screensize'));
         saveas(p, [analysisResultPath temp_trayID '.png'],'png');
         close;
         
         if mod(size(sub_graph,2) /  size(imread([analysisResultPath temp_trayID '.png']),2),5)==0
             
            all_graph=[all_graph;sub_graph];
            sub_graph=[];
            sub_graph=[sub_graph imread([analysisResultPath temp_trayID '.png'])];
         else
            sub_graph=[sub_graph imread([analysisResultPath temp_trayID '.png'])];
         end
          
         %save segmentation images over days
         imwrite(segmentation_images,[analysisResultPath temp_trayID '_' temp_potID '.png']);
         segmentation_images=[];
         
     end 
     
    


    
  
end

if size(all_graph,1)==0
    all_graph=[all_graph;sub_graph];
else
    sub_graph=padarray(sub_graph,[0 size(all_graph,2)-size(sub_graph,2)],'post');
    sub_graph(sub_graph==0)=255;
    all_graph=[all_graph;sub_graph];
end 

imwrite(all_graph,[analysisResultPath 'all' '.png']);