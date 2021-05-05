% takes a folder with tiff movies as input and concatenates them from top
% to bottom in the third dimmension to make one large tiff movie. Deposits
% this concatenated tif in the same folder with '_cat' appended



%% choose file and make list of tifs
fprintf('Select a folder containing tifs\n');
filename = uigetdir();

cd(filename);
tiflist = dir(fullfile(filename,'*.tif'));
% sort by time acquired 
T = struct2table(tiflist);
sortedT = sortrows(T,'date');
sortedS = table2struct(sortedT);

% loop through list and append each element
catMovie = [];

for i = 1:length(sortedS)
    fprintf('Loading %s\n',sortedS(i).name);
    movieChunk = loadtiff(sortedS(i).name);
    catMovie = cat(3,catMovie,movieChunk);
end

% save to datafolder
fprintf('saving concatenated file\n');
saveastiff(catMovie, [sortedS(1).name(1:end-6),'_cat.tif']);



    
    
    