function texture = imageFileToTexture(window, imagePath)
% imageFileToTexture Loads an image file and creates a Psychtoolbox texture.
% Psychtoolbox requiers that all image files are converted to "textures"
% before displaying in a Psychtoolbox window.
%
%   texture = imageFileToTexture(window, imagePath)
%
% Inputs:
%   window    - Psychtoolbox window
%   imagePath - Full file path to the image (e.g., .jpg, .png)
%
% Output:
%   texture   - image as a Psychtoolbox texture

    % Check if the file exists
    if ~exist(imagePath, 'file')
        error('Image file not found: %s', imagePath);
    end

    imageMatrix = imread(imagePath); % Converts image into a matrix of pixels
    texture = Screen('MakeTexture', window, imageMatrix); % Create texture from image matrix, ready to display in a Psychtoolbox window
    
end
