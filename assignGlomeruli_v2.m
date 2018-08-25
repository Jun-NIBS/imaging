% assign glomeruli
% calculate two odor distances.
% Matt Churgin, August 2018
%% load data and compute spatial and odor response priors

%clear all
close all

% initialization
leftLobe=0;
minResponse=0.1; % remove clusters with maximum response less than this
showIntermediateFigs=0;
compressDoORdata=1; % if you want to take log of DooR data to compress (DoOR data is ORN, PNs have compressed signal)
omitAtlasZSlices=1;
myPercentage=3;

% weights for each prior
% all 1s for equal weighting
physDistWeight=2;
odorWeight=1;
shapeWeight=1;

filename=uigetfile(); % load processed k means .mat file

load(filename)

% load published odor response matrix and centroids
publishedOdorPath='/Users/mattchurgin/Desktop/dblab/mattFunctions/odorpanelResponsesDoOR/odorPanel_12/odorPanel_12_DoORData.mat';
publishedOR=load(publishedOdorPath);
pubOR=publishedOR.publishedOR.gh146response';
pubNames=publishedOR.publishedOR.gh146receptorNames;
pubGlomNames=publishedOR.publishedOR.gh146glomerulusNames;
pubX=publishedOR.publishedOR.gh146xCentroid;
pubY=publishedOR.publishedOR.gh146yCentroid;
pubZ=-publishedOR.publishedOR.gh146zCentroid;% minus sign flips the z centroids to match our data (lower z means more ventral)
pubXborder=publishedOR.publishedOR.gh146glomBorderX;
pubYborder=publishedOR.publishedOR.gh146glomBorderY;
pubZborder=publishedOR.publishedOR.gh146glomBorderZ;
pubXborderAll=[];
pubYborderAll=[];
for j=1:length(pubXborder)
    pubXborderAll=[pubXborderAll pubXborder{j}];
    pubYborderAll=[pubYborderAll pubYborder{j}];
end
xscale=size(clusterVolU{1},2)/max(pubXborderAll); % find x and y scaling from atlas to 2-photon images
yscale=size(clusterVolU{1},1)/max(pubYborderAll);

% flip x axis if data is a left lobe
if leftLobe
    pubX=-pubX;
end

% remove z slices
if omitAtlasZSlices
    slicesToRemove=find(pubZ==-5);
    pubZ(slicesToRemove)=NaN;
    pubX(slicesToRemove)=NaN;
    pubY(slicesToRemove)=NaN;
else
    slicesToRemove=[];
end
% pubX=(pubX-nanmin(pubX))/(max(pubX)-min(pubX));
% pubY=(pubY-nanmin(pubY))/(max(pubY)-min(pubY));
% pubZ=(pubZ-nanmin(pubZ))/(max(pubZ)-min(pubZ));
pubX=(pubX-prctile(pubX,myPercentage))/(prctile(pubX,100-myPercentage)-prctile(pubX,myPercentage));
pubY=(pubY-prctile(pubY,myPercentage))/(prctile(pubY,100-myPercentage)-prctile(pubY,myPercentage));
pubZ=(pubZ-prctile(pubZ,myPercentage))/(prctile(pubZ,100-myPercentage)-prctile(pubZ,myPercentage));

for j=1:length(pubNames)
    pubNames{j}=num2str(pubNames{j});
    pubGlomNames{j}=num2str(pubGlomNames{j});
end

if compressDoORdata
    % DoOR data is taken from ORNs.  PNs are known to amplify weak signal.
    % Therefore, we compress pubOR signal by taking log of published odor response
    pubOR=log10(pubOR);
    pubOR(isinf(pubOR))=NaN;
    pubOR=pubOR-min(min(pubOR));
end

% mean center and normalize published data

for i=1:size(pubOR,2)
    if nanstd(pubOR(:,i))>0
        pubORWithinGlom(:,i)=(pubOR(:,i)-nanmin(pubOR(:,i)))./(nanmax(pubOR(:,i))-nanmin(pubOR(:,i)));
    else
        pubORWithinGlom(:,i)=(pubOR(:,i)-nanmin(pubOR(:,i)));
    end
end

for i=1:size(pubOR,1)
    if nanstd(pubOR(i,:))>0
        pubORAcrossGlom(i,:)=(pubOR(i,:)-nanmin(pubOR(i,:)))./(max(pubOR(i,:))-min(pubOR(i,:)));
    else
        pubORAcrossGlom(i,:)=(pubOR(i,:)-nanmin(pubOR(i,:)));
    end
end

% calculate max response over all time points
maxResponse=max(grnResponseNorm,[],3);
myOR=maxResponse(2:13,:); % omit air (odor 1
rawClustersToDelete=max(myOR)<minResponse;
myOR(:,rawClustersToDelete)=NaN;
myORraw=myOR;

% load cluster centroid data and normalize
cX=zeros(1,length(clusterInfoU));
cY=zeros(1,length(clusterInfoU));
cZ=zeros(1,length(clusterInfoU));

for j=1:length(clusterInfoU)
    cX(j)=clusterInfoU{j}.Centroid(1);
    cY(j)=clusterInfoU{j}.Centroid(2);
    cZ(j)=clusterInfoU{j}.Centroid(3);
end
cX(rawClustersToDelete)=NaN;
cY(rawClustersToDelete)=NaN;
cZ(rawClustersToDelete)=NaN;

% cX=(cX-nanmin(cX))/(max(cX)-min(cX));
% cY=(cY-nanmin(cY))/(max(cY)-min(cY));
% cZ=(cZ-nanmin(cZ))/(max(cZ)-min(cZ));
cX=(cX-prctile(cX,myPercentage))/(prctile(cX,100-myPercentage)-prctile(cX,myPercentage));
cY=(cY-prctile(cY,myPercentage))/(prctile(cY,100-myPercentage)-prctile(cY,myPercentage));
cZ=(cZ-prctile(cZ,myPercentage))/(prctile(cZ,100-myPercentage)-prctile(cZ,myPercentage));

figure
plot3(pubX,pubY,pubZ,'o')
hold on
for j=1:length(pubX)
    try
        text(pubX(j),pubY(j),pubZ(j), pubGlomNames{j},'FontSize',15,'FontWeight','Bold')
    catch
    end
end
plot3(cX,cY,cZ,'ro')

% mean center and normalize each cluster's odor response
% normalize each cluster's odor response (to get relative activation

for i=1:size(myOR,2)
    if std(myOR(:,i))>0
        myORWithinGlom(:,i)=(myOR(:,i)-nanmin(myOR(:,i)))./(nanmax(myOR(:,i))-nanmin(myOR(:,i)));
    else
        myORWithinGlom(:,i)=(myOR(:,i)-nanmin(myOR(:,i)));
    end
end

for i=1:size(myOR,1)
    if nanstd(myOR(i,:))>0
        myORAcrossGlom(i,:)=(myOR(i,:)-nanmin(myOR(i,:)))./(nanmax(myOR(i,:))-nanmin(myOR(i,:)));
    else
        myORAcrossGlom(i,:)=(myOR(i,:)-nanmin(myOR(i,:)));
    end
end

% calculate euclidean distance between each cluster and published responses
% for these odors
odorDist=NaN*zeros(size(myOR,2),size(pubOR,2));
odorDistAcross=NaN*zeros(size(myOR,2),size(pubOR,2));
physDist=NaN*zeros(size(myOR,2),size(pubOR,2));
for i=1:size(myOR,2)
    for j=1:size(pubOR,2)
        odorDist(i,j)=sqrt(nansum((myORWithinGlom(:,i)-pubORWithinGlom(:,j)).^2))/sqrt(sum(isfinite(pubORWithinGlom(:,j))));
        %odorDist(i,j)=sqrt(nansum(((myOR(:,i)-pubOR(:,j)))).^2)/sqrt(nansum(((myOR(:,i)+pubOR(:,j)))).^2);
        
        %odorDist(i,j)=sqrt(nansum(((myOR(:,i)-pubOR(:,j))./myORraw(:,i)).^2))./sqrt(sum(isfinite(pubOR(:,j))));
        
        
        %odorDistAcross(i,j)=????
        
        physDist(i,j)=sqrt((cX(i)-pubX(j)).^2+(cY(i)-pubY(j)).^2+(cZ(i)-pubZ(j)).^2);
        
        % omit z information
        %physDist(i,j)=sqrt((cX(i)-pubX(j)).^2+(cY(i)-pubY(j)).^2);
    end
end

%% compute glomerulus shape prior
% use 2d cross-correlation between each cluster maximum 2d projection and
% the glomerulus cross-section

% create 2d maximum projections for quantifying shape prior
clusterProj=cell(1,size(myOR,2));
for i=1:size(myOR,2)
    clusterTemp=double(any(clusterVolU{i},3));
    
    % set pixels outside of cluster equal to -1 to penalize partial
    % overlaps
    clusterTemp(clusterTemp==0)=-1;
    
    clusterProj{i}=clusterTemp;
end

% make glomProj from atlas glom borders
glomCentroidMask=cell(1,size(pubOR,2));
glomProj=cell(1,size(pubOR,2));
for i=1:size(pubOR,2)
    % scale coordinates according to size of 2-photon image
    pubXborderScaled{i}=xscale*pubXborder{i};
    pubYborderScaled{i}=yscale*pubYborder{i};
    
    %  convert boundary into logical matrices
    [xx yy]=meshgrid(1:size(clusterVolU{1},2),1:size(clusterVolU{1},1));
    glomCentroidMask{i} = inpolygon(xx,yy,pubXborderScaled{i},pubYborderScaled{i});
    
    glomTemp=double(glomCentroidMask{i});
    glomTemp(glomTemp==0)=-1;
    if leftLobe
        glomProj{i}=glomTemp(:,end:-1:1);
    else
        glomProj{i}=glomTemp;
    end
end

% use maximum projection of ech cluster and convolve with door glomeruluar
% atlas to find cluster that maximizes shape correlation
shapePriorNorm=zeros(size(myOR,2),size(pubOR,2));

xpeaks=zeros(size(myOR,2),size(pubOR,2));
ypeaks=zeros(size(myOR,2),size(pubOR,2));
tic
for i=1:size(myOR,2)
    for j=1:size(pubOR,2)
        tempcorrnorm=normxcorr2(clusterProj{i},glomProj{j});
        shapePriorNorm(i,j)=max(tempcorrnorm(:));
        
        % save location of maximum cross correlation
        [ypeak xpeak]=find(tempcorrnorm==max(tempcorrnorm(:)));
        try
            xpeaks(i,j)=xpeak;
            ypeaks(i,j)=ypeak;
        catch
            xpeaks(i,j)=xpeak(1);
            ypeaks(i,j)=ypeak(1);
        end
        disp(['calculated cross-correlation for cluster ' num2str(i) ', glomerulus ' num2str(j)])
    end
end
disp(['time elapsed to compute cross-correlations: ' num2str(toc) ' seconds'])

%% combine priors and assign glomeruli
% normalize distance matrices between 0 and 1
%odorDistNormed=(odorDist-min(odorDist(:)))/max(odorDist(:)-min(odorDist(:)));
odorDistNormed=odorDist;
%physDistNormed=(physDist-min(physDist(:)))/max(physDist(:)-min(physDist(:)));
physDistNormed=(physDist-prctile(physDist(:),1))/max(physDist(:)-min(physDist(:)));
%shapePriorNormed=(shapePriorNorm-min(shapePriorNorm(:)))/max(shapePriorNorm(:)-min(shapePriorNorm(:)));
shapePriorNormed=(shapePriorNorm-prctile(shapePriorNorm(:),1))/max(shapePriorNorm(:)-min(shapePriorNorm(:)));

physDistNormed=physDistNormed-2*min(physDistNormed(:));


toFillP=find(any(physDistNormed)==0);
physDistNormed(:,toFillP)=nanmean(physDistNormed(:));
physDistNormed(rawClustersToDelete,:)=NaN;

toFillS=find(any(shapePriorNormed)==0);
shapePriorNormed(:,toFillS)=nanmean(shapePriorNormed(:));
shapePriorNormed(rawClustersToDelete,:)=NaN;

toFillO=find(any(odorDistNormed)==0);
odorDistNormed(:,toFillO)=nanmean(odorDistNormed(:));
odorDistNormed(rawClustersToDelete,:)=NaN;

compositeDist =  physDistWeight*log10(physDistNormed)+ shapeWeight*log10(1-shapePriorNormed);

% create a fully randomized composite dist as a control
compositeDistControl=rand(size(physDistNormed,1),size(physDistNormed,2));
compositeDistControl(~any(physDistNormed,2),:)=NaN;

compositeDist(:,slicesToRemove)=NaN;
compositeDistControl(:,slicesToRemove)=NaN;

if showIntermediateFigs
    figure
    imagesc(myORraw)
    xlabel('Cluster #')
    ylabel('Odor #')
    title('Cluster Maximum dF/F (Raw)')
    set(gca,'FontSize',20)
    
    figure
    imagesc(myOR)
    xlabel('Cluster #')
    ylabel('Odor #')
    title('Cluster Maximum dF/F (Normalized)')
    set(gca,'FontSize',20)
    
    figure
    imagesc(pubOR)
    set(gca,'xtick',1:length(pubNames),'xticklabel',string(pubNames),'FontSize',5)
    xtickangle(30)
    xlabel('Glomeruli','FontSize',20)
    ylabel('Odor #','FontSize',20)
    title('Glomerular Maximum Response','FontSize',20)
    
    
    figure;
    imagesc(odorDistNormed)
    %set(gca,'FontSize',20)
    set(gca,'xtick',1:length(pubNames),'xticklabel',string(pubNames),'FontSize',5)
    xtickangle(30)
    xlabel('Glomeruli','FontSize',20)
    ylabel('Cluster #','FontSize',20)
    title('Odor Panel Response Euclidean Distance','FontSize',20)
    
    figure;
    imagesc(physDistNormed)
    %set(gca,'FontSize',20)
    set(gca,'xtick',1:length(pubNames),'xticklabel',string(pubNames),'FontSize',5)
    xtickangle(30)
    xlabel('Glomeruli','FontSize',20)
    ylabel('Cluster #','FontSize',20)
    title('Physical Euclidean Distance','FontSize',20)
    
    figure;
    imagesc(shapePriorNormed)
    %set(gca,'FontSize',20)
    set(gca,'xtick',1:length(pubNames),'xticklabel',string(pubNames),'FontSize',5)
    xtickangle(30)
    xlabel('Glomeruli','FontSize',20)
    ylabel('Cluster #','FontSize',20)
    title('Physical Euclidean Distance','FontSize',20)
    
    figure;
    imagesc((compositeDist))
    %set(gca,'FontSize',20)
    set(gca,'xtick',1:length(pubNames),'xticklabel',string(pubNames),'FontSize',5)
    xtickangle(30)
    xlabel('Glomeruli','FontSize',20)
    ylabel('Cluster #','FontSize',20)
    title('Composite Distance','FontSize',20)
    
end

% Simple Greedy algorithm with one pass through
% find glomerulus that minimizes multiplied distance to each cluster
glomMinimizing=zeros(1,size(myOR,2));
glomMinimizingMatrix=zeros(size(myOR,2),size(pubOR,2));
for i=1:size(myOR,2)
    if any(compositeDist(i,:))
        [val ind]=nanmin(compositeDist(i,:));
        glomMinimizing(i)=ind;
        
        [asdf asdf2]=sort(compositeDist(i,:));
        glomMinimizingMatrix(i,:)=asdf2;
    else
        glomMinimizing(i)=0;
        glomMinimizingMatrix(i,:)=NaN;
    end
end


figure
for j=1:length(glomMinimizing)
    if glomMinimizing(j)>0
        p2=patch(isosurface(clusterVolU{j}),'FaceColor',rand(1,3),'EdgeColor','none','FaceAlpha',0.3);
        isonormals(clusterVolU{j},p2)
        text(clusterInfoU{j}.Centroid(1),clusterInfoU{j}.Centroid(2),clusterInfoU{j}.Centroid(3),pubGlomNames{glomMinimizing(j)},'FontSize',15,'FontWeight','Bold')
        hold on
    end
end

uniqueGloms=unique(glomMinimizing);

% find cluster that minimizes multiplied distance to each glomerulus
uniqueClusters=zeros(1,(length(uniqueGloms)));
for i=2:(length(uniqueGloms))
    currGlom=uniqueGloms(i);
    currClusters=find(glomMinimizing==currGlom);
    [mymin myind]=min(compositeDist(currClusters,currGlom));
    uniqueClusters(i)=currClusters(myind);
end

figure
for j=2:length(uniqueGloms)
    p2=patch(isosurface(clusterVolU{uniqueClusters(j)}),'FaceColor',rand(1,3),'EdgeColor','none','FaceAlpha',0.3);
    isonormals(clusterVolU{uniqueClusters(j)},p2)
    text(clusterInfoU{uniqueClusters(j)}.Centroid(1),clusterInfoU{uniqueClusters(j)}.Centroid(2),clusterInfoU{uniqueClusters(j)}.Centroid(3),pubGlomNames{uniqueGloms(j)},'FontSize',15,'FontWeight','Bold')
    hold on
end

%% More complex greedy algorithm makes multiple passes through
compositeDistTemp=compositeDist;
compositeDistTempControl=compositeDistControl;

assignmentThreshold=prctile(prctile(compositeDist,25),25);
assignmentThreshold=Inf;

assignmentScore=[];
glomerulusAssignment=[];
clusterAssignment=[];
assignmentScoreControl=[];
glomerulusAssignmentControl=[];
clusterAssignmentControl=[];
iters=0;
itersControl=0;
nassignments=1;
nassignmentsControl=1;
while sum(any(compositeDistTemp))>0
    %while iters<3
    % find glomerulus that minimizes multiplied distance to each cluster
    glomMinimizing=zeros(1,size(myOR,2));
    glomMinimizingMatrix=zeros(size(myOR,2),size(pubOR,2));
    for i=1:size(myOR,2)
        if any(compositeDistTemp(i,:))
            [val ind]=nanmin(compositeDistTemp(i,:));
            glomMinimizing(i)=ind;
            
            [asdf asdf2]=sort(compositeDistTemp(i,:));
            glomMinimizingMatrix(i,:)=asdf2;
        else
            glomMinimizing(i)=0;
            glomMinimizingMatrix(i,:)=NaN;
        end
    end
    
    uniqueGloms=unique(glomMinimizing);
    
    % find cluster that minimizes composite distance to each glomerulus
    uniqueClusters=zeros(1,(length(uniqueGloms)));
    for i=2:(length(uniqueGloms))
        currGlom=uniqueGloms(i);
        currClusters=find(glomMinimizing==currGlom);
        [mymin myind]=min(compositeDistTemp(currClusters,currGlom));
        assignmentScore(nassignments)=mymin;
        
        uniqueClusters(i)=currClusters(myind);
        compositeDistTemp(currClusters(myind),:)=NaN;
        compositeDistTemp(:,currGlom)=NaN;
        nassignments=nassignments+1;
    end
    
    glomerulusAssignment=[glomerulusAssignment uniqueGloms];
    clusterAssignment=[clusterAssignment uniqueClusters];
    iters=iters+1;
    disp(['completed ' num2str(iters) ' iterations'])
end

while sum(any(compositeDistTempControl))>0
    %while iters<3
    % find glomerulus that minimizes multiplied distance to each cluster
    glomMinimizingControl=zeros(1,size(myOR,2));
    glomMinimizingMatrixControl=zeros(size(myOR,2),size(pubOR,2));
    for i=1:size(myOR,2)
        if any(compositeDistTempControl(i,:))
            [val ind]=nanmin(compositeDistTempControl(i,:));
            glomMinimizingControl(i)=ind;
            
            [asdf asdf2]=sort(compositeDistTempControl(i,:));
            glomMinimizingMatrixControl(i,:)=asdf2;
        else
            glomMinimizingControl(i)=0;
            glomMinimizingMatrixControl(i,:)=NaN;
        end
    end
    
    uniqueGlomsControl=unique(glomMinimizingControl);
    
    % find cluster that minimizes composite distance to each glomerulus
    uniqueClustersControl=zeros(1,(length(uniqueGlomsControl)));
    for i=2:(length(uniqueGlomsControl))
        currGlom=uniqueGlomsControl(i);
        currClusters=find(glomMinimizingControl==currGlom);
        [mymin myind]=min(compositeDistTempControl(currClusters,currGlom));
        assignmentScoreControl(nassignmentsControl)=mymin;
        
        uniqueClustersControl(i)=currClusters(myind);
        compositeDistTempControl(currClusters(myind),:)=NaN;
        compositeDistTempControl(:,currGlom)=NaN;
        nassignmentsControl=nassignmentsControl+1;
    end
    
    glomerulusAssignmentControl=[glomerulusAssignmentControl uniqueGlomsControl];
    clusterAssignmentControl=[clusterAssignmentControl uniqueClustersControl];
    itersControl=itersControl+1;
    disp(['completed ' num2str(itersControl) ' iterations'])
end

todelete=find(glomerulusAssignment==0);
glomerulusAssignment(todelete)=[];
clusterAssignment(todelete)=[];

todeleteControl=find(glomerulusAssignmentControl==0);
glomerulusAssignmentControl(todeleteControl)=[];
clusterAssignmentControl(todeleteControl)=[];

% remove high scores (poor fit)
highScores=find(assignmentScore>assignmentThreshold);
glomerulusAssignment(highScores)=[];
clusterAssignment(highScores)=[];
assignmentScore(highScores)=[];

highScoresControl=find(assignmentScoreControl>assignmentThreshold);
glomerulusAssignmentControl(highScoresControl)=[];
clusterAssignmentControl(highScoresControl)=[];
assignmentScoreControl(highScoresControl)=[];

odorScore=zeros(1,length(clusterAssignment));
odorScoreShuffled=zeros(1,length(clusterAssignment));
permutedArray=randperm(length(clusterAssignment));
% validate using odor response
for j=1:length(clusterAssignment)
    odorScore(j)=sqrt(nansum((myORAcrossGlom(:,clusterAssignment(j))-pubORAcrossGlom(:,glomerulusAssignment(j))).^2)/sqrt(nansum(isfinite(pubORAcrossGlom(:,glomerulusAssignment(j))))));
    odorScoreShuffled(j)=sqrt(nansum((myORAcrossGlom(:,clusterAssignment((j)))-pubORAcrossGlom(:,glomerulusAssignment(permutedArray(j)))).^2)/sqrt(nansum(isfinite(pubORAcrossGlom(:,glomerulusAssignment(permutedArray(j)))))));
end

tokeepOdorScore=find(isfinite(odorScore));
odorScoreNoNan=odorScore(tokeepOdorScore);
assignmentScoreNoNan=assignmentScore(tokeepOdorScore);
[mycorr myp]=corrcoef(assignmentScoreNoNan,odorScoreNoNan);

tokeepOdorScoreShuffled=find(isfinite(odorScoreShuffled));
odorScoreShuffledNoNan=odorScoreShuffled(tokeepOdorScoreShuffled);
assignmentScoreShuffledNoNan=assignmentScore(tokeepOdorScoreShuffled);
[mycorrShuffled mypShuffled]=corrcoef(assignmentScoreShuffledNoNan,odorScoreShuffledNoNan);

odorScoreControl=zeros(1,length(clusterAssignmentControl));
odorScoreShuffledControl=zeros(1,length(clusterAssignmentControl));
permutedArrayControl=randperm(length(clusterAssignmentControl));
% validate using odor response
for j=1:length(clusterAssignmentControl)
    odorScoreControl(j)=sqrt(nansum((myORAcrossGlom(:,clusterAssignmentControl(j))-pubORAcrossGlom(:,glomerulusAssignmentControl(j))).^2)/sqrt(nansum(isfinite(pubORAcrossGlom(:,glomerulusAssignmentControl(j))))));
    odorScoreShuffledControl(j)=sqrt(nansum((myORAcrossGlom(:,clusterAssignmentControl((j)))-pubORAcrossGlom(:,glomerulusAssignmentControl(permutedArrayControl(j)))).^2)/sqrt(nansum(isfinite(pubORAcrossGlom(:,glomerulusAssignmentControl(permutedArrayControl(j)))))));
end

tokeepOdorScoreControl=find(isfinite(odorScoreControl));
odorScoreNoNanControl=odorScoreControl(tokeepOdorScoreControl);
assignmentScoreNoNanControl=assignmentScoreControl(tokeepOdorScoreControl);
[mycorrControl mypControl]=corrcoef(assignmentScoreNoNanControl,odorScoreNoNanControl);

tokeepOdorScoreShuffledControl=find(isfinite(odorScoreShuffledControl));
odorScoreShuffledNoNanControl=odorScoreShuffledControl(tokeepOdorScoreShuffledControl);
assignmentScoreShuffledNoNanControl=assignmentScoreControl(tokeepOdorScoreShuffledControl);
[mycorrShuffledControl mypControlShuffled]=corrcoef(assignmentScoreShuffledNoNanControl,odorScoreShuffledNoNanControl);

figure
plot(assignmentScoreNoNan,odorScoreNoNan,'o','LineWidth',3)
hold on
plot(assignmentScoreShuffledNoNan,odorScoreShuffledNoNan,'ro','LineWidth',3)
xlabel('Assignment Score')
ylabel('Odor Score')
legend('Unshuffled','Shuffled')
title('Centroid*Shape Prior Matrix')
text(prctile(assignmentScoreNoNan,50),prctile(odorScoreNoNan,10),['Unshuffled r = ' num2str(mycorr(1,2)) ', p = ' num2str(myp(1,2))],'FontSize',15)
text(prctile(assignmentScoreNoNan,50),prctile(odorScoreNoNan,5),['Unshuffled r = ' num2str(mycorrShuffled(1,2)) ', p = ' num2str(mypShuffled(1,2))],'FontSize',15)
legend boxoff
box off
set(gca,'FontSize',15)

figure
plot(assignmentScoreNoNanControl,odorScoreNoNanControl,'o','LineWidth',3)
hold on
plot(assignmentScoreShuffledNoNanControl,odorScoreShuffledNoNanControl,'ro','LineWidth',3)
xlabel('Assignment Score')
ylabel('Odor Score')
legend('Unshuffled','Shuffled')
title('Randomized Prior Matrix')
text(prctile(assignmentScoreNoNanControl,90),prctile(odorScoreNoNanControl,10),['Unshuffled r = ' num2str(mycorrControl(1,2)) ', p = ' num2str(mypControl(1,2))],'FontSize',15)
text(prctile(assignmentScoreNoNanControl,90),prctile(odorScoreNoNanControl,5),['Unshuffled r = ' num2str(mycorrShuffledControl(1,2)) ', p = ' num2str(mypControlShuffled(1,2))],'FontSize',15)
legend boxoff
box off
set(gca,'FontSize',15)


figure
for j=1:length(glomerulusAssignment)
    p2=patch(isosurface(clusterVolU{clusterAssignment(j)}),'FaceColor',rand(1,3),'EdgeColor','none','FaceAlpha',0.3);
    isonormals(clusterVolU{clusterAssignment(j)},p2)
    text(clusterInfoU{clusterAssignment(j)}.Centroid(1),clusterInfoU{clusterAssignment(j)}.Centroid(2),clusterInfoU{clusterAssignment(j)}.Centroid(3),pubGlomNames{glomerulusAssignment(j)},'FontSize',15,'FontWeight','Bold')
    hold on
end

save('assignedGlomeruli.mat','clusterAssignment','glomerulusAssignment','compositeDist','myOR','pubOR','odorDist','physDistWeight','shapeWeight')

%% Use random permutations to try and improve greedy algorithm

nShuffles=10000; % number of trials
glomerulusAssignmentTries=cell(1,nShuffles);
clusterAssignmentTries=cell(1,nShuffles);
trialScore=zeros(1,nShuffles);
correlationTries=zeros(1,nShuffles);
correlationShuffledTries=zeros(1,nShuffles);
totalOdorScore=zeros(1,nShuffles);
totalOdorScoreShuffled=zeros(1,nShuffles);

glomsToTry=5;  % for each cluster, which top X gloms to consider
clustersToTry=5; % for each glomerulus, which top X clusters to consider
probToPermute=0.1; % fraction of time to permute [0,1]

assignmentThreshold=prctile(prctile(compositeDist,25),25);
%assignmentThreshold=Inf;

tic
for nTries=1:nShuffles
    compositeDistTemp=compositeDist;
    assignmentScore=[];
    glomerulusAssignment=[];
    clusterAssignment=[];
    iters=0;
    nassignments=1;
    while sum(any(compositeDistTemp))>0
        % find glomerulus that minimizes multiplied distance to each cluster
        glomMinimizing=zeros(1,size(myOR,2));
        glomMinimizingMatrix=zeros(size(myOR,2),size(pubOR,2));
        for i=1:size(myOR,2)
            if any(compositeDistTemp(i,:))
                %[val ind]=nanmin(compositeDistTemp(i,:));
                [val ind]=sort(compositeDistTemp(i,:));
                
                % take top X and randomly permute
                if nTries==1
                    val=val(1);
                    ind=ind(1);
                else
                    val=val(1:glomsToTry);
                    ind=ind(1:glomsToTry);
                    if rand<probToPermute
                        tempperm1=randperm(glomsToTry);
                    else
                        tempperm1=1:glomsToTry;
                    end
                    val=val(tempperm1);
                    ind=ind(tempperm1);
                end
                glomMinimizing(i)=ind(1);
                
                [asdf asdf2]=sort(compositeDistTemp(i,:));
                glomMinimizingMatrix(i,:)=asdf2;
            else
                glomMinimizing(i)=0;
                glomMinimizingMatrix(i,:)=NaN;
            end
        end
        
        uniqueGloms=unique(glomMinimizing);
        
        % find cluster that minimizes composite distance to each glomerulus
        uniqueClusters=zeros(1,(length(uniqueGloms)));
        for i=2:(length(uniqueGloms))
            currGlom=uniqueGloms(i);
            currClusters=find(glomMinimizing==currGlom);
            %[mymin myind]=min(compositeDistTemp(currClusters,currGlom));
            [mymin myind]=sort(compositeDistTemp(currClusters,currGlom));
            
            % randomly permute result
            if nTries==1
                mymin=mymin(1);
                myind=myind(1);
            else
            if length(mymin)>=clustersToTry
                if rand<probToPermute
                    tempperm=randperm(clustersToTry);
                else
                    tempperm=1:clustersToTry;
                end
                mymin=mymin(1:clustersToTry);
                myind=myind(1:clustersToTry);
            else
                if rand<0.5
                    tempperm=randperm(length(mymin));
                else
                    tempperm=1:length(mymin);
                end
            end
            mymin=mymin(tempperm);
            myind=myind(tempperm);
            end
            assignmentScore(nassignments)=mymin(1);
            
            uniqueClusters(i)=currClusters(myind(1));
            compositeDistTemp(currClusters(myind(1)),:)=NaN;
            compositeDistTemp(:,currGlom)=NaN;
            nassignments=nassignments+1;
        end
        
        glomerulusAssignment=[glomerulusAssignment uniqueGloms];
        clusterAssignment=[clusterAssignment uniqueClusters];
        iters=iters+1;
        %disp(['completed ' num2str(iters) ' iterations'])
    end
    
    
    todelete=find(glomerulusAssignment==0);
    glomerulusAssignment(todelete)=[];
    clusterAssignment(todelete)=[];
    
    
    % remove high scores (poor fit)
    highScores=find(assignmentScore>assignmentThreshold);
    glomerulusAssignment(highScores)=[];
    clusterAssignment(highScores)=[];
    assignmentScore(highScores)=[];
    
    totalscore=nansum(assignmentScore);
    
    odorScore=zeros(1,length(clusterAssignment));
    odorScoreShuffled=zeros(1,length(clusterAssignment));
    permutedArray=randperm(length(clusterAssignment));
    % validate using odor response
    for j=1:length(clusterAssignment)
       odorScore(j)=sqrt(nansum((myOR(:,clusterAssignment(j))-pubOR(:,glomerulusAssignment(j))).^2)/sqrt(nansum(isfinite(pubOR(:,glomerulusAssignment(j))))));
       odorScoreShuffled(j)=sqrt(nansum((myOR(:,clusterAssignment((j)))-pubOR(:,glomerulusAssignment(permutedArray(j)))).^2)/sqrt(nansum(isfinite(pubOR(:,glomerulusAssignment(permutedArray(j)))))));
    end
    
    tokeepOdorScore=find(isfinite(odorScore));
    odorScoreNoNan=odorScore(tokeepOdorScore);
    assignmentScoreNoNan=assignmentScore(tokeepOdorScore);
    mycorr=corrcoef(assignmentScoreNoNan,odorScoreNoNan);
    
    tokeepOdorScoreShuffled=find(isfinite(odorScoreShuffled));
    odorScoreShuffledNoNan=odorScoreShuffled(tokeepOdorScoreShuffled);
    assignmentScoreShuffledNoNan=assignmentScore(tokeepOdorScoreShuffled);
    mycorrShuffled=corrcoef(assignmentScoreShuffledNoNan,odorScoreShuffledNoNan);
    
    
    % save trial data
    glomerulusAssignmentTries{nTries}=glomerulusAssignment;
    clusterAssignmentTries{nTries}=clusterAssignment;
    trialScore(nTries)=totalscore;
    assignmentScoreTries{nTries}=assignmentScore;
    odorScoreTries{nTries}=odorScore;
    totalOdorScore(nTries)=nansum(odorScore)/sum(isfinite(odorScore));
    %totalOdorScore(nTries)=nansum(odorScore)/length(clusterAssignment);
    correlationTries(nTries)=mycorr(1,2);
    odorScoreShuffledTries{nTries}=odorScoreShuffled;
    totalOdorScoreShuffled(nTries)=nansum(odorScoreShuffled)/sum(isfinite(odorScoreShuffled));
    %totalOdorScoreShuffled(nTries)=nansum(odorScoreShuffled)/length(clusterAssignment);
    correlationShuffledTries(nTries)=mycorrShuffled(1,2);
    
    if mod(nTries,500)==0
        disp(['completed shuffle ' num2str(nTries)])
    end
end
disp(['finished. time elapsed = ' num2str(toc) ' seconds'])

trialScore=real(trialScore);
[bestv besti]=min(trialScore);
clusterAssignment=clusterAssignmentTries{besti};
glomerulusAssignment=glomerulusAssignmentTries{besti};

figure
plot(trialScore)
hold on
plot(1:length(trialScore),trialScore(1)*ones(1,length(trialScore)),'k--','LineWidth',2)
plot(besti,trialScore(besti),'ro','LineWidth',2)
xlabel('Trial #')
ylabel('Total Assignment Score')
legend('Trials','Vanilla Greedy','Winner')
legend boxoff
box off
set(gca,'FontSize',15)

figure;
plot(trialScore,totalOdorScore,'o')
hold on
plot(trialScore,totalOdorScoreShuffled,'r.')
legend('Unshuffled','Shuffled')
xlabel('Total Assignment Score')
ylabel('Total Odor Score')
legend boxoff
box off
set(gca,'FontSize',15)

figure;
plot(trialScore,correlationTries,'o')
hold on
plot(trialScore,correlationShuffledTries,'r.')
legend('Unshuffled','Shuffled')
xlabel('Total Assignment Score')
ylabel('Test - Train Correlation')
legend boxoff
box off
set(gca,'FontSize',15)
%%
figure
for j=1:length(glomerulusAssignment)
    p2=patch(isosurface(clusterVolU{clusterAssignment(j)}),'FaceColor',rand(1,3),'EdgeColor','none','FaceAlpha',0.3);
    isonormals(clusterVolU{clusterAssignment(j)},p2)
    text(clusterInfoU{clusterAssignment(j)}.Centroid(1),clusterInfoU{clusterAssignment(j)}.Centroid(2),clusterInfoU{clusterAssignment(j)}.Centroid(3),pubGlomNames{glomerulusAssignment(j)},'FontSize',15,'FontWeight','Bold')
    hold on
end

save('assignedGlomeruli.mat','clusterAssignment','glomerulusAssignment','compositeDist','myOR','pubOR','odorDist','physDistWeight','shapeWeight')