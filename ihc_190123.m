clear all
close all

filePrefix='fly27_bothALs_';
nc82name=[filePrefix 'nc82.tif'];
spotname=[filePrefix 'spots.tif'];
surfacename=[filePrefix 'surfaces.tif'];

% get image info
nc82info=imfinfo(nc82name);
spotinfo=imfinfo(spotname);
surfaceinfo=imfinfo(surfacename);

nc82l=length(nc82info);
spotl=length(spotinfo);
surfacel=length(surfaceinfo);

nc82im=zeros(nc82info(1).Width,nc82info(1).Height,nc82l);
spotim=zeros(spotinfo(1).Width,spotinfo(1).Height,spotl);
surfaceim=zeros(surfaceinfo(1).Width,surfaceinfo(1).Height,surfacel);
for i=1:nc82l
    nc82im(:,:,i)=imread(nc82name,'Index',i);

    spotim(:,:,i)=imread(spotname,'Index',i);

    surfaceim(:,:,i)=imread(surfacename,'Index',i);
    
    if mod(i,10)==0
       disp(['loaded ' num2str(i)]) 
    end
end
disp('images loaded')

%% manually mask left and right lobes
figure
imagesc(nc82im(:,:,30))
rmask=roipoly;
lmask=1-rmask;

for i=1:nc82l
   imagesc(rmask.*nc82im(:,:,i))
   pause(0.05)
end
for i=1:nc82l
   imagesc(lmask.*nc82im(:,:,i))
   pause(0.05)
end


%% create masked left and right image
% create blurry spotb image
smoothkernelsize=15;
spotbBlur = imgaussfilt(single(spotim>0),smoothkernelsize);
disp('blurred spot image')
minarea=1000000;
spotbBlur2 = bwareaopen(spotbBlur,minarea);
disp('removed small objects')

% dilate spotb
spotbclosed=imclose(spotbBlur2,strel('sphere',4));

% mask nc82 channel
maskednc82=spotbclosed.*nc82im;

% figure
% for i=1:nc82l
% imagesc(maskednc82(:,:,i))
% pause(0.05)
% end

rightim=rmask.*maskednc82;
leftim=lmask.*maskednc82;

gs=30;
x=[-100:100];
y=x;
[xx yy]=meshgrid(x,y);
gau=1/(length(x)*gs^2)*exp(-(xx.^2+yy.^2)/(2*gs^2));
for i=1:nc82l
    temp=rightim(:,:,i);
    
    % normalize image intensity to mean within a grid
   
    normalizer=conv2(temp,gau,'same');
    tempn=temp./normalizer;
    
    rightim(:,:,i)=tempn;
    
    temp2=leftim(:,:,i);
    
    % normalize image intensity to mean within a grid
    normalizer=conv2(temp2,gau,'same');
    tempn2=temp2./normalizer;
    
    leftim(:,:,i)=tempn2;
    
    if mod(i,10)==0
       disp(['normalized slice ' num2str(i)]) 
    end
end
%%
% set dynamic threshold
upperthresh=3.5; % left lobe
lowerthresh=2.9; % left lobe
upperthresh=25; % left lobe
lowerthresh=upperthresh; % left lobe
%upperthresh=6; % right lobe
%lowerthresh=2.5;%right lobe



sliceNum=10;
temp=leftim(:,:,sliceNum);
thresh=linspace(upperthresh,lowerthresh,size(nc82im,3));
figure
subplot(1,2,1)
imagesc(temp,[0 100])

I = (imgaussfilt(temp,2));


im=I<thresh(sliceNum);
im=imclose(im,strel('disk',2));
im=bwareaopen(im,1000);
im=~bwareaopen(~im,1000);

% Distance transform
imb=bwdist(im);

% Blur
sigma=3;
kernel = fspecial('gaussian',4*sigma+1,sigma);
im2=imfilter(imb,kernel,'symmetric');


% Watershed transform
L = watershed(max(im2(:))-im2);

% Plot
lblImg = bwlabel(L&~im);


subplot(1,2,2);
imshow(label2rgb(lblImg,'jet','k','shuffle'));

%% perform watershed transform on entire z-stack downsampled by 2 in x + y with gradient
downsamplefactor=1;
%myimtrunc=maskednc82(1:downsamplefactor:end,1:downsamplefactor:end,1:end);
myimtrunc=imresize(leftim,[round(size(maskednc82,1)/downsamplefactor) round(size(maskednc82,2)/downsamplefactor)],'bilinear');
%myimtrunc=myimtrunc(:,:,10:20);

thresh=linspace(upperthresh,lowerthresh,size(myimtrunc,3)); 

thresholdedim=zeros(size(myimtrunc));
for sliceNum=1:size(myimtrunc,3)
    tempn=myimtrunc(:,:,sliceNum);
   
    I = imgaussfilt(tempn,2);
    
    im=I<thresh(sliceNum);
    im=imclose(im,strel('disk',2));
    im=bwareaopen(im,1000);
    im=~bwareaopen(~im,1000);
    thresholdedim(:,:,sliceNum)=im;
end

% reverse z - dimension (so slice 1 is bottom and final slice is the top)
thresholdedim=thresholdedim(:,:,end:-1:1);
myimtrunc=myimtrunc(:,:,end:-1:1);
disp('finished pre-processing z-stack')

% Distance transform
imb=bwdist(thresholdedim);

% Blur
sigma=3;
im2=imgaussfilt3(imb,sigma);

% Watershed transform
tic
disp('beginning watershed transform')
minSuppressionThreshold=2;
preL=max(im2(:))-im2;
preL2=imhmin(preL,minSuppressionThreshold); % default 5, revise imhmin threshold to 3 or 4?
L = watershed(preL2);
lblImg = bwlabeln(L&~thresholdedim);

figure
subplot(1,2,1)
imagesc(myimtrunc(:,:,end-10))
subplot(1,2,2)
imagesc(lblImg(:,:,end-10))

disp(['finished. time elapsed: ' num2str(toc)])

%% plot each labelled slice
figure
filename='left_nc82_watershed.gif';
for i=1:size(lblImg,3)

    imagesc(lblImg(:,:,i))
    
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    set(gca,'XTickLabel','')
    set(gca,'YTickLabel','')
    %text(-20,-25,['z-slice ' num2str(i)],'FontSize',20)
    
    drawnow
    
    % Capture the plot as an image
    frame = getframe;
    im = frame2im(frame);
    [imind,cm] = rgb2ind(im,256);
    
     % Write to the GIF File
    if i == 1
        imwrite(imind,cm,filename,'gif', 'Loopcount',inf,'DelayTime',0.1);
    else
        imwrite(imind,cm,filename,'gif','WriteMode','append','DelayTime',0.1);
    end
    
end

%% downsample each dim by a factor of 2 to see if it speeds things up

downsamplefactor=2;
lbl2=imresize(lblImg,[round(size(maskednc82,1)/downsamplefactor) round(size(maskednc82,2)/downsamplefactor)],'nearest');
disp('beginning to find pixel islands')

warning('off')
areathresh=5000;
areathreshhigh=600000;
lbls=regionprops(lbl2,'all');
todelete=[];
clusterVols2=cell(1,length(lbls));
clusterInfo2=cell(1,length(lbls));
for j=1:length(lbls)
    if lbls(j).Area>areathresh && lbls(j).Area<areathreshhigh
        clusterVols2{j}=(lbl2==j);
        clusterInfo2{j}=lbls(j);
    else
        todelete=[todelete j];
    end
    if mod(j,100)==0
       disp(['post-processed ' num2str(j)]) 
    end
end
clusterVols2(todelete)=[];
clusterInfo2(todelete)=[];

%plot downsampled results
disp(['plotting results. found ' num2str(length(clusterVols2)) ' voxel islands'])

figure
view(3);
axis tight
camlight
lighting gouraud

hold on

rng('default')
mycmap=hsv(length(clusterVols2));
mycmap=mycmap(randperm(length(mycmap)),:);

randv=randperm(length(clusterVols2));
for i=randv
    p2=patch(isosurface(clusterVols2{i}),'FaceColor',mycmap(i,:),'EdgeColor','none','FaceAlpha',0.8);
    isonormals(clusterVols2{i},p2)

    drawnow
end
disp('done plotting')