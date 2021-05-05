# RetinotopicMapping
Package to process widefield data into segmented visual areas when drifting bars are presented
Retinotopic Mapping protocol 

---------------VERSION 1----------------------
December 6 2020

Setup
Machine must have these programs installed: 
Python 3
Conda or miniconda (recommended)
Pycharm (or some other interpreting software ie dsCode or IDLE, I like Pycharm because its an integrated environment similar to Matlab) 
This protocol assumes Pycharm is being used 
Matlab 2020b

Files required: 
MATLAB
preprocessSignMaps_v1.m 
concatRawTifs.m
Loadtif.m / saveastiff.m (downloaded from https://www.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack)
Permn.m ( from https://www.mathworks.com/matlabcentral/fileexchange/7147-permn) 
avgDff.m
parseVisualStimData.m
PYTHON
Core (folder)
Clone from https://github.com/zhuangjun1981/NeuroAnalysisTools 
RetinotopicMapping.py
Adapted from https://github.com/zhuangjun1981/NeuroAnalysisTools
makeMaps.py 
preprocessDriftCheck.py
Requirements.txt
** red scripts are the only two files we’ll need to execute - everything else just needs to be on the matlab or python path
** these can all be found at Gu lab>personal files>Alyssa>analysis>code>visualStimProc>signMapping

Create virtual environment / configuration / Installing packages
Create new Pycharm project 
New environment using Conda
Python version 3.7 or higher
Don’t need a main script
Deposit core, makeMaps.py, processDriftCheck.py, requirements.txt, and RetinotopicMapping.py into the project folder
Create a new folder called ‘data’ and another called ‘results’ in the project folder
Configure executed script
Click dropdown menu at top right of screen > Edit configurations
Name ‘makeMaps’ and enter name of script in ‘Script path’ field 
Make sure the working directory is the pycharm project folder you just made 
In the terminal run pip install -r requirements.txt to install dependencies in your new virtual environment

Mapping 
Preprocessing
Add preprocessSignMaps_v1.m, concatRawTifs.m, loadtif.m, permn.m, avgDff.m, and parseVisualStimData.m to Matlab path

Open preprocessSignMaps.m and set routine parameters (top code block)

Run preprocessSignMaps_v1.m. You will be prompted to choose a data folder. This folder must contain one tif with nomenclature FILENAME_cat.tif OR a series of tifs to be concatenated. Note if running concatRawSave on raw files, this will concatenate ALL tiffs in the input folder, so make sure that folders are separated by sessions

If all goes well, there should be a new folder entitled ‘ProcessedData’ in your input folder. This is where the output .mat files are deposited. These are: 
dffMovies (4 tiff stacks with the average movie of each drifting bar direction scaled by the average resting frame and subtracted from the average resting frame, in other words percent intensity change from baseline) 
Vasculature.tif (vascular map, for overlaying the sign maps)
processingParameters (routine parameters that you set before running the script, for documentation purposes)
parsedMovieData (cell array with each drifting bar trial organized into a matrix m x n, where m is bar direction and n is cycles. These are raw trials in case you’re interested in looking at individual stim presentations)
Mapping 
Deposit dffMovies_filename.mat and vasculature_filename.tif into the data folder in Pycharm project

In the PARAMETERS code block, change sessionID to the saveFileName string you set in preprocessSignMaps. This will be added to the name of the output files

Run makeMaps.py

You will see a popup figure with angle maps, power maps, sign map, and sign map overlaid onto the vasculature 

Results folder should now contain 5 csv files (delimiters = ‘ | ’ ):
Azimuth map (radians)
Azimuth power map
Altitude power map
Altitude map (radians)
Sign map
Further analysis: 
Play with values in params dictionary to fine-tune sign map 
Look at documentation in github repo for RetinotopicMapping for parameter descriptions
Uncomment lines 101:134 to segment and identify V1 and extrastriate regions

--------------------VERSION 2--------------------------------
January 13 2021

See setup in version 1 

Files required: 
MATLAB
preprocessSignMaps_v2.m 
concatRawTifs.m
Loadtif.m / saveastiff.m (downloaded from https://www.mathworks.com/matlabcentral/fileexchange/35684-multipage-tiff-stack)
Permn.m ( from https://www.mathworks.com/matlabcentral/fileexchange/7147-permn) 
avgDff.m
parseVisualStimData.m
PYTHON
Core (folder)
Clone from https://github.com/zhuangjun1981/NeuroAnalysisTools 
RetinotopicMapping.py
Adapted from https://github.com/zhuangjun1981/NeuroAnalysisTools
**makeMaps_v2.py 
preprocessDriftCheck_v2.py
Requirements.txt
** only script we will execute
** these can all be found at Gu lab>personal files>Alyssa>analysis>code>visualStimProc>signMapping

Make sure all .m files are in matlab path 
python in venv should be version 3.8 to interface with matlab eng

Create virtual environment / configuration / Installing packages
Create new Pycharm project: what you name this will be myVirtualEnv
New environment using Conda
Python version 3.8 works, untested in other versions
Don’t need a main script
Deposit core, makeMaps.py, processDriftCheck.py, requirements.txt, and RetinotopicMapping.py into the project folder
Create a new folder called ‘data’ and another called ‘results’ in the project folder
Configure executed script
Click dropdown menu at top right of screen > Edit configurations
Name ‘makeMaps’ and enter name of script in ‘Script path’ field 
Make sure the working directory is the pycharm project folder you just made 
In the terminal run pip install -r requirements.txt to install dependencies in your new virtual environment
next install matlabengineforpython
- in search bar type 'anaconda prompt' and right click > run as administrator 
- go to matlab - enter 'matlabroot' in command window - copy this directory to clipboard
- go to conda terminal type conda activate myVirtualEnv
- cd 'matlabroot/extern/engines/python'
- next enter 'python setup.py install'


change sessionID in PARAMETERS code block in makeMaps_v2.py to animal/ session identifier. This will be included in saved files.

run makeMaps_v2.py 
you will be promted to choose data folder when matlab script is called. Choose folder that has concatenated drifting 
bar stim and metadata.m file. Option to concatenate raw datafiles if you go into preprocessSignMaps_v2 and set concatRawTif = 1
