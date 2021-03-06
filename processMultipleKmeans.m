function [clusterVolU clusterInfoU clusterArea nClustersFound] = processMultipleKmeans(rawKmeansFile)
% returns clusters and cluster info for rawKmeansFile where there are
% multiple replicates or multiple values for k

load(rawKmeansFile);

if length(numKmeans==1) % one kmeans run with multiple replicates
    disp('one kmeans run with multiple replicates')
    
    % find best kmeans replicates and only use those
    topkmeans=5;

    Csums = cellfun(@mean, sumd);
    [vals topinds]=sort(Csums,'ascend');
    topinds=topinds(1:topkmeans);
    
    nClustersFound=zeros(1,length(topinds));
    clusterVolU=cell(1,length(topinds));
    clusterInfoU=cell(1,length(topinds));
    clusterArea=cell(1,length(topinds));
    
    for jj=1:length(topinds)
        [clusterVol clusterInfo uniqueCV uniqueCI uniqueCI2d] = visualizeClusters(kmeansOut{topinds(jj)},400,20000000,50); % default 20000
        clusterVolU{jj}=uniqueCV;
        clusterInfoU{jj}=uniqueCI;
        %clusterInfo2dU{jj}=uniqueCI2d;
        clusterArea{jj}=zeros(1,length(uniqueCI));
        for z=1:length(uniqueCI)
            clusterArea{jj}(z)=uniqueCI{z}.Area;
        end
        nClustersFound(jj)=length(uniqueCV);
        disp(['found clusters for replicate # ' num2str(jj) ' of ' num2str(length(topinds))])
    end
else % multiple kmeans runs with multiple replicates
    disp('multiple kmeans runs with multiple replicates')
    nClustersFound=zeros(length(numKmeans),length(kmeansOut{1}));
    clusterVolU=cell(length(numKmeans),length(kmeansOut{1}));
    clusterInfoU=cell(length(numKmeans),length(kmeansOut{1}));
    clusterArea=cell(length(numKmeans),length(kmeansOut{1}));
    for j=1:length(numKmeans)
        for jj=1:length(kmeansOut{j})
            [clusterVol clusterInfo uniqueCV uniqueCI uniqueCI2d] = visualizeClusters((kmeansOut{j}{jj}),400,20000,50);
            clusterVolU{j}{jj}=uniqueCV;
            clusterInfoU{j}{jj}=uniqueCI;
            %clusterInfo2dU{j}{jj}=uniqueCI2d;
            clusterArea{j}{jj}=zeros(1,length(uniqueCI));
            for z=1:length(uniqueCI)
                clusterArea{j}{jj}(z)=uniqueCI{z}.Area;
            end
            nClustersFound(j,jj)=length(uniqueCV);
            disp(['found clusters for kmeans = ' num2str(numKmeans(j))])
        end
    end
end