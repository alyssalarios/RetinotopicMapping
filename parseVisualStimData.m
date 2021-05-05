function [parsedData,locationPerms,cycleLabels] = parseVisualStimData(data,rectPositions,stimType,varargin )
% Takes either a tiff movie or a vector and splits the data into an n by m
% cell array according to numPosns and numTrials

%   If the data is a tiff movie, each row of trialMovies is a different visual
%   stim position presentation and each column is a trial. every cell
%   with each cell carrying one x-by-y-by-z matrix, each x-y plane is a
%   single frame and z is of length numFrames
%
%   If the data is a vector, each row of trialMovies is a different
%   visualstim position presentation and each column is a trial. individual
%   cells contain vectors of length numFrames corresponding to number of
%   frames in an individual trial.

% rect positions is a 1x2xz matrix from Luke's metadata describing the
% location of a presented visual stim, z is number of trials total

%% Initialize input parser
p = inputParser;

p.addRequired('data');
p.addRequired('rectPositions');
p.addRequired('stimType'); % takes 'bpNoise' or 'driftCheck'
p.addParameter('numPosns',9);
p.addParameter('numTrials',6);
p.addParameter('numFramesperTrial',55);
p.addParameter('posVector',[.2,.5,.8]);

p.addParameter('numCycles',10);
p.addParameter('numFramesPerCycle',835);


parse(p,data,rectPositions,stimType,varargin{:});

%% initialize parameters
data = p.Results.data;
rectPositions = p.Results.rectPositions;
pos = p.Results.posVector;
numTrials = p.Results.numTrials;
stimType = p.Results.stimType;
numCycles = p.Results.numCycles;
restFrames = 20;
numFramesPerCycle = p.Results.numFramesPerCycle;

%% parse data
% create vector with label number for every cycle
cycleLabels = zeros(size(rectPositions,3),1);
locationPerms = permn(pos,2)';
%driftVector = repmat(rectPositions,[1,numCycles]);


%create cell array with gcamp movie data separated by stim location and
%trial
switch isvector(data)
    case 0
        
        switch stimType
            case 'bpNoise'
                parsedData = cell(length(locationPerms),numTrials);
                for i = 1:size(rectPositions,3)
                    %add label
                    for j = 1:size(locationPerms,2)
                        if isequal(round(rectPositions(:,:,i),2),round(locationPerms(:,j)))
                            cycleLabels(i) = j;
                        end
                    end
                    
                    %grab portion of data that corresponds to ith trial
                    trialIndexVector = 1+(p.Results.numFramesperTrial*(i-1)):p.Results.numFramesperTrial+(p.Results.numFramesperTrial*(i-1));
                    trialBlock = data(:,:,trialIndexVector);
                    
                    %place that trial in corresponding cell in parsedData
                    posEmptyVec = cellfun(@(x) isempty(x), parsedData(cycleLabels(i),:));
                    colNum = find(posEmptyVec,1,'first');
                    
                    %create cell array for each block
                    parsedData{cycleLabels(i),colNum} = trialBlock;
                end
            case 'driftCheck'
                % output data structure
                parsedData = cell(length(unique(rectPositions)),numCycles);
                lastIndex = 0;
                %for i = 1:40
                for i = 1:size(data,3)/numFramesPerCycle*4
                    
                    %define number of frames in trial
                    if rectPositions(i) == 1 
                        framesPerTrial = restFrames + 98;
                    elseif rectPositions(i) == 2
                        framesPerTrial = restFrames + 97;
                    elseif rectPositions(i) == 3
                        framesPerTrial = restFrames + 90;
                    elseif rectPositions(i) == 4
                        framesPerTrial = restFrames + 90;
                    end
                    
                    % grab portion of data for ith trial
                    trialIndexVector = lastIndex+1: lastIndex + framesPerTrial ;
                    trialBlock = data(:,:,trialIndexVector);
                    lastIndex = trialIndexVector(end);
                    
                    %place that trial in corresponding cell in parsedData
                    posEmptyVec = cellfun(@(x) isempty(x), parsedData(rectPositions(i),:));
                    colNum = find(posEmptyVec,1,'first');
                    
                    %create cell array for each block
                    parsedData{rectPositions(i),colNum} = trialBlock;
                    
                end
        end
    case 1
        switch stimType
            case 'bpNoise'
                parsedData = cell(length(locationPerms),numTrials);
                for i = 1:size(rectPositions,3)
                    %add label
                    for j = 1:size(locationPerms,2)
                        if isequal(round(rectPositions(:,:,i),2),round(locationPerms(:,j),2))
                            cycleLabels(i) = j;
                        end
                    end
                    
                    %grab portion of data that corresponds to ith trial
                    trialIndexVector = 1+(p.Results.numFramesperTrial*(i-1)):p.Results.numFramesperTrial+(p.Results.numFramesperTrial*(i-1));
                    trialBlock = data(trialIndexVector,1);
                    
                    %place that trial in corresponding cell in parsedData
                    posEmptyVec = cellfun(@(x) isempty(x), parsedData(cycleLabels(i),:));
                    colNum = find(posEmptyVec,1,'first');
                    
                    %create cell array for each block
                    parsedData{cycleLabels(i),colNum} = trialBlock';
                end
            case 'driftCheck'
                parsedData = cell(length(unique(rectPositions)),numCycles);
                lastIndex = 0;
                for i = 1:size(data,1)/numFramesPerCycle*4
                    %define number of frames in trial
                    if rectPositions(i) == 1 
                        framesPerTrial = restFrames + 98;
                    elseif rectPositions(i) ==  2
                        framesPerTrial = restFrames + 97;
                    elseif rectPositions(i) == 3
                        framesPerTrial = restFrames + 90;
                    elseif rectPositions(i) == 4
                        framesPerTrial = restFrames + 90;
                    end
                    
                    % grab portion of data for ith trial
                    trialIndexVector = lastIndex+1: lastIndex + framesPerTrial ;
                    trialBlock = data(trialIndexVector,1);
                    lastIndex = trialIndexVector(end);
                    
                    %place that trial in corresponding cell in parsedData
                    posEmptyVec = cellfun(@(x) isempty(x), parsedData(rectPositions(i),:));
                    colNum = find(posEmptyVec,1,'first');
                    
                    %create cell array for each block
                    parsedData{rectPositions(i),colNum} = trialBlock;
                    
                end
        end
end