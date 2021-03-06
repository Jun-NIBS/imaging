function [output] = assignGloms(nShuffles,odorCorrNormed,physDistNormed,shapePriorNormed,slicesToRemove,odorRankCorr,clusterCentroids,glomCentroids)
% assigns clusters a glomerular identity using a combination of prior
% information on odor response, centroid location, and shape
% assignGloms by default uses a greedy algorithm that makes the best
% assignment it can in a local fashion
%  assignGloms can run through multiple trials, where it will randomly
%  choose suboptimal solutions in an attempt to find a better global
%  minimum assignment
% nShuffles is number of trials to do (default is one)
%

physDistWeight=0.8;
shapeWeight=0.0;
odorWeight=0.1;

glomerulusAssignmentTries=cell(1,nShuffles);
clusterAssignmentTries=cell(1,nShuffles);

trialScore=zeros(1,nShuffles);

totalOdorScore=zeros(1,nShuffles);
totalOdorScoreShuffled=zeros(1,nShuffles);
totalDistScore=zeros(1,nShuffles);
totalDistScoreShuffled=zeros(1,nShuffles);
totalShapeScore=zeros(1,nShuffles);
totalShapeScoreShuffled=zeros(1,nShuffles);
totalPairwiseDistScore=zeros(1,nShuffles);

glomsToTry=5;  % for each cluster, which top X gloms to consider
clustersToTry=5; % for each glomerulus, which top X clusters to consider

% create lookup table for how often to select the top glomsToTry and top
% clustersToTry matches.  Use a n^powerProb probability distribution.
glomSelector=[];
clusterSelector=[];
powerProb=1; % 1 = linear.  2 = quadratic
for i=1:glomsToTry
    glomSelector=[glomSelector i*ones(1,(glomsToTry+1-i)^powerProb)];
end
for i=1:clustersToTry
    clusterSelector=[clusterSelector i*ones(1,(clustersToTry+1-i)^powerProb)];
end
probToPermute=1; % fraction of time to permute [0,1]

%compositeDist =  physDistWeight*(physDistNormed)+shapeWeight*shapePriorNormed;
compositeDist =  physDistWeight*(physDistNormed)+odorWeight*odorCorrNormed;

assignmentThreshold=prctile(compositeDist(:),20);
assignmentThreshold=Inf;

compositeDist(:,slicesToRemove)=NaN;

tic
for nTries=1:nShuffles
    % compositeDist copy that will be modified as clusters are assigned
    compositeDistTemp=compositeDist;
    
    assignmentScore=[];
    glomerulusAssignment=[];
    clusterAssignment=[];
    iters=0;
    nassignments=1;
    
    % while there are still unassigned clusters
    while sum(any(compositeDistTemp))>0
        % find glomerulus that minimizes composite distance to each cluster
        glomMinimizing=zeros(1,size(compositeDist,1));
        glomMinimizingMatrix=zeros(size(compositeDist,1),size(compositeDist,2));
        for i=1:size(compositeDist,1)
            if any(compositeDistTemp(i,:))
                
                % sort the closest glom matches to the current cluster
                [val ind]=sort(compositeDistTemp(i,:));
                nanstoremove=find(isnan(val));
                val(nanstoremove)=[];
                ind(nanstoremove)=[];
                
                % take top X matches and randomly permute
                % if we are past the first iteration
                if nTries==1
                    val=val(1);
                    ind=ind(1);
                else
                    if length(val)>=glomsToTry
                        val=val(1:glomsToTry);
                        ind=ind(1:glomsToTry);
                        if rand<probToPermute
                            tempperm1=randperm(length(glomSelector));
                        else
                            tempperm1=1:glomsToTry;
                        end
                    else
                        if rand<probToPermute
                            tempperm1=randperm(length(find(glomSelector<=length(val))));
                        else
                            tempperm1=1:length(val);
                        end
                    end
                    val=val(glomSelector(tempperm1(1)));
                    ind=ind(glomSelector(tempperm1(1)));
                end
                % assign the cluster to the glomerulus minimizing (or
                % randomly chosen non-optimal choice within top glomsToTry
                glomMinimizing(i)=ind(1);
                
                [asdf asdf2]=sort(compositeDistTemp(i,:));
                glomMinimizingMatrix(i,:)=asdf2;
            else
                glomMinimizing(i)=0;
                glomMinimizingMatrix(i,:)=NaN;
            end
        end
        
        % enumerate all uniquely chosen glomeruli
        uniqueGloms=unique(glomMinimizing);
        uniqueGloms(uniqueGloms==0)=[];
        
        % find cluster that minimizes composite distance to each glomerulus
        % This is for any glomeruli that have been assigned to multiple
        % clusters
        uniqueClusters=zeros(1,(length(uniqueGloms)));
        for i=1:(length(uniqueGloms))
            currGlom=uniqueGloms(i);
            currClusters=find(glomMinimizing==currGlom);
            [mymin myind]=sort(compositeDistTemp(currClusters,currGlom));
            
            nanstoremove=find(isnan(mymin));
            mymin(nanstoremove)=[];
            myind(nanstoremove)=[];
            
            % randomly permute result
            if nTries==1
                mymin=mymin(1);
                myind=myind(1);
            else
                if length(mymin)>=clustersToTry
                    if rand<probToPermute
                        tempperm=randperm(length(clusterSelector));
                    else
                        tempperm=1:clustersToTry;
                    end
                    mymin=mymin(1:clustersToTry);
                    myind=myind(1:clustersToTry);
                else
                    if rand<probToPermute
                        tempperm=randperm(length(find(clusterSelector<=length(mymin))));
                    else
                        tempperm=1:length(mymin);
                    end
                end
                mymin=mymin(clusterSelector(tempperm(1)));
                myind=myind(clusterSelector(tempperm(1)));
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
    end
    
    %     todelete=find(glomerulusAssignment==0);
    %     glomerulusAssignment(todelete)=[];
    %     clusterAssignment(todelete)=[];
    %
    %     todelete2=find(clusterAssignment==0);
    %     glomerulusAssignment(todelete2)=[];
    %     clusterAssignment(todelete2)=[];
    
    % remove high scores (poor fit)
    highScores=find(assignmentScore>assignmentThreshold);
    glomerulusAssignment(highScores)=[];
    clusterAssignment(highScores)=[];
    assignmentScore(highScores)=[];
    
    totalscore=nansum(assignmentScore);
    
    % calculate published glomeruli pairwise distances based on labelled
    % glomeruli
    pubPairwiseDist=NaN*zeros(size(glomCentroids,1),size(glomCentroids,1));
    for i=1:length(glomerulusAssignment)
        for j=1:length(glomerulusAssignment)
            if i~=j
                pubPairwiseDist(glomerulusAssignment(i),glomerulusAssignment(j))=sqrt(sum((glomCentroids(glomerulusAssignment(i),:)-glomCentroids(glomerulusAssignment(j),:)).^2));
            end
        end
    end
    % convert pairwise distances into rank distances
    pubPairwiseDistRank=NaN*zeros(size(glomCentroids,1),size(glomCentroids,1));
    for i=1:length(glomerulusAssignment)
        [vals inds]=sort(pubPairwiseDist(i,:));
        % remove nans
        todelete=find(isnan(vals));
        vals(todelete)=[];
        inds(todelete)=[];
        
        % save rank order
        for j=1:length(inds)
            pubPairwiseDistRank(i,inds(j))=j;
        end
    end
    
    % find pair-wise distances between all clustered glomeruli locations
    clusterPairwiseDist=NaN*zeros(size(glomCentroids,1),size(glomCentroids,1));
    for i=1:length(glomerulusAssignment)
        for j=1:length(glomerulusAssignment)
            if i~=j
                clusterPairwiseDist(glomerulusAssignment(i),glomerulusAssignment(j))=sqrt(sum((clusterCentroids(clusterAssignment(i),:)-clusterCentroids(clusterAssignment(j),:)).^2));
            end
        end
    end
    
    % convert pairwise distances into rank distances
    clusterPairwiseDistRank=NaN*zeros(size(glomCentroids,1),size(glomCentroids,1));
    for i=1:length(glomerulusAssignment)
        [vals inds]=sort(clusterPairwiseDist(i,:));
        % remove nans
        todelete=find(isnan(vals));
        vals(todelete)=[];
        inds(todelete)=[];
        
        % save rank order
        for j=1:length(inds)
            clusterPairwiseDistRank(i,inds(j))=j;
        end
    end
    
    odorScore=zeros(1,length(clusterAssignment));
    odorScoreShuffled=zeros(1,length(clusterAssignment));
    distScore=zeros(1,length(clusterAssignment));
    distScoreShuffled=zeros(1,length(clusterAssignment));
    shapeScore=zeros(1,length(clusterAssignment));
    shapeScoreShuffled=zeros(1,length(clusterAssignment));
    pairWiseDistScore=zeros(1,length(clusterAssignment));
    
    permutationsForShuffledArray=1;
    % validate using odor rank correlation
    for j=1:length(clusterAssignment)
        odorScore(j)=(odorRankCorr(clusterAssignment(j),glomerulusAssignment(j)));
        distScore(j)=(physDistNormed(clusterAssignment(j),glomerulusAssignment(j)));
        shapeScore(j)=(shapePriorNormed(clusterAssignment(j),glomerulusAssignment(j)));
        
        tempinds=find(isfinite(clusterPairwiseDistRank(glomerulusAssignment(j),:)));
        tempinds2=find(isfinite(pubPairwiseDistRank(glomerulusAssignment(j),:)));
        tempintersect=intersect(tempinds,tempinds2);
        %tempcorr=corrcoef(clusterPairwiseDistRank(glomerulusAssignment(j),tempintersect),pubPairwiseDistRank(glomerulusAssignment(j),tempintersect));
        tempcorr=corrcoef(clusterPairwiseDist(glomerulusAssignment(j),tempintersect),pubPairwiseDist(glomerulusAssignment(j),tempintersect));
        pairWiseDistScore(j)=tempcorr(1,2);
        
        odorScoreShuffledTemp=zeros(1,permutationsForShuffledArray);
        distPriorScoreShuffledTemp=zeros(1,permutationsForShuffledArray);
        shapePriorScoreShuffledTemp=zeros(1,permutationsForShuffledArray);
        for perms=1:permutationsForShuffledArray
            permutedArray=randperm(length(clusterAssignment));
            odorScoreShuffledTemp(perms)=(odorRankCorr(clusterAssignment(j),glomerulusAssignment(permutedArray(j))));
            distPriorScoreShuffledTemp(perms)=(physDistNormed(clusterAssignment(j),glomerulusAssignment(permutedArray(j))));
            shapePriorScoreShuffledTemp(perms)=(shapePriorNormed(clusterAssignment(j),glomerulusAssignment(permutedArray(j))));
        end
        
        odorScoreShuffled(j)=nanmean(odorScoreShuffledTemp);
        distScoreShuffled(j)=nanmean(distPriorScoreShuffledTemp);
        shapeScoreShuffled(j)=nanmean(shapePriorScoreShuffledTemp);
    end
    
    % save trial data
    glomerulusAssignmentTries{nTries}=glomerulusAssignment;
    clusterAssignmentTries{nTries}=clusterAssignment;
    
    trialScore(nTries)=totalscore;
    assignmentScoreTries{nTries}=assignmentScore;
    
    % save prior scores
    odorScoreTries{nTries}=odorScore;
    totalOdorScore(nTries)=nanmedian(odorScore);
    
    distScoreTries{nTries}=distScore;
    totalDistScore(nTries)=nanmedian(distScore);
    
    shapeScoreTries{nTries}=shapeScore;
    totalShapeScore(nTries)=nanmedian(shapeScore);
    
    pairwiseDistScoreTries{nTries}=pairWiseDistScore;
    totalPairwiseDistScore(nTries)=nanmedian(pairWiseDistScore);
    
    % save shuffled scores
    odorScoreShuffledTries{nTries}=odorScoreShuffled;
    totalOdorScoreShuffled(nTries)=nanmedian(odorScoreShuffled);
    
    distScoreShuffledTries{nTries}=distScoreShuffled;
    totalDistScoreShuffled(nTries)=nanmedian(distScoreShuffled);
    
    shapeScoreShuffledTries{nTries}=shapeScoreShuffled;
    totalShapeScoreShuffled(nTries)=nanmedian(shapeScoreShuffled);
    
    if mod(nTries,100)==0
        disp(['completed shuffle ' num2str(nTries) ' of ' num2str(nShuffles)])
    end
end
disp(['finished. time elapsed = ' num2str(toc) ' seconds'])


output.clusterAssignmentHistory=clusterAssignmentTries;
output.glomerulusAssignmentHistory=glomerulusAssignmentTries;

output.optimizedScore=trialScore;
output.optimizedScoreHistory=assignmentScoreTries;

output.odorScoreHistory=odorScoreTries;
output.distScoreHistory=distScoreTries;
output.shapeScoreHistory=shapeScoreTries;
output.totalOdorScore=totalOdorScore;
output.totalDistScore=totalDistScore;
output.totalShapeScore=totalShapeScore;
output.pairwiseDistScoreHistory=pairwiseDistScoreTries;
output.totalPairwiseDistScore=totalPairwiseDistScore;

output.odorScoreShuffledHistory=odorScoreShuffledTries;
output.distScoreShuffledHistory=distScoreShuffledTries;
output.shapeScoreShuffledHistory=shapeScoreShuffledTries;
output.totalOdorScoreShuffled=totalOdorScoreShuffled;
output.totalDistScoreShuffled=totalDistScoreShuffled;
output.totalShapeScoreShuffled=totalShapeScoreShuffled;

output.assignmentThreshold=assignmentThreshold;