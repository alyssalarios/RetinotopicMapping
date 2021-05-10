import os
import tifffile as tf
import matplotlib.pyplot as plt
import numpy as np
import RetinotopicMapping as rm
from processDriftCheck_v2 import preprocessDriftCheck

# takes Data generated from Psychotoolbox parameters in 'driftingCheck_ALbranch_2.m'
# 455 frames per complete round of bar presentations in each cardinal direction
# 10 recorded cycles - different number of cycles may result in error from unexpected matrix size

# sessionID is the mouse/ session identifier for that recording session. this will be appended to output files
# script will prompt you to choose a directory - this directory must contain 2 files with criteria:
#   1)a tif file that is a concatenated widefield movie for drifting bar stim presentation with the
#   nomenclature 'drift*cat.tif'
#   2) associated metadata.mat file with the nomenclature 'drift*.mat'
# no other files in this directory should meet this criteria (crash otherwise)
# routine still works if there are other files in directory that DONT fit nomenclature

# save ims = 1 if you want to save csv file maps in 'results' folder

# patch segmentation available if 'patches' section below is uncommented
################################################
# PARAMETERS
sessionID = 'test'
saveIms = 1

###########################################################
vascularFilename = 'vasculature_' + sessionID + '.tif'
dffFilename = 'dffMovies_' + sessionID + '.mat'

curr_folder = os.path.dirname(os.path.realpath(__file__))
data_folder = os.path.join(curr_folder, 'data')
results_folder = os.path.join(curr_folder, 'results')

os.chdir(curr_folder)
processedDC = preprocessDriftCheck()

vasculature_map = processedDC['vascularMap']
altitude_map = processedDC['altitudeMap']
azimuth_map = processedDC['azimuthMap']
altitude_power_map = processedDC['altitudePowerMap']
azimuth_power_map = processedDC['azimuthPowerMap']
freqTD = processedDC['TDfreq']
freqDU = processedDC['DUfreq']
freqLR = processedDC['LRfreq']
freqRL = processedDC['RLfreq']

################################
params = {
    'phaseMapFilterSigma': 1.8,
    'signMapFilterSigma': 10.,
    'signMapThr': 0.2,
    'eccMapFilterSigma': 15.0,
    'splitLocalMinCutStep': .5,
    'closeIter': 3,
    'openIter': 3,
    'dilationIter': 15,
    'borderWidth': 1,
    'smallPatchThr': 100,
    'visualSpacePixelSize': 0.5,
    'visualSpaceCloseIter': 15,
    'splitOverlapThr': 1.2,
    'mergeOverlapThr': 0.1
}

date = 1111
trial = rm.RetinotopicMappingTrial(altPosMap=altitude_map,
                                   aziPosMap=azimuth_map,
                                   altPowerMap=altitude_power_map,
                                   aziPowerMap=azimuth_power_map,
                                   vasculatureMap=vasculature_map,
                                   mouseID=sessionID,
                                   dateRecorded=date,
                                   comments='',
                                   params=params)

output = trial._getSignMap()

altMapf = output[0]
aziMapf = output[1]
altPowerf = output[2]
aziPowerf = output[3]
signMapf = output[5]

if saveIms == 1:
    # set paths
    signMapPath = os.path.join(results_folder, 'signMap_' + sessionID + '.csv')
    aziMapPath = os.path.join(results_folder, 'aziMap_' + sessionID + '.csv')
    altMapPath = os.path.join(results_folder, 'altMap_' + sessionID + '.csv')
    aziPowerPath = os.path.join(results_folder, 'aziPowerMap_' + sessionID + '.csv')
    altPowerPath = os.path.join(results_folder, 'altPowerMap_' + sessionID + '.csv')

    # save
    np.savetxt(signMapPath, signMapf, delimiter='|')
    np.savetxt(aziMapPath, aziMapf, delimiter='|')
    np.savetxt(aziPowerPath, aziPowerf, delimiter='|')
    np.savetxt(altMapPath, altMapf, delimiter='|')
    np.savetxt(altPowerPath, altPowerf, delimiter='|')

print("plotting figs")
# plots
fig, _axs = plt.subplots(3, 2, sharex=True, sharey=True)
fig.suptitle(sessionID)
axs = _axs.flatten()

axs[0].set_title('alt map filtered')
axs[0].imshow(output[0], cmap='jet')

axs[1].set_title('azi map filtered')
axs[1].imshow(output[1], cmap='jet')

#fig.colorbar(ax=[[0, 0], [0, 1]])

axs[2].set_title('alt power map')
axs[2].imshow(output[2], cmap='hot')

axs[3].set_title('azi power map')
axs[3].imshow(output[3], cmap='hot')

axs[4].set_title('sign map')
axs[4].imshow(output[5], cmap='coolwarm')

axs[5].set_title('Sign Map overlay')
axs[5].imshow(vasculature_map, cmap='Greys_r')
axs[5].imshow(output[5], cmap='coolwarm', alpha=0.5)


plt.figure()
fig2, _ax2 = plt.subplots(1,2, sharex=True, sharey=True)
fig2.suptitle('sessionID: Unfiltered Radian Maps')
axs2 = _ax2.flatten()

fig2.colorbar(axs2[0].imshow(altitude_map,cmap='jet'),ax=axs2[0])
axs2[0].set_title('Altitude Map Raw')
fig2.colorbar(axs2[1].imshow(azimuth_map,cmap='jet'),ax=axs2[1])
axs2[1].set_title('Azimuth Map Raw')
plt.show()
##########patches###################
# trial.processTrial(isPlot=True)

# plt.show()
#
# _ = trial.plotFinalPatchBorders2()
# plt.show()
#
# names = [
#     ['patch01', 'V1'],
#     ['patch02', 'PM'],
#     ['patch03', 'RL'],
#     ['patch04', 'P'],
#     ['patch05', 'LM'],
#     ['patch06', 'AM'],
#     ['patch07', 'LI'],
#     ['patch08', 'MMA'],
#     ['patch09', 'AL'],
#     ['patch10', 'RLL'],
#     ['patch11', 'LLA'],
#     #['patch13', 'MMP']
#   ]
#
# finalPatchesMarked = dict(trial.finalPatches)
#
# for i, namePair in enumerate(names):
#     currPatch = finalPatchesMarked.pop(namePair[0])
#     newPatchDict = {namePair[1]: currPatch}
#     finalPatchesMarked.update(newPatchDict)
#
# trial.finalPatchesMarked = finalPatchesMarked
#
# _ = trial.plotFinalPatchBorders2()
# plt.show()
#
# trialDict = trial.generateTrialDict()
