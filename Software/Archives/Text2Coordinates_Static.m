clc;
clear all;
close all;

% Parameters
thinning = false;
image = false;
scaleFactor = 10;  % Set the desired scaling factor for font size
pauseTime = 0.001;  % Time delay between each movement (seconds)

% Create image from text if not uploading an image
if ~image
    % Styles: normal, bold
    % Thin Text: Font size of 15
    % Thick Text: Font size of 30 and turn thinning off. Creates double boundaries
    % Font size increases number of coordinates and text resolution
    createTextImage('hi', 40, 500, 100, 'image.png', 'Arial', 'normal'); 
end

% Load and process image
img = imread('image.png'); % Load image
grayImg = rgb2gray(img); % Convert to grayscale
binaryImg = imbinarize(grayImg); % Binarize the image
binaryImg = ~binaryImg; % Invert image if needed (black text on white)

% Extract contours
boundaries = bwboundaries(binaryImg, 'holes');  % Find inner and outer boundaries

%% THINNING
if thinning == true
    % Thin slightly to preserve small components
    thinnedImg = bwmorph(binaryImg, 'thin', 1);       % Thin only once to avoid losing small dots
    
    % Extract contours (without holes, due to thickness)
    boundaries = bwboundaries(thinnedImg, 'noholes'); % Find boundaries of thinned text, but ignore holes (since we're thinning)
end
%%

% Collect and scale points for each boundary
allPoints = [];                                       % Initialize array for all points

for k = 1:length(boundaries)
    boundary = boundaries{k};                         % Get boundary points for each character
    scaledBoundary = boundary * scaleFactor;          % Apply scaling to each boundary point
    allPoints = [allPoints; NaN NaN; scaledBoundary]; % Separate each character with NaN for plotting
end

% Reformat
allPoints(:,3) = -allPoints(:,1);
allPoints(:,1) = allPoints(:,2);
allPoints(:,2) = allPoints(:,3);

% Plot
figure;
plot(allPoints(:,1), allPoints(:,2), '.-');           % Swap x and y, and flip y-axis to correct orientation
axis equal;
title('Scaled Coordinates for Text');
xlabel('X');
ylabel('Y');

% allPoints contains the scaled coordinates of all text boundaries

function createTextImage(inputText, fontSize, imageWidth, imageHeight, outputFileName, fontName, fontStyle)
    % Parameters:
    % inputText      : The text to be rendered (e.g., 'Hello World!')
    % fontSize       : Font size for the text (e.g., 30)
    % imageWidth     : Width of the image (e.g., 500)
    % imageHeight    : Height of the image (e.g., 100)
    % outputFileName : Output file name (e.g., 'text_image.png')
    % fontName       : Name of the font (e.g., 'Arial', 'Times New Roman')
    % fontStyle      : Font style ('normal', 'bold', 'italic', 'bolditalic')

    % Create a blank canvas (white background)
    figure;
    imshow(ones(imageHeight, imageWidth), 'InitialMagnification', 'fit'); % White canvas
    hold on;
    axis off;
    
    % Render the text on the canvas with the specified font and style
    text(10, 50, inputText, 'FontSize', fontSize, 'FontName', fontName, ...
         'FontWeight', fontStyle, 'Color', 'black');
    
    % Capture the figure as an image
    frame = getframe(gcf);          % Capture the figure content
    textImg = frame.cdata;          % Extract image data
    close;                          % Close the figure
    
    % Save the generated image to a file
    imwrite(textImg, outputFileName); % Save as PNG or any format

    % Inform the user
    disp(['Image saved as ' outputFileName]);
end
