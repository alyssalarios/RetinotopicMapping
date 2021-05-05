% PREPROCESSING ROUTINE FOR DRIFTING VISUAL STIMULUS

% script that calculates dffMovies for drifting bar stim. intended for use
% in python wraparound script. Should create variables in the workspace
% that python matlab.engine object can access for further processing. 

% python should change cd to data folder before this script is run

%% Routine parameters
concatRawSave = 0; %starting from raw/ split up data movies or not
saveData = 0; % if 1, saves preprocessed data in a mat file.
loadCatTif = 1; % if starting with an input folder that has concatenated tif already, 1
normFrames = 10:20;
stimFrames = 20:90;
stimType = 'driftCheck';
numFramesPerCycle = 455;
numCycles = 10;
cameraFramerate = 0.1; %seconds
screenRefreshRate = 3;
saveFileName = 'ms8_s1';


%% Concatenate raw data
% Select folder with raw gcamp movies for concatenation, must contain
% associated metadata.mat file
% In this folder, a tif file will be deposited with '_cat.tif' appended
switch concatRawSave
    case 1
        concatRawTifs;
    case 0
        filename = uigetdir(); %select raw data folder to have variable
        cd(filename) % go to correct directory
end

catMovieDir = dir('drift*cat.tif');
metaFile = dir('drift*.mat');
if loadCatTif
    fprintf('Loading %s\n',catMovieDir.name);
    catMovie = loadtiff(catMovieDir.name);
    
end
load(metaFile.name,'cycleOrder');
avgWholeMovie = mean(catMovie,3);
cycleID = repmat(cycleOrder,[1,numCycles]);
%% Check for dropped frames
% returns error if length of tif ~= numFramesPerCycle * scalar (numCycles)
fprintf(['Expected number of frames: ',num2str(numFramesPerCycle*numCycles),'\n'])
if mod(size(catMovie,3) ,numFramesPerCycle) ~= 0
    fprintf([num2str(numFramesPerCycle - (mod(size(catMovie,3) ,numFramesPerCycle))),' dropped frames detected\n'])
    error('Error parsing tif, unpredicted number of frames');
    
else
    fprintf('No dropped frames\n')
    droppedFrames = 0;
end

%% output file
if saveData
    mkdir('ProcessedData');
    dataPath = [cd,'/','ProcessedData'];
end

%% vasculature map
vascularMap = mean(catMovie,3);
% hot pixel correction
% assigns any pixel that is > 3 standard deviations from the mean frame
% across the whole movie equal to the mean intensity value of the mean
% frame
meanVal = mean(vascularMap(:));
upperBound = (std(double(vascularMap(:))) * 3) + meanVal;
index = vascularMap > upperBound;
vascularMap(index) = meanVal;

%% Parse raw movie and compute Dff
parsedData = parseVisualStimData(catMovie,cycleID,stimType,'numCycles',numCycles,...
    'numFramesPerCycle',numFramesPerCycle);

% average all trials and subtract baseline
DffAllTrials = avgDff(parsedData,normFrames);


%% create variables for time delay- position conversion
load(metaFile.name,'frametime','verticalPositions','verticalCycleTime','horizontalPositions','horizontalCycleTime')
rightLeftPosVec = verticalPositions;
leftRightPosVec = fliplr(verticalPositions);
topDownPosVec = horizontalPositions;
downUpPosVec = fliplr(horizontalPositions);

% average every screenRefreshRate position
blocksize = [1,screenRefreshRate];

meanFilterFunction = @(theBlockStructure) mean2(theBlockStructure.data(:));
LRPositionAvg = blockproc(leftRightPosVec, blocksize, meanFilterFunction);
RLPositionAvg = blockproc(rightLeftPosVec, blocksize, meanFilterFunction);
TDPositionAvg = blockproc(topDownPosVec, blocksize, meanFilterFunction);
DUPositionAvg = blockproc(downUpPosVec, blocksize, meanFilterFunction);

horizontalTimeSteps = 0:cameraFramerate:cameraFramerate * ceil(length(horizontalPositions)/screenRefreshRate);
horizontalTimeSteps(1) = [];
verticalTimeSteps = 0:cameraFramerate:cameraFramerate* ceil(length(verticalPositions)/screenRefreshRate);
verticalTimeSteps(1) = [];


%% Separate averaged movies into new variables and save

% permute so that first dimmension is time
permutedAllTrials = cellfun(@(x) permute(x,[3,1,2]),DffAllTrials,...
    'un',false);

rightLeft = permutedAllTrials{1,1};
leftRight = permutedAllTrials{2,1};
topDown = permutedAllTrials{3,1};
downUp = permutedAllTrials{4,1};

rightLeftTif = uint16(permutedAllTrials{1,1}*6000);
leftRightTif = uint16(permutedAllTrials{2,1}*6000);
topDownTif = uint16(permutedAllTrials{3,1}*6000);
downUpTif = uint16(permutedAllTrials{4,1}*6000);


if saveData
    save([dataPath,'/dffMovies_',saveFileName,'.mat'],'rightLeft','leftRight','topDown','downUp',...
        'LRPositionAvg','RLPositionAvg','TDPositionAvg','DUPositionAvg',...
        'verticalTimeSteps','horizontalTimeSteps');
    save([dataPath,'/parsedMovieData_',saveFileName,'.mat'],'parsedData');
    save([dataPath,'/processingParameters_',saveFileName,'.mat'],'normFrames','stimFrames',...
        'stimType','numFramesPerCycle','numCycles','cameraFramerate','screenRefreshRate','cycleID');
    cd(dataPath)
    saveastiff(vascularMap,['vasculature_',saveFileName,'.tif']);
end

fprintf("Finished preprocessing\n")