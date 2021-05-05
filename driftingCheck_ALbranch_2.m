% this version of the drifting checkerboard takes away the spherical
% correction of the azimuthal bars
% 
% be sure to open serial communication with camera triggering arduino  before starting; can
% use this line of code:
%s = serialport("COM4",9600);%
% if doing ball tracking arduino as well, need to do this:
%ballTrackingPort = serialport('COM6',9600);

% Clear the workspace
close all;
clearvars -except s ballTrackingPort;
sca;


%% recording parameters
dorecording = 0;
numCycles = 1;
recordCycles = 2:11;
fileSaveName = 'test';

%% execute

% Time to wait in frames for a flip (this effectively determines the frame
% rate)
waitframes = 2;
writelinecounter = 0;       % keeps track of how many times the cameras are triggered
% declare if you will be doing any recording:


if dorecording
    %flush(ballTrackingPort);
end

%% set checkerboard parameters:
boxsize = deg2rad(25);
barwidth = deg2rad(20);
driftspeed = deg2rad(9);        %this will be rad/sec
switchrate = 1/6;     %how long to wait before you switch the contrast on the checkerboard
frametimecheck = [];
%% screen parameters:
params.imsz = [1024, 1280];         %in pixels
params.screenHeight = 270;          %in mm
params.screenWidth = 338;           %in mm
params.pixelsize = params.screenHeight/params.imsz(1);
params.screenDistance = 170;        %in mm
params.screenAngle = deg2rad(30); 
params.origin = [.26,.5];       %the point on the screen normal to the eye in fraction of the screen coordinates for azimuth and elevation respectively

%% generate both checkerboards:
check1 = generateCheckerboard(deg2rad(25),params);
check2 = ~check1;
[azim,elev] = pixel2angle_v2_1(params);

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
screenNumber = 1;

% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Query the frame duration for the screen
ifi = Screen('GetFlipInterval', window);
frametime = ifi*waitframes;     %this will store the amount of time between actual updates to the screen, not just the screen's refresh rate


%% figure out movie length based on drift speed:
horizontalNumFrames = round((max(elev(:))-min(elev(:)))/driftspeed/frametime);
verticalNumFrames = round((max(azim(:))-min(azim(:)))/driftspeed/frametime);

verticalCycleTime = verticalNumFrames*frametime;
horizontalCycleTime = horizontalNumFrames*frametime;

horizontalPositions = min(elev(:)):(driftspeed*frametime):max(elev(:));
verticalPositions = min(azim(:)):(driftspeed*frametime):max(azim(:));

%% before start presenting the stimuli, calculate the timestamps for the 
% start of each stimulus presentation to keep sync accurate with the camera

%create a cycleOrder variable which sets the parameters of the drifting.
%1 is vertical bar drifting towards the medial direction, 2 is vertical bar
%drifting in opposite direction, 3 is horizontal bar drifting upwards, 4 is
%horizontal bar driftin downwards
cycleOrder = [1,2,3,4];
              % this is the # of times cycleOrder will repeat
intercyclePause = 3;        %some additional buffer time in between cycles to account for possible timing mismatching
cycleID = repmat(cycleOrder, 1, numCycles);
restTime = 2;       %length of time a blank grey screen is shown before start of stim presentation (in seconds)
          %this varialbe stores the cycles where you're actually going to trigger the camera to record
recordCycles = (recordCycles - 1)*length(cycleOrder)+1;

cycleStartTimes = zeros(1,length(cycleID));       %this will store the exact times at which each bar starts being presented
cycleStartTimes(1) = restTime;
for n = 2:length(cycleStartTimes)
    if cycleID(n-1) == 1 || cycleID(n-1) == 2
        cycleStartTimes(n) = cycleStartTimes(n-1)+verticalCycleTime + restTime;
    else
        cycleStartTimes(n) = cycleStartTimes(n-1)+horizontalCycleTime + restTime;
    end
    if mod(n,length(cycleOrder)) == 1
        cycleStartTimes(n) = cycleStartTimes(n) + intercyclePause;
    end
end


% Screen resolution in X and Y
screenXpix = windowRect(3);
screenYpix = windowRect(4);

% Now we make this into a PTB texture
blank = grey*ones(screenYpix,screenXpix);

%% now that camera has been triggered and visual stim is about to start,
% the window into top priority level:

% Retreive the maximum priority number
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Display grey screen; timing for this display not important
Screen('FillRect', window, grey);
Screen('Flip', window);
globalTime = GetSecs();             % this will keep track of the time since the whole experiment started; use this to sync with the cycleStartTimes
cycleTimingCheck = zeros(size(cycleStartTimes));
counter = 0;
tic
for k = 1:length(cycleID)
    switch cycleID(k)
        case 1
            barPositions = verticalPositions;
            barOrientation = 'vertical';
        case 2
            barPositions = fliplr(verticalPositions);
            barOrientation = 'vertical';
        case 3
            barPositions = horizontalPositions;
            barOrientation = 'horizontal';
        case 4
            barPositions = fliplr(horizontalPositions);
            barOrientation = 'horizontal';
    end
    
    boardpattern = 1;
    simtime = 0;
    
    stimbar = generateStimBar(barPositions(1),barOrientation,barwidth,azim,elev);
    temp = check1.*stimbar;
    temp(stimbar==0) = .5;
    curImage = Screen('MakeTexture',window,temp);
    Screen('DrawTexture',window,curImage);
    simtime = simtime + frametime;
    triggertracker = 0;
    while (GetSecs()-globalTime) < cycleStartTimes(k)
        if dorecording && ismember(k,recordCycles) && triggertracker == 0
            while (GetSecs()-globalTime) < (cycleStartTimes(k)-restTime)
                %wait to trigger camera until rest to start of imaging
                %cycle
            end
            tic;
            writeline(s,'m');
            writelinecounter = writelinecounter + 1;
            triggertracker = 1;
        end
    end
    vbl = Screen('Flip', window);           %sync to vertical retrace
    cycleTimingCheck(k) = GetSecs()-globalTime;
    timingCheck_cycleStart = GetSecs();
    for n = 2:length(barPositions)
        if simtime > switchrate
            boardpattern =  -boardpattern;
            simtime = 0;
        else
            simtime = simtime + frametime;
        end
        switch boardpattern
            case 1
                stimbar = generateStimBar(barPositions(n),barOrientation,barwidth,azim,elev);
                temp = check1.*stimbar;
            case -1
                stimbar = generateStimBar(barPositions(n),barOrientation,barwidth,azim,elev);
                temp = ~check1.*stimbar;
        end
        temp(stimbar==0) = .5;
        curImage = Screen('MakeTexture',window,temp);
        Screen('DrawTexture',window,curImage);
        %vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
        vbl = Screen('Flip', window, vbl + (waitframes - 0.0) * ifi);
        if length(frametimecheck) < 300
            frametimecheck = [frametimecheck, GetSecs()-timingCheck_cycleStart];
        end
    end
    timingCheck_cycle(k) = GetSecs()-timingCheck_cycleStart;
    Screen('FillRect', window, grey);
    %Screen('Flip',window, vbl + (waitframes - 0.5) * ifi);
    Screen('Flip',window, vbl + (waitframes - 0.0) * ifi);
    Screen('Close')
    counter = counter+1;
    fprintf([num2str(counter/4),'\n']);
end
fintime = toc;
WaitSecs(restTime)
cycleEndTime = GetSecs() - globalTime;

% Color the screen blue
Screen('FillRect', window, [0 0 0.5]);
Priority(0);        % reset priority back to normal
% Tell PTB no more drawing commands will be issued until the next flip
Screen('DrawingFinished', window);
%vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
vbl = Screen('Flip', window, vbl + (waitframes - 0.0) * ifi);
WaitSecs(1);

%% read out the ball tracking data
if dorecording
    %ballTrackingData = read(ballTrackingPort,ballTrackingPort.NumBytesAvailable,'string');
  %  ballTrackingData = getBallTrackingData(ballTrackingPort);
 %   sData = read(s,s.NumBytesAvailable,'string');
end
% Clear up and leave the building
sca;
close all;
if dorecording
    save(fileSaveName);
end
%clear all;