function undersamp(filename,outname,sampFac,rodir)
% This function is made to pseudoundersample a dataset as we wish to do
% so.
%
% Primarily, this will be done only for the output of the gradient
% direction information (keeping in mind that we actually want to make sure
% that what we undersample is going to be the direction perpendicular to
% that line, going through the origin)
%
% This function has some parts of a code that I wrote in order to build
% PDFs (probability density functions) for spreading outside of a line.
%
%
%
% The parameters are as follows:
%
% filename - the input filename (string)
%          - This should be a minc file with information about the brain and
%          which gradient direction it is. Note that for Jacob's data (which
%          this is currently written for) the last 5 are no gradient
%          datasets. In theory, we may be able to get the gradient direction
%          from this information
% outname - The output filename (string)
%         - This data will effectively be the input file with the data
%         changed - that is, undersampled
% rodir - readout direction (string)
%       - The point of this data is to effectively make sure that we are
%       not messing up the data that we are looking at.
%       - As per Jacob, the general readout direction is 'y' for exvivo
%       scans
%
%
% Anthony Salerno                       01/06/15

if nargin < 3
    sampFac = 0.5;
end

if nargin < 4
    rodir = 'y';
end

rawdata = h5read(filename,'/minc-2.0/image/0/image'); % This gives us the dataset
data = zeros(size(rawdata)); % Preallocate memory for speed.

% A little bit of work to make sure that we have the correct order for the
% dimensions
dimorder = h5readatt('C:\Users\saler_000\Documents\raw\real\RealImgRaw.2.1.mnc',...
    '/minc-2.0/image/0/image','dimorder'); %Dimension order
dimorder = strsplit(dimorder,',');

for i = 1:length(dimorder)
    a = dimorder{i};
    dim{i} = a(1);
    clear a
end
clear dimorder
% Now we look at the order and see how we have to change around our
% gradient directions so that they match!
loc = zeros(1,3);
for i=1:3
    if dim{i} == 'x'
        loc(i) = 1;
    elseif dim{i} == 'y'
        loc(i) = 2;
    elseif dim{i} == 'z'
        loc(i) = 3;
    else
        error('Problem with your dimorder. Check file')
    end
end

% Change the order of the gradient vectors so it corresponds with the data
graddir = load('GradientVector.txt');
graddir = [graddir(:,loc(1)) graddir(:,loc(2)) graddir(:,loc(3))];

% Get which gradient we're working with by Splitting the name
nameSpl = strsplit(filename);
gradvec = graddir(round(str2num(nameSpl{end-1})),:); % Get the gradient vector so we know which one we need

if gradvec > 30
    disp('No gradient. Do not undersample');
else
    readloc = find(ismember(dim,rodir)); % This tells us which dimension the readout is on for our dataset, i.e. 1, 2, or 3
    gradvec = find(~ismember(gradvec,gradvec(readloc))); % Gives us only the values for the non readout direction
    % Quick and dirty way
    % to do a projection
    
    % Here is where we will have the heart of the code - this is where we will
    % actually do the undersampling
    % As of 01/06/15 the method will only have the linear undersampling as the
    % perpendicular value of the gradient vector
    
    gradvec = [-gradvec(2) gradvec(1)]; % Here is where we make it perpendicular
    slp = gradvec(2)/gradvec(1);
    n = size(rawdata);
    
    if readloc == 1
        slicesz = ones(n(2),n(3)); %What is the size of each slice
        filt = testline(slicesz,slp); % Make the filter that we will use
        
        for i = 1:n(1)
            data(i,:,:) = reshape(filt,size(rawdata(i,:,:))).*rawdata(i,:,:); % Applies the filter to each "slice"
        end
    elseif readloc == 2
        slicesz = ones(n(1),n(3)); %What is the size of each slice
        filt = testline(slicesz,slp); % Make the filter that we will use
        
        for i = 1:n(2)
            data(:,i,:) = reshape(filt,size(rawdata(:,i,:))).*rawdata(:,i,:); % Applies the filter to each "slice"
        end
    elseif readloc == 3
        slicesz = ones(n(1),n(2)); %What is the size of each slice
        filt = testline(slicesz,slp); % Make the filter that we will use
        
        for i = 1:n(3)
            data(:,:,i) = reshape(filt,size(rawdata(:,:,i))).*rawdata(:,:,i); % Applies the filter to each "slice"
        end
    end
    
    
    
end

